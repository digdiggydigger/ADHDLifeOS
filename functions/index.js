'use strict';

/**
 * The capture endpoint the iOS Shortcut posts to — the Firebase replacement for the retired AWS
 * `POST /captures` route (`life-os-api-gw`), which the Firebase cutover left writing into a
 * DynamoDB table the app no longer reads.
 *
 * Deliberately shaped like the old endpoint so the Shortcut keeps its shape: one POST, one JSON
 * body, one capture created. Everything awkward — the document id, the timestamp, the Storage
 * upload, the download URL — happens here rather than in Shortcuts actions.
 *
 * Auth is a shared secret, not a Firebase ID token: a Shortcut cannot refresh an expiring token
 * unattended, and this is a single-user personal app. The secret and the target uid are runtime
 * config, never committed.
 */

const { randomUUID } = require('node:crypto');
const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret, defineString } = require('firebase-functions/params');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');

const {
  buildCaptureDocument,
  downloadURL,
  mediaObjectPath,
  normalizeCapturePayload,
  secretMatches,
} = require('./capture');

const {
  SUMMARY_SCHEMA,
  buildPrompt,
  normalizeSummaryContent,
  normalizeSummaryRequest,
} = require('./dailySummary');

const CAPTURE_SECRET = defineSecret('CAPTURE_SECRET');
const CAPTURE_UID = defineString('CAPTURE_UID');
const ANTHROPIC_API_KEY = defineSecret('ANTHROPIC_API_KEY');

admin.initializeApp();

/** Base64 inflates by ~33%, so cap the decoded size well inside the 32MB request limit. */
const MAX_MEDIA_BYTES = 20 * 1024 * 1024;

/** The model behind the Daily Executive Summary. */
const MODEL = 'claude-opus-5';

/**
 * Caps thinking AND response text together — adaptive thinking is on by default on Claude Opus 5,
 * so a budget sized only for the JSON would truncate mid-answer. The summary itself is a few
 * hundred tokens; the rest is headroom for reasoning.
 */
const MAX_TOKENS = 8192;

/**
 * `medium`, not the `high` default: writing a short summary from already-structured data is
 * routine work, and Claude Opus 5 performs unusually well at the lower effort levels. This is the
 * first thing to raise if summaries come back shallow — it is a latency/cost/quality dial, and the
 * user is watching a spinner while it runs.
 */
const EFFORT = 'medium';

exports.capture = onRequest(
  { secrets: [CAPTURE_SECRET], cors: false, region: 'us-central1' },
  async (request, response) => {
    if (request.method !== 'POST') {
      response.set('Allow', 'POST');
      return response.status(405).json({ error: 'POST only' });
    }

    // An UNSET secret must fail closed. `secretMatches('', '')` is legitimately true — two empty
    // strings are equal — so without this guard a misconfigured deploy would accept any caller who
    // simply omitted the header. Fail-closed before the comparison, never inside it.
    const expectedSecret = CAPTURE_SECRET.value() || process.env.CAPTURE_SECRET || '';
    if (!expectedSecret) {
      logger.error('CAPTURE_SECRET is not configured — refusing every request');
      return response.status(500).json({ error: 'server not configured' });
    }

    // Checked before anything is parsed or written, so an unauthenticated caller can't use this
    // endpoint to probe payload validation.
    const provided = request.get('X-LifeOS-Key') || '';
    if (!secretMatches(provided, expectedSecret)) {
      logger.warn('capture rejected: bad or missing X-LifeOS-Key');
      return response.status(401).json({ error: 'unauthorized' });
    }

    const uid = CAPTURE_UID.value() || process.env.CAPTURE_UID || '';
    if (!uid) {
      logger.error('CAPTURE_UID is not configured');
      return response.status(500).json({ error: 'server not configured' });
    }

    const normalized = normalizeCapturePayload(request.body);
    if (!normalized.ok) {
      return response.status(400).json({ error: normalized.error });
    }
    const { kind, content, title, lifeAreaId, media } = normalized.value;

    // Uppercase, and used BOTH as the document name and as the `id` field. The app addresses a
    // capture by the id it decoded out of the body (`markProcessed`), so if those two ever diverge,
    // triage silently stops working.
    const id = randomUUID().toUpperCase();

    try {
      let mediaURL;
      if (media) {
        const buffer = Buffer.from(media.data, 'base64');
        if (buffer.length === 0) {
          return response.status(400).json({ error: 'media.data is not valid base64' });
        }
        if (buffer.length > MAX_MEDIA_BYTES) {
          return response.status(413).json({ error: 'media too large' });
        }

        const bucket = admin.storage().bucket();
        const objectPath = mediaObjectPath(uid, id, media.contentType);
        // The token is what makes the download URL permanent — see `downloadURL`.
        const token = randomUUID();
        await bucket.file(objectPath).save(buffer, {
          contentType: media.contentType,
          metadata: { metadata: { firebaseStorageDownloadTokens: token } },
        });
        mediaURL = downloadURL(bucket.name, objectPath, token);
      }

      const doc = buildCaptureDocument({
        id,
        content,
        kind,
        createdAt: admin.firestore.Timestamp.now(),
        title,
        lifeAreaId,
        mediaURL,
        mediaContentType: media && media.contentType,
      });

      await admin.firestore()
        .collection('users').doc(uid)
        .collection('captures').doc(id)
        .set(doc);

      logger.info('capture created', { id, kind, hasMedia: Boolean(media) });
      return response.status(201).json({ id, kind });
    } catch (error) {
      // The Shortcut shows this, so it has to say something the user can act on.
      logger.error('capture failed', error);
      return response.status(502).json({ error: 'could not save the capture' });
    }
  },
);

// ---------------------------------------------------------------------------
// Daily Executive Summary
// ---------------------------------------------------------------------------

/**
 * Writes the end-of-day summary the Home card renders, from the day's real material.
 *
 * Auth is a **Firebase ID token**, not the capture endpoint's shared secret. The difference is
 * deliberate: a Shortcut cannot refresh an expiring token unattended, so `capture` uses a static
 * key; the app can and does refresh, so this endpoint gets the stronger, per-user, revocable
 * credential and never needs a secret shipped to the client.
 */
exports.dailySummary = onRequest(
  { secrets: [ANTHROPIC_API_KEY], cors: false, region: 'us-central1', timeoutSeconds: 120 },
  async (request, response) => {
    if (request.method !== 'POST') {
      response.set('Allow', 'POST');
      return response.status(405).json({ error: 'POST only' });
    }

    // Checked before the payload is looked at, so an unauthenticated caller learns nothing about
    // the request shape — same ordering as `capture`.
    const header = request.get('Authorization') || '';
    const bearer = header.startsWith('Bearer ') ? header.slice('Bearer '.length).trim() : '';
    if (!bearer) {
      return response.status(401).json({ error: 'unauthorized' });
    }
    try {
      await admin.auth().verifyIdToken(bearer);
    } catch (error) {
      logger.warn('daily summary rejected: bad ID token', { message: error.message });
      return response.status(401).json({ error: 'unauthorized' });
    }

    const apiKey = ANTHROPIC_API_KEY.value() || process.env.ANTHROPIC_API_KEY || '';
    if (!apiKey) {
      logger.error('ANTHROPIC_API_KEY is not configured');
      return response.status(500).json({ error: 'server not configured' });
    }

    const normalized = normalizeSummaryRequest(request.body);
    if (!normalized.ok) {
      return response.status(400).json({ error: normalized.error });
    }
    const summaryRequest = normalized.value;
    const { system, user } = buildPrompt(summaryRequest);

    try {
      const Anthropic = require('@anthropic-ai/sdk');
      const client = new Anthropic({ apiKey });

      const message = await client.beta.messages.create({
        model: MODEL,
        max_tokens: MAX_TOKENS,
        system,
        messages: [{ role: 'user', content: user }],
        // Structured outputs: `additionalProperties: false` plus all-required is what makes the
        // result safe to hand to the app, which decodes it straight into `DailySummaryContent`.
        output_config: {
          format: { type: 'json_schema', schema: SUMMARY_SCHEMA },
          effort: EFFORT,
        },
        thinking: { type: 'adaptive' },
        // Claude Opus 5's safety classifiers can decline a request. Without a fallback a refusal
        // is simply a dead end; `"default"` re-runs it on Anthropic's recommended substitute,
        // routed by refusal category, so a false positive on benign text still returns a summary.
        betas: ['server-side-fallback-2026-07-01'],
        fallbacks: 'default',
      });

      // Check stop_reason BEFORE reading content — on a refusal `content` is empty or partial,
      // and indexing into it blindly is how this turns into a 500 instead of a clear message.
      if (message.stop_reason === 'refusal') {
        logger.warn('daily summary refused', { category: message.stop_details?.category ?? null });
        return response.status(502).json({ error: 'the model declined to write this summary' });
      }

      const textBlock = (message.content || []).find((block) => block.type === 'text');
      if (!textBlock) {
        logger.error('daily summary returned no text block', { stop: message.stop_reason });
        return response.status(502).json({ error: 'the model returned nothing to show' });
      }

      const summary = normalizeSummaryContent(JSON.parse(textBlock.text));

      logger.info('daily summary generated', {
        tone: summaryRequest.tone,
        completed: summaryRequest.completedTasks.length,
        wins: summary.dopamineWins.length,
        model: message.model,
        inputTokens: message.usage?.input_tokens,
        outputTokens: message.usage?.output_tokens,
      });

      return response.status(200).json({ success: true, source: message.model, summary });
    } catch (error) {
      logger.error('daily summary failed', error);
      return response.status(502).json({ error: 'could not generate the summary' });
    }
  },
);

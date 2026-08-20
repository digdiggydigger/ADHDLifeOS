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

const CAPTURE_SECRET = defineSecret('CAPTURE_SECRET');
const CAPTURE_UID = defineString('CAPTURE_UID');

admin.initializeApp();

/** Base64 inflates by ~33%, so cap the decoded size well inside the 32MB request limit. */
const MAX_MEDIA_BYTES = 20 * 1024 * 1024;

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

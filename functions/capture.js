'use strict';

/**
 * The pure half of the capture endpoint: payload validation and the Firestore document mapping.
 *
 * Split out of `index.js` and free of any Firebase import so it can be unit-tested with plain
 * `node --test`. The document shape is the ONLY contract between this function and the iOS app —
 * `Capture` (ADHD LifeOS/Capture/CaptureModels.swift) is decoded straight off the document, so a
 * wrong key name doesn't error, it silently drops the field.
 */

/** Mirrors `CaptureKind` in CaptureModels.swift. */
const KINDS = ['note', 'task', 'link', 'voice', 'photo'];

/** The kinds that carry an uploaded file rather than typed text. */
const MEDIA_KINDS = ['voice', 'photo'];

/** What the app names a media capture when the user typed nothing. */
const MEDIA_FALLBACK_CONTENT = {
  photo: 'Photo capture',
  voice: 'Voice capture',
};

const UUID_PATTERN = /^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$/i;

function isNonEmpty(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

/**
 * The file extension the app would have used, so an object written here is indistinguishable from
 * one the app uploaded. Mirrors `FirebaseManager.fileExtension(for:)` — including its `jpeg` → `jpg`
 * special case and its `bin` fallback.
 */
function fileExtension(contentType) {
  if (!isNonEmpty(contentType)) return 'bin';
  const subtype = contentType.split('/').pop();
  if (!subtype) return 'bin';
  return subtype === 'jpeg' ? 'jpg' : subtype;
}

/**
 * `users/{uid}/captures/{lowercase-uuid}.{ext}` — the same layout `makeUploadTarget` uses, so the
 * account-deletion sweep and the Storage rules both keep working on Shortcut-written media.
 */
function mediaObjectPath(uid, id, contentType) {
  return `users/${uid}/captures/${id.toLowerCase()}.${fileExtension(contentType)}`;
}

/**
 * The permanent download URL shape the Firebase client SDK produces, rebuilt by hand.
 *
 * The Admin SDK's `getSignedUrl` returns an EXPIRING url, which would leave the app with dead image
 * links after a while. Writing a `firebaseStorageDownloadTokens` value and composing this URL gives
 * the same non-expiring form `Storage.reference(withPath:).downloadURL()` returns in the app.
 */
function downloadURL(bucket, objectPath, token) {
  return `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/` +
    `${encodeURIComponent(objectPath)}?alt=media&token=${token}`;
}

/**
 * Validates and normalises what the Shortcut posted.
 *
 * Returns `{ ok: true, value }` or `{ ok: false, error }`; the caller turns a failure into a 400 so
 * the Shortcut surfaces something actionable instead of writing a malformed capture.
 */
function normalizeCapturePayload(body) {
  const payload = body && typeof body === 'object' ? body : {};
  const kind = isNonEmpty(payload.kind) ? payload.kind.trim().toLowerCase() : 'note';

  if (!KINDS.includes(kind)) {
    return { ok: false, error: `kind must be one of ${KINDS.join(', ')}` };
  }

  const isMedia = MEDIA_KINDS.includes(kind);
  const media = payload.media && typeof payload.media === 'object' ? payload.media : null;

  if (isMedia && !isNonEmpty(media && media.data)) {
    return { ok: false, error: `a ${kind} capture needs media.data (base64)` };
  }
  if (!isMedia && media) {
    return { ok: false, error: `a ${kind} capture cannot carry media` };
  }

  // A media capture may legitimately have no words — the picture IS the capture — so it falls back
  // to the same wording the app uses. A text capture with no content is just an empty capture.
  const rawContent = isNonEmpty(payload.content) ? payload.content.trim() : '';
  const content = rawContent || (isMedia ? MEDIA_FALLBACK_CONTENT[kind] : '');
  if (!content) {
    return { ok: false, error: 'content must not be empty' };
  }

  let lifeAreaId;
  if (isNonEmpty(payload.lifeAreaId)) {
    const candidate = payload.lifeAreaId.trim();
    if (!UUID_PATTERN.test(candidate)) {
      return { ok: false, error: 'lifeAreaId must be a UUID' };
    }
    // The app encodes `UUID` uppercase, and Firestore lookups on it are exact-match.
    lifeAreaId = candidate.toUpperCase();
  }

  return {
    ok: true,
    value: {
      kind,
      content,
      title: isNonEmpty(payload.title) ? payload.title.trim() : undefined,
      lifeAreaId,
      media: isMedia
        ? {
            data: media.data,
            contentType: isNonEmpty(media.contentType)
              ? media.contentType.trim()
              : kind === 'photo' ? 'image/jpeg' : 'audio/m4a',
          }
        : undefined,
    },
  };
}

/**
 * The Firestore document, keyed exactly as `Capture`'s `CodingKeys` expect.
 *
 * The trap worth stating plainly: **only `created_at` is snake_cased.** `lifeAreaId`, `mediaURL` and
 * `mediaContentType` stay camelCase, because that is what the Swift synthesis produces. Optional
 * fields are OMITTED rather than written as null, matching the app's own encoder (Swift's synthesized
 * `encode(to:)` uses `encodeIfPresent` for optionals).
 *
 * `id` is stored as well as being the document name, and the two must stay identical: the app
 * addresses a capture for `markProcessed` by the id it decoded out of the document body.
 */
function buildCaptureDocument({ id, content, kind, createdAt, title, lifeAreaId, mediaURL, mediaContentType }) {
  const doc = {
    id,
    content,
    kind,
    processed: false,
    status: 'inbox',
    created_at: createdAt,
  };
  if (isNonEmpty(title)) doc.title = title.trim();
  if (isNonEmpty(lifeAreaId)) doc.lifeAreaId = lifeAreaId;
  if (isNonEmpty(mediaURL)) doc.mediaURL = mediaURL;
  if (isNonEmpty(mediaContentType)) doc.mediaContentType = mediaContentType;
  return doc;
}

/**
 * Constant-time-ish comparison for the shared secret, so a caller can't narrow it down by timing
 * the response. Length is compared first because an early return on length alone leaks nothing
 * useful about the secret's content.
 */
function secretMatches(provided, expected) {
  if (typeof provided !== 'string' || typeof expected !== 'string') return false;
  if (provided.length !== expected.length) return false;
  let mismatch = 0;
  for (let i = 0; i < provided.length; i += 1) {
    mismatch |= provided.charCodeAt(i) ^ expected.charCodeAt(i);
  }
  return mismatch === 0;
}

module.exports = {
  KINDS,
  MEDIA_KINDS,
  buildCaptureDocument,
  downloadURL,
  fileExtension,
  mediaObjectPath,
  normalizeCapturePayload,
  secretMatches,
};

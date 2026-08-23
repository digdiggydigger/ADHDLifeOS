'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const {
  KINDS,
  buildCaptureDocument,
  downloadURL,
  fileExtension,
  mediaObjectPath,
  normalizeCapturePayload,
  secretMatches,
} = require('../capture');

const ID = '11111111-2222-3333-4444-555555555555';
const UID = 'xcKeMrUiFoZRGQOEUMNW8y6aXmc2';
const STAMP = new Date('2026-08-20T21:00:00Z');

// ---------------------------------------------------------------- document shape
// This is the contract with the iOS app. `Capture` is decoded straight off the document, so a wrong
// key doesn't throw — it silently drops the field and the app shows a capture with a hole in it.

test('notes are trimmed and carried through', () => {
  const result = normalizeCapturePayload({ kind: 'link', content: 'https://example.com', notes: '  Read later  ' });

  assert.equal(result.ok, true);
  assert.equal(result.value.notes, 'Read later');
});

test('empty or missing notes are omitted from the payload and the document', () => {
  assert.equal(normalizeCapturePayload({ kind: 'note', content: 'x', notes: '   ' }).value.notes, undefined);
  assert.equal(normalizeCapturePayload({ kind: 'note', content: 'x' }).value.notes, undefined);

  const doc = buildCaptureDocument({ id: ID, content: 'x', kind: 'note', createdAt: STAMP, notes: '' });
  assert.equal('notes' in doc, false, 'an empty note must not become an empty-string field');
});

test('notes land on the document under the key the app decodes', () => {
  const doc = buildCaptureDocument({
    id: ID, content: 'https://example.com', kind: 'link', createdAt: STAMP, notes: 'Read later',
  });

  assert.equal(doc.notes, 'Read later');
});

test('document carries exactly the keys the app decodes', () => {
  const doc = buildCaptureDocument({
    id: ID, content: 'Ring the dentist', kind: 'note', createdAt: STAMP,
  });

  assert.deepEqual(Object.keys(doc).sort(), [
    'content', 'created_at', 'id', 'kind', 'processed', 'status',
  ]);
  assert.equal(doc.processed, false);
  assert.equal(doc.status, 'inbox');
  assert.equal(doc.created_at, STAMP);
});

test('only created_at is snake_cased — the others stay camelCase', () => {
  const doc = buildCaptureDocument({
    id: ID,
    content: 'Photo capture',
    kind: 'photo',
    createdAt: STAMP,
    lifeAreaId: 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE',
    mediaURL: 'https://example.com/x.jpg',
    mediaContentType: 'image/jpeg',
  });

  assert.ok('created_at' in doc, 'createdAt is the one snake_case key');
  assert.ok('lifeAreaId' in doc, 'life_area_id would be silently dropped by the app');
  assert.ok('mediaURL' in doc, 'media_url would be silently dropped by the app');
  assert.ok('mediaContentType' in doc);
});

test('absent optionals are omitted, not written as null', () => {
  const doc = buildCaptureDocument({ id: ID, content: 'x', kind: 'note', createdAt: STAMP });

  assert.ok(!('title' in doc));
  assert.ok(!('lifeAreaId' in doc));
  assert.ok(!('mediaURL' in doc));
  assert.ok(!('mediaContentType' in doc));
});

// ---------------------------------------------------------------- payload validation

test('a bare note payload normalises', () => {
  const result = normalizeCapturePayload({ kind: 'note', content: '  Ring the dentist  ' });

  assert.equal(result.ok, true);
  assert.equal(result.value.kind, 'note');
  assert.equal(result.value.content, 'Ring the dentist');
  assert.equal(result.value.media, undefined);
});

test('kind defaults to note when the Shortcut omits it', () => {
  assert.equal(normalizeCapturePayload({ content: 'x' }).value.kind, 'note');
});

test('kind is case-insensitive but must be a real kind', () => {
  assert.equal(normalizeCapturePayload({ kind: 'PHOTO', content: 'x', media: { data: 'AA' } }).value.kind, 'photo');
  assert.equal(normalizeCapturePayload({ kind: 'thought', content: 'x' }).ok, false);
});

test('every documented kind is accepted', () => {
  for (const kind of KINDS) {
    const media = kind === 'photo' || kind === 'voice' ? { data: 'AA' } : undefined;
    assert.equal(normalizeCapturePayload({ kind, content: 'x', media }).ok, true, kind);
  }
});

test('an empty text capture is rejected rather than written empty', () => {
  const result = normalizeCapturePayload({ kind: 'note', content: '   ' });

  assert.equal(result.ok, false);
  assert.match(result.error, /content/);
});

test('a media capture with no words falls back to the wording the app uses', () => {
  // The picture IS the capture — this is not an empty capture.
  assert.equal(
    normalizeCapturePayload({ kind: 'photo', media: { data: 'AA' } }).value.content,
    'Photo capture',
  );
  assert.equal(
    normalizeCapturePayload({ kind: 'voice', media: { data: 'AA' } }).value.content,
    'Voice capture',
  );
});

test('a media capture without a file is rejected', () => {
  const result = normalizeCapturePayload({ kind: 'photo', content: 'A view' });

  assert.equal(result.ok, false);
  assert.match(result.error, /media\.data/);
});

test('a text capture carrying a file is rejected rather than silently dropping it', () => {
  const result = normalizeCapturePayload({ kind: 'note', content: 'x', media: { data: 'AA' } });

  assert.equal(result.ok, false);
});

test('media content type defaults per kind', () => {
  assert.equal(normalizeCapturePayload({ kind: 'photo', media: { data: 'AA' } }).value.media.contentType, 'image/jpeg');
  assert.equal(normalizeCapturePayload({ kind: 'voice', media: { data: 'AA' } }).value.media.contentType, 'audio/m4a');
});

test('lifeAreaId is uppercased, because the app encodes UUIDs uppercase', () => {
  const result = normalizeCapturePayload({
    content: 'x', lifeAreaId: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
  });

  assert.equal(result.value.lifeAreaId, 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE');
});

test('a lifeAreaId that is not a UUID is rejected', () => {
  assert.equal(normalizeCapturePayload({ content: 'x', lifeAreaId: 'Growth' }).ok, false);
});

test('a junk body is rejected, not crashed on', () => {
  assert.equal(normalizeCapturePayload(null).ok, false);
  assert.equal(normalizeCapturePayload('nope').ok, false);
  assert.equal(normalizeCapturePayload(undefined).ok, false);
});

// ---------------------------------------------------------------- storage

test('file extension matches the app, including its jpeg special case', () => {
  assert.equal(fileExtension('image/jpeg'), 'jpg');
  assert.equal(fileExtension('image/png'), 'png');
  assert.equal(fileExtension('audio/m4a'), 'm4a');
  assert.equal(fileExtension(''), 'bin');
  assert.equal(fileExtension(undefined), 'bin');
});

test('media path matches the layout the app writes to', () => {
  // Lowercase uuid under the signed-in user, exactly like `makeUploadTarget`, so the
  // account-deletion sweep and the Storage rules keep working on Shortcut-written media.
  assert.equal(
    mediaObjectPath(UID, ID, 'image/jpeg'),
    `users/${UID}/captures/11111111-2222-3333-4444-555555555555.jpg`,
  );
});

test('download URL is the permanent client-SDK form, with the path encoded', () => {
  const url = downloadURL('adhdlifeos-acb49.firebasestorage.app', `users/${UID}/captures/a.jpg`, 'tok');

  assert.ok(url.startsWith('https://firebasestorage.googleapis.com/v0/b/adhdlifeos-acb49.firebasestorage.app/o/'));
  assert.ok(url.includes('%2F'), 'slashes must be encoded or Storage 404s');
  assert.ok(url.endsWith('?alt=media&token=tok'));
});

// ---------------------------------------------------------------- auth

test('the shared secret matches only itself', () => {
  assert.equal(secretMatches('s3cret', 's3cret'), true);
  assert.equal(secretMatches('s3cret', 's3creT'), false);
  assert.equal(secretMatches('s3cret', 's3cret '), false);
  assert.equal(secretMatches('', ''), true);
});

test('a missing or non-string secret never matches', () => {
  assert.equal(secretMatches(undefined, 's3cret'), false);
  assert.equal(secretMatches(null, 's3cret'), false);
  assert.equal(secretMatches('s3cret', undefined), false);
});

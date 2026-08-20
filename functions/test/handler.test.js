'use strict';

/**
 * Exercises the real exported handler for everything that happens BEFORE Firebase is touched:
 * method rejection, the shared-secret gate, and payload validation. Those three are the whole
 * attack surface of this endpoint, and none of them needs credentials to test.
 *
 * The success path is not covered here — it writes to Firestore and Storage, so it is verified
 * against the real project after deployment rather than mocked into a shape that proves nothing.
 */

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || 'adhdlifeos-acb49';
process.env.CAPTURE_SECRET = 'test-secret';
process.env.CAPTURE_UID = 'test-uid';

const test = require('node:test');
const assert = require('node:assert/strict');

const { capture } = require('../index');

/**
 * Minimal Express-shaped response. `on`/`finish` are required because firebase-functions' v2
 * `onRequest` wrapper awaits the response stream finishing before it resolves.
 */
function mockResponse() {
  const listeners = {};
  const res = {
    statusCode: null,
    body: null,
    headers: {},
    on(event, handler) { (listeners[event] ||= []).push(handler); return this; },
    emit(event) { (listeners[event] || []).forEach((handler) => handler()); },
    set(key, value) { this.headers[key] = value; return this; },
    status(code) { this.statusCode = code; return this; },
    json(payload) { this.body = payload; this.emit('finish'); return this; },
    send(payload) { this.body = payload; this.emit('finish'); return this; },
  };
  return res;
}

/** Pass `key: null` for "the header is absent" — `undefined` would silently take the default. */
function mockRequest({ method = 'POST', key = 'test-secret', body = {} } = {}) {
  return {
    method,
    body,
    headers: {},
    get(name) {
      if (name.toLowerCase() !== 'x-lifeos-key') return undefined;
      return key === null ? undefined : key;
    },
  };
}

async function invoke(req) {
  const res = mockResponse();
  await capture(req, res);
  return res;
}

test('a GET is refused with the allowed method named', async () => {
  const res = await invoke(mockRequest({ method: 'GET' }));

  assert.equal(res.statusCode, 405);
  assert.equal(res.headers.Allow, 'POST');
});

test('a missing key is unauthorized', async () => {
  const res = await invoke(mockRequest({ key: null }));

  assert.equal(res.statusCode, 401);
});

test('a wrong key is unauthorized', async () => {
  const res = await invoke(mockRequest({ key: 'not-the-secret' }));

  assert.equal(res.statusCode, 401);
});

test('auth is checked before the payload, so an anonymous caller learns nothing', async () => {
  // Deliberately invalid payload AND a bad key: the response must be the auth failure, not a
  // helpful validation message that would let someone probe the endpoint's shape.
  const res = await invoke(mockRequest({ key: 'wrong', body: { kind: 'nonsense' } }));

  assert.equal(res.statusCode, 401);
  assert.equal(res.body.error, 'unauthorized');
});

test('an authorised but invalid payload is a 400 that says what is wrong', async () => {
  const res = await invoke(mockRequest({ body: { kind: 'thought', content: 'x' } }));

  assert.equal(res.statusCode, 400);
  assert.match(res.body.error, /kind must be one of/);
});

test('an empty capture is refused', async () => {
  const res = await invoke(mockRequest({ body: { kind: 'note', content: '   ' } }));

  assert.equal(res.statusCode, 400);
});

test('a photo with no file is refused before any upload is attempted', async () => {
  const res = await invoke(mockRequest({ body: { kind: 'photo' } }));

  assert.equal(res.statusCode, 400);
  assert.match(res.body.error, /media\.data/);
});

/**
 * The one that matters most. `secretMatches('', '')` is legitimately true — two empty strings ARE
 * equal — so a deploy that forgot to set CAPTURE_SECRET would have accepted anyone who simply left
 * the header off. Caught by this suite before it ever shipped; the endpoint now fails closed.
 */
test('an unconfigured secret refuses everyone instead of admitting everyone', async () => {
  const saved = process.env.CAPTURE_SECRET;
  process.env.CAPTURE_SECRET = '';
  try {
    const noHeader = await invoke(mockRequest({ key: null }));
    assert.equal(noHeader.statusCode, 500, 'an omitted key must not sail through an empty secret');

    const anyHeader = await invoke(mockRequest({ key: 'anything' }));
    assert.equal(anyHeader.statusCode, 500);
  } finally {
    process.env.CAPTURE_SECRET = saved;
  }
});

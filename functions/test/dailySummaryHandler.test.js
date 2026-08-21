'use strict';

/**
 * Exercises the real exported `dailySummary` handler for everything reachable BEFORE Firebase is
 * touched: method rejection and the ID-token gate.
 *
 * That is a smaller surface than `handler.test.js` covers for `capture`, and deliberately so.
 * `capture` authenticates with a shared secret — pure string comparison, testable in-process — so
 * its payload validation is reachable without credentials. This endpoint verifies a Firebase ID
 * token first, which needs Admin credentials, so nothing past the gate is reachable here. Payload
 * validation is covered directly against the pure module in `dailySummary.test.js`, and the
 * success path is verified against the deployed function with a real token.
 *
 * Auth-before-payload is the point, not an inconvenience: an unauthenticated caller must not be
 * able to probe the request shape.
 */

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || 'adhdlifeos-acb49';
process.env.ANTHROPIC_API_KEY = process.env.ANTHROPIC_API_KEY || 'sk-ant-test-placeholder';

const test = require('node:test');
const assert = require('node:assert/strict');

const { dailySummary } = require('../index');

function mockResponse() {
  const listeners = {};
  return {
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
}

/** Pass `auth: null` for "the header is absent". */
function mockRequest({ method = 'POST', auth = null, body = {} } = {}) {
  return {
    method,
    body,
    get(name) {
      if (name.toLowerCase() === 'authorization') return auth === null ? undefined : auth;
      return undefined;
    },
  };
}

test('a non-POST is refused and advertises the allowed method', async () => {
  const res = mockResponse();
  await dailySummary(mockRequest({ method: 'GET' }), res);
  assert.equal(res.statusCode, 405);
  assert.equal(res.headers.Allow, 'POST');
});

test('a request with no Authorization header is unauthorized', async () => {
  const res = mockResponse();
  await dailySummary(mockRequest({ auth: null }), res);
  assert.equal(res.statusCode, 401);
  assert.deepEqual(res.body, { error: 'unauthorized' });
});

test('a non-Bearer Authorization scheme is unauthorized', async () => {
  for (const auth of ['Basic abc123', 'token abc123', 'abc123', 'Bearer', 'Bearer    ']) {
    const res = mockResponse();
    await dailySummary(mockRequest({ auth }), res);
    assert.equal(res.statusCode, 401, `accepted ${JSON.stringify(auth)}`);
  }
});

/**
 * The gate runs before the body is looked at: a caller with no token gets the same 401 whether the
 * payload is well-formed or garbage, so it reveals nothing about what the endpoint expects.
 */
test('auth is checked before the payload, so an anonymous caller learns nothing', async () => {
  const wellFormed = mockResponse();
  await dailySummary(
    mockRequest({ auth: null, body: { tone: 'energizing', completedTasks: [] } }),
    wellFormed
  );

  const garbage = mockResponse();
  await dailySummary(mockRequest({ auth: null, body: { tone: 'not-a-tone' } }), garbage);

  assert.equal(wellFormed.statusCode, 401);
  assert.deepEqual(wellFormed.body, garbage.body);
});

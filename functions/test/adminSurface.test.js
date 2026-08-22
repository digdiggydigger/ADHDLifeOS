'use strict';

/**
 * Guards the Firebase Admin surface `index.js` actually calls.
 *
 * This file exists because of a specific near-miss (2026-08-22). firebase-admin v14 deleted the
 * legacy `admin.firestore()` / `admin.auth()` / `admin.storage()` namespace, which this codebase
 * used everywhere. After the upgrade, every one of those properties was `undefined` and each
 * handler would have thrown a TypeError on its first real request — and **the whole suite still
 * passed, 51/51**. It passed because `admin.initializeApp` survived on the root (so the module
 * loaded) and because the handler tests deliberately stop at the auth/secret gate, which is before
 * anything Firebase is touched.
 *
 * So a green suite proved nothing about the calls that matter. These assertions are the cheap part
 * of the answer: they need no credentials and no network, but they fail loudly if the SDK moves or
 * removes a handle `index.js` depends on. The expensive part — that the calls actually WRITE
 * correctly — is still only provable against the deployed project (see README).
 */

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || 'adhdlifeos-acb49';
process.env.CAPTURE_SECRET = process.env.CAPTURE_SECRET || 'test-secret';
process.env.CAPTURE_UID = process.env.CAPTURE_UID || 'test-uid';

const test = require('node:test');
const assert = require('node:assert/strict');

// Initialises the Firebase app as a side effect, which the getters below require.
require('../index');

const admin = require('firebase-admin');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');

test('the legacy namespace is gone, so namespace-style calls must never come back', () => {
  // Not a style preference — these are `undefined` as of v14, and reading through them throws.
  for (const removed of ['firestore', 'auth', 'storage', 'messaging', 'database']) {
    assert.equal(
      admin[removed], undefined,
      `admin.${removed} exists again — the namespace assumptions in this file need revisiting`,
    );
  }
});

test('index.js does not reach for a removed namespace service', () => {
  // The assertion above proves the namespace is gone from the SDK; this one proves this codebase
  // stopped asking for it. It is deliberately a source check: the offending call sites live inside
  // handler branches that need credentials to reach, so nothing executable catches them, which is
  // precisely how a 51/51 green suite hid the breakage in the first place.
  const source = require('node:fs').readFileSync(require.resolve('../index.js'), 'utf8');
  const offenders = source
    .split('\n')
    .map((line, index) => [index + 1, line])
    .filter(([, line]) => !line.trim().startsWith('//'))
    .filter(([, line]) => /\badmin\s*\.\s*(firestore|auth|storage|messaging|database)\b/.test(line));

  assert.deepEqual(
    offenders, [],
    'namespace-style admin calls found — these are undefined in v14 and throw at request time',
  );
});

test('a Firestore handle exposes the collection path capture writes through', () => {
  const firestore = getFirestore();
  assert.equal(typeof firestore.collection, 'function');
  // The exact chain `capture` uses: users/{uid}/captures/{id}
  const doc = firestore.collection('users').doc('uid').collection('captures').doc('id');
  assert.equal(typeof doc.set, 'function');
});

test('Timestamp.now() produces the value stamped onto every capture', () => {
  const stamp = Timestamp.now();
  assert.equal(typeof stamp.toDate, 'function');
  assert.ok(stamp.toDate() instanceof Date);
});

test('an Auth handle exposes the ID-token verification dailySummary gates on', () => {
  assert.equal(typeof getAuth().verifyIdToken, 'function');
});

test('a Storage handle exposes the bucket accessor media captures upload through', () => {
  // `.bucket()` itself is not called: it needs a configured bucket, which is deployment
  // configuration rather than anything this rewrite can get wrong.
  assert.equal(typeof getStorage().bucket, 'function');
});

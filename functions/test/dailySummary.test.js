'use strict';

const test = require('node:test');
const assert = require('node:assert');

const {
  SUMMARY_SCHEMA,
  buildPrompt,
  normalizeSummaryContent,
  normalizeSummaryRequest,
  toneGuidance,
} = require('../dailySummary');

/** The exact payload `DailySummaryRequest` encodes on the Swift side. */
function validBody(overrides = {}) {
  return {
    date: '2026-08-21T17:00:00Z',
    tone: 'energizing',
    focusMinutesTotal: 26,
    capturesCount: 6,
    completedTasks: [
      { title: 'Ship the capture fix', lifeAreaName: 'Growth', priority: 'p1', focusMinutesLogged: 15 },
    ],
    inProgressTasks: [{ title: 'Draft the prompt', lifeAreaName: 'Growth' }],
    journalEntries: [
      { body: 'Felt scattered but got there.', lifeAreaName: 'Health', energyLevel: 'low', moodEmoji: '😮‍💨' },
    ],
    ...overrides,
  };
}

test('a valid payload is accepted and normalised', () => {
  const result = normalizeSummaryRequest(validBody());
  assert.strictEqual(result.ok, true);
  assert.strictEqual(result.value.tone, 'energizing');
  assert.strictEqual(result.value.completedTasks.length, 1);
  assert.strictEqual(result.value.focusMinutesTotal, 26);
});

test('tone defaults to energizing when absent, and is rejected when unknown', () => {
  assert.strictEqual(normalizeSummaryRequest(validBody({ tone: undefined })).value.tone, 'energizing');

  const bad = normalizeSummaryRequest(validBody({ tone: 'sarcastic' }));
  assert.strictEqual(bad.ok, false);
  assert.match(bad.error, /tone/);
});

test('a non-object body is refused rather than treated as an empty day', () => {
  for (const body of [null, undefined, 'string', 42, []]) {
    assert.strictEqual(normalizeSummaryRequest(body).ok, false, `accepted ${JSON.stringify(body)}`);
  }
});

test('counts must be non-negative integers', () => {
  assert.strictEqual(normalizeSummaryRequest(validBody({ focusMinutesTotal: -1 })).ok, false);
  assert.strictEqual(normalizeSummaryRequest(validBody({ capturesCount: 1.5 })).ok, false);
  assert.strictEqual(normalizeSummaryRequest(validBody({ focusMinutesTotal: 'lots' })).ok, false);
});

test('missing list fields normalise to empty arrays rather than throwing', () => {
  const result = normalizeSummaryRequest({ date: '2026-08-21T17:00:00Z', tone: 'gentle' });
  assert.strictEqual(result.ok, true);
  assert.deepStrictEqual(result.value.completedTasks, []);
  assert.deepStrictEqual(result.value.inProgressTasks, []);
  assert.deepStrictEqual(result.value.journalEntries, []);
  assert.strictEqual(result.value.focusMinutesTotal, 0);
});

test('entries missing a title or body are dropped, not sent as blanks', () => {
  const result = normalizeSummaryRequest(validBody({
    completedTasks: [{ title: '  ', lifeAreaName: 'X' }, { title: 'Real', lifeAreaName: 'X' }],
    journalEntries: [{ body: '' }, { body: 'Real entry' }],
  }));
  assert.deepStrictEqual(result.value.completedTasks.map((t) => t.title), ['Real']);
  assert.deepStrictEqual(result.value.journalEntries.map((j) => j.body), ['Real entry']);
});

/**
 * The prompt is capped so a pathological day (hundreds of completions) can't blow up cost or
 * push the real content out of the model's attention.
 */
test('oversized lists are truncated', () => {
  const many = Array.from({ length: 200 }, (_, i) => ({ title: `task ${i}`, lifeAreaName: 'X' }));
  const result = normalizeSummaryRequest(validBody({ completedTasks: many, inProgressTasks: many }));
  assert.ok(result.value.completedTasks.length <= 50, 'completed not truncated');
  assert.ok(result.value.inProgressTasks.length <= 20, 'in-progress not truncated');
});

test('each tone produces distinct guidance the prompt can carry', () => {
  const guidance = ['energizing', 'gentle', 'coaching', 'bulleted'].map(toneGuidance);
  assert.strictEqual(new Set(guidance).size, 4);
  for (const text of guidance) assert.ok(text.length > 0);
});

test('the prompt names the real work rather than describing it abstractly', () => {
  const { system, user } = buildPrompt(normalizeSummaryRequest(validBody()).value);
  assert.match(system, /ADHD/i);
  assert.ok(user.includes('Ship the capture fix'), 'completed task missing from prompt');
  assert.ok(user.includes('Draft the prompt'), 'in-progress task missing from prompt');
  assert.ok(user.includes('Felt scattered'), 'journal entry missing from prompt');
  assert.ok(user.includes('26'), 'focus minutes missing from prompt');
});

/**
 * An empty day must be stated as empty in the prompt. Left implicit, the model fills the silence
 * with invented wins — the exact failure the on-device synthesis was written to avoid.
 */
test('an empty day is stated explicitly so the model cannot invent wins', () => {
  const empty = normalizeSummaryRequest({ date: '2026-08-21T17:00:00Z', tone: 'gentle' }).value;
  const { system, user } = buildPrompt(empty);
  assert.match(`${system}\n${user}`, /nothing|none|no tasks|no completed/i);
});

test('the schema pins exactly the five fields the app renders', () => {
  assert.deepStrictEqual(
    Object.keys(SUMMARY_SCHEMA.properties).sort(),
    ['dopamineWins', 'focusStaminaInsight', 'gentleTomorrowKickstart', 'headline', 'journalReflections']
  );
  assert.strictEqual(SUMMARY_SCHEMA.additionalProperties, false);
  assert.strictEqual(SUMMARY_SCHEMA.required.length, 5);
});

test('a well-formed model result passes through intact', () => {
  const raw = {
    headline: 'One finished today.',
    dopamineWins: ['Shipped the capture fix.'],
    journalReflections: 'You noted feeling scattered.',
    focusStaminaInsight: '26 minutes of focus.',
    gentleTomorrowKickstart: ['Start with the prompt draft.'],
  };
  assert.deepStrictEqual(normalizeSummaryContent(raw), raw);
});

test('blank and non-string list entries are stripped from the model result', () => {
  const cleaned = normalizeSummaryContent({
    headline: '  Trimmed  ',
    dopamineWins: ['good', '', '   ', null, 42, 'also good'],
    journalReflections: 'r',
    focusStaminaInsight: 'f',
    gentleTomorrowKickstart: [],
  });
  assert.strictEqual(cleaned.headline, 'Trimmed');
  assert.deepStrictEqual(cleaned.dopamineWins, ['good', 'also good']);
  assert.deepStrictEqual(cleaned.gentleTomorrowKickstart, []);
});

/**
 * Structured outputs make a malformed shape unlikely, not impossible — a refusal or a truncated
 * response can still reach here, and the app decodes this straight off the wire.
 */
test('a malformed model result is rejected rather than half-rendered', () => {
  for (const raw of [null, undefined, 'text', {}, { headline: 'only this' }]) {
    assert.throws(() => normalizeSummaryContent(raw), /summary/i, `accepted ${JSON.stringify(raw)}`);
  }
});

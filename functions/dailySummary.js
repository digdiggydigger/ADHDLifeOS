'use strict';

/**
 * The pure half of the daily-summary endpoint: payload validation, prompt construction, the
 * structured-output schema, and result normalisation.
 *
 * Free of any Firebase or Anthropic import so it can be unit-tested with plain `node --test` —
 * same split as `capture.js`. The five-field summary shape is the ONLY contract between this
 * function and the iOS app: `DailySummaryContent` (ADHD LifeOS/Home/DailySummaryModels.swift) is
 * decoded straight off the response, so a wrong key name doesn't error, it silently drops.
 */

/** Mirrors `DailySummaryTone` in DailySummaryModels.swift. */
const TONES = ['energizing', 'gentle', 'coaching', 'bulleted'];

/**
 * Prompt caps. A pathological day — or a bug upstream — must not turn into an unbounded prompt:
 * cost scales with it, and the genuinely important items get buried among the rest.
 */
const MAX_COMPLETED = 50;
const MAX_IN_PROGRESS = 20;
const MAX_JOURNAL = 20;
/** Long enough for a real journal entry, short enough that one entry can't dominate the prompt. */
const MAX_TEXT_CHARS = 2000;

function isNonEmpty(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function trimmed(value, fallback = '') {
  return isNonEmpty(value) ? value.trim().slice(0, MAX_TEXT_CHARS) : fallback;
}

function isCount(value) {
  return typeof value === 'number' && Number.isInteger(value) && value >= 0;
}

/** What an unassigned task or entry is called. Matches the app's own fallback. */
const UNASSIGNED = 'General';

/**
 * Validates and normalises what the app posted.
 *
 * Deliberately lenient about *absent* lists (an empty day is a real day) and strict about
 * *malformed* ones (a string where a count belongs means the caller is broken, and guessing would
 * hide it).
 */
function normalizeSummaryRequest(body) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    return { ok: false, error: 'body must be a JSON object' };
  }

  const tone = body.tone === undefined || body.tone === null ? 'energizing' : body.tone;
  if (!TONES.includes(tone)) {
    return { ok: false, error: `tone must be one of ${TONES.join(', ')}` };
  }

  for (const key of ['focusMinutesTotal', 'capturesCount']) {
    if (body[key] !== undefined && body[key] !== null && !isCount(body[key])) {
      return { ok: false, error: `${key} must be a non-negative integer` };
    }
  }

  const list = (value) => (Array.isArray(value) ? value : []);

  const completedTasks = list(body.completedTasks)
    .filter((task) => task && isNonEmpty(task.title))
    .slice(0, MAX_COMPLETED)
    .map((task) => ({
      title: trimmed(task.title),
      lifeAreaName: trimmed(task.lifeAreaName, UNASSIGNED),
      priority: isNonEmpty(task.priority) ? task.priority.trim() : null,
      focusMinutesLogged: isCount(task.focusMinutesLogged) ? task.focusMinutesLogged : 0,
    }));

  const inProgressTasks = list(body.inProgressTasks)
    .filter((task) => task && isNonEmpty(task.title))
    .slice(0, MAX_IN_PROGRESS)
    .map((task) => ({
      title: trimmed(task.title),
      lifeAreaName: trimmed(task.lifeAreaName, UNASSIGNED),
    }));

  const journalEntries = list(body.journalEntries)
    .filter((entry) => entry && isNonEmpty(entry.body))
    .slice(0, MAX_JOURNAL)
    .map((entry) => ({
      body: trimmed(entry.body),
      lifeAreaName: trimmed(entry.lifeAreaName, UNASSIGNED),
      energyLevel: isNonEmpty(entry.energyLevel) ? entry.energyLevel.trim() : null,
      moodEmoji: isNonEmpty(entry.moodEmoji) ? entry.moodEmoji.trim() : null,
    }));

  return {
    ok: true,
    value: {
      date: trimmed(body.date, new Date().toISOString()),
      tone,
      focusMinutesTotal: isCount(body.focusMinutesTotal) ? body.focusMinutesTotal : 0,
      capturesCount: isCount(body.capturesCount) ? body.capturesCount : 0,
      completedTasks,
      inProgressTasks,
      journalEntries,
    },
  };
}

/** How each tone should sound. Kept as prose, not adjectives, so the model has something to act on. */
function toneGuidance(tone) {
  switch (tone) {
    case 'gentle':
      return 'Warm and low-pressure. Never imply the reader should have done more. A quiet day is '
        + 'an acceptable day, and you say so plainly rather than consoling them about it.';
    case 'coaching':
      return 'Direct and forward-looking. Name what worked, then point at the single next move. '
        + 'Concrete over encouraging — no pep talk, no exclamation marks.';
    case 'bulleted':
      return 'Terse and scannable. Short declarative fragments, no connective prose, no preamble. '
        + 'The reader is skimming.';
    case 'energizing':
    default:
      return 'Upbeat and momentum-focused, but grounded in what actually happened. Celebrate real '
        + 'progress; never manufacture enthusiasm for a day that was quiet.';
  }
}

/**
 * The system prompt.
 *
 * The honesty constraints are the load-bearing part. This summary is read by someone with ADHD at
 * the end of a day, and a fabricated win is worse than no summary: it teaches them the feature
 * lies, and it distorts the one honest record they have of their own day.
 */
function systemPrompt(tone) {
  return [
    'You write a short end-of-day summary for the ADHD LifeOS app. The reader has ADHD and is '
      + 'reviewing their own day.',
    '',
    'Rules, in priority order:',
    '1. Only state things present in the data you are given. Never invent a task, a feeling, or a '
      + 'number. If a section has no material, say so plainly in one short sentence.',
    '2. Do not pad. An empty day gets a short summary, not a long one about nothing.',
    '3. Refer to completed work by its actual title. Do not generalise it into a category.',
    '4. Address the reader as "you". No third person, no clinical framing, no diagnosis talk.',
    '5. No emoji unless the data contains one (a journal mood emoji may be echoed).',
    '',
    `Tone: ${toneGuidance(tone)}`,
    '',
    'dopamineWins holds one entry per genuinely completed task — an empty array when nothing was '
      + 'completed. gentleTomorrowKickstart holds at most three concrete next actions drawn from '
      + 'open work; prefer the smallest viable first step over the most important task.',
  ].join('\n');
}

/**
 * The user turn: today's material, stated flatly.
 *
 * Empty sections are spelled out ("None.") rather than omitted. An omitted section reads to the
 * model as an oversight it should fill in; an explicit "None." reads as a fact to report.
 */
function userPrompt(request) {
  const lines = [`Date: ${request.date}`, ''];

  lines.push('Tasks completed today:');
  if (request.completedTasks.length === 0) {
    lines.push('  None. Nothing was completed today.');
  } else {
    for (const task of request.completedTasks) {
      const focus = task.focusMinutesLogged > 0 ? `, ${task.focusMinutesLogged}m focused` : '';
      const priority = task.priority ? `, ${task.priority}` : '';
      lines.push(`  - ${task.title} (${task.lifeAreaName}${priority}${focus})`);
    }
  }

  lines.push('', 'Still open:');
  if (request.inProgressTasks.length === 0) {
    lines.push('  None.');
  } else {
    for (const task of request.inProgressTasks) {
      lines.push(`  - ${task.title} (${task.lifeAreaName})`);
    }
  }

  lines.push('', 'Journal entries today:');
  if (request.journalEntries.length === 0) {
    lines.push('  None. No journal entries were written today.');
  } else {
    for (const entry of request.journalEntries) {
      const energy = entry.energyLevel ? `, energy ${entry.energyLevel}` : '';
      const mood = entry.moodEmoji ? `, mood ${entry.moodEmoji}` : '';
      lines.push(`  - [${entry.lifeAreaName}${energy}${mood}] ${entry.body}`);
    }
  }

  lines.push(
    '',
    `Focus time today: ${request.focusMinutesTotal} minutes.`,
    `Untriaged captures in the inbox: ${request.capturesCount}.`
  );

  return lines.join('\n');
}

function buildPrompt(request) {
  return { system: systemPrompt(request.tone), user: userPrompt(request) };
}

/**
 * The structured-output schema. `additionalProperties: false` plus all five required is what makes
 * the response safe to decode straight into `DailySummaryContent`.
 */
const SUMMARY_SCHEMA = {
  type: 'object',
  properties: {
    headline: { type: 'string', description: 'One sentence naming the shape of the day.' },
    dopamineWins: {
      type: 'array',
      items: { type: 'string' },
      description: 'One entry per completed task. Empty when nothing was completed.',
    },
    journalReflections: {
      type: 'string',
      description: 'What the journal entries say, reflected back. Say so if there were none.',
    },
    focusStaminaInsight: {
      type: 'string',
      description: 'What the focus minutes say. Say so if there were none.',
    },
    gentleTomorrowKickstart: {
      type: 'array',
      items: { type: 'string' },
      description: 'At most three concrete next actions drawn from open work.',
    },
  },
  required: [
    'headline',
    'dopamineWins',
    'journalReflections',
    'focusStaminaInsight',
    'gentleTomorrowKickstart',
  ],
  additionalProperties: false,
};

function cleanList(value) {
  if (!Array.isArray(value)) return [];
  return value.filter(isNonEmpty).map((item) => item.trim());
}

/**
 * Last line of defence before the app decodes this. Structured outputs make a malformed shape
 * unlikely, not impossible — a refusal, a truncation, or a future model change can all land here.
 */
function normalizeSummaryContent(raw) {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
    throw new Error('summary was not an object');
  }
  for (const key of ['headline', 'journalReflections', 'focusStaminaInsight']) {
    if (!isNonEmpty(raw[key])) throw new Error(`summary is missing ${key}`);
  }
  return {
    headline: raw.headline.trim(),
    dopamineWins: cleanList(raw.dopamineWins),
    journalReflections: raw.journalReflections.trim(),
    focusStaminaInsight: raw.focusStaminaInsight.trim(),
    gentleTomorrowKickstart: cleanList(raw.gentleTomorrowKickstart),
  };
}

/**
 * Turns a failed model call into something the card can show.
 *
 * The split is by who can act on it. A 4xx is a configuration or account problem the reader can
 * actually fix — no credits, a revoked key, a rate limit — so it carries the API's own wording. A
 * 5xx is Anthropic's and transient, so it says "try again" rather than exposing internals. Anything
 * else is a bug here, and the reader is told plainly rather than shown a stack.
 *
 * This exists because the first live call failed with "your credit balance is too low" and the
 * card said "could not generate the summary" — sending the reader to debug an app that was working
 * perfectly.
 */
function describeModelError(error) {
  const status = typeof error?.status === 'number' ? error.status : null;
  // The SDK nests the API's own envelope: { error: { error: { type, message } } }.
  const apiMessage = error?.error?.error?.message;

  if (status !== null && status >= 400 && status < 500) {
    if (isNonEmpty(apiMessage)) return apiMessage.trim();
    if (status === 429) return 'Rate limit reached — wait a moment and try again.';
    return `The summary service rejected the request (${status}).`;
  }
  if (status !== null && status >= 500) {
    return 'The model was unavailable. Please try again.';
  }
  return 'Could not generate the summary.';
}

module.exports = {
  MAX_COMPLETED,
  MAX_IN_PROGRESS,
  SUMMARY_SCHEMA,
  TONES,
  buildPrompt,
  describeModelError,
  normalizeSummaryContent,
  normalizeSummaryRequest,
  toneGuidance,
};

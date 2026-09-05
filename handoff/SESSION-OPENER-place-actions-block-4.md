# Session opener — Place Actions arc, Block 4 (written 2026-08-31, end of the block-1→3 session)

Read `claudecode.md`, `CLAUDE.md`, and the **"Place Actions arc"** section of
`TODO-CLAUDE-CODE.md` first, plus auto-memory `place-actions-arc` — that file carries every
settled decision and trap from blocks 1–3. This opener orients and sequences; it does not
replace them.

## State, verified at close

- **Branch `feature/place-actions` at `88e7bb5`**, pushed, tree clean. `main` is at `bca231e`
  and does NOT contain the arc. The branch = spec + three shipped blocks + E's field-pass
  record. Commits: `e5f53a4` spec → `fccb3be` B1 model → `bcd729b` B2 editor → `f177059` B3
  execution → `338005f` duplicate-delivery race fix → `b4fb714` sim-drive record → `0c65ca5`
  tap-attribution fix → `88e7bb5` field record.
- Unit suite **1,965 / 0**; SwiftLint **0 violations in 574 files**; sim + device builds green.
- **Device `wishwashwacky15` carries the branch tip build (installed via cable 2026-08-31
  ~17:20, launch verified)** — i.e. the phone is OFF main until the arc merges.
- Firebase: actions ride the `places` documents — **no rules change, nothing to republish.**

## Where the arc stands

E's spec (settled in chat, in the TODO arc header — do not re-litigate): both-layered
execution, open action catalogue (all kinds "and likely more"), arrival AND departure per
action, list per place, firing rule option 1 with per-action re-fire tuning parked as E's
declared future follow-up.

- **Block 1 (model) ✅, Block 2 (editor) ✅, Block 3 (execution) BUILT and field-passed once
  but NOT ticked.** The tick waits on E's second walk:
  1. **Double-confirm retest.** E's first pass: fences fired on foot (Monzo custom scheme at
     the Bank, Spotify on leaving Home — composing with both custom messages), but the tap
     showed iOS's "LifeOS wants to open Spotify" dialog. `0c65ca5` opens synchronously in the
     delegate callback to keep user-initiated attribution — the installed build carries it.
     If the dialog SURVIVES, it is Apple's cross-app guard: say so honestly, do not chase it.
  2. **In-app auto-run on device** — simulator-proven (journal line written place-stamped from
     a background wake); E can field-confirm by adding a journal-line action to any place.
  When E reports, tick Block 3's field criterion and the block header, commit
  `F-PlaceActions-3: record E's field verdict`, push.

## FIRST TASK: Block 4 — F-PlaceActions-4-Shortcuts

Spec is in the TODO block. The shape:

- **App Intents** ("Start a sprint", "Capture a note", "Log a journal line") so Apple's
  Shortcuts app can drive the in-app actions — that is the layer where "arrive → open app /
  send text" can genuinely run ZERO-touch, using Apple's own location automations instead of
  ours. iOS 16 floor: `AppIntents` framework is iOS 16+, but check each API you use; the app
  target is 16.0 (widget 16.1) and the Places UI is separately 17-gated with E's standing
  authorisation — intents are NOT part of that grant, so gate or floor-check accordingly.
- **"Make this automatic"** — a guided walkthrough row per external action on the place editor,
  opening into Apple's Shortcuts app. Apple allows NO programmatic creation of automations;
  the guide is the honest ceiling and must say which steps are E's.
- Wiring the intents to real work: reuse the seams blocks 1–3 built — `FocusSprintPlan` +
  `PlaceActionSprint.plan` for sprints, `CaptureValidation`/`FirebaseCaptureClientAdapter` for
  captures, `LogValidation`/`FirebaseJournalClientAdapter` for journal lines (stamp via
  `RecordLocationStamp`, the no-per-record-switch path). An intent runs without the UI —
  the same no-screen discipline as `PlaceTriggerEventHandler`.
- Acceptance (from the TODO): intents callable from the Shortcuts app ON DEVICE; guide content
  pure and tested; suite/lint/build; E walks one real automation end-to-end.
- TDD per the house rule; deliberate-regression red-check AFTER committing (E's standing rule);
  every block ends with verified commit+push on the branch.

## After Block 4

Merge the arc: `--no-ff` into `main` (the location-v1 precedent — field-tested first), suite
re-run on main, push, reinstall device from main, update `place-actions-arc` memory +
`TODO-CLAUDE-CODE.md`, and ask E about deleting `feature/place-actions` (and the long-merged
`feature/location-services`, still kept on E's word).

## Traps this session paid for (details in memory `place-actions-arc`)

- **`.sheet(item:)` on a Form `Section` presents per-row and dismissed the whole parent
  sheet** — presentation modifiers hang off ONE concrete view inside the section.
- **iOS delivers one crossing twice within seconds** — the handler's in-flight guard closes
  the race; a test for it only goes red if the fake writers SUSPEND like Firestore.
- **`try?` flattens nested optionals (SE-0230)** — `decodeIfPresent` can't tell absent from
  undecodable; check `container.contains` first.
- **`PlaceEditorValidation.makePlace` REBUILDS the place** — every new Place field must be
  threaded through it and `PlaceEditorView.save()`, or any rename strips it. Test-pinned.
- **Sim drives:** `simctl privacy grant location-always` breaks two unit tests (the hosted
  test target IS the app — reset with `simctl privacy reset location` afterwards); a location
  TELEPORT swallows `didEnter` (simulate a `simctl location start` route instead); notification
  permission needs the app's own prompt (start a sprint once); the Firebase emulator is
  ephemeral and was wiped twice mid-drive; **always launch the sim app with
  `SIMCTL_CHILD_LIFEOS_FIREBASE_EMULATOR_HOST=127.0.0.1`** — one relaunch without it pointed
  at production, and only `FirebaseEmulatorSettings`' resolve-to-off default caught it.

## Session-scale facts

Today, before this arc, the same session also shipped on `main`: `4c0630f` F-ComposerSingleSave
(capture composer's duplicate toolbar Save removed), `4dcb21b` F-JournalComposerLocation (the
per-entry location switch that names the place — E device-approved: "both are working well"),
and `bca231e` recording that verdict. Nothing from main is waiting on review.

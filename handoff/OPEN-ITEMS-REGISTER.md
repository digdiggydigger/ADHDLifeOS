# Open items register — 2026-09-07, SESSION close-out (fifth edition today; the previous four covered the queue-clear, the UI baseline, the permission footer, and the coverage re-measure)

*This edition also carries the handoff: `START-HERE-post-footer.md` archived,
`START-HERE-post-adapter-drift.md` written in the same commit.*

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding — so it is the thing to read, and
to update, rather than improvising a list in chat. Supersedes the four earlier editions.

Every figure below was measured this session unless marked (carried).

## State

**`main` @ `e2e75dc`** at the start of this block (PR #22, the coverage re-measure); F-AdapterDrift
lands on top as PR #23 · local = remote, tree clean, only `main` exists · every change lands
through a PR · **unit suite 2,488 / 0** and **SwiftLint 0 / 710**, both at `9f6381e` with the
emulator UP · **app target 24.68% (11,095/44,961)** · no `127.0.0.1:9099` in any run log — the sim
stayed clean all session · **E's phone TRACKS MAIN at `a3e4bde`**; F-AdapterDrift changed only
TEST files, so **no reinstall is owed** · `firestore.rules` untouched · the emulator was left
running.

**Shipped and CLOSED this session (PRs #22–#23):**

- **The coverage re-measure** (PR #22, `e2e75dc`) — the register's oldest carried A-item, answered
  with a number instead of an estimate. It also disproved four CLAUDE.md claims (adapter coverage,
  two counts, the subcollection list, the view-body figure), all corrected in the same PR.
- **F-AdapterDrift** (PR #23) — the drift that re-measure found, closed the same day. **All four
  adapters are now at 100%**, and none was dead code: every one had live production call sites,
  so these were shipped, reachable, unexercised paths.

```
FirebaseAppDirectoryClientAdapter    0.00% (0/6)     → 100.00% (6/6)
FirebasePlacesClientAdapter         41.67% (5/12)    → 100.00% (12/12)
FirebaseJournalClientAdapter        71.57% (73/102)  → 100.00% (102/102)
FirebaseHomeClientAdapter           80.00% (12/15)   → 100.00% (15/15)
```

  **+19 tests** (2,469 → 2,488), two new recording fakes, **+45 covered lines on an UNCHANGED
  denominator** — 24.58% → 24.68%. Red-checked in two passes, both predicted before running and
  both exact: four deliberate regressions → **exactly 7 failing test cases** (AppDirectory 3,
  Places 2, Home 1, Journal 1), then the `message(for:)` fallback broken → **exactly 1**. Both
  restored with `git checkout --` and proven by a full green rebuild, per the standing rule; no
  `RED-CHECK` marker survives anywhere in the tree.

## A · Decisions only E can make — minutes each

- [ ] **Delete the spent `.xcresult` bundles?** Now **eighteen** sit in the repo root (all
      gitignored): `UIFullRun` (retention condition met), `UIBaseline-1..9`, `GreenLandscape`,
      `SweepLandscape`, `RoutineJourneyEye`, `TestResults`, `UITestResults`, plus this session's
      `Coverage-2026-09-07`, `AdapterDrift`, `CoverageAfterDrift`, `CoverageFinal`. The boot disk
      is at **~17 GB free**. Related trap, and the reason this is worth a minute: **CLAUDE.md's
      documented test command still writes to `TestResults.xcresult`, which already exists**, so
      the next session running it verbatim fails *after* paying for the whole build. Deleting the
      bundles fixes that; so would dating the documented path. I used a dated path rather than
      change the documented command unasked.

## B · Real work, ready to start — recommended order

1. **Arc 2 — first-class routines + the "at a time" trigger.** Not authorised. (carried)
2. **`F-Search-3-Journal`** — recommendation is to kill the block. E's call. (carried)
3. **The Live Activity design review** E parked. (carried)
4. **The widget extension went backwards** — 10.97% → 9.43% (209/2,216): sixteen newly covered
   lines against 457 new executable ones, widget code shipping faster than its tests. It is now
   the worst-covered target in the tree and the only one whose ratio has FALLEN. Smaller and
   lower-value than the adapter work just done, but the same shape, and the same fix.

## C · Parked on E's instruction — do not start unprompted

- **Places backgrounding dismiss bug** — waiting on E's iOS update. (carried)
- **App connections** — real two-way sync; Apple Notes has no iOS API. (carried)
- **LA interactive buttons**, **time-of-day triggers**, **smart skip** — smart skip has its
  data in `routine_runs`. (carried)

## D · Launch blockers — no conversation opened yet

- **Free dev account** → 7-day profiles; the clock restarted with the build of
  **2026-09-07 04:28**, so the profile is roughly valid to **2026-09-14**. (carried — this is an
  absolute date deliberately; it was written the same day and would read as "today" otherwise.)
- **Sign in with Apple** built but dormant. (carried)

## E · Known, not work

- **Two coverage lessons that will recur, both now in CLAUDE.md.** (1) *A fake with no error hook
  makes a `catch` branch untestable, and the report blames the adapter* — `FakeJournalBackingStore`
  had no error property for its three side streams, so the gap was in the double, not the code
  under test. (2) *The last unit in a file is often a partial REGION, not a whole line* — Journal
  sat at 99.02% with ZERO fully-uncovered lines. Read regions with
  `xcrun xccov view --archive --file <path> <bundle>`; **without `--archive` it reports
  "unrecognized file format"**, which reads like a corrupt bundle rather than a missing flag.
- **The "failing tests are slow" oddity is CORROBORATED, no longer a one-off.** The register has
  carried "the 107-second failing test, failure-path only, unexplained" since routine-record block
  1. Both red-checks this session reproduced it: a FAILING assertion took **35s** in one and
  **43s** in the other, while the same suites pass in well under a second. It is the failure path
  specifically, it is not the poisoned-sim symptom (no `9099` in either log), and it is still
  unexplained — but it is now a known, repeatable trait rather than a single sighting. **Budget
  for it when planning a red-check; do not read it as a hang.**
- **The 70% coverage bar is arithmetically out of reach without UI tests.** 108 of the app
  target's 342 measured files sit at exactly 0% — **29,513 lines, 66% of the entire denominator**.
  The largest are `NudgesView` (0/884), `HomeAccessoryStrips` (0/752), `LogComposerView` (0/718),
  `TaskListView` (0/711), `QuickCaptureComponents` (0/677).
- **The emulator harness held its ground**: `+Tags` 97.67%, `+Seed` 98.31%, `+Storage` 95.83%,
  `+AccountDeletion` 90.20% — identical to 2026-08-30, no drift.
- **The watch-list is EMPTY.** (carried)
- **The strong-password pane is environmental** — full story in `UITestAutofill.swift`. (carried)
- **The DEBUG test-fire bypasses the master switch and cooldown BY DESIGN** — its dialog says so;
  `screenshots/routines-permission-footer/README.md` has the worked example. (carried)
- **The live opener is `START-HERE-post-adapter-drift.md`**, written at this close-out on E's
  word. `START-HERE-post-footer.md` was archived into `handoff/archive/` in the SAME commit that
  wrote it, per the rule — exactly one `START-HERE-*` is live in `handoff/`.
- **Twelve `screenshots/` folders without READMEs** — deliberately left. (carried)
- **Stale unchecked bullets inside four finished blocks.** (carried)
- **The emulator was left running** (`scripts/emulators.sh`); `firestore-debug.log` in the repo
  root is the truth for a silently failed write. (carried)

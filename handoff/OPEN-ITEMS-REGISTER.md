# Open items register — 2026-09-07, SESSION close-out (sixth edition today; the previous five covered the queue-clear, the UI baseline, the permission footer, the coverage re-measure, and the adapter drift)

*This edition covers **F-WidgetCoverage (PR #25)**, B4 from the fifth edition's section B — E's
pick, taken directly rather than waiting.*

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding — so it is the thing to read, and
to update, rather than improvising a list in chat. Supersedes the five earlier editions.

Every figure below was measured this session unless marked (carried).

## State

**`main` @ `f39092c`** (PR #25) · local = remote, tree clean, **only `main` exists** (the feature
branch was merged and deleted) · every change lands through a PR · **unit suite 2,497 / 0** and
**SwiftLint 0 / 711**, both at `93beff2` with the emulator UP · **app target 24.72%
(11,114/44,961)** · **widget extension 10.29% (228/2,216) — and 97.9% (228/233) of the surface a
unit test can actually reach**, which is the figure that means something (see below) · no
`127.0.0.1:9099` in any run log; no UI target was run · **E's phone TRACKS MAIN at `a3e4bde`**, and
**no Swift under `ADHD LifeOS/` changed, so no reinstall is owed** · `firestore.rules` untouched ·
the emulator was left running.

**Shipped and CLOSED this session (PR #25):**

- **F-WidgetCoverage** — B4, the widget extension, closed.

```
FocusWidgetSnapshot        101/102 (99.02%)  →  102/102  (100%)
FocusActivityAttributes     71/73  (97.26%)  →   73/73   (100%)
FocusSprintIntents           4/25  (16.00%)  →   20/25   ( 80%)
```

  **+9 tests** (2,488 → 2,497), one new test file, **+19 covered lines on an UNCHANGED
  denominator** — widget 9.43% → 10.29%, app target 24.68% → 24.72% (the five files are members of
  BOTH targets, so widget work moves the app figure too). Red-checked in one pass: committed first,
  five deliberate regressions, **exactly 7 failing test cases predicted before running and exactly
  those 7 by name**. Restored with `git checkout --` and proven by a full green rebuild; no
  `RED-CHECK` marker survives anywhere in the tree.

**The finding is worth more than the +19 lines, and it corrected this register as well as
CLAUDE.md.** Both said the widget target "went BACKWARDS — widget code shipping faster than its
tests". The arithmetic was right and the diagnosis was wrong:

- **Only FIVE of the fourteen widget files are compiled into the app target** (the
  `membershipExceptions` list in `project.pbxproj`), and they are **exactly** the five that have
  ever had non-zero coverage. The unit-test target hosts the APP, so it never compiles the other
  nine at all.
- **The testable surface is 233 lines, not 2,216.** The other 1,983 are widget-only view bodies.
- **The fall was DENOMINATOR, not decay:** `RoutineLiveActivity` (436) + `RoutineActivityAttributes`
  (10) arrived with the routines arc on 2026-09-03 (`534265e`) — ~446 of the 457 new lines. On the
  surface that can actually move, the target was at **89.7%** before this block, not 9.43%.
- **Five lines stay uncovered and that is the floor, not a backlog:** `endAllActivities`' loop body
  needs a real `Activity`, so an entitled process.

## A · Decisions only E can make — minutes each

- [ ] **Delete the spent `.xcresult` bundles?** Now **twenty-two** in the repo root (all
      gitignored), **859 MB** together; boot disk **~19 GB free**. This session added three
      (`WidgetCoverage-2026-09-07`, `RedCheck-widget`, `GreenAfterRedCheck-widget`). Related trap,
      and the reason this is worth a minute: **CLAUDE.md's documented test command still writes to
      `TestResults.xcresult`, which already exists**, so a session running it verbatim fails
      *after* paying for the whole build. Deleting the bundles fixes that; so would dating the
      documented path. I again used a dated path rather than change the documented command unasked.
      (carried, now with a bigger number)

- [ ] **Should the widget's view-only files be made testable at all?** Not started, and
      deliberately not started — it is a design change, not a coverage chore, so it is E's call.
      Two shapes, both real: (a) **extract the pure logic** currently embedded in widget-only view
      files into a file that is a member of both targets — `FocusActivityCopy.status(for:isComplete:)`
      (4 lines), `markerCentre(fraction:width:)` (5), `FocusStatsProvider`'s timeline maths (~13,
      and its `context` parameter is already unused); (b) **UI/snapshot tests**, which is the same
      answer the app target's 108 zero-percent files are waiting on. Shape (a) buys ~1.5% of the
      widget target for a refactor of shipped view code — **my recommendation is to leave it**, and
      to treat 97.9% of the testable surface as done.

## B · Real work, ready to start — recommended order

1. **Arc 2 — first-class routines + the "at a time" trigger.** Not authorised. (carried)
2. **`F-Search-3-Journal`** — recommendation is to kill the block. E's call. (carried)
3. **The Live Activity design review** E parked. (carried)

*B4 (the widget extension) is CLOSED — see above. Nothing has replaced it; section B is three
carried items and none is authorised.*

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

- **A percentage over a denominator that includes code the test target never compiles is not a
  coverage figure, it is two numbers divided.** This is the session's lesson and it generalises
  past the widget. Before reading any target's ratio as effort, check what the test host actually
  links: `xcrun xccov view --report --files-for-target <target> <bundle>` on both targets, and the
  intersection of the file lists is the surface that can move. Now in CLAUDE.md.
- **A `??` autoclosure is a REGION, and three of them were the whole gap in two "finished" files.**
  `FocusWidgetSnapshot` sat at 99.02% and `FocusActivityAttributes` at 97.26% with **zero**
  fully-uncovered lines between them. Same lesson the Journal adapter taught yesterday, now with a
  second instance — read regions with `xcrun xccov view --archive --file <path> <bundle>`;
  **without `--archive` it reports "unrecognized file format"**, which reads like a corrupt bundle
  rather than a missing flag. (extended)
- **A symmetric swap can be invisible to a "these are wired separately" test.** The red-check
  broke BOTH intents' action lookups at once; `testTheTwoIntents_areWiredToSeparateActions` passed
  anyway, because each recorder still saw one call. Predicted before the run and confirmed — the
  two single-intent tests are what actually carry that load. Worth remembering when writing a
  pairwise assertion.
- **Two coverage lessons from F-AdapterDrift, both in CLAUDE.md.** A fake with no error hook makes
  a `catch` branch untestable and the report blames the adapter; the last unit in a file is often a
  partial region. (carried)
- **The "failing tests are slow" oddity is EXPLAINED, and it is a one-off warm-up on the FIRST
  failure — not a per-failure penalty.** This item has been carried as unexplained since
  routine-record block 1 ("the 107-second failing test"), and yesterday's two red-checks
  corroborated it at 35 s and 43 s. Seven failures in one run settle it. In log order their
  durations were:

  ```
  9.391  1.558  0.039  0.002  0.002  0.001  0.006
  ```

  A monotonic decay from the first, not a constant. The whole suite ran **49.8 s** with seven
  failures against **48.3 s** all green — a 1.5 s difference, because the cost is paid ONCE.
  Yesterday's 35–43 s runs were few-failure runs, so that single warm-up WAS the whole measurement,
  which is exactly why it read as a per-failure trait.

  **What this changes:** a red-check with many failures costs barely more than a green run, so
  there is no reason to scope one down to keep it fast. Budget one slow first failure — and do not
  read it as a hang. (RESOLVED)
- **The 70% coverage bar is arithmetically out of reach without UI tests.** 108 of the app
  target's 342 measured files sit at exactly 0% — **29,513 lines, 66% of the entire denominator**.
  The largest are `NudgesView` (0/884), `HomeAccessoryStrips` (0/752), `LogComposerView` (0/718),
  `TaskListView` (0/711), `QuickCaptureComponents` (0/677). (carried)
- **The emulator harness held its ground**: `+Tags` 97.67%, `+Seed` 98.31%, `+Storage` 95.83%,
  `+AccountDeletion` 90.20%. (carried)
- **The watch-list is EMPTY.** (carried)
- **The strong-password pane is environmental** — full story in `UITestAutofill.swift`. (carried)
- **The DEBUG test-fire bypasses the master switch and cooldown BY DESIGN.** (carried)
- **`START-HERE-post-adapter-drift.md` is still the one live opener, and it is now SPENT** — its
  "what is actually next" recommended B4, which this session did. It was deliberately NOT archived:
  the rule archives an opener only in the same move that writes its successor, and E has not asked
  for a handoff. **If E wants one, that is the move that retires this file.** Until then it stays
  live so no session starts blind — but read its "what is actually next" as done. (updated)
- **Twelve `screenshots/` folders without READMEs** — deliberately left. (carried)
- **Stale unchecked bullets inside four finished blocks.** (carried)
- **The emulator was left running** (`scripts/emulators.sh`); `firestore-debug.log` in the repo
  root is the truth for a silently failed write. (carried)

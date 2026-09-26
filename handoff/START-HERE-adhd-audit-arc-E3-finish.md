# START HERE — WIP: arc E, FINISH block 3 `F-E3-OneCardToday`, then E4 → E5 → the ARC-E CLOSE.

*Written 2026-09-26 by the session that BUILT `F-E3-OneCardToday` and stopped at ~71% context on
E's note, at a clean line: every commit is green and pushed to `feature/adhd-e3-onecard`, and the
block is NOT landed (no PR yet) because three gates are still owed — the evidence frames, the
`apple-design` review and the mutation red-check. Bypass removes the wait, never a gate. Archive
this file when you write the arc's successor; its predecessor `archive/START-HERE-adhd-audit-arc-E3-onecard.md`
is spent.*

**E's standing instruction:** *"You must ensure to maintain seamless continuity in context and
memory into the new session."*

## 0. Before anything else

1. **Check against git and the register:** `git log --oneline -9 origin/feature/adhd-e3-onecard`
   must end at this file's commit, above `b0219a9`, `5db4285`, `56b903b`, `292c39e`, `2ab7a69`,
   `9e1cdd5`; `handoff/OPEN-ITEMS-REGISTER.md` edition **85**. `main` is still `df2ab2f` (E2).
2. `git checkout feature/adhd-e3-onecard && git pull --ff-only`. Do NOT branch again.
3. **Read:** CLAUDE.md (Per-arc bypass, the build loop, §7.6), the `F-E3-OneCardToday` block in
   `TODO-CLAUDE-CODE.md` — **including the new "E DECIDED 2026-09-26" banner** — build-log
   session 14, register edition 85, `scripts/build-loop/README.md`.
4. **Emulator:** restart it (it will be old), then probe 8080, 9099 AND 9199 and check `lsof` shows
   the NEW processes (`emulator-freshness`). It was started with `--import scripts/audit/emulator-state`.
5. **Simulators:** erase the unit sim (`9181EBF9…`, 26.5) before the first unit run. The 27.0 sim
   (`0ACE7E5C…`) was already erased after the last UI run; warm it before `ui.sh` (§2.1).
   `export SP=<your scratchpad>` for the `scripts/build-loop/` drivers.

## 1. What is built (and verified) — do not redo

- **Pure layer** (`9e1cdd5`): `Home/TodayPlan.swift` (E's slot order: leave-by > the place pair >
  paused sprint > pinned > suggestion; the "then" list; `headlineTask` for the widget),
  `Home/TodayStores.swift` (per-uid pin; per-uid, per-day "Not this one"), `Home/TodayCardCopy.swift`.
- **History feed** (`2ab7a69`): `FocusAnalyticsSection` was the ONLY writer of `publishedHistory`
  (the chain's sprint signal, the gain line, the week review, the widget). Home now reads it itself
  (`HomeView+FocusHistory`, `.task(id: focusReloadToken + pullRefreshCount)`). **`Focus/FocusAnalyticsSection.swift`
  is now callerless ON PURPOSE — `F-E4` moves its Mon–Sun widget into Week review and deletes it.**
- **New doors first** (`292c39e`): `Tools/ToolsNudgesSection.swift` beside Routines (Tools owns a
  `NudgesService`, `celebrate` became a `var` wired in `.task` like `recordAction`); a Week review
  row at the top of Areas (`Areas/AreasWeekReviewDoor.swift`, `AreasService.weekReviewInputs`,
  sessions + nudges read only when the door is used); both doors build `WeekReviewView(inputs:)`.
- **The rewrite** (`56b903b`, 49 files, −1,244 lines): `Home/HomeTodayCard.swift` (H1 card + Resume
  card + the two button styles), `Home/HomeView+Today.swift` (plan, slot switch, "then" list with
  due nudges + bell first, pin/skip/next-step actions), `HomeWeekReviewRow.swift` = the done line
  (counts `ringCount`, hosts the daily-goal pop origin `doneLineOrigin`). Retired: ring card, Best
  next move, life areas + the WHOLE Home reorder chain down to `FirebaseManager.reorderLifeAreas`,
  inbox peek + its capture door, the week chart + `closedCaption`, the nudges door +
  `NudgeFirstRunMarker` + its helpers, `HomeService.activeGoal`. One absence sweep holds them
  (`TodayOneCardCallSiteTests.testTodaysOldSectionsAreGone`).
- **E's two answers** (`5db4285`): Q1 side by side (the pair keeps ONE height — `buttons.md › Style`),
  Q2 "3 of 5 done today" once a goal is set.
- **UI journeys reversed + the harness** (`b0219a9`): Nudges opens from Tools everywhere
  (`UITestSession.openNudgesFromTools`); the re-tap journey holds E's rule on the week review push
  and seeds 8 due tasks so Today still scrolls; E1's harness reads the done line and finds Task
  Detail's gain line ON-SCREEN (Today's card now carries the same words on the parked tab).
- **Figures at `5db4285`:** full unit suite **3,395 / 0** (+ the Q2 test since → re-run); SwiftLint
  **0 / 908** at `b0219a9`.

## 2. What is left for E3, in order

1. **Frames.** `scripts/build-loop/ui.sh uiL L light large TodayOneCardRenderUITests`, then `D dark
   large`, then `A light accessibility-extra-large` (AX3; the harness ASSERTS Start above the fold
   and stops after frame 01). Erase + warm the 27.0 sim before the AX run (`Accessibility XL`
   trap). **The first light run produced NO frames, and neither result is an app verdict:**
   `testRenderTheOneCard` SKIPPED ("Firebase Emulator Suite is not running at 127.0.0.1:8080" —
   while 8080 answered 200 before and after) and `testRenderTheResumeCard` FAILED on
   `kAXErrorIPCTimeout`. Both fit machine load during the first boot of a simulator whose dyld
   cache E had cleared; the cause is NOT verified. So: boot the 27.0 sim and let it idle ~60s
   (warm) BEFORE `ui.sh`, re-run, and if the skip recurs read `UITestEmulator.skipUnlessRunning`'s
   probe timeout before blaming the app. The sim was erased after the run. **The harness has
   never run green — expect to tune two assertions before blaming the card:** frame 04's
   `value == "Book the photo booth"` is on a VERTICAL-axis `TextField`, whose XCUI `value` can carry
   the placeholder or a trailing newline (E2's harness used it on a single-line field); and
   `assertStartAboveTheFold` takes the fold as the Today PILL's `minY`, a few points below the tab
   bar card's top edge. (The Resume test got past `skipUnlessRunning` while the walk did not —
   evidence for load, not a dead emulator.) Pull frames with
   `xcrun xcresulttool` into `screenshots/today-one-card/` (JPEG), plus the two question boards
   (`E3-Q1-close-layout.jpg`, `E3-Q2-done-line.jpg` — re-render if lost: they came from a
   throwaway `ImageRenderer` probe, deleted, never committed). README per CLAUDE.md "Visual evidence".
2. **Red-check** (commit first): `python3 scripts/build-loop/e3-mutations.py pure` → build →
   `t.sh` the four pure classes → expect exactly: `testWhereYouAreBeatsAPausedSprint`,
   `testTheThenListHoldsWhatIsDueExceptTheCardsTask` (the WIDENING case), the two skip-expiry
   tests, `testAnUnchangedLineWritesNothing`, `testWithADailyGoalTheDoneLineSaysTheGoal` → restore.
   Then `source` batch with `test-without-building` on `TodayOneCardCallSiteTests` → expect the
   five guards named in the script → restore → prove the restore green.
3. **`apple-design` review** over the frames (pages refreshed 2026-09-26 — no text changed). Cite
   `layout.md` (HOME-03), `typography.md` (AX3), `buttons.md › Style` (two prominent max), the
   pin at 44pt vs round 7's 48 corner-control rule (a register candidate for `F-B1`, not a fix).
4. **Affected UI journeys, run deliberately then ERASE:** `FirstRunJourneyUITests`,
   `CaptureDiscClearanceUITests`, `TabReselectionJourneyUITests`,
   `SignedInJourneyUITests/testDueNudge_appearsOnHomeAndCanBeDismissed`,
   `RenderHarnessUITests/testRenderFirstRunNudgesDoor`, `UndoCapsuleRenderUITests`,
   `WeeklyChainRenderUITests`. (`IOS27CompatSweepUITests` also changed — a long sweep; judge.)
5. **`CLAUDE.md` — three small edits, ON THIS BRANCH so they land with E3** (E agreed 2026-09-26;
   `CLAUDE.md` describes `main`, so it changes when the code it describes merges). **Read the LIVE
   version first** — `git fetch && git diff origin/main -- CLAUDE.md` must be empty, or merge `main`
   in before editing; it was last changed at `3943579` (2026-09-24) when this was written.
   - **Project status (line ~9):** "Home (Active Goal hero, life-area grid + reorder, daily summary,
     focus analytics)" is stale — Today is one card, a "then" list and a done line; Nudges opens
     from Tools; Week review opens from Today's done line and the top of Areas.
   - **"The build loop" section:** its close-out bullet names `verify.sh` (2026-09-24) as the
     template — that lived in a past session's scratchpad and is gone. Point at
     `scripts/build-loop/` (`t.sh`, `full.sh`, `ui.sh`; README there) instead.
   - **Repo layout, the `scripts/` row (line ~33):** add "the build-loop drivers" beside the
     emulator harness.
6. **Close-out:** full suite (+ the scripted chain), lint, TODO tick with the **"Built … departs
   from the spec"** note (list in build-log session 14), register edition, build-log entry, PR +
   merge + the `origin/main` paste.

## 3. Departures from the spec already made (put them in the TODO note)

`ClosureCelebrationCard` was already gone (F-C1); the "then" list keeps the board's bordered card;
the eyebrow is `.secondary` (round 9: blue means tap me); the paused card is **Resume only** (the
board drew End, but "End" is arc F's rename and the focus bar's confirm still says "Stop"); b10's
"focus logged today" chip kept on the card; leave-by is a resolver rank only (no view — `F-F5`
feeds it; the time bar is F5's); `nextFire`, `ringProgress`, `closedCaption`, the whole reorder
chain and `NudgeFirstRunMarker` retired as dead code; the pin is 44pt per round 5a (round 7's
48pt corner rule → `F-B1`); the empty Today (all done) is header + done line only — for E's look.

**Say so in the Built note (the spec's last acceptance boxes):** no `firestore.rules` change (the
pin and "Not this one" are `UserDefaults`, the next step reuses `F-E2`'s field); no `#available`
site, so no Verified-paths line; no reduced-motion site of the card's own (the pin swaps its glyph
without animation; the 0.97 press scale is every house button's precedent) — the RM-on pass owed is
the undo capsule's arrival from the card's Close, and nothing else.

## 4. Then E4, E5 and the ARC-E CLOSE

- **E4** (`F-E4-WeekReviewConsolidation`): its Step 0 is answered; it also deletes
  `FocusAnalyticsSection` (callerless since E3) and `ProductivityTrendChart` — **and must reverse
  `WeeklyChainCallSiteTests:58`, which reads `Focus/FocusAnalyticsSection.swift` BY PATH for
  `.focusDailyGoalMinutes ?? 0`** (re-point it at wherever the goal-gated bar lands); `streakLine` is
  already gone (E1). Both Week review doors now build through `WeekReviewInputs` — add the
  sessions-driven chart there once and both doors get it.
- **E5** (`F-E5-EveningFirstThing`): Step 0 answered — a state variant of E3's card on
  `TodayPinStore` (answering pins).
- **Arc close:** coverage once; install on E's phone FIRST; `handoff/ARC-REVIEW-E.md`. **Owed there
  from E1–E3:** Settings' reveal rows + Today's no-goal count (E1, now the done line), the Next Step
  row (E2), and all of E3 — the one card in every state, the side-by-side gain line, "3 of 5",
  "Not this one", pinning, the Resume card, Tools' Nudges row, Areas' Week review row, the empty
  Today. **RM-on pass owed for E3** (spec): the close-from-card feedback (capsule) and the card's
  pin/skip swaps — name each site; the card itself adds no animation of its own.

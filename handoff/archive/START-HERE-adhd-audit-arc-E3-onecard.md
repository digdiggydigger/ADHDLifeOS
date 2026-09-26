# START HERE — WIP: arc E, block 3 `F-E3-OneCardToday`, then E4 → E5 → the ARC-E CLOSE.

*Written 2026-09-25 by the session that built `F-E1-WeeklyChain` and `F-E2-NextStepField`. A
disposable `WIP:` pointer (CLAUDE.md › Per-arc bypass: "mid-arc, a session that must stop writes a
`WIP:` opener for the next block of the same arc"). It stopped at a clean line after E2 LANDED, at
~50% context on E's note, because E3 is the arc's biggest block and deserves a fresh session.
Archive this file when you write the arc's successor. Its predecessor,
`archive/START-HERE-adhd-audit-arc-E.md`, is spent.*

**E's standing instruction:** *"You must ensure to maintain seamless continuity in context and
memory into the new session."*

## 0. Before anything else

1. **Check the register against this brief:** `git log --oneline -8` and
   `handoff/OPEN-ITEMS-REGISTER.md`'s header (edition 84). Arc E's E1 and E2 are merged.
2. **Branch:** `git checkout main && git pull --ff-only && git checkout -b feature/adhd-e3-onecard`.
3. **Read:** CLAUDE.md (Per-arc bypass, the build-loop economies, §7), `claudecode.md`, the
   **`### FEATURE: F-E3-OneCardToday`** block in `TODO-CLAUDE-CODE.md` (its two Step 0s are
   **E DECIDED 2026-09-24** — Nudges door → Tools beside Routines; live-routine + arrival card
   count as the one card), and E1's and E2's blocks directly above it (both have "for E3" notes).
   Build-log sessions 12 and 13, register editions 83 and 84. Memory: `per-arc-bypass`,
   `adhd-audit-build-progress`, `test-vacuity-mutation-check`, `dead-shared-component-pattern`,
   **`emulator-freshness` (NEW trap, below)**.
4. **Emulator — the 2026-09-25 trap.** TERM on the parent `firebase emulators:start` can leave its
   Firestore JVM (`cloud-firestore-emulator-*.jar`) ORPHANED on 8080. This session lost a whole
   close-out run to it: 8080 said 200 while Auth 9099 and Storage 9199 were dead, so 32 emulator
   tests FAILED instead of skipping and every UI render died at sign-up. After any cycle, check
   `lsof -nP -iTCP:8080 -sTCP:LISTEN` shows the NEW process, and probe all three ports. Kill a
   leftover JVM only after its `--project_id` reads `adhdlifeos-acb49` — E runs another repo's
   simulator work on this machine too.
5. **Erase** the unit simulator (`9181EBF9…`, iPhone 17 Pro 26.5) once before the first unit run.

## 1. What E1 and E2 left that E3 builds on — verify, don't assume

- **The gain line.** `MomentumTaskContext.Context.closeButtonTitle` is THE Close copy ("Close it —
  makes today count" until today counts; plain when the chain is hidden). Home's answer is
  `HomeView+WeeklyChain.hasCountedToday` (all four signals). **Today's hero still reads plain
  "Close it"** while Task Detail reads the gain line — the H1 card must take its Close title from
  the same context, so the two can never disagree (frame `weekly-chain-goals-off/05`).
- **Goals off until set.** `momentumPreferences.dailyGoal` is `Int?`; `MomentumRingCard` already
  renders a plain count without a goal and has NO streak column. E3 deletes the card; the F7
  daily-goal celebration's origin (`ringOrigin`, `onRingOrigin:`) moves to the done-today line, and
  `CelebrationMilestoneCallSiteTests` pins `onRingOrigin:` in `HomeMomentumSections.swift` by name —
  re-point, never drop.
- **The chain for the done-today line:** `WeeklyActiveChain.activeDays(_:)`,
  `activeDaysThisWeek(activeDays:)`, `chainLength(activeDays:goal:)`, fed by `activitySignals`.
- **The next step.** `TaskSummary.nextStep` decodes `next_step`; `TaskUpdatePayload.nextStep` is
  `String??` (cleared = delete). The card-side editing is E3's (round 5a: "editable from the card
  and from task detail"). Task Detail's row is a footnote caption "Next Step" over a field whose
  placeholder is "What to do first" — the card should read the same way.
- **`HomeView.swift` is at 398/400 lines.** E3 deletes a lot from it, but add nothing first.
- **E4's "delete `streakLine`" is already done** (E1). The in-app focus widget's goal bar is
  already gated on a set goal.

## 2. Harness traps this session paid for (all in build-log sessions 12–13)

- **A hidden tab stays in the hierarchy, parked ~10,000pt off screen.** Today's hero carries the
  same seeded task title AND a "Close it" button, so `firstMatch` and `tap(untilExists:)` resolve
  to Today's copy. Pick the ON-SCREEN match (`onScreen(_:)` in `WeeklyChainRenderUITests` /
  `NextStepFieldRenderUITests`) and wait on a DETAIL-only element (`taskDetailTitleField`).
- **Watchdog on the END of the suite.** `"Test Suite 'Selected tests'"` also prints at the START;
  key on `(passed|failed)` or `TEST (FAILED|SUCCEEDED)`, with a 900s ceiling. The chains in the
  scratchpad (`e2final.sh`) are the template.
- **A lazily built Form has no element below the fold** until scrolled to (Save failed "no
  matches" in light and passed in dark). Scroll first, then assert.
- **Accessibility XL: erase + warm (60s) before the run**, or the restored sign-in breaks sign-out.
- **iOS's "Save Password?" sheet** can cover a fresh account's first frame. It is the system's.

## 3. Then E4, E5 and the ARC-E CLOSE

- E4 and E5 have their Step 0s answered (E, 2026-09-24). E5's "Do not build past Step 0" line is
  superseded by that answer: build it as a state variant of E3's card.
- **Arc close:** coverage once; install on E's phone FIRST; then `handoff/ARC-REVIEW-E.md` (one
  numbered list, RM-on items grouped so E flips Reduce Motion once, a verdict line per block).
  **E1's and E2's device looks are owed there**: Settings' reveal rows and Today's no-goal count
  (E1), and the Next Step row and its caption (E2). Neither has an RM site.

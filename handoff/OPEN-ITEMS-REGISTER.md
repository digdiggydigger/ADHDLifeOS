# Open items register — 2026-09-12 (thirty-sixth edition; `F-CTACelebrations-5`, the three full-screen milestones, is BUILT and MERGED; **two blocks of the arc remain**, and E now owes ONE device sitting covering `-4` AND `-5` together)

*The close-out of the sixth build session of the CTA celebrations arc. E's standing ask — use any
skills, MCPs, plugins and subagents that help — was followed: the TDD skill, the render probe, a
`feature-dev:code-reviewer` pass and an `apple:hig-reviewer` pass. **Both review passes found real
defects, and one of them was in this block's own fix.** What each returned is below.

The opener `handoff/START-HERE-cta-celebrations-5.md` is SPENT — archived in the same move that
writes this edition and the next session's opener. Supersedes the thirty-five earlier editions.*

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding, so it is the thing to read and to
update rather than improvising a list in chat.

## State

**`main` @ `5e10586`** (PR #97, `F-CTACelebrations-5`). `firestore.rules` is untouched, so there is
**nothing for E to republish**.

**Verified at `2498c9b`** (the block's last commit; the merge adds nothing):
- unit suite **2,884 / 0**, emulator UP, **0** `127.0.0.1:9099` hits;
- SwiftLint **0 / 791**;
- sim `** BUILD SUCCEEDED **`; device build, install and launch from `main` at the close.

Coverage, measured at `2498c9b`:

```
ADHD LifeOS.app              27.39%  (13050/47646)
ADHD LifeOSTests.xctest      94.73%  (46522/49109)
ADHD LifeOSUITests.xctest     0.00%  (0/2962)       ← skipped in the standard run by design
FocusTimerWidgetExtension    10.30%  (228/2214)     ← read the 233-line testable surface, not this
```

**Comparable with the previous edition's 27.29 % (12,949/47,457), and it ROSE.** Both runs measured
100 % of the app target, which is CLAUDE.md's test for comparability. The denominator gained 189
because the tree grew; the numerator gained 101. So coverage grew slightly faster than the code —
the opposite of last block, where every line added was inside a view body. This block's additions
are mostly pure logic (`DailyGoalTracker`, `CelebrationDayMarking`, `NudgeStreak.landsOnSeven`,
`CaptureInboxZero`, `CelebrationPopOrigin`), which is exactly the code a unit test can reach.

### Landed this session

- **`F-CTACelebrations-5`** — E's three remaining full-screen milestones: **inbox zero** (the
  Sorted / Journal it / Create Task that empties the capture inbox), **the streak on 7**, and **the
  daily goal**. Room first: `CaptureInboxService.swift` 397 → 355. **60 tests** (2,824 → 2,884).
  Evidence `screenshots/cta-celebrations-block-5/`. **Awaiting E's device verdict**, together with
  `-4`'s. (NEW)
- **Register §B.00b's latent defect is CLOSED.** A burst held behind the Create Task sheet used to
  stamp the cooldown and fire the chime at REQUEST time, and `releaseHeld` set neither. Both paths
  now go through one `start(_:at:)`, and `CelebrationCenterHeldBurstTests` closes the test gap the
  register named. (NEW)
- **E's accessibility decision, asked at the start of the session as this register required:
  "the daily goal only".** It posts `UIAccessibility.post(notification: .announcement, …)`; the
  other two milestones do not. **The premise behind that answer was partly wrong — see §A.** (NEW)

### What this session established

- **Three defects were found AFTER the suite was green, and not one of them was reachable by an
  assertion.** This is the block that makes the pattern undeniable:
  - **Looking at a render found one.** The downgraded-pop render raised the question "where does
    that origin come from when the user is not on Home?", and the probe MEASURED the answer:
    `AppTabContent` parks a hidden tab 10,000 pt away and the offset reaches a `.global` frame
    reading — **(196.5, 451.0) visible → (10196.5, 451.0) parked**. R-h's fallback pop was being
    thrown off screen for the one milestone that fires from a tab the user is not on. The
    `apple:hig-reviewer` pass reached the same defect independently, from the other direction.
  - **A review pass found a Settings toggle that could buy a celebration.** `capturesClearedToday`
    was stored and refreshed asynchronously while `nudgesDismissedToday` read its toggle live, so
    flipping "count cleared captures" moved the ring's RULES one tick before its COUNT, and the
    catch-up read as a crossing under rules that already matched.
  - **And a review pass found a defect in this block's own fix.** `cooldownAnchor` used a held
    burst's `start`, which is its REQUEST time, so the cooldown "expired" after five seconds while
    the burst was still waiting unplayed — and `releaseHeld` would start both at one instant, the
    exact stacking the anchor was added to prevent. (NEW)
- **A guard that reads the wrong text is worse than no guard, because it fails in the believable
  direction — and this block wrote two of them.** One sliced a call's arguments "up to the next
  `)`", which for `HomeView(…)` lands inside `onToggleSprintPause: { focusService.togglePause() }`
  a dozen arguments early and reported an argument missing that was plainly there (now depth-tracked
  to the matching paren). The other closed a slice on a COMMENT line, which `stripped` removes
  before the slice is cut, so the anchor read as missing and the test threw instead of asserting.
  Both were caught only because the red PREDICTION missed. (NEW)
- **A COUNT cannot see a SWAP.** The deliberate regression moved the inbox-zero call from
  "Journal it" onto `discard` — nine tests went red, and
  `testExactlyTheThreeDoingVerbsAskForInboxZero` was not one of them, because three is still three.
  The named `testDiscardingACaptureNeverAsksForInboxZero` is what caught it. Keep both shapes. (NEW)
- **Predicting in TESTS and ASSERTIONS separately paid off five times**, and the one deliberate
  regression matched exactly: **9 tests / 11 assertions predicted, 9 / 11 observed**, test for test.
  The two misses were both guard defects, above. (NEW)
- **A "naive first pass" is how you prove a guard load-bearing without waiting for a real
  regression.** The centre's stamp fix, the daily-goal tracker and the day marker were each written
  wrong ON PURPOSE first — the naive fix turned exactly the intended tests red, and only then were
  they written properly. `testASecondMilestoneAskedForWhileOneIsHeldGetsThePopInstead` is green on
  the ORIGINAL code and red on the naive fix, so nothing but this technique would have shown it
  meant anything. (NEW)

### Carried from the design session

- **E's design answers are the spec.** Seven recommendations were overruled (a Finish button; a
  streak milestone and the daily goal; a chime; the mini confetti pop over the halo; the
  congratulation view; the display name; the 5 s cooldown). Record them, do not re-derive them.
- **Three app-level `ObservableObject`s**: `AuthService`, `FocusSessionService`, `CelebrationCenter`.
- **The Completed flow reverses an E-settled rule** (the routine-record arc's "a run ends when you
  LEAVE the screen"). The tests that pin the old rule must be updated by name, not silently.
- **`PlaceRoutineScreen.swift` is at 384** and `-6` adds to it; the design names the split
  (`PlaceRoutineCompletedCard.swift`, `PlaceRoutineCongratulationView.swift`, and a
  `+Completion.swift` extension if the screen nears 400).

## A · Decisions only E can make — minutes each

- [x] **THE DEVICE SITTING — DONE 2026-09-12, and BOTH blocks PASSED with Reduce Motion OFF *and*
      ON.** E, verbatim: *"both of those tests work correctly!"*, and confirmed when asked
      precisely that the passes included Reduce Motion turned on. So `F-CTACelebrations-4` (the
      nine pops) and `F-CTACelebrations-5` (the three milestones) are both verified on device, and
      **both blocks' Verified-paths lines may now read "Reduced: run on sim (injected) + E's phone
      (RM on)"** — the first time in this arc that line is earned rather than owed. E also sent a
      16.7 s screen recording of the whole showcase.
      **What came out of it is a new block, not a defect:** E asked for the pop to be bigger. See
      `F-CTACelebrations-PopScale`, built and merged the same day. (CLOSED)
- [ ] ~~**THE DEVICE SITTING — one sitting, TWO passes, covering `F-CTACelebrations-4` AND `-5`.**~~
      E deferred `-4`'s passes until after this block (2026-09-12, verbatim: *"I will push the
      device passes off until after the next block."*), so both are owed now and both are landed,
      green and installed on the phone from `main`. **Ask once, and say which sites belong to which
      block so a failure can be attributed.** Reduce Motion OFF first, then ON (Settings →
      Accessibility → Motion).
      **`-4`'s nine pops** — the Tasks **search surface** (a real `fullScreenCover`; the probe used
      a synthetic one); **Create Task** from the promote sheet (R-e's 0.45 s hold — the top of the
      pop is expected to clip at the sheet's edge, §C2, by design); the task detail's **Close it**;
      a **routine step**; and a circle tap AND a swipe on the same row (one origin).
      **`-5`'s three milestones** — clear the LAST capture (all three verbs reach it); a nudge's
      seventh consecutive "Done for now"; and the ring crossing the daily goal **from another tab**,
      which is the one that exercises the off-screen-origin fix.
      **No waiver applies to any of them** — the Confirm's §7.2 waiver covers the Confirm alone.
      Until E answers, both blocks' Verified-paths lines read *"Reduced: run on sim (injected);
      NOT on device."* (NEW)
- [ ] **THE ACCESSIBILITY ANSWER NEEDS RE-ASKING, because one of the three options I put to E
      rested on a premise that is FALSE.** E chose "the daily goal only" on the stated grounds that
      the other two milestones leave the user on a screen that states the outcome. The
      `apple:hig-reviewer` pass checked that, and I verified it: **`NudgesService.dismiss` sets
      `lastFiredAt`, `NudgeDueness.isNudgeDue` then measures the next fire from it, and the card is
      removed from the due list immediately** — exactly as on every other day. There is no
      "7 of 7 days" left on screen, the haptic is the same `.success` every dismissal plays, and the
      card vanishes identically whether the streak just hit 1 or 7. **So a VoiceOver user reaching
      day seven gets nothing that distinguishes it from any other day.** The inbox-zero half of the
      premise holds on the Captures tab (its `emptyState` is real) but was not traced for the
      pushed-detail doors. Nothing was changed: adding the streak announcement is one line and it is
      E's call, not a correction to make silently. (NEW)
- [ ] **PHOTOSENSITIVITY — the fireworks' flash rate, and this one is a launch-safety question, not
      a polish one.** The 14 shells' burst flashes land at **5 inside one second** (from ≈ 2.00 s),
      against **WCAG 2.3.1's threshold of 3**. Each flash is a radial gradient growing 40 → 240 pt
      at up to 0.35 alpha, over 0.35 s.
      **What is NOT claimed:** whether the luminance delta and the screen area also cross the
      guideline's thresholds is **unmeasured** — the flash COUNT alone is what crosses. There is no
      app-readable API for iOS's "Dim Flashing Lights", so this cannot be gated in code.
      **This block's HIG pass re-confirmed the finding does NOT extend to the three new
      milestones**: `CelebrationLayer` sets `fireworks` only for `burst.clearedStack`, and none of
      `inboxZero` / `streakSeven` / `dailyGoal` is a `.confirm`. The finding is the stack-clearing
      Confirm's alone. **It is E's call**: measure the luminance properly, thin the two clusters, or
      accept it. (carried, re-confirmed)
- [ ] **The milestone cooldown — E's call is DUE NOW.** E: *"i am undecided about the cooldown at
      the moment anyway."* It ships at **5 s for testing**; whether it exists and at what value was
      to be settled on the phone **after `F-CTACelebrations-5`**, which is this sitting. Note one
      thing that was not true before: the cooldown now also governs how a held burst behaves, so
      lowering it further would make §B.00b's second defect live again were it not fixed. (carried,
      now due)
- [ ] **The pop is not gated by the Celebrations switch, and the HIG pass asks whether that should
      stay.** It is E's #3, decided deliberately, and the Settings footer says so out loud. What the
      pass names is the consequence: a user who wants ZERO decorative motion on a rapid closing
      streak has no path to it except Reduce Motion, which stills the pop rather than removing it.
      Options: leave it, let the Celebrations switch cover pops too, or add a third switch.
      (carried)
- [ ] **Install an older simulator runtime** via Xcode → Settings → Components. E, 2026-09-11:
      *"In a number of days in the future, I will install this."* Until then every `#available`
      fallback is compile-only by policy (§7.3). (carried)
- [ ] **Optional, still not decided: an `.accessibilityHint` on the Celebration sounds row only.**
      (carried)
- [x] **E's device verdicts on `F-CTACelebrations-1`, `-2`, `-3` and `F-ConfirmCelebration-2`** —
      all PASSED 2026-09-12. (CLOSED)
- [x] **An accessibility announcement for the milestones** — E chose **"the daily goal only"**,
      2026-09-12, and it shipped. **Re-opened above on a false premise, not on the decision.**
      (CLOSED, superseded)
- [x] **How does the reduced path get DEVICE time now that E runs with Reduce Motion OFF?** —
      **E chose (a), 2026-09-12**, written into CLAUDE.md §7.3. (CLOSED)

## B · Real work, ready to start — recommended order

**00. THE CTA CELEBRATIONS ARC — blocks 1–6 of 8 BUILT and MERGED; the next is
   `F-CTACelebrations-6`, the routine Completed flow.** The record is
   `handoff/SESSION-OPENER-cta-celebrations-design.md`; the opener is the session's own
   `handoff/START-HERE-*`; the blocks are in `TODO-CLAUDE-CODE.md`.
   **The blocks, in order:** ~~`F-ConfirmCelebration-2`~~ → ~~`F-CTACelebrations-1`~~ →
   ~~`-2`~~ → ~~`-3`~~ (centre + layers) → ~~`-4`~~ (the nine pops) → ~~`-5`~~ (the three
   milestones) → **`-6`** (the routine Completed flow, R1–R5) → `-7` (the chime).
   **For block 6, four things this block leaves it:**
   - **Render the congratulation view FIRST** (light, dark, Reduce Motion, the switch-off beat)
     and send it to E before wiring anything. That is in the block as written.
   - **It REVERSES an E-settled rule** — "leaving a fully-resolved run ends it". Every test that
     pins the old rule is updated BY NAME, and each is named in the block report.
   - **Room first:** `PlaceRoutineScreen.swift` is at 384 of 400.
   - **The Completed button is the second site R-h names** (no pop of its own), so it records a
     `.celebrationPopOrigin` and `CelebrationPopCallSiteTests`' hand-recorded origin count moves
     **3 → 4**. Update the count and its message deliberately. The wrapper count stays 9. (NEW)

**0b. Two surfaces question, raised by the HIG pass and NOT closed: a full-screen celebration can
   play entirely unseen behind an untracked sheet or cover.** Only four surfaces call
   `surfacePresented` (root, routine cover, Tasks search, promote sheet). Every other `.sheet` /
   `.fullScreenCover` in the app — **Quick Capture** (`RootView.swift`, arguably the most-opened
   full-screen surface in the app), Settings, Add Task, the Journal composer, the focus detail, add
   nudge, the Life Area / Place / Tag editors — leaves `frontmost` reading `.root`, so a milestone
   requested then is drawn on the root layer BELOW the sheet: invisible, while still consuming the
   cooldown, marking the day and firing the haptic and the announcement.
   **The design record raised this for Settings alone** (*"acceptable, or add a `.settings` surface
   if E minds"*) and it was never answered; the gap is much wider than that one sentence. Options:
   accept it, add the one or two surfaces that matter (Quick Capture first), or hold a full-screen
   celebration behind ANY unknown presentation. **E's call, and it is cheap to defer — but it should
   be a decision rather than an oversight.** (NEW)

**0c. The daily-goal announcement is an INTERRUPT, and nothing here has been checked on a real
   VoiceOver device.** `UIAccessibility.post(notification: .announcement,)` speaks over whatever
   VoiceOver is reading, and it can fire on any tab about a second after an unrelated action; a
   second accessibility notification landing in the same beat can coalesce one away. Neither effect
   is provable from source. Worth folding into the next VoiceOver pass rather than a block of its
   own. A 17+ attributed-string announcement API with a priority option may exist in the 26.5 SDK —
   unverified — which would make this a §7.1 register candidate. (NEW)

**0d. Follow-ups to the modern-iOS pilot — only what E asks for.** (carried)
   - **RM arrival fade for the bottom furniture**, only if E likes the cross-fade.
   - **The modern-API inventory, register-only until each is a block.**
     - **Free at 16.0:** `.contentTransition(.numericText(countsDown: true))` on the sprint
       countdown and ~20 `.monospacedDigit()` counters; `.presentationBackground` (16.4) on three
       sheets.
     - **Needs 17:** `ContentUnavailableView` in four empty states;
       `.contentTransition(.symbolEffect(.replace))`; interactive widgets and routine Live Activity
       check-off; the `@Observable` migration (now 28 classes); TipKit.
     - **Needs 18/26:** `Tab`/`.tabBarMinimizeBehavior` and `.glassEffect`, both constrained by the
       custom `AppTabBar` (adoption means replacing it).
   - **Two RM sites that remove the press affordance entirely** (`AppTabBar.swift:266`,
     `AppSearchRow.swift:71`), and `RootView.swift`'s declared-but-unread `reduceMotion`.

1. **E's one un-run device check: airplane mode + pull-to-refresh on Home.** `F-HomeTasksLastKnown`
   (`8b5f740`) should keep the last-known task set rather than emptying it. (carried)

2. **`F-FocusCard-Corners` — after the arc (E: "Round them").** Round the collapsed card's bottom
   corners AND give `FocusBarCardShape.roundsBottomCorners` `animatableData`. (carried)

3. **`AppFeedback.hapticsEnabled()` and `.notificationSound()` have no test that calls them.** Two
   small tests, no production change. (carried)

4. **Two more dead design tokens, and two dead helpers.** `BarSurface` is defined, unit-tested and
   used by nothing; `AppTabBarPresentation.slotWidth` / `restingSlotWidth` have ZERO production call
   sites and disagree about their input. (carried)
5. **Accuracy-aware containment for the arrival card — ONLY if E still sees drops.** (carried)
6. **Arc 2 — first-class routines + the "at a time" trigger.** (carried)
7. **`F-Search-3-Journal`** — recommendation is still to kill the block. (carried)
8. **The Live Activity design review** E parked. (carried)

## C · Parked on E's instruction — do not start unprompted

- **A nudge-specific screen animation for EVERY "Done for now".** E, 2026-09-11. (carried)
- **14- and 21-day streak milestones** (R-b): the arc fires at exactly 7. (carried)
- **Places backgrounding dismiss bug** — waiting on E's iOS update. (carried)
- **App connections** — real two-way sync; Apple Notes has no iOS API. (carried)
- **LA interactive buttons**, **time-of-day triggers**, **smart skip**. (carried)
- **`OfflineSprintSummaryCard`** — E ruled it out of the focus-card arc explicitly. (carried)

## C2 · Noticed, below the bar, worth E's eye on device

- **The daily goal is the one celebration the user did not just cause with their thumb.** Raised by
  the HIG pass. Inbox zero and the streak both fire from a tap, so a wash starting under the thumb
  is no surprise; the daily goal can land about a second after ANY action, anywhere — including
  while typing in a task's notes. Hit-testing passes through, so nothing is blocked, but it is a
  real cost of E's "any tab" design (F7) rather than a defect. Worth naming at the device sitting.
  (NEW)
- **Eight of the ten pop sites are OPTIMISTIC** — they pop before the work is known to have
  succeeded. Each fires in the same closure and at the same instant as the haptic that was already
  there. The one worth a second look is **Sorted from the triage card**, where the
  `await service.sort(...)` genuinely can return false. **The three milestones are NOT optimistic**
  — each is asked for only after its write landed, which is why a failed sort celebrates nothing.
  (updated)
- **The promote sheet's celebration layer is sized to the SHEET, not the screen**, so the Create
  Task pop clips at the sheet's top edge. By design, and visible for 0.45 s (R-e). (carried)
- **Under Reduce Motion the closure card's `withAnimation(.default)` also animates the SIBLING
  sections reflowing beneath it.** A REDUCED-path effect, so E's passing verdicts did not see it.
  **The RM-on pass this sitting owes is the natural moment to look.** (carried)
- **The Feedback section's footer is a thirteen-line paragraph** covering six switches. (carried)

## D · Launch blockers — no conversation opened yet

- **Free dev account** → 7-day profiles; the current one is valid to **2026-09-17**. When a device
  install fails on it, E re-signs in Xcode → Settings → Accounts. (carried)
- **Sign in with Apple** built but dormant. (carried)
- **Photosensitivity: the stack-clearing Confirm's fireworks flash 5 times in one second** against
  WCAG 2.3.1's 3. Full detail in §A — including this block's re-confirmation that the finding does
  not extend to the three new milestones. (carried)

## E · Known, not work

- **`MILESTONE_PROBE_OUT` passed on the `xcodebuild` command line does NOT reach the test process.**
  It is taken as a build setting, and the probe falls back to `NSTemporaryDirectory()` — the
  simulator's own app-container `tmp`. Not a failure: the probe prints the path it actually wrote
  to, and the files are copied out afterwards. **Read the printed path rather than assuming the
  environment variable landed.** (NEW)
- **The `xcode` MCP bridge was NOT USED this session**, as the opener instructed; the
  run-loop-pumping probe did everything needed. (carried)
- **A stale `TestResults.xcresult` fails the whole suite before a test runs.** Gitignored, so it
  survives everything; delete it as part of the run. It was present at session start again.
  (carried)
- **A green suite cannot see a `View`'s appearance, a TIMING WINDOW, or a COORDINATE.** This block
  added the third: the fallback pop's origin was correct, its request was correct, and it was drawn
  faithfully at a point 10,000 pt off screen. Render, render the CONTROL, and prove the harness
  deterministic before any pixel claim — then ask what the numbers in the picture MEAN. (updated)
- **`Executed N tests, with M failures` counts failed ASSERTIONS, not failing TESTS.** Predict in
  both, and treat a MISS as a possible defect in the guards rather than a bad forecast — this
  session's two misses were exactly that. (carried)
- **SwiftLint's ceilings bite in two places now.** The 400-line FILE ceiling
  (`CaptureInboxService.swift` 397 → 355 this block; `PlaceRoutineScreen.swift` 384 is next), and
  the 250-line TYPE BODY ceiling, which `CelebrationCenterTests` crossed — split to
  `CelebrationCenterHeldBurstTests` on the `CaptureInboxTriageServiceTests` precedent. (updated)
- **Moving an extension to a new file ends same-file `private` access.** `replaceCapture` could not
  follow its two callers out of `CaptureInboxService.swift` — it writes `state`, whose
  `private(set)` setter keeps every writer in the type's own file — so it was relaxed to internal
  instead. (updated)
- **A UI-target run poisons the simulator; erase it before the next unit run**
  (`xcrun simctl erase 9181EBF9-0F54-4A4D-A19C-19945D1BF155`). No UI target was run this session.
  (carried)

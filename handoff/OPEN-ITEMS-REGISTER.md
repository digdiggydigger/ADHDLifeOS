# Open items register — 2026-09-13 (thirty-eighth edition; **`F-CTACelebrations-6` is PLANNED IN FULL and not yet built**, E answered nine open questions and closed §0b)

*The close-out of a PLANNING-ONLY session. No feature code, no tests, no branch — the whole output
is a plan, a rewritten opener and this register. E's standing instruction is that each block is
BUILT in a fresh Claude Code terminal, so this session deliberately stopped at the plan.*

*Nine questions were put to E and answered; **five of the nine are E's own wording or a reversal of
what was offered**, so they cannot be re-derived from the design record. Three exploration passes
and one design pass mapped every test the block touches and corrected three things the design record
and the previous opener got wrong. Supersedes the thirty-seven earlier editions.*

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding, so it is the thing to read and to
update rather than improvising a list in chat.

## State

**`main` @ `b5a55cf`** (PR #104) plus this session's docs-only commit. `firestore.rules` is
untouched, so there is **nothing for E to republish**.

**NO CODE CHANGED THIS SESSION.** It was planning only — the plan, a rewritten opener, the TODO
block and this register. So the figures below are **carried forward unverified from the
thirty-seventh edition, not re-measured**, and saying which is the point: nothing here is a claim
about a run that happened today.

Carried from `706728e` (the last code commit):
- unit suite **2,882 / 0**, emulator UP, **0** `127.0.0.1:9099` hits;
- SwiftLint **0 / 791**;
- sim `** BUILD SUCCEEDED **`; device build, install and launch from `main`.

```
ADHD LifeOS.app              27.39%  (13058/47668)
```

**One new measurement WAS taken, and it corrects a number this file has repeated for weeks:**
`PlaceRoutineScreen`'s **type body is 235 lines against SwiftLint's `type_body_length` ceiling of
250** — so the real headroom is **15 body lines**, not the 18 file lines the design record's
"384 of 400" implies. `.swiftlint.yml` overrides neither metric. See §B.00.

### Landed this session — documentation only

**No code, no tests, no feature branch.** E's standing instruction is that each block is BUILT in a
fresh terminal, so this session planned `F-CTACelebrations-6` and stopped.

- **`handoff/START-HERE-cta-celebrations-6.md` REWRITTEN.** It is no longer a thin pointer: it
  carries E's nine answers, the nine-commit plan, the test map, the three booby-traps, the red
  prediction and the risks. **It also corrects three things its own previous version got wrong** —
  the probe README it pointed at, the claim that a probe copy could be recovered, and the room-first
  move. (NEW)
- **`TODO-CLAUDE-CODE.md`** — the `F-CTACelebrations-6` block now carries E's nine answers and the
  three corrections; **`F-CTACelebrations-Surfaces` added** as its own block from E's §0b answer. (NEW)
- **This register** — thirty-eighth edition. (NEW)

*The previous session's landed work (`F-CTACelebrations-5`, the held-burst chime fix, `PopScale`,
`NoCooldown`, `SwipeOrigin`) is recorded in the thirty-seventh edition and is unchanged.*

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
- **TWO CORRECT DECISIONS CAN COLLIDE, and neither block could have seen it alone.** `-4` gave the
  row's circle and its swipe ONE origin for good reasons; `PopScale` took the throw to 208 pt at
  E's request, also for good reasons. Together they threw a swipe's paper off the screen. **Nothing
  in 2,884 tests caught it and no review pass did** — E found it in seconds on the phone. The lesson
  is not "test harder": a change to a shared CONSTANT deserves a re-look at every site that
  constant reaches, and E's device pass is load-bearing rather than ceremonial. (NEW)
- **When E reverses a rule, REVERSE the test that pinned it — never delete it.**
  `testTheSwipeAndTheCircleClosePopFromOneOrigin` became
  `testTheCirclePopsFromItselfAndTheSwipePopsFromTheFinger`, carrying E's reason inside it. The
  seven cooldown tests went the same way, each named in its commit. A deleted test leaves no trace
  of the decision that removed it. (NEW)
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

**E settled four of these at the device sitting on 2026-09-12/13. What remains is one deferral E
asked to be held, and two housekeeping items.**

- [ ] **DEVICE CHECK OWED on the three follow-on blocks, whenever E is next on the phone.** All
      three are landed, green and installed from `main`; none is urgent, and E has already passed
      everything that came before them.
      - **The swipe's pop** (`SwipeOrigin`) — swipe a task closed and confirm the paper now leaves
        from the finger rather than off the right-hand edge. **This is the one that replaces a
        defect E reported**, so it is the only check with a known "before".
      - **The overlap** (`NoCooldown`) — clear the last capture and cross the daily goal close
        together; two full-screen celebrations now OVERLAP rather than the second being downgraded.
        That is the direct consequence of removing the cooldown and it is E's decision; it is worth
        a look only to confirm it does not read badly.
      - **Reduce Motion ON** (`PopScale`) — the still pop's scatter scaled 48 → 76.8 pt with the
        pop, so §7.3 owes it one RM-on look. Until then that block's Verified-paths line reads
        *"Reduced: run on sim; NOT on device."* (NEW)
- [ ] **PHOTOSENSITIVITY — E POSTPONED this on 2026-09-13, and asked in the same breath that it be
      brought back before public launch.** E, verbatim: *"Can we postpone this decision for later
      date? But we must come back to this before shipping to the public."*
      **So this is now a LAUNCH BLOCKER by E's own instruction, not an open polish item** — it is
      listed in §D as well, and neither entry may be closed without E.
      The finding, unchanged: the stack-clearing Confirm's 14 shells flash **5 times inside one
      second** (from ≈ 2.00 s) against **WCAG 2.3.1's threshold of 3**. Each flash is a radial
      gradient growing 40 → 240 pt at up to 0.35 alpha over 0.35 s. **Unmeasured:** whether the
      luminance delta and screen area also cross the guideline — the flash COUNT alone is what
      crosses. There is no app-readable API for iOS's "Dim Flashing Lights", so it cannot be gated
      in code. The finding does NOT extend to the pops or the milestones (both re-confirmed).
      The options remain: measure the luminance properly, thin the two clusters, or accept it with
      eyes open. (DEFERRED BY E, carried to §D)
- [ ] **Install an older simulator runtime** via Xcode → Settings → Components. E, 2026-09-11:
      *"In a number of days in the future, I will install this."* Until then every `#available`
      fallback is compile-only by policy (§7.3). (carried)
- [ ] **Optional, still not decided: an `.accessibilityHint` on the Celebration sounds row only.**
      (carried)
- [x] **THE DEVICE SITTING — DONE 2026-09-12, and BOTH blocks PASSED with Reduce Motion OFF *and*
      ON.** E, verbatim: *"both of those tests work correctly!"*, confirmed when asked precisely
      about RM. So `F-CTACelebrations-4` and `-5` are verified on device and **both blocks'
      Verified-paths lines read "Reduced: run on sim (injected) + E's phone (RM on)"** — the first
      time in this arc that line is earned rather than owed. (CLOSED)
- [x] **The milestone cooldown — E REMOVED IT ENTIRELY, 2026-09-13.** Verbatim: *"Remove the
      cooldown entirely."* It was E's own 5 s testing value from the start, so this closes the
      question rather than reversing a settled answer. Shipped in `F-CTACelebrations-NoCooldown`;
      the consequence to watch on device is the overlap, above. (CLOSED)
- [x] **The VoiceOver announcement on the streak — E: leave as shipped, 2026-09-13.** E was told
      that the premise behind the original answer was wrong (the nudge card VANISHES on dismissal,
      so day seven leaves nothing on screen that distinguishes it) and chose to keep the shipped
      behaviour anyway: the daily goal announces, the other two do not. **Decided with the correct
      facts in hand, which is what the re-ask was for.** (CLOSED)
- [x] **Whether the Celebrations switch should also gate pops — E: leave as shipped, 2026-09-13.**
      So the switch covers full-screen celebrations only, the Settings footer continues to say so,
      and a user wanting zero decorative motion has Reduce Motion (which stills the pop rather than
      removing it). Raised by the `apple:hig-reviewer` pass; E has now ruled. (CLOSED)
- [x] **An accessibility announcement for the milestones** — E chose "the daily goal only",
      2026-09-12, re-confirmed 2026-09-13 on corrected facts. (CLOSED)
- [x] **How does the reduced path get DEVICE time now that E runs with Reduce Motion OFF?** —
      **E chose (a), 2026-09-12**, written into CLAUDE.md §7.3. (CLOSED)

## B · Real work, ready to start — recommended order

**00. THE CTA CELEBRATIONS ARC — blocks 1–6 of 8 BUILT and MERGED, all PASSED on device, plus
   three follow-on blocks. `F-CTACelebrations-6` is now PLANNED IN FULL but NOT BUILT.** The record
   is `handoff/SESSION-OPENER-cta-celebrations-design.md`; the plan is
   `handoff/START-HERE-cta-celebrations-6.md` (rewritten 2026-09-13 and no longer a thin pointer —
   it carries the whole plan); the blocks are in `TODO-CLAUDE-CODE.md`.
   **The blocks, in order:** ~~`F-ConfirmCelebration-2`~~ → ~~`F-CTACelebrations-1`~~ → ~~`-2`~~ →
   ~~`-3`~~ → ~~`-4`~~ → ~~`-5`~~ → **`-6`** (planned, unbuilt) → `-7` (the chime) →
   `F-CTACelebrations-Surfaces` (NEW, E's §0b answer). Plus ~~`PopScale`~~, ~~`NoCooldown`~~,
   ~~`SwipeOrigin`~~.

   **What the planning session established, and none of it should be re-derived:**
   - **E's nine answers**, tabled in the opener and the TODO block. Five are E's own wording.
   - **The binding lint ceiling is `type_body_length` 250, not `file_length` 400.**
     `PlaceRoutineScreen`'s body is at **235** — 15 lines of headroom, not 18. The `#if DEBUG`
     preview block sits OUTSIDE the type body, so moving it buys 61 *file* lines and **zero** body
     lines: **both** room moves are needed and it still lands at ≈251. **And the design record's
     suggested `+Completion.swift` for `complete()` cannot work** — `private` is file-scoped.
   - **Three booby-traps**, each breaking a currently-green test: the `store.end` → `record`
     **adjacency**; the **unique anchor** `"Button(title) { Haptics.play(.solid)"`; and the raw
     **`leaveScreen()` == 5** count that drops to 4.
   - **The full test map** — four tests reversed/updated by name, six sites that read
     `PlaceRoutineScreen.swift` as a string, and the large set of `reason: .completed` tests at the
     store/record/reconciler layer that are **UNAFFECTED** and must not be "fixed".
   - **The probe recipe base is `screenshots/cta-celebrations-block-2/README.md`, not block 3**
     (block 3 says so itself), and **no probe code survives anywhere** — the scratchpad copies both
     READMEs cite are gone, so the probe is re-implemented from prose.
   - **Two design answers settled:** "shrink to fit" is a pure, testable density table rather than
     `ViewThatFits` (and `PlaceRoutineStepCircle` must gain a `size`, because 20 rows is 560 pt of
     glyph alone); and the body swap is a **`ZStack`** — a `Group` would re-fire
     `.task { activity.started(run) }` and restart the Live Activity moments after `complete()`
     ended it, which **no test could see**.
   - **Red prediction: 27 tests / 48 assertions**, plus three single-assertion flips, and five
     named naive-first-passes.

~~**0b. Two surfaces question, raised by the HIG pass and NOT closed.**~~ **ANSWERED BY E,
   2026-09-13 — and it is now a BLOCK, not a question.** Offered "add Quick Capture only", "hold
   behind any unknown sheet", "accept it and close the item" or "defer and ask again", E chose
   **hold a full-screen celebration behind ANY unknown sheet**. Written up as
   **`F-CTACelebrations-Surfaces`** in `TODO-CLAUDE-CODE.md`, queued after `-7`. **The hard part is
   the whole block:** iOS hands the app no signal that a sheet is up, so the detection needs a
   deliberate seam — that design question is OPEN and is the first thing the block must settle.
   The existing R-g 60 s drop applies to the held burst unchanged. (CLOSED as a question)

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

1. ~~**E's one un-run device check: airplane mode + pull-to-refresh on Home.**~~ **RUN AND PASSED
   2026-09-13** — E: *"Airplane mode ON check has been run and was successful."* Home keeps the
   last-known task set rather than emptying it, which is what `F-HomeTasksLastKnown` (`8b5f740`)
   exists to do. **Nothing is outstanding here.** (CLOSED)

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

## C2 · Noticed, below the bar — **E asked explicitly that these be KEPT, 2026-09-13**

*E, verbatim: "Don't forget Your flagged points, So we can come back to them later." So nothing in
this section is dropped for age, and none of it may be quietly closed as stale. Each is something
this session or an earlier one noticed and judged below the bar for its own block — not something
that was tried and dismissed.*


- **A fully-ticked routine that is never confirmed will be recorded as `dayEnded`, not
  `completed`.** Found while planning `-6`. An arrival run stays live until **end of day**
  (`RoutineRun.swift:96-102`) and `RoutineRunReconciliation` then stamps `.dayEnded` /
  `.windowLapsed` (`:40-42`), so R1's *"Completed can be tapped later"* has a deadline: midnight.
  Tick every step, swipe away, come back tomorrow — the Journal shows a lapsed run. **This is
  exactly what E asked for** (*"nothing is recorded as completed without the tap"*), so it is
  intended rather than a defect, but E has not seen it stated. (NEW)
- **A shared constant reaches more sites than the block that changes it.** The swipe's pop went
  off-screen because `PopScale` moved a throw distance that a DIFFERENT block had built an origin
  decision around. Fixed in `F-CTACelebrations-SwipeOrigin`, but the shape recurs: the next time a
  celebration constant moves, re-read every site that constant reaches rather than trusting the
  suite. (NEW)
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
  WCAG 2.3.1's 3. **E POSTPONED the decision on 2026-09-13 and asked in the same breath that it come
  back before launch** — verbatim: *"Can we postpone this decision for later date? But we must come
  back to this before shipping to the public."* So it sits here by E's own instruction rather than
  by anyone's judgement, and **it may not be closed without E**. Full detail, and what is and is not
  claimed, in §A. The finding does not extend to the pops or the milestones. (DEFERRED BY E)

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

# Open items register — 2026-09-13 (thirty-seventh edition; `F-CTACelebrations-5` shipped, E's device sitting PASSED everything, and E's four decisions from it are all settled — **two blocks of the arc remain**)

*The close-out of the sixth build session of the CTA celebrations arc, plus the three follow-on
blocks E asked for from the phone. E's standing ask — use any skills, MCPs, plugins and subagents
that help — was followed: the TDD skill, render probes, a `feature-dev:code-reviewer` pass and an
`apple:hig-reviewer` pass. Both review passes found real defects, one of them in this session's own
fix; a third was found by LOOKING at a render; and a fourth was found by E on the phone, which no
test could have caught.

The opener `handoff/START-HERE-cta-celebrations-5.md` is SPENT and archived. Supersedes the
thirty-six earlier editions.*

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding, so it is the thing to read and to
update rather than improvising a list in chat.

## State

**`main` @ `210d931`** (PR #103). `firestore.rules` is untouched, so there is **nothing for E to
republish**.

**Verified at `706728e`** (the last code commit; the merges and the close-out add no code):
- unit suite **2,882 / 0**, emulator UP, **0** `127.0.0.1:9099` hits;
- SwiftLint **0 / 791**;
- sim `** BUILD SUCCEEDED **`; device build, install and launch from `main` at the close.

Coverage, measured at `706728e`:

```
ADHD LifeOS.app              27.39%  (13058/47668)
```

**Comparable with the thirty-sixth edition's 27.39 % (13,050/47,646)** — both runs measured 100 % of
the app target. Flat, and honestly so: the three follow-on blocks are a constant, a policy
simplification and a coordinate, not new logic.

**The suite count FELL, 2,888 → 2,882, and that is the expected shape rather than a regression:**
`NoCooldown` removed seven tests that pinned a rule E deleted, and added two.

### Landed this session

- **`F-CTACelebrations-5`** — E's three remaining full-screen milestones: **inbox zero**, **the
  streak on 7**, and **the daily goal**. Room first: `CaptureInboxService.swift` 397 → 355. 60
  tests. Evidence `screenshots/cta-celebrations-block-5/`. **PASSED E's device pass, with Reduce
  Motion off and on.** (NEW)
- **Register §B.00b's latent defect is CLOSED.** A held burst now chimes when it PLAYS rather than
  when it was asked for, and one dropped at R-g's sixty seconds never chimes at all.
  `CelebrationCenterHeldBurstTests` closes the test gap the register named. (NEW)
- **`F-CTACelebrations-PopScale`** (PR #99) — E saw the pop on the phone and asked for it bigger, in
  three messages covering size, spread and count. Four variants rendered in situ; **E picked C**.
  One constant, `CelebrationRecipes.popScale = 1.6`, carries all three: 18 → 28 pieces, 2,087 →
  5,590 painted px, furthest piece 140 → 208 pt. Evidence
  `screenshots/cta-celebrations-pop-scale/`. **Do not tune it down** — it is E's by-sight value. (NEW)
- **`F-CTACelebrations-NoCooldown`** (PR #102) — **E removed the milestone cooldown entirely.**
  `CelebrationPolicy.outcome` takes no clock; `milestoneCooldown`, `lastFullScreenAt` and
  `cooldownAnchor` are gone rather than left unread. (NEW)
- **`F-CTACelebrations-SwipeOrigin`** (PR #102) — **a swipe now pops from the finger.** E recorded
  the defect on the phone: the swipe shared the circle's origin, the circle sits at the row's
  trailing edge, and the 1.6× throw put most of the paper off the right of the screen. (NEW)

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

**00. THE CTA CELEBRATIONS ARC — blocks 1–6 of 8 BUILT, MERGED and all PASSED on device, plus
   three follow-on blocks from E's device pass. The next is `F-CTACelebrations-6`, the routine
   Completed flow.** The record is `handoff/SESSION-OPENER-cta-celebrations-design.md`; the opener
   is `handoff/START-HERE-cta-celebrations-6.md`; the blocks are in `TODO-CLAUDE-CODE.md`.
   **The blocks, in order:** ~~`F-ConfirmCelebration-2`~~ → ~~`F-CTACelebrations-1`~~ →
   ~~`-2`~~ → ~~`-3`~~ → ~~`-4`~~ → ~~`-5`~~ → **`-6`** (the routine Completed flow, R1–R5) →
   `-7` (the chime). Plus, out of the device pass and not in the original plan:
   ~~`PopScale`~~, ~~`NoCooldown`~~, ~~`SwipeOrigin`~~.
   **For block 6, four things this session leaves it:**
   - **Render the congratulation view FIRST** (light, dark, Reduce Motion, the switch-off beat) and
     send it to E before wiring anything. That is in the block as written, and it is how the pop
     and the pop's SCALE were both settled.
   - **It REVERSES an E-settled rule** — "leaving a fully-resolved run ends it". Every test that
     pins the old rule is updated BY NAME, and each is named in the block report.
   - **Room first:** `PlaceRoutineScreen.swift` is at 384 of 400.
   - **The Completed button is the second site R-h names** (no pop of its own), so it records a
     `.celebrationPopOrigin` and `CelebrationPopCallSiteTests`' hand-recorded origin count moves
     **3 → 4**. The wrapper count stays 9. **And note `SwipeOrigin`'s lesson**: think about where
     that origin sits relative to the 208 pt throw before trusting it. (updated)

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

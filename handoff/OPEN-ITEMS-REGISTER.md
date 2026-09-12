# Open items register — 2026-09-12 (thirty-second edition; the CTA celebrations arc's block 2, `F-CTACelebrations-1`, is BUILT, MERGED and PASSED E's device verdict BY FEEL on the FULL path; **E turned Reduce Motion OFF the same day**, which changes the project's verification coverage but not §7.2's rule; six blocks remain)

*The close-out of the second build session of the CTA celebrations arc. E's asks this session,
verbatim: *"Start from handoff/START-HERE-cta-celebrations-1.md. Read it, then the register and the
design record's 'Haptic only' and 'closure card's spring-in' sections. No gate question is owed. Do
the room-first commit on HomeView.swift and HomeMomentumSections.swift, then build
F-CTACelebrations-1 test-first with a written red prediction, and stop for my device verdict by
feel. The cooldown stays at 5 s. Ignore the untracked AGENTS.md."* — and, mid-session, *"Remember
that you should make use of ANY skills, MCPs, Plugins and subagents to assist your work"* and
*"the previous sessions emulator is probably still open, use that if you can"*.

The opener `handoff/START-HERE-cta-celebrations-1.md` is SPENT — it is archived in the same move
that writes this edition and the next session's opener. Supersedes the thirty-one earlier editions.*

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding, so it is the thing to read and to
update rather than improvising a list in chat.

## State

**`main` @ `49c78d9`** (PR #80, `F-CTACelebrations-1`). `firestore.rules` is untouched, so there
is **nothing for E to republish**.

**E's phone: built, installed and launched from the CLI at the close of this session** — the
device build ran `** BUILD SUCCEEDED **` against `3DBC979A-3255-5456-8C30-172DB19B99B3`
(`wishwashwacky15`, an iPhone **15** Pro — the opener did not say the model), installed to bundle
`com.ethananthony.ADHD-LifeOS` and launched. The profile is valid to 2026-09-17.

**Verified at `844daae`** (the block's green commit; the PR adds only the TODO tick):
- unit suite **2,747 / 0** (2,741 + this block's six), emulator UP, **0** `127.0.0.1:9099` hits;
- SwiftLint **0 / 760**;
- sim `** BUILD SUCCEEDED **`; device build at the close.

Coverage, measured at `844daae`:

```
ADHD LifeOS.app              27.07%  (12643/46702)
ADHD LifeOSTests.xctest      94.94%  (44066/46415)
ADHD LifeOSUITests.xctest     0.00%  (0/2962)       ← skipped in the standard run by design
FocusTimerWidgetExtension    10.30%  (228/2214)     ← read the 233-line testable surface, not this
```

(Comparable with the previous edition's 27.07 % (12,635/46,678): the denominator moved by 24 lines
because the TREE grew by this block's production lines, and both runs measured 100 % of the app
target. The ratio is unchanged to four figures — a block of call-site guards over view code moves
the numerator by about as much as it moves the denominator.)

### Landed this session

- **`F-CTACelebrations-1`** — the four haptic tidies (Sorted on the capture DETAIL screen
  `.solid` → `.success`; "Done for now" `.light` → `.success`; Save a place gains `.solid` INSIDE
  the success branch; Stop sprint gains `.light` on the confirmation's destructive button, not the
  toolbar Stop that merely raises the dialog) and the closure card's spring-in. Six tests, not the
  five the block predicted; red 6 / 6 tests predicted and observed (11 assertions); green 6 / 6.
  Evidence `screenshots/cta-celebrations-block-1/`. **E's device verdict PASSED** 2026-09-12 BY
  FEEL — *"it feels good, all five work as you described"* — on the **FULL** path; the reduced one
  is verified by injection only (§A). (NEW)
- **The room-first split**, its own commit: `HomeView.swift` 399 → 362 (`Home/HomeView+Refresh.swift`)
  and `HomeMomentumSections.swift` 399 → 303 (`Home/HomeLifeAreasSections.swift`). Four `private`
  declarations widened to internal, because `private` in an extension is scoped to the FILE the
  extension is written in — `widgetSprint`, `widgetPublisher`, `pullRefreshCount`,
  `publishWidgetSnapshot`. **Two of the five near-ceiling files listed in the thirtieth edition are
  now clear**; `RootView.swift` 394, `CaptureInboxService.swift` 397 and `PlaceRoutineScreen.swift`
  379 remain, and blocks `-3` and `-5` each carry their own room-first commit. (NEW)

### What this session established

- **The three writers of `celebratedTask` share one `setCelebratedTask` rather than each carrying
  its own `withAnimation(...)`** — a deliberate deviation from the record's wording, and the reason
  is testability: "no writer bypasses the animation" is a property a test can hold only if there is
  one writer to point at. The record's literal animation string is still present and pinned. (NEW)
- **A call-site guard must be scoped to its CLOSURE, not its file.** Three of this block's four
  files already held the target feel at a different site that must not move — `CaptureDetail\
  Components` plays `.solid` on the notes save, `PlaceEditorView` plays `.solid` when an address
  suggestion drops the pin, `FocusTimerBar` plays `.light` on expand/collapse. A whole-file
  `contains(".light")` on `FocusTimerBar` would have been GREEN on a tree where the stop
  confirmation buzzed nothing at all. The tests extract one closure between two unique anchors and
  throw loudly if an anchor has moved. (NEW)
- **The reviewer subagent (`feature-dev:code-reviewer`) found nothing at its bar and one thing
  worth fixing below it:** the no-bypass guard read ONE file while its name claimed "EVERY write",
  and `celebratedTask` is internal on `HomeView`, so any of that type's eight extension files could
  have bypassed the setter unseen. The guard now sweeps every Swift file in the app target and
  names the offenders; red-checked by planting a bare write in `HomeLifeAreasSections.swift`
  (2 != 1, the file named in the failure), tree restored with `git checkout --`. It also confirmed
  the one path that could have silently defeated the whole animation: `HomeService.load()` guards
  its `.loading` state, so the `await homeService.load()` following `setCelebratedTask(task)` does
  NOT bounce `HomeView.body`'s switch and tear down the in-flight transition. (NEW)
- **A rendered sheet could not settle whether `.scale(0.9)` was applied at all** — both new rows
  read as a cross-fade, because at the instant the scale is 0.9 the opacity is still ≈ 0 and there
  is nothing to see. The probe therefore MEASURES the card's rendered width off the `CGImage`:
  against a settled **370 pt**, the full path narrows to **340–346 pt** (0.92 ×) at t ≈ 0.11 s and
  recovers by ≈ 0.29 s, while the reduced path never leaves **369.5–370 pt**. Reproduced over three
  consecutive runs. **When a sheet cannot resolve the property, measure it and publish the number**
  — §7.2's opening-pose rule is a claim about geometry, not about how something looks. (NEW)
- **Two probe harnesses were wrong before one was right, and both failures looked like app bugs.**
  (a) The first scan band sat in the hosting controller's ~59 pt safe-area inset and returned zero
  width for EVERY row — including the control row that cannot move. *A measurement that reports
  nothing for a control that cannot move is measuring the wrong pixels.* (b) A card-alone harness
  (empty else-branch) failed to render the inserted card at all in some runs and showed it at
  ≈ 0.83 s in others, from identical code; it was DISCARDED as unreliable rather than reported as
  inconclusive, and no number in the evidence comes from it. The harness that works keeps content
  in both branches. (NEW)
- **The emulator suite from the PREVIOUS session was still up** (java on 8080/9099/9199), and
  `./scripts/emulators.sh` failed with "port taken" rather than reusing it. E: *"use that if you
  can."* Checking the hub (`curl 127.0.0.1:4400/emulators`) is the cheap way to tell a stale
  harness from a broken one. (NEW)

### Carried from the design session (thirtieth edition)

- **E's design answers are the spec.** Seven of the recommendations were overruled (a Finish
  button; a streak milestone and the daily goal; a chime; the mini confetti pop over the halo; the
  congratulation view; the display name; the 5 s cooldown). Record them, do not re-derive them.
- **Two full-screen covers host celebration sites** — the routine screen and the Tasks search
  surface — and the Create Task sheet hosts a third; the shipped root overlay sits below all of
  them. That is why the design mounts one layer per surface (E's choice over a `UIWindow`).
- **Only two `ObservableObject`s are app-level** (`AuthService`, `FocusSessionService`); every other
  service is screen-scoped, and `AppTabContent` builds tabs lazily and KEEPS them, so Home's
  `.onChange`s run on every tab once visited (it is the initial tab).
- **`onGeometryChange(for:of:action:)` is back-deployed to iOS 16.0** in the 26.5 SDK
  (`@_alwaysEmitIntoClient`), so the pop's origin needs no `#available`.
- **Five files sit at or near the 400-line ceiling** and need room-first commits before their
  blocks: `RootView.swift` 394, `HomeView.swift` 399, `HomeMomentumSections.swift` 399,
  `CaptureInboxService.swift` 397, `PlaceRoutineScreen.swift` 379.
- **The Completed flow reverses an E-settled rule** (the routine-record arc's "a run ends when you
  LEAVE the screen"). The tests that pin the old rule must be updated by name, not silently.
- The Xcode MCP bridge was UP this session (`XcodeListWindows` → `windowtab1`); Xcode was open
  before the session started.

### How the Reduce Motion story got here (carried in brief)

E's phone ran **Reduce Motion ON (and Prefer Cross-Fade Transitions ON)** from the start of this
story until **2026-09-12, when E turned it OFF** (E, unprompted: *"I no longer run with reduce
motion on"*). CLAUDE.md §7 is the rule and it is UNCHANGED — it rests on Apple's guidance and on the
public-launch intent, never on E's own setting. The Confirm celebration is its ONE waiver, and this
arc's design does not extend it: every new site fades (E's #7). **What the change costs is coverage,
not policy:** the reduced path used to be tried on a real phone every day by the person reviewing
the blocks, and now is exercised only by injection. §7.3 carries the consequence for reports, and
§A carries E's open question about how the reduced path gets device time from here.

## A · Decisions only E can make — minutes each

- [x] **Review the design record** and rule on **R-a…R-h** — E, at the start of the build session
      2026-09-11, asked in one message with each default listed: **"yes"**. The record is approved
      and all eight recommendations stand as the build's defaults. (CLOSED)
- [x] **E's device verdict on `F-CTACelebrations-1`** — **PASSED 2026-09-12**, E: *"it feels
      good, all five work as you described."* All five taps confirmed by thumb — Sorted on the
      capture detail screen, Done for now, Save a place, the sprint Stop CONFIRMATION, and the
      closure card's arrival from Home's Best-next-move. **Corrected 2026-09-12:** this item first
      said the verdict exercised the REDUCED path, on the then-standing fact that E's phone ran
      Reduce Motion ON. E turned it OFF earlier the same day and confirmed it was already off for
      this test, so **what E approved is the FULL path — the spring**. The reduced path is verified
      by injection only. The §C2 sibling-reflow question is a REDUCED-path effect, so E did not see
      it and it cannot be treated as having drawn no complaint. The block is CLOSED; the next is
      `F-CTACelebrations-2`, the two switches. (CLOSED)
- [ ] **How does the reduced path get DEVICE time now that E runs with Reduce Motion OFF?** Until
      2026-09-12 every reduced branch was tried on a real phone daily, for free, by the person
      reviewing the blocks. That coverage is gone. Injection proves the code runs and which branch
      is chosen; it cannot show how a fade READS on the device, and this app ships to users who
      will have the setting on. Three options, none of them started: **(a)** E toggles Reduce
      Motion on for the device check of any block that adds a reduced site — a few seconds per
      block, and the only one that gives real device evidence; **(b)** reduced paths are accepted
      as sim-injection-only and every report says so (§7.3's new default line); **(c)** a UI
      journey runs with the setting forced, which costs a simulator erase per run and still is not
      a phone. Recommend **(a)**, because the reduced path is the one users with motion sensitivity
      get. E's call. (NEW)
- [ ] **E has still never seen the focus card's completion celebration** (`F-FocusCard-4` — the
      ring burst and the tick that springs from 0.6, after a 0.3 s pre-beat). It was built and
      approved while E's phone had Reduce Motion ON, so E judged a hard cut plus a haptic and the
      arc closed on *"the pre-beat reads fine"*. **With the setting off it will now actually play.**
      Nothing to build; finish a sprint and look at it, and say if it is wrong. (NEW)
- [x] **E's device verdict on `F-ConfirmCelebration-2`** — PASSED 2026-09-12, E: *"it looks good.
      It looks as if it's working as as you specified."* The block is CLOSED. E also said to ignore
      the stray Codex `AGENTS.md` for now. (CLOSED)
- [ ] **The milestone cooldown.** E: *"i am undecided about the cooldown at the moment anyway."* It
      ships at **5 s for testing**; whether it exists and at what value is E's call on the phone
      after `F-CTACelebrations-5`. (carried; untouched this session, as E instructed)
- [ ] **Install an older simulator runtime** via Xcode → Settings → Components. E, 2026-09-11:
      *"In a number of days in the future, I will install this."* Until then every `#available`
      fallback is compile-only by policy (§7.3). (updated)
- [x] **The widget extension's `MARKETING_VERSION`** — E: *"Set the widget to 1.3"*. Done in this
      PR. (CLOSED)
- [x] **Should the widget's view-only files be made testable?** — E: *"Leave it, close the item"*.
      (CLOSED)
- [x] **The collapsed card's square BOTTOM corners** — E: *"Round them"*. Now a block,
      `F-FocusCard-Corners`, after the arc (§B.2). (CLOSED as a question; open as work)
- [x] **E's SECOND change** — E: *"There is no second change"*. Removed. (CLOSED)
- [x] **E's device verdicts on both celebrations** — DONE 2026-09-11 (carried; see the twenty-ninth
      edition's wording in the evidence READMEs).

## B · Real work, ready to start — recommended order

**00. THE CTA CELEBRATIONS ARC — blocks 1 and 2 of 8 BUILT and MERGED (`F-ConfirmCelebration-2`
   PR #76 verdict PASSED; `F-CTACelebrations-1` PR #80 awaiting the verdict by feel); the next is
   `F-CTACelebrations-2`, the two switches.** The record is
   `handoff/SESSION-OPENER-cta-celebrations-design.md`; the opener is the session's own
   `handoff/START-HERE-*`; the blocks are in `TODO-CLAUDE-CODE.md`.
   **E's decisions, all settled** (the record has them verbatim):
   1. **Fireworks take the same +1.2 s stretch** (≈ 6.43 s on a stack-clearing Confirm), built FIRST
      as `F-ConfirmCelebration-2`.
   2. **A "Celebrations" switch** (ON by default) turns off every full-screen celebration; haptics
      and pops stay. **A "Celebration sounds" switch** (OFF by default) adds one soft chime to the
      full-screen celebrations.
   3. **Celebrate DOING, not ADDING.** Four full-screen milestones at the every-Confirm size: inbox
      zero; a routine COMPLETED; a nudge streak landing on 7; the Momentum daily goal (any tab, ~1 s
      after the action, once per day). "The day cleared" dropped.
   4. **Nine in-place moments get a MINI CONFETTI POP** (task closes ×5, Sorted ×2, Journal it,
      Create Task, Done for now, each routine step); the closure card springs in.
   5. **Haptic only** for the adding moments; Save a place `.solid` and Stop sprint `.light` are new;
      Sorted `.success` on both screens; Done for now `.success` (the tidy, `F-CTACelebrations-1`).
   6. **Milestones on a cooldown** — 5 s for testing (§A) — falling back to the pop inside it;
      Confirm is never cooled down.
   7. **Every new site FADES under Reduce Motion**; Confirm stays the one waiver.
   8. **The routine Completed flow:** a Completed card once every step is resolved; the tap ends the
      run, writes the completed record, buzzes, and shows a TEMPORARY full-screen congratulation with
      the account display name and the confetti, auto-leaving when the confetti ends or on a tap;
      leaving without tapping keeps the run LIVE (reverses the leave-ends-run rule).
   9. **Architecture:** one App-owned `CelebrationCenter`, reached through an environment value with
      an inert default; one `CelebrationLayer(surface:)` per presented surface (root, the routine
      cover, the Tasks search surface, the Create Task sheet).
   **The blocks, in order:** ~~`F-ConfirmCelebration-2`~~ (DONE 2026-09-12, verdict PASSED) →
   ~~`F-CTACelebrations-1`~~ (DONE 2026-09-12, verdict PASSED) → `-2` (switches) → `-3` (centre + layers,
   Confirm re-routed) → `-4` (pops; render first, E picks) → `-5` (inbox zero, streak, daily goal)
   → `-6` (Completed flow; render the congratulation first) → `-7` (chime; E picks by ear).
   **For block 3 note:** the shared `CelebrationFrame` now has to carry the fireworks and the dim
   too (`ConfirmCelebrationScene.fireworks`, `ConfirmCelebrationDim`, `ConfirmFireworksDrawing`);
   the waiver pin lists six Confirm files, not three. (updated)

**0. Follow-ups to the modern-iOS pilot — only what E asks for.** (carried)
   - **RM arrival fade for the bottom furniture** (`RootBottomOverlay`'s three nil animations + the
     card's unconditional `.move + .opacity` transition), only if E likes the cross-fade. (carried)
   - **The modern-API inventory, register-only until each is a block.** (carried)
     - **Free at 16.0:** `.contentTransition(.numericText(countsDown: true))` on the sprint countdown
       and ~20 `.monospacedDigit()` counters; `.presentationBackground` (16.4) on three sheets.
     - **Needs 17:** `ContentUnavailableView` in four empty states; `.contentTransition(.symbolEffect(.replace))`
       for pause/play and the chevrons; interactive widgets and routine Live Activity check-off; the
       `@Observable` migration (27 classes); TipKit for the card's gestures.
     - **Needs 18/26:** `Tab`/`.tabBarMinimizeBehavior` and `.glassEffect`, both constrained by the
       custom `AppTabBar` (adoption means replacing it).
   - **Two RM sites that remove the press affordance entirely** (`AppTabBar.swift:266`,
     `AppSearchRow.swift:71`), and `RootView.swift:63`'s declared-but-unread `reduceMotion`. (carried)

1. **E's one un-run device check: airplane mode + pull-to-refresh on Home.** `F-HomeTasksLastKnown`
   (`8b5f740`) should keep the last-known task set rather than emptying it. (carried)

2. **`F-FocusCard-Corners` — after the arc (E: "Round them").** Round the collapsed card's bottom
   corners AND give `FocusBarCardShape.roundsBottomCorners` `animatableData`, so the corner morph
   stops SNAPPING inside the 350 ms spring. In `TODO-CLAUDE-CODE.md`. (NEW, absorbs the first bullet
   of the old §B.2)
   - Still open from the old §B.2, none blocking: the card's `.accessibilityAction(named:)` may
     attach to nothing (Accessibility Inspector pass wanted); `FocusTimerBarContent` has no
     `#Preview`; a slow location fix delays the completion CARD; the stack has no UI journey.
     (carried)

3. **Two more dead design tokens, and two dead helpers.** `BarSurface` is defined, unit-tested and
   used by nothing; `AppTabBarPresentation.slotWidth` / `restingSlotWidth` have ZERO production call
   sites and disagree about their input. (carried)
4. **Accuracy-aware containment for the arrival card — ONLY if E still sees drops after #32.**
   (carried)
5. **Arc 2 — first-class routines + the "at a time" trigger.** (carried)
6. **`F-Search-3-Journal`** — recommendation is still to kill the block. (carried)
7. **The Live Activity design review** E parked. (carried)

## C · Parked on E's instruction — do not start unprompted

- **A nudge-specific screen animation for EVERY "Done for now".** E, 2026-09-11: *"every 'done for
  now' must be given a different screen animation - We can handle this later."* Not designed; not in
  this arc. Ask E when the arc has shipped. (NEW)
- **14- and 21-day streak milestones** (R-b): the arc fires at exactly 7. (NEW)
- **Places backgrounding dismiss bug** — waiting on E's iOS update. (carried)
- **App connections** — real two-way sync; Apple Notes has no iOS API. (carried)
- **LA interactive buttons**, **time-of-day triggers**, **smart skip**. (carried)
- **`OfflineSprintSummaryCard`** — E ruled it out of the focus-card arc explicitly; "Got it" stays
  without a celebration (#5). (carried)

## C2 · Noticed, below the bar, worth E's eye on device

- **Under Reduce Motion the closure card's `withAnimation(.default)` also animates the SIBLING
  sections reflowing beneath it** (life areas, Due now, nudges), because they share the VStack and
  the transaction. §7.2 treats continuous re-layout as the one case where no animation is correct,
  and a single transaction cannot both fade the card in place and hard-cut the reflow under it.
  It only matters if `ClosureCelebrationCard` and `bestNextMoveSection` differ much in height.
  Raised by the reviewer subagent, below its reporting bar. **It is a REDUCED-path effect, and E
  now runs with Reduce Motion OFF, so E's passing verdict did not see it** — this cannot be
  written off as "tried and not noticed". It stays open and unjudged until someone looks with the
  setting on (§A). (updated)

## D · Launch blockers — no conversation opened yet

- **Free dev account** → 7-day profiles; the current one is valid to **2026-09-17**. When a device
  install fails on it, E re-signs in Xcode → Settings → Accounts. (carried)
- **Sign in with Apple** built but dormant. (carried)
- **A way to turn the Confirm confetti off — RESOLVED BY DESIGN, ships in `F-CTACelebrations-2`.**
  E chose a "Celebrations" switch, ON by default, covering every full-screen celebration, before any
  new full-screen site ships. Until that block lands the accepted cost stands: people who turned
  Reduce Motion on for motion sensitivity get full-screen falling confetti on Confirm with no
  escape. (updated)

## E · Known, not work

- **Xcode's MCP bridge was UP this session** (Xcode open before launch). `RenderPreview` rendered
  the new "Stack cleared · Light" preview in ~2 min and it matched the probe's still; the bar is
  still pasted `xcodebuild` output. (updated)
- **A green suite cannot see a `View`'s appearance.** Render to PNG from a unit test before the
  device build: `UIHostingController` + `UIGraphicsImageRenderer` + `drawHierarchy(afterScreenUpdates: true)`
  in a scene-attached `UIWindow`, a synchronous test pumping `RunLoop.main`; render IN SITU. The
  probes live outside the repo in the scratchpad and are rebuilt from the evidence READMEs. (carried)
- **`Executed N tests, with M failures` counts failed ASSERTIONS, not failing TESTS.** Predict in
  TESTS, then reconcile. (carried)
- **SwiftLint's 400-line file, 250-line `type_body_length` and 40-character `type_name` ceilings.**
  Two of the five near-ceiling files were cleared by this block's room-first commit; `RootView.swift`
  394, `CaptureInboxService.swift` 397 and `PlaceRoutineScreen.swift` 379 remain, and blocks `-3`
  and `-5` carry their own room-first commits for the first two. **Moving an extension to a new file
  ends same-file `private` access** — budget for widening every `private` the moved code touches.
  (updated)
- **A `devicectl` launch denied with `Security` right after a re-issued profile is TRANSIENT — retry
  once.** The three species: `Locked` (unlock), `Security` + valid profile (retry), `Security` +
  expired profile or "No Accounts" (E signs in via Xcode → Settings → Accounts). (carried)
- **A UI-target run poisons the simulator; erase it before the next unit run**
  (`xcrun simctl erase 9181EBF9-0F54-4A4D-A19C-19945D1BF155`). The routine journey pins the rule
  `F-CTACelebrations-6` reverses, so it WILL be run in that block. (carried, made specific)

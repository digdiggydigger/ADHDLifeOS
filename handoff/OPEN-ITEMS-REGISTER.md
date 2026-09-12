# Open items register — 2026-09-12 (thirty-first edition; the CTA celebrations arc's block 1, `F-ConfirmCelebration-2`, is BUILT, MERGED and PASSED E's device verdict; seven blocks remain)

*The close-out of the first build session of the CTA celebrations arc. E's asks this session,
verbatim: *"Start from handoff/START-HERE-cta-celebrations-build.md. Read it, then the design
record … and the register. Before building anything, ask me in one message whether the record is
approved and how R-a to R-h are ruled. Then build F-ConfirmCelebration-2 test-first and stop for my
device verdict. The cooldown stays at 5 s."* — and, mid-session, *"remember that you should use any
skills, MCPs, plugins or subagents to help your work."* E answered the gate question **"yes"**.

The opener `handoff/START-HERE-cta-celebrations-build.md` stays LIVE: it covers the whole arc and
the next session starts block 2 (`F-CTACelebrations-1`) from it once E's verdict on block 1 is in.
Supersedes the thirty earlier editions.*

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding, so it is the thing to read and to
update rather than improvising a list in chat.

## State

**`main` @ `9a7b664`** (PR #76, `F-ConfirmCelebration-2`). `firestore.rules` is untouched, so there
is **nothing for E to republish**.

**E's phone: `main @ 9a7b664` installed and launched from the CLI at the close of this session**
(see the session report for the install log; the profile is valid to 2026-09-17).

**Verified at `29c6267` (the block's green commit; PR #76 adds only evidence and the TODO tick):**
- unit suite **2,741 / 0**, emulator UP, **0** `127.0.0.1:9099` hits;
- SwiftLint **0 / 757**;
- sim `** BUILD SUCCEEDED **`; device build at the close (session report).

Coverage, measured at `29c6267`:

```
ADHD LifeOS.app              27.07%  (12635/46678)
ADHD LifeOSTests.xctest      94.99%  (43903/46220)
ADHD LifeOSUITests.xctest     0.00%  (0/2962)       ← skipped in the standard run by design
FocusTimerWidgetExtension    10.30%  (228/2214)     ← read the 233-line testable surface, not this
```

(Comparable with the 26.87 % (12,470/46,405) of the previous edition: the tree grew by this block's
three files and the numerator by their tests — `ConfirmFireworksPhysics` 100 %, `Schedule` 96 %,
`Drawing` 19 % because its Canvas operations are view territory, proved by the renders.)

### Landed this session

- **`F-ConfirmCelebration-2`** — the stack-clearing fireworks (14 shells in 9 tokens on the record's
  fixed schedule) and the light-only 85 % dim, on the SAME stretch as the confetti (E's decision 1):
  a stack-clearing Confirm is on screen ≈ 6.43 s, every other Confirm stays 5.4 s and is
  pixel-identical to block 1 (0 / 1,339,344, diffed against block 1's own rendering from a
  throwaway worktree). 31 tests; red 2,741 / 31 tests predicted and observed; red-check 5 / 5 by
  name; green 2,741 / 0. Evidence `screenshots/confirm-celebration-block-2/`. **Awaiting E's device
  verdict** (§A). (NEW)
- **E's approval of the CTA design record and R-a…R-h** ("yes"), recorded in the record and here.
  (NEW)

### What this session established

- **A render probe that drives the app on the real clock must be a SYNCHRONOUS test.** The first
  live run captured nothing: an `async` test method runs inside a main-queue block, and a nested
  `RunLoop.main.run(until:)` cannot drain the main queue from there, so the `Task` holding the
  Confirm never ran. §E already said "a synchronous test pumping `RunLoop.main`"; this is why.
  A 1.0 s settle before the reference captures also removes a 69-pixel tab-bar selection-spring
  artefact. (NEW)
- **The pixel-diff against block 1 was rendered by block 1's code, not by this tree with the
  feature off** — a `git worktree` at `b5fe8c8` with a two-appearance baseline probe. A diff
  against one's own tree proves only that the gate is closed, not that the drawing is unchanged.
  (NEW)
- **The reviewer subagent (`feature-dev:code-reviewer`) found nothing at its bar** and re-derived
  the 4.79 s last spark independently; it noted (below threshold) that a stack-clearing Confirm
  builds 220 pieces + 880 sparks synchronously at the busiest instant, a one-time cost that is
  E's phone's to measure. (NEW)
- A stray untracked `AGENTS.md` (a Codex copy of CLAUDE.md, not written by this session) appeared
  in the repo root mid-session; it was left out of every commit. E to decide whether it stays. (NEW)

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

E's phone runs **Reduce Motion ON (and Prefer Cross-Fade Transitions ON)**. CLAUDE.md §7 is the
rule; the Confirm celebration is its ONE waiver, and this arc's design does not extend it: every new
site fades (E's #7).

## A · Decisions only E can make — minutes each

- [x] **Review the design record** and rule on **R-a…R-h** — E, at the start of the build session
      2026-09-11, asked in one message with each default listed: **"yes"**. The record is approved
      and all eight recommendations stand as the build's defaults. (CLOSED)
- [x] **E's device verdict on `F-ConfirmCelebration-2`** — PASSED 2026-09-12, E: *"it looks good.
      It looks as if it's working as as you specified."* The block is CLOSED; the next is
      `F-CTACelebrations-1`. E also said to ignore the stray Codex `AGENTS.md` for now. (CLOSED)
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

**00. THE CTA CELEBRATIONS ARC — block 1 of 8 BUILT and MERGED (`F-ConfirmCelebration-2`, PR #76);
   the next is `F-CTACelebrations-1` once E's verdict is in.** The record is
   `handoff/SESSION-OPENER-cta-celebrations-design.md`; the opener is
   `handoff/START-HERE-cta-celebrations-build.md`; the blocks are in `TODO-CLAUDE-CODE.md`.
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
   `F-CTACelebrations-1` (haptic tidy + spring-in) → `-2` (switches) → `-3` (centre + layers,
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
  Five files near the first are listed above. (updated)
- **A `devicectl` launch denied with `Security` right after a re-issued profile is TRANSIENT — retry
  once.** The three species: `Locked` (unlock), `Security` + valid profile (retry), `Security` +
  expired profile or "No Accounts" (E signs in via Xcode → Settings → Accounts). (carried)
- **A UI-target run poisons the simulator; erase it before the next unit run**
  (`xcrun simctl erase 9181EBF9-0F54-4A4D-A19C-19945D1BF155`). The routine journey pins the rule
  `F-CTACelebrations-6` reverses, so it WILL be run in that block. (carried, made specific)

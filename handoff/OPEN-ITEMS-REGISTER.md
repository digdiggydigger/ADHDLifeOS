# Open items register — 2026-09-12 (thirty-fifth edition, amended; `F-CTACelebrations-4`, the nine mini confetti pops, is BUILT and MERGED, and **E has DEFERRED its device verdict until after `-5`**, so the RM-on pass will cover two blocks at once; **three blocks of the arc remain**)

*The close-out of the fifth build session of the CTA celebrations arc. E's standing ask — use any
skills, MCPs, plugins and subagents that help — was followed: the render probe, the `xcode` bridge's
absence worked around, a `feature-dev:code-reviewer` pass and an `apple:hig-reviewer` pass. What each
returned is below, and the code review **found a real defect that this block introduced**.

The opener `handoff/START-HERE-cta-celebrations-4.md` is SPENT — archived in the same move that
writes this edition and the next session's opener. Supersedes the thirty-four earlier editions.*

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding, so it is the thing to read and to
update rather than improvising a list in chat.

## State

**`main` @ `1b80cee`** (PR #94, `F-CTACelebrations-4`). `firestore.rules` is untouched, so there is
**nothing for E to republish**.

**Verified at `050e3b4`** (the block's last commit; the merge adds nothing):
- unit suite **2,824 / 0**, emulator UP, **0** `127.0.0.1:9099` hits;
- SwiftLint **0 / 780**;
- sim `** BUILD SUCCEEDED **`; device build, install and launch from `main` at the close.

Coverage, measured at `050e3b4`:

```
ADHD LifeOS.app              27.29%  (12949/47457)
ADHD LifeOSTests.xctest      94.78%  (45560/48068)
ADHD LifeOSUITests.xctest     0.00%  (0/2962)       ← skipped in the standard run by design
FocusTimerWidgetExtension    10.30%  (228/2214)     ← read the 233-line testable surface, not this
```

**Comparable with the previous edition's 27.42 % (12,949/47,221), and the FALL is honest.** Both runs
measured 100 % of the app target, which is CLAUDE.md's test for comparability. What moved is worth
saying precisely, because it is the cleanest example of the rule the file already states: **the
numerator did not move at all — 12,949 both times — and the denominator gained 236.** Every line
this block adds is inside a SwiftUI view body, which a unit test structurally cannot reach; the ten
wrapped call sites and the promote sheet's new state are all view-body lines. This is the same fact
CLAUDE.md records for the 108 files sitting at exactly 0 %, arriving as a ratio rather than as a
list. It is not decay, and it is not something a test could have prevented.

Per-file: every file this block touched is a view body at or near 0 % — `TaskRow` 3.27 % (9/275),
`MomentumScoreboardViews` 3.99 % (28/702), and the other nine at 0.00 %. `CelebrationPopSource`
remains **0/21**, and that is the point of the thirteen call-site guards: the wrapper's body is
never evaluated by a unit test, so reachability had to be asserted by reading the tree.

### Landed this session

- **`F-CTACelebrations-4`** — E's nine in-place moments wired to the mini confetti pop. **E picked
  variant A ("as designed") from four rendered in situ on a real `TaskRow`, and "keep rise-then-fall"
  for the still pop**, so `CelebrationRecipes` and `CelebrationStillField` are UNCHANGED and the
  block is call sites, one constant and one defect fix. Room first:
  `CaptureInboxSections.swift` 390 → 270. 14 tests. Evidence
  `screenshots/cta-celebrations-block-4/`. **Awaiting E's device verdict.** (NEW)
- **Four ways the build differed from the written plan, all recorded in `TODO-CLAUDE-CODE.md`:**
  `TaskRow` uses `.celebrationPopOrigin` rather than the wrapper; `CreateTaskButton` pops after the
  await; R-e's hold is scheduled rather than awaited; thirteen tests, not eleven. (NEW)
- **`CelebrationMountCallSiteTests`' open runtime question is CLOSED.** A layer inside a presented
  cover really does inherit the centre from outside it — 2,761 pixels drawn, against a control where
  a wrong-surface layer draws **0**. Both of block 3's probes had injected the environment
  themselves, so nothing had shown it at runtime. (NEW)

### What this session established

- **A guard that anchors on a string and then asserts that same string is inside the slice can never
  go green, and only a wrong red PREDICTION exposes it.** The first red check predicted 17 assertion
  failures and got 20. The three extra were not a forecasting error: three guards opened on
  `Button { Haptics.play(…)` and then asserted the haptic was in the slice, which starts AFTER its
  anchor. They would have stayed red however correctly the sites were wired. The haptic is now part
  of the anchor — the adjacency is structural — and `assertAnchorIsUnique` stops a guard silently
  reading a different button. **The corrected prediction, 13 / 17, matched exactly.** (NEW)
- **`feature-dev:code-reviewer` found a real defect, and it was this block's own.** R-e's hold buys
  the pop 0.45 s by SCHEDULING the dismiss, which left the promote sheet fully interactive for the
  whole hold with its work already committed. Cancel or swipe it away in that window and the
  orphaned hold still ran `onPromoted()` — `CaptureDetailView` passes `onPromoted: { dismiss() }`,
  so the DETAIL SCREEN popped about half a second after the user's own dismiss, unasked. Fixed with
  `hasPromoted`, set before the hold, gating Cancel, `.interactiveDismissDisabled` and the create
  button. **No test in the block could have seen it: it is a timing window, not a value.** (NEW)
- **`apple:hig-reviewer` found no violations** across accessibility, Reduce Motion, hit targets and
  photosensitivity, and confirmed two things worth having in writing: the pop can never contribute
  to a full-screen wash (`ConfirmCelebrationGlow` filters `isFullScreen`, `ConfirmCelebrationDim`
  filters `clearedStack`, and `.pop` is neither), so the §D photosensitivity finding does not extend
  to it; and `TaskRowPresentation.accessibilityLabel` already appends "closed" to the row's label, so
  a VoiceOver user closing a task gets the haptic AND a real state change, not just a burst they
  cannot perceive. **Two findings carried to §A rather than acted on.** (NEW)
- **Check how a site is PRESENTED before trusting that its pop will be seen.** The per-surface
  architecture fails silently: a site on a surface with no layer draws nothing and passes
  everything. All ten sites were traced to their presenters before the PR — every detail screen is a
  `navigationDestination` push, so the root layer covers it, and the only sheets in the tree that
  host a site are the promote sheet (which has its own layer) and `TaskCreateView` (an ADDING verb,
  deliberately no pop). Thirty seconds that would otherwise have been diagnosed on the phone. (NEW)
- **A `minHeight`-flexible row will eat the whole screen in a probe.** `TaskRow` is
  `.frame(minHeight: 56)`, so in a `VStack` with a `Spacer` it competes for the leftover height: the
  first set of variant renders was made on rows 172 pt tall instead of 74. `.fixedSize(horizontal:
  false, vertical: true)` on the card is the fix. (NEW)
- **To render the real feature rather than a picture of its drawing, let the handle escape the
  wrapper's body** — `CelebrationPopSource { handle in … .onAppear { box.handle = handle } }` gives
  a probe the same trigger the button has, so the render exercises the wrapper, the environment, the
  centre, the policy, the burst and the layer. (NEW)

### Carried from the design session

- **E's design answers are the spec.** Seven recommendations were overruled (a Finish button; a
  streak milestone and the daily goal; a chime; the mini confetti pop over the halo; the
  congratulation view; the display name; the 5 s cooldown). Record them, do not re-derive them.
- **Three app-level `ObservableObject`s**: `AuthService`, `FocusSessionService`, `CelebrationCenter`.
- **`onGeometryChange(for:of:action:)` is back-deployed to iOS 16.0** in the 26.5 SDK.
- **One file remains at the 400-line ceiling and needs a room-first commit before its block:**
  `CaptureInboxService.swift` 397. (`RootView.swift` 374, `CaptureInboxSections.swift` 270 and
  `PlaceRoutineScreen.swift` 384 are handled or clear.)
- **The Completed flow reverses an E-settled rule** (the routine-record arc's "a run ends when you
  LEAVE the screen"). The tests that pin the old rule must be updated by name, not silently.

## A · Decisions only E can make — minutes each

- [ ] **E's device verdict on `F-CTACelebrations-4` — DEFERRED BY E until after `F-CTACelebrations-5`**
      (2026-09-12, verbatim: *"I will push the device passes off until after the next block."*).
      **This is a scheduling decision, not an outstanding failure**: `-4` is landed, green and
      installed on the phone from `main`. Do not re-ask before `-5` is built, and do not treat `-4`
      as unverified work to redo.
      **The consequence to plan for:** `-5` adds reduced sites of its own, so the passes when they
      happen cover BOTH blocks. Ask once, at the close of `-5`, naming which sites belong to which
      block so a failure can be attributed. Until then both blocks' Verified-paths lines read
      *"Reduced: run on sim (injected); NOT on device."*
      It still needs TWO passes in one sitting (§7.3, E's own call): Reduce Motion OFF, then ON
      (Settings → Accessibility → Motion). What to exercise for `-4`, because the simulator could
      not prove these:
      the Tasks **search surface** (a real `fullScreenCover` — the probe used a synthetic one);
      **Create Task** from the promote sheet (R-e's 0.45 s hold — the top of the pop is expected to
      clip at the sheet's edge, §C2, by design); the task detail's **Close it** (the root layer
      beating Form-row clipping); a **routine step**; and a circle tap AND a swipe on the same row
      (one origin). **Nine reduced sites, and no waiver applies to any of them** — the Confirm's
      §7.2 waiver covers the Confirm alone. (NEW)
- [ ] **The pop is not gated by the Celebrations switch, and the `apple:hig-reviewer` pass asks
      whether that should stay.** It is E's #3, decided deliberately, and the Settings footer says
      so out loud ("haptics and the small in-place flourishes are left alone either way"), so it is
      not a misleading control. What the pass names is the consequence: a user who wants ZERO
      decorative motion on a rapid closing streak has no path to it except Reduce Motion, which
      stills the pop rather than removing it — in an app whose own brief is to prevent visual
      distraction. **Nothing was changed.** The options are to leave it (E's existing call), to let
      the Celebrations switch cover pops too, or to add a third switch. (NEW)
- [ ] **PHOTOSENSITIVITY — the fireworks' flash rate, and this one is a launch-safety question, not
      a polish one.** The 14 shells' burst flashes land at **5 inside one second** (from ≈ 2.00 s),
      against **WCAG 2.3.1's threshold of 3**. Each flash is a radial gradient growing 40 → 240 pt
      at up to 0.35 alpha, over 0.35 s.
      **What is NOT claimed:** whether the luminance delta and the screen area also cross the
      guideline's thresholds is **unmeasured** — the flash COUNT alone is what crosses. There is no
      app-readable API for iOS's "Dim Flashing Lights", so this cannot be gated in code.
      **This block's HIG pass confirmed the finding does NOT extend to the pop**: a pop can never
      contribute to the glow or the dim, because both filter on `isFullScreen` / `clearedStack` and
      `.pop` is neither. The finding is the stack-clearing Confirm's alone. **It is E's call**:
      measure the luminance properly, thin the two clusters, or accept it. (updated)
- [ ] **An accessibility ANNOUNCEMENT for the milestones, owed before `F-CTACelebrations-5` wires
      the first one.** A full-screen celebration is `accessibilityHidden`, which is right for
      Confirm and right for all nine of this block's sites — each has a haptic and a real on-screen
      change, and this block's HIG pass confirmed that. It is NOT right for a milestone whose site
      has neither, and R-h names the ring and the Completed button as exactly those. The house
      precedent is `TaskDetailFormSections.swift`'s
      `UIAccessibility.post(notification: .announcement, …)`, queued behind what VoiceOver is
      already reading. `-5` should not ship without deciding it. (carried, sharpened)
- [ ] **The milestone cooldown.** E: *"i am undecided about the cooldown at the moment anyway."* It
      ships at **5 s for testing**; whether it exists and at what value is E's call on the phone
      after `F-CTACelebrations-5`. (carried; untouched this session)
- [ ] **Install an older simulator runtime** via Xcode → Settings → Components. E, 2026-09-11:
      *"In a number of days in the future, I will install this."* Until then every `#available`
      fallback is compile-only by policy (§7.3). (carried)
- [ ] **Optional, still not decided: an `.accessibilityHint` on the Celebration sounds row only.**
      Defensible either way; nothing was added. (carried)
- [x] **E's device verdict on `F-CTACelebrations-3` — PASSED 2026-09-12** ("it passes, looks exactly
      the same", the right answer to a deliberately negative test). (CLOSED)
- [x] **E's device verdicts on `F-CTACelebrations-1`, `-2` and `F-ConfirmCelebration-2`** — all
      PASSED 2026-09-12. (CLOSED)
- [x] **How does the reduced path get DEVICE time now that E runs with Reduce Motion OFF?** —
      **E chose (a), 2026-09-12**, written into CLAUDE.md §7.3. **It bites for the first time
      NOW**, on this block's verdict. (CLOSED)
- [x] **Review the design record** and rule on **R-a…R-h** — E: **"yes"**. (CLOSED)

## B · Real work, ready to start — recommended order

**00. THE CTA CELEBRATIONS ARC — blocks 1–5 of 8 BUILT and MERGED; the next is
   `F-CTACelebrations-5`, the three full-screen milestones.** The record is
   `handoff/SESSION-OPENER-cta-celebrations-design.md`; the opener is the session's own
   `handoff/START-HERE-*`; the blocks are in `TODO-CLAUDE-CODE.md`.
   **The blocks, in order:** ~~`F-ConfirmCelebration-2`~~ → ~~`F-CTACelebrations-1`~~ →
   ~~`-2`~~ → ~~`-3`~~ (centre + layers) → ~~`-4`~~ (the nine pops; **verdict pending**) →
   **`-5`** (inbox zero, the streak on 7, the daily goal) → `-6` (the routine Completed flow) →
   `-7` (the chime).
   **For block 5, five things this block leaves it:**
   - **Room first, its own commit:** `CaptureInboxService.swift` is at **397** of 400.
   - **§B.00b's latent defect becomes REACHABLE in this block** — read it below before touching the
     centre, and note R-e's hold interacts with it: a held inbox-zero burst is released 0.45 s after
     the pop the same tap threw.
   - **The accessibility announcement (§A) is owed before the first milestone ships**, because the
     ring and the Completed button are sites with no pop and no haptic of their own.
   - **E's cooldown call (§A)** comes after this block, on the phone. It ships at 5 s.
   - **Do NOT "correct" this block's two deviations.** `TaskRow` uses `.celebrationPopOrigin` and
     not `CelebrationPopSource` on purpose — its circle and its swipe share one `close()`, and the
     wrapper would move the origin to the middle of the row. `CreateTaskButton` pops after the
     await on purpose — a create can fail. Both are pinned by name in
     `CelebrationPopCallSiteTests`. (NEW)

**00b. A LATENT defect in `CelebrationCenter`, still NOT fixed, and `-5` is where it becomes
   reachable.** `request(_:at:)` stamps `lastFullScreenAt` and fires the `chime` hook when the
   outcome is `.fullScreen` — **before** the held branch — and `releaseHeld()` sets neither. Two
   consequences:
   - a burst HELD behind the Create Task sheet chimes while the sheet is still up, before any
     confetti is drawn, rather than when it plays;
   - a held burst DROPPED at 60 s (R-g) has already chimed and already stamped the cooldown, for a
     celebration that never appeared — so it can silence a real milestone that follows it.

   **Unreachable until `-5`**: the only thing that requests `.fullScreen` today is the Confirm
   bridge on `RootBottomOverlay`, which sits BELOW every sheet. Inbox zero via the promote sheet is
   exactly the held path, so `-5` makes it reachable and `-7` makes it audible. Fix it in whichever
   lands first: move the stamp and the chime to the moment a burst actually starts, so a held
   release and a direct enqueue go through one place. **`CelebrationCenterTests` has no test of
   held-burst stamp or chime timing** — closing that gap is part of the fix. (carried)

**0. Follow-ups to the modern-iOS pilot — only what E asks for.** (carried)
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

- **Eight of the ten pop sites are OPTIMISTIC — they pop before the work is known to have
  succeeded.** Raised by the `apple:hig-reviewer` pass. Each fires in the same closure and at the
  same instant as the haptic that was already there, so it is not a new species of risk; and
  `CreateTaskButton` is deliberately the exception, popping only inside `if succeeded`, because a
  create can fail. The one worth a second look is **Sorted from the triage card**
  (`CaptureInboxSections.swift`), where the `await service.sort(...)` genuinely can return false.
  Not changed: doing so would mean the paper arrives late at every one of the eight. (NEW)
- **The promote sheet's celebration layer is sized to the SHEET, not the screen**, so the Create
  Task pop clips at the sheet's top edge. By design, and now visible for 0.45 s rather than not at
  all (R-e). Worth E's eye on device — if it reads badly, the fix is R-e's alternative: no pop
  there. (updated)
- **Under Reduce Motion the closure card's `withAnimation(.default)` also animates the SIBLING
  sections reflowing beneath it.** A REDUCED-path effect, and E now runs with Reduce Motion OFF, so
  E's passing verdicts did not see it. **The RM-on pass this block owes is the natural moment to
  look.** (updated)
- **The Feedback section's footer is a thirteen-line paragraph** covering six switches. If it reads
  as a wall on the phone, splitting the two celebration rows into their own `Section` is the fix,
  and it is E's call. (carried)

## D · Launch blockers — no conversation opened yet

- **Free dev account** → 7-day profiles; the current one is valid to **2026-09-17**. When a device
  install fails on it, E re-signs in Xcode → Settings → Accounts. (carried)
- **Sign in with Apple** built but dormant. (carried)
- **Photosensitivity: the stack-clearing Confirm's fireworks flash 5 times in one second** against
  WCAG 2.3.1's 3. Full detail, and what is and is not claimed, in §A — **including this block's
  confirmation that the finding does not extend to the pop**. The Reduce Motion half of the old
  "accepted cost" was PAID by `F-CTACelebrations-2`'s Celebrations switch; photosensitivity is a
  different axis, is not answered by that switch, and is unresolved. (updated)

## E · Known, not work

- **The `xcode` MCP bridge was NOT USED this session.** `RenderPreview` had already failed twice in
  the previous session for the same kind of target, and the block's opener says not to sink time
  into it; the run-loop-pumping probe is the sanctioned fallback and did everything needed,
  including recording video off the real `TimelineView` clock. (updated)
- **A stale `TestResults.xcresult` fails the whole suite before a test runs.** Gitignored, so it
  survives everything; delete it as part of the run. It was present at session start again.
  (carried)
- **A green suite cannot see a `View`'s appearance, and it cannot see a TIMING WINDOW either.**
  Render to PNG from a unit test before the device build; render IN SITU; always render the CONTROL;
  prove the harness deterministic before any pixel claim. **And this session added the other half:
  the one real defect in the block was a 0.45 s window in which an already-succeeded sheet stayed
  interactive — no assertion in 2,824 tests could see it, and a review pass over the diff did.**
  (updated)
- **`Executed N tests, with M failures` counts failed ASSERTIONS, not failing TESTS.** Predict in
  TESTS as well, and treat a MISS as a possible defect in the guards rather than a bad forecast —
  this session's 17-vs-20 miss was exactly that. (updated)
- **SwiftLint's 400-line file ceiling.** `CaptureInboxService.swift` 397 remains. **Moving an
  extension to a new file ends same-file `private` access, and breaks any call-site test that reads
  the old file** — `testTrailingClearanceStillReadsTheMetricDirectly` asserted the old filename and
  was updated by name, found by reading the test BEFORE the move. (updated)
- **`multiple_closures_with_trailing_closure`**: adding `onDismiss:` to a `.sheet` or
  `.fullScreenCover` means the content must become an explicit `content:` argument, which rewraps
  the call and breaks any test anchored on the one-line form. (carried)
- **A `devicectl` launch denied with `Security` right after a re-issued profile is TRANSIENT — retry
  once.** (carried)
- **A UI-target run poisons the simulator; erase it before the next unit run**
  (`xcrun simctl erase 9181EBF9-0F54-4A4D-A19C-19945D1BF155`). No UI target was run this session.
  (carried)

# Open items register — 2026-09-12 (thirty-fourth edition; `F-CTACelebrations-3`, the centre and the shared layer, is BUILT and MERGED and **awaits E's device verdict**; **four blocks of the arc remain**)

*The close-out of the fourth build session of the CTA celebrations arc. E's ask this session,
verbatim and restated mid-session: *"Remember that you should make use of ANY skills, MCPs, Plugins
and subagents to assist you in your work"* — the TDD skill, the `xcode` MCP bridge, a
`feature-dev:code-reviewer` pass and an `apple:hig-reviewer` pass all ran; what each returned is
below.

The opener `handoff/START-HERE-cta-celebrations-3.md` is SPENT — it is archived in the same move
that writes this edition and the next session's opener. Supersedes the thirty-three earlier
editions.*

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding, so it is the thing to read and to
update rather than improvising a list in chat.

## State

**`main` @ `c10813d`** (PR #90, `F-CTACelebrations-3`). `firestore.rules` is untouched, so there
is **nothing for E to republish**.

**Verified at `2a441db`** (the block's last commit; the merge adds nothing):
- unit suite **2,810 / 0**, emulator UP, **0** `127.0.0.1:9099` hits;
- SwiftLint **0 / 778**;
- sim `** BUILD SUCCEEDED **`; device build, install and launch at the close.

Coverage, measured at `2a441db`:

```
ADHD LifeOS.app              27.42%  (12949/47221)
ADHD LifeOSTests.xctest      94.83%  (45333/47806)
ADHD LifeOSUITests.xctest     0.00%  (0/2962)       ← skipped in the standard run by design
FocusTimerWidgetExtension    10.30%  (228/2214)     ← read the 233-line testable surface, not this
```

**Comparable with the previous edition's 27.05 % (12,659/46,799), and the rise is real.** The
denominator moved by 422 lines because the TREE grew — this block's production lines — and both
runs measured 100 % of the app target, which is CLAUDE.md's test for comparability. The numerator
grew faster than the denominator (+290 against +422 on a base that is only 27 % covered), which is
what a block whose logic is all pure and all tested looks like.

Per-file, the honest picture — everything that is not a view body is at 100 %:

```
Celebrations/CelebrationCenter.swift      100.00% (87/87)
Celebrations/CelebrationPolicy.swift      100.00% (15/15)
Celebrations/CelebrationMotion.swift      100.00% (4/4)
Celebrations/CelebrationRecipes.swift     100.00% (135/135)
Celebrations/CelebrationBurst.swift       100.00% (51/51)
Focus/ConfirmCelebrationRecipe.swift      100.00% (99/99)
Celebrations/CelebrationRequesting.swift   50.00% (4/8)     ← the two environment get/set pairs
Celebrations/CelebrationFrame.swift         0.00% (0/211)   ← view body
Celebrations/CelebrationLayer.swift         0.00% (0/109)   ← view body
Celebrations/CelebrationPopSource.swift     0.00% (0/21)    ← view body, and no call site until -4
```

**The centre reached 100 % because the coverage report was READ, not assumed.** At first pass it
was 96.55 %, and the three uncovered lines were the init's three production DEFAULT arguments —
`Date.init`, `AppFeedback.celebrationsEnabled()` and the no-op chime. Every test injected all
three, so the ones the APP uses had never been evaluated: live, shipped, unexercised paths, exactly
the `F-AdapterDrift` lesson. `CelebrationDefaultsTests` closes them, plus
`InertCelebrationRequester` (the shipped default of `\.celebrate`, which runs in every preview and
was called by nothing), and was red-checked by planting four faults — 4 / 4 tests red, restored
with `git checkout --` and proved by rebuilding. The four lines left in `CelebrationRequesting` are
the environment getters and setters, reachable only through SwiftUI's environment; they are the
honest floor.

### Landed this session

- **`F-CTACelebrations-3`** — E's ARCH answer built: one App-owned `CelebrationCenter`, one
  `CelebrationLayer(surface:)` per presented surface, and Confirm re-routed through the centre with
  `ConfirmCelebrationOverlay.swift` deleted. Room first (`RootView.swift` 394 → 374). 53 tests.
  Evidence `screenshots/cta-celebrations-block-3/`. **Awaits E's device verdict.** (NEW)
- **Four ways the build differed from the written design, all recorded in `TODO-CLAUDE-CODE.md`:**
  four `onDismiss`es not three (`CapturePromoteSheet` has two presenters); no `originOffset` on the
  frame (the stage resolves it, so the frame stays a pure function of scenes + date); the §7.2
  waiver pin kept its NAME but not its body, because it read the file the block deletes; and
  `CelebrationPopSource` / `.pop` / the three new recipes have **no production call site until
  `-4`/`-5`**. (NEW)

### What this session established

- **A room-first commit can pass lint and the build and still break the suite, and only the suite
  says so.** Moving `searchScope`, `showsPill` and `refreshCaptureInboxCount()` out of
  `RootView.swift` broke `AppSearchCallSiteTests` and `CaptureDiscPillCallSiteTests`, which read
  that file for members that had moved. Both now read BOTH halves of the type, which is the
  property they were always asserting. **Run the suite after a room-first commit, not just lint and
  the build.** (NEW)
- **A pixel-identity claim needs the harness proved deterministic FIRST, and then the difference
  explained rather than asserted.** The moved frame differed from the shipped one in up to 109,847
  pixels — alarming until measured: every difference was **one 8-bit level in one channel**, and in
  an otherwise-empty frame it was a single full-width row. The decisive control was rendering the
  *same unchanged code* in a different process, which reproduced the identical counts. Diagnose
  where and by how much before concluding anything about what changed. (NEW)
- **`TimelineView` draws at the REAL instant, so a burst dated in the future renders an empty
  canvas — and two empty canvases agree with each other.** The Reduce Motion comparison passed
  VACUOUSLY the first time for exactly this reason; the only tell was the PNG being byte-for-byte
  the size of the empty-frame baseline. Compare at a fixed `date` through the frame, and give every
  "identical" claim a control that proves the comparison can see a real difference. (NEW)
- **Guess bounds last.** The forced-still control was written as `> 100_000` and failed at 62,996
  with the code entirely correct. A still field is 120 pieces at rest against 220 in flight. (NEW)
- **Capture the "before" BEFORE deleting the file.** Twelve renders of the shipped
  `ConfirmCelebrationFrame` were taken and kept outside the repo in the same session, ahead of the
  deleting commit. Once the file was gone there would have been no "today" left to diff. (NEW)
- **`feature-dev:code-reviewer` found nothing at its bar** and confirmed four things worth having in
  writing: `releaseHeld()` clears `held` before iterating, so a redundant `surfaceDismissed` cannot
  double-release; a released burst reuses its own ordinal and was never in `bursts` before, so it
  cannot collide; release targets `frontmost` computed AFTER the dismissed surface is removed; and
  `FocusConfirmation` carries an incrementing ordinal, so `.onChange` fires for back-to-back
  Confirms and the bridge cannot silently miss one. (NEW)
- **`apple:hig-reviewer` found no violations** and called it ready to merge, confirming the
  decorative treatment (`accessibilityHidden` + `allowsHitTesting(false)`) is correct for VoiceOver,
  Switch Control and Full Keyboard Access across all four simultaneous mounts. **Two findings were
  carried to this register rather than acted on** — §A below — and it correctly declined to
  recommend touching E's Reduce Motion waiver. (NEW)

### Carried from the design session

- **E's design answers are the spec.** Seven recommendations were overruled (a Finish button; a
  streak milestone and the daily goal; a chime; the mini confetti pop over the halo; the
  congratulation view; the display name; the 5 s cooldown). Record them, do not re-derive them.
- **Only two `ObservableObject`s were app-level** (`AuthService`, `FocusSessionService`); as of this
  block there are **three** — `CelebrationCenter` joined them, owned by the App.
- **`onGeometryChange(for:of:action:)` is back-deployed to iOS 16.0** in the 26.5 SDK.
- **Two files remain at or near the 400-line ceiling** and need room-first commits before their
  blocks: `CaptureInboxService.swift` 397, `PlaceRoutineScreen.swift` 379. (`RootView.swift` is
  handled — 374.)
- **The Completed flow reverses an E-settled rule** (the routine-record arc's "a run ends when you
  LEAVE the screen"). The tests that pin the old rule must be updated by name, not silently.

## A · Decisions only E can make — minutes each

- [ ] **E's device verdict on `F-CTACelebrations-3`.** The app is installed and launched on the
      phone from `main` @ `c10813d`. **What to check, and it is deliberately a NEGATIVE test:**
      finish a focus sprint and Confirm it — **the celebration should look exactly as it did
      yesterday**, glow and confetti, with the stack-clearing Confirm still getting its fireworks
      and (in light mode) its dim. Then turn **Celebrations off** in Settings → Feedback and Confirm
      again: nothing should play, and the phone should still buzz. Nothing NEW is visible in this
      block; if anything looks different, that is the bug. **No Reduce Motion pass is owed or
      asked for** (§7.3): the block adds no reduced site. (NEW)
- [ ] **PHOTOSENSITIVITY — the fireworks' flash rate, and this one is a launch-safety question, not
      a polish one.** The `apple:hig-reviewer` pass raised it and the arithmetic was re-derived
      independently here from `ConfirmFireworksSchedule` and `ConfirmFireworksPhysics`: the 14
      shells' burst flashes land at **5 inside one second** (the window from ≈ 2.00 s), against
      **WCAG 2.3.1's threshold of 3**. Each flash is a radial gradient growing 40 → 240 pt at up to
      0.35 alpha, over 0.35 s.
      **What is NOT claimed:** whether the luminance delta and the screen area also cross the
      guideline's thresholds is **unmeasured** — the flash COUNT alone is what crosses. And there is
      no app-readable API for iOS's "Dim Flashing Lights", so this cannot be gated in code; it is a
      design-level number.
      **Nothing was changed**, deliberately: the schedule is E's, chosen by watching video at 85 %
      dim, and only the stack-clearing Confirm plays it. **It is E's call**, and the options are to
      measure the luminance properly, to thin the two clusters, or to accept it. Related to the
      accepted cost §D has recorded since 2026-09-11. (NEW)
- [ ] **An accessibility ANNOUNCEMENT for the milestones, owed before `F-CTACelebrations-5` wires
      the first one.** The HIG pass's point is sound: a full-screen celebration is
      `accessibilityHidden`, which is right for Confirm (the completion card already changes on
      screen) but leaves a VoiceOver user with **nothing at all** for a milestone whose site has no
      pop and no haptic of its own — R-h names the ring and the Completed button as exactly those.
      The house precedent is `TaskDetailFormSections.swift:265`
      (`UIAccessibility.post(notification: .announcement, …)`, queued behind what VoiceOver is
      already reading). **Nothing was added in this block**, because no milestone site exists yet
      and an unused hook is dead code — but `-5` should not ship without deciding it. (NEW)
- [ ] **The milestone cooldown.** E: *"i am undecided about the cooldown at the moment anyway."* It
      ships at **5 s for testing**; whether it exists and at what value is E's call on the phone
      after `F-CTACelebrations-5`. (carried; untouched this session)
- [ ] **Install an older simulator runtime** via Xcode → Settings → Components. E, 2026-09-11:
      *"In a number of days in the future, I will install this."* Until then every `#available`
      fallback is compile-only by policy (§7.3). (carried)
- [ ] **Optional, still not decided: an `.accessibilityHint` on the Celebration sounds row only.**
      Defensible either way; nothing was added. (carried)
- [x] **E's device verdict on `F-CTACelebrations-2` — PASSED 2026-09-12.** "All correct — passes",
      *"They were both successful."* (CLOSED)
- [x] **How does the reduced path get DEVICE time now that E runs with Reduce Motion OFF?** —
      **E chose (a), 2026-09-12**, written into CLAUDE.md §7.3. **The first block it bites is
      `F-CTACelebrations-4`**, the nine pops. (CLOSED)
- [x] **Review the design record** and rule on **R-a…R-h** — E: **"yes"**. (CLOSED)
- [x] **E's device verdicts on `F-CTACelebrations-1` and `F-ConfirmCelebration-2`** — both PASSED
      2026-09-12. (CLOSED)

## B · Real work, ready to start — recommended order

**00. THE CTA CELEBRATIONS ARC — blocks 1–4 of 8 BUILT and MERGED; the next is
   `F-CTACelebrations-4`, the nine mini confetti pops.** The record is
   `handoff/SESSION-OPENER-cta-celebrations-design.md`; the opener is the session's own
   `handoff/START-HERE-*`; the blocks are in `TODO-CLAUDE-CODE.md`.
   **The blocks, in order:** ~~`F-ConfirmCelebration-2`~~ → ~~`F-CTACelebrations-1`~~ →
   ~~`-2`~~ (all three verdicts PASSED) → ~~`-3`~~ (centre + layers; **verdict pending**) →
   **`-4`** (the nine pops; render on a real `TaskRow` FIRST, E picks by looking) →
   `-5` (inbox zero, streak, daily goal) → `-6` (the routine Completed flow) → `-7` (the chime).
   **For block 4, four things this block leaves it:**
   - **It is the first block that owes an RM-on DEVICE pass** (§7.3, E's call). Ask for both passes
     in one message so E flips the setting once.
   - **`CelebrationPopSource` and `CelebrationRecipes.pop`/`stillPop` exist and nothing calls
     them.** Block 4 is where the reachability guard belongs — `CelebrationPopCallSiteTests`, one
     prose test per site.
   - **The still pop has NO hold at full opacity**: `fadeIn` 0.3 + `fadeOut` 0.7 = `popLength` 1.0
     exactly, so it rises and immediately falls. The HIG pass flagged it as probably intentional
     rather than a typo. **Judge it when E looks at the render, and say it is a rise-then-fall.**
   - The pop's origin is recorded GLOBAL and converted in `CelebrationStage`; a `TaskDetail` Form
     row is drawn by the ROOT layer, which is what beats row clipping. (NEW)
   - **Cover environment inheritance is pinned by a call-site test, and UNEXERCISED at runtime.**
     `CelebrationMountCallSiteTests` asserts the two `.environment(...)` lines sit outside the
     covers' chain, and block 3's renders prove the layers draw — but both probes injected the
     environment themselves, so nothing has yet proved a layer inside a `fullScreenCover` inherits
     the centre from `RootView` at runtime. **No cover-hosted celebration exists until block 4**,
     so the first pop on `TaskSearchSurface` is also the first real test of that wiring. Read it as
     one. (NEW)

**00b. A LATENT defect in `CelebrationCenter`, found after the close-out and deliberately NOT fixed
   in block 3.** `request(_:at:)` stamps `lastFullScreenAt` and fires the `chime` hook when the
   outcome is `.fullScreen` — **before** the held branch — and `releaseHeld()` sets neither. Two
   consequences, both wrong once anything depends on them:
   - a burst HELD behind the Create Task sheet chimes while the sheet is still up, ~0.45 s before
     any confetti is drawn (R-e's hold), rather than when it plays;
   - a held burst DROPPED at 60 s (R-g) has already chimed and already stamped the cooldown, for a
     celebration that never appeared — so it can silence a real milestone that follows it.

   **Unreachable today**, which is why it was left: the only thing that requests `.fullScreen` is
   the Confirm bridge on `RootBottomOverlay`, which sits BELOW every sheet, so a Confirm cannot be
   tapped while the promote sheet is frontmost. It becomes reachable at **`-5`** (inbox zero via
   the promote sheet is exactly the held path) and audible at **`-7`** (the real player). Fix it in
   whichever lands first: move the stamp and the chime to the moment a burst actually starts, so
   both a held release and a direct enqueue go through one place. **`CelebrationCenterTests` has no
   test of held-burst stamp or chime timing** — that gap is the reason this was not caught by the
   suite, and closing it is part of the fix. (NEW)

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
   small tests, no production change. Note the same species was just closed for the celebration
   centre's defaults, so the pattern is proven worth closing. (carried)

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

- **Under Reduce Motion the closure card's `withAnimation(.default)` also animates the SIBLING
  sections reflowing beneath it.** A REDUCED-path effect, and E now runs with Reduce Motion OFF, so
  E's passing verdict did not see it. It stays open and unjudged until someone looks with the
  setting on — which, under §7.3's RM-on pass, happens naturally at `F-CTACelebrations-4`. (carried)
- **The Feedback section's footer is a thirteen-line paragraph** covering six switches. If it reads
  as a wall on the phone, splitting the two celebration rows into their own `Section` is the fix,
  and it is E's call. (carried)
- **The promote sheet's celebration layer is sized to the SHEET, not the screen.** Harmless today
  and by design — a full-screen celebration requested while that sheet is frontmost is HELD and
  released over whatever is behind it, so the only thing that layer ever draws is a pop. Noted
  because it would matter if `dismissesItself` were ever turned off for that surface. (NEW)

## D · Launch blockers — no conversation opened yet

- **Free dev account** → 7-day profiles; the current one is valid to **2026-09-17**. When a device
  install fails on it, E re-signs in Xcode → Settings → Accounts. (carried)
- **Sign in with Apple** built but dormant. (carried)
- **Photosensitivity: the stack-clearing Confirm's fireworks flash 5 times in one second** against
  WCAG 2.3.1's 3. Full detail, and what is and is not claimed, in §A. **This supersedes the shape
  of the old "accepted cost" line here:** the Reduce Motion half of that cost was PAID by
  `F-CTACelebrations-2`'s Celebrations switch — there is an off switch now, one tap away — but a
  photosensitivity risk is a different axis from motion sensitivity, it is not answered by that
  switch being available, and it is unresolved. (NEW)

## E · Known, not work

- **The `xcode` MCP bridge was UP this session** (Xcode was open before it started), but
  `RenderPreview` returned `The data couldn't be read because it is missing.` for both preview
  indices of the target file, twice. Not diagnosed further — the run-loop-pumping probe is the
  sanctioned fallback and was used instead. `XcodeListWindows` and `XcodeLS` worked normally, so
  the bridge itself was healthy. (NEW)
- **A stale `TestResults.xcresult` fails the whole suite before a test runs.** Gitignored, so it
  survives everything; delete it as part of the run. (carried)
- **A green suite cannot see a `View`'s appearance.** Render to PNG from a unit test before the
  device build; render IN SITU, and always render the CONTROL. **And prove the harness is
  deterministic before making any pixel claim** — one scene rendered twice in the same run must come
  back identical, or a cross-run difference says nothing. (updated)
- **`Executed N tests, with M failures` counts failed ASSERTIONS, not failing TESTS.** Predict in
  TESTS, and when a block introduces a symbol, predict the BUILD FAILURE separately — that half
  prints no count at all. Both halves matched exactly again this session. (carried)
- **SwiftLint's 400-line file ceiling.** `CaptureInboxService.swift` 397 and
  `PlaceRoutineScreen.swift` 379 remain. **Moving an extension to a new file ends same-file
  `private` access** — and breaks any call-site test that reads the old file. (updated)
- **`multiple_closures_with_trailing_closure`**: adding `onDismiss:` to a `.sheet` or
  `.fullScreenCover` means the content must become an explicit `content:` argument, which rewraps
  the call over several lines and breaks any test anchored on the one-line form. Two were, and they
  now read the source flattened. (NEW)
- **A `devicectl` launch denied with `Security` right after a re-issued profile is TRANSIENT — retry
  once.** (carried)
- **A UI-target run poisons the simulator; erase it before the next unit run**
  (`xcrun simctl erase 9181EBF9-0F54-4A4D-A19C-19945D1BF155`). No UI target was run this session.
  (carried)

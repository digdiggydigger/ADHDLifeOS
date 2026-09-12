# Open items register — 2026-09-12 (thirty-third edition; `F-CTACelebrations-2`, the two switches, is BUILT and MERGED and awaits E's device verdict; **five blocks of the arc remain**)

*The close-out of the third build session of the CTA celebrations arc. E's asks this session,
verbatim: the opener's instruction, *"go with (a), start block 3 in a fresh Claude code terminal
session"*, and mid-session *"Remember that you should make use of ANY skills, MCPs, Plugins and
subagents to assist you"*.

The opener `handoff/START-HERE-cta-celebrations-2.md` is SPENT — it is archived in the same move
that writes this edition and the next session's opener. Supersedes the thirty-two earlier editions.*

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding, so it is the thing to read and to
update rather than improvising a list in chat.

## State

**`main` @ `2efd705`** (PR #87, `F-CTACelebrations-2`). `firestore.rules` is untouched, so there
is **nothing for E to republish**.

**Verified at `f31ec6d`** (the block's last commit; the merge adds nothing):
- unit suite **2,757 / 0** (2,747 + this block's ten), emulator UP, **0** `127.0.0.1:9099` hits;
- SwiftLint **0 / 762**;
- sim `** BUILD SUCCEEDED **`; device build and install at the close.

Coverage, measured at `f31ec6d`:

```
ADHD LifeOS.app              27.05%  (12659/46799)
ADHD LifeOSTests.xctest      94.87%  (44329/46725)
ADHD LifeOSUITests.xctest     0.00%  (0/2962)       ← skipped in the standard run by design
FocusTimerWidgetExtension    10.30%  (228/2214)     ← read the 233-line testable surface, not this
```

**Comparable with the previous edition's 27.07 % (12,643/46,702), and the two-hundredths of a point
is real rather than noise.** The denominator moved by 97 lines because the TREE grew by this block's
production lines, and both runs measured 100 % of the app target — CLAUDE.md's test for
comparability. The ratio fell because **most of what this block added is view body**: the two
`Toggle`s and the rewritten footer live in `SettingsPreferenceSections.swift`, which is 0 % (0/547)
and structurally out of a unit test's reach, while the logic that CAN be reached went to 100 %.

Per-file, the honest picture:

```
MomentumPreferences.swift        100.00% (81/81)     ← every line of the four-place edit
AppFeedback.swift                 66.67% (12/18)     ← was 6/12 (50%) before this block
SettingsPreferenceSections.swift   0.00% (0/547)     ← view body
ConfirmCelebrationOverlay.swift    0.00% (0/265)     ← view body
```

**`AppFeedback`'s six uncovered lines are not this block's.** Read with
`xcrun xccov view --archive --file`, the two new gates are hit (3 and 2 times); the uncovered pairs
are `hapticsEnabled()` and `notificationSound()`, both of which predate this block and neither of
which any test calls — `HapticsTests` injects a `gate:` closure instead of going through
`AppFeedback`. Noted, not fixed: it is a real gap in *those two* accessors, not in these.

### Landed this session

- **`F-CTACelebrations-2`** — `celebrationsEnabled` (true) and `celebrationSoundsEnabled` (false) as
  the four-place edit; `AppFeedback.celebrationsEnabled(store:)` / `.celebrationSoundsEnabled(store:)`
  read at fire time; two Toggles straight after Haptics with their ids; and
  `ConfirmCelebrationOverlay` gating on the switch inside its listener, before the burst is
  appended, through an injectable `celebrationsGate` defaulting to `AppFeedback`. Ten tests, not the
  five the block predicted; the prediction was written down in two parts and both matched. Evidence
  `screenshots/cta-celebrations-block-2/`. **Awaiting E's device verdict.** (NEW)
- **No room-first commit was needed** and this was checked BEFORE editing, not after: the two target
  files were 172 and 215 lines against the 400 ceiling. They are 192 and 245 now. (NEW)

### What this session established

- **The red prediction has to be written in TWO parts when a block introduces a symbol, because a
  test that names a symbol that does not exist yet cannot fail — the target cannot BUILD, and the
  harness prints no count at all.** Part 1 was the four source-reading tests, which compile against
  today's tree: predicted 3 red of 4 (the fourth a pin, green on arrival), observed exactly that,
  as `Executed 4 tests, with 6 failures` — the 6 being assertions, which the prediction had already
  said to expect. Part 2 was the six symbol tests: predicted a build failure naming
  `celebrationsEnabled`, observed exactly that. A single "predicted red N/N" would have been wrong
  about both halves. (NEW)
- **Asserting a field's own DEFAULT value is a vacuous round-trip test, and the block's own wording
  invited it.** The design says "`normalized()` keeps both OFF" — but `celebrationSoundsEnabled`
  ships OFF, so a `normalized()` that forgets the field resets it to `false` and the assertion
  stays green. Both round-trip tests therefore set the switches AWAY from their defaults and to
  OPPOSITE states, which also catches a swap between the two fields. Planting the omission proved
  it: three tests failed. (NEW)
- **The closure-scoped guard earned its keep a second time.** `feedbackSection` holds six Toggles of
  the identical shape, three of which persist correctly. Deleting only the Celebrations row's
  `momentumPreferencesStore.write(...)` failed the test — a whole-file `contains()` would have been
  green. (NEW)
- **A "nothing drew" probe is worth nothing without its control, and the control belongs in the
  evidence folder.** The Confirm-with-the-switch-off render is byte-identical to a window that never
  mounted the overlay — same SHA-256, 0 differing pixels of 943,200. That claim is equally true of a
  probe that forgot to stamp a Confirm, so the same harness renders a third time with the gate
  forced ON (943,200 of 943,200 pixels differ, because the glow washes the screen) and asserts the
  control FIRST. (NEW)
- **Stamp the state change AFTER mount, or the probe does not exercise the thing it is testing.**
  Writing `latestConfirmation` before hosting would bring the layer up with the burst already
  present and never run `.onChange` — the gate's actual site. Mount, pump ~0.25 s, then stamp. (NEW)
- **The `apple:hig-reviewer` subagent found two real copy defects the code reviewer did not**, both
  taken: the two new footer sentences had been appended to the END of the footer, four rows below
  the switches they explain — a VoiceOver user swiping the section linearly reaches them last, after
  the rows they do not describe; and "the confetti a Confirm sets off" / "until the chime itself
  ships" were developer vocabulary in user-facing copy. The reorder is now pinned by an assertion,
  red-checked against the appended version. **It also declined twice to recommend undoing settled
  design** (renaming the row "Full-screen celebrations", splitting the rows into their own Section),
  flagging both under §7.5 rather than silently acting. (NEW)
- **`feature-dev:code-reviewer` found nothing at its bar** and confirmed two things worth having in
  writing: adding a stored closure property to a `View` struct does not break `RootView`'s
  memberwise call site (the `TaskRow.onStartFocus` precedent already compiles that shape), and
  `ConfirmCelebrationOverlay` is mounted exactly once with no other listener on
  `latestConfirmation`, so there is no path that bypasses the new gate. (NEW)
- **A stale `TestResults.xcresult` fails the suite before a single test runs**, with
  `xcodebuild: error: Existing file at -resultBundlePath`. It is gitignored, so it survives a clean
  checkout and a branch switch; delete it as part of the run rather than reading the exit code as a
  test failure. (NEW)
- **The `xcode` MCP bridge was DOWN this session** (`CONNECTION_CLOSED` at startup), so
  `RenderPreview` was unavailable and the stills came from the run-loop-pumping probe instead. That
  is the sanctioned fallback and it cost nothing here — but the bridge needs Xcode open BEFORE the
  session starts, which it was not. (NEW)

### Carried from the design session

- **E's design answers are the spec.** Seven of the recommendations were overruled (a Finish button;
  a streak milestone and the daily goal; a chime; the mini confetti pop over the halo; the
  congratulation view; the display name; the 5 s cooldown). Record them, do not re-derive them.
- **Two full-screen covers host celebration sites** — the routine screen and the Tasks search
  surface — and the Create Task sheet hosts a third; the shipped root overlay sits below all of
  them. That is why the design mounts one layer per surface (E's choice over a `UIWindow`).
- **Only two `ObservableObject`s are app-level** (`AuthService`, `FocusSessionService`); every other
  service is screen-scoped, and `AppTabContent` builds tabs lazily and KEEPS them.
- **`onGeometryChange(for:of:action:)` is back-deployed to iOS 16.0** in the 26.5 SDK, so the pop's
  origin needs no `#available`.
- **Three files remain at or near the 400-line ceiling** and need room-first commits before their
  blocks: `RootView.swift` 394, `CaptureInboxService.swift` 397, `PlaceRoutineScreen.swift` 379.
- **The Completed flow reverses an E-settled rule** (the routine-record arc's "a run ends when you
  LEAVE the screen"). The tests that pin the old rule must be updated by name, not silently.

## A · Decisions only E can make — minutes each

- [ ] **E's device verdict on `F-CTACelebrations-2`** — installed from `main` @ `2efd705`. **What to
      check, in one pass:** Settings → Feedback now has **Celebrations** (on) and **Celebration
      sounds** (off) straight after Haptics. Turn **Celebrations off**, finish a sprint and tap
      Confirm: **the confetti must not play, and the phone must still buzz.** Turn it back on and
      Confirm again: the celebration returns unchanged. Flipping either switch must stick across a
      relaunch. **The Celebration sounds switch does nothing yet** — its footer says so, and its
      player is block 7. **No Reduce Motion pass is owed for this block** (§7.3): it adds no reduced
      site, and the Confirm celebration is §7.2's waiver, which renders identically either way.
      (NEW)
- [ ] **The milestone cooldown.** E: *"i am undecided about the cooldown at the moment anyway."* It
      ships at **5 s for testing**; whether it exists and at what value is E's call on the phone
      after `F-CTACelebrations-5`. (carried; untouched this session)
- [ ] **Install an older simulator runtime** via Xcode → Settings → Components. E, 2026-09-11:
      *"In a number of days in the future, I will install this."* Until then every `#available`
      fallback is compile-only by policy (§7.3). (carried)
- [ ] **Optional, and flagged rather than decided: an `.accessibilityHint` on the Celebration sounds
      row only.** The HIG pass noted it is the one toggle in the app whose ON state produces no
      observable effect today, so a hint like *"Doesn't play anything yet — saves your choice for
      when the sound ships"* is defensible; so is leaving it, since none of the other nine toggles
      in that file carries a hint and the hint would need deleting again when block 7 lands. Nothing
      was added. (NEW)
- [x] **How does the reduced path get DEVICE time now that E runs with Reduce Motion OFF?** —
      **E chose (a), 2026-09-12.** Written into CLAUDE.md §7.3. **First block it bites is
      `F-CTACelebrations-4`, the nine pops** — `-2` (this one) and `-3` add no reduced rendering,
      and this block's report and README both say why none was owed. (CLOSED)
- [x] **Review the design record** and rule on **R-a…R-h** — E: **"yes"**. (CLOSED)
- [x] **E's device verdict on `F-CTACelebrations-1`** — **PASSED 2026-09-12** on the FULL path,
      E: *"it feels good, all five work as you described."* (CLOSED)
- [x] **E's device verdict on `F-ConfirmCelebration-2`** — PASSED 2026-09-12, E: *"it looks good."*
      (CLOSED)
- [x] **The focus card's completion celebration (`F-FocusCard-4`)** — E has seen it with Reduce
      Motion off; the sign-off stands. (CLOSED)
- [x] **The widget extension's `MARKETING_VERSION`** → 1.3. **The widget's view-only files
      testable?** → "Leave it". **The collapsed card's square bottom corners** → "Round them"
      (now `F-FocusCard-Corners`, §B.2). **E's SECOND change** → "There is no second change".
      (all CLOSED)

## B · Real work, ready to start — recommended order

**00. THE CTA CELEBRATIONS ARC — blocks 1, 2 and 3 of 8 BUILT and MERGED; the next is
   `F-CTACelebrations-3`, the centre and the shared layer.** The record is
   `handoff/SESSION-OPENER-cta-celebrations-design.md`; the opener is the session's own
   `handoff/START-HERE-*`; the blocks are in `TODO-CLAUDE-CODE.md`.
   **The blocks, in order:** ~~`F-ConfirmCelebration-2`~~ (verdict PASSED) →
   ~~`F-CTACelebrations-1`~~ (verdict PASSED) → ~~`-2`~~ (switches; **verdict pending**) →
   **`-3`** (centre + layers, Confirm re-routed) → `-4` (pops; render first, E picks) →
   `-5` (inbox zero, streak, daily goal) → `-6` (Completed flow; render the congratulation first)
   → `-7` (chime; E picks by ear).
   **For block 3, three things this block leaves it:**
   - **Room first — `RootView.swift` is at 394.**
   - The shared `CelebrationFrame` has to carry the fireworks and the dim too
     (`ConfirmCelebrationScene.fireworks`, `ConfirmCelebrationDim`, `ConfirmFireworksDrawing`); the
     waiver pin lists **six** Confirm files.
   - **`celebrationsGate` moves.** Block 3 re-routes Confirm through the `CelebrationCenter`, so the
     gate belongs in the centre, not on the overlay — and
     `testTheConfirmLayerGatesOnTheCelebrationsSwitchBeforeStartingABurst` must be updated BY NAME
     when it does, never deleted. The two tests that must survive the move unchanged are
     `testTheCelebrationsSwitchNeverSilencesTheConfirmHaptic` and the §7.2 waiver pin. (NEW)

**0. Follow-ups to the modern-iOS pilot — only what E asks for.** (carried)
   - **RM arrival fade for the bottom furniture**, only if E likes the cross-fade.
   - **The modern-API inventory, register-only until each is a block.**
     - **Free at 16.0:** `.contentTransition(.numericText(countsDown: true))` on the sprint
       countdown and ~20 `.monospacedDigit()` counters; `.presentationBackground` (16.4) on three
       sheets.
     - **Needs 17:** `ContentUnavailableView` in four empty states;
       `.contentTransition(.symbolEffect(.replace))`; interactive widgets and routine Live Activity
       check-off; the `@Observable` migration (27 classes); TipKit.
     - **Needs 18/26:** `Tab`/`.tabBarMinimizeBehavior` and `.glassEffect`, both constrained by the
       custom `AppTabBar` (adoption means replacing it).
   - **Two RM sites that remove the press affordance entirely** (`AppTabBar.swift:266`,
     `AppSearchRow.swift:71`), and `RootView.swift:63`'s declared-but-unread `reduceMotion`.

1. **E's one un-run device check: airplane mode + pull-to-refresh on Home.** `F-HomeTasksLastKnown`
   (`8b5f740`) should keep the last-known task set rather than emptying it. (carried)

2. **`F-FocusCard-Corners` — after the arc (E: "Round them").** Round the collapsed card's bottom
   corners AND give `FocusBarCardShape.roundsBottomCorners` `animatableData`, so the corner morph
   stops SNAPPING inside the 350 ms spring. In `TODO-CLAUDE-CODE.md`. (carried)
   - Still open, none blocking: the card's `.accessibilityAction(named:)` may attach to nothing;
     `FocusTimerBarContent` has no `#Preview`; a slow location fix delays the completion CARD; the
     stack has no UI journey. (carried)

3. **`AppFeedback.hapticsEnabled()` and `.notificationSound()` have no test that calls them** — both
   are 0-hit, found in this block's coverage read. Everything that consults them injects a closure
   or a fake instead. Two small tests, no production change. (NEW, below the bar for this block)

4. **Two more dead design tokens, and two dead helpers.** `BarSurface` is defined, unit-tested and
   used by nothing; `AppTabBarPresentation.slotWidth` / `restingSlotWidth` have ZERO production call
   sites and disagree about their input. (carried)
5. **Accuracy-aware containment for the arrival card — ONLY if E still sees drops after #32.**
   (carried)
6. **Arc 2 — first-class routines + the "at a time" trigger.** (carried)
7. **`F-Search-3-Journal`** — recommendation is still to kill the block. (carried)
8. **The Live Activity design review** E parked. (carried)

## C · Parked on E's instruction — do not start unprompted

- **A nudge-specific screen animation for EVERY "Done for now".** E, 2026-09-11: *"every 'done for
  now' must be given a different screen animation - We can handle this later."* Not designed; not in
  this arc. Ask E when the arc has shipped. (carried)
- **14- and 21-day streak milestones** (R-b): the arc fires at exactly 7. (carried)
- **Places backgrounding dismiss bug** — waiting on E's iOS update. (carried)
- **App connections** — real two-way sync; Apple Notes has no iOS API. (carried)
- **LA interactive buttons**, **time-of-day triggers**, **smart skip**. (carried)
- **`OfflineSprintSummaryCard`** — E ruled it out of the focus-card arc explicitly. (carried)

## C2 · Noticed, below the bar, worth E's eye on device

- **Under Reduce Motion the closure card's `withAnimation(.default)` also animates the SIBLING
  sections reflowing beneath it** (life areas, Due now, nudges), because they share the VStack and
  the transaction. It only matters if `ClosureCelebrationCard` and `bestNextMoveSection` differ much
  in height. **It is a REDUCED-path effect, and E now runs with Reduce Motion OFF, so E's passing
  verdict did not see it.** It stays open and unjudged until someone looks with the setting on —
  which, under §7.3's RM-on pass, will next happen naturally at `F-CTACelebrations-4`. (updated)
- **The Feedback section's footer is now a thirteen-line paragraph** covering six switches. Nothing
  clips and it reads in row order, but it is long. The HIG pass considered recommending the two
  celebration rows be split into their own `Section` with their own short footer, and declined
  because that would undo E's settled placement (#3 puts them in the Feedback section). Worth E's
  eye on the phone: if the paragraph reads as a wall, splitting the section is the fix and it is
  E's call, not a sweep's. (NEW)

## D · Launch blockers — no conversation opened yet

- **Free dev account** → 7-day profiles; the current one is valid to **2026-09-17**. When a device
  install fails on it, E re-signs in Xcode → Settings → Accounts. (carried)
- **Sign in with Apple** built but dormant. (carried)
- **A way to turn the Confirm confetti off — SHIPPED, `F-CTACelebrations-2`, `main` @ `2efd705`.**
  The Celebrations switch is live on Confirm today, on by default. The accepted cost recorded here
  since 2026-09-11 — that people who turned Reduce Motion on for motion sensitivity get full-screen
  confetti with no escape — **is now paid**: there is an escape, and it is one tap in Settings.
  §7.2's waiver is unchanged and still covers only how the celebration renders when it DOES play.
  (CLOSED)

## E · Known, not work

- **The `xcode` MCP bridge was DOWN this session** — `CONNECTION_CLOSED` in the startup reminder,
  because Xcode was not open before the session began. `RenderPreview` was therefore unavailable and
  the stills came from the probe instead. Open Xcode BEFORE starting a session that wants the
  bridge; there is no in-session recovery. (updated)
- **A stale `TestResults.xcresult` fails the whole suite before a test runs** —
  `xcodebuild: error: Existing file at -resultBundlePath`. Gitignored, so it survives everything;
  delete it as part of the run. (NEW)
- **A green suite cannot see a `View`'s appearance.** Render to PNG from a unit test before the
  device build: `UIHostingController` + `UIGraphicsImageRenderer` + `drawHierarchy(afterScreenUpdates: true)`
  in a scene-attached `UIWindow`, a synchronous test pumping `RunLoop.main`; render IN SITU, and
  always render the CONTROL. The probes live outside the repo and are rebuilt from the evidence
  READMEs. (updated)
- **`Executed N tests, with M failures` counts failed ASSERTIONS, not failing TESTS.** Predict in
  TESTS, then reconcile — and when a block introduces a symbol, predict the BUILD FAILURE
  separately, because that half prints no count at all. (updated)
- **SwiftLint's 400-line file, 250-line `type_body_length` and 40-character `type_name` ceilings.**
  `RootView.swift` 394, `CaptureInboxService.swift` 397 and `PlaceRoutineScreen.swift` 379 remain.
  **Moving an extension to a new file ends same-file `private` access.** (carried)
- **A `devicectl` launch denied with `Security` right after a re-issued profile is TRANSIENT — retry
  once.** The three species: `Locked` (unlock), `Security` + valid profile (retry), `Security` +
  expired profile or "No Accounts" (E signs in via Xcode → Settings → Accounts). (carried)
- **A UI-target run poisons the simulator; erase it before the next unit run**
  (`xcrun simctl erase 9181EBF9-0F54-4A4D-A19C-19945D1BF155`). No UI target was run this session.
  (carried)

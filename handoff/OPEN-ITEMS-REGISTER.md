# Open items register — 2026-09-11 (twenty-second edition; MODERN iOS PILOT QUEUED — two blocks, fresh session)

*Written at the close of the session that shipped `F-FocusCard-4` and `F-FocusCard-5`, then
debugged E's "I can't see any of the animations", found the cause on E's phone, and planned the
modern-iOS pilot with E. **E's instruction: a FRESH session builds it** — this session landed only
the handoff. Supersedes the twenty-one earlier editions.*

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding — so it is the thing to read, and to
update, rather than improvising a list in chat.

Every figure below was measured this session unless marked (carried).

## State

**`main` @ the block-0 handoff merge; the last CODE change is `d8b334b`** (PR #58,
`F-FocusCard-4`; everything since is docs) · **the focus card arc is CLOSED** · **the modern-iOS
pilot is QUEUED for a fresh session: `handoff/START-HERE-modern-ios-pilot.md`** · figures below
are (carried) from the block-5 run: suite **2,663 / 0** (emulator
UP, 0 `127.0.0.1:9099`, 0 skipped — run twice, once per block), lint **0 / 738**, sim + device
`** BUILD SUCCEEDED **`, app target **26.68% (12,255/45,932)** after block 5 — the numerator is
byte-identical to block 4's 26.69% (12,255/45,914) and the +18 in the denominator came from a
comment-only diff, so it is xccov counting comment lines inside view-body regions, not code. Evidence: `screenshots/focus-completion-celebration/`. **Nothing for E to
republish.** **E's phone runs the block-4 build, which IS `main`'s code.** Otherwise: **no
branch in flight**; every feature and chore branch was deleted by its
own merge, so **`main` is the only branch on GitHub** · every change lands through a PR ·
verified: **unit suite 2,638 / 0** (emulator UP, **0** `127.0.0.1:9099` hits, 0 skipped),
**SwiftLint 0 / 734**, sim + device builds `** BUILD SUCCEEDED **` · `firestore.rules` untouched,
**nothing for E to republish** · every `.xcresult` deleted after its figures were read.

**E's phone was installed and launch-verified at 01:48 on 2026-09-11 from `d8b334b`.**

**Coverage: app target 26.68% (12,255/45,932) — comparable to the twentieth edition's 26.56%
(12,161/45,782).** Block 4 grew the tree by one file (`FocusCompletionCelebration.swift`, 98
executable lines) and the numerator by 94, so the rise is real; block 5's comment-only diff then
moved the denominator by +18 with the numerator byte-identical — xccov counting comment lines
inside view-body regions, which is worth knowing the next time a doc-only PR appears to lower
the figure. Full breakdown (block 4's run; block 5 changed only the app line):

```
ADHD LifeOS.app              26.68%  (12255/45932)  ← 26.69% (12255/45914) before block 5's comments
ADHD LifeOSTests.xctest      95.30%  (42100/44176)
ADHD LifeOSUITests.xctest     0.00%  (0/2962)     ← skipped in the standard run by design
FocusTimerWidgetExtension    10.30%  (228/2214)   ← read the 233-line testable surface, not this
```

### Landed this session

- **`F-FocusCard-4` — the celebration** (PR #58, `d8b334b` + `95038a7`). The ring's own stroke
  radiates 1 → 1.6 while fading 0.8 → 0 on a 0.9s easeOut, the tick springs in from 0.6, both
  after a 0.3s wait for the card to land; success haptic on `RootBottomOverlay` keyed on
  `confirmableCompletionCount`. One service stamp (`latestConfirmableCompletion`), written by
  the push only. Call-site guards ran RED on 5 tests / 9 failures before the implementation
  existed; three red-checks after, each on the predicted tests. **E, on device: "the pre-beat
  reads fine."** Evidence: `screenshots/focus-completion-celebration/` (11 frames + README).
- **`F-FocusCard-5` — the close-out** (this PR). Stale comments corrected, the
  `OfflineSprintSummaryCard` collision recorded in the code, the design record's postscript
  table, this register, and the handoff swap.
- **Two register PRs** (#59 twentieth edition, and this one).

### What this session established — the Reduce Motion root cause (2026-09-11)

- **E's phone runs Reduce Motion ON (and Prefer Cross-Fade Transitions ON).** Read off the phone
  via iPhone Mirroring, read-only. Every animation in the bottom furniture is
  `reduceMotion ? nil : …` and the celebration opens on its settled pose under RM — exactly what
  the design record specified — so **the block-4 burst has never once played on E's phone.** E
  saw a hard cut plus the success haptic (which does fire under RM). Not a code defect: the
  celebration renders correctly in the simulator in isolation AND in situ through the real
  overlay + service. A product gap: Apple's guidance under RM is to replace motion with a fade,
  not remove feedback, and this app removes it (19 of its 20 RM-guarded sites are `nil`; the one
  fade is `Capture/CaptureFanOverlay.swift:89-96`).
- **E's decisions, settled:** RM → cross-fade celebration; progressive enhancement across every
  tier that adds value above the 16.0 floor; fallback proof compile-only for now, documented;
  policy first (CLAUDE.md §7 rewrite) then the celebration as the pilot; a fresh session builds;
  the tick's ladder is 16 spring / RM fade / **iOS 26 `.drawOn`** with no 17 tier (the 17 symbol
  effects add nothing the spring lacks for this glyph).
- **`.drawOn`/`.drawOff` are `@available(iOS 26.0)`** in the 26.5 SDK's swiftinterfaces and E's
  phone is on 26, so it is a tier E can see. `SymbolEffectOptions` has no RM option — symbol
  effects do not self-gate; RM must be resolved before the tier.
- **What "compile-only" means here, precisely:** the 16 branch's CODE runs on the 26.5 simulator
  whenever the motion mode is injected as `.full`; what cannot be exercised is its *selection* on
  a 16–25 OS. Report per tier; never write "works on iOS 16".
- **Harness lessons:** an `async` XCTest pumping `RunLoop.main` cannot drain the queue SwiftUI's
  updates land on — the in-situ frames froze mid-transition until the probe became a synchronous
  test driving `finishCurrentSprint` → pump → `pushUnconfirmedCompletion`. And the block-4 render
  was the card in isolation; the first in-situ render came only when E reported the gap.

### What block 4 established, beyond the animation

- **`drawHierarchy(afterScreenUpdates: false)` from a test host renders BLANK WHITE.** Use `true`
  and a scene-attached `UIWindow`; it then captures in-flight SwiftUI animation frames, so motion
  can be evidenced by render too.
- **`accessibilityReduceMotion` is not writable via `.environment(\.)`.** Render the leaf with the
  flag as a parameter; hold the parent's pass-through with a call-site test.
- **A listener on a view inserted in the same update that changes its trigger misses that
  change.** The haptic lives on the persistent overlay for exactly this reason.
- **`FocusSessionService.swift` is at 394/400** after moving two accessors out.

### What the peek work established (2026-09-10), and it is worth more than the constant

- **The lever ordering this register carried was BACKWARDS.** It named `opacityStep` the blunt
  instrument. Opacity moves the keyline **1.30:1 → 1.35:1** — invisible — because the layer behind
  already draws at 0.85. **What the eye reads is the sliver's HEIGHT**, so `peekStep` is the lever.
  `scaleStep` 0.10 actually *lowers* keyline contrast to 1.21:1, dropping more of the line onto the
  corner curve. **A contrast ratio answers whether an edge can be DISTINGUISHED, never whether
  anyone will NOTICE it** — render the options before ranking levers.
- **`peekStep = 14` is the app's ONLY sanctioned off-grid spacing value.** §2 is 4/8/16/24; E was
  offered the on-grid 16 explicitly and chose the value they had approved by sight. The waiver is
  written into **`CLAUDE.md` §2** and pinned by `testThePeekStepIsTheValueEChoseByLooking`.
  **Do not "correct" it.**

## A · Decisions only E can make — minutes each

- [ ] **Install an older simulator runtime** — Xcode → Settings → Components, iOS 17.x proves the
      17 gates select and 16.x proves the floor; ~7 GB on the external SSD; **E's GUI job** per the
      manual-step convention. Until then every `#available` fallback in the app is compile-only
      **by policy (CLAUDE.md §7.3 once block 1 lands), not by oversight.** Ask at a natural
      break. (NEW)
- [ ] **Do the collapsed card's square BOTTOM corners still earn their keep?** (carried) A "look
      again next time you are in there", not a defect.
- [ ] **Should the widget's view-only files be made testable at all?** Recommendation is still to
      leave it. (carried)
- [ ] **E's SECOND change — still not described.** Ask once the arc reaches a natural stopping
      point. (carried; E's *first* change was the focus card arc.)

## B · Real work, ready to start — recommended order

**0. THE MODERN iOS PILOT — two blocks, a FRESH session builds them (E's instruction).**
   Live opener **`handoff/START-HERE-modern-ios-pilot.md`**, which carries E's approved plan
   verbatim. Block 1 `F-ModernIOS-1-Policy`: CLAUDE.md §7 becomes the progressive-enhancement +
   Reduce-Motion policy; delete `testTheCelebrationUsesNothingAboveTheiOS16Floor`, add
   `ModernAPIPolicyCallSiteTests`. Block 2 `F-ModernIOS-2-Celebration`: three motion modes
   (`.full` 16 spring unchanged / `.reduced` RM cross-fade / `.modern` iOS 26 draw-on), pure
   types split to `FocusCompletionCelebrationPose.swift`, test-first (predicted red 3 tests /
   6 failures on the string tests), rendered in all three modes + in situ, then **E's phone with
   RM ON is the verdict that closes it**, RM OFF a second look. Block 2's branch is not cut until
   block 1 is on `main`.

**0b. Follow-ups the pilot deliberately leaves out — pick up only after E's verdict:**
   - **RM arrival fade for the bottom furniture** (`RootBottomOverlay`'s three nil animations +
     the card's unconditional `.move + .opacity` transition) — only if E likes the pilot's
     cross-fade. The reflow must NOT tween under RM; the card's transition would split.
   - **The modern-API inventory, register-only until each is a block:** free at 16.0 —
     `.contentTransition(.numericText(countsDown: true))` on the sprint countdown
     (`FocusTimerBarContent.swift:194`) and ~20 `.monospacedDigit()` counters;
     `.presentationBackground` (16.4) on three sheets. Needs 17 — `ContentUnavailableView` in
     `TaskListView`, `CaptureInboxView`, `TagEditorListView`, `TaskSearchSurface`;
     `.contentTransition(.symbolEffect(.replace))` for pause/play and disclosure chevrons;
     interactive Home Screen widgets (`Button(intent:)`) and step check-off on the routine Live
     Activity; `@Observable` migration (27 classes); TipKit for the card's undiscoverable
     gestures. Needs 18/26 — `Tab`/`.tabBarMinimizeBehavior` and `.glassEffect`, both constrained
     by the custom `AppTabBar` (adoption means replacing it, not augmenting it).
   - **Two RM sites that remove the press affordance entirely** (`AppTabBar.swift:266`,
     `AppSearchRow.swift:71`) and `RootView.swift:63`'s declared-but-unread `reduceMotion` beside
     two unguarded animations — the policy's first sweep candidates.

   The focus card design record (`handoff/SESSION-OPENER-focus-card-design.md`, permanent) opens
   with a postscript table of everything that shipped against it; block 2 adds one row.

1. **E's one un-run device check: airplane mode + pull-to-refresh on Home.**
   `F-HomeTasksLastKnown` (`8b5f740`) should keep the last-known task set rather than emptying it.
   Unrelated to the focus card; checks 1–3 (Confirm-doesn't-reopen-a-collapsed-card,
   tap-opens-detail, `F-TabBar-NoScrollDrop`) were run by E on 2026-09-11 with nothing reported
   wrong. (NEW)

2. **Small defects in the card, none blocking:**
   - **`FocusBarCardShape.roundsBottomCorners` is a `Bool` with no `animatableData`**, so the
     corner morph SNAPS inside the 350ms spring while the inset, offset and padding all tween.
     Fixing it means a `CGFloat` bottom radius and per-corner arcs. (carried)
   - **The card's `.accessibilityAction(named:)` may attach to nothing.** Wants an Accessibility
     Inspector pass — this bar is the app's only door to `FocusSprintDetailView`. (carried)
   - **`FocusTimerBarContent` has no `#Preview` of its own**, unlike the other content-split
     files. (carried)
   - **A slow location fix delays the completion CARD, not just the write.** Correct as built;
     worth knowing if E ever reports the card appearing late. (carried)
   - **The stack has no UI journey** and probably cannot have a useful one. The evidence is the
     render plus E's device shots, which is what the design record anticipated. (carried)

3. **Two more dead design tokens, and two dead helpers.** `BarSurface` (a colorset, defined,
   unit-tested, used by nothing), and `AppTabBarPresentation.slotWidth` / `restingSlotWidth`,
   which have ZERO production call sites and **disagree about their input**. (carried)

4. **Accuracy-aware containment for the arrival card — ONLY if E still sees drops after #32.**
   (carried)
5. **Arc 2 — first-class routines + the "at a time" trigger.** (carried)
6. **`F-Search-3-Journal`** — recommendation is still to kill the block. (carried)
7. **The Live Activity design review** E parked. (carried)

## C · Parked on E's instruction — do not start unprompted

- **Places backgrounding dismiss bug** — waiting on E's iOS update. (carried)
- **App connections** — real two-way sync; Apple Notes has no iOS API. (carried)
- **LA interactive buttons**, **time-of-day triggers**, **smart skip**. (carried)
- **`OfflineSprintSummaryCard`** — E ruled it out of this arc explicitly. The collision is real and
  documented-not-fixed: it shares `RootBottomOverlay`'s VStack with the completion stack, so an old
  unacknowledged app-was-dead completion and a new unconfirmed sprint can be on screen together in
  two different visual languages. `F-FocusCard-5` records it. (carried)

## D · Launch blockers — no conversation opened yet

- **Free dev account** → 7-day profiles; the current one is valid to **2026-09-17**. (updated)
- **Sign in with Apple** built but dormant. (carried)

## E · Known, not work

- **Xcode's MCP bridge is live (`xcrun mcpbridge`, server `xcode`) and documented in CLAUDE.md
  under Commands.** Open Xcode BEFORE the session or its tools are absent all session. Its
  `GetTestList` enumerates 2,688 enabled unit tests against the 2,663 the last full run
  executed — a 25-test gap the fresh session should reconcile in its first suite report. (NEW)

- **A green suite cannot see a `View`'s appearance, and this arc proved it four times now.**
  Block 1's `layoutPriority` compression reached E's device; block 2's was caught by a render;
  block 3's was the cards behind **ghosting through `.regularMaterial`**; and the peek's own
  quietness was invisible to every layout assertion, all of which held. **Render the view to PNG
  from a unit test before the device build** — `UIHostingController` +
  `UIGraphicsImageRenderer` + `drawHierarchy`, `overrideUserInterfaceStyle` for dark, hosted in a
  `UIWindow` with the run loop pumped briefly. It costs a minute and needs no signed-in simulator.
  **To vary a `static let` constant across variants, make it `var` for ONE run, then
  `git checkout --` and prove the restore with a full build.** (updated)
- **`Executed N tests, with M failures` counts failed ASSERTIONS, not failing TESTS.** Predict in
  TESTS, then reconcile. Names: `grep -oE "Test Case .*' failed" <log> | sort -u`. (carried)
- **SwiftLint's 400-line file and 250-line `type_body_length` ceilings are one TEST away.** The fix
  is a thematic file split with its own `private` doubles. (carried)
- **A `devicectl` launch denied with `Security` / "invalid code signature… not explicitly trusted"
  right after a re-issued profile is TRANSIENT — retry once before escalating to E.** It reads
  exactly like the free-account provisioning blocker. Check the embedded profile's
  `ExpirationDate` against `date` and run `codesign --verify --deep --strict`: valid and freshly
  minted means retry, not E. Three species share that one error surface, separated only by the
  failure reason: `Locked` (unlock), `Security` + valid profile (retry), `Security` + expired
  profile or "No Accounts" (E signs in via Xcode → Settings → Accounts). (NEW)

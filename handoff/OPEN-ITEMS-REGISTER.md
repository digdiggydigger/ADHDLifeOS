# Open items register — 2026-09-11 (twenty-sixth edition; Confirm-celebration design record WRITTEN, awaiting E's review)

*Written the same session as the twenty-fourth and twenty-fifth. E answered that edition's verdict
request with two asks:
- "Can you make the animations longer?" — done in PR #66;
- a full-screen celebration on Confirm, "possibly confetti?".

**All eight of E's decisions on the celebration are now taken, and the design record is written:**
`handoff/SESSION-OPENER-confirm-celebration-design.md`, on the open PR for
`chore/confirm-celebration-design`. It is not built; E's review of the record is the gate. Block 2
is still **waiting on E's Reduce-Motion-ON verdict**, on the longer build. Supersedes the
twenty-five earlier editions.*

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding, so it is the thing to read and to
update rather than improvising a list in chat.

Every figure below was measured this session unless marked (carried).

## State

**`main` @ the longer-fades merge (PR #66; its code commit is `e1d87d8`), on top of the
`F-ModernIOS-2-Celebration` merge (PR #65, `a2f20ab`).** #65 was the first APP-code change since
`d8b334b` (`F-FocusCard-4`): `bfb1fa3` is the code, `da65027` corrects its comments to what the
renders showed, `0f5624b` is the evidence and paperwork.
- **Longer fades (#66), E's ask on device:** the halo 0.9s → **1.8s** in every mode and the
  Reduce Motion tick 0.4s → **0.8s**, pinned by `testTheFadesRunAtTheLengthEAskedFor`. The factor
  (2×) was Claude Code's pick, pending E's feel on the phone. The 0.3s delay, the RM-off tick
  spring and the draw-on did not change. Red predicted and observed 2,673 / 2 (1 test); green
  **2,673 / 0**, 0 `9099`, lint 0. **Installed and launch-verified on E's phone at 07:32 BST.**
  Coverage not re-run: constants only, no executable line added (figures below are #65's).
- **The modern-iOS pilot is BUILT:** block 1 (the §7 policy) and block 2 (the celebration) are both
  on `main`. Block 2 is not CLOSED until E's Reduce-Motion-ON verdict.
- **The live opener is still `handoff/START-HERE-modern-ios-celebration.md`**, now headed by a status
  line saying the block has landed and must not be rebuilt. It stays live until E's verdicts are in;
  the session that records them archives it together with its successor.
- **Verified this session:**
  - unit suite **2,672 / 0** (emulator UP, **0** `127.0.0.1:9099` hits, 0 skipped). The baseline was
    2,663 / 0 before any change, and the prediction 2,663 → 2,672 held.
  - SwiftLint **0 / 742**
  - sim `** BUILD SUCCEEDED **`; device `** BUILD SUCCEEDED **`
  - app target **26.75% (12,309/46,014)**
- `firestore.rules` untouched, so there is **nothing for E to republish**. Every `.xcresult` was
  deleted after its figures were read.
- **One branch in flight, deliberately: `chore/confirm-celebration-design`**, the design record and
  its prototype evidence, left OPEN for E's review. This is the sanctioned open-PR state, not an
  unlanded block. No app code is on it. #65's and #66's branches were deleted by their merges.

**E's phone runs this block's app code**, installed and launch-verified at **07:02 BST on
2026-09-11**, built from `0f5624b`. `main`'s app code at the merge is identical to that commit's
(checked at close-out with `git diff 0f5624b main -- "ADHD LifeOS" FocusTimerWidget`, empty).
Reduce Motion is still ON there, as E left it. (carried)

**Coverage: app target 26.75% (12,309/46,014), and it IS comparable to block 1's 26.68%
(12,255/45,932).** The denominator moved +82 because the tree grew (one new app file, and the view
grew), not because the measurement's extent changed: both runs measured the whole app target. The
numerator moved +54. The new pure file is **92.31% (36/39)**; its three uncovered lines are
`burstAnimation`, moved unchanged from block 4 and reached only from the view's `onAppear`.

```
ADHD LifeOS.app              26.75%  (12309/46014)  ← was 26.68% (12255/45932)
ADHD LifeOSTests.xctest      95.20%  (42362/44500)  ← was 95.27% (42130/44220)
ADHD LifeOSUITests.xctest     0.00%  (0/2962)       ← skipped in the standard run by design
FocusTimerWidgetExtension    10.30%  (228/2214)     ← read the 233-line testable surface, not this
```

### Landed this session

- **`F-ModernIOS-2-Celebration`** (PR #65). The completion celebration now has three motion modes,
  chosen by `FocusCompletionCelebrationMotion.resolve(reduceMotion:drawOnAvailable:)`, which decides
  Reduce Motion BEFORE the tier:
  - **`.full`**, below iOS 26 with RM off: block 4's burst, unchanged.
  - **`.reduced`**, RM on, any OS: geometry pinned at rest (halo 1.6, tick 1), and only opacity
    travels. It replaces the hard cut E lived with.
  - **`.modern`**, iOS 26 with RM off: the tick draws itself on, via
    `AsymmetricTransition(insertion: .symbolEffect(.drawOn), removal: .identity)` in its own
    `@available(iOS 26.0, *)` type.
  - **No iOS 17 tier**, per §7.1's filter: `.appear` is less than the spring and `.bounce` ignores
    the landing delay.

  The pure types moved to `Focus/FocusCompletionCelebrationPose.swift`. `init(plays:reduceMotion:)`
  kept its signature, so the card, stack, overlay, service and `Theme/Haptics.swift` show NO diff
  against `main`.
- **Tests, first.**
  - **Red #1, predicted in writing and observed exactly:** `Executed 2672 tests, with 16 failures`,
    9 tests.
  - **Three red-checks on a committed tree, each predicted by TEST NAME and observed exactly:**
    - `} else {` → `} else  {`: 2,672 / 1, `testTheCelebrationCarriesBothTheModernAndTheFloorBranch`.
    - `resolve` ignoring RM: 2,672 / 5, `testReduceMotionWinsOverEveryTier` (2) and
      `testReduceMotionOpensWithGeometryAtRestAndOnlyOpacityToTravel` (3).
    - `geometryPinned = true`: 2,672 / 3, `testTheArmedPoseHoldsTheRingAtTheRingAndTheCheckmarkSmall`
      (2) and `testAPoseReadsItsRingOffTheCurve` (1).

    Each was restored with `git checkout -- "ADHD LifeOS/"`; the final green run proved the last.
- **Evidence:** `screenshots/focus-completion-celebration-modes/`, 14 JPEGs and a README with the
  Verified paths line.
- **Paperwork:** TODO ticked; one postscript row in `SESSION-OPENER-focus-card-design.md`; the
  opener's status line.

### What this session established

- **The iOS 26 draw-on does NOT wait for the landing transaction's 0.3s delay.** This was the plan's
  named risk, and the render settles it. The stroke starts the moment the tick is inserted and is
  complete in ~0.3s (a dot at t0.09, whole by t0.42), while the halo still waits and starts ~t0.51.
  - In situ the draw is under way while the card is still arriving. **So on a phone with RM off the
    tick draws during the slide-up**, the collision block 4's delay was added to prevent.
  - Shipped as rendered, per the plan ("evidence it, don't fight it"), and the code's comments say
    so. **The lever:** land `.modern` after `FocusCompletionCelebrationMetrics.delay`, not inside it.
- **The reduced halo pinned at 1.6 is heavier inside the real card than in the plan's reasoning.**
  At 1.6 the stroke scales too (4pt → 6.4pt). Measured off an in-situ render:
  - **outer diameter 77.3pt against the card's 76.0pt**, so it overhangs the top and bottom border by
    ~0.7pt each;
  - **right edge 92.3pt against the summary column's 85.0pt**, so it runs ~7pt behind the emoji and
    "25m";
  - held at 80% opacity through the delay before it fades.

  **A pin ≤ 1.25 clears the text** (right edge 83.8pt); 1.3 touches it. Not changed: E's lever.
- **Both plan corrections resolved as the opener said.**
  - The `AsymmetricTransition` form compiles and is what shipped.
  - The red count depends on the assertion set, which this session changed: its string tests read
    ORDER inside the tick site. They also pin `guard pose.isArmed else { return }` and ban
    `pose == .armed`, because that old guard would have frozen the reduced opening for ever, halo up
    and no tick.
  - Red #1's string tests counted 3 tests / 6 failures, the plan's number, from a different
    composition.
- **The plan's bare-presence pin on `#available(iOS 26.0, *) {` was VACUOUS.** The view's own
  `drawOnAvailable` flag (the `placesSupported` shape) contains that exact string on a line that
  draws nothing. Same lesson as block 1's `} else {`: read order inside a scoped region.
- **SwiftLint's `type_name` ceiling is 40 characters.** The plan's
  `FocusCompletionCelebrationModernPathCallSiteTests` (49) failed lint, so the class is
  `FocusCelebrationModernPathCallSiteTests`.
- **The app target's `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` makes every pure app type's
  `Equatable` main-actor-isolated.** A non-`@MainActor` test class comparing them raises
  "main actor-isolated conformance … cannot be used in nonisolated context".
  - `FocusCompletionCelebrationTests` carried 5 such warnings before this block.
  - `@MainActor` on the class (92 test files already do it) cleared those and the 3 the new tests
    would have added.
  - The test target still carries ~665 unique warnings at baseline: known noise, not this block's.
- **`Animation` equality is reliable at runtime** on this toolchain.
  `.spring(response: 0.4, dampingFraction: 0.6).delay(0.3)` built twice compares equal, so an
  animation choice is assertable directly.
- **A nested insertion transition does NOT replay when its parent is rebuilt or revealed.** On a
  second push the new front card draws on and the old one keeps its tick; on Confirm the revealed
  card arrives already ticked, with no draw-off on the leaving one.
- **Reduce Motion in situ can be rendered by a ONE-RUN temporary edit** (force `reduceMotion: true`
  into `resolve`), restored with `git checkout --` and proved by the next build. It is the §7.2 gap
  the environment cannot fill. The overlay still animates the arrival in that render, so it shows
  the celebration, not E's cut arrival.
- **`xcodebuild` prints "Executed 1 test" (singular)** for a one-test run, so a grep for `tests`
  misses it. Read the exit code.

### How the Reduce Motion story got here (2026-09-11, carried in brief)

E's phone runs **Reduce Motion ON (and Prefer Cross-Fade Transitions ON)**, read off the phone via
iPhone Mirroring, read-only. Every RM gate in the bottom furniture was `reduceMotion ? nil : …`, so
block 4's burst never once played for E: E saw a hard cut plus the haptic. This was a product gap,
not a code defect. E's decisions produced CLAUDE.md §7 (block 1) and this block's ladder. The haptic
fires under RM, as it always did.

### What block 4 established (carried)

- **`drawHierarchy(afterScreenUpdates: false)` from a test host renders BLANK WHITE.** Use `true` and
  a scene-attached `UIWindow`. It captures in-flight SwiftUI animation frames.
- **`accessibilityReduceMotion` is not writable via `.environment(\.)`** (now §7.2).
- **A listener on a view inserted in the same update that changes its trigger misses that change.**
- **`FocusSessionService.swift` is at 394/400.**

### What the peek work established (2026-09-10) (carried)

- **What the eye reads is a sliver's HEIGHT, not its contrast.** Render the options before ranking
  levers.
- **`peekStep = 14` is the app's ONLY sanctioned off-grid spacing value**, waived in CLAUDE.md §2 and
  pinned by `testThePeekStepIsTheValueEChoseByLooking`. **Do not "correct" it.**

## A · Decisions only E can make — minutes each

- [ ] **Review the Confirm-celebration design record** (`handoff/SESSION-OPENER-confirm-celebration-design.md`,
      open PR on `chore/confirm-celebration-design`). The settled half is E's own eight answers,
      quoted with the options as E saw them. **What needs E's eye is its "recommendations — NOT yet
      E's decisions" list, R1–R9**, chiefly:
      - R1: rapid Confirms overlap, capped at 3;
      - R2: a second service stamp, never the existing one;
      - R9: two blocks, each closing on a device verdict.

      Approve, change, or reject; the build starts only after. (NEW)
- [ ] **E's device verdict with Reduce Motion ON — this closes `F-ModernIOS-2-Celebration`.** The
      phone has the LONGER build (07:32 BST): halo fades over 1.8s, tick over 0.8s. Finish a short
      sprint and expect:
      - a CUT arrival;
      - a bold green halo around the ring;
      - after ~0.3s, the tick fading in as the halo fades out;
      - nothing scaling, no stroke drawing, the haptic as before.

      Evidence lands as `40-…` in the evidence folder. (NEW)
- [ ] **E's second look with Reduce Motion OFF.** Expect the card to slide up with the tick drawing
      itself on DURING the slide, then the halo radiating once it has landed. The early draw is the
      finding above: judge whether it reads as one gesture or as a collision. Evidence: `50-…`. (NEW)
- [ ] **The reduced halo's pinned scale: keep 1.6, or go smaller?** The frame to look at is
      `screenshots/focus-completion-celebration-modes/34-…`. At 1.6 the halo overhangs the card by
      ~0.7pt and runs ~7pt behind the text; ≤ 1.25 clears the text. Renders of the options are one
      probe run away if wanted. (NEW)
- [ ] **Install an older simulator runtime** via Xcode → Settings → Components. iOS 17.x proves the
      17 gates select and 16.x proves the floor. It is ~7 GB on the external SSD and **E's GUI job**.
      Until then every `#available` fallback is compile-only by policy (§7.3). (carried; asked
      2026-09-11)
- [ ] **The widget extension's `MARKETING_VERSION` is 1.0; the app's is 1.3.** Xcode warns on every
      build. Version numbers are E's. (carried)
- [ ] **Do the collapsed card's square BOTTOM corners still earn their keep?** A "look again next
      time you are in there", not a defect. (carried)
- [ ] **Should the widget's view-only files be made testable at all?** Recommendation is still to
      leave it. (carried)
- [ ] **E's SECOND change — still not described.** Ask once the pilot reaches its stopping point.
      (carried)

## B · Real work, ready to start — recommended order

**0a. The Confirm celebration — E's ask (2026-09-11). DESIGN SETTLED, RECORD WRITTEN, awaiting E's
   review; nothing built.** A celebration that uses the full screen when the user taps Confirm on a
   completion card. **The record is `handoff/SESSION-OPENER-confirm-celebration-design.md`**,
   renamed from the `…-confetti-design.md` the last edition promised because it now covers
   fireworks, the glow and the dim as well. Its evidence is `screenshots/confirm-celebration-prototypes/`.
   **E's eight decisions, all settled:**
   1. **Reduce Motion ON shows BOTH a full-screen done-green glow AND real falling confetti.** A
      deliberate, named **waiver of CLAUDE.md §7.2** for this one moment (like `peekStep`'s of §2).
      With nothing left to reduce, Reduce Motion OFF is the same.
   2. **Every Confirm fires it; the Confirm that empties the stack is bigger.** Decision 6 made the
      fireworks the "bigger"; the confetti is identical on both.
   3. **The success haptic fires on every Confirm.**
   4. **No Settings switch for now** — recorded as a pre-launch item in D.
   5. **Confetti from two sources at once, on every Confirm:** rain from the top (120) and both
      bottom corners' cannons (100), chosen by video.
   6. **The stack-clearing Confirm adds fireworks.**
   7. **More of them, in more colours:** 14 shells in 9 token colours, in three burst kinds (single,
      two-tone, ring-in-ring) and three sizes, ending on a two-shell finale, chosen by video.
   8. **In LIGHT appearance the screen dims to 85% (`Scrim`) for the fireworks' length**; dark never
      dims, chosen by video over 55% and none.

   **Next, only after E approves the record:** write `F-ConfirmCelebration-1` (engine, trigger stamp,
   every Confirm's confetti + glow + haptic) and `-2` (fireworks + dim) into `TODO-CLAUDE-CODE.md`
   from it, then build test-first. **Both files the build touches are at their line ceiling**
   (`FocusSessionService.swift` 394, `RootView.swift` 399). The record plans the room-making move
   as block 1's first commit.

**0. Follow-ups to the pilot — pick up only after E's verdicts, and only what E asks for:**
   - **The draw-on's timing**, if E's RM-OFF look says the tick should wait for the card: land
     `.modern` after `delay`, not inside it. A small change to the view's `onAppear` plus its
     call-site pin, then a re-render.
   - **The reduced halo's pinned scale**, if E picks a smaller value. It needs its own constant
     beside `burstScaleEnd`, the two pure tests that read `burstScaleEnd` for the reduced pose, and a
     re-render in the card.
   - **RM arrival fade for the bottom furniture** (`RootBottomOverlay`'s three nil animations + the
     card's unconditional `.move + .opacity` transition), only if E likes the cross-fade. The
     reflow must NOT tween under RM, so the card's transition would split. (carried)
   - **The modern-API inventory, register-only until each is a block.** `apple:modernize`'s
     suggestions land here too, per §7.5. (carried)
     - **Free at 16.0:** `.contentTransition(.numericText(countsDown: true))` on the sprint countdown
       (`FocusTimerBarContent.swift:194`) and ~20 `.monospacedDigit()` counters;
       `.presentationBackground` (16.4) on three sheets.
     - **Needs 17:** `ContentUnavailableView` in four empty states;
       `.contentTransition(.symbolEffect(.replace))` for pause/play and the chevrons; interactive
       widgets (`Button(intent:)`) and routine Live Activity check-off; the `@Observable` migration
       (27 classes); TipKit for the card's gestures.
     - **Needs 18/26:** `Tab`/`.tabBarMinimizeBehavior` and `.glassEffect`, both constrained by the
       custom `AppTabBar` (adoption means replacing it).
   - **Two RM sites that remove the press affordance entirely** (`AppTabBar.swift:266`,
     `AppSearchRow.swift:71`), and `RootView.swift:63`'s declared-but-unread `reduceMotion` beside
     two unguarded animations. §7.2's first sweep candidates. (carried)

1. **E's one un-run device check: airplane mode + pull-to-refresh on Home.** `F-HomeTasksLastKnown`
   (`8b5f740`) should keep the last-known task set rather than emptying it. (carried)

2. **Small defects in the card, none blocking:** (carried)
   - **`FocusBarCardShape.roundsBottomCorners` is a `Bool` with no `animatableData`**, so the corner
     morph SNAPS inside the 350ms spring.
   - **The card's `.accessibilityAction(named:)` may attach to nothing.** It wants an Accessibility
     Inspector pass: this bar is the app's only door to `FocusSprintDetailView`.
   - **`FocusTimerBarContent` has no `#Preview` of its own.**
   - **A slow location fix delays the completion CARD, not just the write.**
   - **The stack has no UI journey** and probably cannot have a useful one.

3. **Two more dead design tokens, and two dead helpers.** `BarSurface` is defined, unit-tested and
   used by nothing; `AppTabBarPresentation.slotWidth` / `restingSlotWidth` have ZERO production call
   sites and **disagree about their input**. (carried)
4. **Accuracy-aware containment for the arrival card — ONLY if E still sees drops after #32.**
   (carried)
5. **Arc 2 — first-class routines + the "at a time" trigger.** (carried)
6. **`F-Search-3-Journal`** — recommendation is still to kill the block. (carried)
7. **The Live Activity design review** E parked. (carried)

## C · Parked on E's instruction — do not start unprompted

- **Places backgrounding dismiss bug** — waiting on E's iOS update. (carried)
- **App connections** — real two-way sync; Apple Notes has no iOS API. (carried)
- **LA interactive buttons**, **time-of-day triggers**, **smart skip**. (carried)
- **`OfflineSprintSummaryCard`** — E ruled it out of the focus-card arc explicitly. It shares
  `RootBottomOverlay`'s VStack with the completion stack, so two visual languages can be on screen
  together. `F-FocusCard-5` records it. (carried)

## D · Launch blockers — no conversation opened yet

- **Free dev account** → 7-day profiles; the current one is valid to **2026-09-17**. (carried)
- **Sign in with Apple** built but dormant. (carried)
- **A way to turn the Confirm confetti off.** E chose no switch for now (2026-09-11). Because it
  deliberately ignores Reduce Motion, people who turned Reduce Motion on for motion sensitivity get
  full-screen falling confetti with no escape. Revisit before launch. (NEW)

## E · Known, not work

- **Xcode's MCP bridge (`xcrun mcpbridge`, server `xcode`) was DOWN again this session**
  (CONNECTION_CLOSED at startup). Open Xcode BEFORE the session. Every figure above is pasted
  `xcodebuild` output, which is the bar either way. The bridge's 2,688-vs-2,663 enumeration question
  is still unchecked. (updated)
- **A green suite cannot see a `View`'s appearance, and this block proved it twice more.** Neither
  the draw-on's timing nor the reduced halo's collision with the card is visible to any assertion
  that holds.
  - **Render the view to PNG from a unit test before the device build:** `UIHostingController` +
    `UIGraphicsImageRenderer` + `drawHierarchy(afterScreenUpdates: true)` in a scene-attached
    `UIWindow`, a synchronous test pumping `RunLoop.main`.
  - **Render IN SITU, not just the leaf:** the halo's collision exists only against the card's real
    edges and text.
  - The probe from this block is kept outside the repo in that session's scratchpad; rebuild it from
    the evidence README's description if needed. (updated)
- **`Executed N tests, with M failures` counts failed ASSERTIONS, not failing TESTS.** Predict in
  TESTS, then reconcile. Names: `grep -oE "Test Case .*' failed" <log> | sort -u`. (carried)
- **SwiftLint's 400-line file, 250-line `type_body_length` and 40-character `type_name` ceilings.**
  The first two are one TEST away in the big files; the third bit a test class name this block.
  (updated)
- **A `devicectl` launch denied with `Security` / "invalid code signature… not explicitly trusted"
  right after a re-issued profile is TRANSIENT — retry once before escalating to E.** The three
  species: `Locked` (unlock), `Security` + valid profile (retry), `Security` + expired profile or
  "No Accounts" (E signs in via Xcode → Settings → Accounts). (carried)

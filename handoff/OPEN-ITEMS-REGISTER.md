# Open items register — 2026-09-11 (twenty-eighth edition; SESSION CLOSE-OUT — the Confirm celebration is on E's phone at 5.4 s; next session: celebrations for other CTAs)

*The close-out of the session that built `F-ModernIOS-2-Celebration` and `F-ConfirmCelebration-1`.
E's last two asks:
- **"extend the animation length by 1.2 seconds"** — done, in this edition's PR;
- **"safely close this session out … I want to focus on assigning animations such as this one we've
  just created to other CTA buttons etc. throughout the app."**

The next session's opener is **`handoff/START-HERE-cta-celebrations.md`**. The consumed
`START-HERE-modern-ios-celebration.md` is archived in the same move. Supersedes the twenty-seven
earlier editions.*

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding, so it is the thing to read and to
update rather than improvising a list in chat.

Every figure below was measured this session unless marked (carried).

## State

**`main` @ this edition's merge (the +1.2 s PR; its last code commit is `967472a`).** Nothing is in
flight once it merges; every branch this session was deleted by its merge. `firestore.rules` is
untouched, so there is **nothing for E to republish**.

**E's phone runs `967472a`'s app code**, installed and launch-verified at **10:26 BST on
2026-09-11** (earlier installs: 09:54, 09:06, 07:32, 07:02). Reduce Motion is still ON there, as E
left it. (carried)

**Verified at close** (the last code change, +1.2 s):
- unit suite **2,710 / 0**, emulator UP, **0** `127.0.0.1:9099` hits;
- SwiftLint **0 / 751**;
- sim `** BUILD SUCCEEDED **` (at close) and device `** BUILD SUCCEEDED **`.

Coverage was last measured at block 1:

```
ADHD LifeOS.app              26.87%  (12470/46405)  ← was 26.75% (12309/46014) at #65; comparable (tree grew, whole target measured both times)
ADHD LifeOSTests.xctest      95.09%  (43131/45358)
ADHD LifeOSUITests.xctest     0.00%  (0/2962)       ← skipped in the standard run by design
FocusTimerWidgetExtension    10.30%  (228/2214)     ← read the 233-line testable surface, not this
```

The new pure files are at 97–100%. `ConfirmCelebrationOverlay` is 0/217: a view body, which the
render probe exercises and no unit test can.

### Landed this session (PRs #65–#72)

- **#65 `F-ModernIOS-2-Celebration`.** The in-ring completion celebration's three motion modes:
  - `.full` below iOS 26;
  - `.reduced` with Reduce Motion ON: geometry pinned, opacity only;
  - `.modern`, the iOS 26 draw-on tick.

  Reduce Motion is resolved before the tier. Evidence: `screenshots/focus-completion-celebration-modes/`.
- **#66, then #68: the fades are E's numbers.** Halo **2.1 s**, Reduce Motion tick **1.1 s** (first
  doubled from 0.9 / 0.4, then named by E), pinned by `testTheFadesRunAtTheLengthEAskedFor`.
- **#67 (+ #70, #71): the Confirm-celebration design record**, `handoff/SESSION-OPENER-confirm-celebration-design.md`,
  permanent. It holds E's nine answers, R1–R9, and every number; E: "R1, R2, R9 (a+b) = Approved".
- **#69 `F-ConfirmCelebration-1`.** Every Confirm gets the glow, the rain and both corner cannons,
  plus the success haptic.
  - A second service stamp: `FocusConfirmation`, written before `await log`.
  - A pure engine: `ConfettiPhysics` / `ConfettiRecipe` / `ConfirmCelebrationQueue`, capped at 3.
  - One always-mounted overlay in `RootView`, which draws only while a burst is live.
  - CLAUDE.md §7.2 carries E's waiver.
  - Red 2,708 / 46 (4 unexpected, 32 tests), predicted per test; both red-check pairs exact.
  - Evidence: `screenshots/confirm-celebration-block-1/`. A real Confirm fires it on the real clock,
    it leaves 0 pixels behind, and ordinal 1 is the prototype E chose.
- **#72 (this edition): +1.2 s.** The 4.2 s choreography is stretched evenly over **5.4 s**
  (`extraLength`, `pace`, `choreographyTime`), so every piece and beat is kept.
  - Red 2,710 / 8 (3 tests), predicted; a red-check on the clock wiring was exact.
  - `12-every-confirm-light-dark-5.4s.mp4` shows the shipped length.

### What this session established

- **The iOS 26 draw-on does NOT wait for a transaction's delay.** It draws at insertion, so with
  Reduce Motion OFF the tick draws during the card's slide-up. The lever is to land `.modern` after
  `delay`.
- **The reduced halo pinned at 1.6 overhangs the 76 pt card** (77.3 pt) and runs ~7 pt behind the
  text; ≤ 1.25 clears it. Frame: `…-modes/34-…`. E's lever.
- **A stored `@Published` cannot live in an extension.** Room for the 400-line bar comes from moving
  METHODS out (the `+Completions` / `+Persistence` / `+Notifications` arrangement).
- **A countable red needs inert stubs.** Use early `XCTUnwrap` and count-first assertions. A thrown
  source-read error counts as "unexpected"; an `XCTUnwrap` failure does not.
- **"Nothing left drawn" is provable.** Diff late live frames against a window that never mounted
  the layer (0 pixels).
- **Parity with a prototype is provable too.** Re-run the prototype's generator with its seeds and
  compare field for field.
- **To lengthen a physics animation E likes, stretch its clock** rather than tacking on a tail. A
  tail draws off-screen or thins the effect, and the stretch keeps what E approved.
- **SwiftLint:** `type_name` ≤ 40 characters, `identifier_name` ≥ 3 (no `x`, `y`, `xs`),
  `large_tuple` > 2 warns. With `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, passing a static
  method by reference into `map` warns; use a closure.
- **`Animation` equality is reliable at runtime**, and a nested insertion transition does not replay
  when its parent is rebuilt.
- **`xcodebuild` prints "Executed 1 test" (singular)**, so read the exit code.

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
- **`FocusSessionService.swift` was at 394/400**; it is 374 since `F-ConfirmCelebration-1` moved the notification pair out.

### What the peek work established (2026-09-10) (carried)

- **What the eye reads is a sliver's HEIGHT, not its contrast.** Render the options before ranking
  levers.
- **`peekStep = 14` is the app's ONLY sanctioned off-grid spacing value**, waived in CLAUDE.md §2 and
  pinned by `testThePeekStepIsTheValueEChoseByLooking`. **Do not "correct" it.**

## A · Decisions only E can make — minutes each

- [ ] **ONE short sprint gives BOTH open device verdicts** (the phone has everything as of 10:26 BST;
      Reduce Motion stays ON, as E has it):
      1. **When the sprint finishes → `F-ModernIOS-2-Celebration`'s Reduce-Motion-ON verdict.**
         Expect a CUT arrival, a bold green halo fading over 2.1s, the tick fading in over 1.1s
         after ~0.3s, nothing scaling, and the success haptic.
      2. **Tap Confirm → `F-ConfirmCelebration-1`'s verdict.** Expect:
         - the card leaves;
         - the success haptic;
         - a green glow swelling from the bottom;
         - confetti raining from the top AND fired from both bottom corners at once, falling over
           the tab bar and gone by ~5.4s (E's +1.2 s, played as an even stretch at ~78% speed —
           if it reads floaty, the alternative is the old speed with a longer tail);
         - taps still working underneath.

         With two cards waiting, each Confirm fires its own celebration, and they overlap. Worth an
         eye: whether it stutters on the phone (the prototypes were rendered offline, so this is
         the first real-time run), and whether the glow reads in light. Evidence lands as `40-…`
         in `screenshots/confirm-celebration-block-1/`. (NEW)

      **R3–R8 shipped as the record's defaults**, since E approved only R1, R2 and R9: one overlay
      in `RootView`; the haptic on the overlay; a fresh seed per Confirm; the glow in both
      appearances; the card's dismissal unchanged; no VoiceOver announcement. Any of them is E's to
      change at this verdict.

- [ ] **E's device verdict with Reduce Motion ON — this closes `F-ModernIOS-2-Celebration`.**
      Folded into the one-sprint item at the top of this section (its step 1), which carries what to
      expect. Its evidence still lands as `40-…` in `screenshots/focus-completion-celebration-modes/`.
      (NEW)
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
- [ ] **E's SECOND change.** E has now named the next focus, celebrations on other CTAs. Whether
      that IS the long-pending "second change" is unconfirmed: ask in the next session. (updated)

## B · Real work, ready to start — recommended order

**00. NEXT SESSION — celebrations for the app's other call-to-action buttons.** E, verbatim: *"I
   want to focus on assigning animations such as this one we've just created to other CTA buttons
   etc. throughout the app."* **Nothing is decided or built.**
   - The opener, **`handoff/START-HERE-cta-celebrations.md`**, carries a verified survey of 23 CTA
     sites and their current feedback, the engine to reuse, the constraints, and E's open questions.
   - The key constraint: **§7.2's Reduce Motion waiver covers ONLY the Confirm celebration**; every
     new site needs E's own answer, and the off switch (§D) becomes more pressing.
   - Design-first (brainstorming, architectural path), then a record, then E's approval. (NEW)

**0a. The Confirm celebration — E's ask (2026-09-11). RECORD APPROVED; BLOCK 1 BUILT and on E's
   phone (awaiting E's verdict, see A); block 2 (fireworks + dim) waits on that verdict.** A celebration that uses the full screen when the user taps Confirm on a
   completion card. **The record is `handoff/SESSION-OPENER-confirm-celebration-design.md`**,
   renamed from the `…-confetti-design.md` the last edition promised because it now covers
   fireworks, the glow and the dim as well. Its evidence is `screenshots/confirm-celebration-prototypes/`.
   **E's nine decisions, all settled:**
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

   9. **"extend the animation length by 1.2 seconds"** (after block 1): shipped as an even stretch to
      5.4 s (#72), pending E's feel.

   **Both blocks are in `TODO-CLAUDE-CODE.md`; block 1 is ticked.** Block 2 needs no more room:
   `FocusSessionService.swift` is at 374 and `RootView.swift` at 394.
   - How it would draw: the fireworks and the dim go inside `ConfirmCelebrationFrame`, key on
     `FocusConfirmation.clearedStack`, and extend `ConfirmCelebrationQueue.length(of:)`.
   - **Two questions for E before building it:** does the +1.2 s stretch apply to the fireworks too
     (≈ 5.0 s → ≈ 6.4 s)? And should block 2 wait for the CTA arc's design, which may generalise
     the engine?

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
  full-screen falling confetti with no escape. Revisit before launch, and **before celebrations
  spread to other buttons** (B.00). (updated)

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
  - The probes from this session are kept outside the repo in its scratchpad
    (`ZZFocusCelebrationRenderProbe`, `ZZConfettiPrototypeProbe*`, `ZZConfirmCelebrationRenderProbe`).
    Rebuild from the evidence READMEs' descriptions: a scene-attached `UIWindow`, an injected time,
    ffmpeg for video. (updated)
- **`Executed N tests, with M failures` counts failed ASSERTIONS, not failing TESTS.** Predict in
  TESTS, then reconcile. Names: `grep -oE "Test Case .*' failed" <log> | sort -u`. (carried)
- **SwiftLint's 400-line file, 250-line `type_body_length` and 40-character `type_name` ceilings.**
  The first two are one TEST away in the big files; the third bit a test class name this block.
  (updated)
- **A `devicectl` launch denied with `Security` / "invalid code signature… not explicitly trusted"
  right after a re-issued profile is TRANSIENT — retry once before escalating to E.** The three
  species: `Locked` (unlock), `Security` + valid profile (retry), `Security` + expired profile or
  "No Accounts" (E signs in via Xcode → Settings → Accounts). (carried)

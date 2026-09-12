# F-CTACelebrations-3 — the centre, the shared layer, the four surfaces, Confirm re-routed

**Environment.** iPhone 17 Pro simulator (iOS 26.5, the machine's only runtime), rendered at 2× from
the unit-test host on `feature/cta-celebrations-3` @ `2527a62`, 2026-09-12 (07:58–09:04 BST).
- **No backend, no account, no sign-in, nothing written anywhere.** Every scene is built from test
  doubles and plain value types; `FocusSessionService()` is constructed with all-default
  dependencies (no logger, no mirror, no scheduler, no store), and `CelebrationCenter` is given an
  injected gate, so the probe never touches Firestore and never writes the simulator's own
  `UserDefaults`.
- The scenes are the **real** `CelebrationFrame`, `CelebrationStage`, `CelebrationLayer`,
  `CelebrationCenter` and `RootBottomOverlay` — in situ, not copies. In 03/04 the Confirm is stamped
  **after** mount, so the bridge's own `.onChange` is what starts the burst.
- The probe (`ZZCelebrationBlock3Probe.swift`) ran from the test target and was removed from the
  tree before the commit that adds this folder. Rebuild it from "How to rebuild the probe" below.
- **No throwaway data was created**, on device or in any backend, so there was nothing to clean up.

The design: `handoff/SESSION-OPENER-cta-celebrations-design.md` — E's **ARCH** answer ("One layer per
surface", chosen over a passthrough `UIWindow`), **R-c**, **R-g**, and the §7.2 waiver E granted the
Confirm celebration by name on 2026-09-11.

## Verified paths (CLAUDE.md §7.3)

> **No `#available` site is added or changed by this block, and no tier was passed over.** `Canvas`
> and `TimelineView(.animation)` are iOS 15 and `onGeometryChange(for:of:action:)` is back-deployed
> to 16.0 in the 26.5 SDK, so every file here is a single implementation that runs the same code on
> every OS at or above the 16.0 floor. §7.1's filter asks whether a later tier shows the user
> something the tier below cannot; for a particle field none does — `MeshGradient` (18) would draw
> the glow the radial gradient already draws, and `.visualEffect` (17) and `.glassEffect` (26) have
> nothing to act on. The one mount that sits inside an existing `#available(iOS 17.0, *)` is the
> routine cover's, and it adds no gate of its own.
> - **Full path:** run on the 26.5 simulator (every row below) and on E's phone from `main`.
> - **Reduced:** run on sim (injected — 07 and 08). **NOT on device.**
> - **iOS 16–25:** behaviour is COMPILE-ONLY; no older runtime is installed.
>
> **No RM-on device pass is owed, and this is the reason** (§7.3, E's call 2026-09-12). A block owes
> one only when it ADDS or CHANGES a reduced site. This block adds none. It moves where Reduce Motion
> is READ — out of the celebration's own files and into `CelebrationMotion.resolve`, one place — and
> the only celebration that exists today is the Confirm, which is **§7.2's named waiver** and renders
> identically either way (07 proves it, 08 proves the comparison could have caught it). The still
> recipes this block adds are not requested by anything yet: the nine pops are
> `F-CTACelebrations-4`, which is the first block that owes an RM-on device pass, and the four
> milestones are `-5`.

Nobody here can say "works on iOS 16" yet, and nothing in this folder does.

## Why this folder exists

The block DELETES `ConfirmCelebrationOverlay.swift` and rebuilds what it did out of a shared centre,
a shared frame and four layers. E's device verdict for it is "Confirm indistinguishable from today",
and that is a claim about pixels that no assertion in the suite can make: every unit test in
`ConfirmCelebrationTimingTests`, `ConfirmCelebrationDimTests` and `ConfettiRecipeTests` was green
before the move and stayed green through it, because they test the maths, which did not change.

E's per-surface architecture has a second failure mode that is silent by construction — a cover that
hosts a celebration site but mounts no layer draws nothing and passes everything — so the surface
isolation is shown here rather than only enumerated by `CelebrationMountCallSiteTests`.

## What these settle that the tests cannot

1. **The moved frame draws the shipped Confirm, pixel for pixel — within one 8-bit level.** Twelve
   frames of the SHIPPED `ConfirmCelebrationFrame` (two kinds × four instants × both appearances)
   were rendered and kept **before** the overlay was deleted; the moved `CelebrationFrame` was then
   rendered at the same twelve instants. **No pixel in any of the twelve differs by more than 1
   channel level of 255**, and most differ not at all.
2. **Those one-level differences are the RENDERER, not the move, and that is proven rather than
   asserted.** Rendering the *same, unchanged* code in a different process reproduces exactly the
   same counts — `every-0.3-light` differs from the shipped baseline in 109,847 pixels at worst=1,
   and from the previous run of the identical new code in **the same 109,847 pixels at worst=1**.
   Re-run twice, identical both times. Diagnosed before it was explained: the differences are one
   level in one channel, and in an otherwise-empty frame they are a single full-width row
   (`y=58…58`, `x=0…779`) — a gradient band boundary moving by one least-significant bit.
3. **And that tolerance is not vacuous.** The same comparison between the new frame at 1.2 s and the
   shipped frame at **2.6 s** differs in **1,121,066 pixels, worst channel delta 247**. A tolerance
   that cannot tell two frames apart is not a measurement.
4. **The live chain runs.** 03 drives the real path — `FocusSessionService.latestConfirmation` →
   the bridge on `RootBottomOverlay` → `CelebrationCenter` → `CelebrationLayer(surface: .root)` —
   with the stamp written after mount. It differs from the identical scene with no Confirm stamped
   (04) in **1,124,815 of 1,316,640 pixels**. Pixels prove what is drawn; only this proves anything
   reaches it.
5. **One layer per surface, and only one.** A burst requested while `.routineCover` is frontmost is
   drawn by the cover's layer (05: 1,126,050 pixels over an empty canvas) and by the root's layer in
   **0 pixels** (06). Without the second half, "the cover drew it" would be equally true of an
   implementation that drew it everywhere.
6. **E's §7.2 waiver survives the shared layer.** With one resolver reading Reduce Motion for every
   celebration, the Confirm must come out the same either way: injected ON versus OFF differs in
   **0 pixels**, in light and dark. 08 is the control — the same burst forced to `.still` differs in
   **62,996** pixels (light) and **62,072** (dark), so the comparison would have caught the waiver
   being undone.

## The files

| file | what it proves |
|---|---|
| `00-confirm-1.2s-light.jpg` | The moved `CelebrationFrame` at 1.2 s of choreography, light. Within one channel level of the frame that shipped. |
| `01-confirm-1.2s-dark.jpg` | The same instant, dark. The glow shows in both appearances (R6); only the dim is light-only. |
| `02-stack-clearing-1.2s-light.jpg` | The stack-clearing Confirm — fireworks and the light-mode dim — still drawn only for `clearedStack`, through the shared frame. |
| `03-live-confirm-through-the-centre.jpg` | The real chain: a Confirm stamped into `FocusSessionService` **after** mount, bridged by `RootBottomOverlay`, routed by `CelebrationCenter`, drawn by the root layer. |
| `04-live-control-no-confirm.jpg` | The control for 03 — the identical scene with nothing stamped. 1,124,815 of 1,316,640 pixels differ between them. |
| `05-routine-cover-layer.jpg` | A `.routineCover` burst drawn by the routine cover's OWN layer. |
| `06-root-layer-silent.png` | The same burst, same instant, rendered by the ROOT layer: **nothing**, to the pixel. PNG because the claim is exactly zero. |
| `07-confirm-reduce-motion-on-light.jpg` | The Confirm with Reduce Motion injected **ON**. Identical to the Reduce Motion OFF render in 0 pixels — E's §7.2 waiver, intact through the shared layer. |
| `08-control-forced-still-light.jpg` | The control for 07: the same burst forced to `.still`. 62,996 pixels differ, so 07's "identical" is a measurement rather than a coincidence. |

## How to rebuild the probe

A throwaway `XCTestCase` in the test target (`@MainActor`, named `ZZ…` so it sorts last), deleted
before the commit. Block 2's recipe still holds — a scene-attached `UIWindow`, a synchronous
`RunLoop.main.run(mode:before:)` pump, appearance via `window.overrideUserInterfaceStyle`, and RGBA
comparison rather than PNG bytes. Four things this block added, each of which cost a run:

- **Capture the baseline BEFORE deleting the old file.** The whole of claim 1 depends on twelve
  renders of code that no longer exists. They were written to the scratchpad, outside the repo, in
  the same session and before the deleting commit; once `ConfirmCelebrationOverlay.swift` was gone
  there would have been no "today" left to diff against.
- **Prove the harness is deterministic before making any pixel claim.** The probe renders one scene
  twice in the same run and asserts 0 differing pixels first. Without that, a cross-run difference
  says nothing about the code that changed between the runs — and with it, the ≤1 noise could be
  attributed to the renderer with evidence instead of a guess.
- **`TimelineView` draws at the REAL instant, so a burst dated in the future renders an empty
  canvas — and two empty canvases agree with each other.** The Reduce Motion comparison passed
  vacuously the first time for exactly this reason: both renders were blank, `differing = 0`, and
  the only tell was the PNG being byte-for-byte the size of the empty-frame baseline. Compare at a
  FIXED `date` through `CelebrationFrame`, and give every "identical" claim a control that shows the
  comparison can see a real difference.
- **Guess bounds last, measure them first.** The forced-still control was written as `> 100_000` and
  failed at 62,996 — the code was right and the expectation was invented. A still field is 120
  pieces at rest against 220 in flight; that is a large difference, but nothing like the whole-screen
  change a glow makes.

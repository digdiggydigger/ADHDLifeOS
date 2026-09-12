# F-CTACelebrations-4 — the nine mini confetti pops

**Environment.** iPhone 17 Pro simulator (iOS 26.5, the machine's only runtime), rendered at 2× from
the unit-test host at a fixed 393 × 852 pt — **E's iPhone 15 Pro's point size, so the videos are
life-size** — on `feature/cta-celebrations-4`, 2026-09-12.

- **No backend, no account, no sign-in, nothing written anywhere.** Every scene is built from plain
  value types and a `CelebrationCenter` constructed with an injected gate, so no probe touched
  Firestore or the simulator's own `UserDefaults`.
- The scenes use the **real** `TaskRow`, `CelebrationPopSource`, `CelebrationCenter`,
  `CelebrationLayer`, `CelebrationStage`, `CelebrationFrame` and `CelebrationRecipes` — in situ, not
  copies.
- Two throwaway probes ran from the test target and were removed from the tree before the commit
  that adds this folder: `ZZCelebrationPopProbe` (00–05, the variants E chose from) and
  `ZZPopEvidenceProbe` (06–14, the wired chain). Rebuild both from
  `screenshots/cta-celebrations-block-3/README.md`, plus the two notes at the bottom of this file.
- **No throwaway data was created**, on device or in any backend, so there was nothing to clean up.

The design: `handoff/SESSION-OPENER-cta-celebrations-design.md` — E's **F6** (the mini confetti pop,
chosen over a halo and tick), **#7** (the still scatter under Reduce Motion), and **R-e** (the Create
Task sheet holds so its pop can be seen).

## Verified paths (CLAUDE.md §7.3)

> **No `#available` site is added or changed by this block, and no tier was passed over.**
> `onGeometryChange(for:of:action:)` is back-deployed to iOS 16.0 in the 26.5 SDK, and `Canvas` and
> `TimelineView(.animation)` are iOS 15, so every file here is a single implementation that runs the
> same code on every OS at or above the 16.0 floor. §7.1's filter asks whether a later tier shows the
> user something the tier below cannot; for a particle field thrown from a measured point, none does.
> - **Full path:** run on the 26.5 simulator (every row below) and on E's phone from `main`.
> - **Reduced:** run on sim (injected — 10, 11, 12). **E's phone with Reduce Motion ON: pending E's
>   pass.** This is the FIRST block that owes one (§7.3, E's call 2026-09-12), because it is the
>   first to add reduced sites — nine of them.
> - **iOS 16–25:** behaviour is COMPILE-ONLY; no older runtime is installed.

Nobody here can say "works on iOS 16" yet, and nothing in this folder does.

## Why this folder exists

Two claims in this block cannot be made by any assertion in the suite.

**The first is E's, and it is the whole reason the block renders before it wires:** which pop. F6
settled the family ("12 to 20 pieces from the tap point"); it could not settle whether that reads as
a celebration or as a smudge on a 393 pt screen. E picked **A** from four, by looking.

**The second is the app's own wiring.** `F-CTACelebrations-3` shipped `CelebrationPopSource`,
`CelebrationKind.pop` and `CelebrationRecipes.pop` with **no production call site at all** — every
one unit-tested, correct, and incapable of putting a single piece of paper on screen. Thirteen
call-site guards now grep the tree for the call, but a guard proves a line exists, not that the
chain it belongs to runs. 06–09 run it.

## What these settle that the tests cannot

1. **The pop leaves from the circle, not from the middle of the screen.** On a real `TaskRow`, the
   paper's centroid 50 ms after launch sits at **(334.9, 309.6)** against the circle's measured
   centre of **(339.0, 306.3)** — 4 pt. A `nil` origin would have drawn a perfectly plausible pop
   from the canvas centre and nothing would have complained.
2. **The whole chain runs, and it is the chain the user drives.** A real `CelebrationPopSource`
   hands its content a handle; calling it — which is exactly what the tap does — reaches the real
   centre, which tags a real burst with a real origin, which the real layer draws: **3,047 pixels**
   differ from the same scene before the tap (07 against 06).
3. **A layer inside a presented cover DOES inherit the centre from outside it — and until now
   nothing had shown that at runtime.** `F-CTACelebrations-3` asserted the two `.environment(…)`
   lines sit outside the covers' chain and proved the layers draw, but both of its probes injected
   the environment themselves; the register recorded the gap and said the first pop on the Tasks
   search surface would be the first real test of it. It is: **2,761 pixels** (08).
4. **And that is not vacuous.** The same cover, the same burst, with the inner layer mounted for the
   WRONG surface draws **0 pixels** (09). Without this half, "the cover drew it" would be equally
   true of a build that drew every burst on every layer.
5. **The reduced path is a still scatter that fades, and its rise and fall are exactly symmetric.**
   10 and 12 — 150 ms and 650 ms — are **byte-identical**, because `fadeIn` 0.3 and `fadeOut` 0.7
   over a 1.0 s pop put both instants at 50 % opacity. That is the "rise then fall, no hold" E was
   shown and chose to keep, measured rather than described.

## The files

| file | what it proves |
|---|---|
| `00-pop-on-a-real-taskrow-080ms.jpg` | Variant A, 80 ms after launch, on a real `TaskRow` in a real Tasks-style card. The paper is still a tight cluster on the close-circle. |
| `01-pop-on-a-real-taskrow-220ms.jpg` | 220 ms: the radial throw, at its most legible. |
| `02-pop-on-a-real-taskrow-400ms.jpg` | 400 ms: drag and gravity have taken over and the pieces are fading. |
| `03-pop-on-a-real-taskrow-dark-220ms.jpg` | The same instant in dark. The seven confetti tokens carry both appearances; nothing about the pop is light-only. |
| `04-the-four-variants-E-chose-from.jpg` | **The choice.** Rows top-to-bottom A / B / C / D, columns 80 / 220 / 400 / 650 ms. E picked **A — as designed**. |
| `05-the-chosen-pop-variant-A.mp4` | Variant A at true speed, life-size. What E actually judged. |
| `06-control-before-the-tap.jpg` | The control for 07 — the identical scene with nothing requested. |
| `07-live-pop-through-the-real-chain.jpg` | The real wrapper → real centre → real layer, 120 ms in. 3,047 pixels differ from 06. |
| `08-a-cover-inherits-the-centre.jpg` | A pop inside a presented cover, drawn by the cover's OWN layer, reading the centre from outside the cover. The question block 3 left open. |
| `09-control-wrong-layer-draws-nothing.png` | The control for 08: the same burst, a layer mounted for the wrong surface. **Nothing, to the pixel.** PNG because the claim is exactly zero. |
| `10-reduced-still-pop-150ms.jpg` | Reduce Motion, rising: the same pieces already scattered within 48 pt, at rest, at 50 % opacity. §7.2's opening-pose rule — the first frame has the final geometry. |
| `11-reduced-still-pop-300ms.jpg` | The peak, and the only instant that reaches it. |
| `12-reduced-still-pop-650ms.jpg` | Falling, at 50 % — **byte-identical to 10**, which is the rise-then-fall symmetry as a measurement. |
| `13-the-reduced-still-pop.mp4` | The reduced path at true speed. |
| `14-live-pop-real-layer-real-clock.mp4` | The live chain recorded off the real `TimelineView` at the real instant, rather than reconstructed at fixed dates. |

**Which origin is which, and it matters.** 00–05 are the real `TaskRow`, whose origin is its
**close-circle** — `TaskRow` records that point with `.celebrationPopOrigin` and requests the pop in
its shared `close()`, so its circle and its swipe throw from one place. 06–14 use a synthetic row
wrapped in `CelebrationPopSource`, whose origin is the **wrapper's own centre**; that is the shape
the other eight sites use, where the wrapper IS the button.

## How to rebuild the probes

Block 3's recipe still holds — a scene-attached `UIWindow`, a synchronous
`RunLoop.main.run(mode:before:)` pump, appearance via `window.overrideUserInterfaceStyle`, RGBA
comparison rather than PNG bytes, the harness proved deterministic before any pixel claim (it was:
one scene rendered twice, **0** differing pixels, against a control at another instant differing in
**3,912**). Two things this block added, each of which cost a run:

- **A minHeight-flexible row will eat the whole screen.** `TaskRow` is `.frame(minHeight: 56)`, so
  in a `VStack` with a `Spacer` it competes for the leftover height and rendered at 172 pt instead
  of 74. The first set of variant renders was made on rows nearly three times life-size. The fix is
  `.fixedSize(horizontal: false, vertical: true)` on the card.
- **To drive the real chain, let the handle escape the wrapper's body.**
  `CelebrationPopSource { handle in … .onAppear { box.handle = handle } }` gives the test the same
  trigger the button has, so the probe exercises the wrapper, the environment, the centre, the
  policy, the burst and the layer instead of injecting a burst into a frame. It is the difference
  between a picture of the drawing and a picture of the feature.

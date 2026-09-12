# F-CTACelebrations-1 — the four haptic tidies and the closure card's spring-in

**Environment.** iPhone 17 Pro simulator (iOS 26.5, the machine's only runtime), rendered at 2× from
the unit-test host on `feature/cta-celebrations-1` @ `3e945fd`, 2026-09-12 (03:45–04:10 BST).
- **No backend, no account, no sign-in, nothing written anywhere.** The card is built from literals;
  the probe never touches Firestore.
- The scene is the real `ClosureCelebrationCard` and the real `BestNextMoveCard` in the real
  `Group { if … else … }` of `HomeMomentumSections.momentumLeadSection`, over `Color.pageBackground`.
- The probe (`ZZClosureCardSpringProbe.swift`) ran from the test target and was removed from the
  tree before the commit that adds this folder.

The design: `handoff/SESSION-OPENER-cta-celebrations-design.md` — E's decision **#8**, "the closure
card springs in", and §3's "The closure card's spring-in".

## Verified paths (CLAUDE.md §7.3)

> **A single implementation, no `#available`**: `.transition`, `.scale`, `.opacity` and
> `withAnimation` are all iOS 13, and no later tier renders this better (§7.1 — a tier ships only
> when it shows the user something the tier below cannot).
> - **Full path:** run on the 26.5 simulator (the middle row of each sheet) **and on E's phone**,
>   which is what E's verdict judged.
> - **Reduced path:** run on the 26.5 simulator with Reduce Motion INJECTED as a parameter — the
>   bottom row of each sheet. **NOT on device.**
> - **E's phone:** installed from `main` @ `49c78d9`. **E's device verdict PASSED** on 2026-09-12:
>   *"it feels good, all five work as you described."* All four haptics were judged by thumb, which
>   is the only way a haptic can be judged — nothing in this folder could have settled them.
> - **Which path that verdict judged, corrected 2026-09-12:** this README first recorded it as the
>   REDUCED path, on the standing fact that E's phone ran Reduce Motion ON. **E turned Reduce Motion
>   OFF earlier the same day** and confirmed it was already off for this test, so **the verdict
>   judged the FULL path — the spring, with the 0.9 scale measured below.** The reduced path is
>   verified by injection on the simulator only. See CLAUDE.md §7.2 and §7.3.
> - **iOS 16–25:** behaviour is COMPILE-ONLY; no older runtime is installed.

Nobody here can say "works on iOS 16" yet, and nothing in this folder does.

## Why this folder exists

The unit tests (`CTAHapticTidyCallSiteTests`) prove that both branches of the transition and both
branches of the animation are in the tree, and that no writer of `celebratedTask` bypasses the
animated setter. **None of them can show that the card actually moves** — a `.transition` whose
`withAnimation` never reaches it is a string that passes every assertion and renders a hard cut.
These sheets are the proof that it runs, and the measured widths are the proof that the two paths
are genuinely different code paths rather than the same fade twice.

The four haptic tidies have no visual evidence by nature: **a haptic cannot be photographed.** They
are settled by E's thumb, which is why this block's verdict is *by feel* rather than by looking.

## What the sheets settle that the tests cannot

Each sheet is three rows × six frames, one appearance per file. **Rows are the three code paths**,
top to bottom: `before` (the tree as it stood at `249343c` — no transition, no `withAnimation`),
`full` (Reduce Motion off), `reduced` (Reduce Motion on). **The `t = …` burnt into each tile is the
MEASURED elapsed second**, from `CACurrentMediaTime()` either side of the capture — never an instant
the probe asked for. Frames were aimed at 0.02/0.08/0.16/0.26/0.40/0.60 s and landed within about
30 ms of each aim.

1. **The card used to pop in, and now it arrives.** The `before` row is fully present and fully
   opaque in frame one, at t ≈ 0.04–0.12 s, and never changes across the whole 0.63 s. That is what
   Home did before this block. The two rows below it cross-fade from the Best-next-move card and
   settle by ≈ 0.43 s.
2. **The full path really scales, and the reduced path really does not.** Measured from the
   `CGImage` — the widest run of green-dominant pixels across the band holding the card's tick and
   title, in points, against a settled width of **370 pt** — over three consecutive probe runs:

   | path | narrowest sample | at | settled |
   |---|---|---|---|
   | `full` (light) | **340–355 pt** (0.92–0.96 ×) | t ≈ 0.11–0.19 s | 370 pt by t ≈ 0.29 s |
   | `full` (dark) | **346 pt** (0.935 ×) | t ≈ 0.11 s | 370 pt by t ≈ 0.42 s |
   | `reduced` (both) | **369.5 pt** (0.999 ×) | — | 370 pt throughout |
   | `before` (both) | 370 pt | frame one | never moves |

   The transition's floor is 0.9 (333 pt); the deepest sample catches the spring near its start, not
   at it, because at the instant the scale is 0.9 the opacity is still ≈ 0 and there is nothing to
   measure. **The reduced path never leaves final geometry** — §7.2's opening-pose rule, measured
   rather than asserted.
3. **Both paths read in light and in dark.** The card's green panel, tick, line and the two buttons
   are legible against `pageBackground` in both, at every instant after ≈ 0.19 s.

## Artefacts of the harness, not the app

- **Reduce Motion is a PARAMETER here, not an environment value.** `accessibilityReduceMotion`
  cannot be written through `.environment(\.)`, which is why production has `HomeView` read it and
  `HomeMomentumSections` consume the resolved value, and why this harness inlines the same two
  expressions. `testTheClosureCardSpringsInAndCrossFadesInsteadUnderReduceMotion` is what holds the
  harness and the tree together; if they drift, it fails.
- **The probe is a SYNCHRONOUS test** pumping `RunLoop.main`. An `async` one runs inside a
  main-queue block and cannot drain that queue, so nothing animates — the lesson that cost block 1
  a run.
- **The first two frames of each measured row read 370 pt because they are measuring the OUTGOING
  card**, which is full width and has green of its own ("Close it"). Only the frames where the
  incoming card dominates carry the scale signal.
- A ~59 pt safe-area inset sits above the card: the probe's first scan band missed the card entirely
  and reported zeros for every row, including the one that never animates. A measurement that
  reports nothing for a control that cannot move is measuring the wrong pixels, not the app.
- **A second probe that rendered the card ALONE was discarded as unreliable**, not merely
  inconclusive: with an empty else-branch the inserted card failed to render at all in some runs and
  appeared at ≈ 0.83 s in others, from identical code. No number in this README comes from it.
- There is no Today content above or below the slot; the page is the bare background.

## Files

| file | what it proves |
|---|---|
| `00-arrival-light-before-full-reduced.jpeg` | Light. Row 1 `before`: fully present at t = 0.073 s and unchanged to 0.624 s — the pop-in this block removes. Row 2 `full`: cross-fade from Best-next-move, narrowest 340 pt at t ≈ 0.11 s, settled 370 pt by t ≈ 0.29 s. Row 3 `reduced`: the same cross-fade, never below 369.5 pt — geometry final from the first frame, only opacity travelling. |
| `01-arrival-dark-before-full-reduced.jpeg` | The same three rows in dark: `before` static at 370 pt; `full` down to 346 pt at t ≈ 0.11 s; `reduced` at 370 pt throughout. The card's tint, tick and buttons read against the dark page in every frame. |

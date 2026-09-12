# F-ConfirmCelebration-2 — the stack-clearing fireworks and the light-mode dim

**Environment.** iPhone 17 Pro simulator (iOS 26.5, the machine's only runtime), rendered at 2×
from the unit-test host on `feature/confirm-celebration-2` @ `29c6267`, 2026-09-12 (01:40–01:50 BST).
- **No backend, no account, no sign-in, nothing written anywhere.** A real `FocusSessionService`
  on an in-memory logger and store, one card raised by `pushUnconfirmedCompletion` so that its
  Confirm is the stack-clearing one.
- The scene is the real `AppTabBar` + `RootBottomOverlay` + `ConfirmCelebrationOverlay`, layered
  the way `RootView` layers them, over the page background.
- The probe (`ZZConfirmCelebrationRenderProbe2.swift`, plus `ZZBlockOneBaselineProbe.swift` run in
  a throwaway worktree at `b5fe8c8`) ran from the test target and was removed from the tree
  before any commit; the worktree was removed too.

The design, every number and E's decisions: `handoff/SESSION-OPENER-confirm-celebration-design.md`
(the fireworks table, the dim, and E's block-2 decision 1 "Same stretch" recorded in
`handoff/SESSION-OPENER-cta-celebrations-design.md`). The prototypes E chose from:
`screenshots/confirm-celebration-prototypes/` (`20-` / `21-`, the 85 % column).

## Verified paths (CLAUDE.md §7.3)

> **A single implementation, with no `#available`**: `Canvas` and `TimelineView` are iOS 15, and
> no later tier adds anything to a particle field (§7.1: "no tier adds value").
> - **Sim:** run on the 26.5 simulator, live (a real Confirm on the real clock) and injected, light
>   and dark.
> - **E's phone:** installed from `main @ 9a7b664` after the merge; **E's device verdict PASSED**
>   on 2026-09-12 (Reduce Motion ON, E's setting).
> - **iOS 16–25:** behaviour is COMPILE-ONLY; no older runtime is installed.
> - **Reduce Motion:** none of the six celebration files reads it — E's §7.2 waiver, pinned by
>   `testTheConfirmCelebrationIgnoresReduceMotionByDesign`, now listing the three fireworks files.

Nobody here can say "works on iOS 16" yet, and nothing in this folder does.

## Why this folder exists

The unit tests prove each piece separately: the 14-shell table and its nine tokens
(`ConfirmFireworksScheduleTests`), the rise, the sparks, the fade and the flash
(`ConfirmFireworksPhysicsTests`), the dim's envelope and its tie to the last spark
(`ConfirmCelebrationDimTests`), the 6.43 s length on the same stretch
(`ConfirmCelebrationTimingTests`), and where the dim and the fireworks are drawn and gated
(`ConfirmCelebrationCallSiteTests`). None of them can show that a real stack-clearing Confirm
sets the fireworks off through the real overlay, what the dim looks like over the app, that
dark never dims, or that an every-Confirm is untouched. These frames do.

## What the frames settle that the tests cannot

1. **A real Confirm on the LAST card fires the fireworks and dims the page, on the real clock**
   (`00`, `01`). One card is waiting; `confirmCompletion` at t0 (`clearedStack = true`). In light
   the page dims within the first frame, the glow swells, the confetti rains and fires, the
   shells climb and burst in sequence to the two-shell finale, and the dim lifts as the last
   embers fade. In dark the same without any dim. The card leaves on the same tap.
2. **It leaves nothing behind, at the right moment.** Against a window over the same service that
   never mounted the celebration: light differs on every pixel while the dim is on and is
   **0 of 1,339,344 pixels different from t6.65 s** (the burst ends at 6.43 s); dark is
   **0 different from t6.22 s** (its last spark dies at 4.79 s of choreography = 6.16 s wall,
   and the last confetti has landed by 5.4 s). So a stack-clearing burst is pruned at its own
   longer length, and the layer draws nothing afterwards.
3. **Every Confirm is untouched by block 2** (`20`). The production frame for a NON-clearing burst
   at t1.21 s, rendered on this tree, was diffed against the SAME frame rendered by block 1's
   code (`b5fe8c8`, in a throwaway worktree): **0 of 1,339,344 pixels different, light and dark.**
   E's decision 2 holds: the fireworks are the whole difference.
4. **The dim is light-only and the fireworks read in both** (`10`–`13`, `30`). Light beside dark
   at four instants: the dim coming in (0.3 s of choreography), the first shells over the full
   glow (1.2 s), the last launch (2.6 s), and the dim lifting past the last spark (4.8 s). In light
   the sparks sit on a night-sky dim as they did in the 85 % column E chose; in dark the page is
   simply dark. The trails, the flashes and the ring-in-ring inner rings are visible in both.
5. **Same stretch.** The stills are labelled with both clocks: the choreography second the record
   is written in, and the wall second it lands on at the confetti's pace (× 5.4 / 4.2). The video
   (`30`) runs 6.6 s and the last frame is empty in both columns.

## Artefacts of the harness, not the app

- **Live timestamps are ordering evidence, not timing.** Each 2× capture costs roughly 0.2 s, so
  frames are about 0.3 s apart.
- **`10`–`13` and `30` are the production `ConfirmCelebrationFrame` at an INJECTED time**, 24
  frames a second, over the settled scene (no card). The video plays at real speed but is not a
  measurement of real-time performance: that is E's phone (the record's per-frame bound is
  ≈ 1,130 draw operations at the peak).
- The first attempt at the live run captured nothing: an `async` test method cannot drain the
  main queue from a nested `RunLoop.main.run`, so the Confirm task never ran. The register's note
  is right — the probe must be a SYNCHRONOUS test pumping `RunLoop.main`. A 1.0 s settle before
  the reference captures also removed a 69-pixel tab-bar selection-spring artefact.
- There is no Today content behind the furniture: the page is the bare background.

## Files

| file | what it proves |
|---|---|
| `00-live-stack-clearing-light-sheet.jpeg` | Light, real clock: one waiting card → Confirm → dim, glow, confetti and fireworks in sequence through the finale → the dim lifts → everything gone by t6.65 (0 pixels vs the never-mounted reference). |
| `01-live-stack-clearing-dark-sheet.jpeg` | The same in dark: no dim at any instant; gone by t6.22. |
| `10-stack-cleared-c0.3-t0.39-light-dark.jpeg` | The dim coming in (envelope ≈ 0.86) under the swelling glow; the first shell climbing. |
| `11-stack-cleared-c1.2-t1.54-light-dark.jpeg` | Shells 1–2 burst, 3 bursting (ring-in-ring), 4 climbing, over the full glow and the crossing confetti. |
| `12-stack-cleared-c2.6-t3.34-light-dark.jpeg` | The last launch: the finale pair climbing, mid-schedule shells at full spread. |
| `13-stack-cleared-c4.8-t6.17-light-dark.jpeg` | Just past the last spark (4.79 s): the dim lifting (envelope ≈ 0.32), confetti landed, sky nearly clear. |
| `20-every-confirm-t1.21-light-dark-unchanged.jpeg` | A NON-clearing Confirm's frame on this tree — pixel-identical (0 / 1,339,344) to block 1's rendering of the same frame. |
| `30-stack-cleared-light-dark-6.4s.mp4` | The production frame at real speed, 6.6 s, light beside dark: the whole stack-clearing celebration on the stretched clock. |
| *(no `40-` file)* | **E's device verdict, given in chat on 2026-09-12 without screenshots, PASSED:** "I've checked your most recent build on my iPhone, and it looks good. It looks as if it's working as as you specified." |

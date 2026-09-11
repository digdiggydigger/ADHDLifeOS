# F-ConfirmCelebration-1 — every Confirm's confetti, glow and haptic

> **Later the same day, E asked for the celebration to run 1.2 s longer.** It now plays its 4.2 s
> choreography evenly over 5.4 s. `00`, `01`, `10` and `11` were rendered BEFORE that, so read
> their timestamps against 4.2 s; `12` is the shipped length. The wiring, the overlap and the
> "nothing left drawn" result are unaffected; only the pace changed.

**Environment.** iPhone 17 Pro simulator (iOS 26.5, the machine's only runtime), rendered at 2×
from the unit-test host on `feature/confirm-celebration` @ `9314a13`, 2026-09-11.
- **No backend, no account, no sign-in, nothing written anywhere.** A real `FocusSessionService`
  on an in-memory logger and store, with two cards raised by `pushUnconfirmedCompletion`.
- The scene is the real `AppTabBar` + `RootBottomOverlay` + `ConfirmCelebrationOverlay`, layered
  the way `RootView` layers them, over the page background.
- The probe (`ZZConfirmCelebrationRenderProbe.swift`) ran from the test target and was removed
  from the tree before any commit.

The design, every number and E's decisions: `handoff/SESSION-OPENER-confirm-celebration-design.md`.
The prototypes E chose from: `screenshots/confirm-celebration-prototypes/`.

## Verified paths (CLAUDE.md §7.3)

> **The celebration is a single implementation**, with no `#available`: `Canvas` and
> `TimelineView` are iOS 15, and no later tier adds anything (§7.1).
> - **Sim:** it ran on the 26.5 simulator, live and injected, light and dark.
> - **E's phone:** verdict pending (Reduce Motion ON, which E's waiver makes identical to OFF).
> - **iOS 16–25:** behaviour is COMPILE-ONLY; no older runtime is installed.
>
> **The Confirm haptic** rides the house `.haptic` helper: `.sensoryFeedback` on 17+, the UIKit
> performer on 16. Its 17+ path is judged on E's phone; its 16 path is compile-only.

Nobody here can say "works on iOS 16" yet, and nothing in this folder does.

## Why this folder exists

The unit tests prove each piece separately:
- the maths (`ConfettiPhysicsTests`);
- the recipe (`ConfettiRecipeTests`);
- the timing and the cap (`ConfirmCelebrationTimingTests`);
- the stamp (`FocusConfirmationStampTests`);
- where each piece is mounted (`ConfirmCelebrationCallSiteTests`).

None of them can show that a real Confirm, through the real overlay, actually sets the celebration
off, what it looks like over the app, or that it leaves nothing behind. These frames do.

## What the frames settle that the tests cannot

1. **A real Confirm sets it off, through `.onChange`, on the real clock** (`00`, `01`).
   - Two cards are waiting.
   - `confirmCompletion` on the front card at t0: the glow swells, rain enters at the top, both
     cannons fire from the bottom corners, and the card leaves to reveal the older one.
   - About 1.1 s later (light; 1.3 s dark) the second card is confirmed while the first burst is
     still in the air. Its cannons fire, the two bursts OVERLAP, and one glow carries on (R1).
   - The confetti falls over the card, the disc and the tab bar, and every tap target stays
     reachable (`allowsHitTesting(false)`; the tab bar and disc are untouched in every frame).
2. **It leaves nothing behind.** Every frame from t5.41 on in light (the second burst ends about
   t5.3), and from t5.46 on in dark (about t5.5), is **pixel-identical, 0 of 1,339,344 pixels
   different**, to a window over the same service that never mounted the celebration. So the
   bursts are pruned and the layer draws nothing once the confetti has landed. (No frame can show
   that `TimelineView` stopped asking for frames. The call-site test pins the `if !bursts.isEmpty`
   gate that ensures it.)
3. **Ordinal 1 is exactly the prototype E chose from.** The probe re-ran the prototype's generator
   with its seeds 1 and 2 and compared it with `ConfettiRecipe.everyConfirm(ordinal: 1)`: **all 220
   pieces identical, field for field** (`parity: true`). The last piece lands at 4.12 s, inside the
   4.2 s burst; 161 of 220 pieces are rectangles.
4. **Both appearances** (`10`, `11`): the tokens resolve to their dark variants, and the glow reads
   as a soft green wash in light and a deeper one in dark (R6).

## Artefacts of the harness, not the app

- **Live timestamps are ordering evidence, not timing.** Each 2× capture costs roughly 0.2 s, so
  frames are about 0.37 s apart, and the second Confirm lands on a capture boundary.
- **`10` / `11` are the production `ConfirmCelebrationFrame` at an INJECTED time**, 24 frames a second
  over the settled scene (both cards already gone). The video plays at real speed, but it is not a
  measurement of real-time performance: that is E's phone.
- There is no Today content behind the furniture: the page is the bare background.

## Files

| file | what it proves |
|---|---|
| `00-live-confirm-light-sheet.jpeg` | Light, real clock: two waiting cards → Confirm → glow, rain and cannons, the card leaving → a second Confirm overlapping the first → everything landed and gone by t5.68. |
| `01-live-confirm-dark-sheet.jpeg` | The same, dark. |
| `10-every-confirm-t1.21-light-dark.jpeg` | One instant of the production frame, light beside dark: the rain and the cannons meeting mid-screen over the glow. |
| `11-every-confirm-light-dark.mp4` | The production frame at real speed, 4.5 s, light beside dark — at the ORIGINAL 4.2 s length. |
| `12-every-confirm-light-dark-5.4s.mp4` | **After E's "extend the animation length by 1.2 seconds":** the same frame at real speed, 5.7 s, light beside dark. The choreography is stretched evenly over 5.4 s; same pieces, paths and beats. This is what ships. |
| `40-…` | *Pending: E's device verdict.* |

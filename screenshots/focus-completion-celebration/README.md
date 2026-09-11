# F-FocusCard-4 — the completion celebration

**Environment.** iPhone 17 Pro simulator (iOS 26.5), rendered at 393pt wide / 3x from the unit-test
host on branch `feature/focus-card-4`, 2026-09-11. **No backend, no account, no sign-in** — these are
`UIGraphicsImageRenderer` captures (`drawHierarchy(afterScreenUpdates: true)`) of the real
`FocusCompletionCard` with `celebrates: true`, hosted in a `UIHostingController` inside a
scene-attached `UIWindow` over `Color.pageBackground`, driven by one literal `CompletedFocusSession`.
The run loop was pumped between captures and each file's `tNN` is the elapsed time since the window
was made key, measured with `CACurrentMediaTime`. No throwaway data was created and nothing was
written to Firestore. The probe that produced them (`ZZFocusCelebrationRenderProbe.swift`) was
deleted before the block's commit.

## Why this folder exists

**A unit test cannot see an animation.** The design record says so and says the evidence for this
block is this folder, not the test: a test over `withAnimation(.easeOut(...))` is near-vacuous. What
the tests DO hold is the pose the celebration opens in (`FocusCompletionCelebrationTests`), which
card is told to play (`FocusCompletionCelebrationServiceTests`), and that the cue and the haptic are
wired where they must be (`FocusCompletionCelebrationCallSiteTests`). Everything below is what those
three cannot assert — that the burst actually happens, what it looks like, and that the card comes to
rest as the card E approved in block 2.

This is the fourth `View`-level fact in this arc that only a render could settle (block 1's
`layoutPriority` compression, block 2's, block 3's `.regularMaterial` ghosting), and the first that
is motion rather than layout.

## What the frames settle that the tests cannot

1. **The burst plays, in two beats, from the ring's own edge.** `01`/`06`: the checkmark has landed
   and a second ring — the completed ring's own stroke — is radiating outward at roughly 1.25× while
   fading. `02`/`07`: ~1.45×, fainter. `03`: ~1.55×, almost gone. `04`/`08`: gone. It reads as the
   ring itself radiating, not as a second shape appearing, because it starts at scale 1 in the same
   stroke and colour (`FocusCompletionCelebrationMetrics.burstScaleStart = 1`).
2. **It ends on the card E approved.** `04` and `08` are pixel-for-pixel the block-2 completion card
   — green ring, green tick, nothing else. `FocusCompletionCelebrationPose.settled` is asserted to
   draw only the checkmark; this is what that assertion looks like.
3. **The pre-beat is an EMPTY ring, and that is deliberate.** `00`/`05` are the armed pose: the ring
   is complete but the tick has not arrived yet. On device the card slides up on the overlay's 0.35s
   spring; the tick and the halo wait `delay = 0.3s` so they land on a card that has stopped moving,
   rather than popping mid-slide. For that 0.3s the ring reads "done, not yet ticked" — a beat before
   the tick, not a missing tick. **Worth E's eye on device:** if the empty beat reads as a glitch
   rather than anticipation, the lever is `delay`, and the tick could be decoupled from it.
4. **Reduce Motion opens on the FINAL state.** `09` is the first frame (t=0.05) of a celebration told
   to play under Reduce Motion: full tick, no halo. Not the armed pose the record names as the trap.
   (`accessibilityReduceMotion` is not writable through `.environment`, so this frame renders
   `FocusCompletionCelebration(plays: true, reduceMotion: true)` inside the ring directly; the
   card's pass-through of the flag is held by `testReduceMotionIsResolvedBeforeTheCelebrationIsBuilt`.)
5. **A card that did not just finish opens settled.** `10` is `celebrates: false` — the card a
   Confirm reveals or a relaunch restores — at its first frame: identical to `08`. Nothing replays.
6. **Both themes read.** The halo is a soft green wash in light and a brighter one in dark; neither
   overruns the card's 76pt height (44 × 1.6 = 70.4pt).

## Two things the frames show that are artefacts of the harness, not the app

- **The first ~0.4s is host lag, not the app's delay.** `onAppear` in the test host fires some
  hundreds of milliseconds after the window is made key, so the burst's motion begins nearer
  t≈0.55 than the 0.3 the metric names. The ORDER and the phases are the evidence; the absolute
  timestamps are not a measurement of the app's timing.
- **The `t0.13`/`t0.35`/`t0.50` light frames were byte-identical**, for the same reason — nothing had
  moved yet. Only one of them is kept.

## Files

| file | what it proves |
|---|---|
| `00-light-armed-t0.13.jpeg` | The armed pose, light: complete ring, no tick, halo coincident with the ring and invisible as such. The 0.3s pre-beat. |
| `01-light-tick-landed-halo-t0.65.jpeg` | The tick has sprung in and the halo is radiating at ~1.25×. Both beats are real. |
| `02-light-halo-fading-t0.85.jpeg` | ~1.45×, fainter — the long easeOut is seen to radiate, not blink. |
| `03-light-halo-almost-gone-t1.10.jpeg` | ~1.55×, nearly gone; the tick is at rest. |
| `04-light-settled-t1.60.jpeg` | **The resting card, and it is the block-2 card E approved.** |
| `05-dark-armed-t0.09.jpeg` | The armed pose, dark. |
| `06-dark-tick-landed-halo-t0.65.jpeg` | The landed tick and the halo in dark, where the green reads brightest. |
| `07-dark-halo-fading-t0.85.jpeg` | Fading, dark. |
| `08-dark-settled-t1.60.jpeg` | The resting card, dark. |
| `09-reduce-motion-first-frame-t0.05.jpeg` | **The Reduce Motion trap, absent:** the FIRST frame under Reduce Motion is the final state. |
| `10-revealed-card-first-frame-t0.05.jpeg` | A card that is not playing (revealed by Confirm / restored by relaunch) opens settled — identical to `08`. |

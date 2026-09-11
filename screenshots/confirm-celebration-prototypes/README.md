# The Confirm celebration — the throwaway prototypes E chose from

**These are PROTOTYPES, not the feature.** Nothing here is in the app. They were rendered so E
could choose by looking, and they are kept because four of the design's decisions were made by
looking at them (#5, #7, #8 in `handoff/SESSION-OPENER-confirm-celebration-design.md`, which holds
every number used here).

**Environment.** iPhone 17 Pro simulator (iOS 26.5, the machine's only runtime), 2026-09-11,
rendered from the unit-test host on `main` @ `91926c9`'s tree.
- **No backend, no account, no sign-in, nothing written anywhere.** The card is the real
  `RootBottomOverlay` over a real `FocusSessionService` built on an in-memory logger and store,
  raised with `pushUnconfirmedCompletion`.
- **Every frame was computed, not recorded.** A 393 × 852 pt window at 2×, with the celebration's
  time INJECTED at 24 frames per second (`drawHierarchy(afterScreenUpdates: true)` per frame), then
  encoded with ffmpeg at 24 fps. So the MP4s play at real speed, but they say nothing about
  real-time performance on a device.
- **The probe (`ZZConfettiPrototypeProbe.swift`) was never committed**: it ran from the test target
  and was moved out of the repo before any commit. The tree stayed clean throughout.

## What these can and cannot show

- **The card never leaves.** Confirm is never tapped in these renders: the celebration's clock is
  driven over a card sitting still. In the real feature the card is dismissed on the same tap, as it
  is today.
- **The capture disc (`+`) is the overlay's own**, unchanged.
- **Filmstrip labels are truncated by the harness** ("Every Confir", "Stack cleare"), and the stills
  are sampled from the same frames as the videos.
- **Video is new to `screenshots/`.** CLAUDE.md's "prefer JPEG" rule is about stills, and a still
  cannot show motion, which was the thing being chosen. The three MP4s are 5.8 MB of this folder's
  6.4 MB; the tree was 61 MB before it.

## The three rounds

1. **`00` / `01` — where the confetti comes from (#5).** Three rows at the same palette, glow and
   length: **A** bursts up from the Confirm button, **B** rains from the top edge and reaches the
   card at about t2.5, **C** fires from both bottom corners and crosses mid-screen by about t1.1.
   E answered **"B but also C"**.
2. **`10` / `11` — the combination, and the first fireworks (#7).** Top row: every Confirm, with
   rain and cannons together and the glow. Middle and bottom rows: the stack-clearing Confirm, the
   same confetti plus **5** single-colour fireworks, in light and dark. **What the frames showed,
   and what was said to E:** in light the thin spark rings read faintly against the confetti; in
   dark they pop. E answered **"B - more fireworks … and possibly, for light-mode display views, a
   background dim …"**.
3. **`20` / `21` — 14 fireworks in 9 colours, and two dim strengths (#8).** Four columns:
   - light with no dim;
   - light dimmed with `Scrim` at 55%, which goes flat grey and muddies the colours;
   - light dimmed at 85%, which reads like a night sky and is closest to dark;
   - dark.

   The 85% column is a second run of the same probe with only the dim's peak changed (its notes
   line: `220 confetti, 14 fireworks, last spark 4.79s, dim 0.85`). E answered **"A"**, i.e. 85%.

An intermediate 14-firework filmstrip rendered between rounds 2 and 3 was never shown to E, so it is
not here.

## Files

| file | what it proves |
|---|---|
| `00-confetti-styles-A-B-C-filmstrip.jpeg` | The three confetti sources E compared, 8 frames each from t0.00 to t3.50, light. |
| `01-confetti-styles-A-B-C.mp4` | The same three at real speed, 4 s. **The video E answered "B but also C" to.** |
| `10-every-confirm-and-five-fireworks-filmstrip.jpeg` | Every Confirm (rain + cannons + glow) above the stack-clearing Confirm with 5 fireworks, light and dark, t0.00 to t3.75. Light's faint spark rings are visible. |
| `11-every-confirm-and-five-fireworks.mp4` | The same at real speed, 5 s. **The video E answered "B - more fireworks …" to.** |
| `20-stack-cleared-14-fireworks-dim-filmstrip.jpeg` | The stack-clearing Confirm with 14 fireworks: light no dim / 55% / 85% / dark, t0.42 to t4.58. At t4.58 the dims are still fading out. |
| `21-stack-cleared-14-fireworks-dim.mp4` | The same at real speed, 6 s. **The video E answered "A" (85%) to.** |

# F-ModernIOS-2-Celebration — the celebration's three motion modes

**Environment.** iPhone 17 Pro simulator (iOS 26.5, the machine's only runtime), rendered at 3x
from the unit-test host on branch `feature/modern-ios-celebration`, 2026-09-11. **No backend, no
account, no sign-in.** Every frame is a `UIGraphicsImageRenderer` capture
(`drawHierarchy(afterScreenUpdates: true)`) of a `UIHostingController` in a `UIWindow` attached to
the test host's scene, in a synchronous test that pumps `RunLoop.main` between captures. Each `tN.NN`
is `CACurrentMediaTime` since the window was made key. The probe (`ZZFocusCelebrationRenderProbe.swift`)
was deleted before the block's commit. **Nothing was written to Firestore:** the in-situ renders drive
a `FocusSessionService` built on an in-memory logger and store.

Two compositions:
- **The leaf row** (`00`–`21`): four `ClosureRing`s side by side, each holding
  `FocusCompletionCelebration(plays:motion:)` injected with one mode — `.full` | `.reduced` |
  `.modern` | not playing. The strips are those cells cropped UNSCALED from the raw frames and laid
  in a row, with the timestamp drawn above each; `02`–`04` are raw frames, untouched.
- **In situ** (`30`–`34`): the real `RootBottomOverlay` over the real service, with
  `pushUnconfirmedCompletion` called directly, so the card, stack and overlay are the shipped ones.
  On the 26.5 simulator with Reduce Motion off the card resolves `.modern`. The grids are crops of
  the raw frames around the card.

## Verified paths (CLAUDE.md §7.3)

> **26 path (`.modern`):** run on sim (leaf + in situ, both themes in the leaf) — E's phone with
> Reduce Motion OFF pending. **Reduced (`.reduced`):** run on sim by injection — leaf via
> `init(plays:motion:)`, in situ via a one-run temporary edit (below) — E's phone with Reduce Motion
> ON pending, and that verdict closes the block. **16 path (`.full`):** code run on 26.5 by injection,
> leaf only; its SELECTION on an iOS 16–25 OS is COMPILE-ONLY — no older runtime is installed.

Nobody here can say "works on iOS 16" yet, and nothing in this folder does.

## Why this folder exists

A unit test cannot see an animation. The tests hold which mode a card resolves to
(`FocusCompletionCelebrationMotionTests`), the pose each mode opens in and ends on
(`FocusCompletionCelebrationTests`), and that the view carries both branches in order
(`FocusCelebrationModernPathCallSiteTests`). Everything below is what those cannot assert: what each
mode looks like, when its beats land, and what happens inside the real card.

## What the frames settle that the tests cannot

1. **`.full` is block 4's burst, phase for phase** (`00`, `01`). An empty complete ring until the
   0.3s delay has passed (t0.09–0.42), then the tick springs in as the halo leaves the ring's edge
   (t0.51–0.59), radiates and fades (to ~t1.24), and settles by t1.33. Compared with
   `screenshots/focus-completion-celebration/` by PHASE AND ORDER, not by pixel: block 4 rendered
   the whole card, and this is the leaf in a ring, so the compositions differ.
2. **`.reduced` moves nothing and still celebrates** (`10`, `11`). The halo sits at its end scale
   from the first frame and only fades; the tick appears at full size and only fades in, on the same
   0.3s delay. No frame shows a scale change on either.
3. **`.modern` draws the tick on, and — the plan's named risk — the stroke does NOT wait for the
   0.3s delay** (`20`, `21`). A dot at t0.09, a stroke by t0.25, a complete tick by t0.42: the draw
   starts the moment the tick is inserted and takes about 0.3s, on the symbol effect's own clock.
   The halo still waits, and starts ~t0.51, so the two beats come apart: tick first, then halo. In
   situ (`30`) the draw is already under way while the card is still arriving (t0.76) and complete
   as it lands (t0.88). **So on a phone with Reduce Motion off the tick draws during the slide-up**,
   which is the collision block 4's delay was added to prevent. Shipped as rendered, per the plan
   ("evidence it, don't fight it"). The lever, if E wants it: land `.modern` after the delay rather
   than inside it.
4. **Every mode ends on the card E approved.** `03` / `04` are the last frames: the three playing
   cells against the not-playing cell differ on **at most 3 of 108,000 pixels per cell, by 1/255**
   (dark `.full`: 0). That is compositing noise, not a visible difference, and it is the claim —
   not "pixel-identical".
5. **No stray draw-on, no draw-off** (`31`, `32`). A second completion over an unconfirmed one: the
   NEW front card draws its tick (correct — it just finished) while the old card cross-fades out
   with its tick whole. Confirm on the front card: the revealed older card arrives with its tick
   ALREADY complete, and the leaving card keeps its tick. The insertion-only transition holds on
   both rebuilds.
6. **The reduced halo at 1.6, inside the real card — E's lever, and the thing to look at first**
   (`33`, `34`). At its pinned end scale the halo's stroke scales too (4pt → 6.4pt), and measured off
   `34`:
   - its outer diameter is **77.3pt against the card's 76.0pt**, so it overhangs the card's top and
     bottom border by ~0.7pt each and meets the left border (15.3pt against 16pt);
   - its right edge is at **92.3pt, and the summary column (emoji and "25m") starts at 85.0pt**, so it
     runs ~7pt behind the start of the text;
   - it holds at 80% opacity for the 0.3s delay (plus host lag here) before it starts to fade.

   The plan pinned 1.6 because at 1 the halo sits exactly on the ring and fading it shows nothing
   (block 4's frame `00`). The check for a smaller pin: **≤ 1.25 clears the text column** (right edge
   83.8pt) and stays inside the card; 1.3 touches the text. Block 4's `01` shows roughly what ~1.25
   looks like at strength. Not changed here; E decides on device.

## How `33` / `34` were made, and what they cannot show

`accessibilityReduceMotion` cannot be injected through `.environment(\.)`, so the reduced path is
unreachable in situ by construction. For ONE probe run, `FocusCompletionCelebration.init(plays:reduceMotion:)`
passed `reduceMotion: true` to `resolve`, on a committed tree; the file was restored with
`git checkout -- "ADHD LifeOS/"` straight after, and the restore was proved by the three red-check
builds and the final green suite that followed. **The overlay still had Reduce Motion OFF, so the
card SLIDES in here (t0.76).** On E's phone under Reduce Motion the card cuts in, and the bold halo
of `34` is the first frame E sees.

## Artefacts of the harness, not the app

- **Absolute timestamps are ordering evidence, not timing.** `onAppear` fires late in the test host,
  and each capture costs tens of milliseconds.
- **The in-situ grids start at the push**, with the capture disc above the card; the disc is the
  overlay's, unchanged.

## Files

| file | what it proves |
|---|---|
| `00-full-light-strip.jpeg` | `.full`, light: empty ring through the delay → tick springs in with the halo → settled. Block 4's phases. |
| `01-full-dark-strip.jpeg` | The same, dark. |
| `02-all-modes-light-mid-t0.67.jpeg` | Raw frame, all four cells at one instant: `.full` and `.modern` halo leaving the ring, `.reduced` halo fading at 1.6 with a faint tick, not-playing at rest. |
| `03-all-modes-light-end-t2.42.jpeg` | Raw last frame, light: every mode at rest on the approved card (≤3 px per cell differ by 1/255). |
| `04-all-modes-dark-end-t2.39.jpeg` | Raw last frame, dark. |
| `10-reduced-light-strip.jpeg` | `.reduced`, light: halo pinned at 1.6 and tick pinned at 1 on every frame; only opacity travels. |
| `11-reduced-dark-strip.jpeg` | The same, dark. |
| `20-modern-light-strip.jpeg` | `.modern`, light: the stroke draws on from t0.09 and is complete by t0.42 — **before** the halo starts. The delay is not honoured. |
| `21-modern-dark-strip.jpeg` | The same, dark. |
| `30-in-situ-modern-push.jpeg` | The real overlay: the card arrives with the draw-on already under way, lands with the tick complete, then the halo radiates and settles. |
| `31-in-situ-modern-second-push.jpeg` | A second completion over an unconfirmed one: only the new card draws; the older card keeps its whole tick as it goes behind. |
| `32-in-situ-modern-confirm-reveals-older.jpeg` | Confirm: the revealed older card arrives with its tick already drawn — no stray draw-on — and the leaving card keeps its tick — no draw-off. |
| `33-in-situ-reduced-injected.jpeg` | **Reduced, in the real card** (one-run injection): the 1.6 halo at strength on the card's edges and behind the text, then the tick fading in as the halo fades out. |
| `34-in-situ-reduced-injected-opening-t1.01.jpeg` | **The headline frame for E's lever:** the reduced opening, raw — the frame measured above. |
| `40-…` / `50-…` | *Pending: E's device verdicts, Reduce Motion ON (closes the block) then OFF.* |

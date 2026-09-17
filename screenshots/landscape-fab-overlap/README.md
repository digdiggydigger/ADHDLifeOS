# The landscape FAB overlap — F-LandscapeFabOverlap (2026-09-17)

**Environment:** `iPhone 17 Pro` simulators on **iOS 26.5 (23F77), light** and **iOS 27.0 (24A434),
dark** — E's phone runs 27.0. Built with Xcode 27.0 (27A266a) against the iOS 27.0 SDK, deployment
target 16.0, branch `feature/landscape-fab-overlap` @ `11224c9`. Backend: the Firebase Emulator
Suite, signed in as a throwaway `uitest-landscapeaway-*` account created per run. The BEFORE frames
come from the same build with `RootBottomOverlay.swift` reverted to `main`'s (`a8636ee`) for the
red-check. Captured 2026-09-17.

**Why this folder exists.** `LandscapeAwayCardUITests` asserts the geometry — the disc clear of the
gear, the gear hittable and opening Settings, the card clear of the disc — and it fails on the
old overlay and passes on the new one. What no assertion can settle is how the new arrangement
READS: E has never seen the bottom furniture laid out side by side, and whether a card at the
bottom-left with the disc in its own corner looks right in the hand is E's call, made by looking.
The frames below are that arrangement on both runtimes and in both modes.

**How the frames were taken, and why not by the test.** `app.screenshot()` lies on a rotated
simulator (F-LandscapeFix): the attachment comes back letterboxed portrait with the content
squeezed into a column and half the frame black. These are host-side `xcrun simctl io <udid>
screenshot` frames, polled once a second while the journey held each pose for three seconds
(`hold()` in the test). The test still attaches its own frames as the record that each pose was
reached; none of them is in this folder.

**No throwaway data survives.** Each run's account lived only in the emulator process, and both
simulators were erased (`xcrun simctl erase`) in the same command as their run — the standing
rule that a signed-in simulator poisons the next unit suite.

## The measurements, from the journey's own frame prints

Printed on the pass path and the fail path alike (the geometry-journey lesson), `iPhone 17 Pro`,
402 × 874 pt portrait / 874 × 402 pt landscape:

| | disc | gear | away card |
|---|---|---|---|
| portrait, before and after (identical) | y 475–535 | y 78–118 | y 543–740 |
| **landscape, BEFORE** | **y 17–77** | y 16–56 | y 85–282, x 78–796 (full width) |
| **landscape, AFTER** | **y 222–282** (its resting position) | y 16–56 | y 85–282, x 78–696 (the column beside the disc) |

Before: the disc's top at 17.3 is the sum the pure test holds — 381 (the landscape safe height)
− 100 (the lift) − 196.7 (the card) − 8 − 60. The gear at y 16–56 is under it. After: the disc
sits 166pt below the gear, the card ends 100pt short of the trailing edge, and the tap on the gear
opens Settings (frames 04 and 06).

## Files

| file | what it proves |
|---|---|
| `00-before-portrait-control.jpeg` | Portrait with the away card up, OLD overlay: disc above the card, gear clear. The control the journey asserts before rotating — portrait never collided. |
| `01-before-landscape-disc-on-gear-sim-26.5.jpeg` | **The bug, reproduced on the simulator with the old overlay.** Landscape, the capture disc sitting on the Settings gear (the well's edge shows behind the disc). The same frame E photographed on the phone (`ios27-device-findings/04`). |
| `02-after-portrait-unchanged-light-26.5.jpeg` | Portrait with the NEW overlay: byte-for-byte the stack E reviewed — the frames above are identical before and after. |
| `03-after-landscape-cards-beside-disc-light-26.5.jpeg` | **The fix, light, 26.5.** Landscape: the away card takes the column at the bottom-left, the disc keeps its resting corner, the gear is clear. |
| `04-after-landscape-gear-opens-settings-light-26.5.jpeg` | The gear tapped in that state opens Settings — the thing E could not do. |
| `05-after-landscape-cards-beside-disc-dark-27.0.jpeg` | **The fix, dark, 27.0** — E's runtime. Same arrangement. |
| `06-after-landscape-gear-opens-settings-dark-27.0.jpeg` | Settings opened from the gear on 27.0, dark — with iOS 27's retuned sheet chrome, as Phase D recorded. |

## Open, for E on the phone

1. Does the side-by-side arrangement read right in the hand — the card bottom-left, the disc in
   its corner? (A running sprint's timer bar takes the same column in landscape; the disc no
   longer rises above it there.)
2. Portrait is unchanged; nothing to look at, but the claim is on the table.

---

## Device look, 2026-09-17 03:44 — E's six frames (iPhone 15 Pro, iOS 27.0, `main` @ `5c322e5`)

E installed the fix and sent six frames from the phone (`IMG_8503`–`8508` in E's own folder). Two
things in them, and only the first was expected.

**The landscape arrangement, on the phone (07, 08).** 07 is the fix as built: the away card takes
the column bottom-left, the disc keeps its corner, the gear is clear. 08 is portrait with the card
up — unchanged, and it shows something the fix did not touch and this folder should record: with
the card pushing the disc up, the disc floats over the Best Next Move card's *Start another session*
button. That is the pre-existing "the disc floats over content" behaviour at a pushed-up height;
`captureDiscClearance` clears only the bottom of the scroll. Noted as an observation, not a
finding — E has not raised it. **E has not yet given a verdict word on 07.**

**NEW FINDING — the sprint cards sit ABOVE the capture fan (09–12).** With a card up, opening the
fan draws the card crisp on top of the fan's dimmed scrim, and the fan's tiles land where the card
is. 09/10: the LIVE Confirm card ("30s focused · 2 checkpoints · Confirm") in landscape, dark and
light, above the scrim with the tile row butting its bottom edge. 11: the away card, same. 12:
**portrait — the away card hides the LINK and TASK tiles entirely**, so two of the five capture
kinds cannot be tapped while an away card is waiting. Two causes, both read from the code, not
the frames:

- **z-order.** `RootView` applies `.blur` and the fan overlay to the tab content, then mounts
  `RootBottomOverlay` as a later `.overlay` — deliberately, so the disc (which becomes the fan's ×)
  stays crisp and tappable. The cards came along with it: everything in the bottom overlay is
  above the scrim, un-dimmed.
- **anchoring.** `CaptureFanOverlay` places each tile at `(width − fromTrailing, height −
  fromBottom)` — fixed offsets from the screen's bottom-trailing corner, i.e. the disc's RESTING
  position. When a card pushes the disc up (portrait), the × moves and the arc does not, so the
  arc leans out of empty space and its lower tiles sit under the card. In landscape the disc no
  longer moves (this block), but the horizontal arc runs along the bottom exactly where the
  side-by-side column now is.

Recorded in the register (§B) with the options; **not fixed here** — it is a design call E has not
yet made.

| file | what it shows |
|---|---|
| `07-device-landscape-cards-beside-disc-light-27.0.jpeg` | The fix on E's phone: card bottom-left, disc in its corner, gear clear. |
| `08-device-portrait-away-card-disc-over-hero-buttons.jpeg` | Portrait, unchanged; the pushed-up disc floats over the hero's buttons (observation). |
| `09-device-landscape-fan-open-confirm-card-above-scrim-dark.jpeg` | Fan open, landscape, DARK: the Confirm card crisp above the scrim, tiles under its edge. |
| `10-device-landscape-fan-open-confirm-card-above-scrim-light.jpeg` | Same, LIGHT. |
| `11-device-landscape-fan-open-away-card-above-scrim.jpeg` | Fan open, landscape: the away card above the scrim. |
| `12-device-portrait-fan-open-away-card-hides-link-and-task.jpeg` | **Fan open, portrait: LINK and TASK hidden behind the away card — unreachable.** |

---

## `F-FanCardsFade` — E's call on the finding above, built the same day (2026-09-17)

E: *"Fade the cards out while the fan's open."* While the fan is open the cards column fades by
opacity and stops taking touches, keeping its layout so the × stays exactly where the + was.
Frames are the journey's own `app.screenshot()` — portrait, where it is truthful — on the
`iPhone 17 Pro` simulator, iOS 26.5, light, the same emulator account shape as above, sim erased
after. The journey printed the geometry: TASK (314, 602) and LINK (301, 524) inside the card's
frame (16, 543–740), the disc at (318, 475) before AND after the fan opened.

| file | what it proves |
|---|---|
| `13-fanfade-portrait-card-up-fan-closed-26.5.jpeg` | The control: away card up, fan closed, Got it tappable. |
| `14-fanfade-portrait-fan-open-card-faded-tiles-free-26.5.jpeg` | **The fix.** Fan open over the same state: the card is gone from view, LINK and TASK are on top of nothing, the × has not moved. On the unfixed tree the same journey failed here with TASK un-hittable — E's frame 12. |
| `15-fanfade-portrait-fan-closed-card-back-26.5.jpeg` | Dismissed by the ×: the card is back and Got it tappable again. |

**Owed to E:** the fade on the phone with Reduce Motion OFF, then ON — this block adds a reduced
site. The arc still leans out of the resting corner (not re-anchored; see the register).

---

## Device looks, 2026-09-17 05:44 — E's five frames (iPhone 15 Pro, iOS 27.0, `main` @ `9eb5198`)

E ran one 30-second sprint ("celebration sound testing") and sent five frames (`IMG_8515`,
`8517`, `8518`, `8520`, `8521`). Measured from the frames at 3 px per point: landscape is
852 × 393pt, portrait 393 × 852pt. **The one finding is in 19, and it corrects the register:** the
× does not only land on PHOTO, and not only with the away card.

**Landscape (16, 17): the side-by-side arrangement, on the phone, with a running sprint.** The
expanded sprint card takes x 76–677, y 126–273. The disc sits at x 709–769, y 213–273, so its
bottom lines up with the card's. The collapsed bar is at y 246–305 and sits on the tab bar
(y 306), which is the bar's flush drop. The disc stays in its corner. In 16 the disc is in its
translucent scroll pill, not a fault. **E has sent the frames but no verdict word yet.**

**Landscape, fan open (18): the fade works.** The timer bar is gone and the five tiles are clear.
The tile centres match the table exactly: TASK is at (586, 316), from `793 − 207` and `372 − 57`.
The × is at (739, 243), 153pt right of TASK and 73pt above it. Nothing overlaps.

**Portrait, fan open (19): the fade works, but THE × COVERS TASK.** The timer bar is gone. The ×'s
centre is at (339, 620) and TASK's is at (336, 611), 9pt apart, so the nearest and most-used tile
is almost completely hidden. The ×'s resting centre (frame 20) is (339, 688), so the collapsed bar
pushed it up 68pt. TASK sits 77pt above the resting centre (`818 − 207 = 611`). **The tiles are
78pt apart, so any push lands the × within about 39pt of SOME tile. Which one depends on the
card's height.** Arithmetic on the 15 Pro, from the same table:

| what is up | push | × centre | nearest tile(s) |
|---|---|---|---|
| collapsed timer bar (measured, 19) | 68pt | (339, 620) | **TASK**, 9pt |
| expanded sprint card, 148pt | 156pt | (339, 532) | **LINK** (323, 533), ~16pt |
| away card, 186pt | 194pt | (339, 494) | between **PHOTO** (318, 455) ~44pt and **LINK** ~42pt |

A tile is 62pt wide and the × is 60pt, so any gap under about 61pt means they overlap. **So frame
14's "× on PHOTO" was one instance of a general collision.** Leaving it as it is means TASK is
covered whenever a collapsed sprint bar is up in portrait.

**The sprint ended while the fan was open (20).** Two things happened at once:
- **The × dropped 68pt to its resting corner**, because the timer bar left the column. That is the
  × moving under the thumb, the cost of shape B in the register, and it already happens today
  whenever the card set changes with the fan open. (With shape A, the arc would have to move with
  the × or stay where it was when the fan opened.)
- **A celebration (fireworks and confetti) played OVER the open fan**, dimming the tiles and the
  ×, with the in-app "Sprint complete" banner above it. This is the current code working as
  written: `F-CTACelebrations-Surfaces` holds a celebration behind an unknown sheet, alert or
  system picker, and the fan is an overlay in the view tree, so nothing tells the celebrations
  it is open. An observation for E, not a finding.

Reduce Motion's state in these frames is unknown. Stills cannot show a fade, so the fan-fade look
(OFF then ON) still needs E's word.

| file | what it shows |
|---|---|
| `16-device-landscape-sprint-card-beside-disc-27.0.jpeg` | Landscape, expanded sprint card bottom-left, disc in its corner (in its scroll pill), bottoms aligned. |
| `17-device-landscape-sprint-bar-collapsed-beside-disc-27.0.jpeg` | Landscape, collapsed bar on the tab bar, disc beside it. |
| `18-device-landscape-fan-open-timer-bar-faded-27.0.jpeg` | Landscape, fan open: the timer bar faded, tiles clear, no overlap. |
| `19-device-portrait-fan-open-x-covers-task-27.0.jpeg` | **Portrait, fan open with a sprint running: the bar faded, but the × hides TASK (centres 9pt apart).** |
| `20-device-portrait-sprint-ends-fan-open-celebration-x-drops-27.0.jpeg` | The sprint ended with the fan open: a celebration over the fan, and the × dropped 68pt to its corner. |

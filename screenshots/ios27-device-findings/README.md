# iOS 27 device findings — Phase F step 2

**Environment:** E's physical iPhone 15 Pro (`wishwashwacky15`, iPhone16,1) on **iOS 27.0 (24A437)**,
running `main @ 560d068` (`LifeOS 1.3 (1)`, `DTSDKName iphoneos27.0`). Firebase production, E's own
account, over 4G. Captured by E on **2026-09-16**, measured the same evening.

**Why this folder exists.** Phase D's sweep compared 26.5 against 27.0 *in the simulator*. These are
the first looks at the retuned chrome on a physical display, and they caught **two things a test
could not**: a spacing asymmetry E noticed by eye, and a landscape layout collision that only occurs
with a specific card on screen. Neither is assertable — the first is a judgement about how a filled
shape reads against an edge, the second needs a real rotation with real content height.

**No throwaway data was created.** Everything shown is E's live account as it stood after the
restore; the nudges and the sprint are real records, not fixtures.

## The measurements, so a later session need not re-derive them

Taken from the originals at native 1179×2556 (3×), by sampling pixel rows rather than by eye.

**Tab bar, selected pill inset** (files 02 / 03) — measured at the capsule's widest row:

| | light | dark |
|---|---|---|
| bar's left edge → bubble's left edge | **9 px = 3.00 pt** | **8 px = 2.67 pt** |
| last glyph → bar's right edge | 47 px = **15.7 pt** | 47 px = **15.7 pt** |

A **~5× asymmetry**. The constants behind it are in `Theme/AppTabBarPresentation.swift`:
`floatingPaddingHorizontal = 4` (the card's inner padding) and `pillPaddingHorizontal = 16`.
**4 is on §2's grid, so this is not a grid violation** — it is that 4pt was chosen when the
selection was an icon-only chip that never reached its slot edge, and Design C's resting pill is a
filled capsule that does. It will mirror on the right when **Tools** is selected.

**FAB overlap in landscape** (file 04): the capture disc renders at **y 48–226 px on the 1180 px-tall
landscape frame — y 16–75 pt on the 393 pt screen** (the frame is 3×; the first edition of this
line called the pixel values points) — against the top edge, on top of the Settings gear.
Diagnosed and fixed in `F-LandscapeFabOverlap` (2026-09-17): the stack was not overflowing the
screen, it was FILLING it — see `screenshots/landscape-fab-overlap/`.

## Files

| file | what it proves |
|---|---|
| `00-sheet-chrome-light.jpeg` | The "New nudge" sheet, LIGHT. Baseline for the pair. |
| `01-sheet-chrome-dark.jpeg` | Same sheet, DARK. **Confirms Phase D's prediction on a real display**: the toolbar Cancel/Save are lighter and edged on 27.0, content inside unchanged. System behaviour, not a defect — an input to the held colour arc. |
| `02-tab-bubble-inset-light.jpeg` | The selected pill nearly flush with the bar's left edge, LIGHT. The mode where the white bar makes the gap easiest to see. |
| `03-tab-bubble-inset-dark-circled.jpeg` | Same in DARK, **with E's own red circle** round the area of concern. This is the provenance of the finding — E spotted it, the measurement came after. |
| `04-fab-overlap-landscape.jpeg` | **The bug.** Landscape, with an unacknowledged `OfflineSprintSummaryCard` on screen: the capture disc sits on top of the Settings gear, leaving the gear unreachable. Rotated upright from E's screen recording; the original GIF (123 frames, 15 MB) is in E's own screenshot folder, deliberately not committed. |

## The FAB overlap's suspected cause — a hypothesis, NOT a verified diagnosis

`RootBottomOverlay.swift` puts the away card, the capture disc and the timer bar in **one shared
`VStack`**, by design, so that *"an active sprint PUSHES the disc up"* (its own comment). That is
correct in portrait. In landscape there is only 1180 pt of height and `OfflineSprintSummaryCard` is
tall, so the push appears not to stop at the header and carries the disc into it.

**The trigger is the COMBINATION** — landscape *plus* an unacknowledged away card. Neither alone
reproduces it in these frames. **Confirm this by reading the code before fixing it**; it was
inferred from five sampled frames plus one grep, and no test was run against it.

# F-JournalPencilDisc — the pencil disc, the kept nav bar, and the re-tap (2026-09-18)

**Environment:** the rig from `screenshots/journal-pencil-step0/` and `journal-door-unpinned/`.
- **What was rendered:** the REAL `JournalView` (its own `NavigationStack`), the real `AppTabBar` as a
  bottom `safeAreaInset`, the real `CaptureFanOverlay` and the real `RootBottomOverlay` as a `.bottom`
  overlay — `RootView`'s own order. Fake journal data (14 entries over five days); a real
  `FocusSessionService` started for the sprint frames. No backend, no account, nothing signed in.
- **How:** a `UIHostingController` in a key `UIWindow` inside the unit-test host, drawn with
  `drawHierarchy` at 3×. **Portrait:** 393 × 852pt pinned to the BOTTOM of the 17 Pro's screen, so
  the bottom inset is E's real **34pt** (top inset 40, not a 15 Pro's 59 — header only). **Landscape:
  the test host's scene was really rotated** (`requestGeometryUpdate(.landscapeRight)`), so those
  frames are the 17 Pro's true 874 × 402pt with its real 62 / 62 / 20 safe areas.
- **Runtimes:** `iPhone 17 Pro` simulator, **iOS 27.0 first** (E's OS; the numbered frames) and
  **26.5** (sheets 17 and 18). Xcode 27.0. Branch `feature/journal-pencil-disc` @ `0b91ab6`.

The variants came from a THROWAWAY probe test (`ZZPencilDiscRenderProbeTests`), deleted before this
folder was committed. No production file was edited to render.

## Why this folder exists

E chose every part of this block by looking at Step 0's renders, but had NOT seen the final
combination: **the reversed gradient WITH the glow**, a sprint card up, landscape, or the fan open
(`TODO-CLAUDE-CODE.md`, `F-JournalPencilDisc`). Tests hold the values and the wiring; only a render
shows how the twins READ, and whether the disc lands on anything E has not decided. It does not:
nothing lands on a card, a tile or the gear.

## The gate — measured by pixels, identical on 27.0 and 26.5, light and dark

Edges found by strong saturation (max − min channel > 120), which skips the white glyph and the halo:

| frame | + disc | pencil disc | gap |
|---|---|---|---|
| at rest | 60 × 60, centre **696.0** (x 309–369) | 42 × 42, centre **696.0** (x 251–293) | **16.0** |
| sprint card up | centre 540.0 (pushed up by the card) | centre 540.0 | 16.0 |
| after the re-tap | centre 696.0 | centre 696.0 | 16.0 |

- The constants predict the + disc's centre at 852 − 34 − (24 + 68) − 30 = **696.0**. Block 1 measured
  696.5 with a looser threshold. **The + disc did not move.**
- The pencil is exactly E's 42, on the +'s line, 16pt to its left, by construction (same `HStack`).
- **The re-tap, from the probe's own reading** of the `UINavigationBar` and the scroll view: scrolled
  420pt → bar **54pt**, offset 304; re-tapped → bar **106pt**, offset **−168**, the expanded top. The
  large title comes back on both runtimes. (Without the fix it settles at 54 / −116 — Step 0's bug,
  and the committed `JournalLargeTitleReTapTests` RED.)

## E's device look — PASSED, 2026-09-18 (frames 19–24)

**Environment:** E's iPhone (393 × 852pt at 3×), **iOS 27.0**, the `654012f` install (blocks 1 + 2
of the Journal-door arc together), live Firebase, E's own account and real journal. Taken by E
at 21:26–21:27 BST. Nothing was created for the look, so nothing needed cleaning up.

**E's verdicts, the option labels verbatim:**
- **Reduce Motion OFF:** the disc beside the +, the nav bar with the eye, the re-tap bringing the
  large title back, and the 24pt gap in portrait and landscape: **"All passed"**.
- **Reduce Motion ON:** the fan's cards fade, the pencil fades in and out on a tab switch, and the
  re-tap: **"All faded, passed"**.
- **Landscape: fan → Note, does the composer open?** **"Composer opened"**. So
  `testRenderLandscapeSweep`'s failure at that step is the TEST's fault, not the app's (register).

**Measured on the device frames**, by the same saturation threshold as the gate above. JPEG edges
trim about 0.3pt off each side of a disc, so a raw gap reads about 0.6pt wide.

| frame | + disc | pencil disc | gap | disc → bar |
|---|---|---|---|---|
| 19, portrait at rest | 60 × 60, centre **(339.0, 696.0)** | 42 × 42, centre **(272.0, 696.0)** | 16 | bottom 725.7 → bar keyline 751.0 ≈ **24** |
| 23, landscape at rest | 60 × 60, centre (739.0, 251.0) | 42 × 42, centre (672.0, 250.8) | 16 | bottom 280.7 → bar keyline 305.0 ≈ **24** |

**The device matches the sim gate to the point:** the + disc's centre is at 696.0 on the phone, as
the constants predict and both runtimes rendered. The pencil spans the same x (251–293) as it
did on the sim. `gapAboveTabBar = 24` holds in BOTH orientations.

| file | what it proves |
|---|---|
| `19-device-rest-eye-off.jpg` | Portrait at rest on the phone: the large "Journal", with the eye ALONE top right, OFF in the label colour. The pencil disc sits beside the + at the numbers above. |
| `20-device-rest-eye-on.jpg` | **The eye ON, rendered for the first time since Step 0** (the sim frames did not re-render it): accent glyph, and the hidden rows ("Routine offered … not opened") now showing. |
| `21-device-scrolled-pill-eye-off.jpg` | Scrolled: the inline title, the + a pill at 0.68, and the pencil at 0.68 with it (E's "Follows the pill"). The tab bar's selected item drops its label while floating, which is shipped Design C behaviour (`AppTabBarPresentation.showsLabel`), unchanged here. |
| `22-device-scrolled-pill-eye-on.jpg` | The same, with the eye ON. |
| `23-device-landscape-rest.jpg` | Landscape at rest: the inline title (compact height), the eye top right, and the pencil beside the + on its line. The 24pt gap above the bar. |
| `24-device-landscape-scrolled-pill.jpg` | Landscape scrolled: both discs pilled together. |

**What frames 19–24 do NOT show:** motion. The re-tap, the Reduce Motion ON fades and the 24pt
gap under a Confirm card were judged live on the phone. E's verdicts above cover them; no frame
here does.

## What the frames show

| file | what it proves |
|---|---|
| `00-final-disc-zoom-27.jpg` | **The final disc, first time rendered:** the + disc's two colours with the gradient REVERSED (accent top, CaptureDeep bottom; the + runs the other way), the same halo, white glyph. At rest and pilled, light and dark. |
| `01-rest-light-27.jpg`, `02-rest-dark-27.jpg` | The kept nav bar: large "Journal", the eye ALONE top right in the system's glass circle (OFF, label colour — E's B). The summary line first under the title. The pencil disc beside the +. |
| `03-…-pill-light`, `04-…-pill-dark` | Scrolled: inline title, the + a pill at 0.68, the pencil at 0.68 with it (E's "Follows the pill"), its halo shrunk with the +'s. Size stays 42. |
| `05-sprint-light`, `06-sprint-dark` | **A sprint card up (not seen by E before).** The row rides above the card exactly as the + always has; the pencil sits beside the +, not on the card. |
| `07-fan-open-light`, `08-fan-open-dark` | **The fan open (not seen before).** The pencil fades out and stops taking touches with the cards (decision 6); the × is at its resting corner; no tile sits where the pencil was. |
| `09-retap-scrolled-light` → `10-retap-after-light`, `11-…-dark` | **The re-tap:** scrolled (bar 54), then `coordinator.reselect(.journal)` → the large title back (bar 106, offset −168). |
| `12`/`13-landscape-rest` | **Landscape (not seen before):** compact height gives the inline title; the eye top right; the pencil beside the + in its corner. |
| `14`/`15-landscape-sprint` | Landscape with a sprint card: the cards take the column BESIDE the disc row (`F-LandscapeFabOverlap`); the row is 58pt wider on the Journal (16 + 42), so the column is 58pt narrower and ends before the pencil. The card still fits. |
| `16-landscape-fan-open-dark` | Landscape fan: the tiles run left along the bottom; the pencil is hidden, and no tile reaches its spot. |
| `17-portrait-sheet-26.5.jpg`, `18-landscape-sheet-26.5.jpg` | The same frames on 26.5. Every measurement above is identical. |

## Verified paths (§7.3)

- **Re-tap:** 26 path run on sim 26.5 + 27.0 (the committed hosted test and these frames) + E's
  phone (iOS 27.0, RM off): "All passed". 16 path is the shipped `proxy.scrollTo`, unchanged;
  OS-level COMPILE-ONLY, since no runtime below 26.5 is installed.
- **Reduced paths:** the re-tap's reduced branch: run on sim (injected), via
  `TabRootLargeTitleReTap.restore(_:reduceMotion: true)` in the hosted test (106pt at −168 on the
  next layout pass), + E's phone (RM on). The pencil's appear/leave fade and its fan fade are a
  plain-ease fade in code. A still frame cannot show a transition, and the setting cannot be
  injected into the environment, so their evidence is **E's phone (RM on) only**. The capture fan's
  cards fading under RM were covered by the same pass. **E toggled Reduce Motion ON for that check
  and answered "All faded, passed"** (2026-09-18).

## What these frames do NOT show

- **Motion:** the appear/leave fade on a tab switch, the pill curves, the fan fade and the re-tap's
  scroll are all motion. E's device look covers them, with Reduce Motion OFF and then ON.
- **Only default Dynamic Type.** The large-title band grows with Dynamic Type, which is why the
  re-tap FINDS the expanded top instead of hard-coding it (`TabRootReTapPlanTests` holds a
  larger band).
- **The eye ON** was not re-rendered: E saw B's ON state in Step 0 (`journal-pencil-step0/00`), and
  the code is B's.
- The top inset is 40, not a 15 Pro's 59, so the title sits ~19pt higher than on E's phone. The
  bottom furniture is at E's real 34pt inset and is exact.

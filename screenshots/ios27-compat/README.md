# iOS 27 compatibility sweep — Phase D, iOS 26.5 vs iOS 27.0 (the same build)

Driven on **two `iPhone 17 Pro` simulators — iOS 26.5 (23F77) and iOS 27.0 (24A434) — running the
SAME binary**: built once with Xcode 27.0 (27A266a) against the iOS 27.0 SDK, deployment target
16.0, `main` @ `e68d0e5` plus the harness below. Backend: the Firebase Emulator Suite (fresh
instance), signed in as a throwaway `uitest-ios27sweep-*` account created per run. 2026-09-15.

**What this folder answers.** E's question of 2026-09-14: *"look for any clashes between the design
of the UI of the top version iOS 26 compared to the new top level which is iOS 27."* Every
documented iOS 27 change is SDK-gated and the research found nothing about safe areas, Reduce
Motion or the tab bar, so what remained was to LOOK — and with both runtimes installed the look is
a measurement: the same thirteen surfaces photographed on each runtime, in light and in dark, laid
side by side, with the changed-pixel fraction per frame and per band.

**Mechanism, and why it is the harness rather than the bridge.** The frames come from
`ADHD LifeOSUITests/IOS27CompatSweepUITests.swift`, driven once per `OS=` destination and per
appearance (four runs, each simulator **erased** afterwards, `127.0.0.1:9099` hits **0** on all
four). The Xcode MCP bridge's `RenderPreview` was tried first and is NOT the source of any image
here, for two reasons now established rather than assumed: **the preview canvas chooses its own
device and ignores the scheme's run destination** (the scheme was switched to `iPhone 17 Pro (26.5)`
and confirmed active; the preview launched on `iPhone 18 Pro`, iOS 27.0), so it cannot produce a
26.5 render at all; and both attempts on 27.0 failed on launch timeouts (`AppLaunchTimeoutError`,
then `CHSErrorDomain 1051 timelineReloadTimeout` for the widget extension). The harness photographs
the real app on a real runtime, which is the stronger evidence anyway.

**Throwaway data.** Four emulator accounts (`uitest-ios27sweep-<hex>@example.test`), each with one
seeded task, one capture and one nudge, living only in the emulator process; every simulator was
erased at the end of its run (`xcrun simctl erase`, in the same command as the test). Nothing
touched the live project: the harness sets `LIFEOS_FIREBASE_EMULATOR_HOST` through
`launchEnvironment`, the only route the app has to the emulator.

## What driving the real screens caught that no test could

1. **The custom tab bar is pixel-identical on iOS 27.** `AppTabBar` sits above the safe area with
   its own background, and `AppTabContent` parks hidden tabs 10,000 pt off screen — the audit's
   highest-risk surface. The bottom band (search row, capture disc and bar) measures **0.00 %
   changed on every one of the ten plain-tab frames**, light and dark. Nothing moved by a pixel.
2. **iOS 27 changes SHEET CHROME, not sheet content.** On 27.0 a sheet's bottom corners are
   rounded and inset from the screen edge, and the sheet carries a thin dark edge — visible on all
   four sheets photographed (promote, Settings, New nudge at both detents), and the whole of their
   0.4–1.7 % deltas outside the status bar. `zoom-07-sheet-bottom-corner-light.jpg` shows it at
   2×. The app's content inside every sheet is unchanged. This is the "retuned glass" the research
   described from secondary sources, seen first-hand: **an iOS-27-SDK binary does receive it.**
3. **Glass capsule buttons are retuned, and dark mode shows it.** Cancel and Save on the New nudge
   sheet render as barely-there tints on 26.5 and as lighter, edged capsules on 27.0
   (`zoom-11-sheet-toolbar-capsules-dark.jpg`). In light the diff outlines only their edges
   (Done on Settings, Cancel on the promote sheet). These are system controls, so they match the
   rest of iOS 27 — a design input for the held colour arc, not a defect.
4. **`confirmationDialog` is a POPOVER on both runtimes, and it has no Cancel button.** The delete
   confirmation (`AccountDeletionSection`) anchors to its row on 26.5 and on 27.0 alike; only the
   placement differs (26.5 to the row's right, 27.0 above it, arrow down). Neither runtime puts a
   `Cancel` element in the tree — the harness's first run failed on exactly that and now dismisses
   by tapping outside. The 8–17 % deltas on frame 09 are the popover's position, not the sheet.
5. **The bottom search row is unchanged; the input surface underneath it is not.** Frame 01's
   bottom band is 0.00 %. On frame 02 the search field and Cancel are identical; the 5 % (light)
   and 15 % (dark) are iOS 27's first-run **QuickPath tip pane** standing where the keyboard is
   on 26.5, and the empty state re-centring ~2 pt over the taller surface. The precedent that
   built the bottom-search arc (iOS 26 moving `.searchable`) did not repeat.
6. **The status bar accounts for ~2.3 % of every pair**: the clock reads a different minute on
   every 26.5/27.0 pair, and nothing else in that band moves. The per-band table below is why the
   headline percentages are not the number to read.
7. **One text delta in 52 frames, and it is not claimed as a finding.** The summary line under the
   schedule presets (frame 11, dark) averages (139,140,144) on 26.5 and (98,101,108) on 27.0
   against the same background. It is `Color.secondary` footnote text that also carries an opacity
   transition, and the 27.0 run was the slowest of the four, so a mid-fade capture is the likelier
   cause. Flagged for the Phase F device look rather than filed as a change.

## What this sweep does NOT cover, and where that is owed

- **Widgets and Live Activities.** No UI test can reach them, and the bridge could not render
  them this session (above). Their five shared files ran under the unit suite on the 27.0 runtime
  (3,011/0), which proves they compile and their logic holds, not how they look. **Owed to
  Phase F**: E's phone on iOS 27 with the Focus Live Activity running.
- **The `connectedScenes → keyWindow` walks** (`KeyWindowPresentationProbe` and three siblings)
  have no visual: their proof is `CelebrationProbeSwiftUISheetTests` — sheet, cover, alert AND
  `confirmationDialog` — green on the 27.0 runtime, plus frame 09 here, which is the exact
  composition (a dialog over a sheet) that iOS 27's trait-inheritance change would reach first.
- **Reduce Motion.** Nothing in this sweep animates at capture time; §7.2 is untouched by iOS 27
  per the research, and no `#available` site was added or changed, so **no "Verified paths" line
  is owed** by this block.

## Measurement — changed pixels, 26.5 vs 27.0, per band

Per-channel delta > 24/255. Bands are the status bar (top 60 pt), the content, and the bottom
113 pt holding the search row, disc and tab bar. Method: `compare.py` in this folder (run it over the full-size PNG frames from the result bundles). Composites: `side-by-side/<surface>-<mode>-26v27.jpg`
(26.5 | 27.0 | diff heat).

| surface | light: all / status / content / bottom | dark: all / status / content / bottom |
|---|---|---|
| 00-today | 0.16 / 2.35 / **0.00** / **0.00** | 0.16 / 2.32 / **0.00** / **0.00** |
| 01-tasks | 0.18 / 2.34 / 0.02 / **0.00** | 0.55 / 2.32 / 0.49 / **0.00** |
| 02-tasks-search-open | 4.89 / 2.34 / 2.97 / 18.12 | 14.53 / 2.32 / 11.23 / 41.43 |
| 03-areas | 0.17 / 2.43 / **0.00** / **0.00** | 0.16 / 2.32 / **0.00** / **0.00** |
| 04-journal | 0.21 / 2.48 / 0.05 / **0.00** | 0.19 / 2.32 / 0.04 / **0.00** |
| 05-tools | 0.17 / 2.48 / **0.00** / **0.00** | 0.17 / 2.45 / **0.00** / **0.00** |
| 06-captures | 0.17 / 2.48 / **0.00** / **0.00** | 0.17 / 2.45 / **0.00** / **0.00** |
| 07-promote-sheet | 0.67 / 2.39 / 0.46 / 1.01 | 1.25 / 2.45 / 1.28 / 0.43 |
| 08-settings-sheet | 0.68 / 2.39 / 0.02 / 3.86 | 0.43 / 2.37 / 0.13 / 1.28 |
| 09-delete-account-dialog | 7.91 / 2.16 / 7.52 / 13.35 | 17.27 / 2.41 / 15.75 / 34.57 |
| 10-nudges | 0.18 / 2.33 / 0.02 / **0.00** | 0.19 / 2.38 / 0.03 / **0.00** |
| 11-new-nudge-medium | 0.55 / 2.30 / 0.38 / 0.70 | 1.71 / 2.39 / 1.92 / 0.07 |
| 12-new-nudge-large | 0.23 / 2.30 / 0.09 / **0.00** | 0.33 / 2.39 / 0.21 / **0.00** |

The 01-tasks dark content figure (0.49 %) is the task rows' keylines: the same retuned edge as
finding 3, on the app's own bento cards. Look at `01-tasks-dark-26v27.jpg` before reading it as
anything more.

## Files

`frames/` holds the 52 raw frames as half-size JPEG, named `<NN>-<surface>-<os>-<mode>.jpg`
(iPhone 17 Pro, 1206×2622 at capture, 603×1311 here). `side-by-side/` holds the 26 composites and
two zooms. One row per surface; each row stands for its four frames and two composites.

| # | surface (files) | what it proves |
|---|---|---|
| 00 | `00-today-*` | Today at launch: header, ring, Best Next Move, life-area grid, FAB and the **tab bar** — content and bottom band 0.00 % in both modes. |
| 01 | `01-tasks-*` | Tasks with the **bottom search row** beside the disc: row and bar 0.00 %; dark shows the card keyline retune (0.49 %). |
| 02 | `02-tasks-search-open-*` | The search field open: field and Cancel identical; the delta is iOS 27's QuickPath tip pane where 26.5 shows the keyboard. |
| 03 | `03-areas-*` | Areas grid under the bar: 0.00 % / 0.00 %. |
| 04 | `04-journal-*` | Journal under the bar: 0.00 % bottom band, both modes. |
| 05 | `05-tools-*` | Tools (the sixth tab, the reason the bar is custom): 0.00 % / 0.00 %. |
| 06 | `06-captures-*` | Captures with a seeded note on the decision card: 0.00 % / 0.00 %. |
| 07 | `07-promote-sheet-*`, `zoom-07-sheet-bottom-corner-light.jpg` | `CapturePromoteSheet` (`[.medium, .large]`, inline title, own `CelebrationLayer`): content identical; **27.0 rounds the sheet's bottom corners and adds a dark edge**. |
| 08 | `08-settings-sheet-*` | The Settings `.sheet` over Today: content 0.02 % light; the Done capsule's edge and the sheet's bottom corners are the delta. |
| 09 | `09-delete-account-dialog-*` | `confirmationDialog` over the Settings sheet — the dialog-over-sheet composition: **a popover on both runtimes**, placed differently, no Cancel in either tree. |
| 10 | `10-nudges-*` | The nudges screen's inline toolbar (leading back, trailing add): 0.02–0.03 % content, 0.00 % bottom. |
| 11 | `11-new-nudge-medium-*`, `zoom-11-sheet-toolbar-capsules-dark.jpg` | The New nudge sheet at `.medium` (`NudgesView:300`, the selection-bound detent): content identical; **dark-mode Cancel/Save capsules are lighter and edged on 27.0**; the summary line's opacity noted above. |
| 12 | `12-new-nudge-large-*` | The same sheet grown to `.large` by Custom, day row open: 0.09–0.21 % content, 0.00 % bottom. |

## Proven here vs elsewhere

- **This folder:** the thirteen surfaces above, on a real 26.5 and a real 27.0 runtime, both
  appearances, same binary.
- **Unit suite on the 27.0 runtime (register, Phase C):** 3,011/0 including the presentation-probe
  tests and `AppTabContentHiddenTabsTests` — the off-screen parking constant and the probe's four
  presentation kinds.
- **Not yet proven anywhere:** how widgets and Live Activities look on iOS 27, and the retuned
  glass on a physical display. Both are Phase F.

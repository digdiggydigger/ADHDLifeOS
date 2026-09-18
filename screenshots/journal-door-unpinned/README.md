# F-JournalDoorUnpinned — the Journal before and after, at rest and scrolled to the end (2026-09-18)

**Environment:** the REAL `JournalView` — its own `NavigationStack`, header, chips and timeline —
with the real `AppTabBar` as a bottom `safeAreaInset` and the real `RootBottomOverlay` as a
`.bottom` overlay, the order `RootView` composes them in. Hosted in a `UIHostingController` in a
real key `UIWindow` inside the unit-test host and drawn with `drawHierarchy(in:afterScreenUpdates:)`
at **3×, 393 × 852pt (E's iPhone 15 Pro)**, on the `iPhone 17 Pro` simulator, iOS **26.5**, Xcode
27.0. Both appearances via `overrideUserInterfaceStyle`. A fake journal client (eight entries over
six days, one sprint, one capture) — no backend, no account, no signed-in session.
**Before** = `main` @ `8a8b96e`; **after** = `feature/journal-door` @ `d1b3601`. No production file
was edited for either render.

## Why this folder exists

E chose option 04 from `screenshots/journal-door-options/` — *nothing pinned; the header pencil is
the door*. The tests prove the bar is gone and the clearance is called (source-level, see below);
only a render shows what the screen now LOOKS like and that the last entry really clears the disc.

## The rig differs from the options folder's, deliberately — and it moves one of its numbers

The options folder's hosted window carried **no** 34pt home-indicator inset (its README says so).
This one carries E's phone's real bottom inset: the simulator's screen is a 402 × 874 iPhone 17
Pro, so a 393 × 852 window at the TOP of it inherits only 12 of the 34pt, and the first render of
this rig showed exactly that (disc centre 718.5). The window is pinned to the screen's BOTTOM
instead, which gives **bottom 34.0** — E's phone — and top 62.0 (a 15 Pro is 59; 3pt, header only).

**Gate 3 — the frame reproduces the shipped geometry, not an approximation of it.** With the 34pt
inset, the constants predict every edge that matters, and the frames land on them:

| edge | predicted from the constants | measured |
|---|---|---|
| disc centre | 852 − 34 − (24 gap + 68 bar) − 30 = **696.0** | **696.5** light / 695.5 dark |
| bar's hairline (before) | 852 − 34 − 68 − 96.3 (the bar: 8 + 54 + 4 + 26.3 caption + 4) = **653.7** | **653.7** |
| last entry's bottom (after, scrolled to end) | 852 − 34 − 160 `bottomClearance` − 16 padding = **642** | **640.7** + 1pt border |

**A number this folder corrects, recorded rather than smoothed over.** The docs carried "the disc's
centre sits ~5.5pt BELOW the composer field's centre" as a device figure. It is DERIVED: the
2026-09-03 device measurement (composer 700.5, disc 698 at gap 32) plus the 8pt of
`F-FurnitureGap24`. The current constants give **7.3** (field centre 688.7, disc 696.0) and this rig
measures **8.0**; the options rig's 6.0 matched the derived figure at a different inset. The
field is deleted by this block, so the offset no longer exists to be right or wrong about.

## What E's choice bought, in numbers — at E's phone's inset

| | before | after | |
|---|---|---|---|
| content visible at rest, down to | **653.7** (the bar's hairline) | **750.0** (the tab bar's top) | **+96pt** |
| reserved band (scroll reach) | 96.3 bar + 68 tab = **164pt** | `.captureDiscClearance()` = **160pt** | −4pt |

**Read the two rows separately.** +96pt is what the eye gets at rest — the stream now runs behind
the disc to the tab bar instead of stopping at a hairline. The reserve barely moves, so this is a
**look-and-feel win, not a scroll-reach win**. The options README measured +107pt; that rig had no
home-indicator inset, and the bar is 96.3pt tall, so +96 is the number on E's phone.

## What each frame shows

| file | what it proves |
|---|---|
| `00-before-rest-light.jpg`, `01-before-rest-dark.jpg` | The baseline: the pinned bar, its two-line caption, the 40pt header circles. |
| `02-after-rest-light.jpg`, `03-after-rest-dark.jpg` | The bar is gone; the stream runs down to the tab bar under the disc; both header circles are 44pt. |
| `04-before-scrolled-to-end-light.jpg`, `06-…-dark.jpg` | The last entry resting above the bar (card bottom 628.3, hairline 653.7). |
| `05-after-scrolled-to-end-light.jpg`, `07-…-dark.jpg` | **The clearance working:** the last entry ends at 640.7, 25.8pt above the disc's top (666.5) — without `.captureDiscClearance()` it would rest under the disc with nothing below it to scroll to. |

## What the frames do NOT show

- **Persistence.** Scrolled, there is no door on screen at all — the pencil is the first child of the
  `LazyVStack` and the nav bar is hidden. That is `F-JournalPencilReachable`, rendered separately in
  `screenshots/journal-pencil-options/` for E to choose; it was never this block's to fix.
- **Loading and error states** also lose the bar's bottom inset, so their centred spinner / message
  now centre on the full height — lower by half the 164pt the bar reserved, ~82pt by arithmetic
  (NOT rendered). Expected, not a regression: they were centred on a height that subtracted a bar
  they never showed.
- **Portrait, default Dynamic Type only; 26.5, not E's 27.0.**

## How the probe was made, and why it is not committed

A throwaway `JournalDoorRenderProbeTests` in the unit-test target, copied in for each render and
deleted after; `git status` was empty before this folder was added. Measurements are pixel scans of
the 3× PNGs (disc: the accent run down x = 339pt; hairlines and card edges: runs down x = 30 and
x = 200pt). JPEG here per `screenshots/`'s rule; nothing in this folder is sampled for colour.

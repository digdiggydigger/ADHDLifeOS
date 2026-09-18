# The Journal's new-entry pencil — three shapes and three treatments for E to pick by eye (2026-09-18)

**Environment:** the REAL `JournalView` (its own `NavigationStack`), the real `AppTabBar` and the
real `RootBottomOverlay`, composed as `RootView` composes them, hosted in a key `UIWindow` and drawn
with `drawHierarchy` at **3×, 393 × 852pt (E's iPhone 15 Pro) with E's real 34pt home-indicator
inset** — the rig `screenshots/journal-door-unpinned/README.md` documents and gates. `iPhone 17 Pro`
simulator, iOS **26.5** (E's phone is on 27.0), Xcode 27.0, `main` @ `6656866` (block 1 merged).
Both appearances. Fake journal data; no backend, no account.

## Why this folder exists

E, 2026-09-17: *"making the current new journal entry icon (in the top-right-hand corner of the
screen) MORE visable and EASIER to interact with."* After `F-JournalDoorUnpinned` the pencil is the
Journal's only door — and it scrolls away with the header, because the header is the first child of
the `LazyVStack` and the nav bar is hidden. **Once scrolled there is no door on screen at all**
(column 1, bottom row). So this is about PERSISTENCE first; styling cannot help an icon that is
off-screen. `F-JournalPencilReachable` is `[BLOCKED]` on E's choice. No test can make it.

## The sheets

`00-sheet-shapes-light.jpg` / `01-sheet-shapes-dark.jpg` — four columns, at rest (top) and scrolled
420pt (bottom). Columns (a)–(c) all wear the ACCENT-GLYPH treatment, so shape is the only variable.
`02-sheet-pencil-treatments.jpg` — the three treatments on the header circle, light and dark.

| shape | what it is | the pencil once scrolled | viewport it costs | target |
|---|---|---|---|---|
| **today** (block 1) | header scrolls away | **gone** | 0 | 44 (block 1) |
| **(a) pin the header** | the whole header stays, under the app's pinned-surface treatment (bar material + hairline) | top right, where it is now | **85pt, permanently** — the band's hairline sits at y 147, the status bar ends at 62 | 44 |
| **(b) restore a nav bar** | system large title at rest; collapses to an inline title with the eye + pencil in a toolbar capsule | top right, in the toolbar | the inline bar — but on iOS 26/27 content **fades** under it (no hard edge), so it reads lighter than (a) | system (≥ 44) |
| **(c) the disc's band** | a 48pt pencil circle, 16pt left of the + disc, centred on its line; the header keeps only the eye | bottom right, beside the + | **0** — it sits in the 160pt band every screen already reserves | 48 |

## What each shape would owe, beyond the look

- **(a)** gives back ~85 of the 96pt E's option 04 just freed — at the top instead of the bottom. That
  is the complaint E removed the bar for (*"reduces viewing space"*). No motion, no OS gating.
- **(b)** reverses `JournalView.swift:120` (`.toolbar(.hidden, for: .navigationBar)`). The Journal
  would be the only one of the four title-drawing tabs (Today, Areas, Tools, Journal) on the system
  bar. The bar looks different below iOS 26 (classic bar, plain glyphs) — system-drawn, so no
  `#available` to write, but a "Verified paths" line would be owed (§7.3). The header's summary line
  moves under the title (visible in 11/12).
- **(c)** is new furniture in `RootBottomOverlay`, shown on the Journal tab only (the overlay already
  knows the tab — `searchScope`). It **spends the band `F-Search-3-Journal` would need**; it needs a
  landscape answer (compact height puts the sprint cards in the column beside the disc row); and it
  appears/disappears on a tab switch, which is a transition — so **a Reduce Motion ON device pass
  would be owed** (§7.3). Two circles at the bottom (write vs capture): the 48pt card-surface circle
  against the 60pt accent disc keeps the + primary.

**What the frames do NOT show:** (c)'s circle is drawn by the probe, not by app code — it exists
nowhere yet, so it is a proposal at real metrics (`CaptureDiscMetrics`, `AppSearchRowMetrics`), not a
render of a shipped view. (a) and (b) are the real `JournalView` with temporary edits. Portrait,
default Dynamic Type, 26.5 only.

## Treatments (`02`)

**Quiet** is today's (grey glyph, card circle). **Accent glyph** is the smallest change that makes it
read as a control, not chrome. **Filled accent** is loudest — but in shape (c) it would put a second
blue disc beside the +, competing with it; in (a)/(b) it does not.

## The recommendation, for E to overrule

**(c) with the accent glyph.** It is the only shape that is persistent AND costs no viewing space —
the reason E removed the bar — and it lands in the thumb's reach rather than the top corner. (b) is
the runner-up: the most platform-native, and on E's phone the soft edge makes its cost small; its
price is being the one tab on the system bar. (a) is honest but spends the space option 04 bought.

## Files

| file | what it shows |
|---|---|
| `00-sheet-shapes-light.jpg`, `01-sheet-shapes-dark.jpg` | The comparison: today, (a), (b), (c) × at rest / scrolled. |
| `02-sheet-pencil-treatments.jpg` | Quiet / accent glyph / filled accent, header circle, light + dark. |
| `03`–`06` `0-shipped-*` | Block 1 as merged: the pencil at rest, and **no door** once scrolled. |
| `07`–`10` `a-pinned-header-*` | The header pinned: identical at rest, still there scrolled; the 85pt band. |
| `11`–`14` `b-nav-bar-*` | Large title at rest; inline title + toolbar capsule scrolled, content fading under it. |
| `15`–`18` `c-disc-band-*` | The pencil beside the +, in both states; the header keeps only the eye. |

## How the probe was made, and why it is not committed

Temporary edits to `JournalView.swift` and `JournalTimelineSections.swift` — two `static var`
switches (shape 0–3, treatment 0–2) read at body time, so all twenty frames came from ONE build — and
a throwaway `JournalPencilRenderProbeTests`. All reverted with `git checkout --`; `git status` was
empty and `grep probeShape` returned 0 before this folder was added. Shape 0 renders pixel-identical
positions to block 1's shipped frames (disc 696.5 / 695.5 in both), which is the check that the
switches changed nothing when off.

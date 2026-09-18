# The Journal's "One line about today…" door — five options for E to pick by eye (2026-09-18)

**Environment:** the REAL Journal screen — the real `timeline(logs:)`, the real `composerBar`, the
real `AppTabBar`, the real `RootBottomOverlay` and the real `AppSearchRow`, composed in the order
`RootView.swift:204-236` composes them — hosted in a real key `UIWindow` and drawn with
`drawHierarchy(in:afterScreenUpdates:)` at **3×, 393 × 852pt (E's iPhone 15 Pro)**, on the
`iPhone 17 Pro` simulator, iOS **26.5**, Xcode 27.0, `main` @ `c54efd7`. Both appearances via
`overrideUserInterfaceStyle`. No backend, no account, no signed-in session.

**Same caveat the pill-inset folder carries:** rendered on the 26.5 runtime while E's phone is on
27.0, and at 15 Pro dimensions on a 17 Pro device. Not re-derived here.

## Why this folder exists

E, 2026-09-17: the bar *"currently gets in the way and aesthetically unattractive and reduces
viewing space on the Journal page"*, and asked for alternative designs or a recommendation to
remove it. Asked whether the ugliness was the **bar** or the shared `composerFooterSurface()`
treatment it wears, E answered **the bar — its bulk and position**, so the fix stays inside the
Journal tab and the shared footer treatment is untouched. Asked how to choose, E answered
**"render them first, then I'll choose"**. No test can make this judgement.

## The two facts that reframed the request

- **The pinning was never E's design.** E's own v3 mockup
  (`handoff/ADHD LifeOS - Momentum - v3.dc.html:204`) has this bar as the **last child of the
  scrolling screen** (`padding:24px 20px 40px`). Height 54, radius 14, hairline and the caption all
  shipped faithfully; the **pinning was added in implementation**. Option 03 is therefore closer to
  the original design than what ships today.
- **The caption wraps on every iPhone.** *"Entries are append-only. Energy and mood are asked once,
  on save."* measures **355.6pt** at `.caption2` (SF 11pt, CoreText) against an available width of
  `screen − 16 − CaptureDiscMetrics.clearance(92)` = **267pt (SE) / 285pt (15 Pro) / 322pt (Pro
  Max)**. So it is **two lines, always** — 26pt, not 13 — and `LogComposerView.swift:295` already
  states the same rule at the moment it applies. Visible in `00-current-*`.

**A correction recorded deliberately:** an earlier note in this session called the band "96 opaque
points". `composerFooterSurface()` is `.background(.bar)` — **blur material, not opaque**
(`ComposerChips.swift:188-203`). Content shows through it; the stream is still inset by it.

## The trust gate — why these frames can be believed

`ImageRenderer` **cannot** rasterize a `NavigationStack` (it returns SwiftUI's yellow "cannot
render" placeholder), and it renders `ScrollView` + `LazyVStack` **empty** — lazy containers only
materialise children in a real layout pass. Both failures produce a plausible-looking image, so the
probe carried three gates, and the first version of this probe **failed all of them**:

1. the centre pixel is not the yellow placeholder;
2. mid-screen is not flat page colour, i.e. the timeline actually drew;
3. **the frame reproduces the geometry measured on E's phone.** After `F-FurnitureGap24` the disc's
   centre sits ~5.5pt BELOW the composer field's centre. Measured on `00-current-light`:

   ```
   field centre 697.0    disc centre 703.0    offset 6.0pt      (device documents ~5.5)
   ```

   0.5pt from the device. The absolute positions sit ~3.5pt high because a hosted window has no
   34pt home-indicator safe area, but the RELATIVE geometry — the thing being judged — holds.

**A vacuous assertion caught in the act, worth more than the frames.** The first probe asserted only
`image.width == 393*3`, which **passed on the yellow placeholder**. That is
`geometry-journey-vacuity` exactly: a frame assertion passing on a broken render. Gate 1 replaced it.

## What each frame shows

Measured on the light frames by scanning the left gutter (x = 20pt) for the top of the pinned
furniture — i.e. how far down the page content is still visible at rest:

| # | option | content visible to | vs current | reserved band |
|---|---|---|---|---|
| 00 | **Current** | y = 705 | — | 96 (bar) + 68 (tab) = **164pt** |
| 01 | **Minus the caption** | y = 735 | **+30pt** | 66 + 68 = **134pt** |
| 02 | **Prompt in the capture disc's band** | y = 736 | **+31pt** | `.captureDiscClearance()` = **160pt** |
| 03 | **Inline row at the top of the stream** | y = 812 | **+107pt** | **160pt** |
| 04 | **Nothing pinned — pencil only** | y = 812 | **+107pt** | **160pt** |

**Read the two columns separately; they answer different questions.**
- *Content visible* is what the eye gets at rest. The bar's band becomes transparent, so the stream
  shows through instead of stopping at a hairline.
- *Reserved band* is scroll REACH, and it barely moves (164 → 160). **Options 02–04 are a
  look-and-feel win, not a scroll-reach win**, and an early draft of this folder overstated them by
  omitting the clearance. Every screen except Journal already reserves
  `.captureDiscClearance()` = 160pt, fully transparent; Journal is exempt **only because** the
  composer bar occupies that band (`CaptureDiscClearanceCallSiteTests.swift:31-35`). Remove the bar
  and Journal must join them, or the last row lands unreachable under the disc — which is why
  frames 02–04 carry that clearance.

| file | what it proves |
|---|---|
| `00-current-light/dark.jpg` | The baseline, and the caption wrapping to two lines. |
| `01-no-caption-light/dark.jpg` | The 5-line change: 30pt back, nothing else touched. |
| `02-prompt-in-disc-band-light/dark.jpg` | The real `AppSearchRow` carrying the journal prompt beside the disc. |
| `03-inline-row-light/dark.jpg` | The same door, unpinned, at the top of the stream — the v3 mockup's own shape. |
| `04-nothing-pinned-light/dark.jpg` | Nothing pinned; the header pencil is the only door. |

## What the frames do NOT show, and must be said

- **Frame 02's glyph is a magnifying glass** because it is the REAL `AppSearchRow`, unmodified — a
  hand-edited copy would be drift, which is the failure `show-dont-describe-geometry` warns about.
  Shipped, it would take `square.and.pencil` and drop `.accessibilityAddTraits(.isSearchField)`; a
  journal prompt is not a search. E is judging placement and bulk, which the real component gives.
- **Frame 04 is not a free win.** The header pencil scrolls away (it is the first child of the
  `LazyVStack`, `JournalTimelineSections.swift:25-27`) and the nav bar is hidden
  (`JournalView.swift:120`), so once scrolled there is NO door: writing a line becomes tab-re-tap
  then pencil. Both 40×40 circles (`JournalView.swift:202`, `JournalAllActivityButton.swift:24`)
  are also **under §3's 44pt floor** and would have to grow first.
- **Portrait, default Dynamic Type only.** At accessibility sizes the caption has no `lineLimit`
  and goes to 3–5 lines (against §1's layout-safety clause); in landscape the bottom furniture is
  ~40% of a 393pt-tall viewport and `JournalView` has no `verticalSizeClass` branch. Both are real
  and neither changes which option to pick.
- **Scroll reach cannot be shown in a still.** See the reserved-band column.

## How the probe was made, and why it is not committed

A throwaway `JournalDoorRenderProbeTests` plus four temporary edits — a probe init on `JournalView`
(`ImageRenderer` never runs `.task`, so the service is pre-loaded and injected), `composerBar` and
the door `Button` made internal, `static var` flags for the caption and the inline row, and a
probe-overridable `AppSearchScope.placeholder`. **All four reverted; `git status` empty before this
folder was added.** The production files are untouched — every pixel here is the shipping view.

**The mechanism is the reusable part:** `ImageRenderer` is enough for a leaf (it made
`tabbar-pill-inset-options`), but a whole screen needs `UIHostingController` in a key `UIWindow`,
a run-loop turn, then `drawHierarchy`. `RenderPreview` over the Xcode bridge was tried first and
failed as `xcode-mcp-bridge` predicts — it chose its own canvas device (`iPhone 18 Pro`) and timed
out launching in 15s on this 8 GB machine.

## Status

**Awaiting E's choice.** Nothing is built. Per `build-in-a-fresh-session`, whichever option E picks
becomes a FEATURE block in `TODO-CLAUDE-CODE.md` — with E's words, these measured numbers, and the
tests that must change (`AppTabBarCallSiteTests.swift:57-69`'s source-string pin on the
`safeAreaInset` line; `CaptureDiscClearanceCallSiteTests.swift:31-35`'s Journal exemption; the two
now-stale doc comments in `AppSearchScope.swift:88-95` and `AppSearchRowMetricsTests.swift:41-53`
that name this bar as the disc's alignment reference) — and is built in a fresh session.

**Removing the bar also dissolves a parked blocker:** `F-Search-3-Journal`
(`TODO-CLAUDE-CODE.md:2600-2625`, "⚠ RECONSIDER FIRST") is blocked *because* this element is a
field in that band. Option 02 spends the band deliberately instead.

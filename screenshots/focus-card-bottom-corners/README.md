# The collapsed card's bottom corners — the options E was shown

> ## ✅ ANSWERED 2026-09-13: **E chose 24pt — "match the top".**
>
> E's answer to the register's lower-priority question, 2026-09-11, was **"Round them"** — a
> direction, not a number. These renders are the number, and E picked from them by looking.
> One radius everywhere, so the collapsed card reads as a card rather than as a slab seated on the
> bar. **"Leave it square after all" was offered explicitly and was not chosen.**
>
> Shipped as `FocusBarMetrics.collapsedBottomCornerRadius`, spelled as `cornerRadius` rather than
> as a literal 24 — what E chose was *match the top*, so it follows the top if that ever moves.
> Pinned by `testTheCollapsedBottomRadiusIsTheValueEChoseByLooking`.

**The question these settle.** The collapsed focus card is dropped **flush onto the tab bar**
(`FocusBarMetrics.collapsedOffsetY`), and its square bottom corners were only ever correct
*because* it sits there — the design record is explicit that the two decisions are one shape:
told that top-only rounding 100pt above the screen bottom would leave the corners hanging in
mid-air, E chose *"Drop it flush to the tab bar"*. E has now reversed the corner half of that.
**How much** to round is a thing E settles by looking, so it is rendered rather than argued.

**Environment.** iPhone 17 Pro simulator (iOS 26.5), 393×852 at 3x — E's own device width —
rendered from the unit-test host on `feature/focus-card-corners`, 2026-09-13. **No backend, no
account, no sign-in.** `UIGraphicsImageRenderer` + `drawHierarchy(afterScreenUpdates: true)` over a
real `UIWindow` attached to the host's scene, hosting the REAL `FocusTimerBar` and the REAL
`AppTabBar` with one literal sprint. No throwaway data and nothing written to Firestore.

**The scene is the app's own, including its draw ORDER.** `RootView` mounts the bar as a
`.safeAreaInset` (`:203`) and `RootBottomOverlay` as an `.overlay` applied after it (`:229`), so
the card draws **above** the bar — which is what lets the page show through the notch a rounded
bottom corner leaves. The first pass of this probe had them the other way round and was re-rendered.

**How the variants were produced, and why nothing is committed as a variant.**
`FocusBarMetrics.collapsedBottomCornerRadius` is a `static let`, so the probe could not vary it
without a source edit: it is a `static var` for the duration of this render and goes back to `let`
**in the same commit that lands E's pick**, with the probe (`ZZCornerRenderProbe.swift`) deleted in
the same move. The tree was committed clean at `ecaa2c8` before the edit, per the standing
never-destroy-uncommitted-work rule.

## What the renders show

At 1x the difference is a couple of points of curve tucked against the bar — real, but a squint.
The zoom panel is what makes it a choice: at **0pt** the keyline runs straight down and stops dead;
from **8pt** it turns inward; by **24pt** it is a full quarter-circle and the page reads through the
notch between card and bar.

**The other half of the block, and E's choice resolved it in an unexpected way.**
`roundsBottomCorners` was a `Bool`, and a flag cannot tween — mid-spring the corners flipped from
square to round in a single frame while the card was still moving. The radius is a `CGFloat` wired
to `animatableData` now, so SwiftUI can walk it. **But E chose a collapsed radius equal to the
expanded one, so the two states no longer differ and nothing interpolates: the snap is gone because
the DIFFERENCE is gone, not because the animation is running.** The wiring stays as insurance — a
`Shape` with a continuous parameter should declare it — and the code says so rather than implying
a morph that does not happen.

| file | what it shows |
|---|---|
| `00-comparison-light.jpeg` | The four radii stacked, light, in full context — card, bar and page. |
| `01-corner-zoom-light.jpeg` | The bottom-LEFT corner alone at 4x, four radii side by side. **The panel to choose from.** |
| `light-r00.jpeg` | 0pt — what ships today. The square corner. |
| `light-r08.jpeg` | 8pt — the smallest rounding that reads as deliberate. |
| `light-r16.jpeg` | 16pt — two thirds of the top corners' radius. |
| `light-r24.jpeg` | 24pt — matches the top corners exactly (`FocusBarMetrics.cornerRadius`). |
| `dark-r00.jpeg` … `dark-r24.jpeg` | The same four in dark, where the keyline carries more of the shape. |

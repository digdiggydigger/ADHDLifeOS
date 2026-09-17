# The selected pill's inset — four options for E to pick by eye (2026-09-17)

**Environment:** the REAL `AppTabBar` — the same file, tokens and metrics the app draws — rendered
with `ImageRenderer` at 3× inside the unit-test host on the `iPhone 17 Pro` simulator, iOS 26.5,
Xcode 27.0, `main` @ `7e85ec6`. Rendered at **393pt wide, E's iPhone 15 Pro**, so the pill / slot
arithmetic is the phone's. Both appearances via the environment's colour scheme. No backend, no
account, nothing throwaway.

**Why this folder exists.** E circled the resting pill on the phone (`ios27-device-findings/03`):
the filled capsule sits 3pt from the bar's left edge against 15.7pt from the last glyph to the
right edge. `floatingPaddingHorizontal = 4` is ON §2's grid, so nothing is wrong to correct — 4 was
approved when the selection was an icon-only chip that never reached its slot edge, and Design C's
resting pill is a filled capsule that does. **E asked for rendered options, not a chosen number**,
the way `peekStep = 14` was chosen (CLAUDE.md §2). This is a judgement about how a filled shape
reads against an edge; no test can make it.

**How the renders were made, and why not the app on the simulator.** Four values of one constant
means four builds of the app, each a signed-in journey, on an 8 GB machine. Instead the constant was
made a `static var` in the working tree for the duration of ONE unit run, a temporary probe
(`TabBarInsetRenderProbeTests`, not committed) set it to 4 / 8 / 12 / 16 and rendered the bar with
Today selected and with Tools selected, light and dark — sixteen frames — and both the constant and
the probe were reverted (`git status` clean before this folder was added). The bar file itself was
never touched; every pixel is the production view.

## What the numbers mean

Measured on the rendered frames the way the device findings were measured — walking inward from
the card's edge on the row through the pill's middle until the fill changes:

| `floatingPaddingHorizontal` | pill inset from the card's edge | on §2's grid? | SE floor (§3) |
|---|---|---|---|
| **4** (current) | 4.3pt light / 4.0pt dark | yes | 47.8pt |
| **8** | 8.3 / 8.0 | yes | 45.4pt |
| **12** | 12.0 / 12.0 | **no** — would need a named waiver like `peekStep = 14` | 44.6pt |
| **16** | 16.0 / 16.0 | yes | **43.0pt — BELOW the 44pt floor** |

The SE floor is `AppTabBarPresentation.restingSlotWidth` on the 375pt iPhone SE:
(375 − 2·4 − 2·padding − 120) / 5. **16 fails `testRestingSlots_clearTheTouchTargetFloorBesideTheWidestPillOnTheSE`** as the
tree stands; choosing it means lowering `maximumRestingPillWidth` (120) by at least 5pt as well,
where the label's `minimumScaleFactor(0.8)` already absorbs the longest label. 12 keeps the floor by
0.6pt. The right-hand gap (glyph to edge) does not move with this constant — it is the unselected
slot's slack — so the asymmetry E circled closes by the pill moving in, not by the glyphs moving out.

The card's inner padding is the SAME constant in the scrolled state (the icon-only chip), so the
chosen value also insets the chip by that much when the bar is floating. At 4 the chip never reached
the edge, which is why nobody saw this until the pill did.

## Files

| file | what it shows |
|---|---|
| `00-sheet-today-light.png` | **The four options, Today selected, LIGHT** — the case E circled. Top to bottom: 4 (current), 8, 12, 16. Each row is the full 393pt bar. |
| `01-sheet-today-dark.png` | Same, DARK. |
| `02-sheet-tools-light.png` | Tools selected, LIGHT — the mirror case at the right edge. |
| `03-sheet-tools-dark.png` | Same, DARK. |
| `04-zoom-today-light.png` … `07-zoom-tools-dark.png` | The bar's end 2× enlarged, four rows each, so the inset can be compared without the rest of the bar. |

## For E

Pick one of 4 / 8 / 12 / 16 by looking at `00` and `01`. If 12, say so and it ships as a named
waiver with a pinning test, like `peekStep`. If 16, the pill cap comes down with it. Nothing else
on the bar is being re-tuned — every other constant is E-approved and stays.

---

## What shipped — E chose 12 (2026-09-17)

E, verbatim: *"regarding the pill inset I think that padding 12 is the right choice for now."*
Landed as `F-TabBarPillInset`: `floatingPaddingHorizontal` 4 → **12**, the SE floor test's expected
value 47.8 → 44.6 (still clear of 44), `testTheCardsInnerPaddingIsTheValueEChoseByLooking` pinning
it, and CLAUDE.md §2 carrying it as the second named waiver beside `peekStep = 14`. Nothing else on
the bar moved. Red-checked one regression at a time: back at 4 exactly the two tests fail; at 16
the pin fails and the SE floor fails twice (43.0 ≠ 44.6, 43.0 < 44).

| file | what it shows |
|---|---|
| `08-shipped-12-today-light.png` … `11-shipped-12-tools-dark.png` | The SHIPPED tree (no constant override, no probe loop) rendered the same way as the options above: the real bar at 12, Today and Tools, light and dark. Identical to the `12` rows of the sheets, as it must be — same file, same constant. |

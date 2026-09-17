# START HERE — the landscape FAB overlap, then the tab pill's inset

*Written 2026-09-16 at the close of the session that recovered E's iPhone and completed Phase F
step 2. **This is a disposable pointer — archive it when you write your successor.** The design
record it leans on is `SESSION-OPENER-tabbar-select-pill-design.md`, which is permanent.*

## Read these first, in this order

1. `claudecode.md` — the TDD role definition.
2. `CLAUDE.md` → **Architecture notes** and **§2 (spacing grid)**, **§7.1–7.5**. NOT `docs/`.
3. `handoff/OPEN-ITEMS-REGISTER.md` → **§B**, where both of these items now sit, and **§⓪** for
   where Phase F got to.
4. `screenshots/ios27-device-findings/README.md` — **the measurements are already done.** Do not
   re-derive them from the images.

## State when this was written

`main` is clean and everything is landed (run `git log --oneline -1` for the SHA). **E's phone is on iOS 27.0 (24A437)** and
carries `560d068` — the same app code as step 1, since no Swift has changed since `598da3b`.
**Phase F step 2's look is DONE and the app is correct on 27**: E confirmed the Live Activity, the
Home Screen widgets and the app itself. The sheet chrome is confirmed too. **Nothing about iOS 27
is outstanding except the schedule summary line's dimness in dark**, which E has not looked at.

**Neither item below is an iOS 27 regression.** Both are pre-existing and were simply never looked
at in these conditions.

## Item 1 — the landscape FAB overlap (a real bug; do this first)

In **landscape**, with an unacknowledged **`OfflineSprintSummaryCard`** on screen, the capture disc
renders **on top of the Settings gear** and the gear cannot be tapped. Measured: the disc sits at
**y 48–226 on an 1180 pt-tall landscape screen**.

**The suspected cause is a HYPOTHESIS, not a diagnosis. Verify it before you write anything.**
`RootBottomOverlay.swift` shares one `VStack` between the away card, the disc and the timer bar so
that *"an active sprint PUSHES the disc up"* — correct in portrait, and the suspicion is that in
landscape the away card's height pushes past the header. That was inferred from five sampled GIF
frames and one grep. **It has not been reproduced in a test or a simulator.**

- **Reproduce it first** — landscape AND an unacknowledged away card; neither alone did it.
- **TDD applies** (`claudecode.md`): the pure part of whatever positions that stack gets a failing
  test before the fix.
- Mind that the shared `VStack` is deliberate and E-reviewed (2026-08-25 position review). **Do not
  break the sprint-pushes-the-disc behaviour to fix the overlap** — that is the thing the file
  exists to do.
- A landscape UI journey is the natural regression camera; `IOS27CompatSweepUITests` is the
  precedent for a re-runnable one.

## Item 2 — the selected tab pill's left inset (E picks by eye)

Measured on device: the filled pill sits **3.00 pt (light) / 2.67 pt (dark)** from the bar's left
edge, against **15.7 pt** from the last glyph to the right edge — a **~5× asymmetry**. Mirrors on
the right when **Tools** is selected.

**E asked for RENDERED OPTIONS, not a chosen number.** Render the bar with the card's inner padding
at **4 / 8 / 12**, in both modes, with the first tab selected, and let E pick by sight. This is the
house pattern for a spacing decision — see `peekStep = 14` in CLAUDE.md §2, the one sanctioned
off-grid value, which E chose that way.

- Constants: `Theme/AppTabBarPresentation.swift` —
  `floatingPaddingHorizontal = 4` (the card's inner padding, the one to vary) and
  `pillPaddingHorizontal = 16` (the pill's own padding — probably NOT the one to touch).
- **`4` is ON §2's grid, so this is not a violation to correct.** It was approved when the selection
  was an icon-only chip that never reached its slot edge; Design C's pill is a filled capsule that
  does. Frame it to E that way.
- **Memory: all bar constants are E-approved and must not be re-tuned unprompted.** E HAS now
  prompted, for this one constant. That licence does not extend to the others.
- Show, don't describe (E's standing rule): render and send images, or label with real measured
  numbers. No ASCII mock-ups.

## Still held, do not start

**The colour-scheme arc remains on E's HOLD** (2026-09-13), and its opener is in
`handoff/archive/START-HERE-colour-scheme.md`. iOS 27's retuned sheet chrome and dark capsules are
recorded as INPUTS to it. Do not start it, and do not fold item 2 into it — item 2 is spacing, not
colour.

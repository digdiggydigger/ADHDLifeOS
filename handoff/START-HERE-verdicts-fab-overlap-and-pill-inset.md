# START HERE — two verdicts from E, then one tiny block

*Written 2026-09-17 at the close of the session that fixed the landscape FAB overlap and rendered
the pill-inset options. **This is a disposable pointer — archive it when you write your successor.**
The design records it leans on are permanent: `SESSION-OPENER-tabbar-select-pill-design.md` (the
bar) and the F-LandscapeFabOverlap block in `TODO-CLAUDE-CODE.md` (the overlay's two arrangements).*

## Read these first, in this order

1. `claudecode.md` — the TDD role definition.
2. `CLAUDE.md` → **Architecture notes**, **§2**, **§7.1–7.5**. NOT `docs/`.
3. `handoff/OPEN-ITEMS-REGISTER.md` → **State** and **§B**'s first two items, which are the whole
   of this opener.
4. `screenshots/landscape-fab-overlap/README.md` and `screenshots/tabbar-pill-inset-options/README.md`
   — **the evidence and the measurements are done; do not re-derive them.**

## State when this was written

`main` @ `7e85ec6` (PR #137) plus this close-out's chore PR — run `git log --oneline -1`. Suite
3,025 / 0, SwiftLint 0 / 819, build green. **E's phone is on iOS 27.0 and still carries `560d068`:
the fix is NOT installed on it.** `xcrun devicectl list devices` showed simulators only at close-out.
The colour-scheme arc remains on E's HOLD (2026-09-13); its opener is in `handoff/archive/`.

## First: put the build on the phone, THEN ask for the verdict

The standing rule (`ask-for-device-checks-on-a-build-e-has`): install before asking. Recipe in the
`device-build-lag` memory — `xcodebuild build -destination 'platform=iOS,name=wishwashwacky15'
-allowProvisioningUpdates -derivedDataPath <scratch>` then `devicectl device install app` and
`devicectl device process launch --terminate-existing`. A `Security` denial right after a re-issued
profile is TRANSIENT; retry once before escalating. If the phone is not listed, ask E to connect it.

## Verdict 1 — the landscape arrangement (`F-LandscapeFabOverlap`, merged)

What changed: in LANDSCAPE with anything up (the away card, a Confirm card, a running sprint) the
cards take the column at the bottom-left and the capture disc keeps its resting corner; the gear is
reachable. Portrait is byte-for-byte the stack E reviewed. Renders in
`screenshots/landscape-fab-overlap/` (03–06). **Ask E to rotate the phone with a sprint running**
— that is the state E will actually meet; the away card is the rare one. No RM-on pass is owed:
no reduced-motion site changed.

If E wants the column narrower, wider, or the timer bar to keep full width in landscape, the knob
is `RootBottomOverlayLayout.cardsWidth` and the pure tests in `RootBottomOverlayLayoutTests`;
the arrangement rule itself (`arrangement(isCompactHeight:hasCards:)`) is the thing NOT to widen
without E — regular height must stay stacked.

## Verdict 2 — the pill inset (E picks a number)

`screenshots/tabbar-pill-inset-options/00` and `01`: `floatingPaddingHorizontal` at 4 / 8 / 12 / 16.
Then ONE block: set the constant, extend `AppTabBarPresentationTests` with a pinning test that says
E chose it by looking (the `testThePeekStepIsTheValueEChoseByLooking` shape). Two catches, both in
the folder README: **12 is off-grid** → ship as a named waiver and add it to CLAUDE.md §2's
waiver line beside `peekStep`; **16 breaks the SE floor** → `maximumRestingPillWidth` must drop by
≥5pt with it, and the SE test's arithmetic comment moves. Do not touch any other bar constant.

## Still held, do not start

The colour-scheme arc (E's HOLD, 2026-09-13). Item 2 is spacing, not colour — do not fold it in.

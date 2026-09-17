# START HERE — E's device looks on three shipped blocks (one of them with Reduce Motion ON)

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
3,025 / 0, SwiftLint 0 / 819, build green. **E's phone is on iOS 27.0 and carries `main` @ `9eb5198` — all three blocks installed** (built, installed and launched via `devicectl` in one pass on 2026-09-17,
03:38 local). The free-account profile in that build expires **2026-09-17T19:25:02Z**; after that the
app refuses to launch until a rebuild re-issues it, which is the first thing to do if E reports
the app "won't open".
The colour-scheme arc remains on E's HOLD (2026-09-13); its opener is in `handoff/archive/`.

## First: check the build is still on the phone (profile expiry above), THEN ask for the verdict

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

## Verdict 2 — the pill inset: E PICKED 12, and it is SHIPPED (`F-TabBarPillInset`, PR #141)

Nothing to build. E looks at the bar on the phone (installed) and says whether 12 reads right at
the pill's edge; the render of the shipped tree is `screenshots/tabbar-pill-inset-options/08–11`.
If E wants a different number after seeing it in the hand, it is the same one-constant change
with the pin test and CLAUDE.md §2's second waiver updated.

## Verdict 3 — the fan fade (`F-FanCardsFade`), WITH a Reduce Motion ON pass

E's third finding of 2026-09-17 (cards drawn above the capture fan; portrait away card hiding
LINK and TASK) shipped the way E chose: the cards fade out and stop taking touches while the fan
is open, layout kept so the × stays put. **This block ADDS a reduced site** (the same fade on a
plain ease under Reduce Motion), so §7.3's rule applies: **ask E for both passes in one message —
open the fan with a card up, Reduce Motion OFF, then ON.** The arc was deliberately NOT
re-anchored to the disc's real position (see the register §B); if E finds the arc leaning out of
the resting corner odd once the cards are gone, that is a new question, not a bug — and it is now concrete: with a card pushing the disc up in
portrait, the × sits ON the PHOTO tile (register §B has the two shapes for E).

## The original section below is superseded by the three above where they disagree.

## Verdict 2 (original) — the pill inset (E picks a number)

`screenshots/tabbar-pill-inset-options/00` and `01`: `floatingPaddingHorizontal` at 4 / 8 / 12 / 16.
Then ONE block: set the constant, extend `AppTabBarPresentationTests` with a pinning test that says
E chose it by looking (the `testThePeekStepIsTheValueEChoseByLooking` shape). Two catches, both in
the folder README: **12 is off-grid** → ship as a named waiver and add it to CLAUDE.md §2's
waiver line beside `peekStep`; **16 breaks the SE floor** → `maximumRestingPillWidth` must drop by
≥5pt with it, and the SE test's arithmetic comment moves. Do not touch any other bar constant.

## Still held, do not start

The colour-scheme arc (E's HOLD, 2026-09-13). Item 2 is spacing, not colour — do not fold it in.

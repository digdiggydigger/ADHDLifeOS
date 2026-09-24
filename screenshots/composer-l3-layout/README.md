# composer-l3-layout — `F-D2-ComposerKeyboardLayout`

**Environment:** iPhone 17 Pro simulator on **iOS 27.0** (E's OS) and iPhone 16 Pro on **iOS 18.0** (the floor),
Firebase emulator, throwaway `uitest-d2*@example.test` accounts made per run, 2026-09-24. Frames are the UI harness's
own screenshots (`ComposerKeyboardBarUITests.testRenderTheComposer` and the pin), named from what the hierarchy
showed, never from what the runner was told.

## What these frames settle that no test could

1. **Round 7b's L3, built.** The title owns the page; the four "when" segments ride over Area | Time | Add in one bar
   above the keyboard. Measured with the keyboard up: **the bar spans 402–538pt** of the 874pt screen (content
   410–530), against the 406–518pt E approved on board 64. Keyboard down it rests at 696–832pt.
2. **The finding that stopped the block (`00-`).** Findings §L asked for a test that opening Area, Time or the date
   picker would NOT put the keyboard down, and called it unverified. On iOS 27 it does, every time: the SwiftUI
   `Menu`, a UIKit `UIButton` menu tried in its place, and the popover — and the keyboard does not come back.
   **E chose "Let it settle"** (2026-09-24): the first choice lets the bar rest at the bottom, it stays there, and a
   tap on the title raises it again. Nothing re-focuses the title behind the user's back.
3. **The panel (`01-`).** Board 64 drew bare cards; the build puts them on a Liquid Glass panel (26+), per findings
   §L's platform note. **E chose "Keep the panel".** On iOS 18.0 it is the same panel in bar material with a hairline.
4. **"Text, then the date."** The fourth segment reads "Date" in LabelPrimary with no glyph; the popover is a whole
   320pt calendar pointing at it; after a pick the segment IS the selection and reads the day ("Sat 10").
5. **Accessibility sizes stack** (L1's form, carried in E's option): the boxed title, the segments one above the
   next, full-width Area and Time scrolling, Add pinned alone.
6. **No keyboard "Done" row** appears above the keyboard in any frame, before or after the block: `.keyboardDismissal()`
   is applied outside the composer's own `NavigationStack`, so its `.keyboard` toolbar never reaches this screen. The
   bar therefore sits directly on the keyboard (8pt gap), as the probe drew it.

## Verified paths (the one `#available` site, the bar's container)

`26 path (Liquid Glass panel): run on sim 27.0; E's phone at the arc-D close.`
`18–25 path (bar-material panel): run on sim 18.0 (the floor) — the 20–24 frames, and the settle pin PASSED there (rode at 394pt, settled at 696pt); 19–25 never run.`
Reduce Motion: no reduced site — the selection recolours in place (no sliding indicator), so no RM-on pass is owed.

## Throwaway data

Each harness run makes one emulator account (`uitest-d2keyboard-*`, `uitest-d2render-*`, `uitest-composerdoors-*`,
`uitest-*` for the create journey) and one or two tasks in it. The emulator is local and was started with
`--import scripts/audit/emulator-state`, never exported back, so nothing persists past the emulator's shutdown.

## Files

| file | what it proves |
|---|---|
| `00-finding-every-choice-drops-the-keyboard.jpg` | The finding: typing rides (402pt); the Area menu, a UIKit menu tried instead, and a closed menu all leave the keyboard down and the bar at the bottom. What E decided from. |
| `01-finding-panel-vs-board-64.jpg` | Board 64's bare cards beside the built Liquid Glass panel. E: "Keep the panel". |
| `02-L3-down-L.jpg` / `04-L3-down-D.jpg` | Keyboard down: the title alone on the page, the bar resting at 696pt. Add disabled until there is a title. |
| `03-L3-up-L.jpg` / `05-L3-up-D.jpg` | Keyboard up: the bar rides at 402–538pt with an 8pt gap to the keys; no Done row. |
| `06-L3-area-open-settled-L.jpg` / `07-L3-time-open-settled-L.jpg` | "Let it settle": a menu open, keyboard down, the bar at rest at the bottom. |
| `08-` / `09-` / `10-L3-date-…-L.jpg` | "Date" in LabelPrimary with no glyph → a whole 320pt calendar pointing at it → "Sat 10", lit as the selection. |
| `11-` / `12-L3-date-…-D.jpg` | The same in dark. |
| `13-L1-stacked-down-A.jpg` / `14-L1-stacked-up-A.jpg` | AX3: L1's stacked form — boxed title, segments one above the next, full-width tiles scrolling, Add pinned alone and riding the keyboard. |
| `15-L3-up-XXXL.jpg` / `16-L3-date-after-XXXL.jpg` | xxxLarge, the largest ordinary size: still L3, and after the fix "None" and "15 min" read whole (the first render showed "No…"/"15…"). |
| `20-` / `21-L3-down-…-ios18.jpg` | iOS 18.0, the floor branch: the same panel in bar material with a hairline, light and dark. |
| `22-L3-up-D-ios18.jpg` | iOS 18.0 with the keyboard up: the bar rides it at 394pt (iOS 18's keyboard is 8pt taller). |
| `23-` / `24-L3-date-…-D-ios18.jpg` | iOS 18.0: the calendar popover and "Sat 10". |

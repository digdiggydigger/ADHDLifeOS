# Home reorder toggle + archived-aware pickers + "Unassigned" routing — device verification

Block 3 of the Life Areas workstream (closes `docs/ARCHITECTURE.md` §8). Captured on iPhone 17 Pro
(iOS 26.5) against the live AWS backend with a real Cognito session. Dark mode.

| # | Screenshot | What it proves |
|---|-----------|----------------|
| 01 | `01-home-arrange-header.png` | The **"Arrange"** control sits in an inline "Life Areas" header row above the grid. The toolbar (`inboxButton` tray, `settingsButton` gear) is unchanged. Grid shows active areas only. |
| 02 | `02-reorder-mode-list.png` | Tapping "Arrange" swaps the grid for a `List` with native drag grabbers (edit mode); the header button now reads **"Done"**. |
| 03 | `03-after-drag.png` | A drag reorders the list (Work moved down below Family). Each completed drag fires one bulk `PATCH /life-areas/reorder`. |
| 04 | `04-persisted-after-relaunch.png` | After **terminate + cold relaunch** (which re-fetches from AWS), the new order persists (Personal, Family, Work, Health…) — the reorder actually landed on the backend. |
| 05 | `05-editor-archived-section.png` | Archiving "Hobbies" (Settings → Life Areas) moves it to the greyed, badged **"Archived"** section; "9 active areas". |
| 06 | `06-picker-archived-greyed.png` | The shared `LifeAreaPicker` menu (here at Task Create) shows **"Hobbies (Archived)"** greyed with a text badge at the bottom; active areas above. Tapping it did **not** change the selection (stayed "None") — archived rows are unselectable. |
| 07 | `07-tasks-order-follows-home.png` | The Tasks tab's group order follows the new Home order — **Family before Work** — a single ordering across the app. |
| 08 | `08-reorder-with-archived-present.png` | **TRAP 1 proof:** with Hobbies archived, reorder mode lists only the 9 active areas, and a drag succeeds with **no error alert** — the reorder payload included the archived id (a missing id would 400 on set-equality). Verified it persisted across relaunch with Hobbies still archived. |
| 09 | `09-unarchive-roundtrip.png` | Unarchiving Hobbies returns it to the active list ("10 active areas", no Archived section) with no data change — the archive round-trip is reversible. |

## Verification addendum — data-backed archive proofs (captured 2026-07-31)

The original run archived "Hobbies", which had **no items**, so the archive-reversibility promise §8's
whole decision rests on went unproven. This addendum assigns a real task (**"Archivetest task"**) and a
real journal log (**"Archivetest Log entry"**) to **Personal**, archives Personal, walks the four checks,
then unarchives and confirms the round trip. iPhone 17 Pro (iOS 26.5), live AWS backend, real Cognito
session, dark mode.

| # | Screenshot | What it proves |
|---|-----------|----------------|
| 10 | `10-taskdetail-archived-selection.png` | **Check 1.** After archiving Personal, the task opens in Task Detail with Life Area still **Personal** — *not blank*. This shot is after a Save (Priority set to **P3**) and a cold relaunch, so it also proves the save carried `lifeAreaId=Personal` through and Priority persisted. |
| 11 | `11-taskdetail-picker-archived-checkmarked.png` | **Check 1 (the mandatory exception).** The shared picker menu at Task Create shows **"✓ Personal (Archived)"** at the bottom — checkmarked (current selection), greyed, text-badged, and *still selectable*. This is the `isRowDisabled(area:isSelected:)` current-selection exception on the real screen. |
| 12 | `12-capture-triage-archived-disabled.png` | **Check 2.** The **Capture triage** picker now *lists* "Personal (Archived)" (it showed none before this block), greyed at the bottom below the active areas. The selection was "None"; tapping the archived row was refused and stayed "None" — the row is `enabled: false`. |
| 13 | `13-tasks-archived-under-unassigned.png` | **Check 3 (Tasks).** With Personal archived, "Archivetest task" appears under the trailing **"Unassigned"** group. No "Personal" heading appears anywhere in the Tasks list. |
| 14 | `14-journal-archived-log-unassigned.png` | **Check 3 (Journal).** "Archivetest Log entry" reads **"Unassigned"** (it read "Personal" before archiving) while other logs keep their area names. Also shows the Journal filter's new `LabeledContent` row ("Life Area" / "All"). |
| 15 | `15-roundtrip-tasks-personal.png` | **Check 4 (round trip, Tasks).** After unarchiving Personal, "Archivetest task" is back under a **"Personal"** heading — same task, by name, no re-assignment. (Still P3 — the earlier save.) |
| 16 | `16-roundtrip-journal-personal.png` | **Check 4 (round trip, Journal).** "Archivetest Log entry" reads **"Personal"** again — the same log restored to the area with no data entry. Together with #15 this proves `lifeAreaId` was never mutated by archive/unarchive. |
| 17 | `17-axxxl-reorder-mode.png` | **AX-XXXL.** Reorder mode at accessibility-XXXL Dynamic Type: "Life Areas / Done" header and every row (emoji + name + drag grabber) reflow and stay legible — nothing clipped or truncated. |
| 18 | `18-axxxl-picker-archived.png` | **AX-XXXL.** The shared picker's open menu at AX-XXXL: rows wrap and stay legible, including **"Personal / (Archived)"** wrapping to two greyed lines — the archived badge is never cut off. |
| 19 | `19-journal-filter-labeledcontent.png` | **Journal filter (visual change).** The `journalLifeAreaFilter`, previously a bare menu picker outside a `Form`, now renders as a `LabeledContent` row — "Life Area" label with the current value ("All") trailing. No prior screenshot covered this screen. |

# Tag Editor UI — verification (block 3)

Driven on **iPhone 17 Pro (iOS 26.5) simulator against the LIVE API** (`life-os-api-gw`), signed in
as E, 2026-07-30. Every mutation used throwaway `zz-ui-*` tags; all were cleaned up (a DynamoDB
scan afterwards confirmed **zero** `zz-ui-*`/`As-yo-*` debris remains — E's original 7 tags intact).

Two real bugs were caught by driving the actual screens (neither is visible to unit tests) and fixed
before this run — see the build report.

| # | Screenshot | What it proves |
|---|-----------|----------------|
| 00 | `00-launch-state.png` | App signed in (real Home dashboard). |
| 01 | `01-settings.png` | Settings; **Life Areas greyed/disabled** (unchanged). |
| 02 | `02-settings-tageditor-row-active.png` | **Tag Editor row now active** (`settingsTagEditorRow`, enabled NavigationLink). |
| 03 | `03-tag-list-live.png` | Live tag list with correct usage counts from `GET /tags`. |
| 04 | `04-add-tag-sheet.png` | The `+` add-tag sheet. |
| 05 | `05-created-tag-zero-count.png` | Created `zz-ui-alpha` — appears with **“Not used yet”** (0 count). |
| 06 | `06-list-with-throwaways.png` | Full list incl. two throwaway tags, counts singular/plural/zero. |
| 07 | `07-detail-screen.png` | Row tap pushes **detail**: name field, usage, Delete. |
| 08 | `08-rename-clash-merge-alert.png` | Rename `zz-ui-alpha`→`zz-ui-beta` raises the **two-button merge `.alert`** naming the tag. |
| 09 | `09-after-merge-alpha-gone.png` | **Merge** removed the old tag; survivor remains; list reloaded. (Cancel first proved it writes nothing — both tags still present, then re-tapped.) |
| 10 | `10-delete-confirm-names-count.png` | **Delete confirm names the usage count** (“It isn't used by anything…”). |
| 11 | `11-create-dedup-list.png` | Creating an existing name (`family`) adds **no duplicate row** (dedup). |
| 12 | `12-list-AX-XXXL.png` | **AX-XXXL**: `LabeledContent` rows reflow (name/count stack), nothing clipped. |
| 13 | `13-detail-AX-XXXL.png` | **AX-XXXL** detail: all legible, Save correctly disabled (unchanged name). |
| 14 | `14-list-final-clean.png` | Final list — debris gone, back to E's 7 tags. |

## Proven by simulator vs. other layers

- **Simulator (this run):** Settings row active · list + counts · row→detail push · free rename ·
  rename-clash merge alert · Cancel-writes-nothing · Merge removes old tag + reloads · delete confirm
  naming the count · delete removes tag · create · create-dedup adds no duplicate · AX-XXXL on both
  screens.
- **Backend smoke (block 2, 62/0):** the merge **count-dedup arithmetic** — an item carrying *both*
  tags ends with exactly one junction row and the survivor's count is not double-counted. On device
  the throwaway tags had 0 usage, so this run proves the *UI merge flow* (alert → merge → old gone →
  reload); the dedup *arithmetic* is the backend layer's proof, cited here rather than re-claimed.
- **Unit tests (17 new, 531 total green):** validation, usage-count phrasing (0/1/many), the
  PATCH-outcome typing (`409`→needs-merge), merge/delete/create reload, and mutation serialisation.

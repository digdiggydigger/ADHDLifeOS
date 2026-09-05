# Life Areas UI — device verification (iPhone 17 Pro, iOS 26.5, live API)

Settings → Life Areas, block 2 of the Life Areas workstream. Every shot is the real app on the
booted simulator, signed into the live Cognito/DynamoDB backend (the 9 real seeded areas are E's
own). All destructive testing used throwaway `zz-la-*` areas, hard-deleted afterward; **E's nine
real areas were never renamed, re-emojied or archived, and the table was left byte-for-byte as
found (9 areas, `sortOrder` 1..9, `archived` absent).**

| # | Screenshot | What it proves |
|---|-----------|----------------|
| 00 | `00-launch-state.png` | App signed in; Home grid shows the 9 real areas with their real emoji (live API). |
| 01 | `01-settings.png` | Settings sheet — **Life Areas row is now live** (was a disabled placeholder); Tag Editor still live; About & Diagnostics still disabled. |
| 02 | `02-list-9-areas.png` | Life Areas list — all **9 areas in `sortOrder`** with real emoji + names, "9 active areas" footer, `+` toolbar. **No Archived section** (nothing archived). |
| 03 | `03-detail-work.png` | Detail (opened read-only on a real area) — name field, "Selected" emoji preview, the 40-emoji grid with the current emoji highlighted, free-type field, Archive button. Save disabled (nothing changed). |
| 04 | `04-create-sheet.png` | Create sheet — name typed **"zz-la-demo"** stays lowercase (autocapitalisation off, trap e); a default emoji is pre-selected so Save is never blocked. |
| 05 | `05-created-in-list.png` | The created area appears in the list (`POST /life-areas` → 201, live). |
| 06 | `06-emoji-freetype-reject.png` | Free-type field rejects the 2-character string "ab" with the readable inline message **"Enter a single emoji."** |
| 07 | `07-detail-edited.png` | Rename to "zz-la-demo-2" (lowercase) **and** a multi-scalar **family emoji 👨‍👩‍👧‍👦 selected from the grid**; Save enabled. |
| 08 | `08-archived-section.png` | After Archive: the row moves into a new **"Archived" section**, labelled **"zz-la-demo-2, Archived"** (badge carried in text, VoiceOver-safe), with the "hidden from Home / moves to Unassigned" footer. |
| 09 | `09-create-conflict-archived.png` | Creating a name held by an **archived** area → alert offering **"Unarchive it instead?"** (taking it genuinely unarchived that area and created nothing). |
| 10 | `10-create-conflict-live.png` | Creating a name held by a **live** area → **Cancel-only** alert ("Pick a different name."), creates nothing. |
| 11 | `11-rename-conflict.png` | Renaming onto an existing name ("Work") → **Cancel-only** alert ("“Work” is taken"), and it 409'd server-side so **Work was untouched**. |
| 12 | `12-dynamic-type-axxxl-list.png` | Accessibility text size **AX-XXXL** — rows grow, nothing clips or truncates. |
| 13 | `13-home-with-active-throwaway.png` | An **active** throwaway area shows as a card on the **Home grid**. |
| 14 | `14-home-archived-hidden.png` | After archiving that area, it is **removed from the Home grid** (unarchiving restores it). Proves the archived-aware Home filter in `AWSHomeClientAdapter`. |

## Traps checked (all previously paid for)

- **a — lowercase UUID on PATCH:** `AWSLifeAreaEditorClientAdapter` routes every `PATCH`/id through `UUID.lowercaseUUIDString`; unit-asserted (`test_update_200…PatchesLowercasedId`) and confirmed live (rename/emoji/archive all succeeded against real ids).
- **b — closure NavigationLink both hops:** Settings→list and list→detail are both closure links; both pushes proven on device (01→02, 02→03).
- **c — shared `LifeArea` untouched:** editor uses its own `EditableLifeArea`; `HomeModels.swift` is **not** in the diff. The Home archived-filter reads `archived` on the adapter's **private** DTO, not the shared type.
- **d — typed 409 with `archived`:** conflicts decode into `LifeAreaNameConflict{id,name,archived}`; the two create-conflict branches (09 vs 10) are driven by that flag.
- **e — autocapitalisation/autocorrect off:** name and free-type fields both carry `.textInputAutocapitalization(.never)` + `.autocorrectionDisabled()`; "zz-la-demo" stayed verbatim (04).

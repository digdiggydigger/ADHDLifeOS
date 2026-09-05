# Routines section on Tools — device verification (F-Routines-B-ToolsSection)

Taken by **E on `wishwashwacky15` (iPhone 15 Pro), LIGHT appearance, 2026-09-05**, signed in to E's
own live Firebase account (project `adhdlifeos-acb49`), build `1ab5ff2` — whose tree is
byte-identical to main at `511e55b`, so this walk counts for main.

**No throwaway data was created.** These use E's real saved places (`Home`, `routines test`), and
the only change made was adding a second leaving action to `Home` — which is itself shot 3's
subject, and was kept.

**Why the folder exists — what the tests could not reach.** `ToolsRoutinesJourneyUITests` proves
the section is reachable and correctly populated, but every automated shot in this project is
simulator DARK; light had only ever been rendered in a mock. Shot 3 goes further than any test
does, catching the threshold rule being applied to real data in real time rather than its result.

| # | Screenshot | What it proves |
|---|---|---|
| 1 | `1-section-light-two-routines.jpeg` | The section in LIGHT on device: header, caption and rows on the real asset-catalog tokens. Both directions of `routines test` list independently, each judged on its own steps. |
| 2 | `2-row-opens-place-editor.jpeg` | A row opens the real `Edit place` sheet — E's settled Option A, where a routine's editor IS the place's Actions section and no second editor exists. |
| 3 | `3-home-leaving-routine-appears-and-sorts-first.jpeg` | The threshold is live, not cached: adding a SECOND leaving action to `Home` made its routine appear at once. It also sorted ABOVE `routines test`, which is `PlacesService.sorted` reused rather than copied — so this section and the Places list can never disagree about order. |

`Home` renders the 📍 fallback because that place has no emoji set. Correct, not a defect — it is
`PlacesListView`'s own fallback, matched deliberately so one place cannot wear two glyphs.

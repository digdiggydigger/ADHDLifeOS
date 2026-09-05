# Routines section on Tools — E's device verification, 2026-09-05

Light mode on `wishwashwacky15` (iPhone 15 Pro), build `1ab5ff2`, whose tree is byte-identical to
main at `511e55b`. These close the one gap the UI journey could not: every automated shot is
simulator DARK, so light had only ever been rendered in the proposal mock.

They also capture the LIVE behaviour, which is the stronger evidence — a static render cannot show
a rule being applied.

| file | what it proves |
|---|---|
| `1-section-light-two-routines.jpeg` | The section in light: header, caption and rows on the real tokens. Both directions of `routines test` list independently, each judged on its own steps. |
| `2-row-opens-place-editor.jpeg` | A row opens the real `Edit place` sheet — the Option A promise that a routine's editor IS the place's Actions section, not a second editor. |
| `3-home-leaving-routine-appears-and-sorts-first.jpeg` | The threshold is live, not cached: adding a SECOND leaving action to `Home` made its routine appear at once. It also sorted ABOVE `routines test`, which is `PlacesService.sorted` reused rather than copied, so this section and the Places list can never disagree about order. |

`Home` renders the 📍 fallback because that place has no emoji set. That is correct — it is
`PlacesListView`'s own fallback — not a defect.

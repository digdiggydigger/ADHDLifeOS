# Tab depth — the re-tap, the Nudges way back, and the search row (F-TabDepth-1 + F-TabDepth-2)

**Environment:** E's iPhone 15 Pro (`wishwashwacky15`), light mode, live Firebase, signed in as E,
**2026-09-08 19:43–19:44 BST**, the `feature/tab-depth` build at `c4fba78` (installed 12:07;
both blocks). Taken by E, not by the session — E's own screenshots from
`../Ethan's Screenshot Folder/` (`IMG_8392`, `IMG_8393`), filed here because they are the
device half of the verdict that merged PR #35. No throwaway data was created by the session;
every nudge and task shown is E's own.

**What driving the real phone caught that the tests could not:** nothing that failed — and that
is the point of the folder. The arc's proofs are journeys on the simulator
(`TabReselectionJourneyUITests` 3 / 0, `SearchRowDepthJourneyUITests` 1 / 0), which pin the
pop, the scroll-to-top, the Back control and the row's absence by element. What no journey can
settle is whether the two things E designed by looking — a chevron where Nudges used to have no
way back, and an empty stretch beside the capture disc where "Search tasks" used to sit under
a pushed detail — read RIGHT on the device, in E's own data, at a glance. E's verdict, in
words: *"I have run through the 'four checks' … All 4 checks were successful."* The two
checks with no picture (Today comes back on the re-tap; a re-tap at the top scrolls up) are
motion, and the verdict is their record.

| # | file | what it proves |
|---|---|---|
| 00 | `00-nudges-pushed-from-today-back-chevron.jpeg` | Nudges pushed from Today's section (the Today slot is selected on the bar): the **Back chevron** top-left, the house pattern from Task detail, where before block 1 the screen hid the navigation bar and drew nothing — E's *"no way to get back to the Today main page"*. Live data: 3 due · 5 scheduled. |
| 01 | `01-task-detail-no-search-row.jpeg` | A task's detail (`september`, Health · Home · closed) pushed on the Tasks tab: **only the capture disc** sits above the bar. Compare `../arrival-card-refresh/02-task-detail-at-place-home-open.jpeg`, the before, where the *"Search tasks"* row sat beside the disc under this same screen. |

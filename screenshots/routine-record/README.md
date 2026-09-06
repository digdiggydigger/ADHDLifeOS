# The routine record on its surfaces (F-RoutineRecord-2, 2026-09-06)

**Environment:** iPhone 17 Pro simulator, iOS 26.5, Firebase Emulator Suite loading the repo's
own `firestore.rules`, a throwaway account created by `RoutineRecordJourneyUITests`
(`lifeos-test-…@example.test`, label `routine-record`), erased with the simulator afterwards.
Captured by the journey itself (`attach`), exported from the `.xcresult`, re-encoded to JPEG.

**Why a folder, when `JournalRoutineRowsTests` pins every word:** the words are asserted; the
*look* is what E settled by description and had not seen — that an offer nobody took reads
MUTED beside a finished run rather than as loudly, that the eye switch reads as a switch, and
that three lines per completed routine (E's call, taken with the repetition warning) sits
tolerably in a real day. None of that is an assertion.

**What driving the real screens caught that the tests could not** — two defects, both fixed
in the same block:
- The simulator's notification tray outlives a UI run AND a sign-out. The third journey run
  tapped the *previous account's* untouched Office banner, started that routine under the new
  account, and every record write failed server-side ("no entity to update"). Fixed in the app:
  a session ending now clears the routine banners (`RoutineNotificationTray`).
- The register's "tab-root not hittable" defect, unexplained across 60+ probe rounds, showed
  its mechanism in this journey's failure dump: the HIDDEN Today tab's elements were in the
  accessibility tree at their on-screen frames, and its momentum ring covered the Places card's
  centre. `accessibilityHidden` stops at each tab's UIKit navigation controller. Fixed:
  hidden tabs are parked off-screen (`AppTabContentLayout.hiddenTabOffset`).

**Throwaway data:** one emulator account with two places, two `routine_runs` documents, two
`location_events`. The emulator holds nothing durable; the simulator was erased after the run.

| file | what it proves |
|---|---|
| `00-journal-all-activity-off.jpg` | Everything, switch OFF: `Arrived at Gym` kept beside `Started routine at Gym` and `Finished routine at Gym · 1 of 4 done` (three skips, one auto step — "done" excludes skipped). `Arrived at Office` shows with NO routine row: the untaken offer is hidden by default. |
| `01-journal-all-activity-on.jpg` | Switch ON (filled eye, selected): `Routine offered at Office · not opened` appears, muted — tertiary ink and a `bell.slash` glyph with no accent — while started/finished keep the accent glyph. Nothing else moved. |
| `02-tools-last-run-line.jpg` | Tools → Routines: the gym row reads `Gym · 3 steps · last run today, 1 of 4`; the office row, never started, is byte-identical to before (`Office · 3 steps`). |

## E's device walk — 2026-09-06, iPhone 15 Pro (iOS 26.4), live Firebase, E's own account

Branch `7430ea7` installed over `devicectl` after E republished `firestore.rules`. E signed out
and back in (no stale banner in Notification Centre), then test-fired arrivals at `Home` and
worked the eye switch in both appearances. Every row below is REAL data on the live project;
nothing to clean up — it is E's journal.

| file | what it proves |
|---|---|
| `03-device-dark-switch-on.jpg` | Dark, switch ON: two `Routine offered at Home 🏠 · not opened` rows (7:45) muted between accent-glyph rows; a REPLACED run reads gently as `Routine at Home 🏠 · 0 of 2 done` (its `Started` row is the 7:23 one — newest-wins ended it when the 7:46 tap started a new run); the new run's `Started` + `Finished … · 2 of 2 done`. |
| `04-device-light-switch-on.jpg` | The same moment in light. Muted rows still read; the filled eye reads as selected. |
| `05-device-light-switch-off.jpg` | Switch OFF: both offered rows gone, every other row unmoved — the switch touches offers alone. |
| `06-device-dark-switch-off.jpg` | Same in dark. |
| `07-device-third-run-switch-off.jpg` | A third run two minutes later: `Arrived` 7:47 → `Started` 7:47 → `Finished … · 1 of 2 done` 7:48 (one skip). The three-lines-per-visit shape E chose, on real data. |
| `08-device-third-run-switch-on.jpg` | Switch ON again over the same day: the offers return in place, muted. |

**Not proved by these:** the SWIPE path. Both offered rows say `not opened`, i.e. they timed out
or were replaced; a swiped banner would read `· cleared`. Whether E swiped them is the open
question at the time of writing.

**Superseded after the walk:** E's call is that the eye hides EVERY routine row, started and
finished included. Files `00-` and `01-` show the earlier rule (started/finished always visible)
and will be replaced when the journey is re-run on the new rule. Files `03-`…`08-` are E's device
walk under the earlier rule too.

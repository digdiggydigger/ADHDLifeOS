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

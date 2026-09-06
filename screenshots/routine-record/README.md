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
| `00-journal-all-activity-off.jpg` | E's post-walk rule (re-captured 2026-09-06): switch OFF hides EVERY routine row — started and finished included. The day reads `Arrived at Office 💼`, the `Leg day` log, `Arrived at Gym 🏋️` and nothing else. `Leg day` stays because it is the routine's `journal_line` STEP — a `logs` row, not a routine row, so the eye rightly leaves it. |
| `01-journal-all-activity-on.jpg` | Switch ON (filled eye, selected): the whole routine story returns — `Started routine at Gym 🏋️` and `Finished routine at Gym 🏋️ · 1 of 4 done` (three skips, one auto step — "done" excludes skipped) with accent glyphs, and `Routine offered at Office 💼 · not opened` muted — tertiary ink, `bell.slash`, no accent. The crossings never moved. |
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

## The swipe path — proved on device, 2026-09-06 review session (same phone, live Firebase)

The walk left the swipe path open: every offered row said `not opened`, and E's answer to "did
you swipe?" was *a mix of both* — which looked like a broken dismiss branch. A controlled
experiment settled it, still on build `7430ea7`: a test-fired Home arrival at 08:35 (driven
through iPhone Mirroring) wrote run `6EE57B3C…` as `offered` — read live over the Firebase MCP —
then E cleared its notification in Notification Centre by hand (left swipe → Clear; mirroring
cannot reach Notification Centre), and the document flipped to `dismissed` / `swipe` /
`dismissed_at 07:37:27Z`. **Why the walk showed none:** swiping a PRESENTED banner up only
hides it — iOS reports nothing — and the next fire replaces it; only a real Notification Centre
clear is a "swipe" to iOS. E took these two screenshots minutes later; what a test cannot
assert here is precisely the real iOS dismissal delivery and how `· cleared` reads on real data.

| file | what it proves |
|---|---|
| `09-device-swipe-cleared-switch-off.jpg` | Dark, switch OFF: the 8:35 slot shows `Arrived at Home 🏠` alone — the cleared offer hides by default. (Started/finished rows from 7:46–7:48 still visible: this build predates the eye-hides-everything change.) |
| `10-device-swipe-cleared-switch-on.jpg` | Switch ON: `Routine offered at Home 🏠 · cleared` at 8:35 — the first `· cleared` ever rendered, muted with the `bell.slash` glyph, sitting under its arrival row. The whole dismissal pipeline (banner → iOS dismiss action → delegate → Firestore → Journal) on one screen. |

**The rule changed after the walk:** E's call is that the eye hides EVERY routine row, started
and finished included. Files `00-` and `01-` were re-captured by the journey on that rule.
Files `03-`…`10-` are E's device under the EARLIER rule (started/finished always visible with
the eye off) — the phone carried `7430ea7` throughout; what they prove (muting, the three-line
shape, the swipe pipeline) is unchanged by the eye's wider gate.

## E's device confirmation of the finished rule — 2026-09-06 09:07, build `7ad72ac`, live Firebase

The review session installed `7ad72ac` (the finished eye change) over `devicectl`; E force-quit,
relaunched, and took these four before authorising the merge. Real data, E's own journal,
nothing to clean up. What a test cannot assert: the rule on a REAL day's density (six Home
arrivals), in both appearances, and the `· cleared` row from the morning's swipe proof sitting
in the story.

| file | what it proves |
|---|---|
| `11-device-new-rule-dark-switch-off.jpg` | Dark, eye OFF: the whole day is crossings and a Focus sprint — six `Arrived at Home 🏠` rows and NOT ONE routine row. E's rule, live. |
| `12-device-new-rule-dark-switch-on.jpg` | Dark, eye ON: the story returns — `Routine offered at Home 🏠 · cleared` (8:35, muted), two Started/Finished pairs, and the replaced run reading gently as `Routine at Home 🏠 · 0 of 2 done`. |
| `13-device-new-rule-light-switch-on.jpg` | The same moment in light: muted rows still read, accent glyphs hold. |
| `14-device-new-rule-light-switch-off.jpg` | Light, eye OFF: crossings alone again — the switch is symmetric across appearances. |

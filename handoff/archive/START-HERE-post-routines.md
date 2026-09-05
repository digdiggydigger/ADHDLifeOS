# Start here — after the Routines merge

*Paste into a fresh Claude Code session. Written 2026-09-05 ~07:40. **The Routines arc is MERGED
and on `main`.** This supersedes `START-HERE-routines-merge.md`, which was written before the
merge and whose state gate now points at a SHA on a branch we have left — read that one only for
the history of how the arc landed.*

Read `claudecode.md` and `CLAUDE.md`, then the auto-memories `routines-next-arc`,
**`routine-record-gap`** (E's newest ask), **`tab-root-rows-not-hittable`** (the one that saves a
day), `never-destroy-uncommitted-work`, `build-machine-limits`, `ui-test-cross-run-state`,
`device-build-lag`, `never-automate-auth-flows`, `public-launch-intent`.

## State gate — run before anything

```bash
git branch --show-current                # expect main
git status --short                       # must be empty
git log --oneline -1                     # expect 705fb43
git log --oneline -1 origin/main         # same SHA
swiftlint lint                           # expect 0 violations, 672 files
./scripts/emulators.sh                   # SECOND TERMINAL — UI tests SKIP without it
```

Baseline on main: unit suite **2,326 / 0**, lint **0 / 672**, both targets build.
UI target **19 passed / 6 failed**, every failure accounted for (§3).

E's iPhone `wishwashwacky15` carries **`9cff2b7`**. Its app source differs from main's by a
**doc comment only** — `git diff 9cff2b7 main -- "ADHD LifeOS" FocusTimerWidget` touches
`PlaceTriggerEventHandler.swift` and every changed line begins `///`. So the build on the phone is
functionally identical to main and the device walk done on it counts for main. Reinstalling from a
main build is hygiene, not a prerequisite.

`feature/routines` is **KEPT**, local and remote, on E's word. Do not delete it.

## 1. What landed

`0cea871` merged the arc `--no-ff`, re-verified ON main before the push. Six shipped blocks, both
field-walk rounds, and **Block A — deferred logging**, which is the one that changes behaviour:

**A crossing that qualifies as a routine writes NOTHING.** The run, Today's card and the journal
line come into existence only when the notification is TAPPED; swiping the banner away leaves no
trace. The whole frozen run rides the notification's userInfo as JSON
(`place_routine_run_json`) because with nothing written there is no stored run for a bare UUID to
resolve against. `PlaceRoutineActivator` turns it into a real run.

**Do not re-litigate these — E settled each, and each is pinned by a test:**
- the `location_events` record still writes at the crossing (see §2 — the reasoning was corrected);
- a departure still ends a live arrival run at the crossing — a deletion, never a creation;
- deferral is **routines only**; a crossing with no routine auto-runs exactly as shipped;
- the arrival card is SHOWN, not suppressed;
- with the nudge master switch off, a routine crossing now writes nothing and spends no cooldown.

Copy changed on purpose: `Journaled "Leg day"` → **`Will journal "Leg day"`**, and the screen's
`Ran by itself when you arrived` → `Ran by itself when you started`.

## 2. Device walk — checks 1 and 2 PASS, 3–8 outstanding

Checklist: `ON-DEVICE-CHECKLIST-blockA-2026-09-05.md` (kept current).

E walked checks 1 and 2 on 2026-09-05 and both pass. The evidence, from E's Journal screenshot,
is the shape any future regression check should copy: **five `Arrived at routines test` timeline
rows against only three `Leg day` logs** — dismissed banners left an arrival row and no journal
line, tapped ones left both. Today was clean after the dismissal. The banner read
`Time to train · Will journal "Leg day" · 2 steps ready — Open YouTube · Open Apple Maps. Tap to
run.`

**A correction that must not be lost.** E flagged `Arrived at routines test` surviving a dismissed
banner as a possible breach of the no-trace rule. It is not a routine log — it is the
`location_events` timeline row (`JournalTimeline.locationEventLine`, shipped `92a13e6` on
2026-08-27 under E's own "journal rows only" call), and it fires for every crossing. **When first
asking E whether to defer it, I described it as "sensing, not a user-visible log — nothing appears
on Today or in Journal from it". The second clause was FALSE.** Re-put with the real behaviour on
screen, E's ruling was unchanged: **keep it.** The handler's doc comment now says so plainly.

**Still unwalked: checks 3–8.** If E does more, 4 and 5 are the ones worth having — 4 guards
double-writing (tap twice, get two journal lines), 5 guards the stale card that started the whole
field walk. Check 7 needs a real fence crossing; the test-fire button forces the switch on. Check
8 is the light-mode keyline and needs E's eyes.

## 3. The UI target's six failures, all accounted for

| test | verdict |
|---|---|
| `AccountNameJourneyUITests` | pre-existing — re-run at `2c46ee7` and fails there |
| `CaptureDiscClearance/testNudges_…` | pre-existing — same |
| `RenderHarness/testRenderNewNudgeSheet` | pre-existing — same |
| `RenderHarness/testRenderSignUpForm` | pre-existing — same ("Keyboard never appeared") |
| `CaptureDiscClearance/testToday_…` | an honest red: a vacuity guard added this session replaced a false green |
| `SignedInJourney/testSettings_…` | passes in isolation — the `settingsButton` not-hittable family |

`FirstRunJourneyUITests` was among the pre-existing failures and is **FIXED**. Both routine
journeys passed together in the final pre-merge run.

## 4. Open work, in the order it is likely to be picked up

- **Block B — its own "Routines" section on the Tools list.** E's words, 2026-09-05. A first-class
  entry, presented as Routines, NOT folded into Places. Placement and naming are settled; the data
  model is not. Propose FIRST the version needing no new entity — one row per place+direction that
  clears the 2-tap-step threshold, place as subtitle — because a routine has no independent
  existence today: it IS a place's actions for one direction, computed by `PlaceRoutinePlan.make`.
  First-class routine RECORDS are Arc 2 and remain unauthorised.
- **The routine record gap** ([[routine-record-gap]]) — E's ask, PARKED for its own session, do
  not start unprompted. Nothing distinguishes a routine OFFERED from ACCEPTED from COMPLETED.
  Verified: no routine file writes to Firestore, there is no routine collection in
  `firestore.rules`, and completion DELETES the run. A tap-only routine leaves zero trace whether
  it is done or ignored. E has to pick between cheap journal rows and a real `routine_runs`
  history, which is Arc 2 arriving early.
- **The ON-SCREEN half of the unhittable-row defect** ([[tab-root-rows-not-hittable]]). A row at
  y=572/584 on an 874pt screen, settled, not hittable. Sharpest lead, captured once: everything
  inside `AppTabContent` dead while the tab bar and capture disc were live at the same instant.
  A probe never caught it in 60+ rounds. **Build a reproducer before changing anything.**
- **The light-mode keyline.** NOT a token problem — both appearance variants carry byte-identical
  `#FF6B00` and there is no light branch in the code. Needs E's device compare (check 8). Do not
  tune the colour again until that is answered.
- **A real leak:** the routine run store is app-local `UserDefaults` and survives SIGN-OUT, so one
  account's place name can surface on another account's Today. It contaminated two test runs.
  Small fix, worth a block, matters more given [[public-launch-intent]].
- **Arc 2 — first-class routines + the "at a time" trigger.** Designed in outline, NOT authorised.
  The one that unlocks E's morning routine.

## 5. Housekeeping a fresh session should know

- `ADHD LifeOSUITests/HitTestProbeUITests.swift` is a **PROBE, not a guard** — it never fails, it
  prints and attaches. It costs 2–7 minutes of every full UI run. Delete it or make it a real
  assertion once the on-screen defect is understood.
- `TODO-CLAUDE-CODE.md` is Cowork's file. Block A is **not** recorded there as a FEATURE block;
  adding it needs E's authorisation. The routines close-out checkbox IS ticked with the merge
  evidence.

## Traps this arc paid for

- **A permission prompt in a test host has nobody to answer it.** A bare `requestAuthorization`
  in `PlaceTriggerTestFire` hung the unit suite for nineteen minutes; a wedged run and a slow run
  look identical until you read the clock. Make it a seam.
- **`Task.yield()` counting is a flaky harness, not a green one.** `PlaceRoutineActivator` is a
  CLASS so its auto-run `Task` can be HELD and awaited.
- **A tight `while !x.isHittable { app.swipeUp() }` loop does not scroll** — each gesture is
  issued while the previous is in flight and is swallowed, while a `LazyVStack` builds the row
  ahead anyway, so it exists at a plausible frame and is off screen. **Check the frame against
  `app.frame` height before theorising.** The suite now has zero such loops;
  `UITestSession.scrollUntilHittable` is the one implementation.
- **`xcodebuild … > log 2>&1; echo $?` after a redirect reports the SHELL's status**, not
  xcodebuild's. Read the log.
- **Erase the simulator between UI runs.** A non-erased sim carries the previous run's delivered
  notifications AND its live run.
- **A tab keeps its navigation stack**, so a second visit lands inside the pushed screen with no
  door — reads exactly like a render failure.
- **File-length watch:** `HomeView.swift` 398/400, `HomeMomentumSections.swift` 399/400,
  `RootView.swift` ~386/400, `UITestSession.swift` 378/400. Anything new goes in its own file.

## Standing rules unchanged

Per block: failing test first, suite green, `swiftlint lint` 0, red-check with the injected
regressions COUNTED, commit AND push, paste the close-out triple, then STOP for E's review. Never
script a sign-in. Never `&&` a commit onto a piped build. Commit BEFORE any deliberate regression.
Manual Xcode steps are E's.

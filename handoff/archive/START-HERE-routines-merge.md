# Start here — the Routines arc, ready to merge (Block A shipped, one thread parked)

> # ⚠️ SUPERSEDED — do NOT paste this into a fresh session.
> **The current opener is `START-HERE-post-routines.md` / `PASTE-post-routines.md`.**
> This file's state gate expects `f9f7b24` on `feature/routines`; main is now `705fb43` and that
> branch is merged, so the gate here will look like a failure when nothing is wrong. Keep this
> file only as the record of HOW the arc landed.
>
> **MERGED TO MAIN `0cea871` on 2026-09-05.** This file is now the record of HOW the arc landed,
> not a to-do list. The merge is done, re-verified on main (unit **2,326/0**, lint **0/672**, both
> targets build), and pushed. `feature/routines` is KEPT, not deleted.
>
> **Still open after the merge:** E's Block A device walk (the installed build's app source is
> byte-identical to main, so that walk still counts); reinstalling `wishwashwacky15` from a MAIN
> build; **Block B** — its own "Routines" section on the Tools list; the light-mode keyline; the
> ON-SCREEN half of the unhittable-row defect; and the run-store-survives-sign-out leak.

*Paste into a fresh Claude Code session. Written 2026-09-05 ~04:00 at the end of the Block A
session, on `feature/routines` @ `f9f7b24`, **18 commits ahead of main**. The arc is BUILT, round
2 is WALKED, Block A is SHIPPED, and the five pre-existing UI failures are BISECTED as not-ours.
Do not rebuild any of it.*

Read `claudecode.md` and `CLAUDE.md`, then the auto-memories `routines-next-arc`,
**`tab-root-rows-not-hittable`** (written this session, and it is the one that will save you a
day), `never-destroy-uncommitted-work`, `build-machine-limits`, `ui-test-cross-run-state`,
`device-build-lag`, `never-automate-auth-flows`, `public-launch-intent`.

`START-HERE-routines-close.md` is the PREVIOUS opener. Its traps list is still accurate, but
**its "expected notification body" is now WRONG — Block A changed the copy deliberately.**

## State gate — run before anything

```bash
git status --short                            # must be empty
git log --oneline -1                          # expect f9f7b24
git log --oneline -1 origin/feature/routines  # same SHA
swiftlint lint                                # expect 0 violations, 672 files
./scripts/emulators.sh                        # SECOND TERMINAL — UI tests SKIP without it
```

Baseline: unit suite **2,326 / 0**, lint **0 / 672**, both targets build. E's iPhone
`wishwashwacky15` carries **`9cff2b7`** (Block A), installed and launch-verified 00:52.
**The phone is on the BRANCH, not main** — put it back on main after the merge.

## The three commits this session added

```
9cff2b7  F-Routines-BlockA: the crossing offers the routine, the tap creates it
90aaad7  WIP: the "unhittable row" is a SCROLLING defect in the tests, not in the app
f9f7b24  WIP: scrolling fix lands FirstRunJourney; the ON-SCREEN case is still unexplained
```

## 1. The bisect — THE MERGE IS NOT BLOCKED BY A REGRESSION

All five UI failures reproduce at `2c46ee7`, the pre-session baseline. **None is ours.**

| Test | on branch | at `2c46ee7` |
|---|---|---|
| `AccountNameJourneyUITests` | failed | failed |
| `CaptureDiscClearanceUITests/testNudges_…` | failed | **failed** |
| `FirstRunJourneyUITests/testNewAccount_…` | failed | **failed** — *now FIXED, see §3* |
| `RenderHarnessUITests/testRenderNewNudgeSheet` | failed | **failed** |
| `RenderHarnessUITests/testRenderSignUpForm` | failed | **failed** (*"Keyboard never appeared"*, verbatim) |

The `scoreboardSection` padding theory is dead: that padding is on Today, the failing assertion is
on the Nudges screen.

## 2. Block A — DEFERRED LOGGING, SHIPPED `9cff2b7`

A crossing that qualifies as a routine now writes **nothing**. The run, Today's card and the
journal line come into existence only when the notification is **tapped**; swiping the banner away
leaves no trace. E confirmed that consequence explicitly when challenged.

**How the trap was solved.** The notification carried only a run UUID the router resolved against
the store — with nothing written there is nothing to resolve. The whole frozen run now rides the
userInfo as JSON (`place_routine_run_json`, the `place_action_json` precedent) and
`PlaceRoutineActivator` turns it into a real run. The bare `place_routine_run_id` is STILL carried:
the door's stale rule reads it, and a banner delivered by the previous build carries nothing else.

**E's three scope answers, each pinned by a test so a later reading cannot take them along:**
- the silent `location_events` record STILL writes at the crossing — sensing, not logging;
- ending a live arrival run on its departure crossing STILL happens at the crossing — a deletion,
  never a creation. Defer it and "ROUTINE LIVE" haunts Today until midnight;
- **routines only.** A crossing with no routine to initiate auto-runs exactly as shipped.

**Free win:** with the nudge master switch OFF a routine crossing now writes nothing AND spends no
cooldown. That open item was raised twice and never vetoed; deferral settles it.

**Copy changed on purpose.** `Journaled "Leg day"` → **`Will journal "Leg day"`**. The screen's
`Ran by itself when you arrived` → `Ran by itself when you started`, losing its direction with it.

**Two things the block could not be walked without:**
- the test-fire dialog gained **"Open the routine notification"** — it does not simulate a tap, it
  performs one, reading the DELIVERED notification and handing it to the same router iOS would. It
  polls (10 × 300ms) because the post lands a beat after the dialog dismisses;
- test-fire now REQUESTS notification permission, because the place-trigger path never did and
  `UNUserNotificationCenter.add` fails SILENTLY when notDetermined. **The request is an injectable
  seam: as a bare call it HUNG the unit suite for nineteen minutes**, because a permission prompt
  in a test host has nobody to answer it.

## 3. The "unhittable row" — TWO defects wearing one signature

**Check the reported frame against `app.frame` height BEFORE theorising.** That one step separates
them, and not doing it cost a day.

| frame | screen | verdict |
|---|---|---|
| y=1133, y=1377 | 874 | **off screen** — the swipe never scrolled. SOLVED. |
| y=572, y=584, y=181 | 874 | **on screen**, settled, still dead. UNEXPLAINED. |

**SOLVED half.** `app.swipeUp()` in a tight loop is swallowed — the gesture is issued while the
previous is still in flight — while a `LazyVStack` builds the row ahead of the viewport anyway. So
the element exists, at a plausible frame, and is simply off screen. Probe A/B, 12 rounds each,
same account, one variable: settle 0.5s → y=452, hittable **12/12**; tight loop → y=1133, dead
**12/12**. Five copy-pasted loops are now one `UITestSession.scrollUntilHittable`
(`ADHD LifeOSUITests/UITestScrolling.swift`). Selecting the tab before scrolling **fixed
`FirstRunJourneyUITests`**, which had failed for two sessions.

**UNEXPLAINED half, and this is where a fresh session should start if it picks the thread up.**
`homeManageNudgesRow` at y=572/584, settled, on screen, not hittable. The sharpest lead, captured
once: `toolsCard.places` at y=181 dead **while the tab bar and capture disc were hittable at the
same instant** — everything inside `AppTabContent` inert, everything outside it live. That points
back at `AppTabContent`, which was wrongly ruled out early. **The probe never caught that state in
60+ rounds. Build a reproducer for it BEFORE changing anything.**

**Why the thread was parked:** run-to-run results moved more than the code changes did —
`testRenderNewNudgeSheet` passed in one run and failed in the next with no edit between. At that
sample size a fix cannot be told from noise.

`ADHD LifeOSUITests/HitTestProbeUITests.swift` is a **PROBE, not a guard** — it never fails, it
prints and attaches. Delete it or turn it into a real assertion once the second half is understood;
it costs 2–7 minutes of every full UI run in the meantime.

**`testToday_theLastCardIsNotUnderTheCaptureDisc` now fails HONESTLY** at a new vacuity guard
instead of passing on a row 500pt below the fold. Red, but truthful — it was lying before.
That is [[geometry-journey-vacuity]] in the one file that already carried it once.

## 4. What is waiting on E

- **The Block A device walk** — checklist at `ON-DEVICE-CHECKLIST-blockA-2026-09-05.md`, already
  sent. Checks 1–5 essential; check 1 IS Block A. **Check 8 is the light-mode keyline compare.**
- ~~**Block B's scope**~~ — **ANSWERED 2026-09-05: "the routines section deserves its own
  'Routines' section on the Tool list."** First-class entry on Tools, presented as Routines, not
  folded into Places. The data model is still open under it: propose a section listing the
  routines each place WOULD produce (one row per place+direction over the 2-step threshold, place
  as subtitle) — that reads as Routines and needs no new entity. First-class routine RECORDS are
  Arc 2 and remain unauthorised.
- ~~**The merge call**~~ — **APPROVED by E 2026-09-05**: merge on the bisect evidence.

## 5. The light-mode keyline — still open, and NOT a token problem

`IslandKeyline` was READ this session: both appearance variants carry byte-identical `#FF6B00`,
and `.keylineTint` is the only mechanism — the island's shape is not otherwise styleable. Not a
stale build either. So it is an iOS behaviour, and the next step is E's device compare, light vs
dark, one fresh Activity. **Do not tune the colour again until that is answered** — three passes
have already moved a value both variants share.

## 6. The merge, once E blesses it

Full re-run (unit suite + UI target with the emulator up) → `--no-ff` into main → **re-verify ON
main** → push → reinstall `wishwashwacky15` **from main** → **ask before deleting the branch**
(E said keep it for now). Then update `routines-next-arc` with the merge SHA and raise **Arc 2 —
first-class routines + the "at a time" trigger**, designed in outline and NOT authorised.

## 7. Queued after the merge — a real leak found while debugging

**The routine run store is app-local `UserDefaults` and survives SIGN-OUT.** One account's place
name can surface on another account's Today; it contaminated two test runs this session. Small
fix, real leak, and [[public-launch-intent]] makes it worth a block.

## Traps this session paid for

- **A permission prompt in a test host has nobody to answer it.** A bare
  `requestAuthorization` in `PlaceTriggerTestFire` hung the unit suite for nineteen minutes —
  a wedged run and a slow run look identical until you read the clock. Make it a seam.
- **`Task.yield()` counting is a flaky harness, not a green one.** Three yields drained the
  activator's auto-run task in a test that settled twice and failed in one that settled once.
  `PlaceRoutineActivator` is a CLASS so the `Task` can be HELD and awaited.
- **`xcodebuild … ; echo $?` after a redirect reports the SHELL's status, not xcodebuild's** —
  a run reported exit 0 with two test failures in the log. Read the log, not the code.
- **Erase the simulator between UI runs.** A non-erased sim carried the previous run's delivered
  notifications AND its live run (app-local UserDefaults), and both journeys failed on state that
  was not theirs.
- **A tab keeps its navigation stack**, so a second visit lands inside the pushed screen with no
  door — reads exactly like a render failure. The first version of the probe fell for it.
- **File-length watch:** `UITestSession.swift` hit 400 and the new helper went to its own file.
  `HomeView.swift` 398/400, `HomeMomentumSections.swift` 399/400, `RootView.swift` ~386/400.

## Standing rules unchanged

Per block: failing test first, suite green, `swiftlint lint` 0, red-check with the injected
regressions COUNTED, commit AND push, paste the close-out triple, then STOP for E's review. Never
script a sign-in. Never `&&` a commit onto a piped build. Commit BEFORE any deliberate regression.
Manual Xcode steps are E's. `TODO-CLAUDE-CODE.md` is Cowork's file — Block A is NOT recorded there,
and adding it needs E's authorisation.

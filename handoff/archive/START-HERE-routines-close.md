# Start here — closing the Routines arc (last checks → merge)

*Paste into a fresh Claude Code session. Written 2026-09-04 ~05:00 at the end of the round-2
field-walk session, on `feature/routines` @ `07d1185`. **The arc is BUILT and round 2 is mostly
WALKED. One real defect was found and FIXED. What remains is two checks, then the merge.**
Do not rebuild any of it.*

Read `claudecode.md` and `CLAUDE.md`, then the auto-memories `routines-next-arc`,
`mirroring-cannot-scroll` (**rewritten this session — the old claim was wrong**),
`live-activity-design-review-owed`, `never-destroy-uncommitted-work`,
`never-automate-auth-flows`, `dead-shared-component-pattern`, `build-machine-limits`,
`device-build-lag`, `public-launch-intent`.

`START-HERE-routines-fieldwalk.md` (same directory) is the PREVIOUS opener — its traps list is
still accurate and worth reading. `SESSION-OPENER-routines-build.md` is still the spec.

## State gate — run before anything

```bash
git status --short                            # must be empty
git log --oneline -1                          # expect 07d1185
git log --oneline -1 origin/feature/routines  # same SHA
swiftlint lint                                # expect 0 violations, 664 files
```

Baseline on the branch: unit suite **2,311 / 0**, SwiftLint **0 / 664**, both targets build.
E's iPhone `wishwashwacky15` carries **`07d1185`**, installed and launch-verified 04:5x.
**The phone is on the BRANCH, not main** — put it back on main after the merge.

The Firebase emulator must be up for any UI test: `./scripts/emulators.sh` in a second terminal.
Without it the journeys SKIP rather than fail.

## What this session added — six commits on top of `2c46ee7`

```
582cff7  ring breathing room + the fixture the lifecycle test missed
f370219  narrow the compact island, move the ring padding off HomeView
e42791a  amber keyline (+ the asset-exists guard test)
968f601  island content fits its box; keyline goes gold
4dd8f75  keyline to #B4520A — brighter was the wrong lever
577b43c  keyline to vivid orange #FF6B00 (E's pick)
07d1185  THE REFRESH FIX — the change signal was a factory
```

## The defect that was found and fixed — read this before touching DataChangeSignal

Round 2 found that a **departure crossing updated the run store correctly but Today kept the
stale arrival card** until the app was backgrounded and reopened.

`DataChangeSignal.debouncedPublisher()` was a FACTORY. Every SwiftUI body evaluation built a new
`NotificationCenter → debounce` chain and `onReceive` resubscribed, so a body evaluation inside
the 600ms window tore the pending value down. **Switching tabs is a body evaluation**, and it is
exactly what you do between firing a crossing and looking at Today.

The debounce now lives in a permanently-retained pipeline feeding a `PassthroughSubject`; nine
screens subscribe downstream via **`DataChangeSignal.changes`**. The parameterised factory
survives, marked test-only.

**Why the arrival looked fine, which is what made it hard to see:** an arrival runs a journal
auto-step, which writes to Firestore and posts a SECOND signal after the tab switch settles. A
departure of tap-steps writes nothing. The bug was always there; the arrival path had a spare.

Pinned by `RoutineRefreshJourneyUITests` (red first, then green in 134s) and two unit tests in
`DataChangeSignalTests`.

## What E still has to walk — only two left

Everything else passed on E's device, driven through iPhone Mirroring:

| # | Check | Result |
|---|---|---|
| 1 | Today card | PASS — `AT ROUTINES TEST · ROUTINE LIVE`, count excludes the journal step |
| 2 | Auto-run pre-ticked | PASS on the SCREEN; **notification body never seen** |
| 3 | Departure ends the run | Behaviour PASS; the refresh defect it exposed is now fixed |
| 4 | Skip + Undo | PASS — no confirm dialog, skip resolves without counting as done |
| 5 | Tap the Live Activity | PASS — reopens on the routine screen, state intact |
| 6 | One tap-step regression | **NOT RUN** |
| 7 | Island keyline + `1/2` | Count PASS (`1/3` untruncated); keyline still being tuned |

**Check 6** — fire `Simulate departure` on "Action Test 01/09/2026" (it has exactly one
departure tap-step, Open Shortcuts). Expect the OLD per-action notification, no routine, no
Today card.

**Check 2's notification body** — expect
`You're at <Place>` / `<message> · Journal "<line>" · 2 steps ready — <a> · <b>. Tap to run.`

## ⚠ THE UI TARGET IS NOT GREEN — resolve this BEFORE the merge

The full UI run was killed part-way (background tasks kept being stopped), reaching **19 cases
with 5 failures**. Do not read the arc as merge-ready until this is settled.

```
RoutineJourneyUITests …                        passed (120.4s)   ← sibling, unaffected
RoutineRefreshJourneyUITests …                 passed (124.9s)   ← the refresh fix holds

AccountNameJourneyUITests …                    failed — settingsButton never went away
CaptureDiscClearanceUITests/testNudges_…       failed — New nudge row (y 677.7–731.7)
                                                        under the capture disc (y 690–750)
FirstRunJourneyUITests/testNewAccount_…        failed — homeManageNudgesRow never went away
RenderHarnessUITests/testRenderNewNudgeSheet   failed — same row
RenderHarnessUITests/testRenderSignUpForm      failed — keyboard never appeared
```

**What has been ruled OUT:**
- *Cross-test contamination.* `testRenderLandscapeSweep` runs just before them and orientation
  outlives a run ([[ui-test-cross-run-state]]) — but three of them still fail **in isolation on a
  freshly-erased simulator**, so that is not it.
- *The `DataChangeSignal` change.* Both routine journeys pass, and they are the ones that
  exercise the new `changes` stream hardest.

**What is CONFIRMED pre-existing:** `AccountNameJourneyUITests` was re-run at `2c46ee7` — the
pre-session baseline, before any change this session — and **failed there too**. It is not a
regression from this work.

**What is still UNKNOWN:** whether the other four are pre-existing. The baseline run was killed
after one case. **Finish that bisect first:** detach to `2c46ee7`, run the remaining four, then
`git checkout feature/routines`.

The one that deserves the most suspicion if it turns out NOT to be pre-existing is
`CaptureDiscClearanceUITests` — this session added `.padding(.vertical, 8)` to
`scoreboardSection`, which shifts everything below the ring on Today down by 16pt, and that test
is a geometry assertion about a row sliding under the capture disc. It is a real mechanism, not
a hunch; it just has not been proven either way.

## E's four answers (2026-09-04) — three DONE, one is a new block

1. **Kill-switch / when things get written** → E rejected the premise. **See "Block A" below.**
2. **Arrival card suppression** → **VETOED. "i want it shown."** Done in `33e2e50`:
   `suppressesArrivalCard` deleted, both cards render, one source pin replaces three value tests.
3. **Revert the "routines test" place?** → **Keep it.** Nothing to do.
4. **Delete the branch after merge?** → **Keep it for now.**

## Block A — DEFERRED LOGGING (E's spec, confirmed twice, NOT built)

> "The routine card and journal logging must only happen after the notification has been tapped."
> "Only logging when action is actually taken via the notification to initiate the routine."

E was asked directly about the consequence and confirmed it: **swiping the banner away must
leave NO trace** — no journal line, no card, no record. That is intended, not an oversight.

**Today's behaviour, which this reverses:** the crossing runs the auto-run actions (journal
lines, captures) and writes the run immediately; the notification REPORTS what already happened
(`Journaled "Leg day"`).

**The target:**
- crossing → post the notification, write NOTHING
- tap → create the run, run the auto-run steps, open the screen
- swipe → nothing, ever

**The trap, and it is the whole difficulty.** The notification currently carries ONLY a run
UUID (`PlaceRoutineNotificationContent.userInfo(for:)` → `[runIdUserInfoKey: run.id]`) and the
router resolves it against the store (`PlaceRoutineNotificationRouter:37`). With nothing written
at the crossing there is no run to resolve, so every tap would hit the stale-tap rule and open
Today. The userInfo must widen to carry enough to CREATE the run — place id, direction, the
crossing time, and a run UUID minted at POST time.

**Keep minting a UUID.** The build plan's warning still applies: never key on a composed
`placeId|direction|Date`, because a Date serialised two ways makes every tap mismatch. Mint the
id when posting, carry it, and use it when the tap creates the run.

**Copy must change.** `Journaled "Leg day"` is past tense reporting a completed write. Nothing
has run at post time, so that line either goes or becomes forward-looking. The screen's
`Ran by itself when you arrived` also needs rewording — the step now runs when the routine
STARTS, which is the tap.

**One question E has NOT answered:** does the silent `location_events` timeline record still get
written at the crossing? It is a different species from a journal line — sensing, not a
user-visible log — so the argument for keeping it is strong, but E said "only logging when
action is taken". **Ask before assuming.**

## Block B — A ROUTINES SECTION ON THE TOOLS TAB (E's ask, NOT designed)

E wants routines reachable from Tools, and flagged it as larger and wanting its own session.
**That instinct is right, and the reason is worth stating:** a routine today has no independent
existence — it IS a place's actions for one direction, computed on the fly by
`PlaceRoutinePlan.make`. There is no routine entity to list. A Tools section therefore either
lists PLACES that would produce a routine (cheap, honest, a bit indirect) or requires
first-class routines — which is **Arc 2**, already designed in outline and not authorised.

Establish which of those E wants BEFORE writing any code.

## Open with E, not decided

- **The light-mode keyline.** E's 04:39 screenshot shows the island in LIGHT mode with **no
  border at all**. This is NOT a token problem: `IslandKeyline` carries `#FF6B00` in BOTH
  appearance variants, so a variant mismatch cannot explain it. Unverified theory: the Activity
  in that shot was started under an older build — `577b43c` was installed while the phone was
  locked and never launched until 04:50. **Cheapest next step: end the Activity, launch
  `07d1185`, start a fresh routine, and compare light vs dark.** Do not change the colour again
  until that is ruled out.
- **Unify the count with the keyline.** The count inside the pill is still the blue app accent
  against an orange edge — two accents on a few millimetres. Offered, not built; E has not asked.
- **Kill-switch OFF still writes the run.** Stated twice, never vetoed. NOTE: test-fire forces
  the master switch ON, so this cannot be walked from the couch — it needs a real crossing.
- **A live routine suppresses that place's `ArrivalSurfaceCard`.** Stated, never vetoed.
- **E's "routines test" place was modified for the walk** — arrival gained Journal "Leg day",
  Open Apple Maps, Open YouTube, message "Time to train", and arrival nudges ON. Departure
  (Spotify, Health) untouched. Ask whether to revert.

## The merge, once E blesses it

Full re-run (unit suite + the whole UI target with the emulator up) → `--no-ff` into main →
**re-verify ON main** → push → reinstall `wishwashwacky15` **from main** → **ask before deleting
the branch**. Then update the `routines-next-arc` memory with the merge SHA and raise **Arc 2 —
first-class routines + the "at a time" trigger**, which is designed in outline and NOT
authorised. It is the one that unlocks E's morning routine.

## Also produced this session — two artifacts, neither authorised as work

- **Away Receipts** — `claude.ai/code/artifact/7297a406-a2f3-44be-9b24-22ac3cd9f4e4`. E asked
  where the "sprint finished while you were away" card should be reused. It is the ONLY instance
  of that pattern in the app. Headline finding: **with the nudge master switch off, a crossing
  writes journal lines and captures and tells the user nothing** — `ranLines` is only ever
  surfaced through notifications, both paths inside `if isEnabled()`
  (`PlaceTriggerEventHandler.swift:109`). Ranked candidates and what to reject are in the doc.
- **Keyline Candidates** — `claude.ai/code/artifact/164edfec-fab6-4b2b-9967-0643acaa86b1`.

## Traps this session paid for

- **iPhone Mirroring CAN scroll** — with a real CGEvent scroll **WHEEL**, cursor parked in the
  window (E's suggestion). Drags down the centre get eaten by inner scrollables. Helper at
  `scratchpad/edge_scroll.py`. The island also renders, expands on long-press, and is tappable.
  The old `mirroring-cannot-scroll` memory has been rewritten.
- **`type_text` PASTES and fails silently in this app's fields** — use `keystrokes=True`.
- **After a wheel scroll, RE-READ the target's box before tapping** — momentum moves it, and a
  tap landing near the home indicator drops you to the Home Screen mid-sequence.
- **A tab keeps its navigation stack.** Returning to Tools lands back INSIDE Places with no door
  to tap; waiting for the door hangs to the timeout and reads exactly like a render failure.
- **`Color("…")` resolves at RUNTIME.** A missing colorset is not a build error — it renders a
  fallback. `BUILD SUCCEEDED` proves nothing; check `Assets.car` with `assetutil`, and pin the
  asset's existence in a test (the name-check test passed happily with the asset deleted).
- **The keyline's lever is SATURATION, not luminance.** iOS renders it at ~40% of the specified
  colour. `#FFD60A` had the HIGHEST rendered luminance and looked DULLEST, because as red and
  green converge the hue collapses to mud. The predictor is the **green-to-red ratio**, which is
  scale-invariant and survives being measured off a rescaled screenshot.
- **Watch `cd` in compound Bash.** A `cd` inside a loop left the shell in `ADHD LifeOS/`, after
  which `swiftlint` linted 352 files instead of 664 and `xcodebuild` reported the project did
  not exist. Both looked like real failures.
- **File-length watch:** `HomeView.swift` 398/400, `HomeMomentumSections.swift` 399/400,
  `RootView.swift` ~386/400. A four-line comment tipped HomeView over this session. Anything new
  goes in its own file.

## Standing rules unchanged

Per block: failing test first, suite green, `swiftlint lint` 0, red-check with the injected
regressions COUNTED, commit AND push, paste the close-out triple, then STOP for E's review.
Never script a sign-in. Never `&&` a commit onto a piped build. Commit BEFORE any deliberate
regression. Manual Xcode steps are E's. The device signed cleanly all session with
`-allowProvisioningUpdates`.

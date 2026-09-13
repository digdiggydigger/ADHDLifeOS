# START HERE — finish `F-CTACelebrations-6` at **C6** (the wiring and the R1 reversal)

*A disposable pointer (CLAUDE.md, "Session handoff"): paste this path into a fresh Claude Code
terminal. **WRITTEN 2026-09-13** by the session that built C1–C5 and E's new detail section. It
archived its own predecessor (`handoff/archive/START-HERE-cta-celebrations-6.md`) in the same move
that wrote this. The session that finishes the block archives THIS one when it writes the next.*

**The branch is `feature/cta-celebrations-6`, pushed, 13 commits, tree clean.** It is **NOT merged
and must not be merged as it stands** — see "Why main is untouched" below. Check it out and start at
C6.

```bash
git checkout feature/cta-celebrations-6 && git pull --ff-only
```

## State at handoff

| | |
|---|---|
| branch head | `0ea2154` (13 commits ahead of `main` @ `8c6cfc0`) |
| unit suite | **2,941 / 0**, emulator UP, **0** `127.0.0.1:9099` hits |
| SwiftLint | **0 / 801** |
| sim build | `** BUILD SUCCEEDED **` |
| `PlaceRoutineScreen` type body | **209 of 250** — 41 lines of headroom for C6 |
| `PlaceRoutineScreen` file length | 300 of 400 |
| UI journeys | **NOT RUN this session.** C8 runs them. |
| device | **NOT installed this session.** E has seen renders only. |

**Why `main` is untouched, and it is deliberate.** C5 landed
`PlaceRoutineCompletedCard`, which is **tested and reachable by nothing** until C6 wires it into the
slot. Merging now would ship this repo's most-repeated defect shape (six recorded instances) on
purpose. Finish C6 first.

## ⚠ THE BLOCK GREW. E added a whole feature mid-build, and it is built.

E, 2026-09-13, unprompted: *"i want to add a small section within the empty-space on the cards that
display detailed data and info about that specific routine that was run."* That is now
`PlaceRoutineCongratulationDetails`, and answering it took **nine more decisions from E**, five of
which reverse or override something already settled. **Do not re-derive any of them.**

### E's decisions this session — all landed

| # | question | E's answer |
|---|---|---|
| 1 | Which "started"? | **BOTH lines** — the crossing (`Arrived`) and the tap that opened it (`Started`). |
| 2 | Which "finished"? | **BOTH lines** — `Last step` and `Confirmed`. |
| 3 | Which facts? | Total time, **time per step**, **compare to your usual**. |
| 4 | Long routines | **The step list SCROLLS.** ⇦ **reverses E's own answer 6** ("shrink to fit, no scrolling"). |
| 5 | The 5.4 s auto-leave | **"Stays until dismissed."** ⇦ **reverses R5's auto-leave.** |
| 6 | Detail block placement | **Pinned under the summary**, above the scroller. |
| 7 | Light-mode wash | **0.40** — chosen by sight from a rendered ladder. Dark stays **0.14**. |
| 8 | Clock format | **"1:00 pm"** — 12-hour, minutes always, **no seconds**. ⇦ **reverses E's own `hh:mm:ss`.** |
| 9 | Border / verdict colour | Detail card gets a **done-green tinted** border; "Longer than usual" is **accent blue**. |

Plus: *"reword the 'Skipped 2m'"* → rows now read `Done in 2m` / `Skipped after 2m` / `Auto` (no
number — an auto step always resolves instantly).

### Consequences already absorbed, so you do not rediscover them

- **`PlaceRoutineCongratulationLength` is DELETED.** With no timer there is no `hold(for:)` and no
  `quietBeat`. **E's answers 1 and 7 survive only in the CONFETTI dimension** — R-f's unearned run
  and the switch being OFF are no longer "shorter", they are "no confetti".
- **`estimatedHeight` / `listBudget` are DELETED** — with scrolling there is no ceiling to name. The
  density table SURVIVES (a judgement: shrinking means fewer routines need scrolling at all).
  `testTheDensityTableStillShrinksSoFewerRoutinesNeedScrollingAtAll` says so and invites E to
  overrule.
- **The copy is "Close", not "Skip"** — with no timer there is nothing to skip. `closeHint` is
  load-bearing: nothing will rescue a user who cannot find the way out.
- **The clock OVERRIDES the reader's locale** (`en_US_POSIX`, `"h:mm a"`, lowercased). That IS E's
  rule: `en_GB`/`de_DE`/`fr_FR` all default to 24-hour.

## What is built (C1–C5 + the detail arc)

`PlaceRoutineCompletion.swift` (copy, entrance, density, wash), `PlaceRoutineRunTimeline.swift`
(the four moments, per-step durations, the comparison, the formatters),
`PlaceRoutineCongratulationView.swift`, `PlaceRoutineCongratulationDetails.swift`,
`PlaceRoutineCompletedCard.swift`, `PlaceRoutineScreenPreviews.swift`,
`PlaceRoutineScreen+Opening.swift`; `PlaceRoutineStepCircle` gained `var size: CGFloat = 28`;
`PlaceRoutineSubline` moved out of the screen; `RoutineStepState` gained `CaseIterable`.

## ⚠ C6's THREE BOOBY-TRAPS — and the third is WORSE than the old plan said

1. **Adjacency.** `RoutineRecordCallSiteTests.testLeavingAFinishedScreenRecordsCompletion` reads the
   screen comment-stripped and whitespace-collapsed and asserts
   `"store.end(runId: run.id) record { try await recorder.ended(runId: run.id, reason: .completed"`.
   **NOTHING may sit between those two statements** — not `hasRecordedEnd = true`, not the haptic,
   not `dismiss()`. The haptic goes BEFORE `store.end`.
2. **Unique anchor.** `CelebrationPopCallSiteTests.testEachRoutineStepsActionPops` anchors on
   `"Button(title) { Haptics.play(.solid)"` and requires **exactly one** occurrence in
   `PlaceRoutineScreen.swift`. Do not write a second button that shape in that file.
3. **The `leaveScreen()` count is 5 and it does NOT simply become 4.**
   `HomeRoutineCardCallSiteTests.testEveryExitFromTheScreenEndsTheRunItself` reads **RAW** source
   (comments included) and asserts exactly 5. The five are:

   | line | what |
   |---|---|
   | `:82` | **a COMMENT** — "every deliberate exit calls `leaveScreen()` itself" |
   | `:84` | `.onDisappear { leaveScreen() }` |
   | `:90` | the scenePhase hook — **C6 DELETES this** |
   | `:106` | the Close button |
   | `:309` | the declaration |

   **C6 deletes the scenePhase hook AND rewrites the `:77-83` comment block**, which contains the
   `:82` occurrence. Do both and the count is **3, not 4**. **`grep -c 'leaveScreen()'` after your
   edits and set the expected number to what is actually there**, with the message re-enumerating
   the sites. Do not trust either 4 or 3 in advance.

   It also asserts a whitespace-exact `"leaveScreen()\n" + 20 spaces + "dismiss()"`. **That survives
   only because the Close button lives in the separate `private var header` member** — keep `header`
   a member, do not inline it into `body`.

## C6 — the wiring, in one commit

- `complete(from origin: CGPoint?)` in `PlaceRoutineScreen.swift` (**NOT** a `+Completion.swift`
  extension — `private` is file-scoped, so `run`/`store`/`recorder`/`hasRecordedEnd` are invisible
  from another file).
  Order: `Haptics.play(.success)` → `hasRecordedEnd = true` → **`store.end(runId: run.id)` then
  `record { try await recorder.ended(...) }` ADJACENT** → `activity.ended()` →
  `DataChangeSignal.post()` → capture `confirmedAt` into `@State` → `celebrate.request(.milestone(.routineFinished), at: origin)`.
- **Capture `confirmedAt` ONCE in `@State`.** Read from `body` as `.now` it would tick, and the view
  now stays until dismissed.
- The slot branch: when `PlaceRoutineProgress.nextPendingIndex(run) == nil` and the run is fully
  resolved, show `PlaceRoutineCompletedCard(run:onComplete:)` where `nextCard(at:)` would be.
- **The body swap is a `ZStack`, and it is load-bearing.** A `Group` would re-fire
  `.task { activity.started(run) }` and restart the Live Activity moments after `complete()` ended
  it — **and no test could see it**, because `RoutineActivityCallSiteTests` only asserts the string
  exists. Hang `.task` / `.onDisappear` / `.background` on the ZStack; `.transition` on each branch.
- **The entrance:** `PlaceRoutineCongratulationEntrance.resolve(reduceMotion:)` → `.spring` uses the
  screen's OWN existing spring (`response: 0.35, dampingFraction: 0.8`) + the house 0.9 scale;
  `.fade` is `.opacity` with `.easeOut(duration: 0.25)`. **This is the block's reduced site and it
  is why §7.3's RM-on device pass is owed.**
- **Delete** the scenePhase hook and `@Environment(\.scenePhase)`; gut `leaveScreen()` to
  `activity.ended()` + `DataChangeSignal.post()`.
- The init gains `displayName: String? = nil` **and** `history: RoutineRunHistoryReading`.
  **`history` must NOT be defaulted** — `FirebaseRoutineRunHistoryAdapter()` reaches
  `FirebaseManager.shared`, the same reason `recorder` is not defaulted. `RootView+Doors.swift`
  passes `FirebaseRoutineRunHistoryAdapter()` and `authService.signedInUser?.displayName`.
  `RoutineRecordCallSiteTests.testTheDoorHandsTheScreenARealRecorder` is the precedent to copy.
- **Six comments narrate the deleted rule and NOT ONE can go red** (`stripped()` removes comment
  lines before every guard reads): `PlaceRoutineScreen.swift:30-32`, `:77-83`, `:305-308`;
  `HomeRoutineCard.swift:27-29`; `HomeRoutineCardCallSiteTests:36-37`; `RoutineRunStoreTests:271-274`.

## C7 — `continueLabel` → `continueLabel(for:)`

E's answer 8 from the FIRST round: Today's card swaps its label when nothing is pending —
**"Finish routine" / "Continue routine"**. `HomeRoutineCardModel.continueLabel` is a `static let`
today, so this is a compile break in `HomeRoutineCardTests`. Same commit.

## C8 — the two journeys

**Both journeys resolve the gym routine as 1 auto + 3 skipped, so R-f is NOT earned and neither ever
sees confetti** — `testTheJourneysAutoPlusSkippedRunIsDeliberatelyUnearned` pins that. A journey
waiting on paper that never comes hangs to the timeout and reads exactly like a render failure.
Wait on `routineCongratulationGreeting` instead.

- **Reversed:** `RoutineJourneyUITests.testARoutineIsReachableFromTodayAndEndsWhenItIsFinished` —
  taps Close and asserts the Today card is GONE. Under R1 the card must **survive** Close. New
  shape: resolve all → Close → card survives → reopen via card → tap Completed → greeting appears →
  cover gone → card gone. **The test's NAME asserts the old rule too — rename it.**
- **Updated:** `RoutineRecordJourneyUITests.takeAndFinishTheGymRoutine` — tap Completed, not Close,
  or three downstream Journal assertions redden.
- **Tap a list ROW to dismiss, not the greeting.** That is the only way the tap-through-a-ScrollView
  claim gets exercised; a still can never show it.
- **`xcrun simctl erase 9181EBF9-0F54-4A4D-A19C-19945D1BF155` in the SAME command chain,
  unconditionally, before the unit suite.** A UI run poisons the sim and the next unit suite drags a
  Firebase client retrying against a dead emulator — 60–80 s per test, or killed for memory.

## C9 — evidence and close-out

`screenshots/cta-celebrations-block-6/` + README (the mandatory table: filename → what it proves),
`RoutineRunStoreTests`' stale name/comment, the TODO tick, the register, the successor opener, the
PR, E's device verdict.

## The render probe — rebuild it, and here is what THIS session learned

**No probe code survives. The scratchpad is gone.** Base recipe:
`screenshots/cta-celebrations-block-2/README.md` (scene-attached `UIWindow`, synchronous
`RunLoop.main.run(mode:before:)` pump, `window.overrideUserInterfaceStyle`, RGBA comparison not PNG
bytes, always render a control). Blocks 3–5 add: prove determinism FIRST; compare at a fixed `date`;
`.fixedSize` on a `minHeight`-flexible row; let the handle escape the wrapper's body;
`MILESTONE_PROBE_OUT` on the `xcodebuild` command line does NOT reach the test process — read the
path the probe PRINTS.

**Two this session added, both of which cost a run:**
- **A fixture built from `.now` cannot be rendered twice.** Two renders of one scene differed by
  **819 pixels** because the clock times moved between them. The determinism check caught it before
  any pixel claim was built on it. `PlaceRoutineCongratulationPreviewFixture.run` now takes
  `startedAt:` for exactly this reason — pass a fixed date.
- **The congratulation FETCHES**, so it is only deterministic with an inert or fake history reader.
  A probe-local `FakeHistory` returning one slower record of the same place+direction is what makes
  the comparison line render at all.

## Owed to E

- **§7.3's RM-on device pass is OWED** — C6 adds the reduced site (the entrance). Ask for BOTH
  passes in ONE message (RM off, then RM on) so E flips the setting once. Until then the line reads
  *"Reduced: run on sim (injected); NOT on device."*
- E has approved the congratulation **by render only**. Nothing in this block has been on a phone.
- **Device profile expires 2026-09-17.** E re-signs in Xcode → Settings → Accounts.

## Then, strictly in order

`F-CTACelebrations-7` (the chime; E picks by ear) → `F-CTACelebrations-Surfaces` (E's §0b answer) →
`F-FocusCard-Corners`.

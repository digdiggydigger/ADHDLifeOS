# START HERE — build `F-CTACelebrations-6` (the routine Completed flow, R1–R5)

*A disposable pointer (CLAUDE.md, "Session handoff"): paste this path into a fresh Claude Code
terminal. **REWRITTEN 2026-09-13** by a planning-only session that answered nine open questions with
E, mapped every test the block touches, and corrected three things the previous version of this file
got wrong. The session that writes this arc's next opener archives this file in the same move.*

**THIS BLOCK IS FULLY PLANNED. Do not re-derive it.** A planning session on 2026-09-13 put the open
questions to E, ran three exploration passes and one design pass, and landed the plan below. **Five
of E's nine answers are E's own wording or a reversal of what was offered — they cannot be
re-derived from the design record.** Read this file and `TODO-CLAUDE-CODE.md`'s block; you should not
need a fourth exploration pass.

**Nothing was built.** No feature code, no tests, no branch — `main` is at the planning commit and
the tree is clean. Branch `feature/cta-celebrations-6` from `main` and start at C1.

## STATUS of the arc

Blocks 1–6 are MERGED and **every shipped block has PASSED E's device verdict** — `-4` and `-5`
together on 2026-09-12 with Reduce Motion **OFF and ON** (E: *"both of those tests work
correctly!"*). Three follow-on blocks from that sitting are also merged: **`PopScale`**
(`popScale = 1.6`, E's by-sight value — **do not tune down**), **`NoCooldown`** (**E removed the
milestone cooldown entirely**; two milestones landing together now OVERLAP, capped at three), and
**`SwipeOrigin`** (a swipe pops from the finger).

**Nothing is owed from any shipped block except three unhurried device looks** (register §A). E has
passed everything before them, so **do NOT treat any of it as unverified work to redo.**

**E's settled decisions — do not re-litigate:** the VoiceOver announcement stays "daily goal only";
the Celebrations switch does not gate pops; airplane-mode + pull-to-refresh has been RUN and PASSED.
**Photosensitivity is DEFERRED by E and is a launch blocker by E's own instruction** (§A and §D) —
neither entry may be closed without E.

## Read first, in this order

1. CLAUDE.md's start-of-session checklist: `claudecode.md`, "Architecture notes" (it has a
   celebrations entry), and **§7** — especially **§7.3's RM-on device pass, which this block OWES**
   (it adds a reduced site: the congratulation's entrance under Reduce Motion).
2. **`handoff/OPEN-ITEMS-REGISTER.md`** — THE outstanding list.
3. **`handoff/SESSION-OPENER-cta-celebrations-design.md`** — the design record. For THIS block:
   **R1–R5**, **R-f**, **R-h**, and "Engineering constraints". **Read lines 96–273 as well as the
   R1–R5 table** — R-a…R-h and the Reduce Motion section live there, and a previous session read
   around them and missed R-f entirely.
4. `TODO-CLAUDE-CODE.md` — the block `F-CTACelebrations-6`, which carries E's nine answers.
5. `screenshots/cta-celebrations-block-2/README.md` — **the probe recipe. Block 2, NOT block 3**
   (see the correction below).

## ⚠ THREE CORRECTIONS to the previous version of this file

The `-5` session wrote this opener and got three things wrong. Each cost real time to discover.

1. **The probe recipe base is `screenshots/cta-celebrations-block-2/README.md`, not block 3.**
   Block 3's README says in terms *"Block 2's recipe still holds"*. The chain is **2 (base) → 3
   (four additions) → 4 (two) → 5 (the env-var trap) → pop-scale (none)**. The old pointer sent you
   to a layer of additions with no base under it.
2. **No probe code survives anywhere, and the scratchpad copies are GONE.** Blocks 5 and pop-scale
   both say "the copy used here is kept in this session's scratchpad" — those scratchpads no longer
   exist, and nothing matching `ZZ*` was ever committed (by design). The READMEs give API names and
   prose, **never literal code**. The probe is re-implemented from a spec. Budget for it.
3. **The room-first move is NOT what the design record describes, and the ceiling is not 400.**
   See the next section — this is the single most important correction in this file.

## ⚠ THE ROOM PROBLEM — the binding ceiling is `type_body_length` 250, not `file_length` 400

The design record and the old opener both say *"`PlaceRoutineScreen.swift` is at 384 of 400"*.
**Wrong ceiling.** `.swiftlint.yml` overrides neither metric, so both run at SwiftLint's defaults.
Measured 2026-09-13:

| metric | now | ceiling | headroom |
|---|---|---|---|
| file length | 382 | 400 | 18 |
| **type body** (lines 19–319, non-comment, non-blank) | **235** | **250** | **15** |

The two moves fix **different** ceilings, and you need both:

- **The `#if DEBUG` preview block (`:322-382`, 61 lines) is OUTSIDE the type body** → buys 61 *file*
  lines and **zero** body lines. Nine `*Previews.swift` files already exist; no test in either
  target references a preview, `PlaceRoutineScreenPreviewFixture`, `InertRoutineActivityPresenter`
  or `InertRoutineRunRecorder`.
- **`openExternally` (`:285-303`)** buys ~15 body lines *and* ~19 file lines. `private` → internal
  (a cross-file extension cannot see `private`).

**Even after both it is close:** body 235 → ~220, additions ≈30 → **≈251, one line over**.
**Measure after C2 and again before C6.** If it breaches, the next move is `subline` (`:136-142`) or
`perform(_:at:)`'s route switch — each needs `run` or the closures relaxed from `private`, so it is
a deliberate decision, not a reflex. **Do not discover this at the end.**

**And the design record's suggestion of a `+Completion.swift` for `complete()` CANNOT WORK** —
`private` is file-scoped, so an extension file cannot see `run`, `store`, `recorder` or
`hasRecordedEnd`. `complete()` stays in the main file.

## E's NINE answers, 2026-09-13 — five are E's own words

| # | question | E's answer |
|---|---|---|
| 1 | What R-f's "completes quietly" looks like | **Congratulation, no confetti, ≈2 s.** The run still ends and still records. Same beat as switch-OFF. |
| 2 | The congratulation's copy | **E's own design:** greeting + "…routine done — 3 of 4 steps", and **underneath, a per-step list** naming every step and whether it was completed. |
| 3 | The Completed card's title | **E's own wording: `"4 of 4 done - Ready to finish?"`** |
| 4 | How an auto-done step reads | Distinguished — see #9 for the glyph, a **word** per row. |
| 5 | The count on the summary line | **done-of-total, always** ("3 of 4 steps"), so number and list can never disagree. |
| 6 | A long step list (no cap on actions per place) | **Show every step, shrink to fit.** E: *"showing every step as outlined is appropriate"*. No scrolling. |
| 7 | The short ≈2 s beat | **Same view, just shorter** — full step list, no confetti. |
| 8 | Today's card says "Continue routine" on a run with nothing left | **Swap the label when nothing is pending:** "Finish routine" / "Continue routine". |
| 9 | The step list's glyphs | **Match the routine screen's EXISTING rows.** Reuse `PlaceRoutineStepCircle`: accent circle + `checkmark` for done *and* auto-done, `cardBorder` circle + `minus` for skipped, plus a state word ("Done" / "Skipped" / "Auto"). **No `✗`** — the app uses `xmark` only as a Close button. |

**Also settled and NOT in this block:** register §0b — E chose **"hold a full-screen celebration
behind any unknown sheet"**. That is its own block, `F-CTACelebrations-Surfaces`, listed in the TODO.

## ⚠ THREE BOOBY-TRAPS — each breaks a currently-green test

1. **Adjacency.** `RoutineRecordCallSiteTests.testLeavingAFinishedScreenRecordsCompletion` reads the
   screen comment-stripped and whitespace-collapsed and asserts
   `"store.end(runId: run.id) record { try await recorder.ended(runId: run.id, reason: .completed"`.
   **NOTHING may sit between those two statements** — not `hasRecordedEnd = true`, not the haptic,
   not `dismiss()`. The haptic goes *before* `store.end`, exactly as `leaveScreen()` orders it today.
2. **Unique anchor.** `CelebrationPopCallSiteTests.testEachRoutineStepsActionPops` anchors on the
   literal `"Button(title) { Haptics.play(.solid)"` and requires **exactly one** occurrence in that
   file. Writing the Completed button as the obvious copy-paste breaks it. It uses `.success`.
3. **The `== 5` count.** `HomeRoutineCardCallSiteTests.testEveryExitFromTheScreenEndsTheRunItself`
   reads **RAW** source and asserts `"leaveScreen()"` occurs **exactly 5 times** (doc comment,
   `.onDisappear`, scenePhase, Close button, declaration) **and** a whitespace-exact
   `"leaveScreen()\n" + 20 spaces + "dismiss()"`. Deleting the scenePhase hook takes it to **4**.

## The tests that pin the old rule — name each in the block report

**Reversed:** `HomeRoutineCardCallSiteTests.testEveryExitFromTheScreenEndsTheRunItself` (the `== 5`
above); `RoutineJourneyUITests.testARoutineIsReachableFromTodayAndEndsWhenItIsFinished` (taps Close
and asserts the Today card is gone — under R1 the card must **survive** Close; tap Completed
instead, and the test's *name* asserts the old rule too).

**Updated:** `RoutineRecordCallSiteTests.testLeavingAFinishedScreenRecordsCompletion` (renamed only —
the adjacency assertion survives verbatim once it moves into `complete()`);
`RoutineRecordJourneyUITests.takeAndFinishTheGymRoutine` (tap Completed, not Close — otherwise three
downstream assertions redden).

**Untouched on purpose, and the report says so:** `RoutineActivityCallSiteTests` (all three strings
survive), `CelebrationPopCallSiteTests.testEachRoutineStepsActionPops`,
`PlaceRoutineProgressTests.testCompletion_meansNoPendingSteps`. **Everything else mentioning
`reason: .completed` is the store / record / reconciler layer and is UNAFFECTED** — those layers do
not change. Do not "fix" them.

**Six sites read `PlaceRoutineScreen.swift` as a string** — `RoutineRecordCallSiteTests` ×2
(stripped + collapsed), `HomeRoutineCardCallSiteTests` (raw, whitespace-exact),
`RoutineActivityCallSiteTests` ×2 (raw), `CelebrationPopCallSiteTests` ×2. **Re-read all four files
before moving a byte.**

## The machinery, already mapped — do not re-explore

- **The Completed button follows the RING pattern, not the wrapper pattern.**
  `CelebrationPopSource`'s handle only ever requests `.pop`, never a milestone. So the button records
  its own origin via `.celebrationPopOrigin` into `@State` and passes it to
  `celebrate.request(.milestone(.routineFinished), at:)`. **Origin count 3 → 4; wrapper count stays
  9** (both inline literals in `CelebrationPopCallSiteTests.testNoOtherControlInTheAppThrowsAPop`).
- **`CelebrationPolicy.outcome(for:celebrationsEnabled:)`** — two parameters, no clock. With the
  switch **OFF** a `.milestone` returns **`.inPlace`** (R-h's fallback pop), not `.nothing`. The
  policy's own doc names the Completed button. **Do not add `Date` to that file** —
  `testThePolicyHasNoClockAndNoCooldownConstant` asserts its absence.
- **`ConfirmCelebrationClock.everyConfirmLength`** (`Focus/ConfirmCelebrationRecipe.swift:165`) is
  the 5.4 s symbol. **Never write a fresh `5.4`.** There is **no** constant for R5's ≈2 s short hold
  — this block introduces one, and it is the only new duration literal the feature needs.
- **`.routineCover` does not hold** (`dismissesItself` is `.promoteSheet` alone), so the burst starts
  at once on the cover's own layer.
- **The centre plays no haptic here** — it feels `.success` for `.dailyGoal` only, so the site plays
  its own `Haptics.play(.success)` (R-d, the single-owner rule).
- **Surface announce/release is already correct — do not touch it.** `surfacePresented(.routineCover)`
  is implicit via `CelebrationLayer`'s `.onAppear`; release is `RootView.swift:244`'s
  `.fullScreenCover(item:onDismiss:content:)`. `CelebrationMountCallSiteTests` slices `RootView.swift`
  from `".fullScreenCover( item: $presentedRoutineRun"` to `"content:"` — keep that argument order.
- **`CelebrationMilestone.routineFinished` exists with no production call site.** This block uses it.
- **`CelebrationPopOrigin.onScreen` is NOT needed** — it refuses a parked-tab origin, and the routine
  cover is presented, never parked. **Say so in the report** rather than leaving it unconsidered.

## The plan — nine commits, STOPPING at C4 for E's look

Pre-flight: `rm -rf TestResults.xcresult`; `curl -s 127.0.0.1:4400/emulators` (**not** running as of
2026-09-13); re-read the four string-reading test files.

| # | commit | after |
|---|---|---|
| **C1** | room 1/2 — `#if DEBUG` block → `Places/PlaceRoutineScreenPreviews.swift`. File 382 → ~320. | suite + lint + build |
| **C2** | room 2/2 — `openExternally` → `Places/PlaceRoutineScreen+Opening.swift`, `private` → internal. **Body 235 → ~220.** | suite + lint + build |
| **C3** | the pure layer, test-first — `PlaceRoutineProgress.earnedCelebration(_:)`; the copy enum; `…CongratulationLength.hold(for:)`; `…CongratulationEntrance.resolve(reduceMotion:)`; `…CongratulationDensity`. No UI. | suite + lint |
| **C4** | **the view, then STOP** — `PlaceRoutineCongratulationView.swift` + previews (light, dark, RM, switch-off beat, **4 steps and 20 steps**); `PlaceRoutineStepCircle` gains `var size: CGFloat = 28`. Rebuild the probe, render, `SendUserFile`, **wait for E**. | renders sent |
| **C5** | `PlaceRoutineCompletedCard.swift` (records its own origin, calls `onComplete(origin)`). **Same commit:** origin count 3 → 4 + message. | suite |
| **C6** | wiring + the reversal — `complete(from:)`, the body swap, the slot branch, **deletion of the scenePhase hook and `@Environment(\.scenePhase)`**, `leaveScreen()` gutted to `activity.ended()` + `DataChangeSignal.post()`, `displayName: String? = nil` on the init, the door passing `authService.signedInUser?.displayName`. **Same commit:** `leaveScreen` 5 → 4, and the six rotted comments. | suite + lint + build |
| **C7** | `continueLabel` → `continueLabel(for:)` + its doc comment + `HomeRoutineCardTests` (a compile break). | suite |
| **C8** | the two journeys. **`xcrun simctl erase <udid>` in the same command chain, unconditionally**, then the unit suite. | journey → erase → suite |
| **C9** | evidence + close-out — `screenshots/cta-celebrations-block-6/` + README, `RoutineRunStoreTests`' stale name/comment, TODO tick, register, the successor opener. | — |

C1 and C2 are separate because C1 is zero-risk and C2 changes an access level. **C5 leaves the card
deliberately unreachable for exactly one commit — say so in the report**, because an
unreachable-but-tested component is this repo's most-repeated defect shape.

### Two design answers, already settled

**A · "Shrink to fit" is a pure density table, not `ViewThatFits`.** `PlaceRoutineStepCircle` is a
hard `28×28`, so 20 rows is 560 pt of *glyph alone* against a ~600 pt budget — and
`minimumScaleFactor` scales `Text`, never the circle. So **the glyph must shrink**:
`PlaceRoutineStepCircle` gains `var size: CGFloat = 28` (both existing call sites untouched by the
default, which is what keeps "reuse the existing circle" true). Ship a pure `forStepCount(_:)`
returning grid-legal spacings plus `estimatedHeight(forStepCount:)`, both unit-tested.
`ViewThatFits` is rejected: its candidates are hand-authored so the same table exists either way,
just **unverifiable**, and when every candidate overflows it silently picks the last and overflows.
Rows in a plain `VStack`, **never a `ScrollView`** — a scroll gesture fights tap-to-skip.
`.minimumScaleFactor(0.8)` stays as a net for **long titles**, never for row count. **Name the
ceiling:** assert `estimatedHeight(21) > budget`, so 21 steps is a documented boundary for E rather
than a surprise on the phone.

**B · The body swap is a `ZStack`, and that is load-bearing.** **`Group` would re-fire
`.task { activity.started(run) }` on the swap — restarting the Live Activity moments after
`complete()` ended it — and no test could see it**, because `RoutineActivityCallSiteTests` only
asserts that string exists. `ZStack` has stable identity and overlays both branches during the
crossfade; hang `.task` / `.onDisappear` / `.background` on it, `.transition` on each branch. Full
motion reuses the screen's **own existing** spring (`response: 0.35, dampingFraction: 0.8`) and the
house 0.9 scale (`HomeMomentumSections.swift:37`) — no new motion vocabulary. **Reduce Motion:
`.opacity` only, `.easeOut(duration: 0.25)`** (§5 carries an explicit clause for exactly this). The
choice is a **pure enum** (`AnyTransition` is not `Equatable`) resolved by the screen and passed in.
**The leaf gets no internal animation at all**, which makes §7.2's opening-pose rule true *by
construction* and the render evidence deterministic.

## Red prediction — write it before implementing, in TESTS and ASSERTIONS separately

- **C3: 15 tests / 27 assertions.** The pure members must exist as **deliberately wrong stubs**
  (`earnedCelebration → true`, copy strings `→ ""`, `hold(for:) → 0`, density `→ .zero`) or the
  target does not compile and you get *one* failure instead of 27.
- **C4–C6: 12 tests / 21 assertions** — source-read guards, no stubs needed.
- **Total pre-implementation: 27 tests / 48 assertions**, plus three single-assertion flips at their
  own commits (origins 3→4, `leaveScreen` 5→4, the `continueLabel` compile break).
- **Expect nothing else to go red. If anything does, INVESTIGATE before accepting it** — `-5`'s
  lesson was that a missed prediction twice meant a guard reading the wrong text.

**Five naive first passes** (write it WRONG, watch exactly these go red): **1** put
`hasRecordedEnd = true` between `store.end` and `record {` → 1/1. **2** request the milestone
unconditionally → 1/2 and *nothing else* (an unearned run still ends, records and shows the beat, so
no other test can see it — **this pass is what proves R-f's guard is not decorative**). **3** write
the button as `Button(title) { Haptics.play(.solid)` → 1/1 inside `assertAnchorIsUnique`. **4** put
the accessibility id on `.bentoCard()` instead of the button → 1/1. **5** a COUNT cannot see a SWAP —
the origin count stays green if the origin is recorded on the card container, so guard 2 ships in the
same commit as the count.

## Risks to carry into the build

1. **Two glows stack on the full-screen path** — the layer draws `ConfirmCelebrationGlow` (peak 0.32,
   `StateGo`) over the congratulation's own static `StateGo` wash. **Resolve by LOOKING at the render
   before C4's send**, not by guessing a number.
2. **A skip tap orphans the burst** — the cover's layer unmounts mid-flight and the burst sits in
   `center.bursts` until the *root* sweep prunes it (`guard surface == .root`). Harmless, but a skip
   kills ~4.9 s of confetti. **That is R5 working as designed — name it so it is not filed as a
   defect from the phone.**
3. **Six comments narrate the deleted rule and not one can go red** (`stripped()` removes comment
   lines before every guard reads): `PlaceRoutineScreen.swift:30-32`, `:77-83`, `:305-308`;
   `HomeRoutineCard.swift:27-29`; `HomeRoutineCardCallSiteTests:36-37`; `RoutineRunStoreTests:271-274`.
4. **`RoutineRecordJourneyUITests`' routine is 1 auto-done + 3 skipped — R-f is NOT earned**, so it
   gets the 2 s beat with **no confetti**. A journey waiting on confetti hangs to the timeout and
   reads exactly like a render failure. **Give the greeting `Text` an accessibility identifier** so
   both journeys have something deterministic to wait on.
5. **The Live Activity now dies before the run does** — `leaveScreen()` still calls `activity.ended()`,
   so closing a fully-ticked run kills the Lock Screen card while the run stays live, and ActivityKit
   cannot restart it from the background. Reopening via Today recovers it. **Device look.**
6. **`DataChangeSignal.post()` now fires twice per completion** — once in `complete()`, once via
   `onDisappear` 5.4 s later. Harmless.
7. **The congratulation removes the Close button for up to 5.4 s.** For VoiceOver the only escape is
   the "Skip" action, so it must sit on the view's root and the view must not be `accessibilityHidden`.
8. **The screen's init gains a parameter** — default `displayName` to `nil` so the moved previews
   compile untouched, and rely on the new door guard rather than the compiler to catch a host that
   forgets it. That is `-5`'s exact defect shape.

## A consequence of R1 that E has not seen stated

**A fully-ticked run that is never confirmed is recorded as `dayEnded`, not `completed`.** An
arrival run stays live until **end of day** (`RoutineRun.swift:96-102`); `RoutineRunReconciliation`
then stamps `.dayEnded` / `.windowLapsed` (`:40-42`). So *"Completed can be tapped later"* has a
deadline: midnight. **This is exactly what E asked for** (*"nothing is recorded as completed without
the tap"*), so it is intended — but put it in the block report and register §C2.

## Accessibility — the answer, already worked out

`-5` left an open question about milestone announcements. E chose "the daily goal only", on the
grounds that the other milestones leave the user on a screen stating the outcome. **For THIS
milestone that premise is true and then some** — the congratulation is a full screen of text naming
the user, the routine and every step. **Say that in the report; add no announcement here.**

## How to run the block

- Test-first with a written red prediction; red-checks on a committed tree; `swiftlint lint` 0; the
  full suite with the emulator up and **0** `127.0.0.1:9099` hits; the sim build; renders or a probe
  (removed before commit); the PR; the phone from `main`; E's verdict; the register rewritten.
- Tokens only (§4), the 4/8/16/24 grid (§2), haptics through `Theme/Haptics.swift`, prose test
  names, loud call-site guards. **Copy lives in a pure enum pinned by a test, never in a body.**
  **Accessibility identifiers go on controls, never on a card container.**
- Use the installed skills, MCPs and subagents (E's standing ask): the TDD skill, a
  `feature-dev:code-reviewer` pass over the diff before the PR, an `apple:hig-reviewer` pass over the
  finished surface. `SendUserFile` for renders.
- **§7.3's RM-on device pass is OWED by this block.** Ask for both passes in ONE message (RM off,
  then RM on) so E flips the setting once. Until then the line reads *"Reduced: run on sim
  (injected); NOT on device."*

## Environment notes

- **Open Xcode on the project BEFORE starting** or the `xcode` MCP bridge is absent all session.
  It DID connect on 2026-09-13. `RenderPreview` has failed on this project twice — **do not sink
  time into it**; the run-loop-pumping probe is the sanctioned fallback.
- **A stale `TestResults.xcresult` fails the suite before a single test runs.** Gitignored; `rm -rf`
  it as part of the run.
- **The emulator may already be running.** `curl -s 127.0.0.1:4400/emulators` tells a live harness
  from a broken one; use the running one if you can.
- **An env var on the `xcodebuild` command line does NOT reach the test process** — it is taken as a
  build setting. A probe that writes files falls back to the simulator's container `tmp`; **read the
  path it PRINTS** and copy the files out.
- **Test simulator:** iPhone 17 Pro `9181EBF9-0F54-4A4D-A19C-19945D1BF155` (iOS 26.5, the only
  runtime). **A UI-target run POISONS it — erase before the next unit run.** This block runs both
  routine journeys, so **order the erase to follow them unconditionally**.
- **E's phone:** `3DBC979A-3255-5456-8C30-172DB19B99B3` (`wishwashwacky15`, an iPhone **15** Pro).
  **Dev profile expires 2026-09-17**; when an install fails, E re-signs in Xcode → Settings →
  Accounts. Recipe: `xcodebuild build -destination 'platform=iOS,id=<udid>' -allowProvisioningUpdates`,
  then `xcrun devicectl device install app --device <udid> "<…>.app"` and
  `… process launch --device <udid> --terminate-existing com.ethananthony.ADHD-LifeOS`.
- **Baseline at this plan's commit:** suite **2,882 / 0**, lint **0 / 791**, app coverage
  **27.39 % (13,058/47,668)**.

## Then, strictly in order, one per review

`F-CTACelebrations-7` (the chime; E picks by ear) → `F-CTACelebrations-Surfaces` (E's §0b answer:
hold a full-screen celebration behind any unknown sheet) → `F-FocusCard-Corners`.

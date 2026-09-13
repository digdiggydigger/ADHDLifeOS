# Open items register — 2026-09-13 (forty-fifth edition; **`F-CTACelebrations-Surfaces` AND `F-FocusCard-Corners` are DONE, MERGED and PASSED ON DEVICE** — nothing in any merged block is owed to E)

*Close-out of the session that settled two design questions with E, built both blocks, and got both
device verdicts once the phone was carrying them.
Supersedes the forty-four earlier editions. **The previous edition's `-6` / `-7` entries stand
unchanged and nothing is owed on either** — see "Landed" below.*

> ## ⏸ EVERYTHING BELOW IS ON HOLD — E's instruction, 2026-09-13
>
> E paused the whole queue to start **a curated colour scheme for the app**: *"can we hold on
> starting any of those above tasks. I would like to create a properly curated & developed colour
> scheme that we will implement throughout the LifeOS application. lets start that planning in a
> fresh claude code terminal session."*
>
> **Nothing in §A, §B or §C should be started, or offered, until E lifts the hold.** Nothing about
> those items changed except priority — they are still accurate and still outstanding. The three
> device looks in §A and the photosensitivity blocker in §D are unaffected as FACTS; they are
> simply not to be chased.
>
> The colour arc has its own opener: **`handoff/START-HERE-colour-scheme.md`**, which carries a
> measured inventory of the 63 colorsets and the five questions the arc must put to E first. It is
> PLANNING first — no recolouring until there is a block E has seen.

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding, so it is the thing to read and to
update rather than improvising a list in chat.

## State

**`main` @ `f2ed231`** (PR #119; `598da3b` was the last commit to touch app code). `firestore.rules` untouched — **nothing for E to republish**.
Every feature branch is merged and deleted; `origin` carries `main` alone.

Measured on `main`:
- unit suite **3,008 / 0**, emulator UP, **0** `127.0.0.1:9099` hits;
- SwiftLint **0 / 812 files**;
- sim `** BUILD SUCCEEDED **`;
- **both UI journeys GREEN** (run for `-6`; not re-run for `-Surfaces`, which touches no UI, nor
  for `-Corners`, which changes a shape no UI test asserts);
- **device: ON MAIN at `1920536`, installed 2026-09-13 22:29** — build, install and launch clean
  in one wireless pass. **ALL FOUR blocks have passed on the phone**: `-6`, `-7`, `-Surfaces`
  (*"you can mark a PASS"*) and `-Corners` (*"they look okay"*, with two screenshots filed).
  **Nothing in any merged block is owed to E.**

### Landed this session

**`F-CTACelebrations-6`** — C6–C9: the routine Completed flow wired (PRs #106–#109). See the
forty-first edition's detail; nothing about it is outstanding.

**`F-CTACelebrations-7`** — the chime (PR #110). E's F5, and the block that made a switch true:
"Celebration sounds" had been in Settings since `-3` storing a choice nothing read. Five candidates
went to E as `.wav`, peak-normalised to the same −3.0 dBFS so the comparison was of timbre; E picked
the first ElevenLabs generation by ear and **reserved the second for future use**. (NEW)

**`F-CTACelebrations-Surfaces`** — hold a celebration behind any unknown sheet (PR #112). E's
design call, taken before a line of it was written: asked to choose between a house modifier on all
26 `.sheet`/`.fullScreenCover` presenters and asking UIKit, **E chose asking UIKit**, plus holding
behind alerts / dialogs / system pickers and leaving a pop alone. `KeyWindowPresentationProbe`
walks the key window; `isBlocked` is the single predicate behind the hold and the release; a hold
watch replaces the `onDismiss` an untracked sheet never sends, and R-g is enforced by time rather
than by the next dismissal. **It is a PREVENTIVE block** — the five milestone sites were traced and
none of them can be reached from inside an untracked sheet as the tree stands, so what it closes is
the class rather than a live defect. **PASSED ON DEVICE 2026-09-13** (E: *"you can mark a PASS to
'the celebration hold' checklist item"*). Nothing outstanding. (NEW)

**`F-FocusCard-Corners`** — the collapsed card's bottom corners (PR #116). E's *"Round them"* was
a word, not a number, so the four radii went to E as a render and E chose **24 — "match the top"**
("leave it square after all" was offered and not chosen). `FocusBarCardOutline` now cuts BOTH the
fill and the keyline from one silhouette, so they cannot disagree about where the corner is; the
`Bool` became a `CGFloat` on `animatableData`. **PASSED ON DEVICE 2026-09-13** (E: *"they look
okay"*, two screenshots filed). Nothing outstanding. (NEW)

### What this session established

- **"Owed a device check" and "the code is on E's phone" are DIFFERENT FACTS, and conflating them
  wastes E's time.** Both blocks were reported as owing a device verdict while the phone was still
  on `eade58a`, two PRs behind. E looked, saw nothing, and reported it — *"i cant see any change on
  my iphone"* — about a change that was correct and simply not installed. The `device-build-lag`
  note already said *"after a device-affecting block, push a device build too"*. **Install as part
  of the close-out, and write the SHA the phone carries.**

- **A GREEN test suite can leave the one thing users depend on unproven.** Every test in
  `CelebrationSoundTests` injected `loadAsset`, so none of them touched the asset catalog —
  and `assetutil` on the built `Assets.car` proves the bytes SHIP, not that `NSDataAsset(name:)`
  resolves or that `AVAudioPlayer` accepts them. A dataset can be present and unreadable by name.
  **One test using the DEFAULT loader closes it**, and the test target hosts the app so it costs
  nothing. Generalises past audio: whenever a seam is injected everywhere for testability, ask
  what exercises the REAL implementation. (NEW)
- **Reversing a test is now a three-times-proven habit, and once it was the test NAME that lied.**
  `testTheFeedbackFooterExplainsBothSwitchesAndSaysTheSoundIsNotLiveYet` had the reversed claim in
  its own name. Also loosened — not deleted — a mount guard anchored on `CelebrationCenter()`'s
  empty parentheses, in its ARGUMENTS only, so what it is really about (the App owning the centre)
  stayed pinned. (NEW)
- **Footer prose is checked by no compiler, and it had drifted twice.** The Settings footer said
  the sound switch "does nothing until the chime arrives" AND that the milestone celebrations were
  "still to come" — the second stale since `-4`, nothing to do with this block, and nobody had
  noticed. **When a block touches user-facing copy, read the whole paragraph, not the clause.**
  (NEW)
- **E reserved a rejected candidate, which is a case the "no dead assets" rule does not cover.**
  `05-generated-b` is kept in the evidence folder as `.wav` and a ready-to-ship `.caf`, and
  deliberately NOT in the asset catalog: an asset with no call site is weight in every build. Kept
  where it is findable, added when a site exists. (NEW)
- **The provisioning "fastest check" FALSE-ALARMED** — `defaults read … DVTDeveloperAccountManagerAppleIDLists`
  returned an EMPTY `IDE.Identifiers.Prod` and the device build signed perfectly. On Xcode 26 that
  key is not evidence of anything; run the build and read its LOG. (NEW)
- **GitHub can report a merge as unmerged for the better part of an hour.** PR #109's merge landed
  (`4451326`) while `gh pr merge` returned 502; the PR read `merged=false` through ~40 s of polling
  and two more write attempts failed with 504/GraphQL errors. It reconciled itself later. **Verify
  against `origin/main` — `git merge-base --is-ancestor` — and do not re-run `gh pr merge`**, which
  would have put a second empty merge commit on `main`. (NEW)

## A · Decisions only E can make — minutes each

**Every device check on the CTA-CELEBRATIONS ARC and the FOCUS CARD is clear** — E settled four at
the sitting on 2026-09-12/13, then `-6`'s and `-7`'s verdicts, then `-Surfaces`' and `-Corners`' on
2026-09-13 once the phone was finally carrying them.

**"Nothing in any merged block is waiting on E" was written here and it was TOO STRONG — corrected
2026-09-13.** Three earlier follow-on blocks (`SwipeOrigin`, `NoCooldown`, `PopScale`) still owe
device looks; they are landed, green and installed, and the first of them replaces a defect E
themselves reported, so it is the one with a known "before". The honest statement is: **nothing in
the last four blocks is owed; three older ones still are, and none is urgent.**

- [x] **`F-CTACelebrations-Surfaces`' DEVICE PASS — PASSED 2026-09-13.** E, on `main @ 1920536`:
      ***"you can mark a PASS to 'the celebration hold' checklist item"***. **Nothing in the block
      is outstanding.** The note below is kept because it is the reasoning, not the task:

      ~~**read what it is FOR before running it, because the obvious version of this check cannot
      fire.**~~ All five milestone sites were
      traced: `inboxZero`'s three doors, `streakSeven`'s "Done for now", `dailyGoal`'s ring and
      `routineFinished` are reachable only from `.root` or from the two tracked surfaces, and
      **Quick Capture creates captures rather than clearing them** — so as the tree stands today
      there is no user action that fires a milestone from inside an untracked sheet. **The block is
      preventive, not a fix for a demonstrable bug**: it closes the class (every future sheet, plus
      alerts, dialogs and iOS's own interruptions such as "Save Password?") and the composition
      test is its proof.
      **So the device check is the REGRESSION one, and it is two minutes.** Get the capture inbox
      down to one waiting capture, open it, **Create Task**, promote. Inbox zero should celebrate
      **immediately** as the sheet closes, exactly as it did before. That path is the one
      `releaseHeldIfClear` now gates on the probe, it is shipped and E-verified from
      `F-CTACelebrations-5`, and it is the only place this block could have made something worse.
      **No RM-on pass is owed** (§7.3): no `#available` site and no Reduce Motion site is added or
      changed, so the reduced path cannot look different either way. (NEW)

- [x] **`F-FocusCard-Corners`' DEVICE VERDICT — PASSED 2026-09-13.** E: ***"they look okay"***,
      with two device screenshots filed as
      `screenshots/focus-card-bottom-corners/02-device-collapsed-light.jpeg` and
      `03-device-collapsed-dark.jpeg` — the shipped 24pt corner on real glass, light and dark.
      **Nothing in the block is outstanding.** The note below is kept as the reasoning:

      ~~a look rather than a test.~~ Start a sprint, collapse the card, and look at where its bottom
      corners meet the tab bar; then expand it again. E chose 24pt from a simulator render
      (`screenshots/focus-card-bottom-corners/`), and what a render cannot show is how the notch
      between card and bar reads on glass at arm's length. **No RM-on pass is owed** (§7.3): no
      `#available` site is added, and the only Reduce Motion interaction is the existing collapse
      animation, untouched. (NEW)

- [x] **`F-CTACelebrations-7`'s DEVICE VERDICT — PASSED, 2026-09-13, both checks.** E, verbatim:
      ***"both work correctly"*** — the chime plays UNDER music without pausing it
      (`.mixWithOthers`) and stays silent with the ring switch off (`.ambient`). Neither is
      provable on the simulator. **Nothing in the block is outstanding.** (CLOSED)
      - **E reserved the runner-up sound** for use elsewhere: *"keep a hold of the sound 'el-b'
        ... there is likely other locations that [it] Could be used."* Kept at
        `screenshots/cta-celebrations-block-7/candidates/05-generated-b.{wav,caf}`, deliberately
        out of the asset catalog until a real site exists. **This is a standing item for whoever
        adds the next sound** — do not regenerate one. (NEW)


- [x] **`F-CTACelebrations-6`'s DEVICE VERDICT — PASSED, 2026-09-13, BOTH passes.** Installed at
      `4b0f0ad` (build, install, launch clean in one wireless pass). E, verbatim: ***"both work
      correctly"***, answering an ask that enumerated the two checks separately — Reduce Motion OFF
      (Close leaves the card, it reads "Finish routine", reopening offers Completed, the
      congratulation over a real fetch, a step ROW closes it) and then Reduce Motion ON. **So
      §7.3's RM-on pass is EARNED for this block**, and its Verified-paths line reads *"Reduced: run
      on sim (injected) + E's phone (RM on)"* — the second time in this arc that line is earned
      rather than owed. **Nothing in the block is outstanding.** (CLOSED)
      - **Shipped but NOT approved, and worth knowing:** under `.spring` the checklist scales down
        to 0.9 as the congratulation scales in. The plan specified the entrance only; the symmetric
        exit was the implementer's call, was flagged to E in the same message, and drew no comment
        either way. Overrulable. (NEW)

- [ ] **DEVICE CHECK OWED on the three follow-on blocks, whenever E is next on the phone.** All
      three are landed, green and installed from `main`; none is urgent, and E has already passed
      everything that came before them.
      - **The swipe's pop** (`SwipeOrigin`) — swipe a task closed and confirm the paper now leaves
        from the finger rather than off the right-hand edge. **This is the one that replaces a
        defect E reported**, so it is the only check with a known "before".
      - **The overlap** (`NoCooldown`) — clear the last capture and cross the daily goal close
        together; two full-screen celebrations now OVERLAP rather than the second being downgraded.
        That is the direct consequence of removing the cooldown and it is E's decision; it is worth
        a look only to confirm it does not read badly.
      - **Reduce Motion ON** (`PopScale`) — the still pop's scatter scaled 48 → 76.8 pt with the
        pop, so §7.3 owes it one RM-on look. Until then that block's Verified-paths line reads
        *"Reduced: run on sim; NOT on device."* (NEW)
- [ ] **PHOTOSENSITIVITY — E POSTPONED this on 2026-09-13, and asked in the same breath that it be
      brought back before public launch.** E, verbatim: *"Can we postpone this decision for later
      date? But we must come back to this before shipping to the public."*
      **So this is now a LAUNCH BLOCKER by E's own instruction, not an open polish item** — it is
      listed in §D as well, and neither entry may be closed without E.
      The finding, unchanged: the stack-clearing Confirm's 14 shells flash **5 times inside one
      second** (from ≈ 2.00 s) against **WCAG 2.3.1's threshold of 3**. Each flash is a radial
      gradient growing 40 → 240 pt at up to 0.35 alpha over 0.35 s. **Unmeasured:** whether the
      luminance delta and screen area also cross the guideline — the flash COUNT alone is what
      crosses. There is no app-readable API for iOS's "Dim Flashing Lights", so it cannot be gated
      in code. The finding does NOT extend to the pops or the milestones (both re-confirmed).
      The options remain: measure the luminance properly, thin the two clusters, or accept it with
      eyes open. (DEFERRED BY E, carried to §D)
- [ ] **Install an older simulator runtime** via Xcode → Settings → Components. E, 2026-09-11:
      *"In a number of days in the future, I will install this."* Until then every `#available`
      fallback is compile-only by policy (§7.3). (carried)
- [ ] **Optional, still not decided: an `.accessibilityHint` on the Celebration sounds row only.**
      (carried)
- [x] **THE DEVICE SITTING — DONE 2026-09-12, and BOTH blocks PASSED with Reduce Motion OFF *and*
      ON.** E, verbatim: *"both of those tests work correctly!"*, confirmed when asked precisely
      about RM. So `F-CTACelebrations-4` and `-5` are verified on device and **both blocks'
      Verified-paths lines read "Reduced: run on sim (injected) + E's phone (RM on)"** — the first
      time in this arc that line is earned rather than owed. (CLOSED)
- [x] **The milestone cooldown — E REMOVED IT ENTIRELY, 2026-09-13.** Verbatim: *"Remove the
      cooldown entirely."* It was E's own 5 s testing value from the start, so this closes the
      question rather than reversing a settled answer. Shipped in `F-CTACelebrations-NoCooldown`;
      the consequence to watch on device is the overlap, above. (CLOSED)
- [x] **The VoiceOver announcement on the streak — E: leave as shipped, 2026-09-13.** E was told
      that the premise behind the original answer was wrong (the nudge card VANISHES on dismissal,
      so day seven leaves nothing on screen that distinguishes it) and chose to keep the shipped
      behaviour anyway: the daily goal announces, the other two do not. **Decided with the correct
      facts in hand, which is what the re-ask was for.** (CLOSED)
- [x] **Whether the Celebrations switch should also gate pops — E: leave as shipped, 2026-09-13.**
      So the switch covers full-screen celebrations only, the Settings footer continues to say so,
      and a user wanting zero decorative motion has Reduce Motion (which stills the pop rather than
      removing it). Raised by the `apple:hig-reviewer` pass; E has now ruled. (CLOSED)
- [x] **An accessibility announcement for the milestones** — E chose "the daily goal only",
      2026-09-12, re-confirmed 2026-09-13 on corrected facts. (CLOSED)
- [x] **How does the reduced path get DEVICE time now that E runs with Reduce Motion OFF?** —
      **E chose (a), 2026-09-12**, written into CLAUDE.md §7.3. (CLOSED)

## B · Real work, ready to start — recommended order

~~**00. THE CTA CELEBRATIONS ARC — `F-CTACelebrations-6` is BUILT TO C5 ON A BRANCH.**~~
   **THE WHOLE ARC IS FINISHED — corrected 2026-09-13, and this entry was badly stale.** It still
   described `-6` as half-built on a branch and pointed at
   `handoff/START-HERE-cta-celebrations-6-part2.md`, which has been ARCHIVED for days; C6–C9, `-7`
   and `-Surfaces` have all landed and all passed on device since. Anyone following it would have
   gone looking for a branch that no longer exists.
   **Every block is merged:** `F-ConfirmCelebration-2` → `-1` → `-2` → `-3` → `-4` → `-5` → `-6`
   → `-7` (the chime) → `F-CTACelebrations-Surfaces`, plus `PopScale`, `NoCooldown`, `SwipeOrigin`.
   The design record — permanent, never archive — is
   `handoff/SESSION-OPENER-cta-celebrations-design.md`. **Nothing in the arc is work any more**;
   what survives it is the three device looks in §A and the photosensitivity blocker in §D.
   (CLOSED)

~~**0b. Two surfaces question, raised by the HIG pass and NOT closed.**~~ **ANSWERED BY E,
   2026-09-13 — and it is now a BLOCK, not a question.** Offered "add Quick Capture only", "hold
   behind any unknown sheet", "accept it and close the item" or "defer and ask again", E chose
   **hold a full-screen celebration behind ANY unknown sheet**. Written up as
   **`F-CTACelebrations-Surfaces`** in `TODO-CLAUDE-CODE.md`. **BUILT AND MERGED 2026-09-13**
   (`a472f28`, PR #112). The design question it flagged was settled with E FIRST, as the spec
   demanded: two options put to them with catches, misses, cost and what keeps each honest, and E
   chose the UIKit probe. R-g applies unchanged in substance, and is now enforced by time rather
   than by a dismissal that an untracked sheet never sends. **Nothing is outstanding here but E's
   device pass.** (CLOSED as a question; CLOSED as a block bar the verdict)

**0c. The daily-goal announcement is an INTERRUPT, and nothing here has been checked on a real
   VoiceOver device.** `UIAccessibility.post(notification: .announcement,)` speaks over whatever
   VoiceOver is reading, and it can fire on any tab about a second after an unrelated action; a
   second accessibility notification landing in the same beat can coalesce one away. Neither effect
   is provable from source. Worth folding into the next VoiceOver pass rather than a block of its
   own. A 17+ attributed-string announcement API with a priority option may exist in the 26.5 SDK —
   unverified — which would make this a §7.1 register candidate. (NEW)

**0d. Follow-ups to the modern-iOS pilot — only what E asks for.** (carried)
   - **RM arrival fade for the bottom furniture**, only if E likes the cross-fade.
   - **The modern-API inventory, register-only until each is a block.**
     - **Free at 16.0:** `.contentTransition(.numericText(countsDown: true))` on the sprint
       countdown and ~20 `.monospacedDigit()` counters; `.presentationBackground` (16.4) on three
       sheets.
     - **Needs 17:** `ContentUnavailableView` in four empty states;
       `.contentTransition(.symbolEffect(.replace))`; interactive widgets and routine Live Activity
       check-off; the `@Observable` migration (now 28 classes); TipKit.
     - **Needs 18/26:** `Tab`/`.tabBarMinimizeBehavior` and `.glassEffect`, both constrained by the
       custom `AppTabBar` (adoption means replacing it).
   - **Two RM sites that remove the press affordance entirely** (`AppTabBar.swift:266`,
     `AppSearchRow.swift:71`), and `RootView.swift`'s declared-but-unread `reduceMotion`.

1. ~~**E's one un-run device check: airplane mode + pull-to-refresh on Home.**~~ **RUN AND PASSED
   2026-09-13** — E: *"Airplane mode ON check has been run and was successful."* Home keeps the
   last-known task set rather than emptying it, which is what `F-HomeTasksLastKnown` (`8b5f740`)
   exists to do. **Nothing is outstanding here.** (CLOSED)

2. ~~**`F-FocusCard-Corners` — after the arc (E: "Round them").**~~ **BUILT AND MERGED 2026-09-13**
   (`598da3b`, PR #116). E chose **24pt, "match the top"** from a four-way render. Note for anyone
   reading the old line: the `animatableData` half is DONE and is currently **inert**, because
   E's radius equals the expanded one — the snap is gone because the difference is gone. That is
   recorded in the code rather than glossed. **Nothing outstanding but the device verdict** (§A).
   (CLOSED)

3. **`AppFeedback.hapticsEnabled()` and `.notificationSound()` have no test that calls them.** Two
   small tests, no production change. (carried)

4. **Two more dead design tokens, and two dead helpers.** `BarSurface` is defined, unit-tested and
   used by nothing; `AppTabBarPresentation.slotWidth` / `restingSlotWidth` have ZERO production call
   sites and disagree about their input. (carried)
5. **Accuracy-aware containment for the arrival card — ONLY if E still sees drops.** (carried)
6. **Arc 2 — first-class routines + the "at a time" trigger.** (carried)
7. **`F-Search-3-Journal`** — recommendation is still to kill the block. (carried)
8. **The Live Activity design review** E parked. (carried)

## C · Parked on E's instruction — do not start unprompted

- **A nudge-specific screen animation for EVERY "Done for now".** E, 2026-09-11. (carried)
- **14- and 21-day streak milestones** (R-b): the arc fires at exactly 7. (carried)
- **Places backgrounding dismiss bug** — waiting on E's iOS update. (carried)
- **App connections** — real two-way sync; Apple Notes has no iOS API. (carried)
- **LA interactive buttons**, **time-of-day triggers**, **smart skip**. (carried)
- **`OfflineSprintSummaryCard`** — E ruled it out of the focus-card arc explicitly. (carried)

## C2 · Noticed, below the bar — **E asked explicitly that these be KEPT, 2026-09-13**

*E, verbatim: "Don't forget Your flagged points, So we can come back to them later." So nothing in
this section is dropped for age, and none of it may be quietly closed as stale. Each is something
this session or an earlier one noticed and judged below the bar for its own block — not something
that was tried and dismissed.*


- **A fully-ticked routine that is never confirmed will be recorded as `dayEnded`, not
  `completed`.** Found while planning `-6`. An arrival run stays live until **end of day**
  (`RoutineRun.swift:96-102`) and `RoutineRunReconciliation` then stamps `.dayEnded` /
  `.windowLapsed` (`:40-42`), so R1's *"Completed can be tapped later"* has a deadline: midnight.
  Tick every step, swipe away, come back tomorrow — the Journal shows a lapsed run. **This is
  exactly what E asked for** (*"nothing is recorded as completed without the tap"*), so it is
  intended rather than a defect, but E has not seen it stated. (NEW)
- **A shared constant reaches more sites than the block that changes it.** The swipe's pop went
  off-screen because `PopScale` moved a throw distance that a DIFFERENT block had built an origin
  decision around. Fixed in `F-CTACelebrations-SwipeOrigin`, but the shape recurs: the next time a
  celebration constant moves, re-read every site that constant reaches rather than trusting the
  suite. (NEW)
- **The daily goal is the one celebration the user did not just cause with their thumb.** Raised by
  the HIG pass. Inbox zero and the streak both fire from a tap, so a wash starting under the thumb
  is no surprise; the daily goal can land about a second after ANY action, anywhere — including
  while typing in a task's notes. Hit-testing passes through, so nothing is blocked, but it is a
  real cost of E's "any tab" design (F7) rather than a defect. Worth naming at the device sitting.
  (NEW)
- **Eight of the ten pop sites are OPTIMISTIC** — they pop before the work is known to have
  succeeded. Each fires in the same closure and at the same instant as the haptic that was already
  there. The one worth a second look is **Sorted from the triage card**, where the
  `await service.sort(...)` genuinely can return false. **The three milestones are NOT optimistic**
  — each is asked for only after its write landed, which is why a failed sort celebrates nothing.
  (updated)
- **The promote sheet's celebration layer is sized to the SHEET, not the screen**, so the Create
  Task pop clips at the sheet's top edge. By design, and visible for 0.45 s (R-e). (carried)
- **Under Reduce Motion the closure card's `withAnimation(.default)` also animates the SIBLING
  sections reflowing beneath it.** A REDUCED-path effect, so E's passing verdicts did not see it.
  **The RM-on pass this sitting owes is the natural moment to look.** (carried)
- **The Feedback section's footer is a thirteen-line paragraph** covering six switches. (carried)

## D · Launch blockers — no conversation opened yet

- **Free dev account** → 7-day profiles; the current one is valid to **2026-09-17**. When a device
  install fails on it, E re-signs in Xcode → Settings → Accounts. (carried)
- **Sign in with Apple** built but dormant. (carried)
- **Photosensitivity: the stack-clearing Confirm's fireworks flash 5 times in one second** against
  WCAG 2.3.1's 3. **E POSTPONED the decision on 2026-09-13 and asked in the same breath that it come
  back before launch** — verbatim: *"Can we postpone this decision for later date? But we must come
  back to this before shipping to the public."* So it sits here by E's own instruction rather than
  by anyone's judgement, and **it may not be closed without E**. Full detail, and what is and is not
  claimed, in §A. The finding does not extend to the pops or the milestones. (DEFERRED BY E)

## E · Known, not work

- **`MILESTONE_PROBE_OUT` passed on the `xcodebuild` command line does NOT reach the test process.**
  It is taken as a build setting, and the probe falls back to `NSTemporaryDirectory()` — the
  simulator's own app-container `tmp`. Not a failure: the probe prints the path it actually wrote
  to, and the files are copied out afterwards. **Read the printed path rather than assuming the
  environment variable landed.** (NEW)
- **The `xcode` MCP bridge was NOT USED this session**, as the opener instructed; the
  run-loop-pumping probe did everything needed. (carried)
- **A stale `TestResults.xcresult` fails the whole suite before a test runs.** Gitignored, so it
  survives everything; delete it as part of the run. It was present at session start again.
  (carried)
- **A green suite cannot see a `View`'s appearance, a TIMING WINDOW, or a COORDINATE.** This block
  added the third: the fallback pop's origin was correct, its request was correct, and it was drawn
  faithfully at a point 10,000 pt off screen. Render, render the CONTROL, and prove the harness
  deterministic before any pixel claim — then ask what the numbers in the picture MEAN. (updated)
- **`Executed N tests, with M failures` counts failed ASSERTIONS, not failing TESTS.** Predict in
  both, and treat a MISS as a possible defect in the guards rather than a bad forecast — this
  session's two misses were exactly that. (carried)
- **SwiftLint's ceilings bite in two places now.** The 400-line FILE ceiling
  (`CaptureInboxService.swift` 397 → 355 this block; `PlaceRoutineScreen.swift` 384 is next), and
  the 250-line TYPE BODY ceiling, which `CelebrationCenterTests` crossed — split to
  `CelebrationCenterHeldBurstTests` on the `CaptureInboxTriageServiceTests` precedent. (updated)
- **Moving an extension to a new file ends same-file `private` access.** `replaceCapture` could not
  follow its two callers out of `CaptureInboxService.swift` — it writes `state`, whose
  `private(set)` setter keeps every writer in the type's own file — so it was relaxed to internal
  instead. (updated)
- **A UI-target run poisons the simulator; erase it before the next unit run**
  (`xcrun simctl erase 9181EBF9-0F54-4A4D-A19C-19945D1BF155`). No UI target was run this session.
  (carried)

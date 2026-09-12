# START HERE — build `F-CTACelebrations-3` (the centre, the shared layer, the four surfaces, Confirm re-routed)

*A disposable pointer (CLAUDE.md, "Session handoff"): paste this path into a fresh Claude Code
terminal. Written 2026-09-12 at the close of the session that built `F-CTACelebrations-2`. **The
session that writes this arc's next opener archives this file in the same move.***

**STATUS.** Blocks 1–3 of the arc are MERGED. `F-ConfirmCelebration-2` (`9a7b664`, PR #76) and
`F-CTACelebrations-1` (`49c78d9`, PR #80) both PASSED E's device verdict.
**`F-CTACelebrations-2` (the two switches, PR #87) also PASSED, 2026-09-12** — E: "All correct —
passes", *"They were both successful."* With Celebrations off the Confirm confetti did not play and
the phone still buzzed. **Nothing is owed from it; start this one.** The app code is `main` @ `2efd705`
(PR #87), which is the build E judged and the one running on E's phone; the verdict itself
landed as a docs-only PR on top. Check `git log --oneline -1 origin/main` for today's tip
rather than trusting a SHA written here.

**No RM-on device pass is owed by block 3 either** (§7.3), for the same reason block 2 owed none: the
centre and the layers add no reduced rendering, and Confirm is §7.2's waiver. **Say so in the
report** rather than silently omitting it. The first block that owes one is `F-CTACelebrations-4`.

## Read first, in this order

1. CLAUDE.md's start-of-session checklist: `claudecode.md`, "Architecture notes", and **§7**.
2. **`handoff/OPEN-ITEMS-REGISTER.md`** (thirty-third edition) — THE outstanding list. §A holds the
   pending verdict, the cooldown decision (5 s, untouched until `F-CTACelebrations-5`) and an
   optional accessibility hint E may or may not want. **§B.00 lists the three things block 2 leaves
   block 3**, and §C2 has two things for E's eye on device.
3. **`handoff/SESSION-OPENER-cta-celebrations-design.md`** — the design. For THIS block: E's
   decision **#9** (the architecture), the ARCH answer ("one layer per surface", chosen over a
   passthrough `UIWindow`), and R-c / R-g.
4. `TODO-CLAUDE-CODE.md` — the block `F-CTACelebrations-3` under `# ⚠ CLAUDE CODE ADDITIONS`.
5. `screenshots/cta-celebrations-block-2/README.md` — the probe technique, and specifically **why
   the control render is in the folder**. Block 3's device verdict is "Confirm indistinguishable
   from today, switch off = nothing", which is the same claim block 2 proved by pixels; the harness
   is already written down and should be reused rather than rediscovered.

## The block — `F-CTACelebrations-3`

- **Room first, as its own commit: `RootView.swift` is at 394** against the 400 ceiling. The design
  record names the split (`:73-93` → `RootView+Furniture.swift`). **Budget for widening every
  `private` the moved code touches** — `private` in an extension is scoped to the FILE the extension
  is written in, which cost block 1 four declarations.
- One App-owned **`CelebrationCenter`**, reached through an environment value with an **inert
  default**, and one **`CelebrationLayer(surface:)`** per presented surface: root, the routine
  cover, the Tasks search surface, the Create Task sheet.
- **Confirm is re-routed through the centre**, and must come out indistinguishable.
- **The shared `CelebrationFrame` now has to carry the fireworks and the dim too**
  (`ConfirmCelebrationScene.fireworks`, `ConfirmCelebrationDim`, `ConfirmFireworksDrawing`), and the
  §7.2 waiver pin lists **SIX** Confirm files, not three.
- **`ordinal` did three jobs** in the Confirm build (SwiftUI id, seed, haptic trigger). The centre's
  counter takes the first two and the service's keeps the third, so they never meet.
- R-c: **Confirm stamps `lastFullScreenAt`** (it counts toward the cooldown) but is **never itself
  downgraded**. R-g: held full-screens drop after 60 s.

## The three things block 2 leaves this block — do not rediscover them

- **`celebrationsGate` MOVES.** Block 2 put the switch on `ConfirmCelebrationOverlay` as an
  injectable `var celebrationsGate: () -> Bool = { AppFeedback.celebrationsEnabled() }`, consulted
  inside `.onChange` before the burst is appended. Once the centre owns the routing the gate belongs
  in the centre. **Update `testTheConfirmLayerGatesOnTheCelebrationsSwitchBeforeStartingABurst` BY
  NAME when you move it — never delete it**, and keep proving the gate runs BEFORE anything is
  enqueued.
- **Two tests must survive the move UNCHANGED**, and both encode an E decision rather than an
  implementation detail: `testTheCelebrationsSwitchNeverSilencesTheConfirmHaptic` (E's #3 — the
  switch covers the full-screen celebration alone; the haptic lives in `RootBottomOverlay` and stays
  outside it) and `testTheConfirmCelebrationIgnoresReduceMotionByDesign` (the §7.2 waiver, now over
  six files).
- **The switch is live and E may have it OFF.** Anything you drive by hand on the phone — and every
  render probe — has to say which state it was in. A "the confetti didn't play" bug report is
  the switch until proven otherwise.

## Four harness lessons worth a run each, from blocks 1 and 2

- **A call-site guard must be scoped to its CLOSURE, not its file.** `feedbackSection` holds six
  Toggles of identical shape; a whole-file `contains()` is green on a tree where the new row stores
  nothing. Extract one closure between two unique anchors and throw loudly if an anchor has moved.
- **Write the red prediction in TWO parts when the block introduces a symbol.** A test naming a
  symbol that does not exist cannot fail — the target cannot BUILD and the harness prints no count.
  Predict the source-reading tests' red separately from the build failure.
- **Never assert a field's own DEFAULT value in a round-trip test.** The omission it exists to catch
  resets the field to exactly that. Set the value away from its default, and where there are two
  fields, to opposite states, so a swap is caught too.
- **A "nothing drew" render proves nothing without its CONTROL.** Render the same scene with the
  feature forced ON, assert the control FIRST, and put it in the evidence folder. Block 2's numbers:
  0 differing pixels with the switch off, 943,200 of 943,200 with it on.

## Then, strictly in order, one per review

`F-CTACelebrations-4` (the nine pops; render on a real `TaskRow` FIRST, E picks — **and this is the
first block that owes an RM-on device pass**, §7.3) → `-5` (inbox zero, streak on 7, daily goal;
**room first** — `CaptureInboxService.swift` is at 397; E's cooldown call) → `-6` (the routine
Completed flow; render the congratulation first; reverses leave-ends-run, update the pinning tests
by name) → `-7` (the chime; E picks by ear). Then `F-FocusCard-Corners`.

## How to run each block

- Test-first with a written red prediction; red-checks on a committed tree; `swiftlint lint` 0; the
  full suite with the emulator up and 0 `127.0.0.1:9099` hits; the sim build; in-situ renders or a
  probe (removed before commit); the PR; the phone from `main`; E's verdict; the register rewritten
  at close-out. Every report carries a Verified-paths line (§7.3).
- Tokens only (§4), the 4/8/16/24 grid (§2), haptics through `Theme/Haptics.swift`, prose test
  names, loud call-site guards. **The cooldown constant stays 5 s** (register §A).
- Use the installed skills, MCPs and subagents (E's standing ask, restated again 2026-09-12): the
  TDD skill, `RenderPreview` via the `xcode` bridge for stills when it is up, **a
  `feature-dev:code-reviewer` pass over the diff before the PR**, and — new this session, and it
  earned its place — **an `apple:hig-reviewer` pass over any finished USER-FACING surface**. It
  found two real copy defects in block 2 that the code reviewer did not, and correctly declined
  twice to recommend undoing settled design. `SendUserFile` for renders.

## Environment notes

- **Open Xcode on the project BEFORE starting the session.** It was NOT open at the start of block
  2's session, so the `xcode` MCP bridge reported `CONNECTION_CLOSED` and `RenderPreview` was
  unavailable for the whole session. There is no in-session recovery.
- **A stale `TestResults.xcresult` fails the suite before a single test runs**
  (`xcodebuild: error: Existing file at -resultBundlePath`). It is gitignored, so it survives
  everything; `rm -rf` it as part of the run rather than reading the exit code as a test failure.
- **The emulator may ALREADY be running from a previous session.** `./scripts/emulators.sh` fails
  with "port taken" rather than reusing it; `curl -s 127.0.0.1:4400/emulators` tells a live harness
  from a broken one, and E's instruction (2026-09-12) is to use the running one if you can. Started
  fresh this session with `nohup ./scripts/emulators.sh &`, which detaches cleanly.
- **Test simulator:** iPhone 17 Pro `9181EBF9-0F54-4A4D-A19C-19945D1BF155` (iOS 26.5, the only
  runtime). **A UI-target run poisons it — erase before the next unit run.** None was run in block 2.
- **E's phone:** `3DBC979A-3255-5456-8C30-172DB19B99B3` (`wishwashwacky15`, an iPhone **15** Pro).
  **Its dev profile expires 2026-09-17**; when an install fails, E re-signs in Xcode → Settings →
  Accounts. Install recipe:
  `xcodebuild build -destination 'platform=iOS,id=<udid>' -allowProvisioningUpdates`, then
  `xcrun devicectl device install app --device <udid> "<…>.app"` and
  `… process launch --device <udid> --terminate-existing com.ethananthony.ADHD-LifeOS`.
- **Baseline at close** (`f31ec6d`, merged as `2efd705`): suite 2,757 / 0, lint 0 / 762, app
  coverage 27.05 % (12,659/46,799).

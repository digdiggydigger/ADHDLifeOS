# START HERE — build `F-CTACelebrations-6` (the routine Completed flow, R1–R5)

*A disposable pointer (CLAUDE.md, "Session handoff"): paste this path into a fresh Claude Code
terminal. Written 2026-09-12 at the close of the session that built `F-CTACelebrations-5`. **The
session that writes this arc's next opener archives this file in the same move.***

**STATUS.** Blocks 1–6 of the arc are MERGED. Blocks 1–4's verdicts all PASSED.

**`-4` AND `-5` both await ONE device sitting, and E owes it now.** E deferred `-4`'s passes until
after `-5` (2026-09-12, verbatim: *"I will push the device passes off until after the next
block."*), so the ask covering both was made at the close of `-5`. **If E has not answered when this
session starts, do NOT re-ask and do NOT treat either block as unverified work to redo** — both are
landed, green and installed on the phone from `main`. If E HAS answered, record the verdict in the
register before doing anything else.

The app code is `main` @ `5e10586`; check `git log --oneline -1 origin/main` for today's tip rather
than trusting a SHA written here.

**E's standing instruction: each block is built in a FRESH Claude Code terminal session.** This
file is how that session starts.

## Read first, in this order

1. CLAUDE.md's start-of-session checklist: `claudecode.md`, "Architecture notes" (it has a
   celebrations entry), and **§7** — especially **§7.3's RM-on device pass**, which this block owes
   if it adds or changes a reduced site (it does: the congratulation view under Reduce Motion).
2. **`handoff/OPEN-ITEMS-REGISTER.md`** (thirty-sixth edition) — THE outstanding list. §A holds the
   device sitting, **the accessibility answer that needs RE-ASKING on a false premise**, and E's
   cooldown call. **§B.00 lists the four things `-5` leaves this block; §0b is a surfaces question
   the HIG pass opened and nobody has answered.**
3. **`handoff/SESSION-OPENER-cta-celebrations-design.md`** — the design. For THIS block: **R1–R5**
   (the whole Completed flow), **R-f** (an auto-only or all-skipped run completes quietly), **R-h**
   (the Completed button is a site with no pop of its own), and the "Engineering constraints"
   section, which names the file splits.
4. `TODO-CLAUDE-CODE.md` — the block `F-CTACelebrations-6` under `# ⚠ CLAUDE CODE ADDITIONS`, and
   the six-point list of how `-5` differed from its plan, directly above it.
5. `screenshots/cta-celebrations-block-5/README.md` — the probe technique, and the one trap in
   "How to rebuild the probe". You will be rendering a view before you wire it.

## The block — `F-CTACelebrations-6`

**RENDER FIRST, and this is not optional: the block as written says the congratulation view is
rendered (light, dark, Reduce Motion, the switch-off beat) and SENT to E before anything is
wired.** E picks by looking, as they did for the pop in `-4`. Do not build the flow and then show
it.

- **Room first, its own commit.** `PlaceRoutineScreen.swift` is at **384** of SwiftLint's 400. The
  design names the move: the Completed pieces are NEW files
  (`Places/PlaceRoutineCompletedCard.swift`, `Places/PlaceRoutineCongratulationView.swift`, and a
  `PlaceRoutineScreen+Completion.swift` for `complete()` if the screen nears 400).
  **Run the full SUITE after the move, not just lint and the build** — `-3`, `-4` and `-5` all
  proved a room-first move can pass both and still break a call-site test that reads the file it
  emptied. Read the tests that name the file BEFORE moving anything.
- **It REVERSES an E-settled rule.** The routine-record arc's "a run ends when you LEAVE the
  screen" becomes "leaving keeps it open" (R1). Every test pinning the old rule — `isFullyResolved`
  / `leaveScreen` / `reason: .completed` in `ADHD LifeOSTests/`, and the routine UI journey — is
  updated **BY NAME**, and each is named in the block report as reversed by E's R1. The
  background-with-everything-resolved auto-end goes with it.
- **The Completed card** fills the next-step slot once nothing is pending and the run is fully
  resolved (done OR skipped). **`complete()`**: `.success` → `store.end` + `recorder.ended(.completed)`
  → `activity.ended(); DataChangeSignal.post()` → `celebrate.request(.milestone(.routineFinished), at:)`
  on the cover's OWN layer (NOT held — `routineCover.dismissesItself` is false) → the congratulation.
- **`CelebrationPopCallSiteTests`' hand-recorded origin count moves 3 → 4**, because the Completed
  button is R-h's second site with no pop of its own. The WRAPPER count stays 9. Update the count
  and its message deliberately, in the same commit.
- **`CelebrationPopOrigin.onScreen` exists now** (`-5`) and you should think about whether the
  Completed button needs it. It probably does NOT — the routine cover is presented, not parked —
  but say so in the report rather than leaving it unconsidered.

## The four things `-5` leaves this block — do not rediscover them

- **Render the congratulation view before wiring it.** Above, and in the block as written.
- **Room first:** `PlaceRoutineScreen.swift` 384.
- **The origin count moves to 4.**
- **`-5`'s accessibility question is OPEN, and it touches this block.** E chose "the daily goal
  only" announces itself, on the stated grounds that the other milestones leave the user on a
  screen that states the outcome. **For the streak that premise is false** (register §A: the nudge
  card vanishes on dismissal exactly as on any other day), and it is back with E. **For THIS
  block's milestone the premise is TRUE and then some** — the congratulation view is a full screen
  of text naming the user and the routine, so it is readable by VoiceOver whatever E decides about
  the others. Say that in the report; do not add an announcement here without asking.

## Harness lessons worth a run each, from blocks 1–5

- **Three defects in `-5` were found AFTER the suite was green, and none was reachable by an
  assertion.** One by LOOKING at a render and asking what a coordinate meant, two by the
  `feature-dev:code-reviewer` pass — and one of those two was a defect in the block's own fix. Run
  both review passes before the PR, and read a render rather than filing it.
- **A "naive first pass" proves a guard load-bearing without waiting for a real regression.** Write
  the implementation WRONG on purpose first, watch exactly the intended tests go red, then write it
  properly. `-5` did this three times, and one guard was green on the original code and red only on
  the naive fix — nothing else would have shown it meant anything.
- **A COUNT cannot see a SWAP.** `-5`'s deliberate regression moved a call from one verb to
  another; nine tests went red and the count guard was not one of them. Keep a named guard beside
  every count.
- **A guard that reads the wrong text is worse than no guard.** `-5` wrote two: one sliced to the
  next `)` and landed inside a closure argument, one anchored on a COMMENT line that `stripped`
  removes. Both surfaced only because the red PREDICTION missed. **Investigate a miss before
  accepting it.**
- **Predict in TESTS and in ASSERTIONS, separately.** `-5`'s deliberate regression predicted
  9 / 11 and observed 9 / 11, test for test.
- **Prove the render harness deterministic BEFORE any pixel claim**, and give every "identical"
  claim a control that shows the comparison can see a real difference. `TimelineView` draws at the
  REAL instant, so a still must go through `CelebrationFrame` at a fixed date.
- **To render the real feature and not a picture of its drawing**, drive the real service and the
  real centre and mount the real layer — `-5`'s 00/01 pair is the shape.

## Then, strictly in order, one per review

`F-CTACelebrations-7` (the chime; E picks by ear). Then `F-FocusCard-Corners`.

## How to run each block

- Test-first with a written red prediction in TESTS and ASSERTIONS; red-checks on a committed tree;
  `swiftlint lint` 0; the full suite with the emulator up and 0 `127.0.0.1:9099` hits; the sim
  build; in-situ renders or a probe (removed before commit); the PR; the phone from `main`; E's
  verdict; the register rewritten at close-out. Every report carries a Verified-paths line (§7.3).
- Tokens only (§4), the 4/8/16/24 grid (§2), haptics through `Theme/Haptics.swift`, prose test
  names, loud call-site guards.
- Use the installed skills, MCPs and subagents (E's standing ask): the TDD skill, a
  `feature-dev:code-reviewer` pass over the diff before the PR, and an `apple:hig-reviewer` pass
  over any finished user-facing surface. `SendUserFile` for renders.
- **Ask for device passes in ONE message** (Reduce Motion off, then on) so E flips the setting once.

## Environment notes

- **Open Xcode on the project BEFORE starting the session** or the `xcode` MCP bridge is absent for
  the whole session with no recovery. `RenderPreview` has failed on this project twice; **do not
  sink time into it** — the run-loop-pumping probe is the sanctioned fallback, documented in
  `screenshots/cta-celebrations-block-5/README.md`.
- **A stale `TestResults.xcresult` fails the suite before a single test runs.** It is gitignored;
  `rm -rf` it as part of the run. It has been present at the start of the last three sessions.
- **The emulator may ALREADY be running from a previous session.** `curl -s 127.0.0.1:4400/emulators`
  tells a live harness from a broken one; E's instruction is to use the running one if you can.
- **An env var passed on the `xcodebuild` command line does NOT reach the test process** — it is
  taken as a build setting. A probe that writes files falls back to the simulator's own container
  `tmp`; read the path it PRINTS and copy the files out of there.
- **Test simulator:** iPhone 17 Pro `9181EBF9-0F54-4A4D-A19C-19945D1BF155` (iOS 26.5, the only
  runtime). **A UI-target run poisons it — erase before the next unit run.** This block runs the
  routine UI journey (it pins the reversed rule), so **order the erase to follow it
  unconditionally**.
- **E's phone:** `3DBC979A-3255-5456-8C30-172DB19B99B3` (`wishwashwacky15`, an iPhone **15** Pro).
  **Its dev profile expires 2026-09-17**; when an install fails, E re-signs in Xcode → Settings →
  Accounts. Install recipe:
  `xcodebuild build -destination 'platform=iOS,id=<udid>' -allowProvisioningUpdates`, then
  `xcrun devicectl device install app --device <udid> "<…>.app"` and
  `… process launch --device <udid> --terminate-existing com.ethananthony.ADHD-LifeOS`.
- **Baseline at close** (`2498c9b`, merged as `5e10586`): suite 2,884 / 0, lint 0 / 791, app
  coverage 27.39 % (13,050/47,646).

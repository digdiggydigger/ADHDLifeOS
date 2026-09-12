# START HERE — build `F-CTACelebrations-2` (the two switches; Celebrations live on Confirm)

*A disposable pointer (CLAUDE.md, "Session handoff"): paste this path into a fresh Claude Code
terminal. Written 2026-09-12 at the close of the session that built `F-CTACelebrations-1`. **The
session that writes this arc's next opener archives this file in the same move.***

**STATUS.** Blocks 1 and 2 of the arc are MERGED and **both PASSED E's device verdict**.
`F-ConfirmCelebration-2` (fireworks + light dim, `9a7b664`, PR #76): *"it looks good."*
`F-CTACelebrations-1` (the four haptic tidies + the closure card's spring-in, PR #80, `main` @
`49c78d9`): **PASSED 2026-09-12 BY FEEL**, E: *"it feels good, all five work as you described."*
Nothing is owed from block 2 — start this one. E's phone runs the block-2 build.
No gate question is owed; E approved the record and R-a…R-h on 2026-09-12. **E's instruction for
this session, verbatim: *"go with (a), start block 3 in a fresh Claude code terminal session"*** —
(a) is the RM-on device pass, now settled in §7.3 and closed in register §A.

**READ THIS BEFORE WRITING A REDUCED PATH. E TURNED REDUCE MOTION OFF ON 2026-09-12**
(*"I no longer run with reduce motion on"*), reversing a fact this project designed around for
months. **CLAUDE.md §7.2's rule is UNCHANGED** — it rests on Apple's guidance and the public-launch
intent, not on E's setting, so keep writing complete reduced branches and keep testing both paths
by string (§7.4). What changed is COVERAGE: the reduced path used to be exercised daily on a real
phone by the person reviewing every block, and now runs only where a test injects it.

**E's call, 2026-09-12 — the RM-ON DEVICE PASS is now part of the bar (§7.3):** a block that adds or
changes a REDUCED site is not done until E has also looked at it on the phone with Reduce Motion
turned ON. Ask for both passes in ONE message so E flips the setting once. **THIS BLOCK OWES NO
RM-ON PASS** — two switches, a preferences round-trip and a fire-time gate add no new reduced
rendering, and the one thing they gate (the Confirm celebration) is §7.2's waiver and renders
identically either way. **Say in the report why none was owed**, rather than silently omitting it.
The first block that owes one is `F-CTACelebrations-4`, the nine pops.

## Read first, in this order

1. CLAUDE.md's start-of-session checklist: `claudecode.md`, "Architecture notes", and **§7**.
   Block 3 adds no `#available` site, but §7.2 governs the switch's reduced behaviour.
2. **`handoff/OPEN-ITEMS-REGISTER.md`** (thirty-second edition) — THE outstanding list. §A holds
   the pending verdict and the cooldown decision (5 s, untouched until `F-CTACelebrations-5`);
   **§C2 is new** — a Reduce Motion sibling-reflow question for E's eye on device.
3. **`handoff/SESSION-OPENER-cta-celebrations-design.md`** — the design. For THIS block: §4 "The
   switches and the chime" (the FOUR-place `MomentumPreferences` edit), and E's decisions #3 and F5.
4. `TODO-CLAUDE-CODE.md` — the block `F-CTACelebrations-2` under `# ⚠ CLAUDE CODE ADDITIONS`.
5. `screenshots/cta-celebrations-block-1/README.md` — the render-probe technique and the three
   harness lessons below, as evidence.

## The block — `F-CTACelebrations-2`

- **No room-first commit needed.** `MomentumPreferences.swift` and `SettingsPreferenceSections.swift`
  are both well under the 400-line ceiling; check before editing, not after.
- `MomentumPreferences`: `celebrationsEnabled` (default **true**) and `celebrationSoundsEnabled`
  (default **false**), **each the FOUR-place edit the file documents** — stored property, memberwise
  default, `decodeIfPresent ?? default`, `normalized()`. An omitted place silently resets the field,
  which is exactly the kind of bug no round-trip test catches unless it round-trips through
  `normalized()` with both OFF.
- `Settings/AppFeedback.swift` gains `celebrationsEnabled(store:)` / `celebrationSoundsEnabled(store:)`,
  read at **FIRE time** (the `hapticsEnabled()` precedent — flipping the switch takes effect on the
  very next tap, with no relaunch).
- Two Toggles after "Haptics" in `SettingsPreferenceSections.swift`'s `feedbackSection`, identical
  in shape, ids `settingsCelebrationsToggle` / `settingsCelebrationSoundsToggle`, one footer
  sentence each.
- `ConfirmCelebrationOverlay` gates on `AppFeedback.celebrationsEnabled()` at fire time, **so the
  row is never a lie.** The sound switch goes live with block 7's player — say so in its footer.
- **Tests:** defaults; a pre-existing blob keeps its values; `normalized()` keeps both OFF; the
  Feedback section carries both with ids and writes; the Confirm layer reads the switch at fire
  time. Predicted red 5 / 5 — write the prediction down, then reconcile TESTS against the
  assertion count the harness prints.
- **Evidence:** the Feedback section light + dark (`RenderPreview` via the `xcode` bridge is
  sanctioned for stills), and Confirm with the switch OFF proved pixel-identical to a
  never-mounted window. Device verdict: the switch off means nothing plays.

## Three harness lessons from block 2 that will save this session a run

- **A call-site guard must be scoped to its CLOSURE, not its file.** Three of block 2's four files
  already held the target feel at a different site; a whole-file `contains()` would have been green
  on a tree where the new site did nothing. Extract one closure between two unique anchors and
  throw loudly if an anchor has moved.
- **When a render cannot resolve the property, MEASURE it and publish the number.** Block 2's
  sheets could not show a 0.9 scale at the opacity the card is first visible at, so the probe read
  the rendered width off the `CGImage` — 340–346 pt against a settled 370 pt, reproduced three
  times.
- **A measurement that reports nothing for a control that cannot move is measuring the wrong
  pixels.** Block 2's first scan band sat in the hosting controller's ~59 pt safe-area inset. And a
  harness whose else-branch is empty renders the inserted card unreliably — keep content in both
  branches.

## Then, strictly in order, one per review

`F-CTACelebrations-3` (`CelebrationCenter` + `CelebrationLayer` per surface; **room first** —
`RootView.swift` is at 394; the shared frame now carries the fireworks and the dim too, and the
waiver pin lists SIX Confirm files) → `-4` (the nine pops; render on a real `TaskRow` FIRST, E
picks) → `-5` (inbox zero, streak on 7, daily goal; **room first** — `CaptureInboxService.swift` is
at 397; E's cooldown call) → `-6` (the routine Completed flow; render the congratulation first;
reverses leave-ends-run, update the pinning tests by name) → `-7` (the chime; E picks by ear).
Then `F-FocusCard-Corners`.

## How to run each block

- Test-first with a written red prediction; red-checks on a committed tree; `swiftlint lint` 0; the
  full suite with the emulator up and 0 `127.0.0.1:9099` hits; the sim build; in-situ renders or a
  probe (removed before commit); the PR; the phone from `main`; E's verdict; the register rewritten
  at close-out. Every report carries a Verified-paths line (§7.3).
- Tokens only (§4), the 4/8/16/24 grid (§2), haptics through `Theme/Haptics.swift`, prose test
  names, loud call-site guards. **The cooldown constant stays 5 s** (register §A).
- Use the installed skills, MCPs and subagents (E's standing ask, restated 2026-09-12): the TDD
  skill, the `xcode` bridge's `RenderPreview` for stills, a `feature-dev:code-reviewer` pass over
  the diff before the PR (it earned its place in block 2 — it caught a guard that read one file
  while claiming every write), `SendUserFile` for renders.

## Environment notes

- **Open Xcode on the project BEFORE starting the session**, or the `xcode` MCP bridge is absent all
  session.
- **The emulator may ALREADY be running from a previous session.** `./scripts/emulators.sh` fails
  with "port taken" rather than reusing it; `curl -s 127.0.0.1:4400/emulators` tells a live harness
  from a broken one, and E's instruction (2026-09-12) is to use the running one if you can.
- **Test simulator:** iPhone 17 Pro `9181EBF9-0F54-4A4D-A19C-19945D1BF155` (iOS 26.5, the only
  runtime). **A UI-target run poisons it — erase before the next unit run.**
- **E's phone:** `3DBC979A-3255-5456-8C30-172DB19B99B3` (`wishwashwacky15`, an iPhone **15** Pro —
  earlier openers did not say the model; paired and available 2026-09-12). **Its dev profile
  expires 2026-09-17**; when an install fails, E re-signs in Xcode → Settings → Accounts. Install
  recipe: `xcodebuild build -destination 'platform=iOS,id=<udid>' -allowProvisioningUpdates`, then
  `xcrun devicectl device install app --device <udid> "<…>.app"` and
  `… process launch --device <udid> --terminate-existing com.ethananthony.ADHD-LifeOS`.
- **A stray untracked `AGENTS.md`** (a Codex copy of CLAUDE.md) sits in the repo root. E,
  2026-09-12: *"ignore the codex copy files for now."* Never `git add -A`; add paths explicitly.
- **Baseline at close** (`844daae`): suite 2,747 / 0, lint 0 / 760, app coverage 27.07 %
  (12,643/46,702).

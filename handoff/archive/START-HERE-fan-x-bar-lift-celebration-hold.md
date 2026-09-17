# START HERE — build E's three calls from the 2026-09-17 device looks, back to back, one install

*Written 2026-09-17 ~06:10 BST by the session that collected E's device looks on the three blocks
shipped that morning. **That session built nothing, at E's instruction:** *"I suggest that any
building happens in a fresh Claude code terminal session."* **This is a disposable pointer. Archive
it when you write your successor.** Its predecessor, `archive/START-HERE-three-device-looks.md`, is
spent.*

## Read these first, in this order

1. `claudecode.md`, the TDD role definition.
2. `CLAUDE.md`: **Architecture notes**, **§2**, **§5**, **§7.1–7.5**. NOT `docs/`.
3. `handoff/OPEN-ITEMS-REGISTER.md`: **State** and **§B's first three items**.
4. **`TODO-CLAUDE-CODE.md`, the last section: "E's three calls from the 2026-09-17 device looks".**
   It holds all three FEATURE blocks, with E's words verbatim, the numbers, the shape the collecting
   session worked out, and the tests that must be REVERSED. That section is the spec; this file is
   only the pointer.
5. `screenshots/landscape-fab-overlap/README.md`: the two 2026-09-17 device sections (frames 16–21,
   E's GIF). **The measurements are done; do not re-derive them.**

## E's pacing call, which overrides the stop-after-each-block rule for THESE three

**Build all three back to back without stopping for review between them, then ONE install and ONE
set of phone looks** (E chose *"All three, one install"*). Each block still gets its own branch,
test-first work, a red-check, a PR merged to `main`, and pasted output (suite, SwiftLint, build).

1. **`F-FanXAtRest`**: the × drops to its resting corner while the fan is open (E's shape B). E called
   it a bug. Reverses `F-FanCardsFade`'s "the × stays where the + was", including a UI journey
   assertion.
2. **`F-CollapsedBarLift`**: the collapsed sprint bar stops dropping onto the tab bar, **in portrait
   AND landscape**. Its bottom lines up with the disc, and the alignment holds with several cards up.
   Reverses the 2026-09-09 flush drop and brings the bottom keyline back.
3. **`F-FanHoldsCelebration`**: a full-screen celebration waits while the capture fan is open.

## State when this was written

`main` @ the SHA `git log --oneline -1` prints; clean. No app Swift has changed since `9eb5198`.
Suite **3,029 / 0**, SwiftLint **0 / 819**, build green (37 distinct warnings) as of that SHA.
**The Firebase emulator is NOT running** (`lsof -iTCP:8080` was empty); start it with
`./scripts/emulators.sh` before a baseline or any UI journey (see the `emulator-freshness` memory).

**E's phone (iPhone 15 Pro, iOS 27.0) carries `main` @ `9eb5198`.** **Its profile expires
2026-09-17T19:25:02Z (20:25 BST).** After that the app will not open until it is reinstalled. Install
the finished three-block build, and check `xcrun devicectl list devices` first.

**Already settled on device that session, nothing owed:** the pill at 12 (*"looks perfect"*), and
`F-FanCardsFade` with Reduce Motion OFF and ON.

## The one message at the end

After the install: ask E, in ONE message, for (1) the × at its corner with a sprint running,
portrait, and on Tasks too (the search row rides down with the disc); (2) the collapsed bar's
margin, portrait and landscape, alone and under a Confirm card; (3) a sprint ending while the fan
is open, where the celebration should wait; (4) block 1's × move with **Reduce Motion ON**. Force-quit
and reopen after the install before asking (`relaunch-before-judging-device`).

## Carried, unchanged

- Frame 08's observation: the pushed-up disc floats over the hero's *Start another session* in
  portrait. An observation only; E has not raised it.
- Phase D's one unlooked-at delta: the schedule summary line's dimness in dark on 27.0.
- The colour-scheme arc: HELD.

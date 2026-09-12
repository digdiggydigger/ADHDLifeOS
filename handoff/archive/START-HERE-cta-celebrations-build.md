# START HERE — build the CTA celebrations arc

*A disposable pointer (CLAUDE.md, "Session handoff"): paste this path into a fresh Claude Code
terminal. Written 2026-09-11 at the close of the DESIGN session. **The session that writes this
arc's successor archives this file in the same move.***

**STATUS: DESIGNED AND RECORDED, NOTHING BUILT.** E, verbatim: *"YOU MUST NOT BUILD IT IN THIS
SESSION"* and *"You must start building this in a fresh claude code terminal session."* This is
that session.

## Before the first block: the gate

The design record is **`handoff/SESSION-OPENER-cta-celebrations-design.md`** (permanent). Its
"settled specification" is E's, verbatim. Its "Claude Code's recommendations" **R-a…R-h are NOT
decided**. **First action of this session: ask E whether the record is approved and how R-a…R-h are
ruled** (one message, the eight items listed with the default each takes). Do not start block 1
until E has answered. If E has already approved in chat before this session, say so and proceed.

## Read first, in this order

1. CLAUDE.md's start-of-session checklist: `claudecode.md`, "Architecture notes", and **§7** (the
   iOS 16 floor, modern APIs, Reduce Motion — the Confirm celebration is the ONE §7.2 waiver and this
   arc does not extend it).
2. **`handoff/OPEN-ITEMS-REGISTER.md`** (thirtieth edition or later) — THE outstanding list. §B.00 is
   this arc; §A holds the two decisions still open (the record review; the cooldown).
3. **`handoff/SESSION-OPENER-cta-celebrations-design.md`** — the design, every number, the
   constraints, the blocks.
4. **`handoff/SESSION-OPENER-confirm-celebration-design.md`** — the shipped engine this arc
   generalises, and the fireworks numbers block 1 builds.
5. `TODO-CLAUDE-CODE.md` — the eight blocks under `# ⚠ CLAUDE CODE ADDITIONS`, after
   `F-ConfirmCelebration-1`.
6. The evidence: `screenshots/confirm-celebration-block-1/README.md` (the render-probe technique)
   and `screenshots/confirm-celebration-prototypes/`.

## The blocks, strictly in order — one per review, E's device verdict closes each

1. **`F-ConfirmCelebration-2`** — the fireworks + light-mode dim, on the same stretch (≈ 6.43 s).
2. **`F-CTACelebrations-1`** — the haptic tidy + the closure card's spring-in.
3. **`F-CTACelebrations-2`** — the Celebrations and Celebration-sounds switches; Celebrations live
   on Confirm.
4. **`F-CTACelebrations-3`** — `CelebrationCenter`, `CelebrationLayer` per surface, Confirm
   re-routed; no new triggers.
5. **`F-CTACelebrations-4`** — the nine mini confetti pops. **Render the pop in situ on a real
   `TaskRow` FIRST and send the variants; E picks by looking.**
6. **`F-CTACelebrations-5`** — inbox zero, the streak on 7, the daily goal.
7. **`F-CTACelebrations-6`** — the routine Completed flow. **Render the congratulation view first.**
   Reverses the leave-ends-run rule; update the pinning tests by name.
8. **`F-CTACelebrations-7`** — the chime; E picks by ear.

Then `F-FocusCard-Corners`. Stop after each block for E's review; commit and push at the moment a
block is ticked; land through a PR; paste the four-line close-out.

## How to run each block

- **Test-first with a written red prediction**, red-checks on a committed tree, `swiftlint lint` 0,
  the full suite with `./scripts/emulators.sh` up and 0 `127.0.0.1:9099` hits, the sim build,
  in-situ renders or a probe, the PR, the phone from `main`, E's verdict.
- **Room first, own commit**, for any file at the ceiling: `RootView.swift` 394, `HomeView.swift`
  399, `HomeMomentumSections.swift` 399, `CaptureInboxService.swift` 397, `PlaceRoutineScreen.swift` 379.
- **Show, don't describe.** Throwaway render probes from the test target (a scene-attached
  `UIWindow` + `drawHierarchy(afterScreenUpdates: true)`, an injected time, ffmpeg), removed before
  commit; `RenderPreview` via the `xcode` MCP bridge for stills. Send with `SendUserFile`.
- **Every report carries a Verified-paths line** (§7.3). The arc is single-implementation
  (`Canvas`, `TimelineView`, `onGeometryChange` back-deployed to 16.0): "no tier adds value".
- **The cooldown constant is 5 s for E's testing** — do not "correct" it to 30 min; the value and
  its existence are E's open decision (register §A).
- **Tokens only (§4, `raw_hue_color`), the 4/8/16/24 grid (§2), haptics through
  `Theme/Haptics.swift`**, prose test names, loud call-site guards.

## Environment notes

- **Open Xcode on the project BEFORE starting the session**, or the `xcode` MCP bridge is absent all
  session (it was UP in the design session).
- Start the Firebase emulator (`./scripts/emulators.sh`) before the suite.
- **Test simulator:** iPhone 17 Pro `9181EBF9-0F54-4A4D-A19C-19945D1BF155` (iOS 26.5, the only
  runtime). **A UI-target run poisons it — erase before the next unit run.**
- **E's phone:** `3DBC979A-3255-5456-8C30-172DB19B99B3`. **Its dev profile expires 2026-09-17**;
  when a device install fails on it, E re-signs in Xcode → Settings → Accounts.
- **Baseline at close** (carried from `967472a`): suite 2,710 / 0, lint 0 / 751, app coverage 26.87%.

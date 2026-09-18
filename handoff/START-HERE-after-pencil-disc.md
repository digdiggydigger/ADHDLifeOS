# START HERE — after F-JournalPencilDisc: nothing to build; E's device look is the next move

*Written 2026-09-18 by the session that BUILT `F-JournalPencilDisc` (PR #160, merge `654012f`). A
disposable pointer: archive it when you write your successor. Its predecessor,
`archive/START-HERE-journal-pencil-disc.md`, is spent — the block it asked for is built and merged.*

## Read these first

1. `claudecode.md`, then `CLAUDE.md`'s Architecture notes, §1-§5 and §7. NOT `docs/`.
2. `handoff/OPEN-ITEMS-REGISTER.md`: the sixty-second edition's **State** block. It has the figures,
   what landed, and the exact list of looks owed.
3. `TODO-CLAUDE-CODE.md`, the last section (`F-JournalPencilDisc`, `[x] COMPLETED`): its "Built …
   and where it departs" list is the record of every judgement call.
4. `screenshots/journal-pencil-disc/README.md`.

## State

`main` @ `654012f` (+ the close-out docs). Suite **3,085 / 0**, SwiftLint **0 / 831**. The phone:
see the register's **Device** line — blocks 1 + 2 went on TOGETHER.

## What to do

**Nothing is to be built until E has looked.** The next move is E's device verdict on the Journal
(the kept nav bar, the pencil disc, the re-tap), the 24pt gap, and one Reduce Motion ON pass — all on
the one install. Take E's answers as they come:
- **A pass:** tick it in the register; update memory `journal-door-arc` and `fab-overlap-and-tab-inset`.
- **A change to the look** (size, colour, placement, glow): that is a design decision. Render the
  options, let E choose, and — E's standing rule — BUILD it in a fresh session.
- **A defect:** reproduce first (memory `relaunch-before-judging-device`: force-quit and reopen before
  judging), then TDD.
- **The optional landscape Note-tile check:** if the composer does NOT open on the phone, it is a real
  app bug that predates this block (the landscape sweep fails on `main` @ `aec558a` too) — a new block,
  E's priority call. If it DOES open, the sweep test is at fault — fix the test.

## Carried, unchanged

- The colour-scheme arc stays **HELD** (E, 2026-09-13; re-confirmed 2026-09-18).
- `F-Search-3-Journal`: its objection is LIVE — the band left of the disc is the pencil's. Not to be
  started unasked.
- The cards' VoiceOver gap under the fan (`F-FanCardsFade`): the fix the pencil got
  (`.accessibilityHidden(!fanPresence.acceptsTouches)`) — small, below the bar, not started.

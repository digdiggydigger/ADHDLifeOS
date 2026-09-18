# START HERE — build F-JournalPencilReachable: restore the Journal's nav bar, pencil filled accent

*Written 2026-09-18 at the close of the session that built block 1 and rendered block 2's options.
**This is a disposable pointer. Archive it when you write your successor.** Its predecessor,
`archive/START-HERE-journal-door.md`, is spent.*

## Read these first

1. `claudecode.md`, then `CLAUDE.md`'s Architecture notes, §1-§5 and §7 — NOT `docs/`.
2. `handoff/OPEN-ITEMS-REGISTER.md` — the sixtieth edition's **State** block.
3. `TODO-CLAUDE-CODE.md`, the LAST section: `F-JournalPencilReachable`. **It is the approved plan** —
   E's two answers verbatim, Step 0, the decisions, the tests to reverse, the acceptance criteria.
4. `screenshots/journal-pencil-options/README.md` (what E chose from) and
   `screenshots/journal-door-unpinned/README.md` (the render rig and its gates).

## State

`main` @ the merge of this hand-off (block 1 is `6656866`, the options folder `5cbbc01`). Suite
**3,057 / 0**, SwiftLint **0 / 826**, both at `d1b3601` (block 1's code; nothing since touched Swift).

**Block 1 is MERGED and NOT on the phone.** The phone still carries `c54efd7`. That is deliberate:
block 1 alone leaves the Journal with no door once scrolled, so **install both blocks together, in
one build, after block 2** — then force-relaunch, then ask E for the look. Profiles run to
**2026-09-24T19:49Z**. The Firebase emulator will be down; start it before any suite or journey.

## What to build

`F-JournalPencilReachable`, exactly as specced. E chose **"(b) Restore a nav bar"** and
**"Filled accent"**. **Do Step 0 first** — a throwaway probe build, before any test:
(i) is `.glassProminent` visibly different from `.borderedProminent` in a toolbar on 26.5? If not, one
style and no `#available`; (ii) render the combination E will get (eye plain, pencil filled, in a
`ToolbarItemGroup`) and, if it differs materially from the capsule E chose, send E a before/after and
confirm before building. The riskiest mechanic is the tab re-tap: `scrollTo(anchor: .top)` under a
large title — render scrolled → `coordinator.reselect(.journal)` and prove the title re-expands.

## The render rig — use it, don't re-derive it

Memory `full-screen-render-harness`, updated this session. The two things that cost time: **pin the
393×852 window to the BOTTOM of the simulator's 874pt screen**, or it inherits only 12 of the 34pt
home-indicator inset and every bottom edge is 22pt out; and use **static switches read at body time**
so every variant renders from ONE build (each build is ~10 minutes on this machine). Targeted
`xcodebuild test` runs want `-enableCodeCoverage NO` — a coverage-on run hung 20 minutes in
post-processing after its tests had finished.

## Owed by E, carried, NOT blocking

1. **The 24pt gap** — portrait AND landscape, collapsed bar alone and under a Confirm card. (The
   Journal-alignment half is moot: block 1 deleted the composer.)
2. **Reduce Motion ON** — open and close the capture fan with a card up: the cards must FADE, not cut.

Both belong on the same install as blocks 1 + 2, so E looks once.

## Carried, unchanged

- The colour-scheme arc: **HELD**.
- `F-Search-3-Journal`: its objection is void (the bar is gone and E chose (b), so the disc's band is
  free). Noted; not to be started unasked.
- Frame 08's pushed-up disc observation; Phase D's dark schedule-summary dimness.

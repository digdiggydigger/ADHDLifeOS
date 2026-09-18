# START HERE — build the Journal door arc (E chose option 04), then the pencil

*Written 2026-09-18 at the close of the session that rendered the door options. **This is a
disposable pointer. Archive it when you write your successor.** Its predecessor,
`archive/START-HERE-after-gap-24.md`, is spent.*

## Read these first

1. `claudecode.md`, then `CLAUDE.md`'s Architecture notes, §1-§5 and §7 — NOT `docs/`.
2. `handoff/OPEN-ITEMS-REGISTER.md` — the fifty-ninth edition's **State** block.
3. `TODO-CLAUDE-CODE.md`, the LAST section: `F-JournalDoorUnpinned` and `F-JournalPencilReachable`.
4. `screenshots/journal-door-options/README.md` — **the measurements are done; do not re-derive them.**

## State

`main` @ `79fa171`, clean. Suite **3,053 / 0**, SwiftLint **0 / 824** (both as of `c54efd7`; the two
commits since are evidence and spec only, no Swift changed).

**The phone carries `c54efd7`** — Swift-identical to `173ba7d`. **Profiles were re-issued 2026-09-17
19:49Z and expire 2026-09-24T19:49Z**, so there is a week of runway. If a device build ever fails on
`No Accounts`, that is E's Xcode → Settings → Accounts step and it recurs roughly weekly
(`app-group-provisioning-blocker`).

The Firebase emulator is **NOT running**; start it before any baseline or journey
(`emulator-freshness`).

## What to build

**Both blocks, in order, in this session** — E asked for the pencil work "in a fresh session", and
block 1 is what makes it urgent. Block 1 removes the only persistent door; block 2 restores
persistence. Shipping 1 alone leaves the Journal with no door once scrolled.

`F-JournalPencilReachable` is marked **[BLOCKED]** on purpose: three shapes, E has not chosen.
**Render options and ask** (`show-dont-describe-geometry`) rather than guessing.

## The render harness — it exists now, and it is not obvious

`ImageRenderer` **cannot** render a whole screen: a `NavigationStack` gives SwiftUI's yellow
placeholder and `ScrollView` + `LazyVStack` come out EMPTY, both as plausible-looking images. Use
`UIHostingController` in a key `UIWindow` + `drawHierarchy`, and **gate every frame on a number
already measured on E's device**. Full recipe, including the three gates and the vacuity trap that
caught this session out, is in memory `full-screen-render-harness` and the options README.

## Owed by E, carried, NOT blocking this work

1. **The 24pt gap** — portrait AND landscape, collapsed bar alone and under a Confirm card. **The
   Journal-composer-alignment half of this look is now MOOT**: block 1 deletes the composer that was
   the reference.
2. **Reduce Motion ON** — open and close the capture fan with a card up: the × jumping is by design
   (§7.2); the cards must FADE, not cut. Still the one regression nothing on the sim has proved.

## Carried, unchanged

- The colour-scheme arc: **HELD**.
- `F-Search-3-Journal` is **unblocked** by block 1 (its objection was that the band held a field).
  Note it; do not start it.
- Frame 08's pushed-up disc observation; Phase D's dark schedule-summary dimness.

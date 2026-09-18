# START HERE — build F-JournalPencilDisc: the nav bar stays (eye alone), the pencil is a 42pt disc beside the +

*Written 2026-09-18 by the session that ran `F-JournalPencilReachable`'s Step 0. **E revised the shape
by looking at it, so, per E's standing rule, that session built nothing and handed off.** This is a
disposable pointer: archive it when you write your successor. Its predecessor,
`archive/START-HERE-journal-pencil-navbar.md`, is spent.*

## Read these first

1. `claudecode.md`, then `CLAUDE.md`'s Architecture notes, §1-§5 and §7. NOT `docs/`.
2. `handoff/OPEN-ITEMS-REGISTER.md`: the sixty-first edition's **State** block.
3. `TODO-CLAUDE-CODE.md`, the LAST section, `F-JournalPencilDisc`. **It is the approved plan**: E's
   answers verbatim, Step 0's measured facts, the decisions, the tests to reverse, and the acceptance
   criteria. The block before it, `F-JournalPencilReachable`, is SUPERSEDED IN PART. Read it for the
   why; do not build it.
4. `screenshots/journal-pencil-step0/README.md`: what E chose from, and the re-tap measurements.
   Also `screenshots/journal-door-unpinned/README.md`: the render rig and its gates.

## State

`main` @ the merge of this hand-off. Suite **3,057 / 0** and SwiftLint **0 / 826**, both at
`d1b3601` (block 1's code). **No Swift has changed since**: this session's probes were temporary and
reverted, and `git status` was empty before anything was committed.

**Block 1 (`F-JournalDoorUnpinned`) is MERGED and NOT on the phone.** The phone still carries
`c54efd7`. Block 1 alone leaves the Journal with no door once scrolled.
- **Install:** blocks 1 + 2 together, in one build, after this block. Force-relaunch, THEN ask E
  for the look. Profiles run to **2026-09-24T19:49Z**.
- **Emulator:** DOWN. This session stopped it cleanly at close-out (the `emulators:start` parent
  only; the `firebase mcp` was left alone). Start it before any suite or journey.

## What to build

`F-JournalPencilDisc`, exactly as specced. In one breath:
- **the nav bar:** restore it with the large title; the eye goes ALONE into the toolbar (OFF
  `.primary`, ON accent);
- **the pencil:** a **42pt** disc filled with the + disc's two colours, **gradient REVERSED**
  (accent top → `CaptureDeep` bottom), with the + disc's **glow**. E: *"twins with halos"*. White
  glyph. It sits in `RootBottomOverlay`'s disc row, 16pt left of the +, centred on
  its line, and on the Journal at its root only;
- **the pill:** the disc follows the + disc's pill translucency (0.68) on the same curves;
- **the fan:** the disc fades with the cards while the fan is open;
- **the re-tap:** fix it so the large title comes back. This is iOS 26+ only, UIKit-assisted, with
  the shipped `proxy.scrollTo` as the floor.

**No design question is open.** Everything E was asked is answered and recorded. The spec lists what
E has NOT seen: the final disc (reversed gradient + glow), a sprint card up, landscape, the fan open, and a tab
switch. **Render those to VERIFY them. If one shows something E has not decided (the disc on a card,
a tile or the gear), STOP and ask. Do not improvise.**

**The re-tap is the riskiest mechanic, and Step 0 measured it** (the spec's table):
- `proxy.scrollTo` and iOS 18 `ScrollPosition.scrollTo(edge: .top)` both leave the bar at **54pt,
  collapsed**.
- A UIKit offset to the expanded top restores **106pt**.
- An overscroll written with no finger down settles at the expanded top by itself, so the fix
  FINDS that top instead of hard-coding the 52pt band.
- Tasks never collapses, so it is NOT a control. Leave it, and the four hidden-bar tabs, exactly as
  they are.

## The render rig — reuse it, don't re-derive it

Memory `full-screen-render-harness`, plus what this session added:
- **Measure the nav bar in the hosted window:** find the `UINavigationBar` (frame height 106 at rest
  and 54 collapsed, on both runtimes). Also read the main `UIScrollView`'s `contentOffset` and
  `adjustedContentInset.top`.
- **A SwiftUI button's `accessibilityIdentifier` is NOT on any `UIView`**, so find furniture by
  pixels:
  - the disc: an accent run down x = 339pt, centre 695.8;
  - the pencil at 42pt: centred at x = 309 − 16 − 21 = 272pt.
- **27.0 is E's OS: render there first and on 26.5 second**, in one chained command, sequentially.

The Step 0 probes' patch scripts were throwaway, and they are not in the repo.

## Owed by E, carried, NOT blocking — all on the same install

1. **The 24pt gap:** portrait AND landscape, with the collapsed bar alone and under a Confirm card.
2. **Reduce Motion ON, one pass covering three reduced sites.** Ask for it in one message together
   with the RM-off look (§7.3):
   - the capture fan: the cards must FADE, not cut;
   - the pencil disc appearing and leaving on a tab switch;
   - the re-tap.

## Carried, unchanged

- The colour-scheme arc stays **HELD** (E re-confirmed it this session: *"Colour arc stays on hold"*).
- `F-Search-3-Journal`: its objection is BACK. The band left of the disc is now the pencil's. Not
  to be started unasked.
- Frame 08's pushed-up disc observation; Phase D's dark schedule-summary dimness.

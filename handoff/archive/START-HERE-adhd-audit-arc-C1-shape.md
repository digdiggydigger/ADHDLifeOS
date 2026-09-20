# START HERE — build `F-C1-UndoCapsule`'s SHAPE ROUND, then `F-C2-DraftsToInbox`

*Written 2026-09-20 by the session that took `F-C1-UndoCapsule` to E's phone for the first time.
A disposable pointer: archive it when you write your successor. Its predecessor,
`archive/START-HERE-adhd-audit-arc-C2.md`, is spent.*

**E's standing instruction for these hand-offs:** *"You must ensure to maintain seamless continuity
in context and memory into the new session."* **Nothing below needs re-deciding. Every design
question is answered and E owes you nothing.**

## 0. Before anything else

1. **Branch first:** `git checkout main && git pull --ff-only && git checkout -b feature/adhd-c1-shape`.
2. **Read, in this order.**
   - `CLAUDE.md`: Architecture notes and §1–§7, especially §7.6 (`apple-design`).
   - `claudecode.md`: the TDD role.
   - **`TODO-CLAUDE-CODE.md`, the `### THE FINAL SHAPE — build exactly this` block** inside
     `F-C1-UndoCapsule` (~line 5571). **That is your spec. Read the whole "E's SHAPE ROUND" section
     around it**, because the part that will bite you is a decision E REVERSED mid-round.
   - `handoff/ADHD-AUDIT-BUILD-LOG.md`, session 2 — the thread and the six-step close-out you owe.
   - `handoff/OPEN-ITEMS-REGISTER.md`.
   - Memory: `adhd-audit-build-progress`, `adhd-ux-audit-arc`, `device-build-lag`.
3. **Evidence you must not re-derive:** `screenshots/undo-capsule-redesign/` — eight shapes on the
   real screen, light and dark, with measured card heights and a README that says what each one
   proves and which two measurements were WRONG before they were right.

## 1. THE ONE THING MOST LIKELY TO BE MIS-BUILT

**E's opening words were *"Bringing back a second line is smart"*. THE FINAL SHAPE HAS NO SECOND
LINE.** E overturned it by looking, after being shown that a second line costs 15pt on every task
title and does not buy back the 44pt the height round settled.

Build this and nothing else:

| | |
|---|---|
| card shape | **`Capsule(style: .continuous)`** — fully rounded, not a radius number |
| Undo chip | **gone** |
| `undoHorizontalPadding` | **deleted** — from the constant AND from `spacings` |
| subject | **`.lineLimit(1)`, unchanged.** The reclaimed 32pt widens the one line |
| `minHeight` | **44, unchanged** |

`strokeBorder` needs `InsettableShape`; `AnyShape` is NOT one. `Capsule` is — branch on the real
shape rather than erasing it.

## 2. Tests

Three to REVERSE and one to STRENGTHEN, all named with their reasons in the spec. The one that
matters most: `testTheUndoControlIsDrawnSmallerThanItsTapTargetAndTheTargetIsStillFortyFour`.
**With the chip gone nothing on screen shows the tap target any more**, so that assertion stops
being a double-check and becomes the only guard (`apple-design`'s one Medium finding on the round,
`buttons.md › Best practices`).

`testEveryCapsuleSpacingIsOnTheGrid` will FAIL rather than lapse if you zero the padding instead of
deleting it — 0 is not in {4, 8, 16, 24}, and widening that set would weaken a rule that protects
every other value.

## 3. Then `F-C2-DraftsToInbox`, unchanged

Its spec is untouched and its Step 0 is still answered. Read `F-C1`'s five departures above it —
two change what C2 must write (`RecentAction.undo` returns `Bool`; the capsule WRAPS the disc row's
leading band).

## 4. Four things this session learned the hard way

1. **E's phone is reachable WIRELESSLY and was never disconnected**, whatever an older opener said.
   `xcrun devicectl device info details --device 00008130-000268DE3C98001C` answering is the proof.
   Build → install → launch went clean in one pass with no cable. **Probe before asking E to plug in.**
2. **A combination has to be RENDERED, not reasoned about.** Two of E's three picks interacted:
   reclaiming the Undo padding widened the column, which stopped `.minimumScaleFactor(0.8)` shrinking
   the text, which made the card 59pt instead of the 53pt an earlier frame had measured. That is how
   a decision E made for a reason turned out not to serve the reason.
3. **Validate a measurement against a known value before believing it.** A sweep that returned five
   identical card heights looked like a design that had not changed; it was a tolerance bug — the
   white card differs from the page background by only 13. The method was only trustworthy once it
   read the shipped capsule as exactly 44.0pt.
4. **UI tests are skipped in the standard run.** `F-C1` shipped with `SignedInJourneyUITests` broken
   and every gate green. **Grep `ADHD LifeOSUITests` for any identifier or label you change and RUN
   what you touch.** This block changes no label, but C2 changes "Cancel" → "Close" on three
   composers, which is exactly the shape of change that broke it last time.

## 5. What is NOT owed

- **No RM-on device pass for the shape round** — geometry and fill only; `UndoCapsuleMotion` is
  untouched, and **F-C1's RM-on pass already PASSED on E's phone**.
- **No "Verified paths" line** — no `#available` site is touched.
- **No `firestore.rules` change.**
- **Do not fix contrast.** E's change IMPROVES the Undo label (3.38 → 3.93 light, 3.48 → 4.47 dark).
  It still falls short of 4.5:1 and that is the HELD colour arc's, recorded in the register.
- **Do not re-tune** the tab bar, `peekStep = 14`, `floatingPaddingHorizontal = 12`, the capture
  disc, the appearance override or the Confirm celebration's RM waiver.

## 6. What the block owes before it is done

Tests first; a red-check that MUTATES and counts the failures; SwiftLint, the full suite and the
build pasted verbatim; **re-render `screenshots/undo-capsule/`** at the new shape (its README
already carries one re-render note — this is the second, and the two landscape frames suffixed
`-PRE-HEIGHT-ROUND` are now two rounds stale); an `apple-design` review (§7.6). Then the **six-step
close-out in `handoff/ADHD-AUDIT-BUILD-LOG.md`, in full.**

## 7. The state you inherit

- **`main` @ PR #177's merge.** Suite **3,132 / 0**, SwiftLint **0 / 842**, build green. No Swift
  changed: the round's variant switch and render harness were REMOVED before merging and
  `UndoCapsule.swift` is byte-identical to its shipped state, so you start from the shipped capsule.
- **The simulator (iPhone 17 Pro, `9181EBF9-…`) was ERASED at close-out** after the render runs.
- **The Firebase emulator was left RUNNING** with the audit's imported state
  (`./scripts/emulators.sh --import scripts/audit/emulator-state` if it is down).
- **E's phone is on `main` @ `3f7932c`** — the 44pt capsule with the chip and radius 12. It will
  need reinstalling after this block to show E the new shape.
- **The profile expires 2026-09-24T19:49:37Z.** A build after that re-issues it; a build shortly
  before it ships a profile that dies that night.

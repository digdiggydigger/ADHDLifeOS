# START HERE — `F-C1-UndoCapsule` owes E ONE device look; then build `F-C2-DraftsToInbox`

*Written 2026-09-20 by the session that built E's shape round. A disposable pointer: archive it
when you write your successor. Its predecessor, `archive/START-HERE-adhd-audit-arc-C1-shape.md`,
is spent.*

**E's standing instruction for these hand-offs:** *"You must ensure to maintain seamless continuity
in context and memory into the new session."* **Every design question below is answered. The only
thing E owes you is a LOOK, and §0.1 says how to ask for it.**

## 0. Before anything else

1. **Branch first:** `git checkout main && git pull --ff-only && git checkout -b feature/adhd-c2-drafts`.
2. **Read, in this order.**
   - `CLAUDE.md`: Architecture notes and §1–§7, especially §7.6 (`apple-design`).
   - `claudecode.md`: the TDD role.
   - **`TODO-CLAUDE-CODE.md`, the `### FEATURE: F-C2-DraftsToInbox` block.** That is your spec.
     **Read `F-C1`'s departures notes immediately above it first** — two of them change what C2 must
     write (`RecentAction.undo` returns `Bool`; the capsule WRAPS the disc row's leading band), and
     the newest one records the radius cap.
   - `handoff/ADHD-AUDIT-BUILD-LOG.md`, **session 3** — the thread and the six-step close-out you owe.
   - `handoff/OPEN-ITEMS-REGISTER.md`, edition 71.
   - Memory: `adhd-audit-build-progress`, `adhd-ux-audit-arc`, `device-build-lag`.

### 0.1 THE ONE THING OWED TO E — do it FIRST, before starting C2

**E has seen the new capsule shape only as RENDERS. The RM-off device look has not happened.**

- **Probe before asking E for anything:**
  `xcrun devicectl device info details --device 00008130-000268DE3C98001C`. It answering at all is
  the proof the phone is reachable **wirelessly** — it was never disconnected, whatever an older
  opener said, and build → install → launch has gone clean in one pass with no cable twice now.
- **Install BEFORE asking for a verdict** (`ask-for-device-checks-on-a-build-e-has`): "owed a device
  check" is not the same as "it's on the phone", and asking first once cost E a wasted look.
  **Force-quit the app after the install before judging anything** (`relaunch-before-judging-device`).
- **Ask for RM-OFF only.** **No RM-on pass is owed** and asking for one wastes E's time: the round
  changed geometry and fill only, `UndoCapsuleMotion` is untouched, and F-C1's RM-on pass PASSED on
  2026-09-20.
- **THE BUILD IS ALREADY ON E'S PHONE.** The session that wrote this installed `main` @ `fea8c9e`
  (a Debug build) over the wireless tunnel. Confirm it is still there before rebuilding, and
  **force-quit the app before E judges anything**.
- **Ask for TWO looks in one message, both Reduce Motion OFF**, because they prove different things:
  1. **At E's usual text size** — the first time the shape round has been on hardware at all. Close
     a task on Tasks: fully rounded, no blue chip behind Undo, one line, and a task title that now
     reads much further before truncating.
  2. **With Settings → Accessibility → Display & Text Size → Larger Text turned up** — this is the
     only thing that can tell E anything new about the RADIUS CAP. At the default size the capped
     shape and a true capsule render byte-identically, so the cap is invisible there by design; the
     accessibility layout is the whole reason it exists, and E chose it from a render.
- **The profile expires 2026-09-24T19:49:37Z**; a build after that re-issues it.

## 1. What shipped in the shape round, so you do not re-litigate it

| | |
|---|---|
| card shape | `UndoCapsuleMetrics.cardShape` — an `InsettableShape` whose radius is `min(height, minHeight) / 2` |
| Undo chip | **gone** |
| `undoHorizontalPadding` | **deleted**, from the constant AND from `spacings` |
| subject | `.lineLimit(1)`, `minHeight` 44 — both unchanged |

**The radius cap is E's own call and must not be "corrected" to a bare `Capsule`.** Every frame of
the shape round was rendered at the DEFAULT text size; a capsule's radius is derived from its
height, so at Accessibility XL's 194.3pt card the caps reached 97.2pt and **6,329 pixels of the
completion glyph and 2,604 of the ↶ Undo control were drawn OUTSIDE the card**. E was shown both
shapes (`screenshots/undo-capsule/11-…`) and chose the cap. At the 44pt E approved the two shapes
render **byte-identical** (max channel delta 0), so the cap costs nothing E looked at.
`testTheContentsOwnCornerSitsOnTheCardAtEveryHeightTheLayoutCanTake` pins it as geometry.

## 2. `F-C2-DraftsToInbox`, unchanged

Its spec is untouched and its Step 0 is still answered. Three composers, one rule: text typed and
not sent goes to the Capture Inbox as a `.note`, the capsule says *"Kept in your inbox · Reopen"*,
and **Cancel becomes "Close"** on all three (`sheets.md`: Cancel means "without saving").

**The trap the spec names and the last session hit in a different form:** `TaskCreateView` is a real
`.sheet`, so swipe-down is live and undefended, and a `.sheet`'s swipe cannot distinguish "empty,
discard silently" from "typed, must file first" without `.onDisappear` or
`.interactiveDismissDisabled(true)` plus a custom close button.

**`JournalService.composerBody` must be CLEARED when filed**, or the text exists twice.

## 3. Five things this session learned the hard way

1. **When a shape's geometry is DERIVED from its content's size, the accessibility layout is a
   DIFFERENT SHAPE — render it before calling a shape round closed.** This was the third instance in
   one block of "a combination has to be rendered, not reasoned about".
2. **The AX3 render pass needs a FRESHLY ERASED simulator.** The harness signs out of any existing
   session first, and at accessibility text sizes the taller Settings rows put `signOutButton` past
   its 8 swipe attempts. It fails with *"Settings opened but presented no sign-out control"*, which
   reads like a bug in the thing you are photographing and is not one.
3. **Ask a frame the DIRECT question.** "Where does the fill begin on this row" gave a number that
   contradicted the unit test; *counting content pixels drawn outside the fill* answered cleanly
   (6,329 / 2,604 → 0 / 0) and was the claim that actually mattered.
4. **Never pipe `xcodebuild` through `| head -N`.** `head` closes the pipe and the run's own
   `** TEST FAILED **` is never reached, so you cannot see the result. Redirect to a file, grep the
   file.
5. **UI tests are skipped in the standard run.** C2 changes "Cancel" → "Close" on three composers —
   **grep `ADHD LifeOSUITests` for every label you change and RUN what you touch.** That exact shape
   of change broke `SignedInJourneyUITests` once already with every gate green.

## 4. What is NOT owed

- **No RM-on device pass** for C2 unless it adds or changes a REDUCED site — say why none was owed.
- **Do not fix contrast.** The Undo label is 3.93:1 light / 4.47:1 dark, short of 4.5:1, and that is
  the HELD colour arc's (register §D).
- **Do not re-tune** the tab bar, `peekStep = 14`, `floatingPaddingHorizontal = 12`, the capture
  disc, the appearance override or the Confirm celebration's RM waiver.
- **Do not "correct" the capsule's radius cap** (§1).

## 5. What the block owes before it is done

Tests first; a red-check that MUTATES and counts the failures; SwiftLint, the full suite and the
build pasted verbatim; an `apple-design` review (§7.6); evidence in `screenshots/` with a README if
anything was settled by looking. Then the **six-step close-out in
`handoff/ADHD-AUDIT-BUILD-LOG.md`, in full.**

## 6. The state you inherit

- **`main` @ PR #178's merge.** Suite **3,137 / 0**, SwiftLint **0 / 843**, build green,
  app-target coverage **29.83% (14,612/48,985)**. **That coverage numerator is FLAGGED, not
  claimed** — it moved +387 against edition 68's figure on a denominator that barely moved, which
  four assertion-only tests cannot account for, and the cause was not established. Do not cite the
  delta as anyone's work.
- **The simulator (iPhone 17 Pro, `9181EBF9-…`) was ERASED at close-out** after the render runs.
- **The Firebase emulator was RESTARTED this session** (it had been up ~7 hours) and left running
  with the audit's imported state — `./scripts/emulators.sh --import scripts/audit/emulator-state`
  if it is down.
- **E's phone is on `main` @ `3f7932c`** — the OLD capsule, with the chip and radius 12. §0.1.
- **The profile expires 2026-09-24T19:49:37Z.**

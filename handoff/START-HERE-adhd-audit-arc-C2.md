# START HERE — build `F-C2-DraftsToInbox`, arc C's second block

*Written 2026-09-20 by the session that built `F-C1-UndoCapsule`, arc C's first block and the first
app Swift the ADHD audit has produced. A disposable pointer: archive it when you write your
successor. Its predecessor, `archive/START-HERE-adhd-audit-arc-C.md`, is spent.*

**E's standing instruction for these hand-offs:** *"You must ensure to maintain seamless continuity
in context and memory into the new session."* Nothing below needs re-deciding.

## 0. Before anything else

1. **Branch first, never work on `main`:**
   `git checkout main && git pull --ff-only && git checkout -b feature/adhd-arc-C2-drafts`.
2. **Read, in this order.**
   - `CLAUDE.md`: Architecture notes and §1–§7, especially §7.1–7.3 and §7.6 (`apple-design`).
   - `claudecode.md`: the TDD role.
   - **`TODO-CLAUDE-CODE.md`, `F-C2-DraftsToInbox`** (~line 5570). **Read `F-C1-UndoCapsule` just
     above it too** — its "Built 2026-09-20, and where it departs from the spec" note is the
     contract C2 builds on, and two of its five departures change what C2 must write.
   - **`handoff/ADHD-AUDIT-BUILD-LOG.md`** — the thread, and the six-step close-out you owe.
   - `handoff/SESSION-OPENER-adhd-ux-audit-design.md`, round 2, for E's words.
   - `handoff/OPEN-ITEMS-REGISTER.md`.
   - Memory: `adhd-audit-build-progress`, `adhd-ux-audit-arc`, `audit-sim-drive-lessons`.
3. **Evidence you must not re-derive:** `screenshots/undo-capsule/` — 26 frames of the capsule on
   every surface, light/dark/AX3 plus compact-height landscape, with a README saying what each one
   proves. **The draft bar reuses this design** (round 2b: *"The draft bar ('Kept in your inbox ·
   Reopen') uses the same design"*), so it is a `RecentActionKind` case, not a new component.

## 1. THE FIRST THING TO DO, before writing any code

**E's phone is DISCONNECTED and must be reconnected — say so in your first message.** It was
unplugged during the height round below, and nothing has been on it.

**E has not seen `F-C1-UndoCapsule` on the phone.** It is merged and green but nothing has been on
a device. Two passes are owed and they must be asked for **in one message** so E flips the setting
only once (§7.3):

> Reduce Motion **OFF**: close a task from Tasks, from Today's hero, from a life area and from task
> detail; dismiss a nudge; triage a capture. Is the 44pt capsule the right height on the real
> screen, and does Undo take it back? Then Reduce Motion **ON** (Settings → Accessibility →
> Motion): the capsule should **fade** in and out, never cut. The inbox's old bar used to slide up
> from the bottom; that slide is gone.

**The capsule was RESIZED after the block landed** (E's height round, 2026-09-20): 74pt → **44pt**,
two lines a size smaller, and the Undo pill drawn at 32 with its tap target held at 44. E chose
both by looking at renders, not on the device — so the device look is the first real test of the
new size. If it sends the shape back, that is a fresh session's job, not this one's (memory:
`build-in-a-fresh-session`).

**Install the build BEFORE asking** (memory: `ask-for-device-checks-on-a-build-e-has` — "owed a
device check" ≠ "it's on the phone"; asking without installing cost E a wasted look once already).

## 2. What this session builds

**`F-C2-DraftsToInbox` — one block, then stop for E's review.** Unsent composer text files into the
Capture Inbox as a note; Cancel becomes Close; task detail autosaves and swipe-back is restored.

## 3. What `F-C1` established that C2 must honour

Three, and the first two will bite:

1. **`RecentAction.undo` returns `Bool`, and `false` puts the offer BACK.** The draft bar's
   "Reopen" must return it too — a reopen that could not land has to leave its offer standing, the
   same promise the Capture Inbox has always made. `RecentActionCenter.undo()` clears the slot
   before awaiting and restores on `false`, but only into a slot nothing else has claimed.
2. **The capsule WRAPS the disc row's leading band** — `UndoCapsuleSlot { leadingBand }` in
   `RootBottomOverlay` — rather than sitting beside it. That is what makes it stand IN FOR the
   search row and the Journal pencil while the + disc never moves. Do not add a second occupant.
3. **The capsule is 44pt and every number in it is E-approved** — `minHeight` 44,
   `verticalPadding` 4, `undoDrawnHeight` 32 with `undoHitOverflow` 6 holding §3's target. **Do not
   re-tune any of them**, and note that this one control overrides round 7's 48pt rule by E's
   explicit choice. C2's draft bar is a `RecentActionKind` case in the same capsule, so it inherits
   all of it.
4. **A visible change here can break a UI JOURNEY that the standard suite never runs.** `F-C1`
   shipped with `SignedInJourneyUITests` broken and every gate green: the capsule NAMES what it
   would take back, so a sorted capture's own words are on screen immediately, and that journey
   waited app-wide for exactly those words to go. **Before you finish: `grep -rn "<any identifier
   or label you changed>" "ADHD LifeOSUITests"`, and RUN any journey you touched**
   (`-only-testing:"ADHD LifeOSUITests/<Suite>/<test>"`, emulator up, then `simctl erase`).
   The same episode also cost a `accessibilityLabel`: keep the Undo control's label the plain word
   "Undo", because that journey addresses it by label.
5. **It is drawn in a tight `HStack`, so new content steals the control's width.** The first render
   showed the Undo button as "Un…". If C2's bar needs a second control ("Reopen" beside a dismiss,
   say), give it the same `.layoutPriority(1)` + `.fixedSize` treatment and **render it before
   believing it** — no unit test can see truncation.

**Where the pieces live:** `ADHD LifeOS/Undo/` (`RecentAction`, `RecentActionCenter`,
`RecentActionRecording`, `UndoCapsule`, `UndoCapsuleMetrics`). A new kind is a case on
`RecentActionKind` plus its verb, glyph and tint — `UndoCapsulePresentationTests` will make you say
what all three are.

**And one more trap that cost two render rounds:** a switch the app never receives. A launch
argument beginning with `-` is parsed as a UserDefaults key expecting a value, and `xcodebuild`'s
own environment does not reach the TEST RUNNER. Both failures look identical — every variant
renders the default. **One test method per variant** is the fix; a method name cannot be swallowed.

## 4. What this session must NOT do

- **Do not start C3, C4 or arcs D–G.**
- **Do not fix contrast.** Round 9: *"Leave it to the colour arc"*, which is HELD. The Undo label's
  3.38:1 / 3.48:1 is already in the register as a colour-arc input; leave it there.
- **Do not re-tune** the tab bar, the appearance override, the Confirm celebration's RM waiver,
  `peekStep = 14`, `floatingPaddingHorizontal = 12`, or the capture disc.
- **Do not build a second undo mechanism.** One slot, one occupant — it is the whole point of C1.

## 5. What the block owes before it is done

Per `CLAUDE.md`: tests first; a red-check that MUTATES and counts the failures (C1 ran six, one per
guard, and all six bit — that shape is worth copying); SwiftLint, the full suite and the build
pasted verbatim; `screenshots/` + README where the result is settled by looking; an `apple-design`
review (§7.6); and the RM-on device pass if a reduced site is added or changed.

Then **the six-step close-out in `handoff/ADHD-AUDIT-BUILD-LOG.md`, in full.**

## 6. The state you inherit

- **`main` @ the merge of `F-C1-UndoCapsule`.** Suite **3,130 / 0**, SwiftLint **0 / 842**, build
  green. App-target coverage **29.07% (14,225/48,930)**; all four non-view files in `Undo/` at 100%.
- **The simulator (iPhone 17 Pro, `9181EBF9-…`) was ERASED at close-out** after the UI render runs,
  which is mandatory — a signed-in simulator drags the next unit suite to 60–80s per test.
- **The Firebase emulator was left RUNNING** with the audit's imported state. Restart it with
  `./scripts/emulators.sh --import scripts/audit/emulator-state` if it is down; the render harness
  and the four emulator-backed suites skip without it.
- **`ADHD LifeOSUITests/UndoCapsuleRenderUITests.swift` is committed deliberately**, not left
  behind. It drives the real app to every capsule surface and it is the fastest way to re-render
  after a change. Four traps are documented in it and all four cost a run: Today's hero is found by
  LABEL (a `CelebrationPopSource` container owns the identifier), it needs the retrying tap, AX3
  comes from `xcrun simctl ui <udid> content_size accessibility-extra-large` and not from a launch
  argument, and `app.screenshot()` lies in landscape.
- **`firestore.rules` needs no change for C2** — drafts are ordinary captures, and the rules have
  no field-level validation.

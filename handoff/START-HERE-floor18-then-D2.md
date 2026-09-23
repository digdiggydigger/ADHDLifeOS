# START HERE — `F-Floor18` (iOS 16 → 18), THEN `F-D2-ComposerKeyboardLayout`.

*Written 2026-09-23 by the session that built `F-D1-ComposerBothDoors`, and re-pointed the same day
when E decided the floor. A disposable pointer: archive it when you write your successor. Its
predecessor, `archive/START-HERE-adhd-audit-arc-D1-composer.md`, is spent.*

**E's standing instruction:** *"You must ensure to maintain seamless continuity in context and
memory into the new session."*

## THE ORDER CHANGED — E, 2026-09-23: *"iOS 18, before F-D2"*

**Build `F-Floor18` FIRST** (`TODO-CLAUDE-CODE.md`, the block directly above `F-D2`). It is a global
sweep: the deployment target goes 16.0/16.1 → **18.0** on all six build settings, every
availability gate below 18 goes (~95 in 43 files), Places and routines stop being optional, the 35
deprecated `onChange` spellings are fixed, and the GOVERNING docs (CLAUDE.md §7 above all) are
rewritten while the RECORDS are left untouched. Its spec holds the measured inventory, the compiler's
evidence, the tests to reverse and a new tree-walking guard — read it whole.

**Then `F-D2`** — from §0.1 below, with ONE Step 0 question, not two: question 2 (the 16.0–16.3
popover) is void at an 18 floor, and a banner on the D2 spec says so.

## 0. Before anything else

1. **CHECK THE REGISTER AGAINST WHAT YOU WERE HANDED.** Two sessions running have been handed a
   brief with stale lines in it. `git log --oneline -8` and `OPEN-ITEMS-REGISTER.md`'s header take
   ten seconds, and they are the only defence.
2. **Branch:** `git checkout main && git pull --ff-only && git checkout -b chore/floor-ios18` for the
   floor; `feature/adhd-d2-keyboard` for D2 once the floor has merged.
3. **Read:** `CLAUDE.md` (§1–§7, especially §7.1–§7.3 because this block adds an `#available` site,
   and §7.6), `claudecode.md`, the `### FEATURE: F-D2-ComposerKeyboardLayout` block in
   `TODO-CLAUDE-CODE.md`, register edition 78, and `handoff/ADHD-AUDIT-BUILD-LOG.md` session 8.
   Memory: `adhd-audit-build-progress`, `adhd-ux-audit-arc`.
4. **Start the emulator** with `./scripts/emulators.sh --import scripts/audit/emulator-state`, and
   restart it if it has been up for hours.
5. **ERASE the simulator before the first unit run** if a UI run came before it:
   `xcrun simctl erase 9181EBF9-0F54-4A4D-A19C-19945D1BF155`.

### 0.1 D2's ONE Step 0 question is E's, and it comes BEFORE any D2 code

Written out in full in the spec, with options and a recommendation. Put it to E with
`AskUserQuestion` (memory: `ask-questions-directly`):
1. **Does the Date popover offer a time, or only a day?** Recommended: date only.

~~2. The 16.0–16.3 popover~~ — **void**: `F-Floor18` makes 16.4's `presentationCompactAdaptation`
always available. Do not ask it.

## 1. What `F-D1` leaves behind that D2 builds on

- **`TaskCreateView` is the ONE composer.** Three doors open it: the Tasks "+" and "Add to
  <area>" as a `.sheet`, and the capture disc's Task tile (and the widget door) as a
  `.fullScreenCover`. The last two go through `RootView+Doors.swift › composer(for:)`. D2 changes
  its LAYOUT and nothing about its doors.
- **Area and Time are pop-up `Menu`s in 48pt carded rows.** Area is the shared `LifeAreaPicker`
  with `popUpRowHeight: 48`; Time is `timeMenu` over `TaskEffortChoice` (15 min, the default,
  always written / 30 min / 1 hr). **The row is sized INSIDE each Menu's label**, because a
  `Menu`'s hit area is its label. The first `F-D1` build padded from outside and measured
  **338 × 20.3pt** inside a 48pt card. L3's bar must keep the same rule.
- **The Time write is a follow-up `updateTask` in `TaskCreateService.createTask()`**, after the
  create is committed; a failure WARNS and still returns `true`. Do not move it into the create's
  `do`; `testCreateTask_focusDurationUpdateFailure_…` exists to stop exactly that.
- **`ComposerBothDoorsCallSiteTests`** reads the source for the doors, the menus and the prune. D2
  will move things; update its string anchors DELIBERATELY (`private var timeMenu`,
  `taskCreateTimeMenu`, `LifeAreaPicker(`, `noSelectionLabel: "None"`).
- **The render harness `ComposerBothDoorsRenderUITests`** asserts both menus are ≥ 48pt tall and
  photographs both doors. Re-run it for D2's frames rather than building a new drive. It labels
  `before-`/`after-` from the hierarchy (via `taskCreateNotesField`), so after D1 every frame
  reads `after-`, which is correct.

## 2. Traps this session paid for

1. **A frame was the only gate that saw the 20pt hit target.** The picture looked right, and
   suite, lint and build were green. For any control D2 moves into the keyboard bar, ASSERT its
   frame.
2. **`XCTAssertGreaterThanOrEqual(height, 48)` fails at 47.99999999999994.** Allow half a point.
3. **The spec's red-check ("restore the three files from the pre-block commit") is a COMPILE
   failure** once a seam has been pruned. Report it as such, then red-check with compiling
   mutations and count those.
4. **`RootView.swift` is at 391 of 400 lines.** Anything more goes in an extension file.

## 3. What must NOT be re-tuned or re-litigated

- Everything `F-D1`'s opener listed: the capsule's radius cap, `peekStep = 14`,
  `floatingPaddingHorizontal = 12`, the tab bar, the capture disc, the appearance override, the
  Confirm celebration's RM waiver, no confirm on a soft delete, E's tag decisions.
- **Time defaults to 15 min and is always written** (every board E approved). The named cost is in
  the D1 report.
- **Contrast stays with the colour arc** (R9). The menu card's value text is 3.22:1 in light, and
  it is recorded in the register, not fixed.

## 4. The state you inherit — VERIFIED, not assumed

- **`main` @ the merge of `F-D1`**, `git status` clean.
- Suite, lint, build and coverage are in register edition 78.
- **E's phone carries `F-C3` + `F-C4`, not `F-D1`.** D2 owes a device check (keyboard stays up
  through the menus). Install the D2 build BEFORE asking for it (memory:
  `ask-for-device-checks-on-a-build-e-has`). **The provisioning profile expired 2026-09-24**
  (edition 77), so that install will likely need it re-issued first — E's job in Xcode
  Settings (memory: `app-group-provisioning-blocker`).

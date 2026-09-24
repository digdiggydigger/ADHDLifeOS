# START HERE — WIP: arc D, block 3 `F-D3-TasksAnytimeRow`, then the ARC-D CLOSE.

*Written 2026-09-24 by the session that built `F-D2-ComposerKeyboardLayout`. A disposable `WIP:`
pointer (CLAUDE.md › Per-arc bypass: "mid-arc, a session that must stop writes a `WIP:` opener for
the next block of the same arc"). It stopped at 65% context, on E's warning, with D2 LANDED. Archive
this file when you write the arc's successor. Its predecessor,
`archive/START-HERE-adhd-audit-arc-D2-keyboard.md`, is spent.*

**E's standing instruction:** *"You must ensure to maintain seamless continuity in context and
memory into the new session."*

## 0. Before anything else

1. **Check the register against this brief:** `git log --oneline -8` and
   `handoff/OPEN-ITEMS-REGISTER.md`'s header (edition 81). Three sessions running were handed stale
   lines.
2. **Branch:** `git checkout main && git pull --ff-only && git checkout -b feature/adhd-d3-anytime`.
3. **Read:** CLAUDE.md (Per-arc bypass, the build-loop economies, §7), `claudecode.md`, the
   **`### FEATURE: F-D3-TasksAnytimeRow`** block in `TODO-CLAUDE-CODE.md` (directly below the
   completed `F-D2`), build-log session 10, register edition 81. Memory: `per-arc-bypass`,
   `menus-dismiss-the-keyboard` (the harness traps apply to any UI render here),
   `adhd-audit-build-progress`, `test-vacuity-mutation-check`.
4. **Emulator:** `./scripts/emulators.sh --import scripts/audit/emulator-state`. **Erase** the unit
   simulator (`9181EBF9…`) before the first unit run.

## 1. D3 — straight to code (no Step 0; the spec is fully specified)

- One guard in `MomentumTaskBuckets.bucket(for:)` (`guard let due = task.dueDate else { return nil }`)
  becomes `.anytime`; `case anytime` goes LAST in `Bucket` so it renders at the bottom; the
  beyond-tomorrow branch stays `nil` (round 8b: "future-dated tasks are untouched").
- `TaskListView.taskList(groups:)` special-cases `customId == "momentum-anytime"` with the shared
  `CollapsibleSectionHeader`, `@AppStorage("tasks.anytimeCollapsed") = true` (collapsed by default —
  round 6: "the tail stays folded"). No ▶ sprint launcher on Anytime rows (already keyed off
  `momentum-dueToday` — pin it).
- Reverse `testGroup_excludesLaterAndUndatedTasks` in place; annotate both file headers.

## 2. Then the ARC-D CLOSE (both blocks)

1. **Coverage, once for the arc** (economy 1), with the documented command — `-enableCodeCoverage YES`.
2. **Install on E's phone FIRST** (memory `ask-for-device-checks-on-a-build-e-has`, `device-build-lag`;
   wireless, probe `devicectl device info details`; `-allowProvisioningUpdates`).
3. **Write `handoff/ARC-REVIEW-D.md`:** one numbered checklist, a verdict line per block:
   - **D2:** the composer from the Tasks "+" AND the capture disc's Task tile. Type a title → the bar
     rides the keyboard. Tap Area → the keyboard goes down and the bar settles at the bottom (E's
     "Let it settle"). Choose; tap Time and Date → the bar stays put. Tap the title → it rides again.
     Date → a whole calendar; pick → the segment reads the day. The Liquid Glass panel (E: "Keep the
     panel"). Settings › Accessibility › Larger Text at AX3 → the stacked form. **No RM-on pass is
     owed** for D2 (no reduced site).
   - **D3:** per its spec (the Anytime row collapsed, expanded, a new undated task landing in it).
4. Ask E for the one pass in one message; record verdicts per block in the register and build log.
5. Write the arc's successor opener (arc E, `F-E1`) and archive this one.

## 3. What D2 left that D3 or the close must NOT undo

- **E, 2026-09-24: "Let it settle"** — never re-focus the composer's title programmatically
  (`testAChoiceLetsTheBarSettleRatherThanBouncingBack` bans `@FocusState` there). **"Keep the panel."**
- Close stays the system bar item (72 × 36 on 27.0, 56 × 56 on 18.0) — `F-B1` owns 48 × 48.
- Everything the earlier openers froze: `peekStep = 14`, `floatingPaddingHorizontal = 12`, the tab
  bar, the capture disc, the appearance override, the Confirm RM waiver, no soft-delete confirms,
  E's tag decisions, Time defaults to 15 min, contrast held for the colour arc.

## 4. State you inherit — verify, don't assume

- `main` @ the merge of `F-D2`'s PR. Suite **3,337 / 0**, SwiftLint **0 / 892**, build green.
- **E's phone still carries `F-Floor18` (`442db4e`)** — NOT D2. The install is part of the close.
- UI-harness facts (memory `menus-dismiss-the-keyboard`): erase + boot + launch Settings + 30s
  before a UI run, or the runner dies "waiting for AX loaded"; erase before each run (a restored
  session breaks the sign-out at AX3); the iOS 18.0 sim's first boot shows no software keyboard.

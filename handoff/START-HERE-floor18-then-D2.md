# START HERE — `F-Floor18` (iOS 16 → 18), THEN `F-D2-ComposerKeyboardLayout`.

*Written 2026-09-23 by the session that built `F-D1-ComposerBothDoors`, and re-pointed the same day
when E decided the floor. A disposable pointer: archive it when you write your successor. Its
predecessor, `archive/START-HERE-adhd-audit-arc-D1-composer.md`, is spent.*

**E's standing instruction:** *"You must ensure to maintain seamless continuity in context and
memory into the new session."*

## THE ORDER CHANGED — E, 2026-09-23, twice over

*"iOS 18, before F-D2"*, and then: **"do it in the fresh session BEFORE anything else in the
Redesign Audit is handled."** So `F-Floor18` is the FIRST thing this session builds — before `F-D2`,
before any other audit block, before any look or question about the audit. Nothing else starts
until it has merged.

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
3. **Read, for the floor:** `CLAUDE.md` (§7 IN FULL — it is the section this block rewrites — and
   the Architecture notes' first bullet), `claudecode.md`, the **`### FEATURE: F-Floor18`** block in
   `TODO-CLAUDE-CODE.md` in full, register edition 79. Memory: **`ios-18-floor`**,
   `modern-ios-pilot`, `adhd-audit-build-progress`. **Only once the floor has merged**, read the
   `F-D2` block, build-log session 8 and `adhd-ux-audit-arc` for D2.
4. **Start the emulator** with `./scripts/emulators.sh --import scripts/audit/emulator-state`, and
   restart it if it has been up for hours.
5. **ERASE the simulator before the first unit run** if a UI run came before it:
   `xcrun simctl erase 9181EBF9-0F54-4A4D-A19C-19945D1BF155`.

### 0.1 `F-Floor18` — how to run it (the spec has the full inventory)

- **Re-run the spec's greps FIRST and reconcile against its numbers** (6 build settings, ~95
  annotations in 43 files, 35 `onChange` deprecations). The spec was measured at `d85b18a`.
- **RED first:** write `DeploymentFloorTests` (all six targets at 18.0; no availability check
  below iOS 18 anywhere in `ADHD LifeOS/` or `FocusTimerWidget/`) and count its failures on the
  untouched tree.
- **Suggested commit order**, each RED→GREEN→commit+push: (1) the build settings + the floor tests;
  (2) the ActivityKit/App Intents/trivial gates; (3) the iOS 17 "degraded" sites incl. `.haptic`;
  (4) Places + routines made universal, the three flags deleted, their tests reversed; (5) the 35
  `onChange` spellings + the six tests that pin them; (6) the governing docs. Commit BEFORE every
  red-check (memory: `never-destroy-uncommitted-work`).
- **No Step 0 question is owed to E** — the decision is made. The one thing to ASK is optional:
  whether E will install the iOS 18 simulator runtime (Xcode → Settings → Components) so the floor
  path can RUN rather than only compile. Don't block on it.
- **It closes like any block:** suite + lint + build pasted, widget and UI-test targets built,
  `plutil -p` of the built app's AND widget's `MinimumOSVersion` pasted, the device smoke launch
  (install FIRST), register edition, build-log entry, memory, then rewrite THIS opener for `F-D2`
  (drop §0.1 and this paragraph, keep the rest) — exactly one live opener.

### 0.2 D2's ONE Step 0 question is E's, and it comes BEFORE any D2 code

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

## 2. Traps — the floor's first, then D1's

**For `F-Floor18`:**
1. **The compiler will NOT find a missed gate.** Swift never warns that a `#available` is redundant
   against the deployment target. The grep and `DeploymentFloorTests` are the whole guard.
2. **`onChange(of:) { foo($0) }` passes the NEW value.** Its two-parameter form is
   `{ _, new in foo(new) }` — never `{ old, _ in … }`, which compiles and silently inverts it.
3. **Six call-site tests pin the old one-parameter spelling** (`AppSearchCallSiteTests:79`,
   `CelebrationCaptureFanCallSiteTests:20`, `ConfirmCelebrationCallSiteTests:64`,
   `CelebrationMilestoneCallSiteTests:125,129`, `JournalHeaderControlsTests:99`). Change them in the
   SAME commit as the code, deliberately.
4. **Every "16" in CLAUDE.md that is not the floor is a SPACING token (16pt).** Do not touch those.
5. **Records are never edited:** `TODO-ARCHIVE.md`, `handoff/archive/`, `SESSION-OPENER-*`, every
   `screenshots/*/README.md`, completed TODO blocks. The acceptance criteria want an EMPTY
   `git diff --stat` over them, pasted.
6. **Keep `.haptic(_:trigger:)`** as the house API (§3 prescribes it); only its UIKit floor branch goes.
7. **The iOS 26 gates STAY**, with their `else` branches — those now mean iOS 18–25.
8. **The ~1,790 concurrency warnings are NOT this block's** — measured identical at 16 and 18.

**From `F-D1`, for D2:**

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

- **`main` @ the merge of this opener's PR** (after `51f01cf`, the floor spec), `git status` clean.
- Suite **3,317 / 0**, SwiftLint **0 / 885**, build SUCCEEDED, coverage **30.11% (15,081/50,094)** —
  register edition 78; nothing in Swift has changed since.
- **E's phone carries `F-D1`** (`main @ d85b18a`, installed and launched 2026-09-23). The floor
  block owes a device SMOKE launch (widget, Live Activity, App Intents all change targets); D2 owes
  a device check (the keyboard stays up through the menus). Install BEFORE asking (memory:
  `ask-for-device-checks-on-a-build-e-has`). **The provisioning profile EXPIRES
  2026-09-24T19:49:37Z** — an install after that needs it re-issued; `-allowProvisioningUpdates`
  usually does it, and E's Xcode sign-in is the fallback (memory: `device-build-lag`).

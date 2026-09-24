# START HERE — `F-D2-ComposerKeyboardLayout`, at the iOS 18 floor.

*Written 2026-09-24 by the session that built `F-Floor18` (iOS 16 → 18). A disposable pointer:
archive it when you write your successor. Its predecessor,
`archive/START-HERE-floor18-then-D2.md`, is spent — the floor has MERGED.*

**E's standing instruction:** *"You must ensure to maintain seamless continuity in context and
memory into the new session."*

## THE FLOOR IS 18. Nothing below 26 is gated any more.

`F-Floor18` landed on 2026-09-24: every target is `IPHONEOS_DEPLOYMENT_TARGET = 18.0`, the tree
carries **zero** availability checks below iOS 18, and `DeploymentFloorTests` fails the suite if
one comes back (the compiler never will — it does not flag a `#available` made redundant by the
deployment target). Places and the routine screen are universal; `placesSupported`,
`available(placesSupported:)` (now `ToolsCatalog.entries`) and `routineScreenAvailable` are gone.
The only `#available` sites left are iOS 26, and their `else` means 18–25. `CLAUDE.md` §7 was
rewritten for this; read it as it now stands, not as the design records quote it.

**Build `F-D2-ComposerKeyboardLayout`** (`TODO-CLAUDE-CODE.md`, directly below the completed
`F-Floor18` block). Its spec was rewritten in place by the floor block: **Step 0 is ONE question**,
and its one `#available` site is the iOS 26 Liquid Glass container.

## 0. Before anything else

1. **CHECK THE REGISTER AGAINST WHAT YOU WERE HANDED.** Three sessions running have been handed a
   brief with stale lines in it. `git log --oneline -8` and `OPEN-ITEMS-REGISTER.md`'s header
   (edition 80) take ten seconds, and they are the only defence.
2. **Branch:** `git checkout main && git pull --ff-only && git checkout -b feature/adhd-d2-keyboard`.
3. **Read:** `CLAUDE.md` (§7 in full — it changed — and the Architecture notes' first bullet),
   `claudecode.md`, the **`### FEATURE: F-D2-ComposerKeyboardLayout`** block in
   `TODO-CLAUDE-CODE.md` in full, register edition 80, build-log sessions 8 and 9. Memory:
   `ios-18-floor`, `adhd-audit-build-progress`, `adhd-ux-audit-arc`, `menu-hit-area-is-its-label`,
   `ask-questions-directly`.
4. **Start the emulator** with `./scripts/emulators.sh --import scripts/audit/emulator-state`, and
   restart it if it has been up for hours.
5. **ERASE the simulator before the first unit run** if a UI run came before it:
   `xcrun simctl erase 9181EBF9-0F54-4A4D-A19C-19945D1BF155`.

### 0.1 D2's ONE Step 0 question — **ANSWERED by E, 2026-09-24: date only**

**E answered every open Step 0 question in the audit on 2026-09-24** (*"Take all the recommendations as
written"*); each block carries an **"E DECIDED 2026-09-24"** banner. Do not re-ask any of them. For D2
that means: build `displayedComponents: [.date]` and go straight to the code.

Written out in full in the spec, with options and a recommendation. Put it to E with
`AskUserQuestion` (memory: `ask-questions-directly`):
1. **Does the Date popover offer a time, or only a day?** Recommended: date only.

The former question 2 (a popover floor path for iOS 16.0–16.3) was VOIDED by `F-Floor18` and is
gone from the spec. Do not ask it, and do not build a floor path for the popover.

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

**From `F-Floor18`:**
1. **A new `#available` below 26 fails `DeploymentFloorTests`**, and it should: there is no OS
   below 18 to gate for. If a skill or a spec line says "gate this on 17", it is stale — the API
   is free.
2. **`onChange` is the two-parameter form everywhere now** (`{ _, new in … }`), or zero-parameter
   where the value is unused. The one-parameter `perform:` form is deprecated and the build is at
   **0** such warnings; do not add one back.
3. **The iOS 18.0 runtime IS installed** ("iPhone 16 Pro (iOS 18 floor)", destination
   `platform=iOS Simulator,name=iPhone 16 Pro (iOS 18 floor),OS=18.0`). So D2's "Verified paths"
   line for the Liquid Glass gate reads: `26 path: run on sim 27.0 + E's phone. 18–25 path: run on
   sim 18.0 (the floor); 19–25 never run.` — and it may say that only if you actually ran the
   floor branch there (CLAUDE.md §7.3). Never write "works on iOS 18" as a blanket claim.
4. **Records still say 16.** `handoff/SESSION-OPENER-adhd-ux-audit-design.md` and the working
   findings talk about a "16 floor path" for the composer bar and the popover. They are records
   of what was true on 2026-09-19 and are not edited; the SPEC is what you build from.

**From `F-D1`:**
1. **A frame was the only gate that saw the 20pt hit target.** The picture looked right, and
   suite, lint and build were green. For any control D2 moves into the keyboard bar, ASSERT its
   frame.
2. **`XCTAssertGreaterThanOrEqual(height, 48)` fails at 47.99999999999994.** Allow half a point.
3. **The spec's red-check ("restore the three files from the pre-block commit") is a COMPILE
   failure** once a seam has been pruned. Report it as such, then red-check with compiling
   mutations and count those.
4. **`RootView.swift` is at ~392 of 400 lines.** Anything more goes in an extension file.

## 3. What must NOT be re-tuned or re-litigated

- Everything `F-D1`'s opener listed: the capsule's radius cap, `peekStep = 14`,
  `floatingPaddingHorizontal = 12`, the tab bar, the capture disc, the appearance override, the
  Confirm celebration's RM waiver, no confirm on a soft delete, E's tag decisions.
- **The floor is 18 (E, 2026-09-23).** Not 17, not 16, and the records that argue for 16 are
  history.
- **Time defaults to 15 min and is always written** (every board E approved). The named cost is in
  the D1 report.
- **Contrast stays with the colour arc** (R9). The menu card's value text is 3.22:1 in light, and
  it is recorded in the register, not fixed.

## 4. The state you inherit — VERIFIED, not assumed

- **`main` @ the merge of this opener's PR** (after `442db4e`, the floor's last code commit),
  `git status` clean.
- Suite, SwiftLint, build and coverage: **register edition 80** has the figures measured at the
  floor's close-out; nothing in Swift changes between that run and this opener.
- **E's phone carries `F-Floor18`** (`442db4e`, installed wirelessly and launched 2026-09-24,
  `MinimumOSVersion 18.0`). E's walk-through PASSED the same day (*"Passes — all three checks work as
  before"*), so nothing from the floor is owed on the phone. The phone pairs WIRELESSLY (`available (paired)` in `devicectl list devices`);
  probe with `devicectl device info details` before asking E for a cable (memory:
  `device-build-lag`). The free-account profile expires weekly; `-allowProvisioningUpdates`
  usually re-issues it, E's Xcode sign-in is the fallback.
- **D2 owes a device check** (the keyboard stays up through the Area, Time and Date menus). Install
  BEFORE asking (memory: `ask-for-device-checks-on-a-build-e-has`).

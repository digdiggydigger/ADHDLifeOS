# Start here — F-FocusCard-4, the celebration

*Paste into a fresh Claude Code terminal. Written 2026-09-11 at the close of the session that
answered the light-mode peek and shipped `F-FocusCard-3-Peek` (PR #56 → `298fb17`), then landed
this close-out.*

**This is the ONE live opener.** If you find a second `START-HERE-*` in `handoff/`, one of them is
a trap. Archive this file into `handoff/archive/` in the same move that writes your successor, at
the END of your session, never at the start. Its predecessor (same name, written 2026-09-09) is
already in `handoff/archive/` — read it only for history.

---

## Where things stand

**Block 3 is CLOSED, peek included.** E ran three of their four device checks on 2026-09-11 and
reported nothing wrong; the four device shots in `screenshots/focus-card-stack/` (`10-`–`13-`) are
E's own, and they are the first real three-layer stack anyone has seen.

**`main` @ this close-out; the last CODE change is `298fb17`. No branch in flight**, and `main` is
the ONLY branch on GitHub. Verified: **suite 2,638 / 0** (emulator up, 0 `127.0.0.1:9099` hits,
0 skipped), **lint 0 / 734**, sim + device builds `** BUILD SUCCEEDED **`, **app target 26.56%
(12,161/45,782)**. **E's phone is ON MAIN at `298fb17`.**

**One thing E has NOT done and it is not the focus card:** the airplane-mode check on
`F-HomeTasksLastKnown` — turn on airplane mode, pull to refresh Home, the task list should keep its
last-known set rather than emptying. Ask E for it when convenient; do not build anything for it.

## Your job

**Build `F-FocusCard-4` only** — the celebration. Stop at the end of it and wait for E's device
verdict; do not roll into block 5.

**Read `handoff/SESSION-OPENER-focus-card-design.md` first.** It is the design record and it is
permanent. **Block 4's section of it is UNTOUCHED** by everything overtaken below.

## ⚠ What the record says that is no longer true

Blocks 1–3 each moved against the record. Block 4 inherits what shipped, not what the record says.

| the record says | what actually shipped |
|---|---|
| collapsed card full-bleed to both screen edges | **inset 16pt** (361pt wide), 60pt tall |
| collapsed card has a chevron | **gone** collapsed; kept expanded |
| long-press opens the detail sheet | **single TAP**, in both states; long-press RETIRED |
| completion card shares the "full-bleed flush geometry" | **it floats** — inset 16, radius 24, all four corners, 76pt tall. E chose this explicitly. |
| Confirm resets collapse | **only when NO sprint is running** — E's call, 2026-09-09 |
| the stack's peek is 8pt | **14pt** — E's call, 2026-09-10, and deliberately OFF §2's grid |

## Block 4's real constraints

- **iOS 16 is the floor.** No `PhaseAnimator`, `.symbolEffect`, `.keyframeAnimator`,
  `.sensoryFeedback`. §7 of `CLAUDE.md` prescribes `.sensoryFeedback` without flagging it is
  iOS 17+ — **the deployment target wins over §3 there.**
- **The haptic keys on `confirmableCompletionCount`.** NOT `completedSprintCount` (bumped on manual
  stops, which raise no card) and NOT `unconfirmedCompletions.count` (changes on confirm-removal,
  so it would buzz on dismissal).
- **Reduce Motion renders the FINAL state.**
- **Only the FRONT layer draws a real card** — the layers behind are blank `FocusCompletionCardEdge`
  bodies, because `.regularMaterial` blurs rather than hides. **A celebration keyed to a layer
  behind would be invisible, and one keyed to the stack rather than to the front record would fire
  for cards the user never saw.**
- **Evidence is `screenshots/focus-completion-celebration/` with its README**, not the unit test.

## Read these, in this order

1. `handoff/SESSION-OPENER-focus-card-design.md` — the design record; block 4's section is the job.
2. `handoff/OPEN-ITEMS-REGISTER.md` — **nineteenth edition**. THE outstanding list.
3. `CLAUDE.md` — Workflow, Version Control (`main` is protected), Session handoff, Visual evidence,
   UI/UX §1–§7. **§2 now carries the app's one sanctioned off-grid value; §7 matters more than
   usual here because iOS 16 is the floor.**
4. `claudecode.md` — the TDD role definition.
5. `screenshots/focus-card-stack/README.md` — the before/after of the peek and three bugs no test
   could catch; then `focus-card-light-peek-options/`, `focus-completion-card/`,
   `focus-card-collapse/`.

**Do NOT read `docs/`.** It is an archive describing a deleted Supabase backend.

## State gate — run before anything

```bash
git branch --show-current            # expect main
git status --short                   # must be empty
git log --oneline -1                 # and compare to origin/main
```

## Hard-won, and all of it will bite again

- **A green suite cannot see a `View`'s appearance. This arc has proved it FOUR times.** Block 1's
  `layoutPriority` compression reached E's device; block 2's was caught by a render; block 3's was
  the cards behind ghosting through `.regularMaterial`; and the 8pt peek's quietness was invisible
  to every layout assertion, all of which held. **Render the view to PNG from a unit test before
  the device build** — `UIHostingController` + `UIGraphicsImageRenderer` + `drawHierarchy`,
  `overrideUserInterfaceStyle` for dark, hosted in a `UIWindow` with the run loop pumped ~0.35s.
  No probe target, no signed-in simulator, no erase. **This is how the celebration should be judged
  too.**
- **To vary a `static let` across render variants, make it `var` for ONE run**, render everything,
  then `git checkout --` and **prove the restore with a full build**. Commit first.
- **A contrast ratio answers whether an edge can be DISTINGUISHED, never whether anyone will NOTICE
  it.** The peek measured 1.03:1 and the fix was geometry, not contrast. **Render the options and
  let E choose from pictures** — E's standing direction.
- **`Executed N tests, with M failures` counts failed ASSERTIONS, not failing TESTS.** Predict in
  TESTS, then reconcile. Names: `grep -oE "Test Case .*' failed" <log> | sort -u`.
- **Adding a single test tipped `FocusCompletionStackServiceTests` over BOTH SwiftLint ceilings**
  (400 lines, 250-line class body). The fix is a thematic file split with its own `private` doubles.
- **Commit BEFORE any red-check**, restore with `git checkout -- "ADHD LifeOS/"`, prove by
  re-running; inject regressions ONE AT A TIME and predict the count first.
- **Erase the sim between any UI run and the next unit run** —
  `xcrun simctl erase 9181EBF9-0F54-4A4D-A19C-19945D1BF155`, chained unconditionally.
- **A zsh glob matching nothing aborts the whole compound command.** Quote `--include="*.swift"`
  and any `rm -f` paths.
- **`layoutPriority` decides who is OFFERED space first, NOT who may shrink.** Rigid siblings need
  `.fixedSize()`, and the check is a look, not a green suite.

## Getting a real stack on device — the recipe E used

Three sprints, each run to its **natural end**, none confirmed. **30s is a preset chip**
(`presetDurationsSeconds = [30, 60, 120, 300, 600, 900, 1500]`), so it is ~90 seconds, not three
pomodoros. **Tapping Stop raises NO card** — `if naturally { pushUnconfirmedCompletion(stamped) }`.
**The stack survives a relaunch** (UserDefaults), so build it once and look at it whenever.

## Device reinstall recipe

```
xcodebuild build -project "ADHD LifeOS.xcodeproj" -scheme "ADHD LifeOS" \
  -destination 'platform=iOS,id=3DBC979A-3255-5456-8C30-172DB19B99B3' -allowProvisioningUpdates
xcrun devicectl device install app --device 3DBC979A-3255-5456-8C30-172DB19B99B3 \
  "/Volumes/Es-SSD/Xcode_External/DerivedData/ADHD_LifeOS-etcfckccqnfwduaoegzziavhdjel/Build/Products/Debug-iphoneos/ADHD LifeOS.app"
xcrun devicectl device process launch --terminate-existing \
  --device 3DBC979A-3255-5456-8C30-172DB19B99B3 com.ethananthony.ADHD-LifeOS
```

**A launch denied with `Security` / "invalid code signature… not explicitly trusted" right after a
re-issued profile is TRANSIENT — retry once before escalating to E.** It reads exactly like the
free-account blocker. Check the embedded profile's `ExpirationDate` against `date` and run
`codesign --verify --deep --strict`; valid and freshly minted means retry. A **locked** phone
refuses the LAUNCH but not the install — read `NSLocalizedFailureReason`. **The profile is valid to
2026-09-17**, days away: an empty Xcode account list means E must sign in via Xcode → Settings →
Accounts, never Claude Code.

# Start here — F-FocusCard-4, the celebration

*Paste into a fresh Claude Code terminal. Written 2026-09-09 at the close of the session that built
**F-FocusCard-3** (PR #49 → `110701a`).*

**This is the ONE live opener.** If you find a second `START-HERE-*` in `handoff/`, one of them is
a trap. Archive this file into `handoff/archive/` in the same move that writes your successor, at
the END of your session, never at the start.

---

## ⚠ READ THIS BEFORE ANYTHING ELSE

**Block 3 is LANDED but NOT CLOSED.** It merged to `main` at `110701a` and E's phone was reinstalled
from main, but **E had not given a device verdict when that session ended.**

So your first job is not block 4:

1. **Ask E for the block-3 verdict** if they have not already given one in this session's chat.
2. **If E asks for changes, they are FOLLOW-UPS TO BLOCK 3**, not block 4 — a `feature/focus-card-3-*`
   branch and its own PR, the way `F-PillReTap` followed the tab-depth arc. This arc is almost
   entirely visual and E iterates fast; block 1 took four device passes.
3. **Only start `F-FocusCard-4` once E has closed block 3.**

The likeliest thing E comes back on, and it is called out in the screenshots README: **in LIGHT
mode the peeking edges are carried almost entirely by the `StateGo` keyline**, because
`.regularMaterial` and `pageBackground` are close in value. It is legible but noticeably quieter
than dark. The levers, in order of bluntness: `FocusCompletionStackLayout.opacityStep` (0.15),
`peekStep` (8), `scaleStep` (0.05). **Do not re-tune any of them unprompted.**

## Your job, once block 3 is closed

**Build `F-FocusCard-4` only** — the celebration. Stop at the end of it and wait for E's device
verdict; do not roll into block 5.

**Read `handoff/SESSION-OPENER-focus-card-design.md` first.** It is the design record and it is
permanent. **Block 4's section of it is UNTOUCHED** by everything that has been overtaken below.

## ⚠ What the record says that is no longer true

Blocks 1–3 each moved against the record. Block 4 inherits what shipped, not what the record says.

| the record says | what actually shipped |
|---|---|
| collapsed card full-bleed to both screen edges | **inset 16pt** (361pt wide), 60pt tall |
| collapsed card has a chevron | **gone** collapsed; kept expanded |
| long-press opens the detail sheet | **single TAP**, in both states; long-press RETIRED |
| completion card shares the "full-bleed flush geometry" | **it floats** — inset 16, radius 24, all four corners, 76pt tall. **E chose this explicitly on 2026-09-09**, so it is settled, not a deviation any more. |
| Confirm resets collapse | **only when NO sprint is running** — E's call, 2026-09-09, changed in block 3 |

## What block 3 built for you

- `FocusCompletionCardStack` + `FocusCompletionStackLayout` in
  `Focus/FocusCompletionCardStack.swift`. The layout is PURE and owns the **draw order** as well as
  the offsets — `drawOrder(for:)` returns the layers back to front, so the `ZStack` trap is an
  ordinary assertion rather than an invisible defect.
- **Only the FRONT layer draws a real card.** The layers behind draw a blank
  `FocusCompletionCardEdge`, because `.regularMaterial` blurs rather than hides and full cards
  ghosted their ring and summary line through the front one. **This matters for block 4**: a
  celebration keyed to a card behind would be invisible, and one keyed to the stack rather than to
  the front record would fire for cards the user never saw.
- `RootBottomOverlay` renders the stack behind `if !unconfirmedCompletions.isEmpty`, and that `if`
  is load-bearing — the stack reserves top padding for peeks its `.offset`s hang outside its frame.

## Where things stand

**`main` @ `110701a`. No branch in flight.** `feature/focus-card-3` deleted both sides by its merge.
Verified on main: **suite 2,637 / 0** (emulator up, 0 `127.0.0.1:9099` hits, 0 skipped),
**lint 0 / 734**, sim + device builds `** BUILD SUCCEEDED **`, **app target 26.56%
(12,161/45,782)**. **E's phone is ON MAIN at `110701a`.**

## Read these, in this order

1. `handoff/SESSION-OPENER-focus-card-design.md` — the design record; block 4's section is the job.
2. `handoff/OPEN-ITEMS-REGISTER.md` — **eighteenth edition**. THE outstanding list.
3. `CLAUDE.md` — Workflow, Version Control (`main` is protected), Session handoff, Visual evidence,
   UI/UX §1–§7. **§7 matters more than usual here: iOS 16 is the floor.**
4. `claudecode.md` — the TDD role definition.
5. `screenshots/focus-card-stack/README.md`, then `focus-completion-card/` and
   `focus-card-collapse/` — what E settled by LOOKING, including three bugs no test could catch.

**Do NOT read `docs/`.** It is an archive describing a deleted Supabase backend.

## State gate — run before anything

```bash
git branch --show-current            # expect main
git status --short                   # must be empty
git log --oneline -1                 # expect 110701a or later
git log --oneline -1 origin/main     # same SHA
swiftlint lint                       # expect 0 violations, 734 files
ls -d *.xcresult                     # expect NONE
curl -s -m 2 http://127.0.0.1:4400/emulators   # emulator; start it if quiet
```

Start the emulator first: `nohup ./scripts/emulators.sh > /tmp/emulators.log 2>&1 &`. With it down
four suites SKIP rather than fail, so the run stays green but the figures are not comparable.

## Traps that matter for BLOCK 4

- **iOS 16 is the floor.** No `PhaseAnimator`, no `.symbolEffect`, no `.keyframeAnimator`, no
  `.sensoryFeedback`. Use the existing `#available`-split `.haptic(_:trigger:)` from
  `Theme/Haptics.swift:113-127`. `swiftui-pro` will tell you iOS 26 is the default target — §7 says
  ignore that entirely.
- **The haptic triggers on `confirmableCompletionCount`** — NOT `completedSprintCount`
  (`FocusSessionService.swift:30`, bumped on manual stops too) and NOT
  `unconfirmedCompletions.count` (which changes on confirm-REMOVAL, so it would buzz on dismissal).
  Key the burst to the record id so a card revealed by a Confirm does not re-celebrate.
- **Under Reduce Motion render the FINAL state** — checkmark present, no pulse. Never the
  pre-animation state, which is the trap that makes reduce-motion paths look broken.
- **Evidence is `screenshots/focus-completion-celebration/` with the mandatory README, not the unit
  test.** A test over a `reduceMotion ? nil : .easeOut(...)` ternary is near-vacuous. **The block is
  not done without the folder.**

## Traps that are general, and cost time in blocks 1–3

- **A SwiftUI view renders to PNG from a unit test** — `UIHostingController` +
  `UIGraphicsImageRenderer` + `drawHierarchy`, `overrideUserInterfaceStyle` for dark, host it in a
  `UIWindow` and pump the run loop briefly. No probe target, no signed-in simulator, no erase.
  **This is how block 3 caught the ghosting bug** the whole 2,637-test suite could not see. Do it
  before the device build, not after.
- **`Executed N tests, with M failures` counts failed ASSERTIONS, not failing TESTS.** Predict in
  TESTS, then reconcile. Names: `grep -oE "Test Case .*' failed" <log> | sort -u`.
- **Adding a single test tipped `FocusCompletionStackServiceTests` over BOTH SwiftLint ceilings**
  (400 lines, 250-line class body). The fix is a thematic file split with its own `private` doubles
  — every Focus test file carries its own twins, so the names cannot collide.
- **Commit BEFORE any red-check**, restore with `git checkout -- "ADHD LifeOS/"`, prove by
  re-running; inject regressions ONE AT A TIME and predict the count first.
- **Erase the sim between any UI run and the next unit run** —
  `xcrun simctl erase 9181EBF9-0F54-4A4D-A19C-19945D1BF155`, chained unconditionally.
- **A zsh glob matching nothing aborts the whole compound command.** Quote the paths in an `rm -f`.
- **`layoutPriority` decides who is OFFERED space first, NOT who may shrink.** Rigid siblings need
  `.fixedSize()`, and the check is a look, not a green suite.

## Device reinstall recipe

```
xcodebuild build -project "ADHD LifeOS.xcodeproj" -scheme "ADHD LifeOS" \
  -destination 'platform=iOS,id=3DBC979A-3255-5456-8C30-172DB19B99B3' -allowProvisioningUpdates
xcrun devicectl device install app --device 3DBC979A-3255-5456-8C30-172DB19B99B3 \
  "/Volumes/Es-SSD/Xcode_External/DerivedData/ADHD_LifeOS-etcfckccqnfwduaoegzziavhdjel/Build/Products/Debug-iphoneos/ADHD LifeOS.app"
xcrun devicectl device process launch --terminate-existing \
  --device 3DBC979A-3255-5456-8C30-172DB19B99B3 com.ethananthony.ADHD-LifeOS
```

A locked phone refuses the LAUNCH but not the install — read `NSLocalizedFailureReason` before
suspecting the build. **The free-dev-account profile is roughly valid to 2026-09-15**, which is six
days out: an empty Xcode account list means E must sign in via Xcode → Settings → Accounts, never
Claude Code.

**Seeing a real stack on device needs THREE completed sprints, each floored at 30s by
`FocusCheckpoints.minimumIntervalSeconds`, none confirmed.** Render it from a unit test instead of
asking E to sit through them.

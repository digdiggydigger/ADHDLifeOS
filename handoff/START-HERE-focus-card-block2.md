# Start here — build F-FocusCard-2, the provisional record and the completed-unconfirmed card

*Paste into a fresh Claude Code terminal. Written 2026-09-09 at the close of the session that
shipped **F-FocusCard-1** (PR #43 → `89ee187`, close-out PR #44 → `21b7b93`, follow-up fix
PR #45 → `59fcf20`) and, at E's separate request, **F-TabBar-NoScrollDrop**. Block 1 is CLOSED on
E's device verdict: "That all works very nicely."*

**This is the ONE live opener.** If you find a second `START-HERE-*` in `handoff/`, one of them is
a trap. Archive this file into `handoff/archive/` in the same move that writes your successor, at
the END of your session, never at the start.

---

## Your job

**Build `F-FocusCard-2` only.** Stop at the end of it and wait for E's device verdict — do not roll
into block 3.

**Read `handoff/SESSION-OPENER-focus-card-design.md` first.** It is the design record, it is
permanent, and block 2's section of it is UNTOUCHED by everything below.

## ⚠ Read this before you trust the design record

**Block 1's half of that record has been overtaken.** E redesigned the collapsed card four times on
device during the block, and a session that follows the record literally will rebuild things E has
already rejected. Block 2's section is unaffected — but the card you are adding to is not the card
the record describes.

| the record says (block 1) | what actually shipped |
|---|---|
| full-bleed to both screen edges | **inset 16pt** (361pt wide) |
| chevron a real button in both states | **collapsed: gone.** expanded: kept |
| grabber is the first child of the stack | **overlaid in the card's top padding** — as a child it cost 13pt in BOTH states |
| long-press opens the detail sheet | **single TAP opens it, in both states**; long-press RETIRED |
| tap toggles collapse | collapse is the **swipe and the grabber only** |
| — | **no bottom border** when collapsed |
| 73pt tall | **60pt** — the tab bar's own height |

The collapsed card is now: `ring 44 | emoji + title | Spacer | Pause glyph`, no chevron, no PAUSED
badge. `FocusBarMetrics` holds every number and each carries the reason in its doc comment.

**Two things block 2 must not undo:**
- **`AppTabBarMetrics.floatingLift` is DELETED.** E retired the nav bar's scroll-driven vertical
  drop. `AppTabBarCallSiteTests.testTheBarsBottomPaddingIsUnconditional` fails if it returns.
- **The collapsed card is flush ONLY because the bar stopped moving.** Do not reintroduce a
  second lift.

## Where things stand

**`main` @ `59fcf20`. No branch in flight. Nothing for block 2 has been started.**
Verified on main: **suite 2,586 / 0** (emulator up, 0 `9099` hits, 0 skipped), **lint 0 / 725**,
sim + device builds `** BUILD SUCCEEDED **`, **app target 26.02% (11,802/45,364)** (measured at
`21b7b93`; PR #45 added one test and three `.fixedSize()` calls, so the figure still stands).

**E's phone has the `59fcf20` build INSTALLED but it was not launched** — the device was locked and
`devicectl` refuses the launch, not the install. Nothing to redo; E opens the app.

## Read these, in this order

1. `handoff/SESSION-OPENER-focus-card-design.md` — the design record; block 2's section is the job.
2. `handoff/OPEN-ITEMS-REGISTER.md` — sixteenth edition. THE outstanding list.
3. `CLAUDE.md` — Workflow, Version Control (`main` is protected), Session handoff, Visual
   evidence, UI/UX §1–§7.
4. `claudecode.md` — the TDD role definition.
5. `screenshots/focus-card-collapse/README.md` — what E settled by LOOKING in block 1, including
   a rendering bug no test could have caught.

**Do NOT read `docs/`.** It is an archive describing a deleted Supabase backend.

## State gate — run before anything

```bash
git branch --show-current            # expect main
git status --short                   # must be empty
git log --oneline -1                 # expect 59fcf20 or later
git log --oneline -1 origin/main     # same SHA
swiftlint lint                       # expect 0 violations, 725 files
ls -d *.xcresult                     # expect NONE
curl -s -m 2 http://127.0.0.1:4400/emulators   # emulator; start it if quiet
```

Start the emulator first: `./scripts/emulators.sh` in a second terminal, or
`nohup ./scripts/emulators.sh > /tmp/emulators.log 2>&1 &`. With it down four suites SKIP rather
than fail, so the run stays green but the figures are not comparable.

## Traps that matter for THIS block

- **The push must happen SYNCHRONOUSLY before `await log(...)`** at `FocusSessionService.swift`'s
  completion path, so the card exists even if the Firestore write hangs.
  `testThePushLandsBeforeTheLogAwait` is the only test that can see an ordering bug here.
- **`testManualStopPushesNothing` is the discriminator for the whole feature.** An implementation
  that pushes on every `finishCurrentSprint` passes the natural-completion test and fails this one.
- **Widening `FocusSprintPersisting` breaks the WHOLE test target's compile** until BOTH recording
  fakes are updated — `FocusSprintPersistenceTests`, `FocusLocationStampTests`, **and now
  `FocusBarCollapseTests` + `FocusBarGeometryTests`, which each carry their own fake** (four, not
  two, since block 1). That compile break IS the red step.
- **Block 2 is what finally resets collapse.** `setCardCollapsed(false)` belongs in
  `confirmCompletion`. Block 1 shipped deliberately sticky and E knows.
- **A source-reading call-site test must strip COMMENT lines before any `XCTAssertFalse`** — these
  files quote the anti-patterns they ban. Copy `appCode()` from `FocusBarCollapseCallSiteTests`.
- **`RootBottomOverlay.swift` animates on `isActive` only** — add a second `.animation(…, value:
  unconfirmedCompletions.count)` or the running card's exit and the completion card's entrance
  will not be choreographed.
- **Use `FocusTimeFormatting.human(seconds:)`, NOT `duration(seconds:)`** — `duration` drops
  seconds, so a `+30s` sprint would read "25m" when 25m 30s was banked.
- **Commit BEFORE any red-check**, restore with `git checkout --`, prove by rebuilding; inject
  regressions ONE AT A TIME.
- **Read the `Executed N tests, with M failures` line.** `grep -c 'Test Case.*failed'` counts
  eight test NAMES containing the word; a trailing `grep -c` that finds nothing also exits 1.
- **`layoutPriority` decides who is OFFERED space first, NOT who may shrink.** This shipped as a
  bug in block 1 and E caught it in a screenshot AFTER the merge: `.layoutPriority(1)` on the
  sprint title made SwiftUI compress its priority-0 `Text` siblings to nothing — the life-area
  emoji vanished and the PAUSED badge became a 1pt sliver. The rigid pieces need `.fixedSize()`.
  **No test saw it**: nothing asserts text layout, and `UIHostingController.sizeThatFits` reaches a
  view's total height but not the width of a `Text` inside an `HStack`. Block 2 adds a completion
  card with a title, a duration and a Confirm button on one row — **if you reach for
  `layoutPriority` there, get a device look, not just a green suite.**
- **Erase the sim between any UI run and the next unit run** —
  `xcrun simctl erase 9181EBF9-0F54-4A4D-A19C-19945D1BF155`, chained unconditionally.

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
suspecting the build. The free-dev-account profile is roughly valid to **2026-09-15**; an empty
Xcode account list means E must sign in via Xcode → Settings → Accounts, never Claude Code.

**This arc is almost entirely visual. E's device verdict is the real evidence** — and E iterates
fast, so expect several passes per block. Build, install, report, and ask rather than guessing at
geometry.

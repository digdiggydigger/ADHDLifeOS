# Start here — the tab depth arc: block 1 (the tab re-tap) is in PR #35 on E's device verdict; block 2 (the search row over a pushed task detail) is next

*Paste into a fresh Claude Code terminal. Rewritten 2026-09-08 mid-morning, after the same
session built `F-TabDepth-1-PopToRoot` on `feature/tab-depth` (PR #35 OPEN) and installed it
on E's phone at 09:22. `main` @ `38b309c`. The emulator was left running.*

**This is the ONE live opener.** If you find a second `START-HERE-*` in `handoff/`, one of them
is a trap — see CLAUDE.md, "Session handoff". Archive this file into `handoff/archive/` in the
same move that writes your successor, at the END of your session, never at the start.

---

## Where the arc stands — read this before the ask below

**Block 1 is BUILT and on E's phone, awaiting E's verdict.** If E has said the re-tap behaves,
merge PR #35 (`gh pr merge 35 --merge --delete-branch`), reinstall the phone from main, tick the
last criterion in `TODO-CLAUDE-CODE.md`, and start block 2 below. If E has not, ask — do not
merge on your own judgment. Design record: `handoff/SESSION-OPENER-tab-depth-design.md` (the
probe table in it is what settled the mechanism; read it before touching any push).

**Block 2 uses the seam block 1 built:** `TabNavigationCoordinator.isAtRoot(tab)` is already
injected at the root as `tabNavigation`. `RootView` derives `searchModel.scope` from
`selectedTab` alone; make it `AppSearchScope.scope(for: tab, isAtRoot:)` (pure rule, TDD in
`AppSearchScopeTests`), have `RootView` read `tabNavigation.isAtRoot(selectedTab)`, and add a
call-site test that it does. The row leaves with `RootBottomOverlay`'s existing spring.

## The one instruction that matters (block 2)

**E, 2026-09-08 06:20, mid-session, with a screenshot:** *"please note that we need to remove the
'search tasks' search bar from a full view task screen such as the one shown in one of the
screenshots."*

The screenshot is `screenshots/arrival-card-refresh/02-task-detail-at-place-home-open.jpeg`: a
task's DETAIL screen, pushed from the Tasks list, with the bottom-search arc's *"Search tasks"*
row still sitting above the tab bar beside the capture disc. E wants it gone there. The row on
the Tasks LIST is settled and approved (bottom-search arc, E's own layout call of 2026-09-03) —
do not touch its position, spacing or behaviour on the list.

## What the code says (read first-hand 2026-09-08, still true at `bab1681`)

The row does not live in the Tasks screen at all. **It is mounted once, at the root, in
`ADHD LifeOS/RootBottomOverlay.swift`** beside the capture disc, and shows when `searchScope !=
.none`. `RootView` derives that scope **from `selectedTab` alone** (`AppSearchScope`,
`AppSearchCallSiteTests.testRootViewDrivesTheScopeFromTheSelectedTab`). `TaskListView.swift:39`
is its own `NavigationStack`, and a task detail is pushed inside it via
`navigationDestination(isPresented:)` (`TaskListView.swift:131`, driven by `inspectingTask`).
**The root never learns that the tab is no longer at its root screen**, so the scope stays
`.tasks` and the row stays. That is the whole bug.

So the fix is a SIGNAL, not a layout change — **and block 1 already built the signal. Do not
build a second one.** `TaskListView` reports its depth through
`.tabRoot(.tasks, isAtRoot: inspectingTask == nil, …)` into `TabNavigationCoordinator`, which
`RootView` owns as `tabNavigation` and injects. Block 2 is therefore small:

- `AppSearchScope` gains the pure rule `scope(for: tab, isAtRoot: Bool)` — `.none` whenever
  `isAtRoot` is false — TDD in `AppSearchScopeTests` (watch it fail first).
- `RootView` feeds it `tabNavigation.isAtRoot(selectedTab)` instead of the tab alone; extend
  `AppSearchCallSiteTests` (`testRootViewDrivesTheScopeFromTheSelectedTab`) so the call site
  is read: the scope must be derived from BOTH the tab and the depth.
- The row leaves with `RootBottomOverlay`'s existing spring; sheets and covers are untouched
  (the task composer and the search surface already cover the overlay).
- Red-check it; then a UI proof if cheap: push a task detail, assert the search row's element is
  gone; re-tap Tasks, assert it is back. `TabReselectionJourneyUITests` shows the settle
  helpers a journey needs after a fresh sign-in.

**E's instruction, 2026-09-08 ~09:40: *"complete block two in a new fresh Claude Code terminal
session."*** That session is you. E was performing the three block-1 checks on the phone when
this was written; the register's A1 records whether the verdict has landed.
  E's ask is the pushed detail; do not widen it unasked.

Animate the row out with the same spring the overlay already uses; a hard pop beside the disc
will read as a glitch.

## Read these, in this order

1. **`CLAUDE.md`** — Workflow, Version Control (every change lands through a PR; `main` is
   protected), Session handoff, Visual evidence, UI/UX §1–§7.
2. **`claudecode.md`** — the TDD role definition.
3. **`handoff/OPEN-ITEMS-REGISTER.md`** — THE outstanding list, **eleventh edition** (A1 is
   E's verdict on block 1; B1 is block 2; B2 and B3 are the arrival-card follow-ups).
4. **`handoff/SESSION-OPENER-bottom-search-build.md`** — the search row's build record: why
   `.searchable` was killed, why the row lives at the root, E's layout call.
5. **`handoff/SESSION-OPENER-tab-depth-design.md`** — the arc's design record: E's four
   answers, the probe table, and what the UI journey caught (all harness, no app defects).

**Do NOT read `docs/`.** It is an archive of a legacy build and says this app runs on Supabase.

## State gate — run before anything

```bash
git branch --show-current            # expect main
git status --short                   # must be empty
git log --oneline -1                 # expect 38b309c or later (main); PR #35 may still be open
git log --oneline -1 origin/main     # same SHA
swiftlint lint                       # expect 0 violations, 712 files
ls -d *.xcresult                     # expect NONE — deleted after each read, E's standing word
```

Last verified ON THE BRANCH at `639cf24`+: suite 2,540 / 0, lint 0 / 717, journey class 3 / 0;
figures in the register's eleventh edition. Free-dev-account profile roughly valid to **2026-09-15**.

## Traps that matter right now

- **Erase the sim between a UI run and any unit run** — `xcrun simctl erase
  9181EBF9-0F54-4A4D-A19C-19945D1BF155`. No UI target ran this session; 0 `9099` hits. The sim
  is SIGNED OUT; a signed-in drive needs E (never automate auth).
- **Commit BEFORE any red-check**, restore with `git checkout --`, prove by rebuilding; inject
  regressions ONE AT A TIME.
- **The device verdict is E's, in words or a screenshot** — E's own screenshots, filed with
  README rows, are the working evidence route; iPhone Mirroring cannot be started from the
  terminal.
- **E's phone ran out of storage once this morning** (`No space left on device` from the
  installer; a launch after a failed install wakes the OLD build). If an install fails, read the
  installer's `NSLocalizedFailureReason` before suspecting the build.
- **After the merge, the phone tracks main only if the merge touched Swift** — this one will, so
  rebuild from main and reinstall (`xcodebuild build -destination 'platform=iOS,id=3DBC979A-
  3255-5456-8C30-172DB19B99B3' -allowProvisioningUpdates`, then `xcrun devicectl device install
  app` and `… process launch --terminate-existing`).

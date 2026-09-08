# Start here — E's next item: the bottom "Search tasks" row must not stay on screen over a pushed task detail

*Paste into a fresh Claude Code terminal. Written 2026-09-08 at the close of the session that
shipped `F-ArrivalCardRefresh` (PR #32, merged; `main` @ `99d9211`). E's phone is on the
`4d8de11` branch build, which is the same Swift as main. The emulator was left running.*

**This is the ONE live opener.** If you find a second `START-HERE-*` in `handoff/`, one of them
is a trap — see CLAUDE.md, "Session handoff". Archive this file into `handoff/archive/` in the
same move that writes your successor, at the END of your session, never at the start.

---

## The one instruction that matters

**E, 2026-09-08 06:20, mid-session, with a screenshot:** *"please note that we need to remove the
'search tasks' search bar from a full view task screen such as the one shown in one of the
screenshots."*

The screenshot is `screenshots/arrival-card-refresh/02-task-detail-at-place-home-open.jpeg`: a
task's DETAIL screen, pushed from the Tasks list, with the bottom-search arc's *"Search tasks"*
row still sitting above the tab bar beside the capture disc. E wants it gone there. The row on
the Tasks LIST is settled and approved (bottom-search arc, E's own layout call of 2026-09-03) —
do not touch its position, spacing or behaviour on the list.

## What the code says (read first-hand at this close-out, `main` @ `99d9211`)

The row does not live in the Tasks screen at all. **It is mounted once, at the root, in
`ADHD LifeOS/RootBottomOverlay.swift`** beside the capture disc, and shows when `searchScope !=
.none`. `RootView` derives that scope **from `selectedTab` alone** (`AppSearchScope`,
`AppSearchCallSiteTests.testRootViewDrivesTheScopeFromTheSelectedTab`). `TaskListView.swift:39`
is its own `NavigationStack`, and a task detail is pushed inside it via
`navigationDestination(isPresented:)` (`TaskListView.swift:131`, driven by `inspectingTask`).
**The root never learns that the tab is no longer at its root screen**, so the scope stays
`.tasks` and the row stays. That is the whole bug.

So the fix is a SIGNAL, not a layout change: the Tasks tab tells the root whether it is at its
root screen, and the scope resolves to `.none` while a detail is pushed. Shapes that fit the
house style, pick after reading:

- A `PreferenceKey` (or an `@Environment` binding handed down from RootView) that
  `TaskListView` sets from `inspectingTask != nil`; `AppSearchScope` gains a pure rule
  `scope(for: tab, atTabRoot: Bool)` and `RootView` feeds it. The pure rule is the TDD target —
  extend `AppSearchScopeTests`; `AppSearchCallSiteTests` is the file that greps the call sites
  and should gain a test that the Tasks screen REPORTS its depth.
- Check the same seam for the task CREATE sheet (`TaskCreateView` is a sheet — sheets cover the
  overlay, so probably fine) and the search SURFACE itself (`fullScreenCover`, covers it too).
  E's ask is the pushed detail; do not widen it unasked.

Animate the row out with the same spring the overlay already uses; a hard pop beside the disc
will read as a glitch.

## Read these, in this order

1. **`CLAUDE.md`** — Workflow, Version Control (every change lands through a PR; `main` is
   protected), Session handoff, Visual evidence, UI/UX §1–§7.
2. **`claudecode.md`** — the TDD role definition.
3. **`handoff/OPEN-ITEMS-REGISTER.md`** — THE outstanding list, **tenth edition** (this item is
   B1; B2 and B3 are the two small follow-ups the arrival-card fix deferred on purpose).
4. **`handoff/SESSION-OPENER-bottom-search-build.md`** — the search row's build record: why
   `.searchable` was killed, why the row lives at the root, E's layout call.
5. **`handoff/SESSION-OPENER-arrival-card-refresh-design.md`** — the newest design record and
   the house style for one; its "investigate the real data first" lesson generalises.

**Do NOT read `docs/`.** It is an archive of a legacy build and says this app runs on Supabase.

## State gate — run before anything

```bash
git branch --show-current            # expect main
git status --short                   # must be empty
git log --oneline -1                 # expect 99d9211 or later
git log --oneline -1 origin/main     # same SHA
swiftlint lint                       # expect 0 violations, 712 files
ls -d *.xcresult                     # expect NONE — deleted after each read, E's standing word
```

Last verified ON MAIN at `99d9211`: lint **0 / 712**; suite and coverage figures are in the
register's tenth edition. Free-dev-account profile roughly valid to **2026-09-15**.

## Traps that matter right now

- **Erase the sim between a UI run and any unit run** — `xcrun simctl erase
  9181EBF9-0F54-4A4D-A19C-19945D1BF155`. No UI target ran this session; 0 `9099` hits. The sim
  is SIGNED OUT; a signed-in drive needs E (never automate auth).
- **Commit BEFORE any red-check**, restore with `git checkout --`, prove by rebuilding; inject
  regressions ONE AT A TIME.
- **The device verdict is E's, in words or a screenshot** — E's own screenshots, filed with
  README rows, are the working evidence route; iPhone Mirroring cannot be started from the
  terminal.
- **After the merge, the phone tracks main only if the merge touched Swift** — this one will, so
  rebuild from main and reinstall (`xcodebuild build -destination 'platform=iOS,id=3DBC979A-
  3255-5456-8C30-172DB19B99B3' -allowProvisioningUpdates`, then `xcrun devicectl device install
  app` and `… process launch --terminate-existing`).

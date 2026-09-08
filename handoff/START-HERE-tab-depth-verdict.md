# Start here — the tab depth arc: BOTH blocks are on E's phone at `c4fba78`, PR #35 carries both, and E's device verdict is the only thing between them and `main`

*Paste into a fresh Claude Code terminal. Written 2026-09-08 midday, after the session that
built `F-TabDepth-2-SearchRowAtRoot` on `feature/tab-depth` on top of block 1 and installed the
combined build on E's phone at 12:07. `main` @ `38b309c`. The emulator was left running.*

**This is the ONE live opener.** If you find a second `START-HERE-*` in `handoff/`, one of them
is a trap — see CLAUDE.md, "Session handoff". Archive this file into `handoff/archive/` in the
same move that writes your successor, at the END of your session, never at the start.

---

## Where the arc stands

**Both blocks are BUILT, in PR #35, and on E's phone.** E deferred block 1's three checks (late
morning: *"Can I complete them after you've built block 2?"*), so block 2 was built on the same
branch rather than after a merge, and the phone carries both. **The install at 12:07 succeeded;
the launch was refused because the phone was locked** — E opens the app by hand, and should
**force-quit it first** (an install over a running app can wake the old build until it is
relaunched; `relaunch-before-judging-device`).

**E's four checks, in one sitting:**

1. Today → into Nudges → tap the Today tab: Today's top-level page comes back. (block 1)
2. Nudges shows a Back chevron of its own. (block 1)
3. Scroll any tab down and re-tap it: it scrolls back to the top. (block 1)
4. Tasks → open any task's detail: the *"Search tasks"* row is GONE beside the capture disc;
   re-tap Tasks (or Back): the row is back on the list. (block 2)

**If all four pass:** `gh pr merge 35 --merge --delete-branch`, then reinstall the phone from
`main` (the merge touches Swift, so the phone tracks main only after a rebuild), tick the last
box in both TODO blocks, rewrite the register, and ask E what is next — the register's B-list
leads with the two arrival-card follow-ups. **If any fails, fix it on the branch — do not merge
on your own judgment.** Block 2's one judgment call E can veto: the overlay's spring now also
fades the row on a tab SWITCH (it used to pop with the hard-cut tab content); reverting that is
one `.animation(value: searchScope)` line in `RootBottomOverlay.swift`.

## What the code says (read first-hand 2026-09-08, true at `c4fba78`)

- `AppSearchScope.scope(for:isAtRoot:)` — `.none` for any tab below its top-level page,
  `isAtRoot` with **no default**. `RootView.searchScope` masks the selected tab's scope by
  `tabNavigation.isAtRoot(selectedTab)` and `.onChange(of: searchScope)` feeds the model.
- `RootBottomOverlay` has a second `.animation(value: searchScope)` on the house spring.
- Guards: `AppSearchScopeTests` (6), `AppSearchCallSiteTests` (the root derives from BOTH tab and
  depth; the overlay animates on the scope), `SearchRowDepthJourneyUITests` (1, the acceptance
  test — it was RED against a build where the rule existed and the root ignored it).
- `seedTask` now lives on `UITestSession` (`UITestFixtures.swift`); `SignedInJourneySupport`'s
  copy delegates. A journey in any class can seed a task with a known id.

## Read these, in this order

1. **`CLAUDE.md`** — Workflow, Version Control (`main` is protected; every change lands through
   a PR), Session handoff, Visual evidence, UI/UX §1–§7.
2. **`claudecode.md`** — the TDD role definition.
3. **`handoff/OPEN-ITEMS-REGISTER.md`** — THE outstanding list, **twelfth edition**.
4. **`handoff/SESSION-OPENER-tab-depth-design.md`** — the arc's design record (the probe table).
5. **`handoff/SESSION-OPENER-bottom-search-build.md`** — the search row's build record.

**Do NOT read `docs/`.** It is an archive of a legacy build and says this app runs on Supabase.

## State gate — run before anything

```bash
git branch --show-current            # main after the merge; feature/tab-depth before it
git status --short                   # must be empty
git log --oneline -1                 # expect c4fba78+ on the branch, or the merge on main
git log --oneline -1 origin/main     # 38b309c until PR #35 merges
swiftlint lint                       # expect 0 violations, 719 files
ls -d *.xcresult                     # expect NONE — deleted after each read, E's standing word
```

Last verified ON THE BRANCH at `c4fba78`: unit suite 2,543 / 0 (emulator up), lint 0 / 719,
`SearchRowDepthJourneyUITests` 1 / 0, `TabReselectionJourneyUITests` 3 / 0 (block 1's run);
figures in the register's twelfth edition. Free-dev-account profile roughly valid to
**2026-09-15**.

## Traps that matter right now

- **Erase the sim between a UI run and any unit run** — `xcrun simctl erase
  9181EBF9-0F54-4A4D-A19C-19945D1BF155`. Two UI runs this session, two erases; the sim is
  erased and SIGNED OUT. A signed-in drive needs E (never automate auth).
- **Commit BEFORE any red-check**, restore with `git checkout --`, prove by rebuilding; inject
  regressions ONE AT A TIME.
- **The device verdict is E's, in words or a screenshot.** iPhone Mirroring cannot be started
  from the terminal.
- **A locked phone refuses `devicectl … process launch` but not the install** — read the
  `NSLocalizedFailureReason` (`Locked`) before suspecting the build. E's phone also ran out of
  storage once this morning; `No space left on device` is the other reason to read.
- **Reinstall from main after the merge:** `xcodebuild build -destination
  'platform=iOS,id=3DBC979A-3255-5456-8C30-172DB19B99B3' -allowProvisioningUpdates`, then
  `xcrun devicectl device install app --device 3DBC979A-… "<Debug-iphoneos>/ADHD LifeOS.app"`
  and `… process launch --terminate-existing com.ethananthony.ADHD-LifeOS`. The `.app` path is
  in the build log (`Debug-iphoneos`), on the external SSD's DerivedData.

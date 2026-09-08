# Start here — the tab depth arc is MERGED and on E's phone; nothing is in flight, so the next block is E's call

*Paste into a fresh Claude Code terminal. Written 2026-09-08 evening, after E's device verdict
(*"All 4 checks were successful"*) merged PR #35 as `main` @ `1100a01`, the phone was
reinstalled from main, and the suite was re-run ON main. The emulator was left running.*

**This is the ONE live opener.** If you find a second `START-HERE-*` in `handoff/`, one of them
is a trap — see CLAUDE.md, "Session handoff". Archive this file into `handoff/archive/` in the
same move that writes your successor, at the END of your session, never at the start.

---

## Where things stand

**Nothing is in flight.** The tab depth arc (a re-tap pops to the tab's top-level page or scrolls
to the top; Nudges has a Back chevron; the "Search tasks" row hides over a pushed task detail)
shipped in one PR on E's verdict, with E's two screenshots filed at `screenshots/tab-depth/`.
The branch is deleted. **E's phone runs `main` @ `1100a01`**, so device behaviour is main's
behaviour.

**The next block is E's call — ask.** The register's B-list is the recommended order, and its
top two are the arrival-card follow-ups deferred when F-ArrivalCardRefresh merged:

1. **Accuracy-aware containment** — ONLY if E still sees the arrival card drop on a
   pull-to-refresh. Widening `LocationFixProviding` touches every caller; do not start it on
   theory.
2. **`HomeService.load()` empties `allTasks` on a failed fetch** — one line + one test, the
   inbox's keep-last-known precedent.
3. Arc 2 (first-class routines + the "at a time" trigger); killing `F-Search-3-Journal`; the
   parked Live Activity design review.

One low item E can veto at any time: block 2's overlay spring also fades the search row on a
tab SWITCH (one line in `RootBottomOverlay.swift` to revert). E's four checks passed on the
build that has it.

## Read these, in this order

1. **`CLAUDE.md`** — Workflow, Version Control (`main` is protected; every change lands through
   a PR), Session handoff, Visual evidence, UI/UX §1–§7.
2. **`claudecode.md`** — the TDD role definition.
3. **`handoff/OPEN-ITEMS-REGISTER.md`** — THE outstanding list, **thirteenth edition**.
4. Whichever design record the block E picks belongs to:
   `handoff/SESSION-OPENER-arrival-card-refresh-design.md` for the arrival-card items,
   `handoff/SESSION-OPENER-tab-depth-design.md` for anything touching a tab's push or the
   bottom furniture, `handoff/SESSION-OPENER-routines-design.md` for arc 2.

**Do NOT read `docs/`.** It is an archive of a legacy build and says this app runs on Supabase.

## State gate — run before anything

```bash
git branch --show-current            # expect main
git status --short                   # must be empty
git log --oneline -1                 # expect 1100a01 or later
git log --oneline -1 origin/main     # same SHA
swiftlint lint                       # expect 0 violations, 719 files
ls -d *.xcresult                     # expect NONE — deleted after each read, E's standing word
```

Last verified ON MAIN at `1100a01`: unit suite 2,543 / 0 (emulator up, 0 `9099` hits), lint
0 / 719, device build green, app target 24.76% (11,189/45,196). Free-dev-account profile roughly
valid to **2026-09-15**.

## Traps that matter right now

- **Erase the sim between a UI run and any unit run** — `xcrun simctl erase
  9181EBF9-0F54-4A4D-A19C-19945D1BF155`. The sim is erased and SIGNED OUT; a signed-in drive
  needs E (never automate auth).
- **Commit BEFORE any red-check**, restore with `git checkout --`, prove by rebuilding; inject
  regressions ONE AT A TIME.
- **Read the `Executed N tests, with M failures` line** — `grep -c 'Test Case.*failed'` counts
  eight test NAMES that contain the word and reads as eight failures on a green suite.
- **A locked phone refuses `devicectl … process launch` but not the install** — read the
  `NSLocalizedFailureReason` before suspecting the build.
- **Device reinstall recipe** (only needed after a merge that touches Swift):
  `xcodebuild build -destination 'platform=iOS,id=3DBC979A-3255-5456-8C30-172DB19B99B3'
  -allowProvisioningUpdates`, then `xcrun devicectl device install app --device 3DBC979A-…
  "<Debug-iphoneos>/ADHD LifeOS.app"` and `… process launch --terminate-existing
  com.ethananthony.ADHD-LifeOS`. The `.app` path is in the build log, on the external SSD.

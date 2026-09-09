# Start here — nothing is in flight: the tab depth arc and its pill follow-up are MERGED and on E's phone; the next block is E's call

*Paste into a fresh Claude Code terminal. Written 2026-09-08 late evening at the close of the
session that shipped F-TabDepth-2, merged the tab depth arc on E's verdict, then found, fixed
and merged F-PillReTap on E's GIF. `main` @ `a6b8021` (+ this close-out's docs merge). The
emulator was left running.*

**This is the ONE live opener.** If you find a second `START-HERE-*` in `handoff/`, one of them
is a trap — see CLAUDE.md, "Session handoff". Archive this file into `handoff/archive/` in the
same move that writes your successor, at the END of your session, never at the start.

---

## Where things stand

**Nothing is in flight, no branch exists but `main`, and E's phone runs `main` @ `a6b8021`.**
Three things landed on 2026-09-08 and all three have E's device verdict in words:

- **F-TabDepth-1** — a re-tap on the selected tab pops to its top-level page or scrolls to the
  top; Nudges has a Back chevron. (PR #35, *"All 4 checks were successful"*)
- **F-TabDepth-2** — the bottom "Search tasks" row hides while a task detail is pushed. (PR #35,
  same verdict; E's screenshots at `screenshots/tab-depth/`)
- **F-PillReTap** — a scroll-to-top re-tap also restores the capture disc from its pill. (PR #37,
  *"I've just checked that on my phone and it works."*)

**The next block is E's call — ASK before building anything.** The register's B-list is the
recommended order:

1. **Accuracy-aware containment for the arrival card** — ONLY if E still sees the card drop on a
   pull-to-refresh after F-ArrivalCardRefresh. Widening `LocationFixProviding` touches every
   caller; do not start it on theory.
2. **`HomeService.load()` empties `allTasks` on a failed fetch** — one line + one test, the
   inbox's keep-last-known precedent.
3. Arc 2 (first-class routines + the "at a time" trigger); killing `F-Search-3-Journal`; the
   parked Live Activity design review.

One low item E can veto at any time: block 2's overlay spring also fades the search row on a
tab SWITCH (one line in `RootBottomOverlay.swift` to revert). E's checks passed on the build
that has it and E has not raised it.

## Read these, in this order

1. **`CLAUDE.md`** — Workflow, Version Control (`main` is protected; every change lands through
   a PR), Session handoff, Visual evidence, UI/UX §1–§7.
2. **`claudecode.md`** — the TDD role definition.
3. **`handoff/OPEN-ITEMS-REGISTER.md`** — THE outstanding list, **fourteenth edition**.
4. Whichever design record the block E picks belongs to:
   `handoff/SESSION-OPENER-arrival-card-refresh-design.md` for the arrival-card items,
   `handoff/SESSION-OPENER-tab-depth-design.md` for anything touching a tab's push, the re-tap
   or the bottom furniture, `handoff/SESSION-OPENER-routines-design.md` for arc 2.

**Do NOT read `docs/`.** It is an archive of a legacy build and says this app runs on Supabase.

## State gate — run before anything

```bash
git branch --show-current            # expect main
git status --short                   # must be empty
git log --oneline -1                 # expect a6b8021 or later
git log --oneline -1 origin/main     # same SHA
swiftlint lint                       # expect 0 violations, 720 files
ls -d *.xcresult                     # expect NONE — deleted after each read, E's standing word
```

Last verified ON MAIN at `a6b8021`: unit suite 2,546 / 0 (emulator up, 0 `9099` hits), lint
0 / 720, device build green, app target 24.76% (11,192/45,206). Free-dev-account profile roughly
valid to **2026-09-15** — the 21:03 device build needed no provisioning update.

## Traps that matter right now

- **Erase the sim between a UI run and any unit run** — `xcrun simctl erase
  9181EBF9-0F54-4A4D-A19C-19945D1BF155`. The sim is erased, shut down and SIGNED OUT; a
  signed-in drive needs E (never automate auth).
- **Commit BEFORE any red-check**, restore with `git checkout --`, prove by rebuilding; inject
  regressions ONE AT A TIME.
- **Read the `Executed N tests, with M failures` line** — `grep -c 'Test Case.*failed'` counts
  eight test NAMES that contain the word and reads as eight failures on a green suite.
- **The capture disc's pill is invisible to a UI journey** (its outer frame is 60×60 in both
  states by design) — anything about the pill is proved on the phone, by E.
- **`RootView.swift` sits at 399 of 400 lines.** A new member goes in an extension file
  (`RootView+Doors.swift`, `RootView+Reselect.swift` are the precedents) with the members it
  touches made `internal` and a comment saying why — Swift `private` is file-scoped.
- **A locked phone refuses `devicectl … process launch` but not the install** — read the
  `NSLocalizedFailureReason` before suspecting the build.
- **Device reinstall recipe** (only needed after a merge that touches Swift):
  `xcodebuild build -destination 'platform=iOS,id=3DBC979A-3255-5456-8C30-172DB19B99B3'
  -allowProvisioningUpdates`, then `xcrun devicectl device install app --device 3DBC979A-…
  "<Debug-iphoneos>/ADHD LifeOS.app"` and `… process launch --terminate-existing
  com.ethananthony.ADHD-LifeOS`. The `.app` path is in the build log, on the external SSD.

# Start here — the routine record is built; E reviews, then merge

*Paste into a fresh Claude Code terminal. Written 2026-09-06 at the close of the session that
designed and built BOTH blocks of the routine record on `feature/routine-record`.*

**This is the ONE live opener.** If you find a second `START-HERE-*` in `handoff/`, one of them
is a trap — see CLAUDE.md, "Session handoff". Archive this file into `handoff/archive/` in the
same move that writes your successor, at the END of your session, never at the start.

---

## Read these, in this order

1. **`CLAUDE.md`** — Repo layout, Workflow, Session handoff, Visual evidence.
2. **`claudecode.md`** — the TDD role definition.
3. **`handoff/OPEN-ITEMS-REGISTER.md`** — the outstanding list, rewritten at this close-out.
4. **`handoff/SESSION-OPENER-routine-record-design.md`** — the design record for what you are
   about to review with E, including the "Build record" section at its end.
5. `TODO-CLAUDE-CODE.md`, the two `F-RoutineRecord-*` blocks at the bottom, only when working.

**Do NOT read `docs/`.** It is an archive of a legacy build and says this app runs on Supabase.

## State gate — run before anything

```bash
git branch --show-current            # expect feature/routine-record
git status --short                   # must be empty
git log --oneline -1                 # the close-out commit; origin/feature/routine-record matches
swiftlint lint                       # expect 0 violations, 704 files
```

Baseline on the branch: unit suite **2,453 / 0** with the emulator up, lint **0 / 704**, both
targets build, `RoutineRecordJourneyUITests` PASSED on an erased simulator. The full UI target
was **not** re-run this session. E's phone carries `1ab5ff2` (= main's app source), which has
NONE of this branch.

**Before any unit suite, if a UI run has happened: `xcrun simctl erase 9181EBF9-0F54-4A4D-A19C-19945D1BF155`**
(shut it down first). This session found a second disguise of that rule: the notification TRAY
outlives a run too, and a stale routine banner from the previous run's account was tapped by
the next run's journey. Erase, don't reason about it.

## What the last session did

E picked the routine record gap (register B1), answered eleven design questions in three rounds
(record in `SESSION-OPENER-routine-record-design.md`), and both blocks shipped:

- **`F-RoutineRecord-1-Ledger`** — `routine_runs` collection, the recorder seam, six write
  sites (offer at the crossing — E's exception to Block A; started/replaced at the tap; swiped
  via a new dismiss branch; progressed/completed from the screen; left_place at the departure;
  passive endings reconciled on load), and the run-store sign-out leak fixed (register B2).
- **`F-RoutineRecord-2-Surfaces`** — Journal rows (`Started routine at …`, `Finished routine at
  … · N of M done`, unfinished read gently), the "All activity" eye switch that reveals offers
  muted, the Tools row's `last run today, 1 of 4` line, one shared reconciler, and the journey.
- **Two defects found by the journey, fixed:** a routine banner outliving a sign-out (tray now
  cleared as a session ends), and the register's tab-root "not hittable" defect — mechanism
  found (hidden tabs' UIKit subtrees stay in the accessibility tree), hidden tabs now parked
  off-screen. Whether that settles the UI target's unstable failure set is UNVERIFIED.

## What to do next — in this order

1. **E must republish `firestore.rules`.** `routine_runs` is in the generic CRUD list on the
   branch and NOT live. Until then, every record write from a device on this branch fails
   permission-denied, silently. Say this before anything is installed on the phone.
2. **Install the branch on E's phone and walk it with E** (`devicectl`, force-quit after the
   install-over-running — see memory). The device is the first real test of the SWIPE path
   (`.customDismissAction`): XCUITest cannot swipe a banner, so it is pinned by unit tests only.
   Checks worth walking: arrive → swipe the banner → Journal eye switch shows "· cleared";
   arrive → tap → finish → two rows + last-run line; sign out and back in → no stale banner.
3. **E's design review of the surfaces** against `screenshots/routine-record/` — the muted
   offer row, the eye switch, three lines per completed routine (E chose it, warned).
4. **Then `--no-ff` merge to main, re-verify ON main** (unit suite, lint, build), push, update
   the register, and re-install the phone from main.
5. **Consider re-running the full UI target once** on main after the merge: if the off-screen
   fix is what it looks like, the unstable set should shrink. Erase the sim afterwards.

**Do not start anything in the register's section C.** Parked on E's explicit instruction.

## How this project works, in four lines

- **TDD is mandatory**: the failing test first, always. Then suite green, lint 0, both targets
  build, and a red-check with the injected regressions COUNTED.
- **A block is not done until the push is VERIFIED** — same SHA on both sides, pasted.
- **Stop for E's review** when a FEATURE block completes; don't roll on to the next unprompted.
- **Nothing else can run a build here**, so paste real terminal output.

## Traps that bit THIS session, in one place

- **The emulator server log is the truth for a write that "silently" failed.**
  `firestore-debug.log` in the repo root said "no entity to update" with the exact doc id, when
  nothing in the app or xcodebuild output said anything. Read it before theorising.
- **Failure-time accessibility dumps show what XCUITest saw**, and `xcrun xcresulttool export
  attachments` gets them out; `ffmpeg -sseof -8` on the screen recording gives the last frame.
- **`element.tap()` on a not-hittable element FAILS the test** (with `continueAfterFailure =
  false`) — a fallback after the helper never runs. Check `isHittable` first.
- **A Tools-tab test-fire leaves the tab INSIDE Places.** The Routines section is on the Tools
  root; pop back before looking for it.
- **The test-fire builds a NEW handler per tap and consults no cooldown** — two places were
  needed to get an untaken offer beside a taken one.
- **`HomeRoutineCardCallSiteTests` counts the literal `leaveScreen()` in the screen source (5).**
  A comment mentioning it breaks the count.
- **`XCTUnwrap(try await …)`** does not compile — await outside, unwrap after.

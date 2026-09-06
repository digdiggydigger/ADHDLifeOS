# Start here — finish the eye-switch change, prove the swipe, then merge the routine record

*Paste into a fresh Claude Code terminal. Rewritten 2026-09-06 08:10 at the true end of the
session that designed and built both blocks of the routine record on `feature/routine-record`,
after E's device walk and a late design call that is HALF DONE. Read the "State" section
before anything else — it corrects an earlier version of this file.*

**This is the ONE live opener.** If you find a second `START-HERE-*` in `handoff/`, one of them
is a trap — see CLAUDE.md, "Session handoff". Archive this file into `handoff/archive/` in the
same move that writes your successor, at the END of your session, never at the start.

---

## Read these, in this order

1. **`CLAUDE.md`** — Repo layout, Workflow, Session handoff, Visual evidence.
2. **`claudecode.md`** — the TDD role definition.
3. **`handoff/OPEN-ITEMS-REGISTER.md`** — the outstanding list, rewritten at this close-out.
4. **`handoff/SESSION-OPENER-routine-record-design.md`** — the design record, with its "Build
   record" at the end. Note the eye-switch rule in it is SUPERSEDED (below).
5. `TODO-CLAUDE-CODE.md`, the two `F-RoutineRecord-*` blocks at the bottom, when working.
6. `screenshots/routine-record/README.md` — the journey's evidence AND E's device walk.

**Do NOT read `docs/`.** It is an archive of a legacy build and says this app runs on Supabase.

## State gate — run before anything

```bash
git branch --show-current            # expect feature/routine-record
git status --short                   # must be empty
git log --oneline -1                 # the "WIP: eye switch hides every routine row" commit
git log --oneline -1 origin/feature/routine-record   # same SHA
swiftlint lint                       # expect 0 violations, 704 files
```

**Before any unit suite, if a UI run has happened: shut down then
`xcrun simctl erase 9181EBF9-0F54-4A4D-A19C-19945D1BF155`.** The tray outlives a run too, not
just the keychain — a stale routine banner from the previous run's account was tapped by a
later run's journey. The sim was erased at this close-out.

## State — read carefully, three things changed late

**Done and verified this session:**
- **`F-RoutineRecord-1-Ledger`** and **`F-RoutineRecord-2-Surfaces`** both built, ticked,
  committed (`0022a37`, `13e8f0e`, `7430ea7`, `7bd9a6c`). Unit suite last green at
  **2,454 / 0** (emulator up), lint **0 / 704**, both targets build.
- **E republished `firestore.rules`** from their own terminal; the live ruleset was fetched
  afterwards and is byte-identical to the repo, `routine_runs` included. Nothing outstanding
  there.
- **E's phone carries `7430ea7`** (installed over `devicectl`, no provisioning trouble; the
  free-account profiles are valid to 2026-09-10). E walked it: sign-out/in left no stale
  banner; arrivals at `Home` produced the rows; the eye switch worked in light and dark. Six
  device screenshots are in `screenshots/routine-record/` (files `03-`…`08-`) with what each
  proves.

**Half done — YOUR FIRST JOB:**
- **E's call after seeing real data: the eye switch hides EVERY routine row**, started and
  finished included, not only the offers. Off (every launch) the Journal shows the crossing
  rows alone; on, the whole routine story with offers muted. This is implemented in the WIP
  commit: `JournalTimeline+RoutineRows.swift` now has `guard showAllActivity else { return [] }`,
  the tests in `JournalRoutineRowsTests` and `RoutineRecordSurfacesCallSiteTests` were changed
  FIRST and watched fail, the unit suite is 2,454 / 0 and lint 0. **What is NOT done:** the
  journey (`RoutineRecordJourneyUITests`, reordered to flip the switch before looking) has not
  passed on this tree — its 08:06 run died at the Places door (next point), before reaching the
  Journal; the design record, the TODO block and the screenshots README still describe the old
  rule; the phone does not have it; E has not seen it. Finish that list, in that order.

**A claim in the committed history is NOT confirmed — do not repeat it as fact:**
- Earlier this session the tab-root "not hittable" defect (register B4) was diagnosed from a
  failure dump — hidden tabs' UIKit subtrees still in the accessibility tree — and
  `AppTabContent` now parks hidden tabs 10,000pt off-screen (`AppTabContentLayout`). The
  journey then passed once (`13e8f0e`). **But the 08:06 run, on a build that HAS that fix,
  failed the same way:** `toolsCard.places` reported not hittable at `{{16,181.7},{370,88}}`,
  the coordinate-tap fallback did not navigate, and the failure dump still listed the hidden
  Today tab's elements. So the off-screen offset did not remove them from the tree, or the
  mechanism is only part of the story. The design record and the TODO block say "mechanism
  found, fixed" — read that as "hypothesis, fix insufficient". Next step, before more theory:
  in a failure dump, read the FRAMES of the Home elements (are they at x≈10,000 or still on
  screen?) — `xcrun xcresulttool export attachments` gets the dumps out. If they are still
  on-screen, `.offset` is not reaching the UIKit-hosted subtree either, and the fix needs a
  different lever (`UIAccessibility`-level, or not keeping hidden tabs mounted at all).
  `HitTestProbeUITests` exists for exactly this and should be used or deleted.

**Also unproved: the swipe path.** Both offered rows on E's phone read `· not opened`. A swiped
banner reads `· cleared`. E did not say whether they swiped; `.customDismissAction` has never
been exercised outside unit tests. **Ask E first thing:** did you swipe the `Home` banners away,
or leave them? If swiped, the dismiss branch is broken on device and must be debugged before the
merge (start at `RoutineDismissRecorder` and the delegate order in `ADHD_LifeOSApp.swift`).

## What to do next — in this order

1. **Ask E about the swipe** (above). Then:
2. **Finish the eye-switch change:** get `RoutineRecordJourneyUITests` green on an erased sim
   (it may need the Places-door problem worked around or fixed first — the sibling journeys hit
   it too); update `SESSION-OPENER-routine-record-design.md` (build record), the
   `F-RoutineRecord-2` block in `TODO-CLAUDE-CODE.md`, and `screenshots/routine-record/README.md`
   to the new rule; export the two new journey screenshots over `00-` and `01-`; red-check;
   commit (not WIP); push; verify SHAs.
3. **Re-install the phone** (`xcodebuild build … -destination 'platform=iOS,id=3DBC979A-3255-5456-8C30-172DB19B99B3' -allowProvisioningUpdates`,
   then `xcrun devicectl device install app --device 3DBC979A-… "<DerivedData>/Debug-iphoneos/ADHD LifeOS.app"`),
   tell E to force-quit and relaunch, and have E confirm the eye now hides everything. If the
   swipe was broken, this is also where it gets re-tested.
4. **Then `--no-ff` merge to main, re-verify ON main** (unit suite, lint, build), push, update
   the register, re-install the phone from main.
5. **Register B4 stays open.** Optionally run the full UI target once on main and record
   whether the unstable set moved; do not claim the fix worked until it does.

**Do not start anything in the register's section C.** Parked on E's explicit instruction.

## How this project works, in four lines

- **TDD is mandatory**: the failing test first, always. Then suite green, lint 0, both targets
  build, and a red-check with the injected regressions COUNTED.
- **A block is not done until the push is VERIFIED** — same SHA on both sides, pasted.
- **Stop for E's review** when a FEATURE block completes; don't roll on to the next unprompted.
- **Nothing else can run a build here**, so paste real terminal output.

## Traps that bit THIS session, in one place

- **The emulator server log is the truth for a write that "silently" failed.**
  `firestore-debug.log` in the repo root said "no entity to update" with the exact doc id when
  nothing in the app or xcodebuild output said anything. Read it before theorising. The
  emulator was left running at close (`scripts/emulators.sh`); check `curl -s -o /dev/null -w
  "%{http_code}" http://127.0.0.1:8080/` before assuming.
- **Failure-time accessibility dumps show what XCUITest saw**: `xcrun xcresulttool export
  attachments --path <bundle> --output-path <dir>`, then read `manifest.json`; the screen
  recording is an `.mp4` and `ffmpeg -sseof -8 -i <mp4> -frames:v 1 out.jpg` gives the last frame.
- **`element.tap()` on a not-hittable element FAILS the test** with `continueAfterFailure =
  false` — a fallback after the helper never runs. Check `isHittable` first. And a coordinate
  tap on that card did NOT navigate either, so the fallback is not a fix.
- **A Tools-tab test-fire leaves the tab INSIDE Places.** The Routines section is on the Tools
  root; pop back (`app.navigationBars.buttons.firstMatch`) before looking for it.
- **The test-fire builds a NEW handler per tap and consults no cooldown** — two places are
  needed to get an untaken offer beside a taken one; a second fire at the same place REPLACES the
  banner and the earlier offer times out as `not opened`.
- **`HomeRoutineCardCallSiteTests` counts the literal `leaveScreen()` in the screen source (5).**
  A comment mentioning it breaks the count.
- **`XCTUnwrap(try await …)`** does not compile — await outside, unwrap after.
- **A UI-test launch on a freshly erased sim takes 60–100 s** before the tabs exist; the
  journey's total is ~4–5 min. Budget for it.

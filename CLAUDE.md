# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

**Feature-complete native port, on Firebase, running on E's physical iPhone.** The React prototype
(`legacy/src/`, reference-only — see `legacy/README.md`) was fully ported to SwiftUI by 2026-08-19:
Home (Active Goal hero, life-area grid + reorder, daily summary, focus analytics), Tasks (swipeable
cards, search/sort, detail with focus-sprint planner), Capture inbox triage, Journal, Nudges,
Settings (incl. account deletion), auth (email/password live; Sign in with Apple built but dormant —
free dev account), the app-wide focus timer, and a design-token layer mirroring the prototype
palette.

**Much has shipped since that line was first written, and it is not a prototype port any more.**
Merged arcs, newest first: the **Routines** arc (location-triggered routines — one notification per
crossing rather than N, an ordered routine screen, a Today recovery card, a display Live Activity;
then Block A's deferred logging, where a crossing writes NOTHING until its notification is tapped;
then Block B, the Routines section on Tools); the **Tools tab** and the app's own six-item tab bar,
replacing `TabView`'s bar entirely; **bottom search** on Tasks; the **app directory**; **place
actions**; **location services** (places, geofences, arrival/departure nudges); the **Momentum v3**
redesign; the **captures** rethink; **auth v3**. Direct instructions from E are the work queue — see
"Workflow" below; there is no second tool writing blocks.

## Repo layout — what is live and what is not

The repo was **cloned** from an earlier project built with a Cowork→Claude Code workflow, and for
three weeks it carried that project's web app at its root. Sorted 2026-09-06:

| path | status |
|---|---|
| `ADHD LifeOS/`, `ADHD LifeOSTests/`, `ADHD LifeOSUITests/`, `FocusTimerWidget/` | **The app.** |
| `functions/`, `shortcuts/`, `scripts/` | **Live.** Firebase functions (self-contained, own `package.json`), the capture Shortcut, the emulator harness. |
| `handoff/` | **Live.** Session openers, design records, and `OPEN-ITEMS-REGISTER.md` — the outstanding list. See "Session handoff". |
| `screenshots/` | **Live.** Visual evidence. See "Visual evidence". |
| `docs/` | **ARCHIVE.** A legacy build's Supabase/AWS design docs. Never read for context. |
| `legacy/` | **ARCHIVE.** The React prototype and its web build tooling. Nothing here is built or run. |
| `TODO-ARCHIVE.md` | **ARCHIVE.** 8,000 lines of shipped and superseded blocks — the record of WHY. |

**`TODO-CLAUDE-CODE.md` was split on 2026-08-23 (E's direction).** It is now ~140 lines holding only
what is genuinely open; the other 8,000+ lines — every shipped block, plus everything written
against the deleted Supabase / Cognito-AWS / Poke backends — moved verbatim to `TODO-ARCHIVE.md`.
**Nothing in the archive is a work item**, but it is the record of *why* much of this app is shaped
the way it is, so read it before assuming a decision was arbitrary. Note this crosses the usual
ownership line as it stood then (Cowork wrote that file, Claude Code only ticked checkboxes; that
split has since ended — see "Workflow" below) — E authorised it
explicitly.

## Workflow: Claude Code only (E's call, 2026-09-06)

**Cowork has no part in this project. E works purely from the Claude Code terminal**, and has done
for some time — this section described a two-tool split with strict ownership boundaries that no
longer exists, so every boundary it enforced is now fiction. **Claude Code owns every file here**:
Swift, tests, `TODO-CLAUDE-CODE.md` in full (blocks as well as checkboxes), `CLAUDE.md`, `handoff/`
and `screenshots/`.

**E is the design authority, in chat.** Direct instructions from E ARE the work queue — there is no
second tool writing FEATURE blocks to wait for. The old rule "stop and wait for user review once a
block is complete" stands and is unchanged: it is E's review, not Cowork's, and it was always the
valuable half.

**Two artefacts of the old split remain, and neither is a bug:**
- The **`⚠ CLAUDE CODE ADDITIONS`** section in `TODO-CLAUDE-CODE.md` was fenced off because writing
  blocks used to cross an ownership line E had to authorise. That line is gone; the section is kept
  because it is where the recent arcs' history lives, not because the fence still means anything.
- **`claudecode.md`** is the TDD role definition. It was REWRITTEN on 2026-09-06, not left as
  inherited: its rule 1 used to send every session to read `docs/` as step one of the checklist,
  which pointed at an archive describing the deleted Supabase backend. It no longer says
  "never edit" — that instruction belonged to the Cowork split.

**`docs/` IS AN ARCHIVE — do not read it for context.** E's 2026-09-06 call ("the seven files in
docs/ are from a legacy build"): all seven moved to `docs/archive/` behind a `docs/README.md` that
says so. They were last edited 2026-08-17 and describe the deleted Supabase and AWS backends —
Supabase 70 mentions, AWS 105, Cognito 64, and **Firebase and Firestore zero**. `ARCHITECTURE.md`
opens by calling the app "a second client on the Es_Life_OS Supabase backend". **The architecture
that is true lives in this file's own "Architecture notes" section**, which is maintained. Keep the
archive for the same reason `TODO-ARCHIVE.md` exists: it is the record of WHY, never of how.

**Start of session checklist:**
1. Read `claudecode.md` for the TDD role definition.
2. Read this file's "Architecture notes" — NOT `docs/`.
3. Read `handoff/OPEN-ITEMS-REGISTER.md`, which is the outstanding list, and the single live
   `handoff/START-HERE-*.md` if one exists.
4. Read `TODO-CLAUDE-CODE.md` for the block you are on.
5. Implement test-first, then mark the item `[x] COMPLETED` when done.
6. If blocked, add a `[BLOCKED]` comment inline in `TODO-CLAUDE-CODE.md` explaining what is
   unclear, and stop — don't guess at unspecified acceptance criteria.

Once a FEATURE block is completed, stop and wait for E's review rather than proceeding to the next
item unprompted — unless E says to bypass.

## Commands

```bash
brew install swiftlint   # one-time manual setup — E runs this, not Claude Code
xcodebuild -resolvePackageDependencies -project "ADHD LifeOS.xcodeproj"

swiftlint lint            # lint check, no errors allowed

xcodebuild test -project "ADHD LifeOS.xcodeproj" -scheme "ADHD LifeOS" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -skip-testing:"ADHD LifeOSUITests" \
  -enableCodeCoverage YES -resultBundlePath TestResults.xcresult
xcrun xccov view --report TestResults.xcresult   # coverage report
```

UI tests are skipped in the standard run — they are credential-free and compile on a fresh clone,
but need a booted simulator and live network; run them deliberately, not per-block.

```bash

xcodebuild build -project "ADHD LifeOS.xcodeproj" -scheme "ADHD LifeOS" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

**Test destination note (2026-07-30):** this machine has only the iPhone 17 family on iOS 26.5
installed — there is no iPhone 15 Pro simulator, so the previously documented destination was not
runnable. If `xcodebuild` reports the destination is unavailable, run
`xcrun simctl list devices available` and use an installed device rather than guessing.

### Xcode's MCP bridge (E installed it 2026-09-11)

Xcode 26.6 ships an MCP server, `xcrun mcpbridge`, registered in this project as the `xcode`
server. **Open Xcode on the project BEFORE starting the Claude Code session.** The session fetches
the tool list once at startup; if Xcode is not running then, the fetch times out and the server
is absent for the whole session — `ToolSearch` finds nothing and the only recovery is a stdio
JSON-RPC helper that spawns the bridge itself (this cost the 2026-09-11 session the tools).

Twenty-one tools. `XcodeListWindows` first — everything else needs its `tabIdentifier`
(`windowtab1` with one window). The file tools (`XcodeLS/Read/Glob/Grep/Write/Update/MV/RM`)
take **project-navigator paths, not filesystem paths**: root is `/`, the project node is
`ADHD LifeOS`, the app group is `ADHD LifeOS/ADHD LifeOS`. Also `XcodeRefreshCodeIssuesInFile`,
`XcodeListNavigatorIssues`, `BuildProject` + `GetBuildLog`, `GetTestList`, `RunAllTests`,
`RunSomeTests` (target name + XCTest identifier), `RunCodeSnippet`, `DocumentationSearch`, and
**`RenderPreview`**, which builds and snapshots any `#Preview` in a file by index.

**Where it sits against the bar above — and it does not move the bar.** `RenderPreview` is a
sanctioned way to produce STILL evidence for `screenshots/` (every view already has Light/Dark
previews); animation FRAMES still need the run-loop-pumping render probe. `RunSomeTests` shortens
a red-check loop. Neither replaces pasted `xcodebuild` output: a block is done on the terminal
output E reads, never on a bridge green. Treat a bridge result as a hint to confirm, and say which
it was in the report.

**A UI-TARGET RUN POISONS THE SIMULATOR. Erase it in the same breath, before any unit run.**
A UI journey signs the simulator in; the next unit suite then drags a Firebase client retrying
against an emulator that is no longer up, and every test takes **60-80 seconds instead of
milliseconds**. It has two disguises: the run looks merely slow, or the harness KILLS it reporting
**"the system is running low on memory"** — the retry churn, not compilation, is what exhausts the
8 GB machine (`grep -c '^Compiling'` returns 0). The tell is `127.0.0.1:9099` in the log tail.

```bash
xcrun simctl erase <udid>   # not `shutdown`, not a reboot — ERASE
```

This cost time TWICE on 2026-09-06, the second time four hours after being diagnosed and written
down. Knowing the cause did not prevent it. **Order the commands so the erase follows the UI run
unconditionally**, rather than checking whether the next suite seems slow.

A feature isn't done until `swiftlint lint`, the full test suite, and the build all pass — and the
real terminal output has been pasted for review, not just a "done" summary. **If the block was
settled by LOOKING at it rather than by an assertion, its `screenshots/` folder and that folder's
README are part of the same bar** — see "Visual evidence" below.

**Coverage reality (2026-09-07, re-measured):** the app target is **24.72% (11,114/44,961)** over
**2,497 unit tests**, measured with the documented command at `93beff2`, emulator UP. (It was
24.68% (11,095/44,961) over 2,488 tests at `9f6381e`, before F-WidgetCoverage closed the widget
target's testable surface below; and 24.58% (11,050/44,961) over 2,469 tests at `f0b7c5c`, before
F-AdapterDrift closed the four adapters below. All three are the same day.)

**These figures ARE comparable to the 23.62% (8,673/36,721) recorded on 2026-08-30 — and the note
that stood here would have told you they are not. Read why: the rule needed sharpening, not
repeating.** A moved denominator is not itself disqualifying. What decides it is WHY it moved:

- **2026-08-23 → 2026-08-30 (20,794 → 36,721): NOT comparable.** The denominator moved because the
  *measurement extent* changed — the old 20,794 was only ~57% of the tree, so that run measured a
  subset of what it claimed to. Two different fractions of two different wholes.
- **2026-08-30 → 2026-09-07 (36,721 → 44,961): comparable.** The denominator moved because the
  *tree grew* — 310 → 380 Swift files, 36,742 → 46,978 raw lines. Both runs measured 100% of the
  app target (44,961 executable against 44,871 raw app-target lines is the same ~1:1 the previous
  measurement had), so both percentages mean the same thing and the difference between them is
  real.

- **`f0b7c5c` → `9f6381e` → `93beff2` (44,961 throughout): trivially comparable.** F-AdapterDrift
  and F-WidgetCoverage both added only TESTS, so the denominator did not move at all and the whole
  delta is numerator — 11,050 → 11,095 (the +45 lines the four adapters were missing) → 11,114
  (the +19 the widget's five shared files were missing; those files are members of the app target
  too, so widget work moves this figure as well). This is the easy case, and it is worth keeping
  in view as the contrast that makes the other two legible.

The honest reading of the first pair is that coverage grew slightly FASTER than the code: the
numerator went **8,673 → 11,050 (+27.4%)** against a denominator that grew **+22.4%**.

**The standing rule, corrected: re-measure, never estimate — and when the denominator has moved,
establish WHY before you either compare the ratios or refuse to.** "Different denominators" is the
start of that question, not the answer to it.

Full target breakdown at `93beff2`:

```
ADHD LifeOS.app              24.72%  (11114/44961)
ADHD LifeOSTests.xctest      96.02%  (39057/40678)
ADHD LifeOSUITests.xctest     0.00%  (0/2751)     ← skipped in the standard run by design
FocusTimerWidgetExtension    10.29%  (228/2216)
```

**The widget extension's percentage is the most misleading number in this file, and the note that
stood here read it wrong.** It said the target "went BACKWARDS" — 193/1,759 → 209/2,216, the ratio
falling 10.97% → 9.43% — and concluded "widget code shipped faster than its tests". The arithmetic
was right and the diagnosis was wrong. **Only FIVE of the fourteen widget files are compiled into
the app target**, via the `membershipExceptions` list in `project.pbxproj`:

```
FocusActivityAttributes.swift   FocusSprintIntents.swift   RoutineActivityAttributes.swift
FocusWidgetSnapshot.swift       LifeAreasWidgetSnapshot.swift
```

Those five are **exactly** the five that have ever had non-zero coverage, and the match is not a
coincidence: the unit-test target hosts the APP, so it compiles and runs those five and never
compiles the other nine at all. **The widget target's testable surface is 233 lines, not 2,216.**
The remaining 1,983 are widget-only view bodies — `FocusTimerWidgetLiveActivity` (0/518),
`FocusStatsWidget` (0/472), `RoutineLiveActivity` (0/436), `FocusActivityComponents` (0/164),
`FocusSprintWidgetSection` (0/133), `LifeAreasWidget` (0/127), `QuickCaptureWidget` (0/105),
`FocusStatsTimeline` (0/17), `FocusTimerWidgetBundle` (0/11) — structurally out of a unit test's
reach, the same fact this section already records for the app target's own view bodies.

So the fall was DENOMINATOR, not decay: `RoutineLiveActivity` (436) and `RoutineActivityAttributes`
(10) arrived with the routines arc on **2026-09-03** (`534265e`), ~446 of the 457 new executable
lines. Read the testable surface instead and the trend inverts — it was **209/233 (89.7%)**, and
F-WidgetCoverage took it to **228/233 (97.9%)**.

**The five lines still uncovered are `endAllActivities`' loop body** (`FocusSprintIntents.swift`
32–36): ending a real `Activity` needs an entitled process, the same exclusion
`FocusActivityContentStateTests` records for the mirror's own ActivityKit calls. They are the
honest floor, not a backlog.

**The lesson generalises past the widget: a percentage over a denominator that includes code the
test target never compiles is not a coverage figure, it is two numbers divided.** Before reading
any target's ratio as effort, check what the test host actually links — `--files-for-target` on
both targets, and the file lists' intersection is the surface that can move.

**The Firebase adapter seam DECAYED and was closed again the same day (F-AdapterDrift,
2026-09-07).** The claim that stood here — "all ... covered (92–100% each)" — had gone false: four
adapters had fallen below the bar, and all four arrived with arcs that shipped after 2026-08-30.
**All four are now at 100%**, and every one of them was reachable in production the whole time —
none was dead code, so these were live, shipped, unexercised paths:

```
FirebaseAppDirectoryClientAdapter    0.00% (0/6)     → 100.00% (6/6)
FirebasePlacesClientAdapter         41.67% (5/12)    → 100.00% (12/12)
FirebaseJournalClientAdapter        71.57% (73/102)  → 100.00% (102/102)
FirebaseHomeClientAdapter           80.00% (12/15)   → 100.00% (15/15)
```

There are **fourteen** `Firebase*ClientAdapter` files (not thirteen), plus
`FirebaseAccountDeletionAdapter` and `FirebaseFocusSessionAdapter` as their own files, and
`FirebaseDailySummaryDataAdapter` declared *inside* `DailySummaryDataBackingStore.swift` — so it
has no file row of its own in the report at all. `grep "private let manager: FirebaseManager"`
returning NOTHING remains the check that the architectural seam is intact; it never broke here,
and what had lapsed was test REACH, not design.

**Two lessons worth more than the percentages, because both will recur:**
- **A fake with no error hook makes a `catch` branch untestable, and the coverage report blames
  the adapter.** `FakeJournalBackingStore` had no error property for its three side streams, so
  those catch branches *could not* be reached by any test — they read as adapter drift but the
  gap was in the double. Check the fake before concluding the adapter is under-tested.
- **The last unit in a file is often a partial REGION, not a whole line.** Journal sat at 99.02%
  with zero fully-uncovered lines; the missing piece was the `?? error.localizedDescription`
  branch of `message(for:)`, invisible to a line-level sweep. Use
  `xcrun xccov view --archive --file <path> <bundle>` — note `--archive`, without which it
  reports "unrecognized file format" — and read the `(col, x, 0)` region rows, not just the
  zero-hit lines.

The four extensions the emulator harness covers (of the **sixteen** that exist) are UNCHANGED at
2026-09-07: `+Tags` **97.67%**, `+Seed` **98.31%**, `+Storage` 95.83%, `+AccountDeletion` 90.20%
— identical to the 2026-08-30 figures, which is the emulator harness holding its ground.

What is still uncovered, and why the 70% bar stays out of reach:
- **SwiftUI view bodies — the real figure is ~15,000 lines, not the ~7,000 recorded here until
  2026-09-07.** The 37 files whose names contain `View` hold **14,993 executable lines at 3.21%**.
  Zoom out and **108 of the app target's 342 measured files sit at exactly 0%, together 29,513
  lines — 66% of the entire denominator.** The largest are `NudgesView` (0/884),
  `HomeAccessoryStrips` (0/752), `LogComposerView` (0/718), `TaskListView` (0/711) and
  `QuickCaptureComponents` (0/677). Unit tests are the wrong tool for these; this is UI-test
  territory, and the UI tests are deliberately skipped in the standard run.

## Firebase emulator (integration tests for `FirebaseManager`'s own extensions)

`FirebaseManager+Seed`, `+Tags`, `+AccountDeletion` and `+Storage` make real Firestore/Auth/Storage
calls, so they are tested against the **Emulator Suite** rather than a fake:

```bash
./scripts/emulators.sh    # leave running in a second terminal
```

Then run the suite as normal. **With the emulator down these tests SKIP, never fail** — the standard
run stays green on a machine that has never started it.

- **firebase-tools 15.x needs Java 21+**, not the "Java 11+" earlier notes claimed. Homebrew keeps
  JDKs keg-only, so `java -version` reporting 1.8 tells you nothing about what is installed;
  `scripts/emulators.sh` sets `JAVA_HOME` to `/opt/homebrew/opt/openjdk@21` itself. Do **not**
  `brew link openjdk@21` — that changes the machine's default Java for everything else.
- The emulator loads `firestore.rules` and `storage.rules`, so these tests exercise the **real
  security rules**. A rules regression fails them — which is the cheapest rules check available,
  given publishing is manual and E-only.
- **Safety, and it is the reason the harness is shaped the way it is.** `deleteAllUserData()`
  erases every document its signed-in user owns; aimed at the live project by accident it would do
  that to E's real account. So: `FirebaseEmulatorSettings` turns emulator mode on ONLY for an
  explicit, well-formed `LIFEOS_FIREBASE_EMULATOR_HOST` and resolves anything malformed to *off*
  rather than falling back to a default; the shared scheme sets that variable on the **Test action
  only** (`shouldUseLaunchSchemeArgsEnv = "NO"`, so running the app is unaffected); and
  `FirebaseEmulatorHarness.requireEmulator()` **fails loudly** if the emulator is reachable but the
  app is not pointed at it — the one state where tests could otherwise touch production.
- **Trap:** Firestore's `useEmulator(withHost:port:)` sets only the *host* — read `FIRFirestore.mm`,
  it does not disable TLS. The client then speaks TLS to a plaintext emulator and retries forever
  with `WRONG_VERSION_NUMBER`, which reads like a broken install rather than a client bug. So
  `FirebaseManager+Emulator` sets `host`, `isSSLEnabled = false` and `MemoryCacheSettings()`
  explicitly. Auth and Storage's same-named methods DO handle their own transport.

The operative rule is unchanged: every piece of NEW pure logic ships with tests written first (TDD
below), and no block may claim the 70% bar is met.

## Session handoff (`handoff/`)

**E's 2026-09-06 call, prompted by a live trap: `START-HERE-routines-blockB.md` still instructed a
fresh session to BUILD a block that had already shipped and merged that morning.** Eleven more
spent pointers were sitting beside it. The folder also lived outside git, so nothing in it was
versioned and a mistaken delete was permanent — it is now `handoff/` in this repo.

**Three species live here, and the file NAMES do not distinguish them. This is the trap:**

| species | what it is | lifetime |
|---|---|---|
| `START-HERE-*`, `PASTE-*` | Disposable pointers — "paste this into a fresh terminal". | **Spent on use.** Archive them. |
| `SESSION-OPENER-*` | **Design RECORDS**, despite the name — the why behind settled decisions. | **Permanent. Never archive.** |
| `ON-DEVICE-CHECKLIST-*`, `VISION-*` | Evidence and direction. | **Permanent.** |

`SESSION-OPENER-routines-design.md` opens with "This is the design record and the why". A rule that
archived everything named "opener" would bury exactly what this file tells you to read before
assuming a decision was arbitrary.

**The archive rule: exactly ONE live opener at a time.** When a session is asked to write the
handoff for the next one, it **archives the `START-HERE-*`/`PASTE-*` pair it consumed in the same
move that writes the successor** — `git mv` into `handoff/archive/`. At the END, with the successor,
never at the start: a session that dies mid-way must leave its opener live and still usable, and the
next session must never start blind. If `handoff/` ever holds two live `START-HERE-*` files, one of
them is a trap; find out which and archive it.

**`OPEN-ITEMS-REGISTER.md` IS the outstanding list.** Rewrite it at every close-out — current SHA,
suite/lint/UI figures, what shipped, what is outstanding, what is parked, what is known-noise. Do
NOT improvise that list in chat: the register went unmaintained for six days while two ad-hoc lists
were produced in conversation, which is how it fell six days out of date in the first place. When E
asks what is outstanding, update the register and answer from it, so the answer has history rather
than being re-derived each time.

## Visual evidence (`screenshots/`)

**E's 2026-09-05 call, after finding this was a practice nobody had written down.** It had been
followed 137 files deep and was quietly decaying: the six folders in the retired
`Verification Screenshots/` all documented themselves, while only four of the sixteen in
`screenshots/` did. Both trees are now merged under **`screenshots/`** — one home, lowercase and
space-free so no command has to quote it.

**What earns a folder: only what a test cannot assert.** Colour, spacing, a live rule being applied
to real data, device-only behaviour, or a decision E settled by looking. If a unit or UI test could
have proved it, write the test instead — a screenshot of something a test already covers is weight
without evidence. Every one of the 22 existing folders passes that filter; keep it that way.

**The README is mandatory, and it is the whole point.** A folder of undated images is not evidence,
because the thing a later session needs is not the picture but the CLAIM the picture settled.
`screenshots/tag-editor-ui/README.md` is the standard to copy, and it is better than most of what
followed it:

- the environment in one line — device or simulator, OS, backend, signed-in account, date;
- what driving the real screens caught that the tests could not (the reason the folder exists);
- any throwaway data created, and the proof it was cleaned up;
- a table, one row per file: **filename → what it proves.** Numeric prefixes so file order is
  screen order (`00-`, `01-`, …).

**Twelve folders predate this rule and have no README. That is deliberate, not a backlog** — E's
call, 2026-09-05: the standard applies from here, and reconstructing what a months-old screenshot
was meant to prove would be guessing dressed as a record. Leave them. `native-port-first-screens/`
is the one exception, and its README says in its first line that its provenance is reconstructed.

**Keep everything, forever.** These folders answer "why does it look like this?" months later, which
is exactly when nobody can reconstruct it. Nothing here is pruned when a block merges.

**Prefer JPEG.** A device screenshot is ~230KB as JPEG; a simulator PNG is several MB, and the tree
is already 44MB. Use PNG only when the point is pixel-exact — a colour comparison, a contrast
measurement, anything that will be sampled rather than looked at.

## Version Control

Repo: https://github.com/digdiggydigger/ADHDLifeOS (private, branch `main`).

**`main` is PROTECTED since 2026-09-06 (E's call, made mid-session and confirmed in chat):
GitHub rejects direct pushes (`GH006: Changes must be made through a pull request`). Every
change lands through a PR now.** The four direct-push bullets that used to sit here described
the pre-protection flow; their spirit — no work ever lost, nothing unverified — is unchanged.

To guarantee no work is ever lost:
- Work on a short-lived branch (`feature/<arc>` for blocks, `chore/<thing>` for the rest).
  Commit at the same moments as before: every completed FEATURE block the moment it is marked
  `[x] COMPLETED`, before waiting for review.
- Push the BRANCH immediately after each commit — don't batch.
- Land via `gh pr create` then `gh pr merge --merge --delete-branch`. If the merge is refused
  (a review requirement, a failed check), hand E the PR link and stop — never force.
- Never end a session with uncommitted or unpushed changes. Mid-feature, commit what exists
  with a `WIP:` prefix to the branch and push the branch.
- Commit message format: `<FEATURE-ID>: <short description>` (e.g. `F2-AuthPersistence: add token refresh on launch`).

### Landing is Claude Code's job, and it is not done until it is VERIFIED (E's standing rule, 2026-07-30; PR flow since 2026-09-06)

**Claude Code owns git for this repo. Every block ends with a real, landed commit AND a real,
landed merge to `main` — performed by Claude Code, in the same session, without being asked.**
Never hand E a git command to run. Never report "landed" from the fact that you typed the command.

**Mandatory close-out, run at the end of every block before you write your report:**

```
git checkout main && git pull --ff-only
git status --short          # must be empty
git log --oneline -1        # local main
git log --oneline -1 origin/main   # must be the SAME SHA, and contain the work
```

Paste that real output in the report. **If the work is not reachable from `origin/main`, it has
not landed and the block is NOT done** — fix it, don't report it (a PR left open awaiting E is
the one sanctioned exception, and the report must say so). This rule exists because a "Pushed"
has silently failed to land in this project more than once, and because a commit command was once
handed to E as text and never verified.

**Stale git lock files.** A push that dies part-way can leave `.git/HEAD.lock` / `.git/index.lock`
behind. **If any git command fails with `Unable to create '.git/index.lock'` or similar, clear them
first** — `rm -f .git/HEAD.lock .git/index.lock` — then re-run. Still check on session start whether
local is ahead of `origin/main` and push it as your first action if so; the cause used to be
Cowork's credential-less sandbox committing without pushing, and is now simply a session that ended
before its push landed.

## Architecture notes

- SwiftUI, Swift. **The deployment target is not one number:** the app target is
  `IPHONEOS_DEPLOYMENT_TARGET = 16.0`, the **FocusTimerWidget extension is 16.1** (Live Activities
  need 16.1). An API above either floor ships behind `#available` with a complete floor branch
  beside it: **§7.1 is the rule, §7.2 the Reduce Motion half, §7.3 what can and cannot be verified
  on this machine.** Widget code gates against the higher floor. Targets verified 2026-08-30 in
  `project.pbxproj`.
- **Backend: Firebase** (Auth + Firestore + Storage, project `adhdlifeos-acb49`;
  `GoogleService-Info.plist` is committed — private repo, client identifiers only). The Supabase
  and AWS layers this doc previously described were deleted at E's direction in commit `5244650`
  ("cut all services over to Firebase"). No local persistence layer — Firestore is the source of
  truth. Everything goes through per-feature `Firebase*ClientAdapter` structs over the shared
  `FirebaseManager`. **Those adapters live beside the feature they serve — `Auth/`, `Capture/`,
  `Home/`, `Journal/`, `Nudges/`, `Tasks/` and so on — NOT in `ADHD LifeOS/Firebase/`**, and there
  are **fourteen** of them (re-counted 2026-09-07 with the coverage sweep; was thirteen on
  2026-08-30, and an earlier "twelve, in `ADHD LifeOS/Firebase/`" was wrong on both count and
  location).
  `ADHD LifeOS/Firebase/` holds the manager, its **sixteen** `FirebaseManager+<Domain>` files
  (re-counted 2026-09-07 — `+AppDirectory` and `+RoutineRuns` joined after the "fourteen" here was
  written), and the codec/mapping types. `FirebaseManager.swift` itself holds only the class, auth,
  and the Firestore plumbing every extension builds on; per-collection storage lives in
  `FirebaseManager+<Domain>.swift` alongside `+Seed`/`+Storage`/`+AccountDeletion`/`+Emulator`.
  Add a new collection's methods to its own such file, not to the core one.
- **Adapters depend on a per-feature `*BackingStore` protocol, never on `FirebaseManager` directly**
  (E's 2026-08-23 call). `FirebaseManager` is a `final class` with a `private init` and a `shared`
  singleton, so an adapter holding it concretely cannot be tested at any price. Each adapter gets
  its own narrow protocol — never one protocol over the manager's ~40 methods — which `FirebaseManager`
  satisfies via a one-line extension, with a recording fake in tests. When a store needs a partial
  write, add a *named* wrapper on the manager (`updateLifeArea(id:fields:)`) rather than exposing the
  generic `update(id:fields:in:)`, so a store cannot address another collection.
- **Hand-written Firestore field dictionaries live in `FirestoreFieldPayloads`, never inline.** They
  are not derived from `Codable`, so no round-trip test reaches them, and a wrong key raises nothing
  — it writes a field nothing reads. Two conventions coexist and disagree on purpose: **tasks are
  fully snake_cased (`life_area_id`), captures are camelCase apart from `created_at` (`lifeAreaId`)**.
  Tests assert the wrong spelling is *absent* as well as the right one being present.
- Firebase SDK error mapping goes through `FirestoreErrorMapping` / `AuthErrorMapping`, which expose
  the SDK's domain and code so tests can build a genuine error. **The unit-test target deliberately
  does not link the Firebase SDK** — these are static products, and linking one into both the app and
  its hosted test bundle realises every Objective-C class twice. `FirestoreDocumentCoder` is the
  codec seam for the same reason.
- Schema: **eleven** per-user subcollections under `users/{uid}` — tasks, life_areas, tags, logs,
  captures, nudges, reminders, focus_sessions, places, location_events, **routine_runs**. Document
  IDs are UPPERCASE `uuidString`. `firestore.rules` is the authoritative enumeration, and note
  `logs` and `location_events` each have their OWN match block (append-only, update denied) while
  the other **nine** sit in the generic `collection in [...]` allow — `routine_runs` belongs there
  deliberately, because a run moves offered → started → ended in place and so must be updatable.
  This list was corrected twice: `places`/`location_events` were missing until 2026-08-30, and
  `routine_runs` (shipped 2026-09-06) until the 2026-09-07 coverage sweep. **There is also one
  path that is NOT per-user — `catalog/{docId}`, the app-directory catalogue: read-only to any
  signed-in user, writable by no client at all.**
- Security rules live in-repo (`firestore.rules`, `storage.rules`). **Publishing stays E's call**
  — a rules change is not live until E republishes, so say so in the block report. But
  **verifying is no longer manual: the Firebase CLI IS authenticated** (`firebase login:list` →
  `reckedgelato@gmail.com`, project `adhdlifeos-acb49`), and the Firebase MCP's
  `firebase_get_security_rules` returns the LIVE ruleset for `firestore` / `storage`. The old
  claim here that "Claude Code has no Firebase CLI auth" was wrong and left `storage.rules`
  recorded as unconfirmed for months. **Diff live against the repo rather than asking E to paste
  the console tab.** Re-verified **2026-08-30**: `firestore.rules` is byte-identical live
  (including `location_events` and `places`); `storage.rules` is semantically identical but the
  live copy carries no comment header, i.e. it was published from a pre-comment revision. Nothing
  is outstanding to republish.
- Manual-step convention (same as web project): anything requiring the Xcode GUI beyond CLI builds — code signing, provisioning profiles, App Store Connect/TestFlight — is E's job, never attempted by Claude Code directly.
- Lint: SwiftLint, config at `.swiftlint.yml` (default ruleset unless a rule is explicitly flagged as too noisy and adjusted).
- Tests live in `ADHD LifeOSTests/` (XCTest), UI tests in `ADHD LifeOSUITests/`.
- TDD is mandatory: write the failing test before the implementation for every feature, per `claudecode.md`.
- No placeholder/TODO-comment code — implementations must be complete and production-ready when a feature is marked `[x] COMPLETED`.
- **Nothing else can run a build, test or lint for this project** — E reads pasted terminal output rather than re-running it, so an unpasted "it passes" is an unverified claim. This was originally about Cowork's macOS-less sandbox; with Cowork gone it is simply E's standing rule.

## UI/UX & Apple HIG Architecture (ADHD-Focused)

Implement layouts as an elite Apple Design Engineer. Every view must look handcrafted, premium, fluid, and highly accessible according to Apple's Human Interface Guidelines (HIG). Minimize cognitive overhead, prevent visual distraction, and maximize micro-interaction feedback. Do not write generic AI layouts or raw opacity soup.

### 1. Typography, Visual Hierarchy & Readability
- **Sizing Contrast**: Anchor views with strong, distinct hierarchy. Use heavy semantic headers (`.font(.largeTitle).bold()`) contrasted sharply against functional labels (`.font(.footnote).foregroundStyle(.secondary)`).
- **Premium Kerning**: Apply custom tracking to large titles to achieve a high-end native look: `.tracking(-0.5)`.
- **Layout Safety**: Text elements must never clip or truncate unexpectedly on smaller layouts. Use dynamic sizing elements such as `.minimumScaleFactor(0.8)` or explicitly configure `.layoutPriority(1)`.

### 2. Spacing Grid (Strict Base-4/Base-8 Tokens)
- **Zero Raw Margins**: Do not inject unmapped integers like `.padding(13)` or `Spacer(minLength: 22)`.
- **Layout Tokens**:
  - `4pt`: Micro positioning, inside asset-to-text gaps.
  - `8pt`: Inter-element bounding spacing within a component wrapper.
  - `16pt`: Outer screen container margins and canvas boundaries.
  - `24pt`: Macro group-to-group layout separation.
- **The ONE sanctioned off-grid value, and it is a waiver rather than a loophole:**
  **`FocusCompletionStackLayout.peekStep = 14`** (E's call, 2026-09-10). The completion stack's
  peek shipped at the on-grid 8 and proved too quiet in LIGHT mode on E's device — the visible
  sliver measured **1.03:1** against the page, so the card behind was carried entirely by its
  keyline. E was shown six rendered options, **offered the on-grid 16 explicitly, and chose 14**:
  the value they had actually approved by sight. `testThePeekStepIsTheValueEChoseByLooking` pins
  it and says why. **Do not "correct" it to a grid value** — that silently undoes a decision made
  by looking. This waiver covers that one constant and nothing else; every other spacing value in
  the app stays on 4/8/16/24, and `12` and `20` remain banned (§7.5).
- **Structural Wrappers**: Use native `ScrollView` systems nested with `LazyVStack` or `LazyHStack` along with custom pinned segment controls over stock, standard `List` containers unless outputting basic Settings structures.

### 3. Hit Targets & Input Interaction
- **Physical Bounds**: Ensure all touch interactions, custom buttons, and action cells maintain a minimum touch targets metric of `44x44pt`. Bind custom view hierarchies with `.contentShape(Rectangle())` to make entire container zones tap-responsive.
- **Physical Sensory Feedback**: Deliver instant behavioral confirmation to reassure ADHD focus paths. Attach native tactile triggers to view interactions via the house helper, `.haptic(.solid, trigger: bindingState)` (`Theme/Haptics.swift`): it is `.sensoryFeedback` on iOS 17+ and the UIKit performer on 16, i.e. §7.1's two-branch pattern. Do not call `.sensoryFeedback` directly.
- **Button Visual States**: Write explicit custom primitive `ButtonStyle` structures to scale interactive objects (e.g., scale down slightly to `0.97` upon active press). Raw opacity filters are prohibited.

### 4. Semantic Color Assets & Accessibility
- **Zero Hex Declarations**: Never inject hardcoded color strings or static RGB code paths **in
  Swift**. The one sanctioned home for hex is the asset catalog's colorsets (E's 2026-08-19
  design-token direction): the prototype palette lives there with light+dark variants, and views
  consume it via the generated symbols / `Theme.swift` helpers (`.bentoCard()`, `UrgencyPalette`,
  `sectionLabel()`, `Color.cardSurface`/`.pageBackground`/`.cardBorder`).
  **`AccentColor` is iOS system BLUE — `#0A7CFF` light, `#0A84FF` dark — not coral.** This file
  claimed "coral `AccentColor`" until 2026-08-30; there is no coral colorset in the catalog and
  never has been, so the FAB, the selected tab and every `.accentColor` tint are blue and are
  behaving correctly. Read the asset before describing the palette.
  Do not bypass the token layer with new inline colors — extend it.
- **Adaptive Semantic Colors**: Use dynamic system assets natively (`Color(.systemBackground)`, `Color(.secondarySystemBackground)`, `Color.primary`, `Color.secondary`).
- **Contrast Ratios**: Maintain high WCAG contrast safety thresholds. Prefer semantic styling methods such as `.foregroundStyle(.secondary)` over `.opacity(0.5)` to align with active system accessibility overrides.

### 5. Intentional Micro-Animation & Depth
- **Smooth Spring Profiles**: Basic linear or rigid standard easing transitions are banned. Deploy custom physical spring curves: `.animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: bindingState)`. **One exception (§7.2):** a Reduce Motion opacity fade may use a plain ease (`.easeOut`, `.default`), since the point of the reduced path is that nothing springs.
- **Layer Architecture**: Separate layout information depths cleanly using native material types: `.background(.ultraThinMaterial)`.
- **Soft Diffusion Shadows**: Prevent heavy, muddy shadow rendering. Apply delicate light diffusion styling paths: `.shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)`.

### 6. Implementation Architecture
- **Unified Screen State**: Contain screen presentations and local state controls contextually using standard state enumerations: `enum ViewState { case loading, success, error(String) }`.
- **Data Execution Lifecycles**: Manage asynchronous operations via modern `.task` blocks instead of legacy `.onAppear` handlers.
- **Preview Support**: Every view structure must include a functioning `#Preview` block rendering Light and Dark environment variants side by side.

### 7. The iOS 16 floor, modern APIs, and Reduce Motion

*Rewritten 2026-09-11 (E's call, `F-ModernIOS-1-Policy`).* This section used to be only "Design
Skills — Precedence and Known Conflicts", and read together with the design records it amounted to
a ban: nothing above iOS 16.0, and `reduceMotion ? nil : …` as the answer to Reduce Motion. Two
things overturned that on the same day. **E's direction:** keep the 16.0 floor, but give users on
recent iOS (the majority) the modern experience. **And E's own phone runs Reduce Motion ON**, so
the focus card's celebration (`F-FocusCard-4`) had never once played for its author: E saw a hard
cut plus a haptic. The skill-precedence rules are unchanged in substance and now live in §7.5.

#### 7.1 The rule — the best API per site, and a complete floor path beside it

- **Use the best available API at each SITE, behind `if #available(iOS N, *)` (17, 18, 26), and
  always ship a complete iOS 16 branch beside it.** "Complete" means the same information, the
  same feedback and the same end state: plainer is fine, absent is not. The deployment target (app
  16.0, widget 16.1) is a floor, not a ceiling.
- **Two shapes, and they must not be blurred:**
  - **Degraded:** a site with a modern and a floor rendering of the same thing. Always
    `if #available { … } else { … }`. The exemplar is **`View.haptic(_:trigger:)`**
    (`Theme/Haptics.swift`): `.sensoryFeedback` on 17+, the UIKit performer through `.onChange`
    on 16. `ModernAPIPolicyCallSiteTests` pins it. `FocusCompletionCelebration` is the second
    (16 spring / RM cross-fade / 26 draw-on), landed in `F-ModernIOS-2-Celebration` (PR #65).
  - **Absent:** a feature whose WHOLE surface is above the floor (Places and the routine screen,
    E's 2026-08-27 deviation recorded in `PlaceMapPicker`). It may have no `else`, but the absence
    is announced by a flag in the `ToolsView.placesSupported` shape, so a 16.x user is never shown
    a door to nothing. **Feedback is never absent.** A haptic, a celebration or a confirmation is
    always a degraded site.
- **A modern branch longer than a few lines lives in its own `@available(iOS N, *)` type** beside
  the call site (the `FocusSprintControls` shape in `FocusTimerWidgetLiveActivity.swift`), so the
  `if #available` reads as a two-line choice rather than a wall.
- **"Every tier that adds value" is a filter, not a quota.** A tier ships only when it shows the
  user something the tier below cannot. When a tier is considered and not added, the block report
  says why. For example, the celebration's tick has no 17 tier: `.symbolEffect(.appear)` is a
  scale-in with less life than the spring, and `.bounce` fires on the state change with no delay.
- **No skill gets to skip the gate** (§7.5). `apple:modernize`'s Liquid Glass and current-OS
  adoption pushes are governed by exactly this filter.

#### 7.2 Reduce Motion — replace motion with a fade, never remove feedback

- **E runs with Reduce Motion ON** (and Prefer Cross-Fade Transitions). The reduced path is the
  author's primary experience of this app, not an edge case, and it is judged on E's phone with the
  setting ON.
- **`reduceMotion ? nil : …` is correct only for continuous re-layout**, such as a VStack
  reflowing or a bar resizing, where the tween IS the motion and the instant change loses nothing.
  **For anything that appears, disappears or celebrates it is a hard cut, and it is WRONG.**
  Apple's guidance under Reduce Motion is to replace motion with fades, not to strip the feedback.
  (In 2026-09-11's audit, 19 of the app's 20 RM-guarded sites were `nil`.)
- **House pattern: `Capture/CaptureFanOverlay.swift:89-96`.** Geometry is pinned to its final value
  by `appeared || reduceMotion`, opacity is left free, and the animation is `.default` under RM.
- **The opening-pose rule:** under Reduce Motion the FIRST frame already has final GEOMETRY
  (scale, offset, size) and only opacity travels. A reduced path that opens on the pre-animation
  geometry and then snaps is the bug, not the fix.
- **Haptics are unaffected**, because they are not motion. They fire under Reduce Motion as they
  always have.
- **The ONE sanctioned waiver of this section, and it is a waiver rather than a loophole: the
  Confirm celebration** (`Focus/ConfirmCelebrationOverlay.swift`, E's call, 2026-09-11). Asked
  what Confirm should show with Reduce Motion ON, E was offered a still confetti that fades (the
  policy answer, recommended), a glow, or real falling confetti as a named waiver, and answered
  **"B AND C"**: the glow AND real falling confetti. So it plays identically with Reduce Motion ON
  and OFF, and its files never read the setting. `testTheConfirmCelebrationIgnoresReduceMotionByDesign`
  pins that. **Do not "fix" it in a Reduce Motion sweep** — that would silently undo E's decision.
  E's accepted cost is recorded in the register (§D): people who turned Reduce Motion on for motion
  sensitivity get full-screen confetti with no off switch, to revisit before launch. Like
  `peekStep`'s waiver of §2, it covers that one site and nothing else.
- **Symbol effects, `PhaseAnimator` and `keyframeAnimator` do NOT honour Reduce Motion themselves.**
  `SymbolEffectOptions` has no Reduce Motion option in the 26.5 SDK. Resolve RM FIRST and choose
  the tier second, so a reduced site can never reach a modern motion tier.
- **`accessibilityReduceMotion` cannot be injected through `.environment(\.)`.** A leaf that must be
  tested in both modes takes the resolved value as a PARAMETER from a parent that reads it (the
  `FocusCompletionCard` → `FocusCompletionCelebration` shape), and a call-site test pins the
  pass-through.
- §5's ban on plain easing does not apply to a Reduce Motion opacity fade; §5 carries the clause.

#### 7.3 Verification honesty — one runtime, and every report says so

- **This machine has ONE simulator runtime, iOS 26.5, and E's phone runs 26.** So a floor branch is
  proved to COMPILE (the 16.0 target plus `CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE` make
  every gate load-bearing) and to be REACHED (the call-site tests, §7.4). Its CODE can be RUN on
  26.5 by injecting the mode it would select. It is **never run ON a 16 or 17 OS, and that is
  compile-only by policy, not by oversight** (E's call, 2026-09-11) until an older simulator
  runtime is installed (register §A, E's GUI job).
- **Every block that adds or changes an `#available` site carries a "Verified paths" line** in its
  report, and in its `screenshots/` README when it has one. There is one entry per tier actually
  shipped, for example:

  > `26 path: run on sim + E's phone (RM off). Reduced: run on sim (injected) + E's phone (RM on).
  > 16 path: code run on 26.5 by injection; OS-level behaviour COMPILE-ONLY — no 16 runtime
  > installed.`

- **Never write "works on iOS 16".** Nobody here can know that yet.

#### 7.4 Tests over two paths

- **Pure logic is shared and tested once.** Which tier, which pose and which animation are pure
  functions of (Reduce Motion, availability), so they get ordinary unit tests with the availability
  flag injected, e.g. a `resolve(reduceMotion:drawOnAvailable:)`-style function.
- **Call-site tests assert BOTH branches by string:** the `#available(iOS N, *) {` gate, the
  `} else {`, and the floor API's name, reading code with comment lines stripped as the
  `*CallSiteTests` files do. **A test that asserts only the modern branch stays green on a build
  that dropped the floor.**
- **Render probes render the leaf with Reduce Motion as a parameter** (§7.2), one render per mode.
  The floor-mode render doubles as the regression proof for the 16 path.

#### 7.5 Design skills — precedence and known conflicts

Design-heavy blocks may mandate the installed design skills (`ui-ux-pro-max`,
`swiftui-design-principles`, `swiftui-pro`). On 2026-09-11 E also installed the `indie-apple-stack`
plugin's `apple:*` skills and agents (`apple:modernize`, `apple:juice`, `apple:review`,
`apple:hig-reviewer`, `apple:swiftui-builder`, …) and the `apple-skills:*` set. **The rule is the
same for every one of them:** they improve *how well* an authorised change is executed. They never
expand scope, and they never override this file.

**Precedence, absolute:** `CLAUDE.md` §1–6, §7.1–7.4 and the **iOS 16.0 deployment target** beat
every skill and every agent. Never silently follow a skill over this doc, and never silently follow
this doc without saying the skill disagreed. **Report every conflict in the build report.**

**Known conflicts, established 2026-07-30 in the Settings rebuild (`3f94eff`). Do not re-litigate
these per block; they are settled:**

- **`ui-ux-pro-max` — use `--stack swiftui`, ignore `--design-system` on native screens.** Its
  `--design-system` output is web-oriented and was discarded wholesale for Settings: it prescribed
  an "Immersive/Interactive Experience" pattern, "Exaggerated Minimalism" with oversized `clamp()`
  typography, a forced dark focus background, a hardcoded hex palette (`#059669`), a Google Fonts
  (Plus Jakarta Sans) import, and hover / `cursor: pointer` states. Every one of those violates §1
  (restrained SF typography), §4 (zero hex, adaptive semantic colours), or the native-iOS premise —
  and hover states do not exist on iOS at all. Its `--stack swiftui` guidance, by contrast, is
  sound and aligned with this doc ("use `Form` for settings screens", "support Dynamic Type — no
  fixed font sizes", "respect Reduce Motion", "add accessibility labels").
- **`swiftui-design-principles` spacing permits `12` and `20`. §2 wins — 4/8/16/24 only.** `12` and
  `20` are unmapped in this project and must not ship.
- **`swiftui-design-principles` pushes fixed `.font(.system(size:))` scales. §1 wins** — semantic
  Dynamic Type throughout.
- **`swiftui-pro` asserts "iOS 26 is the default deployment target" and Swift 6.2. Ignore the
  target claim entirely: this project is iOS 16.0** (`IPHONEOS_DEPLOYMENT_TARGET = 16.0`, set in
  FEATURE-M2) and Swift 5. **A 17+ API it recommends is welcome behind a gate with a complete 16
  path (§7.1)**, never as a raised floor and never ungated. This is the trap that made
  `.sensoryFeedback` need gating in `345233b`. §3 prescribes `.sensoryFeedback`, and the house way
  to use it is `.haptic(_:trigger:)` (`Theme/Haptics.swift`), which IS §7.1's two-branch pattern.
- **`apple:modernize`, and any skill or agent that pushes Liquid Glass, `Tab`, `@Observable`,
  interactive widgets or other current-OS adoption: §7.1's filter governs, and the skill does not
  get to skip the gate** (E, 2026-09-11). A modern API it recommends ships only behind
  `#available`, only with a complete 16 path, and only where it adds value. Anything touching the
  tab bar is further constrained by the custom `AppTabBar`: adopting `Tab` /
  `.tabBarMinimizeBehavior` / `.glassEffect` there means replacing that bar, not augmenting it
  (register §B, the modern-API inventory). A skill's recommendation is a candidate for the
  register, not a mandate for the block in hand.

**`swiftui-pro`'s design / accessibility / views review passes are worth running** over a finished
view — in the Settings rebuild they correctly caught a hand-rolled `HStack` + `Spacer` title-value
row that should have been `LabeledContent` (which reflows at accessibility Dynamic Type sizes
instead of wrapping into narrow columns), and a glyph+text `HStack` that should have been a `Label`
(so VoiceOver reads it as one element and status is never conveyed by colour alone). Both are now
the house pattern for Form rows.

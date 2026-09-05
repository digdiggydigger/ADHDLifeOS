# Session opener — after the pad found its balance

Read `claudecode.md`, `CLAUDE.md` and the memory index first, then this brief. The previous opener
(`SESSION-OPENER-post-round-2.md`) is **CLOSED** — its four unconfirmed items were all reviewed on
device and everything that came out of that review has shipped.

## Where things stand

- **`main` at `200d0ea`**, clean and pushed; `origin/main` matches. Five commits landed on
  2026-08-28 (second session of that day), all committed, pushed and SHA-verified.
- **Suite 1,831 / 0** (up from 1,796). **All five signed-in UI journeys pass** — with a caveat
  about flakiness that has its own section below, because it will cost you time otherwise.
- **Lint debt is EXACTLY two and nothing else is acceptable:** `TaskDetailView` file_length (438)
  and UITests `static_over_final_class`. Held at exactly two through five commits; every new
  violation was fixed rather than accepted (two function-body splits this session).
- **Emulator is UP** (auth 9099, firestore 8080, storage 9199) via `./scripts/emulators.sh`.
  Verified reachable at the time of writing. A fresh machine boot needs it started again.
- **Device `wishwashwacky15` is installed at `200d0ea`** — genuinely current, installed from an
  explicit `-derivedDataPath` scratch build 3½ minutes after the commit. `devicectl` install works.
- `feature/location-services` still exists locally and on origin. Leave it unless E says delete.
- `TODO-CLAUDE-CODE.md`'s Current Sprint has **exactly one open block**: `F-AccountName`. Everything
  else there is COMPLETED or SUPERSEDED. Read it before assuming anything is queued.

## FIRST THING: much less is unreviewed than last time, but not nothing

E reviewed on device *during* this session rather than after it, so most of what shipped has already
been seen and directed. Two things have NOT:

1. **The pad's balanced redesign on a real screen** (`200d0ea`). E approved it from renders — both
   faces, both appearances — and it is installed, but a render is not a phone. This is the sixth
   pass on this surface and three earlier ones were rejected *on device* after looking fine in a
   render, so treat "approved from a render" as weaker evidence than usual.
2. **The nudges door with a genuinely due nudge** (`bb692ce`). E saw the quiet state and a
   simulator render of the due state, but has not had a real nudge fire on the phone.

Everything else from this session E either photographed themselves or explicitly directed.

## What landed on 2026-08-28, second session (context, not work)

Full reasoning is in the commit messages, which are long on purpose.

```
eddef9b  F-TriageCardTruth   blank photo card + stale tab counts; FIVE exit sites, not four
5f576da  F-ArrangeFold       Arrange folds away with the list it reorders
bb692ce  F-NudgesDoor        the nudges section becomes a door, not a footer
6e75dea  F-DropAltButton     the composer's redundant second button goes
200d0ea  F-PadBalance        the pad's wardrobe goes warm; the night face finally reads as gold
```

The arc: E sent five device screenshots, three real defects came out of them, and the last two
commits are a design conversation that ended somewhere much better than where it started.

## The open list

`F-AccountName` is the only queued block. These are the honest leftovers behind it, smallest first.

- **`signOutIfSignedIn` is the biggest source of noise in the suite and it is not a feature.**
  Four false journey failures in one day, every one passing in isolation. See its own section below.
- **`CaptureInboxService.swift` is at 397/400**, up from 398 — a net gain of ONE line after moving
  `refreshInactiveCount` out. That is not headroom. `state` has a `private(set)` setter so
  `removeCapture`/`replaceCapture` are pinned to that file; a real split has to move something
  larger, and `promoteToTask` is the candidate.
- **`TaskDetailView` is 438/400.** Accepted debt of long standing. The next feature that touches it
  should split it rather than grow it again.
- **The FAB overlaps the nudges door's last row** when the door sits near the bottom of Today's
  scroll. `CaptureDiscMetrics.clearance` exists for exactly this and the door is not using it.
- **`weekCounterweightLine` goes stale after a triage exit**, deliberately — it would cost a third
  read per tap on a rapid-triage screen. `refreshCountsAfterExit` is the function it belongs in if
  that ever changes. Reasoning is in the code.
- **The Journal tab still has no UI journey.** The composer is the obvious thing to walk, and it now
  has a lot more surface worth protecting than it did.

## House rules that bit THIS session — these cost real time

### The journey suite is flaky, and it is ONE helper

**Four false failures in one day**, across three separate runs: `testDueNudge`, `testSettings`,
`testTaskDetail`, then `testCreateTask`. Every single one passed when re-run alone. Every single one
failed inside `signOutIfSignedIn`, during SETUP, before its test reached the screen under test.

**The rule, and follow it before touching app code: re-run the failure in isolation.**
`xcodebuild test-without-building … -only-testing:"…/SignedInJourneyUITests/<theTest>"`.

The remaining weak point is visible at `UITestSession.swift:94` — it taps `settingsButton` ONCE with
no retry, so a tap swallowed while Today is still settling surfaces two lines later as "Settings did
not open", which is a true statement about the wrong step. That helper has been hardened twice
already; a third pass wants a retry loop around the tap. **It is unrelated to any feature work,
which is exactly why it keeps not getting fixed.**

### On taste, render — and the camera is a test, so it gets every trap a test gets

Rebuilt the throwaway harness twice this session. Four traps, each of which cost a wasted ~2.5-minute
run, all now in [[journal-pad-design]]:

- **Existing ≠ visible.** The first nudges shot asserted the door EXISTED and fired instantly. Today
  opens scrolled to the top, so it photographed the ring instead of the section — a passing test
  producing a useless picture.
- **Fixing that broke the other state.** `swipeUp` carries momentum, so `isHittable` reads false
  mid-glide, the loop swipes again, and the subject leaves the top of the screen. Needs a ~0.6s
  pause between swipes. Symptom: the state that used to pass starts failing the moment you add
  scrolling.
- **A DUE nudge raises the notification permission alert; a scheduled one does not.** That alone
  explains a camera where one state photographs perfectly and the other times out.
- **Never wait on the simulator with `pgrep -f "xcodebuild …"`.** The script's own shell holds the
  whole script text in its command line, so the pattern matches ITSELF and the loop never exits.
  Cost a silent 20-minute stall that looked exactly like a slow build.

Recover the composer camera with
`git show 22dba79:"ADHD LifeOSUITests/ComposerLookCaptureUITests.swift"`. Drive the appearance
explicitly (`xcrun simctl ui <udid> appearance dark|light`) — that is what proved the forced-light
pad had no night face. Extract with `xcrun xcresulttool export attachments`, then read
`manifest.json` to map UUID filenames back to attachment names.

### Measure the colour, do not reason about it

The pad took six passes because five of them were reasoned. What ended it was arithmetic:

- The night face was goldenrod at **20% lightness** — same hue as the day face, a fifth of the
  brightness. That is why it read as brown.
- Walking the goldenrod ray up, the ceiling was hard and close: `#7A6000` (already rejected by E as
  mustard) measures 4.67:1 against parchment ink, and anything goldier fails AA outright.
- **That ceiling was a consequence of the WARDROBE, not of the yellow** — which is E's insight, not
  mine, and it is the whole reason this finally worked.

**One ink on the gold page, and it is arithmetic:** primary ink clears AA at only ~5.2:1, so any
dimmed version lands under 4.5 (`#6B4E12` on `#DAA520` = 3.45:1). Hierarchy comes from weight and
size (§1), never a lighter ink or an opacity (§4). The writing SHEET is the single exception,
because ink clears ~9.5:1 there. Both facts are encoded in `JournalComposerPalette` with the
measurements in the doc comments — **do not re-add a "subtle" grey.**

I also once picked a placeholder value and called it passing when it measured 3.82:1. Compute the
ratio; do not eyeball it.

### Containment pattern for shared components — reuse this

`F-PadBalance` changed four components across ~20 call sites (`ChoiceChipButtonStyle` ×7,
`PrimaryActionButtonStyle` ×10, `ComposerAreaChips` and `ComposerSectionHeader` ×3 each). Every
override is **OPTIONAL and defaults to nil**, so only the journal pad opts in and every other screen
is unchanged *by construction* rather than by inspection.

The evidence that it held is specific rather than general: `testCreateTask` walks `TaskCreateView`,
which uses BOTH changed chip components. Name the journey that would catch your blast radius, and
make sure it runs.

### Smaller things that cost time

- **`grep` for a method finds its callers, not its equivalents.** `removeCapture` had four call
  sites; `promoteToTask` open-coded the same `state = .loaded(captures.filter { … })` inline and so
  carried the identical bug on the most-used verb of the five. Look for the SHAPE, not the name.
- **A view that duplicates a helper's logic will drift from it.** The triage card hand-rolled
  `title ?? content` instead of calling `CaptureRowPresentation.primaryText`, and rendered a blank
  card for photo captures. That is the SECOND time that card being separate from `CaptureRowView`
  has cost something — check it whenever `CaptureRowView` gains anything.
- **Chained `.background` stacks BACKWARDS.** An opaque surface added after a tint paints straight
  over it. Caught before it shipped, twice.
- **`.foregroundStyle` on a `TextField` paints the typed text as well as the prompt.** Use
  `prompt:` with its own `Text` to recolour a placeholder.
- **Before removing a control, check what it duplicates.** Three of the five alt-button labels were
  exact duplicates of a control inches away (voice's record button already said "Re-record"), which
  is very likely why they read as noise. The other two were the only in-composer kind switch, and
  that capability is now genuinely gone — said out loud rather than discovered later.
- **Verify against the live backend rather than asking E.** The Firebase MCP settled the Settings
  name question in two calls: E's Auth record was created 2026-08-19, nine days before
  `F-DisplayName`, and carries no `displayName` at all.

### Standing project rules (unchanged)

- Per change: failing test first → `swiftlint` (exactly the two debts) → full suite with the
  emulator up → sim build → commit + push → SHA-verify against origin → device build + install.
  Run the UI journeys when a block touches what they walk, or when a shared style has wide reach.
- File budgets 400/file, 250/type body, 50/function. House fix is a same-file extension or an
  own-file split with members made internal.
- Colour is lint-enforced (`raw_hue_color`); the asset catalog is the ONLY home for hex; haptics via
  `Theme/Haptics.swift` only; `inclusive_language` rejects "master" in DECLARATIONS.
- Container accessibility: a bare `.accessibilityIdentifier` on a container is INHERITED by every
  descendant, and `.combine` SWALLOWS the controls inside it. A container that names itself and
  holds a control wants `.accessibilityElement(children: .contain)` BEFORE the identifier — better
  still, build it into the component.
- Wire conventions: tasks / places / location_events / focus_sessions snake_case; captures camelCase
  EXCEPT `created_at` and `tag_ids`. Tests assert the WRONG spelling is absent too.
- iOS 16.0 floor app-wide; the Places UI alone is 17+ by E's explicit §7 deviation.
- `firestore.rules` enumerates COLLECTIONS, not fields — a new field needs no rules change.
  Publishing rules stays E's call; verify live via the Firebase MCP rather than asking E to paste.
- **Never destroy uncommitted work** ([[never-destroy-uncommitted-work]]): commit working code
  BEFORE any deliberate-regression red-check, restore with `git checkout -- <file>`, and prove the
  restore by REBUILDING. `xcodebuild | tail` throws away the exit code — use a log and `echo $?`.
- `-resultBundlePath` fails outright if the path already exists. `rm -rf` it first.
- A five-journey run is ~8.5 minutes and exceeds the 10-minute foreground command cap once the build
  is included. Run it in the background.

Start by asking E whether they want the pad checked on a real screen before anything else is built
on it, then take direction. Nothing here is urgent and nothing is blocked.

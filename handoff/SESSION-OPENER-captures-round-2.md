# Session opener — captures round 2, and the tail of the open-items queue

Read `claudecode.md`, `CLAUDE.md` and the memory index first, then this brief. The previous
opener (`SESSION-OPENER-open-items.md`) is CLOSED — all six of its items shipped. This one picks up
where E's device check left off.

## Where things stand

- **`main` at `fea8297`**, clean and pushed; `origin/main` matches. Nine blocks landed on
  2026-08-28, all committed, pushed and SHA-verified.
- **Suite 1,751 / 0.** Lint debt is EXACTLY two warnings and nothing else is acceptable:
  `TaskDetailView` file_length (**438** — it grew again when the sprint-planner default threaded
  through) and UITests `static_over_final_class`.
- **Device `wishwashwacky15` is installed at `fea8297`.** `devicectl` install works; a one-off
  `PackagePatchFailed` on the widget's Assets.car is iOS's delta installer — retry clears it.
- **Emulator is UP** (auth 9099, firestore 8080, storage 9199) via `./scripts/emulators.sh`;
  "port taken" means already running. A fresh machine boot needs it started again. Emulator-backed
  tests SKIP silently without it, so a green suite with it down is quieter than it looks.
- `feature/location-services` is fully merged and still kept — leave it unless E says delete.
- Nothing is queued in `TODO-CLAUDE-CODE.md`'s Current Sprint; E is directing this work
  personally. Check it anyway in case Cowork has written a block.

## What landed on 2026-08-28 (context, not work)

```
fea8297  the area picker can be unpicked, and undo hands the choice back
0174b23  the Sorted button lights up, and stops hiding under the capture disc
1d8788e  the way into triage says how much is behind it
c71993b  triage gets a fourth verb, and it insists on knowing where things live
c174cb0  a real front door — create an account, sign in, get back in
5df8299  journal rows say where the entry was written
1116f7b  a place can carry E's own words for leaving too
46fa6c9  the composer can name where a task can be done
4e96de9  the detail planner opens at the default-sprint-length setting
```

Full reasoning for each lives in the commit messages and in memory
([[captures-sorted-verb]], [[auth-v3-design]], [[location-services-spec]]).

## FIRST THING: E's device check is unfinished

E ran a visual pass on device and reported everything good EXCEPT two things, both since fixed and
installed but **NOT yet re-checked by E**:

1. tapping a life-area chip locks it in — should be unselectable (fixed in `fea8297`);
2. undo should also reset the staged area pick (fixed in `fea8297`).

**Ask E whether those two now behave**, before building anything new on top of the triage card.

## The open list

### 1. Captures round 2 — E's own framing, and the biggest thing here

E opened the captures rethink by saying **"the Capture triage/storing aspect of this app is
starting to fall a bit behind the other elements of the LifeOS app"**, and — asked what actually
goes wrong — chose **"too many places it lives"** and **"capturing is fine, deciding isn't"**.

Round 1 answered the deciding half: the `Sorted` verb (a life area is REQUIRED), undo both ways,
the sectioned card, and a louder Inbox door. **The "too many places it lives" half is largely
untouched.** Reopen that with E rather than assuming round 1 finished the job.

### 2. Undo for "Journal it" — deliberately not built, and E knows

Undo covers Sorted and Skip only. "Task it" opens a sheet (a flow, not an instant). "Journal it"
writes a `Log` AND marks the capture processed, and reversing it needs **a log-delete and an
unprocess path that do not exist**: `JournalClientAdapting` has no delete, and `markProcessed` has
no inverse. An Undo offered for something it cannot reverse is worse than none, so neither is
claimed. This is a real, scoped next block if E wants it.

### 3. The Areas → "Handled captures" door — ASK, don't assume

It was always interim. Now that the Captures tab's **Sorted** filter IS the archive and the Inbox
door is loud, that door looks redundant — but **E has never been asked directly**, and removing a
door E uses is exactly the sort of taste call E has corrected before. Ask.

### 4. Smaller, genuinely open

- `TaskDetailView` is 438 lines against a 400 ceiling. Accepted debt, but the next feature that
  touches it should split it rather than grow it again.
- `CaptureInboxService.swift` is at **398/400**. Stored properties cannot move to an extension, and
  `state`/`counts` have `private(set)` setters so their only writers must stay in that file — the
  next stored property added there needs a real split first.
- Nothing in the app displays a user's display name, though signup now collects one.

## House rules that bit THIS session — read these, they cost real time

### The binding one: never destroy uncommitted work

**The same mistake happened twice on 2026-08-28 and E instructed it never happen again.** Full rule
in memory as [[never-destroy-uncommitted-work]]. Short form:

The deliberate-regression red-check (break working code on purpose, prove its tests go red, restore
it) is valuable and should keep happening — but the order is fixed, no exceptions:

1. **commit the working implementation first** (green suite + lint before the commit);
2. break it;
3. run the targeted tests, observe red;
4. `git checkout -- <file>`;
5. **REBUILD to prove the restore.** Never `diff` against a hand-rolled backup — that is circular
   and it silently passed on a half-restored file.

If it truly cannot be committed first, `git stash` — never `cp`.

### `xcodebuild | tail` throws away the exit code

A pipeline exits with its LAST command's status, so `tail`/`grep` succeeding always reads as
success. `xcodebuild … | tail -2 && git commit` committed a tree that did not compile. Either
`set -o pipefail`, or redirect to a log and echo `$?` before deciding anything:

```bash
xcodebuild … > "$SCRATCH/build.log" 2>&1; echo "EXIT: $?"
grep -E "error:|BUILD (SUCCEEDED|FAILED)" "$SCRATCH/build.log"
```

Reading the output is not optional — both failures were fully visible in text already generated.

### Simulator, if you drive it at all

- `idb` / `ui_tap` takes **points, not screenshot pixels**. The capture is 3× scale, so divide by 3.
  Two taps silently went off-screen and looked exactly like a broken segmented control.
- `ui_type` only lands if a field actually has focus; taps did not focus text fields, and
  `ui describe-all` failed with "No translation object returned". **Do not hand-drive a signed-in
  session this way** — it has produced false conclusions repeatedly ([[ui-journey-harness]]).
- **There are FIVE `ADHD_LifeOS-*` DerivedData folders.** `find … | head -1` grabbed one from
  6 August and rendered the OLD V1 auth screen, which read convincingly like the rebuild had
  failed. Pick by mtime:
  `ls -dlt /Volumes/Es-SSD/Xcode_External/DerivedData/ADHD_LifeOS-*/Build/Products/Debug-iphonesimulator/"ADHD LifeOS.app"`.
  The live one is `ADHD_LifeOS-etcfckccqnfwduaoegzziavhdjel`.

### Standing project rules (unchanged)

- Per change: failing test first → `swiftlint` (exactly the two debts) → full suite with the
  emulator up → sim build → commit + push → SHA-verify against origin → device build + install.
- File budgets 400/file, 250/type body, 50/function. House fix is a same-file extension or an
  own-file split with members made internal (`CaptureInboxService+Create`,
  `FocusSessionService+Persistence`, `LoginFormSections` precedents).
- Colour is lint-enforced (`raw_hue_color`); haptics via `Theme/Haptics.swift` only; steppers
  confirm once on release; `inclusive_language` rejects "master" in DECLARATIONS.
- Wire conventions: tasks / places / location_events / focus_sessions snake_case; captures
  camelCase except `created_at` / `tag_ids`. Tests assert the WRONG spelling is absent too.
- **Task creation writes through `Codable`, not a hand-written field dictionary** — a dropped field
  raises nothing, so assert the encoded JSON.
- iOS 16.0 floor app-wide; the Places UI alone is 17+ by E's explicit §7 deviation.
- `firestore.rules` enumerates COLLECTIONS, not fields — a new field needs no rules change.
  Publishing rules stays E's call; verify live via the Firebase MCP rather than asking E to paste.

Start by asking E about the device re-check (top of this file), then take direction. Do not start
captures round 2 by building — E's framing is a diagnosis, not a spec.

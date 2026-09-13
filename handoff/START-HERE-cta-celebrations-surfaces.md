# START HERE — `F-CTACelebrations-Surfaces`, and it opens with a DESIGN question

*A disposable pointer (CLAUDE.md, "Session handoff"): paste this path into a fresh Claude Code
terminal. **WRITTEN 2026-09-13** by the session that finished `F-CTACelebrations-6` at C6–C9 and
built `-7` end to end. It archived its own predecessor
(`handoff/archive/START-HERE-cta-celebrations-7.md`) in the same move that wrote this. The session
that finishes `-Surfaces` archives THIS one when it writes the next.*

**`main` @ `eade58a` is clean, green and holds everything.** No branch to check out, nothing
half-built, and `origin` carries `main` alone.

```bash
git checkout main && git pull --ff-only
```

## State

| | |
|---|---|
| `main` | `eade58a` (PR #110) |
| unit suite | **2,975 / 0**, emulator UP, **0** `127.0.0.1:9099` hits |
| SwiftLint | **0 / 806 files** |
| sim build | `** BUILD SUCCEEDED **` |
| UI journeys | both GREEN (run for `-6`); sim erased after |
| device | **ON MAIN. `-6` and `-7` BOTH PASSED** — nothing owed on either. |

## Nothing is owed on the two blocks that just landed

- **`-6`** (the routine Completed flow): E passed both Reduce Motion passes — *"both work
  correctly"*. §7.3's RM-on pass is EARNED for it. Do not re-ask.
- **`-7`** (the chime): E picked `el-a` by ear and passed both device checks — chime under music
  without pausing it, silent with the ring switch off. Do not re-ask.

**One standing item, and it is an instruction rather than a task.** E RESERVED the runner-up sound:
*"keep a hold of the sound 'el-b' ... there is likely other locations that [it] Could be used."* It
is at `screenshots/cta-celebrations-block-7/candidates/05-generated-b.{wav,caf}`, already trimmed,
normalised and in ship-ready `.caf`. **When a second sound gets a real site, use that file — do not
generate a new one.** It is deliberately not in the asset catalog, because an asset with no call
site is weight in every build.

Shipped without a verdict and overrulable if E raises it: under `.spring` the routine checklist
scales down to 0.9 as the congratulation scales in (flagged to E, no comment either way).

## ⚠ `F-CTACelebrations-Surfaces` — DO NOT START BY WRITING THE HOLD

Read the block in `TODO-CLAUDE-CODE.md` (search `F-CTACelebrations-Surfaces`) in full. E has already
chosen the behaviour, so that is not the open question:

> Offered "add Quick Capture only", "hold behind any unknown sheet", "accept it" or "defer",
> **E chose hold behind any unknown sheet** (2026-09-13).

**The block's own spec says the design question is open and must be settled FIRST:**

> *"The hard part, and it is the whole block: knowing a sheet is up. iOS hands us no such signal, so
> this needs a deliberate seam rather than a guess. That design question is OPEN and is the first
> thing the block must settle — do not start by writing the hold."*

The mechanism for the hold itself already exists and is proven: `CelebrationSurface.dismissesItself`
plus the centre's `held` list, which `.promoteSheet` uses today, with R-g's 60 s drop unchanged. So
the work is *detection*, not queueing — and the honest first move is to put the options to E, the
way `-7` put five chimes in front of them.

Today only four surfaces call `surfacePresented`: root, the routine cover, Tasks search, and the
promote sheet. Everything else — **Quick Capture** above all, plus Settings, Add Task, the Journal
composer, focus detail, add nudge, and the Life Area / Place / Tag editors — leaves `frontmost`
reading `.root`, so a milestone requested then draws BELOW the sheet: invisible, while still
marking the day, firing the haptic and posting the announcement.

After it: `F-FocusCard-Corners`.

## What the last session learned that will bite the next one

- **A green suite can leave the one thing users depend on unproven.** Every test in
  `CelebrationSoundTests` injected the asset loader, so none touched the catalog — and `assetutil`
  proves bytes SHIP, not that `NSDataAsset(name:)` resolves. One test using the DEFAULT
  implementation closed it. **Whenever a seam is injected everywhere for testability, ask what
  exercises the real one.** This is the same family as `-6`'s R-f defect: the guards were all
  correct and none of them was looking at the gap.
- **Read the whole paragraph of user-facing copy, not the clause you came for.** The Settings footer
  carried TWO stale claims; one had been wrong since `-4` and had nothing to do with the block in
  hand. No compiler checks prose.
- **Reverse a test, never delete it — and check its NAME.** Done three times this session; once the
  reversed claim was in the test's own name.
- **GitHub can report a landed merge as unmerged for the better part of an hour.** Verify against
  `origin/main` with `git merge-base --is-ancestor`, and do NOT re-run `gh pr merge` — that puts a
  second empty merge commit on `main` for a change already there.
- **`defaults read … DVTDeveloperAccountManagerAppleIDLists` false-alarms on Xcode 26.** An empty
  `IDE.Identifiers.Prod` is no longer evidence of the signing blocker; run the device build and read
  its LOG for `No Accounts` / `profile has expired`. **Device profile expires 2026-09-17** — E
  re-signs in Xcode → Settings → Accounts only if the log actually says so.

## Owed to E, carried

**Nothing on `-6` or `-7`.** What remains is older:

- The three device checks in register §A (the swipe's pop, the overlap, RM-on for `PopScale`) —
  landed, green, installed, none urgent.
- **PHOTOSENSITIVITY is a LAUNCH BLOCKER by E's own instruction** (§A and §D) — postponed, not
  closed, and it may not be closed without E.

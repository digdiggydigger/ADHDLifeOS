# START HERE — `F-CTACelebrations-7`, the chime (E picks by ear)

*A disposable pointer (CLAUDE.md, "Session handoff"): paste this path into a fresh Claude Code
terminal. **WRITTEN 2026-09-13** by the session that finished `F-CTACelebrations-6` at C6–C9 and
merged it. It archived its own predecessor (`handoff/archive/START-HERE-cta-celebrations-6-part2.md`)
in the same move that wrote this. The session that finishes `-7` archives THIS one when it writes
the next.*

**`main` @ `8a74d7d` is clean, green and holds everything.** There is no branch to check out and
nothing half-built.

```bash
git checkout main && git pull --ff-only
```

## State

| | |
|---|---|
| `main` | `8a74d7d` (PR #106) |
| unit suite | **2,958 / 0**, emulator UP, **0** `127.0.0.1:9099` hits |
| SwiftLint | **0 / 801** |
| sim build | `** BUILD SUCCEEDED **` |
| UI journeys | **both GREEN**, first run each; sim erased after |
| device | **ON MAIN at `4b0f0ad`** — `F-CTACelebrations-6` installed and **PASSED on both RM passes**. |

## `F-CTACelebrations-6` is CLOSED — nothing is owed on it

It was installed at `4b0f0ad` on 2026-09-13 and E passed it on both passes. E, verbatim, to an ask
that enumerated the two checks separately: ***"both work correctly"*** — Reduce Motion OFF and
Reduce Motion ON. **§7.3's RM-on pass is EARNED for that block**, so do not re-ask for it.

One thing shipped WITHOUT a verdict, and it is overrulable if E raises it: under `.spring` the
checklist scales down to 0.9 as the congratulation scales in. It was flagged to E in the same
message and drew no comment either way.

**Device profile expires 2026-09-17.** E re-signs in Xcode → Settings → Accounts if a build's LOG
says `No Accounts` — **not** because `defaults read … DVTDeveloperAccountManagerAppleIDLists` is
empty, which false-alarmed on 2026-09-13 and would have cost E a pointless GUI trip. Run the build
first; its log is authoritative.

## Then `F-CTACelebrations-7` — and it is a DESIGN block before it is a build block

The chime. **E picks by ear**, which means the session's first job is to produce something to listen
to, not to write a `AVAudioPlayer` wrapper. Read `handoff/SESSION-OPENER-cta-celebrations-design.md`
(a permanent design RECORD, never archive it) for where the sound question was parked, and put the
options to E before building.

Two constraints that are already settled and should not be re-opened:
- **The Celebrations switch in Settings covers full-screen celebrations only** (E, 2026-09-13).
  Whether it should also gate the chime is a NEW question and worth asking; do not assume either way.
- **Haptics are not motion and fire under Reduce Motion** (§7.2). Sound is the same shape: Reduce
  Motion is not a mute switch, and iOS has no app-readable "prefers no sound" beyond the ringer.

After `-7`, strictly in order: `F-CTACelebrations-Surfaces` (E's §0b answer) → `F-FocusCard-Corners`.

## What the last session learned that will bite the next one

- **A reachability guard can only assert a call it knows to look for.** The block shipped ten of
  them, all correct, and still nearly shipped E's R-f rule with no call site — full-screen confetti
  over a run E had explicitly said should complete quietly. **The journey's own screenshot is what
  caught it.** Before writing a block's guards, list its pure helpers and `grep` each for a call
  site; it is three lines and it would have found this one.
- **Export a journey's attachments INTO `screenshots/<block>/` before choosing which matter.** The
  confetti image — the best artefact this block produced — was exported to a scratch directory and
  deleted before anyone understood what it showed.
- **`reduceMotion ? nil` is not a smell on its own.** It is correct for continuous re-layout and
  wrong for anything that appears. `PlaceRoutineScreen` contains one of each, a few lines apart,
  reading identically. A §7.2 sweep that greps for the pattern will "fix" the right one.
- **Red-check even source-reading guards.** Three lines reverted → 5 failures across 3 tests. Cheap,
  and the alternative is guards nobody has watched bite.
- **When E reverses a rule, reverse the TEST and its NAME.** Two test names and one journey name
  asserted the overturned rule this session; a name is a claim a future reader will believe.

## Owed to E, carried

**Nothing is owed on `F-CTACelebrations-6`.** What remains is older:

- The three device checks in register §A (the swipe's pop, the overlap, RM-on for `PopScale`) —
  landed, green, installed, none urgent.
- **PHOTOSENSITIVITY is a LAUNCH BLOCKER by E's own instruction** (§A and §D) — postponed, not
  closed, and it may not be closed without E.

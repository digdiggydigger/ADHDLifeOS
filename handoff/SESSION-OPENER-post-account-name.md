# Session opener — 2026-08-29

Read `claudecode.md`, `CLAUDE.md` and the memory index first. The previous opener
(`SESSION-OPENER-post-pad-balance.md`) is **CLOSED** — everything on its open list shipped.

## State

- **`main` at `a943988`**, clean, `origin/main` matches. Twelve commits on 2026-08-29.
- **Unit suite 1,843 / 0. Seven UI journeys, 7/7 green** (was five).
- **Lint debt is EXACTLY two** — `TaskDetailView` file_length 438, UITests `static_over_final_class`.
  Nine new violations appeared during the day and every one was fixed, not accepted. Hold that line.
- Emulator UP (9099 / 8080 / 9199). Device `wishwashwacky15` installed at `a943988`.
- **`TODO-CLAUDE-CODE.md`'s Current Sprint has NO open blocks.** Take direction from E.

## Three things that will cost you time if you don't know them

1. **Grep CALL SITES, not definitions.** Three shipped defects this session had one shape: a helper
   existed, was documented, was unit-tested, and *no view called it* while views hand-rolled
   drifting copies. Every one had a green test throughout — "the helper is correct" and "the view
   uses it" are different claims and only the first is unit-testable. See
   [[dead-shared-component-pattern]].

2. **Apply a fix to the whole class, not to the member that failed.** One swallowed-tap bug took
   four commits (`688be1c` → `ed3ffd4` → `f112335` → `a943988`) because each fixed only the call
   site that happened to be failing. `grep "\.tap()"` was the check to run at the first one.

3. **Measure colour, never reason about it.** Predict the offending hex, count its pixels before
   and after; 0 px is far stronger than "looks better". And **render every view change and look at
   it** — two defects this session were introduced *by* the fix and invisible to every test.
   Recipes in [[journal-pad-design]].

## Two operational rules learned the hard way

- **Run the journeys ALONE.** A run with a device build and the unit suite going concurrently
  produced two failures that didn't reproduce; it was not a clean measurement.
- **Delete the device build directory after installing** (~2 GB each). Disk hit 100% this session.
  It sits at ~185/228 GB even when tidy.

## Open list — short, nothing blocked

- `CaptureInboxService` 397/400 and `TaskDetailView` 438/400 — next feature touching either splits it.
- The FAB overlaps the nudges door's last row; `CaptureDiscMetrics.clearance` exists and is unused.
- `weekCounterweightLine` goes stale after a triage exit, deliberately — reasoning is in the code.
- **A contrast unit test is now conceivable and doesn't exist.** Colorsets are readable from a test
  bundle, so the AA arithmetic done by hand this session could be asserted in CI. Six passes on the
  journal pad were all colour; this would have caught most of them.

## Not yet seen on a real screen

The lifted night surround (`78053ce`), the journal row's mood placement (`e7c5b7c`), and the
Settings name editor (`5cca6a5`). All installed. Ask E before building further on any of them.

Read `Momentum-v3-Design-Handoff/START-HERE-post-routines.md` first — it is the current handoff.
Then `claudecode.md`, `CLAUDE.md`, and the auto-memories it names, especially
**`routine-record-gap`** and **`tab-root-rows-not-hittable`**.

**The Routines arc is MERGED and on `main`.** Nothing is mid-flight and nothing is half-built.

State gate:

```bash
git branch --show-current                # expect main
git status --short                       # must be empty
git log --oneline -1                     # expect 705fb43
git log --oneline -1 origin/main         # same SHA
swiftlint lint                           # expect 0 violations, 672 files
./scripts/emulators.sh                   # SECOND TERMINAL — UI tests SKIP without it
```

Unit suite **2,326 / 0**. UI target **19 passed / 6 failed**, all six accounted for in the
handoff. `feature/routines` is KEPT on E's word — do not delete it. E's iPhone carries a build that differs from main by a
doc comment only, so the device walk done on it counts for main.

**What Block A did, in one paragraph.** A crossing that qualifies as a routine writes NOTHING —
the run, Today's card and the journal line come into existence only when the notification is
TAPPED, and swiping the banner away leaves no trace. The whole frozen run rides the
notification's userInfo as JSON, because with nothing written there is nothing for a bare UUID to
resolve against. **Device-verified**: E walked checks 1 and 2 and both pass.

**Settled by E — do not re-litigate:** `location_events` still writes at the crossing (it IS
visible, as a Journal row, and E kept it knowing that); a departure still ends a live arrival run
at the crossing; deferral is routines-only; the arrival card is shown; the branch is kept.

Nothing is blocking. Ask E which of these to pick up:

1. **Block B — its own "Routines" section on the Tools list** (E's words). First-class entry,
   presented as Routines, NOT folded into Places. Propose first the version needing no new
   entity: one row per place+direction clearing the 2-tap-step threshold, place as subtitle.
   First-class routine RECORDS are Arc 2 and are not authorised.
2. **The routine record gap** — E's ask, parked for its own session: nothing distinguishes a
   routine OFFERED from ACCEPTED from COMPLETED, and a tap-only routine leaves zero trace either
   way. Verified in `routine-record-gap`. E must pick between cheap journal rows and a real
   `routine_runs` history.
3. **The rest of E's device walk** — checks 3–8 on
   `ON-DEVICE-CHECKLIST-blockA-2026-09-05.md`. Checks 4 and 5 are the valuable ones.

Parked, with precise next steps in the handoff — do not start unprompted: the ON-SCREEN half of
the unhittable-row defect (build a reproducer FIRST), the light-mode keyline (needs E's eyes, and
do not tune the colour again), the run-store-survives-sign-out leak, and Arc 2.

Read `Momentum-v3-Design-Handoff/START-HERE-routines-close.md` first — it is the full handoff
for this phase. Then `claudecode.md`, `CLAUDE.md`, and the auto-memories it names.

We are closing the **Routines arc** on `feature/routines` @ `07d1185`. The arc is BUILT and
round 2 is mostly walked — do not rebuild any of it.

State gate:

```bash
git status --short                            # must be empty
git log --oneline -1                          # expect 07d1185
git log --oneline -1 origin/feature/routines  # same SHA
swiftlint lint                                # expect 0 violations, 664 files
./scripts/emulators.sh                        # second terminal — UI tests SKIP without it
```

Unit suite 2,311/0. E's iPhone carries `07d1185`. The phone is on the BRANCH, not main.

**Do this first, before anything else: the UI target is NOT green and the merge is blocked on
it.** The full run reached 19 cases with 5 failures. Both routine journeys PASS, cross-test
orientation contamination is ruled out (they fail in isolation on an erased sim), and
`AccountNameJourneyUITests` is confirmed pre-existing (it fails at `2c46ee7` too). The other
four are UNKNOWN because the bisect was killed after one case. Finish it: detach to `2c46ee7`,
run the remaining four, then `git checkout feature/routines`. Suspect
`CaptureDiscClearanceUITests` if it is not pre-existing — this session added
`.padding(.vertical, 8)` to `scoreboardSection`, shifting Today's content below the ring down
16pt, and that test asserts a row is not under the capture disc.

**Round 2 is COMPLETE — all seven checks passed.** E's four decisions are answered; three are
done, and the fourth became a new block.

After the bisect, in order:

1. **Block A — deferred logging.** E's spec, confirmed twice: nothing is written at the crossing;
   the run, the card and the journal line all come into existence only when the notification is
   TAPPED, and swiping the banner away leaves no trace. The trap is that the notification carries
   only a run UUID the router resolves against the store — with nothing written there is nothing
   to resolve, so the userInfo has to widen. Full spec in the START-HERE file. One question for E
   inside it: whether the silent `location_events` record still writes at the crossing.
2. **Block B — a Routines section on the Tools tab.** E wants this in its own session. Settle
   first whether it lists PLACES that would produce a routine, or needs first-class routines —
   the latter is Arc 2, designed in outline and not authorised.
3. The merge.

Still unresolved and NOT a token problem: the island keyline does not render in LIGHT mode.
`IslandKeyline` carries `#FF6B00` in both appearance variants, and it reproduces on `07d1185`
with a fresh Activity, so the stale-build theory is dead. Suspect an iOS behaviour. Stop tuning
the colour until that is confirmed.

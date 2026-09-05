> # ⚠️ SUPERSEDED — do NOT paste this into a fresh session.
> **The current opener is `START-HERE-post-routines.md` / `PASTE-post-routines.md`.**
> This file's state gate expects `f9f7b24` on `feature/routines`; main is now `705fb43` and that
> branch is merged, so the gate here will look like a failure when nothing is wrong. Keep this
> file only as the record of HOW the arc landed.
>
> **MERGED TO MAIN `0cea871` on 2026-09-05.** This file is now the record of HOW the arc landed,
> not a to-do list. The merge is done, re-verified on main (unit **2,326/0**, lint **0/672**, both
> targets build), and pushed. `feature/routines` is KEPT, not deleted.
>
> **Still open after the merge:** E's Block A device walk (the installed build's app source is
> byte-identical to main, so that walk still counts); reinstalling `wishwashwacky15` from a MAIN
> build; **Block B** — its own "Routines" section on the Tools list; the light-mode keyline; the
> ON-SCREEN half of the unhittable-row defect; and the run-store-survives-sign-out leak.

Read `Momentum-v3-Design-Handoff/START-HERE-routines-merge.md` first — it is the full handoff
for this phase. Then `claudecode.md`, `CLAUDE.md`, and the auto-memories it names, especially
**`tab-root-rows-not-hittable`**.

We are closing the **Routines arc** on `feature/routines` @ `f9f7b24`, 18 commits ahead of main.
The arc is BUILT, round 2 is WALKED, **Block A (deferred logging) is SHIPPED**, and the five
pre-existing UI failures are BISECTED as not-ours. Do not rebuild any of it.

State gate:

```bash
git status --short                            # must be empty
git log --oneline -1                          # expect f9f7b24
git log --oneline -1 origin/feature/routines  # same SHA
swiftlint lint                                # expect 0 violations, 672 files
./scripts/emulators.sh                        # SECOND TERMINAL — UI tests SKIP without it
```

Unit suite 2,326/0. E's iPhone carries `9cff2b7` (Block A). The phone is on the BRANCH, not main.

**Where things stand, in one paragraph.** A crossing that qualifies as a routine now writes
nothing — the run, Today's card and the journal line come into existence only when the
notification is tapped, and swiping the banner away leaves no trace. The notification carries the
whole frozen run as JSON so the tap can create it. The bisect proved none of the five UI failures
is a regression from this arc. Of those five, `FirstRunJourneyUITests` is now FIXED: five
copy-pasted `while !x.isHittable { app.swipeUp() }` loops did not scroll at all (a tight swipe
loop is swallowed) and are now one settling helper.

**Do not re-litigate these — they are settled by E:** `location_events` still writes at the
crossing; a departure still ends a live arrival run at the crossing; deferral is routines-only;
the arrival card is shown, not suppressed; the branch is kept after the merge.

Next, in order:

1. **E's device walk of Block A** — checklist already sent
   (`ON-DEVICE-CHECKLIST-blockA-2026-09-05.md`). Nothing merges before it. **The notification copy
   changed on purpose — `Will journal "Leg day"`, not `Journaled` — so the older handoff's expected
   body is stale.**
2. **The merge**, on the bisect evidence ("no regressions vs `2c46ee7`") rather than a green UI
   target. `--no-ff` into main → re-verify ON main → push → reinstall the phone FROM main → ask
   before deleting the branch.
3. **Block B — its own "Routines" section on the Tools list** (E's words, 2026-09-05). First-class
   entry, presented as Routines, NOT folded into Places. Propose first the version that needs no
   new entity: one row per place+direction that clears the 2-tap-step threshold, place as
   subtitle. First-class routine RECORDS are Arc 2 and are not authorised.

Parked, with precise next steps in the START-HERE file — do not start these unprompted:

- **The ON-SCREEN half of the unhittable-row defect.** A row at y=572/584 on an 874pt screen,
  settled, not hittable. Once, everything inside `AppTabContent` was dead while the tab bar and
  capture disc were live at the same instant — that is the lead. A probe never caught it in 60+
  rounds, and run-to-run noise exceeded the effect of code changes, which is why it was parked.
  **Build a reproducer before changing anything.**
- **The light-mode keyline.** NOT a token problem — both appearance variants carry byte-identical
  `#FF6B00` and there is no light branch in the code. It needs E's device compare (check 8 on the
  checklist). Do not tune the colour again until that is answered.
- **A real leak worth a block:** the routine run store is app-local `UserDefaults` and survives
  sign-out, so one account's place name can surface on another account's Today.

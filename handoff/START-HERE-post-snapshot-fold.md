# Start here — main is protected now; the register is the queue

*Paste into a fresh Claude Code terminal. Written 2026-09-06 at the close of the session that
finished and merged the routine record (`8bee20b`), proved the swipe path on E's device, folded
the snapshot leak (`45f74f7`), and — mid-session, E's call — moved the repo to a PR landing
flow. Nothing is half-done; the queue is the register.*

**This is the ONE live opener.** If you find a second `START-HERE-*` in `handoff/`, one of them
is a trap — see CLAUDE.md, "Session handoff". Archive this file into `handoff/archive/` in the
same move that writes your successor, at the END of your session, never at the start.

## The one NEW rule before anything else

**`main` is protected: a direct `git push origin main` is REJECTED (`GH006`).** E enabled it
this session and dropped the approval requirement, so the flow is: short-lived branch → commit
→ push the branch → `gh pr create` → `gh pr merge --merge --delete-branch` → `git checkout
main && git pull --ff-only` → verify. CLAUDE.md's "Version Control" section has the full rewrite
— read it, it replaces the old push-to-main habit everywhere, WIP commits included.

## Read these, in this order

1. **`CLAUDE.md`** — especially the rewritten "Version Control"; then Repo layout, Workflow,
   Session handoff, Visual evidence.
2. **`claudecode.md`** — the TDD role definition.
3. **`handoff/OPEN-ITEMS-REGISTER.md`** — THE outstanding list, rewritten at this close-out.
   No big arc is queued: section A holds E's minutes-each decisions (three possible further
   leak-family stores, coverage re-measure, the permission-banner footer), section B the real
   work (B1 the tab-root defect first). Section C is parked on E's instruction.
4. `handoff/SESSION-OPENER-routine-record-design.md` — the design record for the merged arc,
   including the swipe-path proof and the eye rule's final form.

**Do NOT read `docs/`.** It is an archive of a legacy build and says this app runs on Supabase.

## State gate — run before anything

```bash
git branch --show-current            # expect main
git status --short                   # must be empty
git log --oneline -1                 # the close-out PR's merge commit
git log --oneline -1 origin/main     # same SHA
swiftlint lint                       # expect 0 violations, 705 files
```

Last verified: unit suite **2,458 / 0** (emulator up), lint **0 / 705**, both targets build.
E's phone was reinstalled from main at the close-out and E confirmed the eye rule on device
earlier the same day (`screenshots/routine-record/11-`…`14-`).

## Traps that matter right now

- **Erase the sim between a UI run and any unit run** — `xcrun simctl erase
  9181EBF9-0F54-4A4D-A19C-19945D1BF155`. The tray and keychain both outlive a run.
- **The tab-root not-hittable defect (register B1) is UNSOLVED** and its failing set SHUFFLES —
  never conclude from one run. Next step is written in the register: read the hidden elements'
  FRAMES in a failure dump; use or delete `HitTestProbeUITests`.
- **The swipe path is proved — do not re-litigate it.** A presented banner swiped up reports
  nothing to iOS by design; only a Notification Centre clear fires `.customDismissAction`.
  Notification Centre is NOT reachable through iPhone Mirroring, and banners may not present
  on the phone while mirroring forwards notifications to the Mac.
- **App-local stores are per-user by pattern now** (run store, arrival snapshot + cooldowns):
  scope closure read at CALL time, `clearEveryUser()` sweeps by key prefix on session end, and
  the AuthService default hook's content is pinned by a SOURCE guard
  (`RoutineRecordCallSiteTests`). Three more stores with unscoped keys are on the register —
  E's call whether they are leaks; don't fold unasked.
- **The emulator was left running** (`scripts/emulators.sh`); `firestore-debug.log` in the
  repo root is the truth for a write that "silently" failed.

# Open items register — 2026-09-06 (routine record MERGED TO MAIN; swipe path proved on device)

**This file is THE outstanding list.** It is rewritten at every session close-out (CLAUDE.md,
"Session handoff"), so it is the thing to read — and to update — rather than improvising a list
in chat. Supersedes the edition written at the previous close-out, before the review session.

Every figure below was measured this session unless marked UNVERIFIED.

## State

Branch **`main` @ `8bee20b`** (the `--no-ff` merge of `feature/routine-record`, pushed, remote
matches) · re-verified ON main: unit suite **2,454 / 0** with the emulator UP, SwiftLint
**0 / 704**, both targets build · `RoutineRecordJourneyUITests` PASSED on the finished eye rule
(206 s, erased sim; the Places door did NOT bite this run — one pass proves nothing for B2
below) · full UI target **NOT re-run** · **E's phone carries `7ad72ac`** (tree-identical to
main's merge; re-install from main at this close-out) · **E CONFIRMED the finished eye rule on
device, dark and light** (`screenshots/routine-record/11-`…`14-`) · `firestore.rules` live =
repo (E republished; verified byte-identical).

**Shipped and CLOSED this session (the review session):**
- **The eye-switch change finished**: journey green on the new rule, `00-`/`01-` re-captured,
  red-checked (3 injections → 4 + 6 + 1, each its guard), committed `7ad72ac`, E's device
  confirmation in `11-`…`14-`.
- **The swipe path PROVED on device — not broken.** Controlled experiment: test-fire via
  iPhone Mirroring wrote run `6EE57B3C…` as `offered`; E's physical Notification Centre clear
  flipped it to `dismissed`/`swipe` through the live rules. Swiping a PRESENTED banner up
  reports nothing to iOS — only a Notification Centre clear is a "swipe" — so the walk's
  `· not opened` rows were honest. Evidence: `09-`/`10-` + the design record's swipe section.
  (Also learned: Notification Centre is NOT reachable through iPhone Mirroring, and a banner
  may not present on the phone while mirroring forwards notifications to the Mac.)
- **The routine record merged**: `F-RoutineRecord-1-Ledger` + `F-RoutineRecord-2-Surfaces`,
  `--no-ff` at `8bee20b`, re-verified on main.
- **The `Home` place emoji**: closed — live data and every screenshot show `Home 🏠`.

## A · Decisions only E can make — minutes each

- [x] **Delete the merged branches** — DONE on E's word (2026-09-06): `feature/routine-record`,
      `feature/routines`, `feature/routines-tools` deleted locally and on origin, each verified
      `--merged main` first. (The previous edition said "four" — three existed; the
      app-directory and tools-tab branches were already gone.) Only `main` remains.
- [ ] **Fold the snapshot leak?** `UserDefaultsArrivalNudgeStateStore` — the third member of
      the family (run store fixed, tray fixed, snapshot open). (carried)
- [ ] **Re-measure coverage?** CLAUDE.md records **23.62% at `b1f4b6f`**, stale — the suite has
      since grown to 2,454 tests. (carried)
- [ ] **The permission-banner footer** on the Routines section. (carried)

## B · Real work, ready to start — recommended order

1. **Re-install the phone from main** — done at this close-out if the log below says so;
   otherwise the first action of the next session.
2. **The tab-root not-hittable defect (was B3), honestly restated.** The off-screen
   `AppTabContent` change did NOT hold (an identical failure on a build carrying it, hidden
   elements still in the dump). This session's journey run passed the door without it biting —
   consistent with the shuffling set, proof of nothing. Next: in a FAILURE dump, read the
   hidden elements' FRAMES (x≈10,000 or on-screen?); use or delete `HitTestProbeUITests`.
   Optionally run the full UI target once on main and record whether the unstable set moved.
3. **Arc 2 — first-class routines + the "at a time" trigger.** Not authorised. (carried)
4. **`F-Search-3-Journal`** — recommendation is to kill the block. E's call. (carried)
5. **The Live Activity design review** E parked. (carried)

## C · Parked on E's instruction — do not start unprompted

- **Places backgrounding dismiss bug** — waiting on E's iOS update. (carried)
- **App connections** — real two-way sync; Apple Notes has no iOS API. (carried)
- **LA interactive buttons**, **time-of-day triggers**, **smart skip** — smart skip has its
  data in `routine_runs`. (carried)

## D · Launch blockers — no conversation opened yet

- **Free dev account** → 7-day profiles (valid to 2026-09-10; renewed automatically at this
  session's `-allowProvisioningUpdates` build). (carried)
- **Sign in with Apple** built but dormant. (carried)

## E · Known, not work

- **Six UI-target failures**, unstable set — see B2; the full UI target was NOT re-run on main.
- **Twelve `screenshots/` folders without READMEs** — deliberately left. (carried)
- **Stale unchecked bullets inside four finished blocks.** (carried)
- **The 107-second failing test** in block 1's red-check — failure-path only, unexplained.
- **The emulator was left running** (`scripts/emulators.sh`); its logs sit in the repo root,
  gitignored. `firestore-debug.log` is where a silently failed write shows up.
- **The review-session experiment left real rows in E's journal** (test-fires at Home,
  including the 8:35 offered/cleared run). E's own data, deliberate, nothing to clean up.

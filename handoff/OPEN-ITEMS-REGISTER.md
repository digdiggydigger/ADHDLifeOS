# Open items register — 2026-09-06, true close-out (routine record merged; swipe proved; snapshot fold done; PR flow begins)

**This file is THE outstanding list.** It is rewritten at every session close-out (CLAUDE.md,
"Session handoff"), so it is the thing to read — and to update — rather than improvising a list
in chat. Supersedes the edition written at the previous close-out, before the review session.

Every figure below was measured this session unless marked UNVERIFIED.

## State

**`main` @ `8d5f6fe`** (PR #2's merge), local = remote, tree clean, only `main` exists ·
**`main` is PROTECTED as of this session (E's call): every change lands through a PR** — flow
in CLAUDE.md's rewritten "Version Control"; approval requirement dropped by E, so
`gh pr create` + `gh pr merge --merge --delete-branch` lands without a bypass · last full
verification: unit suite **2,458 / 0** with the emulator UP (at `45f74f7`), SwiftLint
**0 / 705**, both targets build · `RoutineRecordJourneyUITests` PASSED on the finished eye rule
(206 s, erased sim; the Places door did NOT bite this run — one pass proves nothing for B1
below) · full UI target **NOT re-run** · **E's phone: reinstalled from main at this close-out**
(the fold's app-code change included; E confirmed the eye rule on device earlier at `7ad72ac`,
`screenshots/routine-record/11-`…`14-`) · `firestore.rules` live = repo (E republished,
verified byte-identical) · the emulator was left running.

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
- [x] **Fold the snapshot leak** — DONE on E's word (2026-09-06, `45f74f7`): snapshot AND
      cooldowns keyed per user (scope read at call time, the run-store pattern), signed-out
      reads empty and drops writes, the session-end hook sweeps every user's keys plus the
      legacy unscoped ones. Test-first; suite 2,458 / 0; red-checked 3 → 3 + 1 + 1.
- [ ] **Three MORE possible family members, found while folding — E's call whether they are
      leaks:** `DailySummaryStore`, `FocusWidgetSnapshotStore` and `LifeAreasWidgetStore` all
      write unscoped app-local keys. UNVERIFIED whether any carries user content that survives
      a sign-out (the widget stores may be cleared elsewhere); check before folding.
- [ ] **Re-measure coverage?** CLAUDE.md records **23.62% at `b1f4b6f`**, stale — the suite has
      since grown to 2,454 tests. (carried)
- [ ] **The permission-banner footer** on the Routines section. (carried)

## B · Real work, ready to start — recommended order

1. **The tab-root not-hittable defect, honestly restated.** The off-screen `AppTabContent`
   change did NOT hold (an identical failure on a build carrying it, hidden elements still in
   the dump). This session's journey run passed the door without it biting — consistent with
   the shuffling set, proof of nothing. Next: in a FAILURE dump, read the hidden elements'
   FRAMES (x≈10,000 or on-screen?); use or delete `HitTestProbeUITests`. Optionally run the
   full UI target once on main and record whether the unstable set moved.
2. **Arc 2 — first-class routines + the "at a time" trigger.** Not authorised. (carried)
3. **`F-Search-3-Journal`** — recommendation is to kill the block. E's call. (carried)
4. **The Live Activity design review** E parked. (carried)

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

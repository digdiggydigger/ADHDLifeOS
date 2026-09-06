# Open items register — 2026-09-06 (F-RoutineRecord-1 at E's review)

**This file is THE outstanding list.** It is rewritten at every session close-out (CLAUDE.md,
"Session handoff"), so it is the thing to read — and to update — rather than improvising a list in
chat. Supersedes the 2026-09-06 end-of-session edition written before the routine-record work
began.

Every figure below was measured this session unless marked UNVERIFIED.

## State

Branch **`feature/routine-record`** (off `main` @ `ebc5865`) · working tree clean · pushed ·
unit suite **2,424 / 0** with the emulator UP (nothing skipped) · SwiftLint **0 violations in
693 files** · both targets build · full UI target **NOT re-run this session** (last known 23 / 6
on main at `ebc5865`) · E's phone still carries `1ab5ff2` (= main's app source at `ebc5865`),
which does NOT include any of this branch.

**The live opener is `handoff/START-HERE-post-foundations.md`** — the only one. It said "ask E";
E picked the routine record gap. Archive it into `handoff/archive/` in the same move that writes
its successor.

**Shipped this session, on the branch, awaiting E's review:** `F-RoutineRecord-1-Ledger` — the
`routine_runs` collection, the recorder seam, all six write points (offer at the crossing — E's
explicit exception to Block A; started/replaced at the tap; swiped through a new dismiss branch;
progressed and completed from the screen; left_place at the departure; passive endings derived on
the Journal load), and the run-store sign-out leak fix (register B2, now closed). Design record:
`handoff/SESSION-OPENER-routine-record-design.md`. Block in `TODO-CLAUDE-CODE.md`.

**Branches:** `feature/routines` and `feature/routines-tools` both merged into main, both KEPT on
E's word. `feature/routine-record` is live and unmerged.

## A · Decisions only E can make — minutes each

- [ ] **Republish `firestore.rules`.** `routine_runs` joined the generic owner-CRUD list on the
      branch. Until published, every `routine_runs` write from a device on this branch fails
      permission-denied (silently — the sites are best-effort). Publish when the branch merges,
      or before installing the branch on the phone.
- [ ] **Review F-RoutineRecord-1** (this stop). Nothing of it is visible yet — block 2 is the
      Journal rows, the header switch and the Tools last-run line. Firestore console is the only
      place to see a run document today.
- [ ] **Fold the snapshot leak?** `UserDefaultsArrivalNudgeStateStore` holds the at-place
      snapshot (place names, custom messages) under an app-local unscoped key — the same shape
      the run store had. Offered during design, not chosen; found again while building.
- [ ] **Delete the two merged branches?** (carried)
- [ ] **Re-measure coverage?** CLAUDE.md still records **23.62% at `b1f4b6f`**, now stale by
      several arcs plus this one. (carried)
- [ ] **The permission-banner footer** on the Routines section. (carried)
- [ ] **Give the `Home` place an emoji.** (carried)

## B · Real work, ready to start — recommended order

1. **`F-RoutineRecord-2-Surfaces`** — the visible half of E's ask, fully designed and queued in
   `TODO-CLAUDE-CODE.md`: three Journal entry kinds (started / finished always visible under
   Everything; offered rows only behind a new "All activity" header switch, muted), the arrival
   row kept beside them, the Tools row's last-run line, the reconciler joining the Tools load, and
   `RoutineRecordJourneyUITests` with a `screenshots/routine-record/` folder. Needs the emulator
   (`scripts/emulators.sh`) and — after the journey — **`xcrun simctl erase 9181EBF9-0F54-4A4D-A19C-19945D1BF155`
   before any unit run.**
2. **Arc 2 — first-class routines + the "at a time" trigger.** Designed in outline, NOT
   authorised. The record now exists, so the shape question this used to wait on is answered.
3. **The tab-root not-hittable defect — new angle, 2026-09-05.** Vary run ORDER against a fixed
   tree. (carried)
4. **`F-Search-3-Journal`** — UNCHECKED with "⚠ RECONSIDER FIRST"; recommendation is to kill
   the block. E's call. (carried)
5. **The Live Activity design review** E parked. (carried)

## C · Parked on E's instruction — do not start unprompted

- **Places backgrounding dismiss bug** — waiting on E's iOS update. (carried)
- **App connections** — real two-way sync; Apple Notes has no iOS API. (carried)
- **LA interactive buttons**, **time-of-day triggers**, **smart skip with prune and reorder** —
  smart skip now has its data: `routine_runs.steps[].state` + `resolved_at` per run.

## D · Launch blockers — no conversation opened yet

- **Free dev account** → 7-day provisioning profiles. (carried)
- **Sign in with Apple** built but dormant. (carried)

## E · Known, not work

- **Six UI-target failures**, unstable set. Not re-run this session. (carried)
- **Twelve `screenshots/` folders without READMEs** — deliberately left. (carried)
- **Stale unchecked bullets inside four finished blocks.** (carried)
- **The 107-second failing test.** In the red-check run only, with a regression injected,
  `JournalServiceRoutineRunsTests.testLoad_writesEachLapsedRunOnce…` took 107 s to FAIL; on the
  green tree it takes 1 ms, and no `127.0.0.1:9099` tell was in the log. Failure-path only;
  unexplained; noted so nobody bisects it.
- **The emulator is still running** in the background from this session (`scripts/emulators.sh`,
  log at the scratchpad). Block 2's journey wants it; kill it if the machine needs the memory.

# Open items register — 2026-09-06 (end of session: routine record built, unmerged)

**This file is THE outstanding list.** It is rewritten at every session close-out (CLAUDE.md,
"Session handoff"), so it is the thing to read — and to update — rather than improvising a list in
chat. Supersedes the mid-session edition written at F-RoutineRecord-1's review stop.

Every figure below was measured this session unless marked UNVERIFIED.

## State

Branch **`feature/routine-record`** (off `main` @ `ebc5865`) · working tree clean at the close-out
commit · pushed, `origin/feature/routine-record` matches · unit suite **2,453 / 0** with the
emulator UP (nothing skipped) · SwiftLint **0 violations in 704 files** · both targets build ·
`RoutineRecordJourneyUITests` **PASSED** on an erased simulator · full UI target **NOT re-run**
(last known 23 / 6 on main at `ebc5865`) · E's phone carries `1ab5ff2` (= main's app source),
which has NONE of this branch.

**The live opener is `handoff/START-HERE-routine-record-review.md`** — the only one.
`START-HERE-post-foundations.md` was consumed and is archived.

**Shipped this session, on the branch, unmerged:** both blocks of the routine record —
`F-RoutineRecord-1-Ledger` (the `routine_runs` collection, the recorder seam, six write sites,
the sign-out leak fix) and `F-RoutineRecord-2-Surfaces` (Journal rows, the "All activity" eye
switch, the Tools last-run line, the journey). Design record and build record:
`handoff/SESSION-OPENER-routine-record-design.md`. Evidence: `screenshots/routine-record/`.
Plus two defects the journey caught and this session fixed: a routine banner outliving a
sign-out, and the mechanism of the tab-root "not hittable" defect (see E below).

**Branches:** `feature/routines` and `feature/routines-tools` merged and KEPT on E's word;
`feature/routine-record` live and unmerged.

## A · Decisions only E can make — minutes each

- [ ] **Republish `firestore.rules`** — `routine_runs` is in the generic CRUD list on the branch
      and NOT live. Until published, every record write from a device on this branch fails
      permission-denied, silently. Do this before the branch reaches the phone.
- [ ] **Review the routine record on device**, then `--no-ff` merge — the opener has the walk.
      The SWIPE path (`.customDismissAction`) has never run outside unit tests; the phone is its
      first real test.
- [ ] **Fold the snapshot leak?** `UserDefaultsArrivalNudgeStateStore` holds place names and
      custom messages under an app-local unscoped key — the third member of the family (run
      store: fixed; tray: fixed; snapshot: open).
- [ ] **Delete the two merged branches?** (carried)
- [ ] **Re-measure coverage?** CLAUDE.md records **23.62% at `b1f4b6f`**, now stale by several
      arcs plus this one. (carried)
- [ ] **The permission-banner footer** on the Routines section. (carried)
- [ ] **Give the `Home` place an emoji.** (carried)

## B · Real work, ready to start — recommended order

1. **Merge the routine record** (after A's first two). Re-verify on main, re-install the phone
   from main, update this register.
2. **Re-run the full UI target once on main** after the merge. The tab-root defect's fix is on
   this branch; if the unstable failure set shrinks, register item 4 below closes. UNVERIFIED.
3. **Arc 2 — first-class routines + the "at a time" trigger.** Designed in outline, NOT
   authorised. The record exists now, so its data question is answered.
4. **The tab-root not-hittable defect** — mechanism found this session (hidden tabs' UIKit
   subtrees remain in the accessibility tree; `AppTabContent` now parks them off-screen). What
   is left is confirming it on the full UI target (item 2), then deleting `HitTestProbeUITests`
   or turning it into an assertion, as its own header asks.
5. **`F-Search-3-Journal`** — UNCHECKED with "⚠ RECONSIDER FIRST"; recommendation is to kill
   the block. E's call. (carried)
6. **The Live Activity design review** E parked. (carried)

## C · Parked on E's instruction — do not start unprompted

- **Places backgrounding dismiss bug** — waiting on E's iOS update. (carried)
- **App connections** — real two-way sync; Apple Notes has no iOS API. (carried)
- **LA interactive buttons**, **time-of-day triggers**, **smart skip with prune and reorder** —
  smart skip now has its data: `routine_runs.steps[].state` + `resolved_at` per run.

## D · Launch blockers — no conversation opened yet

- **Free dev account** → 7-day provisioning profiles. (carried)
- **Sign in with Apple** built but dormant. (carried)

## E · Known, not work

- **Six UI-target failures**, unstable set — possibly explained and fixed by this session's
  `AppTabContent` change; not re-run. (carried, now with a candidate cause)
- **Twelve `screenshots/` folders without READMEs** — deliberately left. (carried)
- **Stale unchecked bullets inside four finished blocks.** (carried)
- **The 107-second failing test** in block 1's red-check — failure-path only, unexplained,
  1 ms on the green tree. Noted so nobody bisects it.
- **The emulator was left running** from this session (`scripts/emulators.sh`); its two log
  files sit in the repo root, gitignored. Kill it if the machine needs the memory.
- **`firestore-debug.log` is where a silently failed write shows up** — the lesson of this
  session, recorded in the opener's traps.

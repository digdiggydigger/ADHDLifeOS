# Open items register — 2026-09-06 (true end of session: routine record built, eye change WIP)

**This file is THE outstanding list.** It is rewritten at every session close-out (CLAUDE.md,
"Session handoff"), so it is the thing to read — and to update — rather than improvising a list in
chat. Supersedes the edition written an hour earlier, before E's device walk and E's late call
on the eye switch.

Every figure below was measured this session unless marked UNVERIFIED.

## State

Branch **`feature/routine-record`** (off `main` @ `ebc5865`) · HEAD is a **`WIP:` commit** (the
eye-switch change, see B1) · pushed, remote matches · unit suite **2,454 / 0** with the emulator
UP · SwiftLint **0 / 704** · both targets build · `RoutineRecordJourneyUITests` last PASSED at
`13e8f0e`; on the WIP tree it has NOT passed (died at the Places door) · full UI target **NOT
re-run** · **E's phone carries `7430ea7`** (this branch, before the eye change) ·
**`firestore.rules` republished by E and verified byte-identical live.**

**The live opener is `handoff/START-HERE-routine-record-review.md`** — the only one, rewritten
at this close-out. `START-HERE-post-foundations.md` is archived.

**Shipped this session, on the branch, unmerged:** both blocks of the routine record
(`F-RoutineRecord-1-Ledger`, `F-RoutineRecord-2-Surfaces`); E's device walk done and recorded
in `screenshots/routine-record/`. Two defects found by the journey and addressed: a routine
banner outliving a sign-out (FIXED, `RoutineNotificationTray`); the tab-root not-hittable
defect (a hypothesis and an `AppTabContent` change that did NOT hold up — see B3/E).

## A · Decisions only E can make — minutes each

- [ ] **Did you swipe the `Home` banners away during the walk, or leave them?** Both offered
      rows read `· not opened`; a swipe reads `· cleared`. This decides whether the swipe path
      is broken on device (it has never run outside unit tests).
- [ ] **Confirm the eye-switch change on the phone** once it is finished and re-installed (B1).
- [ ] **Fold the snapshot leak?** `UserDefaultsArrivalNudgeStateStore` — the third member of the
      family (run store fixed, tray fixed, snapshot open). (carried)
- [ ] **Delete the two merged branches?** (carried)
- [ ] **Re-measure coverage?** CLAUDE.md records **23.62% at `b1f4b6f`**, stale. (carried)
- [ ] **The permission-banner footer** on the Routines section. (carried)
- [ ] **Give the `Home` place an emoji.** (carried — it now has 🏠 on E's phone per the
      screenshots; verify and close)

## B · Real work, ready to start — recommended order

1. **Finish the eye-switch change (WIP on the branch).** E's call: the eye hides EVERY routine
   row, not only offers. Code and unit tests done (test-first, 2,454 / 0, lint 0). Outstanding:
   the journey green on an erased sim, the design record / TODO block / screenshots README
   updated to the new rule, red-check, a real commit, phone re-install, E's confirmation.
2. **Merge the routine record** — `--no-ff`, re-verify on main, push, re-install the phone from
   main, update this register.
3. **The tab-root not-hittable defect, honestly restated.** A failure dump showed the hidden
   Today tab's elements in the accessibility tree over the Places card; `AppTabContent` was
   changed to park hidden tabs off-screen; the journey passed once; then a later run on a build
   WITH the change failed identically and the dump still listed the hidden elements. So: the
   mechanism is plausible, the fix is insufficient or misaimed, the register's earlier "found"
   is withdrawn. Next: read the hidden elements' FRAMES in a failure dump; use or delete
   `HitTestProbeUITests`.
4. **Arc 2 — first-class routines + the "at a time" trigger.** Not authorised. (carried)
5. **`F-Search-3-Journal`** — recommendation is to kill the block. E's call. (carried)
6. **The Live Activity design review** E parked. (carried)

## C · Parked on E's instruction — do not start unprompted

- **Places backgrounding dismiss bug** — waiting on E's iOS update. (carried)
- **App connections** — real two-way sync; Apple Notes has no iOS API. (carried)
- **LA interactive buttons**, **time-of-day triggers**, **smart skip** — smart skip now has its
  data in `routine_runs`. (carried)

## D · Launch blockers — no conversation opened yet

- **Free dev account** → 7-day profiles (valid to 2026-09-10 as of this session). (carried)
- **Sign in with Apple** built but dormant. (carried)

## E · Known, not work

- **Six UI-target failures**, unstable set — NOT explained by this session after all (B3).
- **Twelve `screenshots/` folders without READMEs** — deliberately left. (carried)
- **Stale unchecked bullets inside four finished blocks.** (carried)
- **The 107-second failing test** in block 1's red-check — failure-path only, unexplained.
- **The emulator was left running** (`scripts/emulators.sh`); its two logs sit in the repo
  root, gitignored. `firestore-debug.log` is where a silently failed write shows up.
- **The design record and the TODO block still say "mechanism found, fixed" for B3** and
  "started/finished always visible" for the eye — both superseded; corrected in the opener and
  here, to be corrected in those files by the next session as part of B1.

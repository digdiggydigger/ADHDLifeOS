# Start here — the routine record is merged; the register is the queue

*Paste into a fresh Claude Code terminal. Written 2026-09-06 at the close of the review session
that finished the eye-switch change, proved the swipe path on E's device, and merged the
routine record to main (`8bee20b`).*

**This is the ONE live opener.** If you find a second `START-HERE-*` in `handoff/`, one of them
is a trap — see CLAUDE.md, "Session handoff". Archive this file into `handoff/archive/` in the
same move that writes your successor, at the END of your session, never at the start.

## Read these, in this order

1. **`CLAUDE.md`** — Repo layout, Workflow, Session handoff, Visual evidence.
2. **`claudecode.md`** — the TDD role definition.
3. **`handoff/OPEN-ITEMS-REGISTER.md`** — THE outstanding list, rewritten at this close-out.
   There is no big queued arc: sections A (E's minutes-each decisions) and B (real work,
   B2 the tab-root defect first) are the queue. Section C is parked on E's instruction.
4. `handoff/SESSION-OPENER-routine-record-design.md` — the design record for the arc that just
   merged, including the swipe-path proof and the eye rule's final form.

**Do NOT read `docs/`.** It is an archive of a legacy build and says this app runs on Supabase.

## State gate — run before anything

```bash
git branch --show-current            # expect main
git status --short                   # must be empty
git log --oneline -1                 # the close-out commit, or 8bee20b
git log --oneline -1 origin/main     # same SHA
swiftlint lint                       # expect 0 violations, 704 files
```

On main: suite **2,454 / 0** (emulator up), lint **0 / 704**, both targets build. E's phone
carries the merged tree and E confirmed the eye rule on device in both appearances
(`screenshots/routine-record/11-`…`14-`).

## Traps that matter right now

- **Erase the sim between a UI run and any unit run** — `xcrun simctl erase
  9181EBF9-0F54-4A4D-A19C-19945D1BF155`. The tray and keychain both outlive a run.
- **The tab-root not-hittable defect (register B2) is UNSOLVED.** The off-screen
  `AppTabContent` change did not hold; the register has the honest next step (read the hidden
  elements' FRAMES in a failure dump). Do not trust a single passing run — the failing set
  shuffles.
- **The swipe path is proved — do not re-litigate it.** A presented banner swiped up reports
  nothing to iOS by design; only a Notification Centre clear is a "swipe". Notification Centre
  is NOT reachable through iPhone Mirroring, and banners may not present on the phone while
  mirroring forwards notifications to the Mac.
- **The emulator server log is the truth for a write that "silently" failed** —
  `firestore-debug.log` in the repo root.

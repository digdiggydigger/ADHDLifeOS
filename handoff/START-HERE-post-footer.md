# Start here — the register's section A is one question deep; nothing in B is authorised

*Paste into a fresh Claude Code terminal. Written 2026-09-07 at the close of the session that
cleared E's queue (DailySummary sweep #13, LifeOS widget copy #14), ran the UI baseline green
(and killed the AutoFill family's second costume en route, #15), reinstalled the phone twice,
and closed the register's oldest carried item — the Routines permission footer, ruled on by E,
built TDD-first (#18), and device-confirmed ("the footer works", evidence #20). Nothing is
half-done. The queue is the register; the only pending decision is the coverage re-measure.*

> **UPDATE 2026-09-07, later the same day — the coverage re-measure below is DONE** (PR #22:
> app target **24.58% (11,050/44,961)** over 2,469 tests, CLAUDE.md updated, four stale doc
> claims corrected). Section A of the register has moved on; **read
> `handoff/OPEN-ITEMS-REGISTER.md` for the current list**, not the summary in this file's
> header. Everything else here — the traps, the state gate — still holds.

**This is the ONE live opener.** If you find a second `START-HERE-*` in `handoff/`, one of
them is a trap — see CLAUDE.md, "Session handoff". Archive this file into `handoff/archive/`
in the same move that writes your successor, at the END of your session, never at the start.

## Read these, in this order

1. **`CLAUDE.md`** — Version Control (every change lands through a PR), Workflow, Session
   handoff, Visual evidence.
2. **`claudecode.md`** — the TDD role definition.
3. **`handoff/OPEN-ITEMS-REGISTER.md`** — THE outstanding list, rewritten at this close-out.
   Section A holds ONE decision (coverage re-measure); section B has nothing authorised —
   wait for E's direction.
4. `handoff/SESSION-OPENER-routine-record-design.md` — still the newest design record.

**Do NOT read `docs/`.** It is an archive of a legacy build and says this app runs on Supabase.

## State gate — run before anything

```bash
git branch --show-current            # expect main
git status --short                   # must be empty
git log --oneline -1                 # this close-out PR's merge commit
git log --oneline -1 origin/main     # same SHA
swiftlint lint                       # expect 0 violations, 706 files
```

Last verified: unit suite **2,469 / 0** (emulator up), lint **0 / 706**, both targets build,
full UI target effectively green (28/29 batch pass + the 29th fixed and proven 3×), and
`ToolsRoutinesJourneyUITests` 3 / 0 after the footer change. **E's phone tracks main at
`a3e4bde`** — the merges since touched no Swift, so no reinstall is owed.

## Traps that matter right now

- **The Automatic Strong Password pane (fixed #15 — do not re-litigate):** iOS 26.5
  deterministically covers a Create-account password field's keyboard slot; `app.keyboards`
  matches NOTHING while it is up, and it reproduces on a freshly erased sim. There is NO
  reliable route back to the visible keyboard (re-tap, the pane's ✕, and typing all falsified
  in runs). Assert the INPUT SURFACE, never the keyboard — full story in `UITestAutofill.swift`.
- **The DEBUG test-fire bypasses the master switch and cooldown BY DESIGN** (its dialog says
  so). Notifications arriving while Arrival nudges is off are that bypass, not the gate
  failing — `screenshots/routines-permission-footer/README.md` has the worked example.
- **Erase the sim between a UI run and any unit run** — `xcrun simctl erase
  9181EBF9-0F54-4A4D-A19C-19945D1BF155`. Unconditional, chained onto the run itself.
- **Run long UI work one xcodebuild at a time, foreground/scoped** — six class batches worked
  2026-09-07; the memory-watchdog rule stands.
- **The emulator was left running** (`scripts/emulators.sh`); if it is down after a reboot,
  restart it before any journey — they SKIP without it.
- **`UIFullRun.xcresult` is deletable at E's word** (its retention condition is met);
  `UIBaseline-*.xcresult` are the 2026-09-07 evidence bundles. All gitignored, repo root.

# Start here — E's queue is clear; the baseline is green; the phone is behind main

*Paste into a fresh Claude Code terminal. Written 2026-09-07 at the close of the queue-clearing
session (PRs #13–#16): the DailySummary session-end sweep, the "Open LifeOS once…" widget copy
(E picked the word), the post-fix full-UI-target baseline — 29 tests, and its one failure
root-caused (iOS 26.5's Automatic Strong Password pane, the AutoFill family's second costume)
and fixed in #15. Nothing is half-done; the queue is the register, and nothing in section B is
authorised to start.*

**This is the ONE live opener.** If you find a second `START-HERE-*` in `handoff/`, one of
them is a trap — see CLAUDE.md, "Session handoff". Archive this file into `handoff/archive/`
in the same move that writes your successor, at the END of your session, never at the start.

## Read these, in this order

1. **`CLAUDE.md`** — Version Control (every change lands through a PR), Workflow, Session
   handoff, Visual evidence.
2. **`claudecode.md`** — the TDD role definition.
3. **`handoff/OPEN-ITEMS-REGISTER.md`** — THE outstanding list, rewritten at this close-out.
   **Section A's first item is the natural first act: E's phone carries `e4fe956` and PRs
   #13–#15 are not on it — and the free-account profile expires 2026-09-10**, so a reinstall
   before then renews it. Section B has nothing authorised; wait for E's direction.
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

Last verified: unit suite **2,465 / 0** (emulator up), lint **0 / 706**, both targets build,
full UI target effectively green (28/29 in the batch pass + the 29th fixed and proven 3×).

## Traps that matter right now

- **The Automatic Strong Password pane (found 2026-09-07, fixed #15 — do not re-litigate):**
  iOS 26.5 deterministically covers a Create-account password field's keyboard slot with
  `PMSafariStreamlinedStrongPasswordViewController` — `app.keyboards` matches NOTHING while it
  is up, and it reproduces on a freshly erased sim. Journeys that TYPE pass straight through;
  there is NO reliable route back to the visible keyboard (re-tap, the pane's ✕, and typing
  all falsified in runs — the ✕ drops field focus, typing latches no-software-keyboard).
  `testRenderSignUpForm` asserts the input surface instead; the full story is in
  `UITestAutofill.swift`'s note. If some other test ever waits on `app.keyboards` after
  focusing a password field, it has met this pane.
- **Erase the sim between a UI run and any unit run** — `xcrun simctl erase
  9181EBF9-0F54-4A4D-A19C-19945D1BF155`. Unconditional, chained onto the run itself.
- **Run long UI work one xcodebuild at a time, foreground/scoped** — six class batches worked
  2026-09-07; the 2026-09-06 memory watchdog never struck, but the rule stands.
- **The emulator was left running** (`scripts/emulators.sh`); if it is down after a reboot,
  restart it before any journey — they SKIP without it.
- **`UIBaseline-*.xcresult`** (repo root, gitignored) are the baseline's evidence bundles;
  `UIFullRun.xcresult`'s retention condition is met — deletable at E's word.

# Start here — the defect sweep is done; the queue is the register

*Paste into a fresh Claude Code terminal. Written 2026-09-06 at the close of the defect-sweep
session (PRs #4–#11): the widget-store session-end fold, the tab-root not-hittable defect's
root cause AND its harness fix, and the capture-disc clearance bar-band fix all landed on
`main`; E's phone was then brought onto main and the fold device-confirmed
(`screenshots/widget-session-fold/`). Nothing is half-done; the queue is the register, and
its section B items 1 and 2 are E's own queued instruction.*

**This is the ONE live opener.** If you find a second `START-HERE-*` in `handoff/`, one of
them is a trap — see CLAUDE.md, "Session handoff". Archive this file into `handoff/archive/`
in the same move that writes your successor, at the END of your session, never at the start.

## Read these, in this order

1. **`CLAUDE.md`** — Version Control (every change lands through a PR), Repo layout, Workflow,
   Session handoff, Visual evidence.
2. **`claudecode.md`** — the TDD role definition.
3. **`handoff/OPEN-ITEMS-REGISTER.md`** — THE outstanding list, rewritten at this close-out
   and kept current through the same evening (phone reinstalled from main at `e4fe956` via
   `devicectl`, E's word — the device TRACKS MAIN; the widget fold is DEVICE-CONFIRMED,
   evidence in `screenshots/widget-session-fold/`, do not re-verify). **Section B's items 1
   and 2 are E's queued instruction for THIS session** — the `DailySummaryStore` sweep
   (authorised: sweep it) and the "Open Momentum once…" widget copy (the replacement word is
   still E's to pick — propose "LifeOS" and wait for the nod). The post-fix full-UI-target
   baseline run follows them.
4. `handoff/SESSION-OPENER-routine-record-design.md` — still the newest design record.

**Do NOT read `docs/`.** It is an archive of a legacy build and says this app runs on Supabase.

## State gate — run before anything

```bash
git branch --show-current            # expect main
git status --short                   # must be empty
git log --oneline -1                 # this close-out PR's merge commit
git log --oneline -1 origin/main     # same SHA
swiftlint lint                       # expect 0 violations, 705 files
```

Last verified: unit suite **2,462 / 0** (emulator up), lint **0 / 705**, both targets build.

## Traps that matter right now

- **Three defects were root-caused and fixed this session — do not re-litigate any of them:**
  1. The tab-root "not hittable" family was **iOS's own AutoFill "Save Password?" sheet**
     interposing late after fresh-credential sign-ins; while it is up, hit-tests die across
     the WHOLE app window. It is addressable ONLY through the app's tree — `app.alerts` is
     the wrong TYPE, `springboard.sheets` the wrong PROCESS, both falsified in runs. The
     sweep (`UITestAutofill.swift`) is woven into every retry helper and prints `[AUTOFILL]`
     when it fires — that print in a log is proof a prompt was live. The hidden-tabs
     hypothesis is DEAD.
  2. The clearance axes are SPLIT: `CaptureDiscMetrics.clearance` (92) is the TRAILING
     number; `bottomClearance` (derived, 158) is the bottom inset. `hasSearchRow` was deleted
     because the field shares the disc's band — never reintroduce it.
  3. A frame that never moves under swipes at LAUNCH means content has not arrived, not rest —
     bring elements into reach with `scrollUntilHittable` before measuring.
- **The 8GB machine's memory watchdog kills BACKGROUND UI runs mid-test** (twice on
  2026-09-06, ~70% free between runs, no auth churn — not the poisoned-sim signature). Run
  long UI work FOREGROUND and scoped; check the log tail for `127.0.0.1:9099` before blaming
  the sim either way.
- **Erase the sim between a UI run and any unit run** — `xcrun simctl erase
  9181EBF9-0F54-4A4D-A19C-19945D1BF155`. Unconditional, chained onto the run itself.
- **The emulator was left running** (`scripts/emulators.sh`); if it is down after a reboot,
  restart it before any journey — they SKIP without it. `firestore-debug.log` in the repo
  root is the truth for a write that "silently" failed.
- **`UIFullRun.xcresult`** (repo root, gitignored) is the session's evidence bundle — both
  root causes were read from its automatic "App UI hierarchy" attachments. Xcode captures
  those on every UI failure; read them before theorising.

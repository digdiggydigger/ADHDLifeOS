# Start here — the register's section A is one DECISION deep; nothing in B is authorised

*Paste into a fresh Claude Code terminal. Written 2026-09-07 at the close of the session that
answered the register's oldest carried item with a number (the coverage re-measure, PR #22),
found four stale CLAUDE.md claims doing it, and then closed the drift that sweep exposed
(F-AdapterDrift, PR #23 — all four adapters 0/41/71/80% → **100%**). Nothing is half-done. No
Swift under `ADHD LifeOS/` changed, so E's phone is still current.*

**This is the ONE live opener.** If you find a second `START-HERE-*` in `handoff/`, one of
them is a trap — see CLAUDE.md, "Session handoff". Archive this file into `handoff/archive/`
in the same move that writes your successor, at the END of your session, never at the start.

## Read these, in this order

1. **`CLAUDE.md`** — Version Control (every change lands through a PR), Workflow, Session
   handoff, Visual evidence. Its **"Coverage reality"** section was rewritten this session and
   is current; read it before quoting any coverage figure.
2. **`claudecode.md`** — the TDD role definition.
3. **`handoff/OPEN-ITEMS-REGISTER.md`** — THE outstanding list, fifth edition, rewritten at this
   close-out. Section A holds ONE decision; section B has nothing authorised — wait for E.
4. `handoff/SESSION-OPENER-routine-record-design.md` — still the newest design record.

**Do NOT read `docs/`.** It is an archive of a legacy build and says this app runs on Supabase.

## State gate — run before anything

```bash
git branch --show-current            # expect main
git status --short                   # must be empty
git log --oneline -1                 # expect 29b5252 (PR #23 merge) or later
git log --oneline -1 origin/main     # same SHA
swiftlint lint                       # expect 0 violations, 710 files
```

Last verified: unit suite **2,488 / 0** (emulator up), lint **0 / 710**, app target
**24.68% (11,095/44,961)** at `9f6381e`. **E's phone tracks main at `a3e4bde`** — everything
merged since touched tests, `handoff/` and `CLAUDE.md` only, so no reinstall is owed.

## What is actually next

**Nothing is authorised.** E's answer to "what next" ended this session; do not start B
unprompted. When E does pick, the recommended item is **B4, the widget extension** — 9.43%
(209/2,216), now the worst-covered target and the only one whose ratio has FALLEN. It is the
same shape as the adapter work just finished, and the recipe below transfers directly.

## Traps that matter right now

- **`xccov view --file` needs `--archive`.** Without it you get **"unrecognized file format"**,
  which reads like a corrupt bundle rather than a missing flag. The full form is
  `xcrun xccov view --archive --file <abs path> <bundle>`, and it is the ONLY way to see the
  `(col, hits, 0)` region rows.
- **The last uncovered unit in a file is often a partial REGION, not a whole line.**
  `FirebaseJournalClientAdapter` sat at 99.02% with **zero** fully-uncovered lines — the gap was
  one `??` branch. A line-level sweep will tell you a file is finished when it is not.
- **A fake with no error hook makes a `catch` branch untestable, and the report blames the
  adapter.** Check the double before concluding the code under test is under-covered.
- **A FAILING test in this project takes 35–43 seconds** while the same suite passes in under a
  second. Reproduced twice this session, no `9099` in either log, still unexplained. **Budget for
  it in a red-check; do not read it as a hang.**
- **`TestResults.xcresult` ALREADY EXISTS in the repo root, and CLAUDE.md's documented test
  command writes to that exact path** — so running it verbatim fails *after* paying for the whole
  build. Pass a dated `-resultBundlePath`, or clear the bundles (a section-A decision for E).
- **Erase the sim between a UI run and any unit run** — `xcrun simctl erase
  9181EBF9-0F54-4A4D-A19C-19945D1BF155`. Unconditional, chained onto the run itself. It did not
  bite this session (no `127.0.0.1:9099` in any log) because no UI target was run.
- **Run long UI work one xcodebuild at a time, foreground/scoped** — the memory-watchdog rule
  stands.
- **The emulator was left running** (`scripts/emulators.sh`); if it is down after a reboot,
  restart it before any journey — they SKIP without it, and the four `FirebaseManager+*`
  integration tests skip too, which silently changes what a coverage run measures.
- **Eighteen `.xcresult` bundles sit in the repo root**, all gitignored, boot disk ~17 GB free.
  Deletable at E's word only.

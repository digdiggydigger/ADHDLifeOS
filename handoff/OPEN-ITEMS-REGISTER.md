# Open items register — 2026-09-07, coverage re-measure close-out (fourth edition today; the previous three covered the queue-clear, the UI baseline, and the permission footer)

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding — so it is the thing to read, and
to update, rather than improvising a list in chat. Supersedes the three earlier editions.

Every figure below was measured this session unless marked (carried).

## State

**`main` @ `f0b7c5c`** at session start; this edition lands on top as PR #22, the session's
first · local = remote, tree clean, only `main` exists · every change lands through a PR ·
**unit suite 2,469 / 0** and **SwiftLint 0 / 706**, both re-run this session at `f0b7c5c` ·
the coverage run took **33.6 seconds** with no `127.0.0.1:9099` in the log — the sim was
clean, the poison rule held · the **emulator was UP** for the measurement, so the four
`FirebaseManager+*` integration tests RAN rather than skipped · **E's phone TRACKS MAIN at
`a3e4bde`**; the merges since touched no Swift, so no reinstall is owed · `firestore.rules`
untouched · the emulator was left running.

**Shipped and CLOSED this session:**
- **The coverage re-measure** (PR #22) — the register's last section-A item, carried since the
  first edition, now answered with a number instead of an estimate. Bundle:
  `Coverage-2026-09-07.xcresult` (repo root, gitignored).

```
ADHD LifeOS.app              24.58%  (11050/44961)     was 23.62%  (8673/36721)
ADHD LifeOSTests.xctest      95.97%  (38570/40191)     was 97.21%  (27728/28523)
ADHD LifeOSUITests.xctest     0.00%  (0/2751)          skipped in the standard run by design
FocusTimerWidgetExtension     9.43%  (209/2216)        was 10.97%  (193/1759)
```

  **These two app-target ratios ARE comparable, and the old note in CLAUDE.md would have said
  they are not.** The denominator moved 36,721 → 44,961 because the *tree grew* (310 → 380
  Swift files), not because the *measurement extent* changed as it had on 2026-08-30. Both
  runs measured 100% of the app target. Covered lines rose **+27.4%** against a denominator up
  **+22.4%** — coverage grew slightly faster than the code. CLAUDE.md's rule is now sharpened
  rather than repeated: establish WHY a denominator moved before either comparing the ratios
  or refusing to.

- **Four stale CLAUDE.md claims the sweep disproved**, all corrected in the same PR: the
  adapter coverage claim (below), adapters thirteen → **fourteen**, `FirebaseManager+` files
  fourteen → **sixteen**, subcollections ten → **eleven** (`routine_runs` was missing, and
  `catalog/{docId}` — the one non-per-user path — was unrecorded), and the SwiftUI view-body
  figure ~7,000 → the measured **14,993 lines at 3.21%**.

## A · Decisions only E can make — minutes each

- [x] **Re-measure coverage.** DONE this session — figures above, CLAUDE.md updated.
- [ ] **Close the Firebase adapter drift?** See B4. It is ~45 lines and half a block's work;
      the question is only whether it jumps the queue ahead of Arc 2.
- [ ] **Delete the spent `.xcresult` bundles?** Fifteen sit in the repo root (all gitignored):
      `UIFullRun` (retention condition met), `UIBaseline-1..9`, `GreenLandscape`,
      `SweepLandscape`, `RoutineJourneyEye`, `TestResults`, `UITestResults`. The boot disk is
      down to **17 GB free**. Say the word and they go; `Coverage-2026-09-07.xcresult` stays.

## B · Real work, ready to start — recommended order

1. **Arc 2 — first-class routines + the "at a time" trigger.** Not authorised. (carried)
2. **`F-Search-3-Journal`** — recommendation is to kill the block. E's call. (carried)
3. **The Live Activity design review** E parked. (carried)
4. **NEW — close the Firebase adapter drift.** Four adapters fell below the 92–100% bar that
   held on 2026-08-30, and all four arrived with arcs that shipped after it:

```
FirebaseAppDirectoryClientAdapter    0.00%  (0/6)      ← never instantiated in any test
FirebasePlacesClientAdapter         41.67%  (5/12)
FirebaseJournalClientAdapter        71.57%  (73/102)
FirebaseHomeClientAdapter           80.00%  (12/15)
```

   The other twelve hold at 91.89–100%. **The architectural seam is intact** —
   `grep "private let manager: FirebaseManager"` still returns nothing — so this is test
   REACH, not design, and the whole shortfall is ~45 lines against existing recording fakes.
   `FirebaseAppDirectoryClientAdapter` at 0/6 is the one that matters: it is the pattern in
   `dead-shared-component`'s family — a type nothing exercises.
5. **NEW — the widget extension went backwards.** 10.97% → 9.43%: sixteen newly covered lines
   against 457 new executable ones. Widget code shipped faster than its tests. Smaller than B4
   and lower value, but it is the only target whose ratio actually FELL.

## C · Parked on E's instruction — do not start unprompted

- **Places backgrounding dismiss bug** — waiting on E's iOS update. (carried)
- **App connections** — real two-way sync; Apple Notes has no iOS API. (carried)
- **LA interactive buttons**, **time-of-day triggers**, **smart skip** — smart skip has its
  data in `routine_runs`. (carried)

## D · Launch blockers — no conversation opened yet

- **Free dev account** → 7-day profiles; the clock restarted with the 2026-09-07 04:28 build,
  so roughly valid to **2026-09-14**. (carried)
- **Sign in with Apple** built but dormant. (carried)

## E · Known, not work

- **The 70% coverage bar is arithmetically out of reach without UI tests, and now there is a
  number for why.** 108 of the app target's 342 measured files sit at exactly 0% — **29,513
  lines, 66% of the entire denominator**. The largest are `NudgesView` (0/884),
  `HomeAccessoryStrips` (0/752), `LogComposerView` (0/718), `TaskListView` (0/711),
  `QuickCaptureComponents` (0/677). Unit tests are the wrong tool; the UI tests that would
  reach them are skipped in the standard run by design.
- **The emulator harness held its ground**: `+Tags` 97.67%, `+Seed` 98.31%, `+Storage` 95.83%,
  `+AccountDeletion` 90.20% — identical to 2026-08-30, no drift.
- **The watch-list is EMPTY.** (carried)
- **The strong-password pane is environmental** — full story in `UITestAutofill.swift`.
  (carried)
- **The DEBUG test-fire bypasses the master switch and cooldown BY DESIGN** — its dialog says
  so; `screenshots/routines-permission-footer/README.md` has the worked example. (carried)
- **`START-HERE-post-footer.md` is still the ONE live opener**, and it is deliberately NOT
  archived: no successor has been written, because E has not asked for the handoff. Its
  section-A line ("the only pending decision is the coverage re-measure") is now spent — a
  note at its head says so and points here.
- **Twelve `screenshots/` folders without READMEs** — deliberately left. (carried)
- **Stale unchecked bullets inside four finished blocks.** (carried)
- **The 107-second failing test** in routine-record block 1's red-check — failure-path only,
  unexplained. (carried)
- **The emulator was left running** (`scripts/emulators.sh`); `firestore-debug.log` in the
  repo root is the truth for a silently failed write. (carried)

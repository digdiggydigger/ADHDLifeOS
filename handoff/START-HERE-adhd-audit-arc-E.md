# START HERE — arc E (Today), from `F-E1-WeeklyChain`.

*Written 2026-09-24 by the session that built `F-D3-TasksAnytimeRow` and CLOSED arc D. A disposable
pointer: archive it when you write your successor. Its predecessor,
`archive/START-HERE-adhd-audit-arc-D3-anytime.md`, is spent.*

**E's standing instruction:** *"You must ensure to maintain seamless continuity in context and
memory into the new session."*

## 0. Before anything else

1. **Check the register against this brief:** `git log --oneline -8` and
   `handoff/OPEN-ITEMS-REGISTER.md`'s header (edition 82). If E has sent the arc-D verdicts since,
   they are recorded there and in build-log session 11. **If they are NOT recorded and E has
   sent them, record them FIRST** (per block, register + build log), before any arc-E code.
2. **Branch:** `git checkout main && git pull --ff-only && git checkout -b feature/adhd-e1-chain`.
3. **Read:** CLAUDE.md (Per-arc bypass, the build-loop economies, §7), `claudecode.md`, the arc-E
   preamble and **`### FEATURE: F-E1-WeeklyChain`** in `TODO-CLAUDE-CODE.md`, build-log session 11,
   register edition 82. Memory: `per-arc-bypass`, `adhd-audit-build-progress`,
   `test-vacuity-mutation-check` (it bit AGAIN in D3, see §3), `dead-shared-component-pattern`.
4. **Emulator:** `./scripts/emulators.sh --import scripts/audit/emulator-state` (restart it if it
   has been up for hours: memory `emulator-freshness`). **Erase** the unit simulator
   (`9181EBF9…`, iPhone 17 Pro 26.5) ONCE before the first unit run.

## 1. Arc E — build order E1 → E2 → E3 → E4 → E5, back to back (per-arc bypass)

- **Every Step 0 in arc E is ANSWERED** (E, 2026-09-24: *"take the recommendations as written"*;
  each is marked **"E DECIDED 2026-09-24"** in its block). **E1 has no Step 0 at all: straight to
  code.** Never re-ask an answered question.
- E3 is load-bearing (Today collapses to one card); E1/E2 feed it; E4/E5 build on what it leaves.
- **The mid-arc stops are the four in CLAUDE.md** (F-F1's Plan-Mode round and F-F5's render pass
  are arc F's, not E's). The two that can bite here: a finding that would change a design E chose
  (→ `AskUserQuestion`, never decide it), and a red gate that won't go green.
- At the arc-E close: coverage once, install on the phone FIRST, then `handoff/ARC-REVIEW-E.md`
  (one numbered checklist, RM-on items grouped so E flips it once, a verdict line per block).

## 2. What is owed to E right now (from the arc-D close)

- **The arc-D phone pass**, `handoff/ARC-REVIEW-D.md`: D1, D2, D3 in one pass, Reduce Motion OFF
  throughout. **The phone carries `ca06c04`** (PR #202, installed and launched 2026-09-24).
- **The chevron question** (`apple-design`, D3): the house fold's ▲ folded / ▼ open (E, 2026-08-28)
  matches neither of Apple's two disclosure conventions in `disclosure-controls.md`. It was put to
  E at the close. Whatever E answers is a change to a SHARED control (Home, Journal, Tasks), so it
  is its own small block, never folded into an arc-E block unasked. See register §A.

## 3. Lessons from D3 the next blocks will meet

- **A `contains` check is vacuous when the mutation is a SUPERSET of the pinned line.** D3's sprint
  guard passed a build that widened `showsSprintStart` with `|| …anytime`, and only the mutation
  red-check caught it. Pin the whole line (or the parsed expression), then mutate BOTH ways.
- **Never write a file while a scripted red-check chain is building.** A UI test written mid-chain
  broke the build, so mutation E never ran, and `test-without-building` silently reused mutation
  C's BINARY for the next two source-read checks. Their "failures" were contamination.
- **UI render chains need a watchdog.** `xcodebuild` hung for 9+ minutes after a failed UI test
  (diagnostics collection). `render2.sh`'s pattern: wait for "Test Suite 'Selected tests'", give it
  120s, then kill.
- **A drag that starts on the bottom row at Accessibility XL is the HOME gesture.** A passing test
  attached a SpringBoard frame. Assert `app.state == .runningForeground` after any drag.
- **The restored sign-in breaks an AX-size UI run** ("Settings opened but presented no sign-out
  control"): erase the simulator, warm it up (launch Settings, wait 60s), then run the AX pass.

## 4. What arc D left that arc E must NOT undo

- **Anytime (`F-D3`):** undated open tasks are Momentum's folded tail; `tasks.anytimeCollapsed`
  defaults TRUE; beyond-tomorrow stays off the board (round 8b). Arc G's "Set aside · N" copies this
  shape (`TasksAnytimeHeader` + a stored fold), and must not invent a second one.
- **E's D2 calls:** "Let it settle" (never re-focus the composer title), "Keep the panel".
- Everything earlier openers froze: `peekStep = 14`, `floatingPaddingHorizontal = 12`, the tab bar,
  the capture disc, the appearance override, the Confirm RM waiver, no soft-delete confirms, E's tag
  decisions, Time defaults to 15 min, contrast HELD for the colour arc.

## 5. State you inherit — verify, don't assume

- `main` @ the merge of the arc-D close chore (after `ca06c04`). Suite **3,344 / 0**, SwiftLint
  **0 / 895**, clean build-for-testing SUCCEEDED, arc-D coverage **30.08% (15,101/50,195)**.
- Simulators: `9181EBF9…` (17 Pro, 26.5) for unit runs; `0ACE7E5C…` (17 Pro, 27.0) for UI renders,
  ERASED at the D3 close; the 18.0 floor sim for any `#available` block.

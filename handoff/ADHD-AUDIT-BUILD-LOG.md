# ADHD UX audit — the build log across sessions

*Opened 2026-09-19 at E's instruction, when the audit closed and the build began: the work is 31
blocks over many sessions, and E asked that **each session's progress be logged and carried in
memory, so every future session starts with full context.** This file is the thread. It is
PERMANENT — never archived, never pruned.*

**Read this file second, after the live `handoff/START-HERE-*` opener.** The opener says what to
build next; this file says what has happened so far and what is still owed.

## Where everything lives

| what | where |
|---|---|
| **The specs** — all 31 blocks | `TODO-CLAUDE-CODE.md`, section "The ADHD UX audit's seven arcs" |
| **The decisions** — E's words, rounds 1–10 | `handoff/SESSION-OPENER-adhd-ux-audit-design.md` |
| **The evidence** — findings §A–§M | `handoff/ADHD-UX-AUDIT-WORKING-FINDINGS.md` |
| **The research** — graded, cited by § | `handoff/SESSION-OPENER-adhd-ux-audit-research.md` |
| **The boards** — `52`–`68` | `screenshots/adhd-ux-audit/README.md` |
| **The outstanding list** | `handoff/OPEN-ITEMS-REGISTER.md` |
| **This thread** | you are reading it |
| **Memory** | `adhd-audit-build-progress`, `adhd-ux-audit-arc`, `build-in-a-fresh-session` |

## The close-out contract — every build session does all six, before it ends

1. Mark the block `[x] COMPLETED` in `TODO-CLAUDE-CODE.md`, and append a **"Built <date>, and where it
   departs from the spec"** note. Every departure is deliberate and named; that note is how the next
   session learns what the spec got wrong.
2. **Add a session entry to this file** (the template is at the bottom) and update the block's row in
   the table: status, the landing SHA or PR, and what is owed to E.
3. Update the memory file `adhd-audit-build-progress` with one line: what landed, what is owed, and
   which block is next.
4. Rewrite `handoff/OPEN-ITEMS-REGISTER.md` with the new edition.
5. Write the successor `handoff/START-HERE-*` and `git mv` the spent one into `handoff/archive/` in
   the same commit. **Exactly one live opener at a time.**
6. Land through a PR and paste the verification that `origin/main` carries the work.

**A session that stops mid-block still does 2, 3 and 5** — a `WIP:` commit, an honest entry saying
where it stopped and what is half-done, and an opener that resumes rather than restarts.

## Status

**Nothing is built yet.** The audit's three sessions produced records, evidence and specs only; no
app Swift has changed. Suite **3,085 / 0** and SwiftLint **0 / 831** at `061dbaa` are carried, not
re-run; the next session to touch Swift re-measures.

**Build order** (E chose C first; the rest is the proposal in the specs' intro):
**C → D → E → F → A → B → G.**

## The 31 blocks

`—` in *landed* means not built. *Owed to E* is the device look, the Reduce-Motion-on pass, or a Step 0 answer.

### Arc C · Nothing lost

| block | what it is | status | landed | owed to E |
|---|---|---|---|---|
| `F-C1-UndoCapsule` | one undo capsule, in the disc row, for every task close | NOT STARTED | — | — |
| `F-C2-DraftsToInbox` | unsent text goes to the inbox; Cancel becomes Close; task detail autosaves | NOT STARTED | — | — |
| `F-C3-RecentlyDeleted` | soft delete for tasks and captures; one row in Tools | NOT STARTED | — | — |
| `F-C4-TagsRecentlyDeleted` | tags in Recently Deleted; hidden links, restore-to-everywhere, merge | NOT STARTED | — | — |

### Arc D · The composer

| block | what it is | status | landed | owed to E |
|---|---|---|---|---|
| `F-D1-ComposerBothDoors` | one composer, both doors, and the settled content | NOT STARTED | — | — |
| `F-D2-ComposerKeyboardLayout` | L3 rides the keyboard; AX3 falls back; the Date segment | NOT STARTED | — | — |
| `F-D3-TasksAnytimeRow` | the "Anytime · N" row on the Momentum board | NOT STARTED | — | — |

### Arc E · Today

| block | what it is | status | landed | owed to E |
|---|---|---|---|---|
| `F-E1-WeeklyChain` | the weekly active-day chain, goals off until set, and the gain-framed Close button | NOT STARTED | — | — |
| `F-E2-NextStepField` | the task's "Next step" field | NOT STARTED | — | — |
| `F-E3-OneCardToday` | Today collapses to one card, a "then" list, and nothing else | NOT STARTED | — | — |
| `F-E4-WeekReviewConsolidation` | one bar chart, the Areas door, the streak-copy removals | NOT STARTED | — | — |
| `F-E5-EveningFirstThing` | evening "tomorrow's first thing" prompt | NOT STARTED | — | — |

### Arc F · The sprint

| block | what it is | status | landed | owed to E |
|---|---|---|---|---|
| `F-F1-HeadsUpReplacesCheckpoints` | the 5-minute heads-up replaces mid-sprint checkpoints | NOT STARTED | — | — |
| `F-F2-LiveActivityFiveMinuteOnly` | the Live Activity: `+5m` only, `.widgetURL`, the minimal Island | NOT STARTED | — | — |
| `F-F3-CardControlsV2` | the card's six controls ("V2 · two rows"), haptics by meaning, the timer size | NOT STARTED | — | — |
| `F-F4-FocusScreenAndDetails` | "Focus screen + Details", the inline stepper, "End" everywhere, round 10b's renames | NOT STARTED | — | — |
| `F-F5-CalendarBlockTime` | calendar access (read + write) and "Block time for a task" | NOT STARTED | — | — |

### Arc A · Copy and colour

| block | what it is | status | landed | owed to E |
|---|---|---|---|---|
| `F-A1-WordsAndStats` | round 8's words: "Still open", the header count, quiet areas, inbox stats | NOT STARTED | — | — |
| `F-A2-ColourJobs` | round 9's four colour jobs | NOT STARTED | — | — |
| `F-A3-JargonCapitals` | round 10b's words, round 6's fan copy, the missed inbox line | NOT STARTED | — | — |
| `F-A4-Footers` | round 10a: one sentence, the rest behind "More about this" | NOT STARTED | — | — |

### Arc B · Accessibility

| block | what it is | status | landed | owed to E |
|---|---|---|---|---|
| `F-B1-TouchTargets` | round 7's target sizes: 48pt actions, 44pt reach on 36pt chips | NOT STARTED | — | — |
| `F-B2-AX3Layouts` | task rows stack, sign-in segments grow, no mid-word breaks, metric labels wrap | NOT STARTED | — | — |
| `F-B3-VoiceOverAndCharts` | labels, combined elements, `.isSelected`, hidden chevrons, Smart Invert, chart descriptor | NOT STARTED | — | — |
| `F-B4-ReduceMotionSwaps` | Daily Summary and sign-in state swaps get a Reduce Motion fade | NOT STARTED | — | — |
| `F-B5-AutomatedAuditPlan` | `performAccessibilityAudit` per screen, its own test plan | NOT STARTED | — | — |

### Arc G · Places, sheets, refresh, Fresh Start

| block | what it is | status | landed | owed to E |
|---|---|---|---|---|
| `F-G1-PlacesOneSheet` | Places' editor becomes one sheet with pushes inside it | NOT STARTED | — | — |
| `F-G2-BottomAndFixList` | Save/Add to the bottom of eight sheets; the fix-list's four items | NOT STARTED | — | — |
| `F-G3-TapTwins` | up/down buttons and a place-editor Delete button | NOT STARTED | — | — |
| `F-G4-Refresh` | reload on appear, on foreground, and prove writes reach their screens | NOT STARTED | — | — |
| `F-G5-FreshStart` | "Welcome back. Start fresh?" and the Set-aside row | NOT STARTED | — | — |

## Session entries

*Newest last. One entry per session, written at close-out. Keep each to what the NEXT session needs.*

### Template — copy this

```
### Session N — <date>, arc <X>, blocks <ids>
- **Landed:** <block ids> at `<sha>` (PR #<n>). Suite <n>/0, SwiftLint 0/<n>.
- **Where the build departed from the spec, and why:** <one line each, or "nowhere">.
- **What E saw, and said:** <device verdict verbatim, RM-off and RM-on, or "not yet shown">.
- **Owed to E:** <device look / RM-on pass / a Step 0 answer — or "nothing">.
- **Owed to the code:** <anything parked, any test left reversed, any register item added>.
- **Next session starts at:** <block id>, from `<opener>`.
```

### Session 0 — 2026-09-19 · the audit (3 sessions), no build

- **Landed:** records, evidence and specs only. `main` @ `53b3ebe`. No Swift changed, so no suite or
  lint run; the figures above are carried from `061dbaa`.
- **What this produced:** E's answers to ten opening questions and rounds 1–10 (about 40 decisions,
  verbatim in the design record); ~80 findings in §A–§M, including the first `apple-skills`
  `ui-review` and `accessibility-audit` passes; boards `52`–`68`; and the 31 specs.
- **Standing principles set:** the app targets **ADHD specifically, not autism** (round 1);
  **gamification is essential throughout the app**, framed as progress, never debt (round 8).
- **Owed to E:** nothing from the audit itself. The phone-checks list is in the register's §Z, and
  each block names its own.
- **Owed to the code:** nothing. Contrast is deliberately excluded from all 31 blocks and belongs to
  the held colour arc.
- **Next session starts at:** `F-C1-UndoCapsule`, from `handoff/START-HERE-adhd-audit-arc-C.md`.

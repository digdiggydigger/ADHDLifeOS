# START HERE — build arc C, "Nothing lost", the audit's first arc

*Written 2026-09-19 by the ADHD UX audit's THIRD session, which finished rounds 7b–10, specced all
31 FEATURE blocks and built nothing. A disposable pointer: archive it when you write your successor.
Its predecessor, `archive/START-HERE-adhd-ux-audit-rounds-7b-to-10.md`, is spent.*

**E's standing instruction for these hand-offs:** *"You must ensure to maintain seamless continuity
in context and memory into the new session."* Nothing below needs re-deciding. **The audit is
CLOSED. This session builds.**

## 0. Before anything else

1. **Branch first, never work on `main`:**
   `git checkout main && git pull --ff-only && git checkout -b feature/adhd-arc-C-nothing-lost`.
2. **Read, in this order. It is enough, and it is everything.**
   - `CLAUDE.md`: Architecture notes and §1–§7, especially §7.1 (the iOS 16 floor), §7.2–7.3
     (Reduce Motion and the RM-on device pass) and §7.6 (`apple-design`).
   - `claudecode.md`: the TDD role.
   - **`TODO-CLAUDE-CODE.md`, the section "The ADHD UX audit's seven arcs"** (from line ~5146): its
     intro, then **Arc C**, blocks `F-C1` to `F-C4`. That is your work queue.
   - `handoff/SESSION-OPENER-adhd-ux-audit-design.md`, rounds 1, 2 and 2b, for the decisions behind
     arc C, in E's words.
   - **`handoff/ADHD-AUDIT-BUILD-LOG.md`** — the thread across every build session: what has landed,
     what departed from its spec, what is owed to E, and the close-out contract you owe at the end.
   - `handoff/OPEN-ITEMS-REGISTER.md`, the outstanding list.
   - Memory: `adhd-ux-audit-arc`, `build-in-a-fresh-session`, `audit-sim-drive-lessons`,
     `never-destroy-uncommitted-work`.
3. **Evidence you must not re-derive:** board `54` and `screenshots/adhd-ux-audit/round-2b-undo-bar/`
   hold the capsule E chose, rendered with the real tokens.

## 1. What this session builds

**Arc C, "Nothing lost", in order. One block, then stop for E's review.**

| block | what it is |
|---|---|
| `F-C1-UndoCapsule` | the 48pt undo capsule in the disc row, and every task close routed through it |
| `F-C2-DraftsToInbox` | unsent composer text files into the inbox; Cancel becomes Close; task detail autosaves |
| `F-C3-RecentlyDeleted` | soft delete for tasks and captures, with a row in Tools and a 30-day purge |
| `F-C4-TagsRecentlyDeleted` | tags too: links stay hidden, restore puts the tag back everywhere |

**Every Step 0 in arc C is already ANSWERED by E** (2026-09-19, in the blocks). Do not re-ask:
- every close gets the undo, including the Life Area tick;
- the inbox KEEPS its header ↶ as a second route, reading the same undo;
- on Journal the capsule stands in for the pencil disc;
- a nudge "Done for now" gets the capsule too, which needs a new `unmarkFired` write;
- "Reopen" opens the filed capture in the inbox;
- deleting shows the capsule as well as filing to Recently Deleted;
- the 30-day purge runs in the app on launch;
- restoring a tag whose name was reused ASKS which tag survives.

**One consequence to name in the report, not to re-open:** with one capsule everywhere, a new undo
replaces a pending one, so closing a task spends a pending capture undo. That follows from E's own
"one bottom bar everywhere".

## 2. What this session must NOT do

- **Do not start arcs D–G.** They are specced in the same section and are separate sessions.
- **Do not fix contrast.** Round 9's answer was *"Leave it to the colour arc"*, which is held.
- **Do not re-tune anything settled:** the tab bar and its constants, the appearance override, the
  Confirm celebration's Reduce Motion waiver, `peekStep = 14`, `floatingPaddingHorizontal = 12`, the
  capture disc.
- **Do not build a second undo mechanism.** `Capture/CaptureInboxUndoSections.swift` is the pattern
  to migrate onto the capsule, not to leave beside it.

## 3. What each block owes before it is done

Per `CLAUDE.md`: tests first; a red-check that restores the old code and counts the failures;
SwiftLint, the full suite and the build pasted as real terminal output; a `screenshots/` folder plus
README where the result is settled by looking; an `apple-design` review (§7.6); and **E's
Reduce-Motion-on device pass for `F-C1`** (§7.3), which adds a reduced site (the capsule's fade) and
changes one (the inbox bar's slide). `F-C1` needs two renders board `54` never produced: **Journal's
disc row** (default and AX3) and **compact-height landscape with a sprint card up**.

Land each block through a PR (`main` is protected), and verify `origin/main` carries it.

**Then the close-out contract, in full** (E's instruction, 2026-09-19: every session's progress is
logged so the next one starts with full context). It is written out in
`handoff/ADHD-AUDIT-BUILD-LOG.md`, and it is six steps: the block's `[x] COMPLETED` plus a "where it
departs from the spec" note; a session entry in the build log with that block's row updated; a line
in the `adhd-audit-build-progress` memory; the register rewritten; the successor opener written and
this one archived in the same commit; the PR landed and verified. **If you run out of context
mid-block, you still owe the log entry, the memory line and an opener that resumes** — a `WIP:`
commit and an honest "here is what is half-done".

## 4. The state you inherit

- **`main` @ the merge of this hand-off.** No app Swift has changed in the whole audit: three
  sessions of records, evidence and specs.
- **Suite and lint figures are carried, not re-run:** suite **3,085 / 0**, SwiftLint **0 / 831**, at
  `061dbaa`. Re-measure when you first touch Swift.
- **The simulator was erased at close-out** (iPhone 18 Pro, `02AE86FA-…`), so the audit account's
  signed-in session is gone. **The Firebase emulator was stopped, and its state is exported to the
  git-ignored `scripts/audit/emulator-state/`.** To drive the app again:
  `./scripts/emulators.sh --import scripts/audit/emulator-state`, then launch with
  `SIMCTL_CHILD_LIFEOS_FIREBASE_EMULATOR_HOST=127.0.0.1 xcrun simctl launch …` — a plain
  `simctl launch` points the app at the LIVE project. **If the app asks for sign-in, tell E.** E
  signs in by hand; never automate it.
- **`firestore.rules` has no field-level validation**, verified this session, so arc C's soft delete
  needs no rules change. Say so in the report rather than asking E to republish for nothing.

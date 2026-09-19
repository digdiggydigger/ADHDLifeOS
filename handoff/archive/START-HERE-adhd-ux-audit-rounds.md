# START HERE — the ADHD UX audit, options rounds 2–10

*Written 2026-09-19 by the session that opened the audit (research → E's ten answers → the simulator audit → round 1),
at E's call to hand off at 61% context so the rounds run in a clean one. A disposable pointer: archive it when you write
your successor. Its predecessor `archive/START-HERE-after-journal-door-pass.md` is spent.*

**E's instruction for this hand-off, verbatim:** *"You must ensure to maintain seamless continuity in context and memory
into the new session. Because as you know, this is quite a large task/process we are working on."* So: do not re-derive,
re-ask or re-audit anything below. It is settled or measured. Pick up at round 2.

## 0. Before anything else

1. **Branch first (E's rule, from the audit brief):** never execute audit work on `main`.
   `git checkout main && git pull --ff-only && git checkout -b feature/adhd-ux-audit-rounds`. The first audit branch
   merged its records into `main` at this hand-off.
2. Read, in this order. It is enough, and it is everything:
   - `CLAUDE.md`: Architecture notes, §1–§7 (especially §7.6 apple-design, and the settled list).
   - **`handoff/SESSION-OPENER-adhd-ux-audit-design.md`**: E's brief, E's ten answers VERBATIM, the scope calls, the two
     guardrails, how they sit against the house rules, and **"Decisions collected in the options rounds"** (round 1).
   - **`handoff/ADHD-UX-AUDIT-WORKING-FINDINGS.md`**: every finding, sections A–J. A–D = four code sub-agents; E + J =
     **verified on the simulator** (these override code-only claims); F = contrast computed from colorset hex; G, H, I =
     three `apple-design` HIG reviews with citations.
   - `handoff/SESSION-OPENER-adhd-ux-audit-research.md`: the evidence-graded research brief. Cite its section numbers.
   - `screenshots/adhd-ux-audit/README.md`: 53 curated evidence frames (file → claim), plus `full/` with every seeded tab frame in light / dark / AX3.
   - Memory `adhd-ux-audit-arc` (the round log) and `audit-sim-drive-lessons` (how to drive the simulator without losing
     an hour).

## 1. Where we are

- **Round 1 is DONE** (recorded in the design record + memory):
  - Every close → "Undo until next action". This retires "closing is one-way" for the undo moment.
  - Sprint start → "1 tap where a task stands alone". This amends b11.
  - Sounds stand as a grounding cue.
  - **E: the app targets ADHD specifically, NOT autistic people.** Weight ADHD evidence; demote autism-specific items
    (sensory over-responsivity, intolerance of uncertainty).
- **Rounds 2–10 are OWED.** Nothing has been edited in Swift. Nothing is built.
- **Tool yield, honestly:** `apple-design` ran properly (three HIG reviews, sections G–I). `apple-skills`
  `ios/ui-review` and `ios/accessibility-audit` were **never invoked**, so run them in a later round or say why
  not. `ui-ux-pro-max` (`--domain ux`, `--stack swiftui`) returned generic web rules or zero matches for every ADHD
  query. Its useful lines were 44pt with 8pt spacing, empty states with an action, and confirm-before-delete. The last
  one conflicts with E's soft-delete choice. Report it as low-yield rather than padding with it.
- **Decision A (build here or fresh?) is owed only AFTER all rounds.** The honest answer, per memory
  `build-in-a-fresh-session`: build in fresh session(s), as FEATURE blocks in `TODO-CLAUDE-CODE.md`. Give it when E has
  selected everything, not before.

## 2. The round method (E approved it by answering round 1 in this shape)

- **One theme per message. Every message is under 400 words.** E reads from a terminal.
- **Evidence first, as an image E can SEE:** build a labelled board from real frames with `scripts/audit/board.py`, then
  `open -a Preview <board>.jpg`. E looks at Preview while answering.
- **The questions via `AskUserQuestion`, ≤4 per call. Put the context INSIDE the question text.** The question pop-up
  HIDES whatever prose came before it. E missed a whole checklist that way ("I don't see where you provided it").
- **Each theme gets 2–3 options.** Each option names:
  - the executive-function struggle it helps (research §);
  - its HIG standing, cited `file.md › Heading` with a quote (read the page first, §7.6);
  - whether it uses the house tokens (E's Q5: tokens win unless they break HIG accessibility).

  One option is marked (Recommended). Where E pre-decided the direction, say "you chose X; these options are on HOW".
- **After each round:**
  - Append the answers VERBATIM to the design record's "Decisions collected" section.
  - Add one line to memory `adhd-ux-audit-arc`.
  - Commit and push.
- **Geometry options need renders, not words** (memory `show-dont-describe-geometry`):
  - Prefer composites cut from real frames with PIL.
  - Before writing ANY render probe in Swift, ask E once: E said no codebase edits before selection, and a probe is a
    throwaway test file.
  - `Claude Design` is allowed where it genuinely helps (E's guardrail 2).
- **Sub-agents are welcome** (E: "use as many subagents as needed"). Keep builds serial on this 8 GB machine.
- **Use the advisor at each round's draft** (E asked for it).

## 3. Rounds 2–10: the plan, with the substance already worked out

**Round 2: nothing lost, everything undoable.** E pre-decided the direction (Q3, Q4 and round 1). The options are on HOW.
Drafted, not yet asked:
- **Q · Where do unsent drafts live?** (evidence frames `21`–`27`)
  - **A.** Each composer keeps its own draft on the device. It survives quitting, and reopening shows it with
    "Draft · Clear".
  - **B.** Any composer closed with text files it into the Capture Inbox as a note. One trusted place, but the inbox
    count goes up.
  - **C.** Hybrid: keep the draft for the day, then move it to the inbox.

  All three replace task detail's blocking "Discard changes?" with autosave and restore the back-swipe.

  HIG: `modality.md › Best practices`: "help people avoid data loss…". `file-management.md`: "Help people be confident
  that their work is always preserved unless they cancel or delete it … avoid making people take an explicit action to
  save".

  Also verified: the quick Task composer DISCARDS on Cancel; the Journal composer keeps text in the session but loses it
  on quit; the toolbar "New task" sheet discards (code).
- **Q · What shape is the undo?** Two shapes already exist (frames `47`, `48`):
  - **A.** A bottom bar everywhere, the inbox pattern, but with a real ≥48pt Undo (today it is **34×16pt**).
  - **B.** In place, where the item was, Today's hero-card pattern.
  - **C.** Both: in place in lists; the bar where the item leaves the view (triage, nudge dismiss).

  HIG: `undo-and-redo.md`: "Show the results of an undo or redo … to keep people from thinking that the action had no
  effect". Research 2.1 (post-error slowing d=.42), 2.4 (time-boxed UI), 3.2 (fixed positions).
- **Q · Where does "Recently Deleted" live?** (E: tasks + captures; a Firestore rules change → E republishes)
  - **A.** Settings.
  - **B.** In context: the Tasks "Done" filter and the Inbox "Sorted".
  - **C.** One row in Tools.

  Retention of 30 days is suggested. Ask separately whether journal entries, tags and places join.

**Round 3: Today is 12 sections; only 3 serve the task** (HOME-03/04/08/09/10, AREAS-03; frames `09`–`15`). Options run
from least to most change:
- **A.** Reorder: hero → Due now → nudge. Analytics collapse into Week review.
- **B.** Split: Today = hero + Due now + the live routine card; the rest moves to Areas / Week review.
- **C.** A "Today is one screen" model, like the routine screen (frame `46`, the app's best ADHD pattern).

Also decide:
- the three streaks down to one ("Days Active This Week" is already on screen as "3/7 Active Days");
- two charts of one dataset (the trend line's `.catmullRom` draws values below 0);
- the repeated counts.

Needs renders or composites.

**Round 4: the sprint** (FOCUS-01…11, LA-01…04; frames `32`–`36`, `42`–`44`). E's Q2: timer + task + +5m/End ONLY.
- Settle the card timer at 11pt.
- The sheet has 14 regions and its controls sit ~290pt below the fold.
- "Close it" = STOP on the sheet but = COMPLETE elsewhere.
- Extension sets: +30s/+5m, +1/+5/+10, none.
- **The Lock Screen Stop has NO confirmation** (options: remove Stop from the Live Activity / Stop opens the app to
  confirm / one-tap Stop + resume-undo).
- There's no 5-min heads-up.
- Haptics: silent on the card, uniform on the sheet. Sounds are wanted per round 1.
- Jargon ×7 (checkpoint ≡ nudge).
- The Island needs E's phone.

**Round 5: the hero** (Q1: suggested-then-pinned; title + 1 next step + time).
- The task model has **no next-step or estimate field**, only `notes`, `focus_duration_seconds` and `nudges_count`. Adding
  one is a schema decision.
- "Close it" (solid green) outranks "Start session".
- Model it on the routine screen.

**Round 6: two task composers + capture copy** (TASKS-03 VERIFIED, frames `49`, `50`):
- The toolbar "+" and the disc → Task open different composers. E, told to use the toolbar "+", reached the disc's by
  mistake.
- An undated task from the toolbar "+" **vanishes from the board it was added from**.
- The quick path forces "due today" (so tomorrow it is "Overdue").
- 16 optional controls per composer.
- The fan says "Everything goes to the inbox"; the Task tile says "Skips the inbox".

**Round 7: targets** (pre-decided at 48–52pt for KEY targets; §3 floor 44). Options on WHICH targets and HOW (tokens;
chips 36→48 grows every composer):
- Settings gear 40×40
- Tasks "+" 27×36
- tag "Add" 24×14
- inbox Undo 34×16
- Back 36×36
- Cancel 77×36
- all chips 36pt
- sprint card controls ×44
- the Live Activity pills ≈34

**Round 8: shame and pressure copy** (pre-decided words, Q9). Options on SCOPE:
- "Overdue" ×3 and "0 OVERDUE" in the eyebrow;
- "Keep it alive today", "Close it — keeps a 6-day streak";
- orange "quiet since Tuesday" on INACTIVE areas (StateWarn = inactive + due + waiting, one colour, three meanings);
- the inbox's "decide or bin them", "oldest is 12 hours old";
- the Fresh Start after 7 days (no flow exists).

**Round 9: accessibility and colour, as an approve-the-list round:**
- AX3 truncation and the 2-column Areas grid that never reflows;
- the sign-in segments don't scale;
- contrast (§F):
  - LabelSecondary fails 4.5:1 in LIGHT (3.92–4.25);
  - LabelTertiary 1.9–2.3;
  - StateWarn text 2.72/3.02;
  - accent links 3.55;
  - **0 of 63 colorsets have an Increase Contrast variant**.
- Q5 vs Q6 collide here (tokens win unless they break accessibility vs no new palette values). Offer the middle option:
  fix only the Increase-Contrast appearance.
- Accent blue on non-interactive labels; raw `.green` ×4 where StateGo exists; the "Nudges Due" flame in StateRisk.

**Round 10: modals, Settings, Tools, polish:**
- modal depth: Places → editor → action → picker = 3; camera covers = 2;
- sheet Save at the top ×9 (Q8 wants the bottom);
- the Settings Notifications-card ~310pt gap;
- footers of ~17 lines;
- "Drag to reorder" only (routine steps, life areas; Q7 hard rule);
- the jargon list;
- "0 OPEN" shown while loading.

**Then:**
- the **Scope C gaps** list:
  - a "waiting mode" leave-by countdown;
  - wake-event routines (routines are location-only);
  - Lock Screen accessory widgets (none exist);
  - an app-wide daily notification cap;
  - Fresh Start;
  - journal edit/delete;
- the **phone checks** list (Dynamic Island compact/minimal/expanded, haptics, sounds, AutoFill, Always-On);
- Decision A.

## 4. Live state you inherit

- **Simulator:** iPhone 18 Pro, iOS 27.0, UDID `02AE86FA-CE2F-4468-90D6-2B8708910993`.
  - Booted, the app installed, signed in as `audit@test.local`, a throwaway account E created by hand.
  - The app was built from `a2abca1`, and no Swift has changed since.
  - Xcode 27's simulator window is **DeviceHub.app** (`/Applications/Xcode.app/Contents/Applications/DeviceHub.app`);
    `open -a Simulator` FAILS.
  - The sim location sits at E's Gym. E is happy for it to be their real location: *"simply adjust yourself accordingly"*.
- **Emulator:** it was started by the old session and may have died with it.
  - Check with `nc -z 127.0.0.1 9099`.
  - If it's down: `./scripts/emulators.sh --import scripts/audit/emulator-state` (a git-ignored export of everything:
    the account, the 33 seeded documents, E's Gym and Office, the photo, voice and task entries).
  - Relaunch the app with `SIMCTL_CHILD_LIFEOS_FIREBASE_EMULATOR_HOST=127.0.0.1 xcrun simctl launch 02AE86FA-… com.ethananthony.ADHD-LifeOS`.
  - The emulator was a background child of the old session and **will almost certainly have died with it**.
    `--import` restores `audit@test.local` with the password E chose. If the app shows sign-in, **ask E to sign in by hand
    with those same credentials** (never automate auth).
  - **Never run the unit suite on the 18 Pro.** It is signed in against an emulator that may be down, which is
    CLAUDE.md's poisoned-sim trap. Tests stay on `iPhone 17 Pro, OS=26.5`. The audit's close-out erase covers the 18 Pro.
- **Tools** in `scripts/audit/`:
  - `ax.py`: a compact accessibility tree; `--small` flags <44 / <48.
  - `tapid.py <id>` or `tapid.py <label> --label`.
  - `cap.sh NAME PAGES [sheet]`.
  - `matrix.sh L|D|A`.
  - `sheet.py` / `board.py`: contact sheets and labelled boards.
  - `seed_audit.py` (emulator-only, `--dry-run`, `--cleanup`).
  - `contrast.py`.

  Set `AUDIT_SCRATCH` to your scratchpad.

## 5. Close-out owed at the very end of the audit (not now)

- `xcrun simctl location 02AE86FA-… clear`
- `xcrun simctl erase 02AE86FA-…`
- stop the emulator
- rewrite the register
- write the successor opener, archiving this one
- nothing left unpushed

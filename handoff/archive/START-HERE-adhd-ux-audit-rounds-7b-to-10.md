# START HERE — the ADHD UX audit, round 7b then rounds 8–10

*Written 2026-09-19 by the audit's SECOND session (rounds 2–7), at E's call to hand off at 60% context: "I highly
recommend that we be consider moving into a fresh Claude code terminal." A disposable pointer: archive it when you
write your successor. Its predecessor `archive/START-HERE-adhd-ux-audit-rounds.md` is spent.*

**E's standing instruction for these hand-offs:** *"You must ensure to maintain seamless continuity in context and
memory into the new session."* So do not re-derive, re-ask or re-audit anything below. It is settled or measured.

## 0. Before anything else

1. **Branch first.** Never work on `main`:
   `git checkout main && git pull --ff-only && git checkout -b feature/adhd-ux-audit-rounds-3`.
   Session 2's branch merged its records into `main` at this hand-off.
2. **Read, in this order.** It is enough, and it is everything.
   - `CLAUDE.md`: Architecture notes, §1–§7, especially §7.6 `apple-design`.
   - **`handoff/SESSION-OPENER-adhd-ux-audit-design.md`**: E's ten answers VERBATIM, and **"Decisions collected in
     the options rounds"** (rounds 1–7, every answer verbatim, with the consequences each one carries).
   - `handoff/ADHD-UX-AUDIT-WORKING-FINDINGS.md`: findings §A–J, plus **§K, the Today ideas** (E added 1, 3–10).
   - `handoff/SESSION-OPENER-adhd-ux-audit-research.md`: the evidence brief. Cite its § numbers.
   - `screenshots/adhd-ux-audit/README.md`: every board and frame, numbered `00`–`64`.
   - Memory `adhd-ux-audit-arc` (one line per round) and `audit-sim-drive-lessons`.

## 1. Where we are

**Rounds 1–7 are DONE and recorded.** No Swift has changed. Every render probe was deleted from the test target after
E chose. In short:
- **R2: nothing lost.**
  - Unsent text: the inbox catches it.
  - Undo: one bottom capsule in the disc row.
  - Recently Deleted: a row in Tools, covering tasks, captures and tags. A restored tag goes back on every item it had.
- **R3: Today** = ONE card plus a short "then" list.
  - Streaks: a weekly chain with auto-repair.
  - Charts: one bar chart in Week review.
  - Goals: off until the user sets one.
- **R4: the sprint.**
  - Lock Screen: +5 min only.
  - A 5-minute heads-up replaces checkpoints.
  - Pause is kept. "End" is the only stop word. The sheet becomes a focus screen plus Details.
  - Six in-app controls in two rows: Pause · +30 sec · +1 min · +5 min · Custom · End. Custom is an inline stepper.
  - The calendar gets read AND write, for time-blocking.
- **R5: the one card.**
  - Start comes first and Close is quiet; the card needs a compact AX3 form.
  - What wins the card: leave-by > routine > paused sprint > pinned task > suggestion.
  - A new "Next step" field. The finished-sprint Confirm is KEPT (E's call).
  - The Week review door appears in both places. Streak N = 3. "Anything that moves life on" counts as active.
- **R6: composers.**
  - ONE composer behind both doors.
  - Content: a title, four "when" chips, and area and time menus.
  - No date by default, plus an "Anytime" row. The capture explanations are dropped.
- **R7: targets.**
  - 48pt for actions that change things, 44pt for navigation.
  - Chips keep a 36pt look with a 44pt reach.
  - Corner controls become 48×48.

## 2. FIRST ACTION: round 7b, the composer LAYOUT (its board is already built)

E confirmed the composer's content, but called my first layout (board `61`) *"quite ugly"* and asked for layout
redesigns. Three layouts were rendered with the real tokens: **`64-ROUND-7b-composer-layouts.jpg`**. If it is missing,
§5 says how to rebuild it.
- **L1 · Tidy grid.** One shape language and equal widths: the title, then ONE segmented "when" control (Not yet ·
  Today · Tomorrow · Date), then Area | Time as two equal halves, with Add at the bottom.
- **L2 · Form card.** A Settings-style card: a "When" row holding the segmented control, then Area and Time rows with
  their values on the trailing edge.
- **L3 · Rides on the keyboard.** The title owns the page. Every choice sits in a toolbar just above the keyboard,
  with Add inside it, so all of it is in thumb reach (Q8).

**The sequence, in this order:**
1. **Re-render L3.** Its Time value still wraps ("15 / min") in board 64. The saved probe
   (`scripts/audit/probes/AuditComposerLayoutProbe.swift.txt`) already carries the fix (`.lineLimit(1)` on the menu
   value). Copy it into `ADHD LifeOSTests/` as `.swift`, set its `outDir` to your scratchpad, and run it (§5).
   Rebuild the `r7-layout` frames that `compose_r7b.py` expects: it needs the status-bar crops from frames `22` and
   `full/s-home-D-p1`, which are in the repo. Recompose board `64`, and delete the probe from the test folder.
2. **Run `apple-design` on the three layouts (§7.6).**
3. **Open board `64` in Preview, then ask.** Recommend **L3**: the keyboard is up whenever the composer is, so L3 is
   the only layout whose choices never move and never need scrolling at standard sizes.
   - Say in the question that the keyboard is drawn as a 336pt block (the sim hides the software keyboard).
   - Name L3's known AX3 defect: its toolbar is taller than the space above the keyboard, and its menu buttons overlap
     in the render. The build gives it a scrolling or two-step AX3 form.

## 3. Round 8: shame and pressure copy (board BUILT: `63-ROUND-8-pressure-copy.jpg`)

E pre-decided the direction in Q9: "Still open" or "Pending", never "Overdue"; streaks become days active; and a
Fresh Start after 7 days away (E also added it as Today idea 7). The drafted questions, four in one call:
- **Q1 · The word for past-due.**
  - "Still open" (Recommended: plain, no judgement, and E's first word).
  - "Pending" (it reads like waiting on someone else).
  - "Since Thu" (a neutral fact: when it was due).
- **Q2 · The past-due count in headers** ("12 OPEN · 2 OVERDUE", shown even at 0; TASKS-04).
  - Remove it; the rows say it (Recommended; research 5.4: "No accumulating red overdue counts").
  - "N still open from before".
  - Only when it is above 0.
- **Q3 · Orange "quiet since Tuesday" on INACTIVE areas** (`Home/MomentumScoreboard.swift:285-290`). StateWarn means
  three things.
  - Neutral "last touched Tue", in no colour (Recommended; `color.md › Best practices`, one colour one meaning).
  - Remove the line.
  - Keep it.
- **Q4 · Inbox pressure** (`Capture/CaptureInboxSummary.swift:31-40,126`): "N are still sitting here — decide or bin
  them", "oldest is 13 hours old", and "Inbox health".
  - A neutral "5 to sort", dropping the age and the health section (Recommended).
  - Neutral wording, keeping the stats.
  - Remove the stats section.
  - NOTE: the ageing line was a deliberate part of Momentum Concept C (M5, "the inbox's ageing counterweight"). Say
    so in the question.

Then **8b**, one call:
- What Fresh Start does to the backlog: move it to a hidden "Later" list / archive / leave it and only dim it.
- The task-detail button "Close it — keeps a 6-day streak" (`Tasks/MomentumTaskContext.swift:27`) becomes "Close it";
  the weekly chain from R3 retires the day streak anyway, so confirm rather than ask.
- "Keep it alive today" (`Home/MomentumScoreboard.swift:251`) goes with the day streak.

## 4. Rounds 9 and 10, and the close

**Round 9: accessibility and colour, as an approve-the-list round.**
- AX3 truncation, and the 2-column Areas grid that never reflows.
- The sign-in segments don't scale at AX3.
- Contrast (§F):
  - LabelSecondary fails 4.5:1 in LIGHT (3.92–4.25);
  - LabelTertiary 1.9–2.3;
  - StateWarn text 2.72/3.02;
  - accent links 3.55;
  - 0 of 63 colorsets have an Increase Contrast variant.
- Q5 vs Q6 collide here (tokens win unless they break accessibility, vs no new palette values). Offer the middle
  option: fix only the Increase Contrast appearance.
- Accent blue on non-interactive labels; raw `.green` ×4 where StateGo exists; the "Nudges Due" flame in StateRisk.
- **Run `apple-skills` `ios/ui-review` and `ios/accessibility-audit` in this round.** Both were never invoked, and
  the report must say so if they are skipped.

**Round 10: modals, Settings, Tools and polish.**
- Modal depth: Places → editor → action → picker = 3; camera covers = 2.
- Sheet Save at the top ×9 → the bottom (Q8).
- The Settings Notifications card's ~310pt gap.
- Footers of ~17 lines.
- "Drag to reorder" with no tap twin (routine steps, life areas; Q7's hard rule), and the Places swipe-delete with no
  twin (GEST-2).
- "0 OPEN" shown while loading.
- The jargon list, now including the Details view's "Deep entry", "Flow calibration", "Sprint target" and "1 of 15
  min logged".
- The inbox's "Anything you capture lands here first".

**Then, as the final text of the round (never inside a question pop-up):**
- The **Scope C gaps** list:
  - the leave-by countdown (now WANTED, idea 1);
  - wake-event routines (idea 5, WANTED);
  - Lock Screen accessory widgets (idea 10, WANTED);
  - an app-wide daily notification cap;
  - Fresh Start (idea 7, WANTED);
  - journal edit/delete;
  - calendar read/write (R4b/4c).
- The **phone checks** list:
  - Dynamic Island compact/minimal/expanded;
  - the differentiated haptics (R4 carry-over);
  - sounds with the silent switch both ways;
  - AutoFill;
  - Always-On;
  - the Live Activity's +5 min hit area;
  - the heads-up notification.
- **Decision A:** build in fresh sessions, as FEATURE blocks in `TODO-CLAUDE-CODE.md`, per memory
  `build-in-a-fresh-session`.

**Close-out, owed only at the very end of the audit:**
- `xcrun simctl location 02AE86FA-… clear`
- `xcrun simctl erase 02AE86FA-…`, the 18 Pro.
- Consider erasing the iPhone 17 Pro 27.0 (`0ACE7E5C-…`) too. It hosted the render probes, but never signed in.
- Stop the emulator.
- Rewrite the register.
- Write the successor, archiving this one.

## 5. Tools and live state

- **The method (E approved it every round).**
  - One theme per call, at most 4 questions, with the context INSIDE each question (the pop-up hides prose).
  - A labelled board opened in Preview first.
  - 2–3 options, each naming the ADHD struggle (research §), its HIG standing (`file.md › Heading`, read first), and
    the house tokens.
  - One option marked (Recommended).
  - Use the advisor on each round's draft.
  - After each round: record the answers verbatim in the design record, add a memory line, then commit and push.
- **Render probes** (E's standing permission since round 2b).
  - Copies of every probe are in **`scripts/audit/probes/`**: the Swift sources as `.swift.txt`, so nothing ever
    compiles them there, plus the Python compositors and `annot.py` / `stitch.py`.
  - To render: copy a probe into `ADHD LifeOSTests/` as `.swift`, then run it:

    ```
    xcodebuild test -project "ADHD LifeOS.xcodeproj" -scheme "ADHD LifeOS"
      -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=27.0'
      -only-testing:"ADHD LifeOSTests/<Probe>" -enableCodeCoverage NO
    ```

    NEVER run it on the signed-in 18 Pro.
  - The compositors expect their frames under the scratchpad path they name: edit `S` at the top.
  - Delete the probe from the test folder after E chooses. It is never committed there.
  - **The first `ImageRenderer` render in a fresh test host returns nil every time.** Use the two-pass job list
    (render only the files that are missing), as in `AuditComposerLayoutProbe.swift.txt`.
- **Simulator:** iPhone 18 Pro / 27.0, `02AE86FA-CE2F-4468-90D6-2B8708910993`.
  - It is signed in as `audit@test.local`, light mode, Large text.
  - The sim location is at E's Gym, so the routine is live on Today.
- **Emulator:** it was up throughout. The export was refreshed at this hand-off.
  - If it is down: `./scripts/emulators.sh --import scripts/audit/emulator-state`.
  - If the app then asks for sign-in, **tell E**. E signs in by hand; never automate it.

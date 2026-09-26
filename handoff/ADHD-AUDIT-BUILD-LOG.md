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

**Arc C's first block has landed, and its shape round with it.** `F-C1-UndoCapsule` merged
2026-09-20, was resized on E's call, then reshaped on E's first device look. Suite **3,137 / 0**,
SwiftLint **0 / 843**, build green.

**The shape round found a Critical nobody had rendered.** E chose "fully rounded" from eight frames,
every one at the DEFAULT text size. A `Capsule`'s radius is derived from its height, so the stacked
accessibility layout (194.3pt) is a *different shape*: 6,329 glyph pixels and 2,604 Undo-control
pixels were drawn outside the card. E was shown both and chose to cap the radius at `minHeight / 2`
— which is pixel-identical to a capsule at the 44pt E approved (max channel delta 0). **The lesson
to carry into every later arc: when a shape's geometry is DERIVED from its content's size, the
accessibility layout is a different shape. Render it before calling a shape round closed.**

App-target coverage is **29.83% (14,612/48,985)** at the shape round's merge, measured with the
documented command and the emulator UP. **Against the 29.07% (14,225/48,930) recorded above, the
denominator barely moved (+55, the `Undo/` edits) but the numerator moved +387 — which four
assertion-only tests cannot account for, so the delta is NOT this round's and its cause was not
established.** What was ruled out: the six emulator-backed suites ran in this measurement and the
four extensions CLAUDE.md documents match their recorded figures exactly (97.67 / 98.31 / 95.83 /
90.20), so a skipped emulator is not the explanation. Reported rather than explained, per
CLAUDE.md's "establish WHY before you compare" — the honest answer here is that it was not
established.

`Undo/`'s four non-view files are back at 100% each. The shape briefly took
`UndoCapsuleMetrics.swift` to 58.33%: `path(in:)` and `inset(by:)` are pure functions only SwiftUI
was calling, and they now have behavioural tests rather than being written off as view-body 0%.

**Build order** (E chose C first; the rest is the proposal in the specs' intro):
**C → D → E → F → A → B → G.**

## How many sessions — the proposal (E asked, 2026-09-19)

**About 16–20 sessions, not 31.** Small copy blocks batch; structural ones do not. What ends a
session is CONTEXT, and it goes on red-check cycles, full-suite runs and device evidence rather than
on lines of code — so size a session by its test surface, not its diff.

| arc | sessions | grouping |
|---|---|---|
| C · Nothing lost | 3 | **C1 alone** (five close surfaces, a new shared component, an RM-on pass) · C2 · **C3+C4** (C4 rides C3's schema) |
| D · The composer | 2–3 | **D1 alone** (two composers merge into one) · D2+D3 |
| E · Today | 3–4 | E1+E2 · **E3 alone** (Today's whole body) · E4+E5 |
| F · The sprint | 4 | **F1 alone** (retires checkpoints across app AND widget) · F2+F3 · F4 · **F5 after its render round** |
| A · Copy and colour | 1–2 | A1+A2 · A3+A4 |
| B · Accessibility | 2–3 | B1+B2 · B3+B4 · **B5 alone** (it migrates the scheme's Test action) |
| G · Places, sheets, refresh | 3 | G1+G2 · G3+G4 · G5 |

**This is a proposal, not a rule.** Two things add sessions: **F5's render round** (the calendar
slot-picker has no rendered design and no chosen option anywhere in the record), and any block whose
device verdict sends the shape back — the journal pencil did that twice in one arc.

**Batching two blocks does NOT batch the review.** The standing rule is unchanged: build one block,
stop, paste the real output, wait for E. Two blocks in a session means two review points.

## The 31 blocks

`—` in *landed* means not built. *Owed to E* is the device look, the Reduce-Motion-on pass, or a Step 0 answer.

### Arc C · Nothing lost

| block | what it is | status | landed | owed to E |
|---|---|---|---|---|
| `F-C1-UndoCapsule` | one undo capsule, in the disc row, for every task close | **MERGED**, + the height round, + E's SHAPE ROUND, + **E's DEVICE LOOK: PASSES** | `ea9cbed` (PR #172), shape round PR #178, device evidence `2db6443` | **nothing.** (The radius CAP has no device evidence — E's larger-text look was the top of the STANDARD range — but no block owes it; the AX3 render covers it.) |
| `F-C2-DraftsToInbox` | unsent text goes to the inbox; Cancel becomes Close; task detail autosaves | **MERGED**, + **E's DEVICE LOOK: PASSES** | PR #180, screenshots PR #183, device evidence `015c41b` | **nothing.** |
| `F-C3-RecentlyDeleted` | soft delete for tasks and captures; one row in Tools | **MERGED**, + **E's DEVICE LOOK: PASSES** (2026-09-22) | PRs #184, #185; verdict `236db22` | **nothing.** *(Row corrected in session 8 — two sessions had left it at IN PROGRESS.)* |
| `F-C4-TagsRecentlyDeleted` | tags in Recently Deleted; hidden links, restore-to-everywhere, merge | **MERGED**, + **E's DEVICE LOOK: PASSES** (2026-09-22) | PR #187; verdict `236db22` | **nothing.** §A-CAPSULE is deferred WORK, not a question. *(Row corrected in session 8.)* |

### Arc D · The composer

| block | what it is | status | landed | owed to E |
|---|---|---|---|---|
| `F-D1-ComposerBothDoors` | one composer, both doors, and the settled content | **MERGED** (2026-09-23), + **E's DEVICE LOOK: PASSES** (2026-09-24, arc-D pass) | see session 8 | **nothing.** |
| `F-D2-ComposerKeyboardLayout` | L3 rides the keyboard; AX3 falls back; the Date segment | **MERGED** (2026-09-24), + **E's DEVICE LOOK: PASSES** (2026-09-24, arc-D pass) | PR #200 (`c25ed44`) | **nothing.** No RM-on pass was owed |
| `F-D3-TasksAnytimeRow` | the "Anytime · N" row on the Momentum board | **MERGED** (2026-09-24), + **E's DEVICE LOOK: PASSES** — **arc D CLOSED** | PR #202 (`ca06c04`) | **nothing.** |

### Arc E · Today

| block | what it is | status | landed | owed to E |
|---|---|---|---|---|
| `F-E1-WeeklyChain` | the weekly active-day chain, goals off until set, and the gain-framed Close button | **LANDED** 2026-09-25 | PR #205 (`8d1df83`) | batched to ARC-REVIEW-E |
| `F-E2-NextStepField` | the task's "Next step" field | **LANDED** 2026-09-25 | PR #206 (`df2ab2f`) | batched to ARC-REVIEW-E |
| `F-E3-OneCardToday` | Today collapses to one card, a "then" list, and nothing else | **LANDED** 2026-09-26 (E answered Q1–Q4) | PR #207 | batched to ARC-REVIEW-E (+ RM-on: the capsule from Close) |
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

### Session 1 — 2026-09-20, arc C, block `F-C1-UndoCapsule`

- **Landed:** `F-C1-UndoCapsule` at `ea9cbed` (PR #172). Suite **3,130 / 0**, SwiftLint **0 / 842**
  (3,131 / 842 after PR #174's follow-up). The first app Swift the audit has produced.
- **Where the build departed from the spec, and why:** five departures, written out in full in the
  block's own note in `TODO-CLAUDE-CODE.md`. The two the next block will feel:
  **(a)** `RecentAction.undo` returns `Bool` and the centre puts the offer back on `false` — C2's
  draft bar and C3's delete bar must return it too, or a failed undo will silently vanish;
  **(b)** the capsule WRAPS the disc row's leading band (`UndoCapsuleSlot { leadingBand }`) rather
  than sitting beside it, which is what makes it stand IN FOR the search row and the pencil.
- **What E saw, and said:** **not yet shown.** Nothing has been on the phone.
- **Owed to E:** the device look, and the **Reduce-Motion-on device pass** (§7.3) — this block adds
  a reduced site (the capsule's appear-fade) and changes one (the inbox bar's slide is gone). Ask
  for both passes in ONE message so E flips the setting once.
- **Owed to the code:** nothing parked, no test left reversed. Two register candidates, both
  routed rather than fixed: the Undo label's **3.38:1 light / 3.48:1 dark** (it is the tab bar's own
  selected-pill wash, and contrast is the HELD colour arc's), and the Capture Inbox's content
  scrolling under the capsule now that the screen's own bottom bar is gone.
- **What the renders caught that the tests could not:** the Undo button truncated to "Un…" beside a
  two-line subject. Fixed and pinned. **Worth carrying into every later arc-C block:** the capsule
  is drawn in a tight `HStack` and any new content in it can take the control's width.
- **Found AFTER the block landed, fixed in PR #174 — and the lesson generalises:** the capsule
  **names what it would take back**, so a capture's own words are on screen the moment it is
  sorted. `SignedInJourneyUITests` waited app-wide for exactly those words to disappear and could
  not survive it. **UI tests are skipped in the standard run**, so a green suite, a green build and
  a green red-check all said nothing. Two more went with it: the capsule's richer
  `accessibilityLabel` stopped `app.buttons["Undo"]` matching, and
  `CaptureInboxService.clearLastTriageAction()` was left dead with a doc comment claiming a guard
  it did not have. **Every later arc-C block should grep `ADHD LifeOSUITests` for the identifiers
  and labels it changes, and RUN any journey it touches** — the suite will not.
- **E's HEIGHT ROUND, after the block landed (same day).** E measured the shipped capsule against
  the capture disc — *"it looks ugly with the UndoCapsule at the same height as the FAB Icon"* —
  and marked a 45.3pt band against 74pt drawn. Four shapes were rendered on the real screen and E
  chose **two lines, a size smaller** (44pt card) plus the Undo control's **draw 32 / tap 44**
  trade, which overrides round 7's 48pt for that one control. Suite **3,132 / 0**.
- **Owed to E, and it is the next session's FIRST job:** the device look and the RM-on pass, now on
  the 44pt capsule. E's phone was disconnected during the height round and must be reconnected.
- **Next session starts at:** the device look, then `F-C2-DraftsToInbox`, from
  `handoff/START-HERE-adhd-audit-arc-C2.md`.

### Session 2 — 2026-09-20, arc C, `F-C1-UndoCapsule`'s DEVICE ROUND (no block built)

- **Landed:** no Swift. Evidence, a spec and this handoff, at PR #177. Suite **3,132 / 0**,
  SwiftLint **0 / 842** — unchanged, because the round-scoped code was removed before merging and
  `UndoCapsule.swift` is byte-identical to its shipped state.
- **What E saw, and said.** `main` @ `3f7932c` went onto E's phone — **build, install and launch
  clean in ONE WIRELESS pass, with no cable and nothing for E to do.** The opener and register both
  said the phone was DISCONNECTED and must be reconnected; it was `available (paired)` over a live
  `localNetwork` tunnel the whole time. **Probe before asking E for a cable** —
  `devicectl device info details --device <udid>` answering at all is the proof, and it costs one
  command. Recorded in the `device-build-lag` memory.
  - **Reduce Motion ON: PASSED.** E: *"Passes your request requested checks"*. **That discharges the
    §7.3 RM-on pass F-C1 owed — it is DONE, not outstanding.**
  - **Reduce Motion OFF: the shape came back.** E, verbatim: *"Bringing back a second line is smart.
    I also recommend that we remove the blue chip background colour behind the "Undo" Button and
    increase the corner radius of the entire UndoCapsule card."*
  - Two things E's own frames settled that no test reaches: `IMG_8565`→`IMG_8566` is the reversal
    landing against real Firestore (the "Closed" chip gone, "Close it" back), and `IMG_8562` is a
    capsule recorded on Today still standing on the Capture Inbox tab — the one-slot design working.
- **What was decided, and it took TWO rounds because the first answer did not survive measurement.**
  Eight shapes rendered on the real screen from one build (`screenshots/undo-capsule-redesign/`).
  E chose **fully rounded** (*"Option C, 'Fully rounded' looks the best"*), the Undo control's
  padding **reclaimed 16 → 0**, and — first time round — "up to two lines". Rendering that exact
  combination showed the third pick does not do what it was for: at the reclaimed width the subject
  column holds ~12–14 characters per line, so every realistic task title wraps and the card is
  **59pt either way**. Shown the binary choice, **E chose 44pt with ONE wider line.**
  **So E's own opening words — "bringing back a second line is smart" — are SUPERSEDED by E's later
  look. The final shape has NO second line.** That is the single most mis-buildable thing here.
- **Owed to E:** nothing. Both passes are done and every design question is answered.
- **Owed to the code:** `F-C1`'s shape round is specced and **NOT BUILT** — that is the next
  session's first job. The Undo label's contrast is still a colour-arc candidate, and E's change
  IMPROVES it (3.38 → 3.93 light, 3.48 → 4.47 dark), which is recorded, not fixed.
- **What the renders caught that no test could — three, and all three generalise:**
  **(a)** two lines alone did NOT fix the truncation E complained about, because
  `undoHorizontalPadding = 16` was padding the inside of the chip E removed and became 32pt of
  invisible dead space. **Found by reading a frame, not by planning** — the winning variant did not
  exist when the round was designed. **(b)** Two of the decisions INTERACT: an earlier frame measured
  52.7pt only because its narrower column made `.minimumScaleFactor(0.8)` shrink the text. A
  combination has to be rendered, not reasoned about. **(c)** A render that measured five identical
  heights was a TOLERANCE BUG, not a design that had not changed — the white card differs from the
  page background by only 13. Validate a measurement against a known value (the shipped 44pt) before
  believing it.
- **The harness guard worked, and it is worth keeping.** Every variant asserts the capsule's
  accessibility identifier carries its own name. One light render failed with *"the variant did not
  reach the app"* rather than photographing the shipped shape and labelling it as the alternative —
  exactly the trap the height round fell into twice.
- **Next session starts at:** `F-C1-UndoCapsule`'s **shape round** (the spec is the
  "THE FINAL SHAPE — build exactly this" block in `TODO-CLAUDE-CODE.md`), then
  `F-C2-DraftsToInbox`. From `handoff/START-HERE-adhd-audit-arc-C1-shape.md`.

### Session 3 — 2026-09-20, arc C, `F-C1-UndoCapsule`'s SHAPE ROUND

- **Landed:** the shape round at PR #178. Suite **3,137 / 0**, SwiftLint **0 / 843**, build green.
  App-target coverage **29.83% (14,612/48,985)**.
- **Where the build departed from the spec, and why:** ONE departure, and **E made it**. The spec
  said `Capsule(style: .continuous)`, "not a radius number"; that was built, rendered, and then the
  stacked accessibility layout was rendered at it **for the first time in the whole arc**. A capsule
  takes its radius from half the card's height — 22 at the default 44pt, **97.2pt** at Accessibility
  XL's 194.3pt card — so the curve ate the corners the content sits in: **6,329 pixels of the
  completion glyph and 2,604 of the ↶ Undo control drawn OUTSIDE the card's fill**, the glyph 59.0pt
  clear of it. E was shown both shapes rendered on the real Tasks screen and chose to cap the radius
  at `minHeight / 2`. After the cap both counts are **0**. Everything else shipped exactly as
  specified, including the part most likely to be mis-built: **no second line.**
- **What E saw, and said:** E chose the cap from `screenshots/undo-capsule/11-…`. **The RM-off
  device look on the new shape has NOT happened** — E has only seen renders of it.
- **Owed to E:** **the RM-off device look**, on a build installed on the phone. Nothing else. No
  RM-on pass is owed (geometry and fill only, `UndoCapsuleMotion` untouched, and F-C1's RM-on pass
  PASSED on 2026-09-20); no "Verified paths" line (no `#available` site touched); no rules change.
- **Owed to the code:** nothing parked, no test left reversed. The Undo label's contrast is still a
  colour-arc candidate and E's change IMPROVED it (3.38 → 3.93 light, 3.48 → 4.47 dark) — recorded,
  not fixed. The coverage numerator delta above is unexplained and flagged rather than claimed.
- **Four things this session learned, and three generalise past this block:**
  1. **When a shape's geometry is DERIVED from its content's size, the accessibility layout is a
     different shape.** This is the third instance in ONE block of "a combination has to be
     RENDERED, not reasoned about" — the height round found it when two of E's picks interacted, the
     shape round when the winning variant did not exist at design time, and this when every frame E
     ever chose from was at one text size.
  2. **The AX3 render pass needs a FRESHLY ERASED simulator.** The harness signs out of any existing
     session first, and at accessibility text sizes the taller Settings rows put `signOutButton`
     beyond its 8 swipe attempts — it fails with *"Settings opened but presented no sign-out
     control"*, which reads like a capsule bug and is not one.
  3. **Ask the direct question of a frame.** Scanning for "where does the fill begin on this row"
     gave a number that contradicted the unit test; counting *content pixels drawn outside the fill*
     answered cleanly (6,329 / 2,604 → 0 / 0) and is the claim that actually mattered.
  4. **`| head -N` on a piped `xcodebuild` truncates the run's own result**, closing the pipe before
     `** TEST FAILED **` is reached, so the exit status is never seen. Redirect to a file and grep
     the file.
- **Next session starts at:** `F-C2-DraftsToInbox`, from
  `handoff/START-HERE-adhd-audit-arc-C2-drafts.md`.

### Session 4 — 2026-09-20, arc C, `F-C2-DraftsToInbox`

- **Landed:** `F-C2-DraftsToInbox` at PR #180. Suite **3,174 / 0**, SwiftLint **0 / 853**, build
  green. **`SignedInJourneyUITests` + `JournalJourneyUITests` run deliberately: 6/6 PASSED** —
  the opener's own lesson, since this block relabels three controls and UI tests are skipped.
- **Where the build departed from the spec, and why:** four, all in the TODO's "Built" note.
  A **spec correction** (`QuickCaptureView` is presented TWICE — a cover from the disc and a
  `.sheet` from the inbox, so "swipe-down is impossible" held for one route only);
  **`.onDisappear` and no `.interactiveDismissDisabled`**; **autosave on leaving, not on blur**
  (saving sets `state = .loaded`, which resets the Form's scroll — a per-blur save would yank the
  user's position); and **the capsule's control is no longer always "Undo"** (E asked for
  "Reopen", which reverses nothing).
- **What E saw, and said:** nothing yet — not shown.
- **Owed to E:** a **device look, RM-off**, on this block AND on `F-C1`'s shape round, which is
  still owed from session 3. Ask for both in one message. **No RM-on pass** — no reduced site was
  added or changed; the capsule's motion is F-C1's and untouched.
- **Owed to the code:** **`screenshots/drafts-to-inbox/` was NOT produced** — the one acceptance
  criterion unmet. The block was settled by assertion, not by looking, but the spec asks for it.
- **Four things learned:**
  1. **A `let` with a default value is EXCLUDED from a struct's synthesised memberwise init**, so a
     defaulted dependency on a view with no hand-written `init` must be a `var` — and it must be
     declared BEFORE any trailing-closure member, since the init takes parameters in declaration
     order. Cost three compile rounds.
  2. **Four files hit SwiftLint ceilings in one block.** `RootView.swift` was at 400/400 and had to
     give up `capturesTab` to `RootView+Doors`; `TaskCreateView` and `LogComposerView` both needed
     `+Drafts` extensions, and the latter also a `+Ink`. Budget for it when adding to any view.
  3. **Moving a call site breaks call-site tests, and that is them working.**
     `CelebrationMilestoneCallSiteTests` failed on the Captures tab moving file. Re-pointed at the
     new file rather than widened to "any file", which would have stopped it catching a real drop.
  4. **An exhaustive `switch` earns itself.** Adding a sixth `RecentActionKind` failed the BUILD at
     the inbox's header-arrow check rather than silently inheriting a branch — exactly what that
     test's failure message had predicted a year of sessions earlier.
- **Next session starts at:** `F-C3-RecentlyDeleted`, from
  `handoff/START-HERE-adhd-audit-arc-C3-deleted.md`.

### Session 6 — 2026-09-22, arc C, `F-C3-RecentlyDeleted` FINISHED

- **Landed:** eight commits on `feature/adhd-c3-deleted`, merged as PR #185. The write payloads,
  the manager methods, the hard delete leaving every UI-facing seam, two capsule kinds, the screen
  + the fifteenth adapter + the Tools row + the launch purge, the copy fix, E's two decisions, and
  `screenshots/recently-deleted/`.
- **Where the build departed from the spec, and why:**
  - **`ToolsView.Push` is a LOCAL superset of `ToolsCatalog.Destination`**, not a third case on it.
    `ToolsCatalogTests.testEveryDestinationHasAnEntry` holds the catalog's case list and its entry
    list equal, so a third destination there would be a third CARD — and E said row. The case names
    match, so `ToolsPageCallSiteTests`' verbatim `pushedDestination = .places` pin is untouched, and
    `Push(_:)` switches exhaustively so a new catalog door fails the build here.
  - **The service publishes ONE `Screen` enum**, not a state beside a computed content. A test
    drove that out: on a failed load the items array is empty, so `content` answered `.empty`.
  - **Two pins moved deliberately:** the disc-clearance count 3 → 4, and both of
    `UndoCapsuleCallSiteTests`' verbatim header-arrow lines.
- **What E decided, and both removed something:** *"Drop both confirms"* and *"Unify on Delete"*.
  The delete confirmations existed BECAUSE delete was irreversible, and `alerts.md › Best
  practices` says not to confirm common, undoable actions; "Recently Deleted" is the anchor Photos,
  Notes and Files all use, so "Discard" moved to "Delete". **"Delete forever" keeps its confirm.**
- **Owed to E: nothing.** No `#available` site and no reduced site, so no RM-on pass (§7.3), and
  the new screen has no animation of its own — deliberately, since adding one would have put that
  pass back on the bar for a list whose job is to be unhurried.
- **Six things learned, and four of them cost a run each:**
  1. **`tap(_:untilGone:)` returns `true` without tapping** when the doomed element is already
     absent — and scrolling a `Form` to its last row takes the title field out of the hierarchy.
     Two assertions passed on a build that had deleted nothing. **The emulator settled it**: a
     `runQuery` with `Authorization: Bearer owner` found `deleted_at` on no document in the
     project. A screenshot could not have shown that.
  2. **`tap(_:untilExists:)` fails identically from the other side.** The replacement signal (the
     capsule) was already satisfied by a capsule left pending from the previous delete.
  3. **A push that has not settled reports frames on the wrong page** — x ≈ 10016, a screen width
     times the tab index. A plain tap fails "not hittable"; a COORDINATE tap, tried as the fix, is
     worse: it bypasses hittability and lands on whatever is really at those coordinates (one run
     ended on the Areas tab). Wait for the pushed screen's own nav bar.
  4. **An accessibility identifier is inherited by a container's children**, so
     `descendants(matching: .any)["toolsCard.places"]` is ambiguous and an ambiguous query reports
     that it does not exist — *"The Tools page never appeared"* about a page plainly on screen.
  5. **A `confirmationDialog`'s button matches twice** (sheet + presenting hierarchy); `.firstMatch`
     or the tap fails on "Multiple matching elements found".
  6. **Copy written earlier in the same block can go dead later in it.** `softDeleteReassurance`
     was written to fix a false sentence and orphaned four cycles later when E dropped the dialog
     that held it. Grep caught it; no test would have.
- **Suite 3,253 / 0**, SwiftLint **0 / 877**, build SUCCEEDED, coverage **29.87%
  (14,953/50,068)** — comparable to session 5's 29.89%, the 0.02 dip being 523 lines of new view
  body that are 0% by design.
- **Next session starts at:** `F-C4-TagsRecentlyDeleted`, from
  `handoff/START-HERE-adhd-audit-arc-C4-tags.md`.

### Session 5 — 2026-09-22, arc C, `F-C2`'s debt + BOTH device looks + `F-C3` started

- **Landed:** `screenshots/drafts-to-inbox/` at **PR #183** (`51910cd`) — `F-C2`'s one unmet
  acceptance criterion, 33 frames (light / dark / AX3) and a README, plus the harness
  `DraftsToInboxRenderUITests`. SwiftLint **0 / 854**. Then E's device evidence for both blocks
  (`2db6443`, `015c41b`) on `feature/adhd-c3-deleted`.
- **Where the build departed from the spec, and why:** nowhere — this was evidence, not app code.
  **No app Swift changed**, so the frames are of the shipped build (`git diff 4917955 bc2827e`
  touches `handoff/` only).
- **What E saw, and said:** **BOTH looks PASS.** `F-C1`'s shape on E's phone: fully rounded, no
  chip, one line, the subject reading in full. `F-C2`: the capsule reads "Kept in your inbox · ↗
  Reopen", the badge ticks 24 → 25, the draft appears in the Journal feed as `captured`, and
  Reopen lands on that capture. On the swipe-back, E: *"Also passes"*. Eleven frames filed in
  `screenshots/undo-capsule-device/` and `screenshots/drafts-to-inbox-device/`.
- **Owed to E: nothing.** One thing is unverified ON DEVICE and no block owes it: the radius CAP.
  E's larger-text look was the top of the STANDARD range with "Larger Accessibility Sizes" OFF
  (E supplied the settings page as `02-` so nobody could over-claim it), and the cap only differs
  from a plain capsule once the layout STACKS, which needs an accessibility size. The AX3 render
  covers it.
- **Owed to the code:** nothing outstanding. One register candidate added, and **one finding of
  mine RETRACTED by E's frames** — see below.
- **Five things learned, four of them by rendering:**
  1. **The Journal has no compose control while a capsule is pending** — it stands in for the
     pencil. `F-C2` made this common (any composer closed on text now makes a capsule) where
     before only a close or a triage did. The harness drives the journal FIRST.
  2. **Reopen lands on a PUSHED screen, not a sheet** — 45s of a harness waiting for a sheet that
     never existed, and it would have corrupted the inbox frame.
  3. **The AX3 set needs TWO runs**: the swipe-back test signs out of the account the composer
     test leaves, and at accessibility sizes the taller Settings rows push `signOutButton` past
     the harness's eight swipes. A fresh erase fixes the FIRST test in a run, not the second.
  4. **`focusAndType`'s focusing tap lands BETWEEN words at accessibility sizes**, so an equality
     assertion reported a WORKING autosave as broken. Assertions on typed text must be CONTAINS.
  5. **A finding I recorded was wrong, and E's own frames retracted it.** I reported the selected
     Captures tab truncating to "Captu…" *because the badge takes width from the pill*. The badge
     is an `.overlay` and consumes no width at all; the clamp is `maximumRestingPillWidth = 120`,
     whose own comment predicts the spot. **And E's phone renders "Captures" in full.** It stands
     as a simulator-only observation. The lesson: a plausible mechanism is not a measured one, and
     the device is the arbiter.
- **`F-C3` was STARTED and its read side landed — three RED→GREEN→commit cycles, each with the
  RED observed before any implementation.** `SoftDelete` (8 tests); the stamp on four models
  (5 codec tests, asserting the WRONG spelling is ABSENT); and `live(_:)`/`requireLive(_:)` over
  all NINE read paths (5 call-site tests, RED at **11 failures**). **Deliberately INERT**: nothing
  writes `deleted_at` yet, so the filter returns everything and the guard never throws — behaviour
  is unchanged, which is the only boundary in this block where that is true, and the reason it
  could be merged on its own.
  - Suite **3,192 / 0**, SwiftLint **0 / 859**, build green, coverage **29.89% (14,713/49,217)**
    — comparable to the 29.83% (14,612/48,985) of 2026-09-20, because the denominator moved only
    by the tree GROWING and both runs measured 100% of the app target.
  - **Three departures, all recorded in the TODO block**: `isLive` takes no `asOf`; the hard delete
    KEEPS its name (`softDeleteTask` is the new one); and the spec's optional rules hardening is
    **declined** — it would check the CLIENT's clock, so a phone running a minute fast could not
    delete anything, and what it prevents is a user pre-dating their own purge window.
  - **A test of mine failed in the full run and it was the good kind.** It asserted
    `SoftDeleteError.itemIsDeleted` appeared in the FETCH files — that is, it asserted the throw
    had NOT been centralised, while the design centralises it. Corrected to assert the read goes
    THROUGH `requireLive`, with the helper's own test pinning the throw.
- **Next session starts at:** `F-C3-RecentlyDeleted`, CONTINUED, from
  `handoff/START-HERE-adhd-audit-arc-C3-continued.md` — which carries all seven remaining steps
  with every decision already taken.

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

### Session 7 — 2026-09-22, arc C, block `F-C4-TagsRecentlyDeleted` — **arc C CLOSES**
- **Landed:** `F-C4-TagsRecentlyDeleted` (PR pending at write time). Suite **3,306 / 0**, SwiftLint
  **0**, build SUCCEEDED, coverage **30.03% (15,103/50,300)** — UP from 29.87%, and comparable:
  the denominator moved because the tree grew, not because the measurement extent changed.
  **All four arc C blocks are now merged.**
- **The session opened on a SPENT brief.** It asked for two device looks, `screenshots/
  drafts-to-inbox/` and `F-C3` — every one already landed (editions 73–75). Checked against
  `git log` and the register before acting. The successor opener now makes that check step 0.
- **Where the build departed from the spec, and why.** The spec's step 4 said the NEW tag wins a
  merge on restore; Step 0 (E, 2026-09-19, marked do-not-re-ask) said ASK which survives. Step 0
  wins and the ask is built. Not raised to E — it was already answered.
- **What E saw, and said:** E was asked one question — whether the Tag Editor's delete confirm
  should go the way the task and capture ones did — and answered **"drop the alert, add an Undo
  capsule"**. **Then, after close-out, E asked for a device install and gave a verdict: *"All
  those checks work nicely"*.** No device look was OWED (no `#available` site, no reduced
  site); the phone had been on `4917955`, so this was the first time either `F-C3` or `F-C4`
  had been on it.
- **Owed to E:** nothing — §A-CAPSULE was ANSWERED the same day (**Option C, DEFERRED with a
  condition: circle back and add a user IN-APP NOTIFICATION**), so it is WORK now rather than a
  question. The finding itself: The capsule E chose is MOUNTED but
  INVISIBLE in the Tag Editor: Settings is a `.sheet` and `RootBottomOverlay` sits beneath it. Every
  gate was green while this was true — `untilExists: capsule` passes because XCUITest finds
  OCCLUDED elements, and the environment that records is inherited by sheets while the drawing is
  not. **A frame caught it, which is precisely what `screenshots/` exists for.**
- **Owed to the code:** nothing for this block. One coverage hole was found and closed inside it
  (`TagEditorService.restore(tagId:)` at 0.00% — F-AdapterDrift's shape). CLAUDE.md's adapter
  counts were stale and are corrected (fifteen / seventeen).
- **Next session starts at:** `F-D1-ComposerBothDoors`, from
  `handoff/START-HERE-adhd-audit-arc-D1-composer.md`.

### Session 8 — 2026-09-23, arc D, block `F-D1-ComposerBothDoors`
- **Landed:** `F-D1-ComposerBothDoors`. Suite **3,317 / 0**, SwiftLint **0**, build SUCCEEDED,
  coverage in the register's edition 78. **The Tasks "+", "Add to <area>" and the capture disc's
  Task tile (and the widget door, which routes the same way) now open ONE composer**: a title, the
  four when-chips, and Area and Time pop-up menus. Tags, place and notes live on the task.
- **The brief was checked first** and was ACCURATE on the block. It was stale on two side facts:
  it listed §A-CAPSULE as owed (answered in `67ae03a`) and the phone as on `4917955` (E's verdict
  on C3/C4 is `236db22`). E's paste said both, and E was right.
- **Where the build departed from the spec, and why:**
  - **Prune, not keep.** The tag methods left `TaskCreateClientAdapting` and everything under it.
  - **The Time default is 15 min, always written.** That is the value on every board E approved.
    The consequence is named: tasks from the Tasks "+" door go from `nil` to 900 seconds, which
    moves them in `bestNextMove`'s ranking.
  - **The disc branch lives in `RootView+Doors.swift`** (`composer(for:)`). The spec put it inline
    in `RootView`, but that tipped the file over 400 lines.
  - **`QuickCaptureView` lost more than the spec listed.** `taskCreateClient`/`taskDetailClient`,
    the `.task` placeholder arm and the `.task` submit glyph all went too. They were dead once the
    path went.
  - **`ComposerDraftCallSiteTests` was VACUOUS for the disc door** — the tabs in `RootView.swift`
    already carry `captureClient: captureClient`. Re-pointed at `RootView+Doors.swift`; the
    red-check now catches it.
- **The finding, and it is the second block running where a FRAME beat every green gate.** The first
  after-render failed with the Area menu measuring **338 × 20.3pt** inside a card drawn 48pt tall.
  A `Menu`'s hit area is its LABEL, and the card was padded from outside. It is fixed, and the
  harness now asserts ≥ 48pt.
- **The create journey had a race, found by running the submit path for real.** It waited on
  an element that already exists under the sheet (the occluded-element trap again), and it lost
  a slow run. Fixed in the TEST, and it now passes. The app path takes 2.08s clean, and the
  emulator's write times prove the old code would have lost that run too.
- **`apple-design`:** rated Good. One High is recorded rather than fixed, because contrast is held
  for the colour arc (R9). The value text on the menu card in light is **3.22:1**. The rest is in
  the block report.
- **Owed to E:** nothing. **Owed to the code:** nothing for this block.
- **After close-out, E decided the floor (2026-09-23): *"iOS 18, before F-D2"*.** A new block,
  `F-Floor18`, sits in front of `F-D2`. It is not an audit block, but it re-orders the audit:
  `F-D2`'s Step 0 question 2 is void at an 18 floor.
- **Next session starts at:** `F-Floor18`, THEN `F-D2-ComposerKeyboardLayout`, from
  `handoff/START-HERE-floor18-then-D2.md`.

### Session 9 — 2026-09-24, the floor: `F-Floor18` (iOS 16 → 18), BEFORE `F-D2`
- **Landed:** `F-Floor18`, six commits on `chore/floor-ios18`, one PR. Suite **3,320 / 0**,
  SwiftLint **0 / 886**, CLEAN build of all four targets SUCCEEDED, coverage **30.18%
  (15,074/49,955)** — register edition 80 has every figure. **Not an audit block, but E's call
  put it in front of the whole audit** (*"do it in the fresh session BEFORE anything else"*).
- **The brief was checked first** and was accurate on the block; `main` was one docs-only PR
  ahead of the SHA E quoted (#193, a register candidate). E answered four questions at the start:
  proceed with the six-commit order; keep `InertRoutineActivityPresenter` for previews; install
  on the phone as soon as the code commits were green; and *"Can you install for me?"* for the
  iOS 18 simulator runtime — which turned out to be impossible from the CLI (register §A).
- **What moved, in numbers:** six build settings 16.0/16.1 → 18.0; **89** availability checks
  below 18 (the RED count; the spec's "~95" was a grep that included four comment lines) → **0**;
  Places' 54 `@available(iOS 17.0, *)` and the three absence flags gone; **35** deprecated
  `onChange` spellings → 0 on a clean build; eleven tests REVERSED with the reason quoted, none
  deleted; ~50 comments that stated the old floor rewritten in the same commits as their code.
- **TDD as run:** `DeploymentFloorTests` written first, RED on the untouched tree (7 failures: six
  settings + one 89-offender list), the settings test GREEN in commit 1, the gate test held in the
  working copy (backed up) and GREEN in commit 4 when the last gate went. Red-checked both ways at
  the end: a planted 17 gate → 1 failure; a planted 16.0 target → 1 failure; both restored and
  re-run green.
- **Where it departed from the spec:** `ToolsCatalog.entries` (a constant) instead of a
  parameterless `available()`; the ActivityKit files' 17 sites went with their files in commit 2;
  the inert presenter KEPT for previews (E); one widget-bundle comment caught by the final grep
  after the coverage run and fixed comment-only in the docs commit.
- **Traps met:** BSD `sed` has no `0,/re/` — the first red-check planted only the gate half, so
  the target half was re-run with a Python edit; the compiler's `onChange` list had two pins the
  spec did not name (`AppSearchCallSiteTests` twice); `PlaceTriggerEventHandler` must not contain
  the word "activity" (a call-site test), so its rewritten comments avoid it.
- **`apple-design` / RM-on:** neither owed — nothing visible changed on E's 27.0 phone.
- **Owed to E:** nothing. The device smoke PASSED the same day — E: *"Passes — all three checks
  work as before"* (app, sprint Live Activity with Pause/Stop, Focus widget). **Owed to the code:**
  nothing.
- **Later the same day — the iOS 18.0 runtime is INSTALLED and the floor path RAN.** E downloaded the
  DMG; the add failed four times ("disk is almost full" at any free space — the portal DMG is two
  layers and each failure leaked an 8 GB mount) and succeeded once the inner `Restore` image was
  extracted to the internal disk and cloned (memory `simulator-runtime-install`). Suite on the
  "iPhone 16 Pro (iOS 18 floor)": **3,320 / 0, 6 skipped** (the iOS-26-only large-title re-tap tests);
  the app boots and draws the same door as on 26.5. **Also: E answered every open Step 0 question
  ("take all the recommendations as written") and set two directives for F-F1: a thorough
  questioning round on checkpoints → heads-up, run in Plan Mode.**
- **Next session starts at:** `F-D2-ComposerKeyboardLayout`, from
  `handoff/START-HERE-adhd-audit-arc-D2-keyboard.md`, with its one Step 0 question ALREADY ANSWERED.

### Session 10 — 2026-09-24, arc D, block `F-D2-ComposerKeyboardLayout` (per-arc bypass: straight on to `F-D3`)
- **Landed:** `F-D2-ComposerKeyboardLayout`. Suite **3,337 / 0**, SwiftLint **0 / 892**,
  build-for-testing SUCCEEDED; coverage waits for the arc close (economy 1). Round 7b's L3 is
  built: the title owns the page (boxless `.title2` semibold), and the four "when" segments ride
  over Area | Time | Add in one panel above the keyboard (`.safeAreaInset(edge: .bottom)`). The
  keyboard-up bar spans **402–538pt**, against the approved 406–518pt. Accessibility sizes fall back
  to L1's stacked form. The Date segment reads "Date" and becomes "Sat 10" once picked. The picker
  offers a day only (E's Step 0), from a 320pt popover.
- **The brief was checked first** and was accurate. Two stale lines were handled as the opener
  warned: the spec's "Verified paths" template said "COMPILE-ONLY — no 18 runtime", and §0.1 still
  carried "put it to E" under the ANSWERED banner. Neither was followed. The spec's "E DECIDED"
  banner had been pasted mid-sentence into the block header, and that is now fixed.
- **THE FINDING — a mid-arc stop (#3, a design-changing finding).** Findings §L had called
  "opening Area, Time or the date picker must NOT dismiss the keyboard" UNVERIFIED, and E chose L3 on
  that condition. The block's own pin measured it on iOS 27.0: **every presentation drops the
  keyboard, and it does not come back.** That held for the SwiftUI `Menu`, for a UIKit `UIButton`
  menu tried in its place (a throwaway probe, reverted), and for the popover. Frames in
  `screenshots/composer-l3-layout/00-`. **E chose "Let it settle"** over "hold the bar and bring
  the keyboard back" and over "inline choices, no menus": the bar rides the keyboard while typing,
  settles once at the bottom, and stays there, and a tap on the title raises it. **Nothing
  re-focuses the title.** E also chose **"Keep the panel"**: the Liquid Glass container §L carried,
  which board 64 never drew.
- **Also found and fixed in-block (all mine, none E's):** the popover drew a ~60pt calendar sliver
  with Next Month off-screen (`minWidth: 320`, and the pin asserts it's whole and on screen). At
  xxxLarge the compact tiles truncated "None"/"15 min" to "No…"/"15…" (`layoutPriority` + 0.8
  scale). Close cannot reach round 7's 48 × 48 from inside a native bar item (72 × 36 on 27.0,
  56 × 56 on 18.0), so the frame was reverted and the measurement handed to `F-B1`.
- **Traps met (memory `menus-dismiss-the-keyboard`):** a Menu takes the app out of the
  accessibility tree while it is open. `app.keyboards.element.frame` THROWS on a gone keyboard. A
  vertical `TextField` is a text VIEW to XCUITest on iOS 18. A field tapped mid-presentation takes
  no focus. A `UIViewRepresentable` button eats all offered height. A freshly erased simulator
  needs a warm-up or the runner fails "waiting for AX loaded". The iOS 18.0 simulator's first boot
  ignored the no-hardware-keyboard setting.
- **Red-check:** the spec's restore of the pre-block `TaskCreateView` is a COMPILE failure (1
  error: `popUpRowHeight`, the pruned seam). Nine compiling mutations gave **16 failures across 9
  tests, all caught**; restored, **28 / 0**.
- **`apple-design`:** Good. The three §L Date-segment findings are closed. It found the XXXL
  truncation (fixed) and names the compact popover as a divergence E's Q4 governs.
- **Owed to E (batched to the arc-D review page):** the phone check, which E's decision re-scoped:
  the bar rides, settles once, and stays settled. **No RM-on pass is owed:** the selection
  recolours in place.
- **The floor behaves the same:** on iOS 18.0 the settle pin PASSED (the bar rode at 394pt, each
  choice dropped the keyboard, and the bar settled at 696pt and stayed). E's decision holds on 18.
- **Stopped at 65% context on E's warning, with D2 LANDED.** Per the bypass rule, a session that must
  stop mid-arc writes a `WIP:` opener: `handoff/START-HERE-adhd-audit-arc-D3-anytime.md`.
- **Next session starts at:** `F-D3-TasksAnytimeRow`, then the arc-D close (install first, then
  `handoff/ARC-REVIEW-D.md`).

### Session 11 — 2026-09-24, arc D, block `F-D3-TasksAnytimeRow` — **arc D closes**
- **Landed:** `F-D3-TasksAnytimeRow`. Suite **3,344 / 0** (3,337 + 7 new), SwiftLint **0**, build
  SUCCEEDED, **arc-D coverage 30.08% (15,101/50,195)**, measured once for the arc (economy 1),
  emulator UP. `MomentumTaskBuckets.swift` is at 100% (111/111). Undated open tasks fold into
  "Anytime · N": last on Momentum, collapsed by default and stored
  (`@AppStorage("tasks.anytimeCollapsed") = true`). Beyond-tomorrow stays off the board (8b).
- **The brief was checked first** and was accurate (edition 81, `5e5f924`). The emulator had been
  up 6.5h and was restarted (memory `emulator-freshness`).
- **Where the build departed from the spec, and why:**
  - **A third test pinned the old exclusion and the spec missed it:**
    `TasksServiceTests.testLoad_momentumExcludesUndatedTasks_openFilterShowsThem` asserted
    `.loaded([])` by SHAPE, so no string grep finds it. Reversed in place, renamed, round 6 quoted.
  - **`MomentumTaskBuckets.anytimeGroupId`** spells the id once. **`Tasks/TasksAnytimeHeader.swift`**
    is its own view because `TaskListView` sat at 398/400 file lines and its struct went to 257/250.
    The fold's STATE stays in `TaskListView`, bound in.
  - **The header is painted the page** (`PinnedHeaderMetrics.surfaceAssetName`). The list pins
    headers, and Anytime is the one bucket whose own rows scroll under its own header.
- **RED:** 9 tests / 14 failures of 35. The two that passed first are guards on behaviour that
  already existed: ▶ stays on Due today, and a closed undated task is evidence, not Anytime.
- **Red-check — and a VACUOUS guard it caught.** The both-file pre-block restore is a COMPILE
  failure (2 errors, `anytimeGroupId`). `TaskListView` alone gives 3 tests / 5 failures. Seven
  compiling mutations: undated→nil 5/7, Anytime-first 2/4, fold default open 1/1, rows ungated 1/1,
  pinned surface dropped 1/1, and **▶ widened to Anytime: first NOT caught.** The sprint guard used
  `contains`, and `== "momentum-dueToday" || …anytime` still contains the Due-today spelling. It
  now asserts the whole line: 1/1. Restored, 6 / 0. **Two harness slips of mine also contaminated
  the first chain**: a UI file written mid-chain did not compile, so mutation E never ran and
  `test-without-building` reused mutation C's binary. Everything was re-run clean.
- **Frames, `screenshots/tasks-anytime-row/` (9 + README), on 27.0, L / D / Accessibility XL, all
  PASSED:** folded "ANYTIME · 2", the count moving to 3 with the fold closed, and the new task
  there once opened. Header **370 × 44.0pt** at both sizes. **No scrolled frame:** four tasks do
  not scroll at the default size. At AX, a drag from the bottom row became the HOME gesture (the
  "passing" frame was SpringBoard; deleted, and the harness now asserts the app stayed in front).
  A drag from the new row was claimed by the row's swipe. The pinned surface rests on red-check H
  and E's item 14. Traps met: `xcodebuild` HUNG after a failed UI run (killed; the chain now has a
  watchdog). The restored sign-in broke the AX run, as the opener predicted (erase, then run).
- **`apple-design` (HIG pages dated 2026-09-22, fresh; read `disclosure-controls`,
  `lists-and-tables`, `accessibility`, `layout`): Good.** No Critical. What works: progressive
  disclosure is exactly `layout.md › "Use progressive disclosure…"`. `disclosure-controls.md ›
  Disclosure triangles` asks for a descriptive label, and "Anytime · N" says what is hidden and
  how much. The target is 44pt. VoiceOver hears the state (`CollapsibleSection.hint`). Nothing
  relies on colour.
  **Medium — the chevron convention.** `disclosure-controls.md` says a disclosure TRIANGLE "points
  inward from the leading edge when its content is hidden and down when its content is visible",
  and a disclosure BUTTON "points down when its content is hidden and up when its content is
  visible". The house fold (▲ folded / ▼ open, E 2026-08-28, "points AT the content") matches
  neither. The decision predates the skill (installed 09-18) and was never checked against this
  page. It is E's design and shared by Home, Journal and now Tasks, so **nothing was changed. It
  goes to E as a question at the arc close.**
  **Medium — contrast, HELD for the colour arc.** The title (bold `.caption2`, system `.secondary`
  on `PageBackground`) is **3.30:1 light / 6.11:1 dark** and passes the 3:1 bold rule. The
  `.tertiary` chevron is **1.71:1 light / 2.47:1 dark**, and it is the fold's only visual state
  cue. It is the shared glyph on three screens, and round 9 says "Leave it to the colour arc", so
  it is a register candidate. **Low — rhythm:** the 44pt fold sits ~8pt looser above its card than
  the 8pt-padded plain headers. §3's floor wins; judgment, no change.
- **Owed to E (batched):** the arc-D phone pass, `handoff/ARC-REVIEW-D.md` — D1, D2 and D3 in one
  pass, **Reduce Motion OFF throughout** (no block adds a reduced site; D3 has no motion at all, and
  grep finds no animation, transition or `#available` in its files). Plus the chevron question.
  No rules change; no `#available` site, so no Verified-paths line.
- **Next session starts at:** `F-E1-WeeklyChain`, from the arc-E opener written at this close.
- **E's verdicts, the same day (on `ca06c04`, RM off):** *"D1–D3 pass"* — all three blocks PASSED —
  and on §A-CHEVRON, *"Keep the chevron as is."* **Arc D is closed with nothing owed to E.**

### Session 12 — 2026-09-25, arc E, block `F-E1-WeeklyChain` (per-arc bypass: straight on to `F-E2`)

- **Landed:** `F-E1-WeeklyChain`. Suite **3,366 / 0** (3,344 + 22), SwiftLint **0 / 900**, build
  SUCCEEDED; coverage waits for the arc close (economy 1). The brief was checked first and was
  accurate (edition 82, `4e5f453`); the emulator had been up 13h and was restarted.
- **What shipped:** `Home/WeeklyActiveChain.swift` (a day is active on a closed task, a finished
  sprint, a sorted capture or a journal line; a week counts at N = 3 by default; ONE missed week
  per rolling four weeks is bridged when the week before it counted, and a bridged week adds
  nothing to the length). `MomentumPreferences.dailyGoal`/`focusDailyGoalMinutes` are `Int?`, and
  `weeklyActiveDayGoal` (1…7) is new. **The migration is keyed on the chain's field, not on the
  values:** a document without `weeklyActiveDayGoal` is pre-E1, so its 5/30 decode as `nil` and a
  moved Stepper survives; a post-E1 document keeps a chosen 5 (the advisor caught the naive rule
  erasing it). Close reads **"Close it — makes today count"** until today counts, and plain when
  the chain is hidden. Settings: "Set a daily goal" / "Set a daily focus goal" toggles reveal their
  Steppers; "Show weekly chain" reveals "Active days a week".
- **Where the build departed from the spec, and why:**
  - **The spec's "no review beyond Settings" did not survive decode→nil.** Every install now reads
    "no goal", so `MomentumRingCard` had to change: no ring and no "of N" without a goal, and the
    streak column gone (round 3). It keeps the ring's 126pt footprint, so setting a goal moves
    nothing. Reviewed and framed. E3 retires the card.
  - **Three `MomentumTaskContext.build` doors, not two** — Journal's too. Home answers from all
    four signals (`HomeView+WeeklyChain`, with a new `fetchLogs()` plumb riding every capture
    refresh), Journal from all four it holds, Tasks from its tasks only: an under-report shows the
    gain line on a day that already counts, and never claims a day that did not happen.
  - **Round 3's other retirements landed here:** the nudge line's "· best N" (and the now-dead
    `NudgeStreak.bestRun`), and the Home Screen widget's focus streak (the stat and the goal bar's
    "· N streak"; the wire field stays so an old widget binary decodes). The widget's goal bar is
    now gated on a set goal (`WeekStats.hasDailyGoal`), and so is the in-app focus widget's.
    **`streakLine` is deleted, so E4's "delete `streakLine`" item is already done.**
  - **Two more tests reversed than listed:** `testTrailingWeekClosureFlags_…` (the compiler found
    it) and `NudgeStreakTests.testRuns_currentAndBest`. Every reversal names its origin; the seven
    `bestStreak`/`streakLine` tests became `WeeklyChainCallSiteTests`' absence sweep.
- **RED:** the new tests against the old code are a COMPILE failure (72 error lines across six
  files). **Red-check, eleven compiling mutations, all caught, restored 90 / 0:** chain reads tasks
  only 12 tests; repair always 1 (the widening case — exactly one test sees it); repair never 4;
  label inverted 4; nil goal crosses 1; migration always legacy 2; legacy 5 kept 1; current week
  never counts 1; Home drops the journal 1; chain toggle ignored 1; "· best" restored 2. No test
  survives both halves of a pair.
- **Frames, `screenshots/weekly-chain-goals-off/` (5 × L/D + README), on 27.0, both PASSED.** Three
  harness traps cost reruns, none an app bug: my watchdog matched the suite's START line and
  killed a run mid-test (now keys on passed/failed/TEST lines with a 900s ceiling); "Close it"
  matched Today's hero on the parked tab, so the detail was never opened; and the seeded title's
  `firstMatch` was Today's copy at x≈10,032. **The hidden Today tab stays in the hierarchy — pick
  the ON-SCREEN match** (`onScreen(_:)`). The UI simulator was erased after.
- **`apple-design` (pages dated 2026-09-22, fresh; `toggles`, `steppers`, `settings`, `layout`,
  `writing`, `accessibility`, `typography`): Good.** No Critical, no High. What works: switches only
  in list rows (`toggles.md › Mobile`), the value beside each Stepper (`steppers.md › Best
  practices`: "Make the value that a stepper affects obvious"), defaults that give "the best
  experience to the largest number of people" (`settings.md`) — no goal nobody chose; rows 52pt,
  the close 370 × 70pt. Sentence case matches the section's existing rows (`writing.md`: one style
  per element type). **Fixed in-block (Medium):** "Active days a week" stayed visible with the chain
  hidden — now revealed with it (`layout.md`: "Use progressive disclosure"), pinned by a call-site
  assertion. **Low, left:** the momentum footer runs nine lines (judgment); the no-goal count's
  fixed 126pt frame may crowd at accessibility sizes, as the ring always did — E3 retires the card.
  **For E3:** Today's hero reads plain "Close it" while Task Detail reads the gain line.
- **Owed to E (batched to `handoff/ARC-REVIEW-E.md`):** the device look — Settings' reveal rows,
  Today's no-goal count, the gain line. No `#available` site, no reduced site, no rules change.
- **Next:** `F-E2-NextStepField`, same session.

### Session 13 — 2026-09-25, arc E, block `F-E2-NextStepField` (same session as 12; stops here, E3 in a fresh session)

- **Landed:** `F-E2-NextStepField`. Suite **3,375 / 0** (3,366 + 9) after a CLEAN build, SwiftLint
  **0 / 902**; coverage waits for the arc close.
- **What shipped:** `next_step` (tasks' snake_case) on `TaskItem`, `TaskSummary` and `TaskDetail`;
  `TaskUpdatePayload.nextStep: String??` (cleared = `FieldValue.delete()`), in `isEmpty`, written by
  `FirestoreFieldPayloads.taskUpdate`; `TaskEditedFields.nextStep: String?` where `nil` = never
  staged, so no older constructor can read as an edit; trimmed like `notes`. Task Detail's row sits
  beside Notes, staged behind Save and autosaved on the way out (`F-C2`). **No rules change** —
  `firestore.rules` grants owner CRUD on the whole `tasks` document.
- **RED:** 19 compile errors in the new file. **Red-check, six compiling mutations, all caught,
  restored 56 / 0:** camelCase key 2; `isEmpty` blind to it 2; unstaged counted as an edit 1;
  untrimmed 2; detail never seeds 1; `TaskSummary` key dropped 1.
- **`apple-design` (pages 2026-09-22, fresh; `text-fields`, `writing`, `accessibility`,
  `typography`, `layout`): Good, after one in-block fix.** **High, fixed — found in the block's own
  frame:** once saved, the placeholder "Next Step" vanished and the line read as an unnamed note.
  `text-fields.md › Best practices`: *"Because placeholder text disappears when people start typing,
  it can also be useful to include a separate label describing the field to remind people of its
  purpose."* Now a footnote caption "Next Step" (hidden from VoiceOver) over a field whose
  placeholder is "What to do first", with `.accessibilityLabel("Next Step")`, pinned by the
  call-site test. Title case matches the form's other rows ("Due Date", "Life Area") —
  `writing.md`: one style per element type. **Low, left:** Notes has the same placeholder-only
  shape (pre-existing; a register candidate, not this block's).
- **Machine traps, none of them app bugs:** (1) **the Firebase emulator had half-died** — the
  session-start restart ORPHANED the old Firestore JVM on 8080, the new emulator later crashed, and
  Auth/Storage were down while 8080 said 200: 32 emulator tests FAILED instead of skipping and every
  UI render died at sign-up. Killed (after checking its `--project_id`), restarted, all three ports
  probed; memory `emulator-freshness`. (2) **A stale incremental build CRASHED the app** after the
  label fix: wrapping the `TextField` in a `VStack` changed `addMoreInfoSection`'s underlying type
  and `TaskDetailView.body` was not recompiled (`initializeWithCopy for TextField`, SIGSEGV) — the
  unit suite stayed green because no unit test renders that body. Clean build; memory
  `opaque-type-incremental-segv`. (3) A lazily built Form has no Save element below the fold until
  scrolled to. (4) Accessibility XL needs an erased, warmed simulator.
- **Frames, `screenshots/next-step-field/` (3 × L/D + README), on 27.0, after a clean build: light
  and dark PASSED.** Accessibility XL measured the field at 338 × 48pt (it grows) but failed at the
  typing step and its bundle was cut short by the watchdog — no AX frame; left for E's pass.
- **Owed to E (batched to `handoff/ARC-REVIEW-E.md`):** the Next Step row and its caption on the
  phone, including at a large text size. No `#available` site, no reduced site, no rules change.
- **Next session starts at:** `F-E3-OneCardToday`, from `handoff/START-HERE-adhd-audit-arc-E3-onecard.md`
  (a `WIP:` opener; this session stopped at ~55% context on E's note, at a clean line).

### Session 14 — 2026-09-26, arc E, block `F-E3-OneCardToday` (BUILT; stopped at ~71% on E's note, NOT landed)

- **Where it stopped:** every commit green and pushed to `feature/adhd-e3-onecard` (`9e1cdd5` →
  `b0219a9` + this hand-off); **no PR** — three gates still owed: the evidence frames
  (`screenshots/today-one-card/`), the `apple-design` review over them, and the mutation red-check
  (scripted: `scripts/build-loop/e3-mutations.py`). Opener: `handoff/START-HERE-adhd-audit-arc-E3-finish.md`.
- **The brief checked out** against git (`df2ab2f`) and edition 84; emulator restarted (12h51m old,
  JVM exited cleanly, all three ports probed on the new processes); unit sim erased.
- **Subagents mapped the block first** (three Explore agents: retirement call sites, slot-order
  inputs, tests that read Today's files) — which is how the build found what the spec did not say:
  1. **`FocusAnalyticsSection` was the ONLY writer of `publishedHistory`** — the weekly chain's
     sprint signal, the gain line, the week review and the widget all read it. Deleting the section
     as specced would have blanked all four with no test failing. Home reads it itself now, BEFORE
     the section's call went (the advisor's ordering: every commit shippable, Nudges never
     unreachable).
  2. The widget already disagreed with Today (`topTask` vs `bestNextMove`); it now publishes the
     card's `headlineTask`.
  3. `NudgesService.celebrate` was a `let` set in `init` — Tools could not have handed it the centre,
     so a dismissal on the Tools-pushed screen would have lost the seven-day streak. Now a `var`
     wired in `.task`, like `recordAction`.
  4. The Home reorder chain was Today-only down to `FirebaseManager.reorderLifeAreas` — retired
     whole, not left dead.
- **RED → GREEN, four stages:** 70 compile errors → 41 / 0 (pure); 3 / 3 → 10 / 0 (history); 6
  compile errors + 5 guards → 130 / 0 (doors); 13 compile errors + 15 guards / 46 assertions →
  **full suite 3,395 / 0**; Q2: 6 compile errors → 32 / 0. SwiftLint **0 / 908**.
- **E took two decisions mid-build** (rendered with a throwaway `ImageRenderer` probe, HIG-checked,
  asked): **Q1 "A · Side by side"** — the gain line wraps inside H1's half-width Close (2 lines;
  3 at xxxLarge); the render caught the pair going RAGGED at xxxLarge (84pt beside 48pt), fixed with
  one-height pairing (`buttons.md › Style`: same size = one set of choices). **Q2 "B · '3 of 5 done
  today'"** once a goal is set — with the ring gone the line is the only place a chosen goal shows.
- **`apple-design` pages refreshed 2026-09-26** (layout decision rule): only `hig-lookup.md`'s date
  changed; no page a settled decision rests on moved.
- **Machine:** `scripts/build-loop/` now holds `t.sh`, `full.sh`, `ui.sh` and the E3 mutations, so
  the next session does not re-derive them. **The first harness run (`TodayOneCardRenderUITests`,
  light, 27.0) produced no frames and no app verdict:** the walk SKIPPED on "emulator not running"
  while 8080 answered 200, and the Resume test failed on `kAXErrorIPCTimeout` — both consistent
  with load during a cache-cleared simulator's first boot, cause unverified. Sim erased after.
- **Owed to E (batched to `handoff/ARC-REVIEW-E.md`):** all of E3's states on the phone, and the
  RM-on pass the spec names for the close-from-card capsule.


### Session 15 — 2026-09-26, arc E, block `F-E3-OneCardToday` FINISHED and landed (per-arc bypass: straight on to `F-E4`)

- **The brief checked out** against git (`b1b7e49` on the branch, `main` `df2ab2f`) and edition 85.
  Emulator restarted (2h35m old; the parent TERM left NO orphaned JVM this time — `lsof` showed the
  new PIDs on 8080 / 9099 / 9199). Unit sim erased; 27.0 sim booted and left idle before every UI run.
- **Warming the simulator fixed last session's frameless run:** the first light run went 2 / 2 with
  frame 04's `value` and the one-height pair asserting as written — neither needed the tuning the
  opener feared. That supports first-boot load as last time's cause; it does not prove it.
- **The frames found two things no test had, and E decided both from real renders:**
  - **Q3 — the capture disc covered "Week review ›" at rest** in EVERY Today frame with a two-row
    "then" list, light and dark. `CaptureDiscClearanceUITests` stayed green: it asserts the row is
    clear once scrolled to rest, and it was (~50pt). **E: "B · Follows the count"** — built RED
    (3 failures) → GREEN (33 / 0) as `TodayDoneLineLabel`, ONE view tree whose layout switches
    (`AnyLayout`), stacking from xxLarge — not a `ViewThatFits` of two copies, because the daily
    goal's pop is an `onGeometryChange` reporter and a hidden copy must never report a position.
  - **Q4 — "Close it" measures 2.74:1 in light** (`StateGo` on its own 12% tint; from the colorsets).
    New in E3: Close was a solid green button before. **E: "A · Keep, send to colour arc"** — the
    colour arc's first item, register §A0.
- **Three harness faults fixed** (committed separately): the "Save Password?" sheet re-appeared over
  frame 02 (now cleared inside `attach`); the Tools row sat under frame 05's undo capsule (lifted);
  the AX3 card STACKS its pair by design, so "one height" is a side-by-side rule (now asserted as
  stacked at AX3). **A slip, owned:** the first harness commit did not compile (`attach` must be
  `@MainActor` to call the prompt helper) — pushed unbuilt, caught by the next run, fixed in `e519b2f`.
- **Red-check** (`scripts/build-loop/e3-mutations.py`, everything committed first): pure batch →
  exactly its six tests (8 assertions), incl. the WIDENING case; restored + rebuilt 67 / 0. Source
  batch by `test-without-building` → exactly its six guards (Q3's added); restored 20 / 0.
- **UI chain, one scripted run** (erase + warm between steps): frames L / D / AX3 green; seven journey
  classes, **11 tests, 0 failed, 0 skipped**. `IOS27CompatSweepUITests` NOT run — its only change is
  `openNudgesFromTools`, exercised by `FirstRunJourneyUITests` and `CaptureDiscClearanceUITests` here.
- **Figures:** full suite **3,397 / 0**; SwiftLint **0 / 908**. Coverage waits for the arc close.
- **`CLAUDE.md`, landed with E3** (E agreed 2026-09-26): Project status says what Today is now; the
  build-loop bullet points at `scripts/build-loop/`; the repo-layout row names the drivers.

#### `apple-design` review (§7.6) — Today's one card

##### Design review: Today — one card, a "then" list, a done line (`F-E3-OneCardToday`)

Pages: refreshed 2026-09-26 (`hig-lookup.md` "Generated … on 2026-09-26"). Read for this review:
`accessibility.md`, `layout.md`, `typography.md`, `color.md`, `buttons.md`, plus the always-load set.
Artifact: real harness frames (iPhone 17 Pro · iOS 27.0, light / dark / AX3) + colorset hex values.

##### Summary
**Good**, with one Critical that E has decided to hold for the colour arc. The thesis is exactly
round 3's: *one next thing* — a single prominent Start, a quiet pair, a short "then" list and a
done line, where Today used to show ~50 numbers (HOME-03). The one thing it is remembered by is the
card itself: one blue button on a calm page.

##### Critical
- **"Close it" words, light: 2.74:1** (`StateGo` #0AA84E on its own 12% tint over `CardSurface`
  #FFFFFF). Under even the 3:1 bar for bold text. Dark reads 5.41:1.
  - **Why:** `accessibility.md › Vision`: *"Strive to meet color contrast minimum standards"* —
    its table: up to 17pt 4.5:1; 18pt 3:1; bold 3:1. New in E3: Close was a solid `StateGo` fill with `OnStateGo` words before.
  - **Status: E's decision (Q4, 2026-09-26) — "A · Keep, send to colour arc".** Shown the
    primary-words alternative (16.89:1). Recorded in register §A0 as the colour arc's FIRST item.
    Not fixed here, by E's call.

##### Improvements
- **High — fixed in-block (E's Q3):** the capture disc covered the done line's "Week review ›" at
  rest in every Today frame with a two-row "then" list. `layout.md › Visual hierarchy`: *"Group
  related items to clearly express related information or functions."* The link now follows the
  count on one line and stacks from xxLarge (`typography.md › Supporting Dynamic Type`: *"Keep
  text truncation to a minimum as font size increases."*).
- **Medium — register §A0 (colour arc):** "Not this one" 3.97:1 light (passes 3:1 at 15pt
  semibold, under 4.5:1); the done line's count 4.04:1 light (`LabelSecondary` on the page, 15pt
  regular — the app-wide secondary label, the same relationship §A0 already holds at 4.25:1).
- **Low — at AX3 the capture disc sits over the right end of "Not this one" at rest** (measured:
  the stacked pair runs to y=769 against the disc's band). The page is long at AX3 and scrolls it
  clear, and the button's left two-thirds stays hittable — the same class as Q3, recorded rather
  than re-asked; register candidate beside `F-B1`.
- **Low — register candidate for `F-B1`:** the corner pin is 44 × 44pt, round 5a's number;
  round 7 set 48pt for corner controls. `accessibility.md › Mobility` (*"Offer sufficiently sized controls"*):
  iOS default 44 × 44 — so it meets Apple's bar and misses only the house's stricter one.

##### Craft notes
- **Boldness spent in one place.** Exactly one filled, accent-coloured control per screen state
  (Start or Resume); `buttons.md › Style`: *"Keep the number of prominent buttons to one or two per
  view."* The pair is the SAME size, so it reads as one set of choices (*"Use style — not size —
  to visually distinguish the preferred choice"*); the one-height rule held at xxxLarge.
- **Structure encodes information.** The eyebrow says why this task has the slot ("Suggested · Due
  today", "Next · Pinned", "Paused · 5 min in") — true, and `.secondary` rather than accent (round 9:
  blue means tap me).
- **Remove one accessory:** nothing obvious. The chips carry time and area the Start label and
  the "then" rows also need; the next-step caption earns its place (`F-E2`'s High).

##### What works
- AX3: the compact card moves the buttons under the title with nothing dropped — Start above the
  fold is ASSERTED by the harness, not eyeballed (`typography.md`: *"keep primary elements toward
  the top of a view even when the font size is very large"*).
- Every close raises the same undo capsule as the other three closes (round 1).
- The Resume card offers no "Not this one" — a paused sprint is not a suggestion.

##### Named, not findings (settled here)
- The custom six-item `AppTabBar` (its AX3 "To…" truncation is the approved bar's own behaviour), the in-app appearance override, and `.ultraThinMaterial` in
  content (§7.6) — not reported. No Confirm celebration on this screen.

##### Platform notes
- SwiftUI, iOS 18 floor; no `#available` site in this block, so no Verified-paths line. The
  press scale (0.97, spring) is every house button's; the card adds no appear animation of its own.
  RM-on pass owed: the undo capsule's arrival from the card's Close, and the pin/skip swaps (no
  animation — a glyph swap and a content swap).

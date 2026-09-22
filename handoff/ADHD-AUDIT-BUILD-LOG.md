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
| `F-C3-RecentlyDeleted` | soft delete for tasks and captures; one row in Tools | **IN PROGRESS** — read side landed and INERT | PR #184 | — |
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

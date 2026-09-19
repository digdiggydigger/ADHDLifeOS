# The ADHD / neurodivergent UX audit — design record (2026-09-19)

*A DESIGN RECORD despite the file name (CLAUDE.md, "Session handoff": `SESSION-OPENER-*` files are
permanent, never archived). It holds the yardstick E set for the ADHD UX audit, so that every
finding and every option offered in the audit — and every block built from it — can be traced back
to E's own words. The evidence brief it rests on is `SESSION-OPENER-adhd-ux-audit-research.md`.*

## How the audit was opened

E's brief (2026-09-19), in summary: target the **iPhone 18 Pro simulator**; first research the
executive-functioning struggles of the ADHD and neurodivergent community (a research sub-agent
produced the evidence-graded brief beside this file); then ask E 7–10 questions across five areas;
then audit. Four operating rules for the execution phase, verbatim in intent:

1. **Alternatives, framed for neurodivergent needs.** For every flaw, propose **2–3 distinct
   alternatives**, each evaluated by how it helps users with day-to-day and lifetime executive-function
   struggles. **Wait for E's selection before editing the codebase.**
2. **Maximise tool use** — `apple-design`, `apple-skills`, `ui-ux-pro-max` on every screen state;
   sub-agents for architecture / UX logic / accessibility checks.
3. **Custom design tokens first.** Apple defaults only where a token causes an HIG accessibility
   violation, or to demonstrate a native alternative.
4. **Branch protection** — the audit lives on `feature/adhd-ux-audit`; nothing on `main`.

Environment: iPhone 18 Pro / iOS 27.0 simulator (`-destination 'platform=iOS Simulator,name=iPhone
18 Pro,OS=27.0'`), Xcode 27.0 (whose simulator front-end is **DeviceHub.app**, not Simulator.app),
the Firebase emulator, and a throwaway emulator account E created by hand (`audit@test.local`).

## E's answers — verbatim

### 1. Visual Density & Noise Reduction
* Q1 (Active Goal Hero): **Suggested and then pinned.** The app should suggest the top priority task
  based on due time/context, but allow me to pin/lock it so layout shift never causes cognitive
  disorientation. **Display scope:** Show Title + 1 concrete next step + time context (e.g., "Next:
  Draft outline • 15 min").
* Q2 (Focus Sprint): **Timer + Current Task + Primary Actions (+5m / End) ONLY.** Zero peripheral
  clutter during live sprints. **No looping or pulsing animations** while at rest. Include a subtle,
  non-intrusive 5-minute remaining heads-up notification/haptic transition.

### 2. Navigation & Exit Paths
* Q3 (Undo vs Confirmations): **Soft-delete ("Recently Deleted") for tasks/captures** to eliminate
  destructive risk without pop-up modal fatigue. For quick actions (e.g., completing/triaging), use an
  **Undo toast that persists until the next user action**.
* Q4 (Sheets & Typing): **Rule:** Maximum **1 sheet deep** as the strict baseline. *(Note Q4.2: In due
  course, I will add the ability to go deeper than "one sheet" for certain specific areas, but assume
  1 sheet is the standard for this audit).* When a composer containing typed text is swiped down,
  **silently save as a draft / quick capture item** in the background—never block with a modal and
  never lose user input.

### 3. Design-Token Alignment
* Q5 (Token vs Apple Primitives): **Custom tokens win for brand identity and bento card
  structures**, PROVIDED they do not violate Apple HIG accessibility standards (contrast, touch
  targets, Dynamic Type).
* Q6 (Colour Scope): **Option 2:** Fix color misuse (ensure the correct tokens are applied
  consistently) but do not add new palette values during this audit pass.

### 4. Touch, Ergonomics & Sensory Feedback
* Q7 (Gestures & Touch Targets): **HARD RULE:** Every swipe, drag, or long-press gesture MUST have a
  visible, single-tap alternative. Key interactive targets should be enlarged to **48-52pt touch
  targets**.
* Q8 (Reach & Surface Scope): Primary actions inside sheets must sit at the **bottom within easy
  thumb reach**. Widgets and the Dynamic Island ARE in scope.
* **NEW (Overlooked Area - In-App Notifications):** We must actively utilize SwiftUI's
  `.sensoryFeedback`, haptic triggers, sounds, and subtle transition animations for in-app
  notifications. These tactile cues are essential grounding tools for neurodivergent users to confirm
  actions without requiring visual reading.

### 5. Cognitive Friction & Motivation
* Q9 (Returning After a Lapse):
  - Replace red "Overdue" tags with neutral **"Still open" or "Pending"**.
  - Reframe streaks to **"Days Active This Week"** with automatic repair days.
  - After 7 days away, greet the user with a 1-tap "Fresh Start" option to clear visual debt.
* Q10 (Rewards & Deliberate Friction):
  - Target **1 tap from task visibility to active sprint**.
  - Deliberate friction is ONLY allowed when exiting a live sprint early or executing permanent
    deletions.

### Scope Decisions & Tool Permissions
* Decision A (Execution Workflow): **Propose 2-3 alternatives per issue within this session**, wait
  for my selection, and then **Provide me with your professional opinion on whether a new session is
  needed or whether we can build in the current**
* Decision B (Coverage Scope): Primary focus is **iPhone 18 Pro on iOS 27.0**, covering **both Light
  and Dark mode** and text scaling up to **Dynamic Type AX3**.
* Decision C (Gaps vs Existing Features): **Judge what exists first**, but flag critical
  neurodivergent capability gaps at the end.

### Overarching guardrails
1. **The Clutter Mandate:** You MUST ENSURE that 'ADHD LifeOS' does not become a cluttered,
   overwhelming, confusing, or indecisive application. Remember exactly who our target audience is and
   what their specific needs are. Every alternative you propose must aggressively reduce cognitive
   load, provide clear and decisive paths, and fulfill the strict requirements of the
   ADHD/Neurodivergent community.
2. **The "Claude Design" Platform:** permitted when formulating and proposing UI redesigns, but only
   where Claude judges it necessary and beneficial for the task at hand.

Also, the same day: *"You must always ensure to ask me questions directly … & … utilise any
subagents and skills and plug-ins and MCP's that may also assist you in your work."* and *"I would
be happy for you to use as many subagents to assist your current workload."*

## How these answers sit against the house rules (read before building)

- **Q7's "48–52pt"** raises the bar for KEY targets only. §3's 44pt stays the floor everywhere else.
  A target size is a component dimension, not §2 spacing, so 48/52 break no grid rule.
- **"NEW — `.sensoryFeedback`"** is honoured through the house helper `.haptic(_:trigger:)`
  (`Theme/Haptics.swift`), which IS `.sensoryFeedback` on 17+ with a UIKit floor on 16 (§3, §7.1).
  Do not call `.sensoryFeedback` directly.
- **Sounds as grounding cues** pull against the research (about 40% of autistic people currently have
  reduced sound tolerance) and against today's default (`celebrationSoundsEnabled = false`). This is
  a tension to put to E with options, not to resolve silently.
- **Q4's "silently save as a draft"** differs from HIG `modality.md` ("getting confirmation before
  closing"). E's rule governs; the audit report names the divergence once.
- **Q8's "primary actions at the bottom of sheets"** differs from the iOS sheet convention of a
  top-trailing confirm. E's rule governs.
- **Q3's soft delete** changes the Firestore schema and `firestore.rules`. Rules are published by E
  only (CLAUDE.md "Architecture notes").
- **Q6** keeps the colour arc's hold intact: misuse fixes only, no new colorset values.
- **Settled, never re-litigated by this audit:** the Settings appearance override, the Confirm
  celebration's Reduce Motion waiver, the custom six-item `AppTabBar` and its constants, standard
  materials in content, the two spacing waivers (`peekStep = 14`, `floatingPaddingHorizontal = 12`),
  and the capture / pencil disc design.

## Decisions collected in the options rounds (verbatim option labels)

**Round 1 — conflicts between older decisions and the new answers (2026-09-19):**
- **Closing a task → "Undo until next action".** Every close (the circle, a full swipe, Today's hero) shows the same undo,
  which stays until the user's next action; after that, closing is final again. This RETIRES the earlier addendum
  "closing is one-way" (`TaskRow.swift:14`) as far as the undo moment goes.
- **Starting a sprint → "1 tap where a task stands alone".** One tap from Today's hero, Due-today rows, task detail and
  search results; the long Tomorrow/Later lists stay quiet. This AMENDS the b11 call ("sprint-starting is a today thing").
- **Sound as a grounding cue → E, verbatim:** *"I appreciate what you have found in your research, but this application is
  not targeting autistic people. But specifically ADHD people. So my original requests still stand firm on this point."*
  So: sounds are a first-class grounding cue beside haptics and subtle transitions (the NEW request above), and **the target
  audience is ADHD specifically** — autism-specific evidence in the research brief (sensory over-responsivity, intolerance of
  uncertainty) carries less weight in this audit than ADHD evidence.
- **Gym steps (a check, not a decision):** E's own screenshots show the departure step saved as a Journal line ("Log today's
  workout") and no arrival journal line; the editor also shows Save at the top, jargon footers ("monitoring slots", "At-Place
  tasks") and "Drag to reorder" with no tap alternative.

**Round 2: nothing lost, everything undoable (2026-09-19, session 2; evidence board `53-ROUND-2-evidence-board.jpg`).**

Every option, whichever was chosen, also carried two things. Task detail's blocking "Discard changes?" becomes autosave
with swipe-back restored. And Cancel becomes "Close", because `sheets.md` says Cancel means "without saving".
- **Unsent text → "Inbox catches it".** A composer closed with text files it into the Capture Inbox as a note. A bar,
  "Kept in your inbox · Reopen", stays until the next action.
- **Undo shape → E, verbatim:** *"'Option 1.' But the "bottom bar" Needs A visual overhaul"*.
  - Option 1 = one bottom bar everywhere: the same spot above the tab bar, clear of the disc, a 48pt Undo with the
    standard ↶ symbol, naming what it undoes.
  - The overhaul's look is a follow-up (renders owed).
- **Where Recently Deleted lives → "One row in Tools"** (not in context, not Settings). Kept 30 days (stated as the
  default in the question; E did not object).
- **What goes to Recently Deleted → E, verbatim:** *"Tasks + Captures + Tags (If A recently deleted tag is restored,
  What happens to Items that previously had this tag? - Such as a photo capture having a tag. The tag then gets deleted.
  But Then the tag is restored. What then happens? Can the tag be restored to the original photo capture it was assigned
  to?)"*
  - Places, nudges and place actions keep confirm-then-permanent delete (Q10).
  - Journal delete goes to the gaps list.
  - Code fact behind E's question: membership is a `tag_ids` array on each task or capture document. Today's delete
    (`FirebaseManager+Tags.swift`, `removeTagEverywhere(_:replacingWith: nil)`) strips the id from every item in one
    batch, so a restore would come back with no links. The answer is a follow-up question.
- **Follow-ups, same day:**
  - **Tag restore → "Back on every item".** While a tag sits in Recently Deleted, its `tag_ids` links stay on the
    items, hidden (no chip, no filter). Restore brings it back on every task and capture it had. The links are
    stripped only at the 30-day purge. A same-name tag created meanwhile is merged on restore (the Tag Editor's
    existing merge).
  - **How the undo-bar overhaul is shown → "Throwaway Swift renders".** A test-only file draws the options with the
    real tokens (light, dark, AX3), placed on real sim frames. No app code changes. The file is deleted after E
    chooses, and only the images are kept. This permission also covers the Today renders (round 3) and the sprint
    renders (round 4).
  - **The undo bar's look → "A · Capsule in the disc row"** (board `54-ROUND-2b-undo-bar-options.jpg`; frames in
    `screenshots/adhd-ux-audit/round-2b-undo-bar/`).
    - It sits exactly where the search row is, left of the + disc. Nothing moves and nothing stacks.
    - On Tasks it stands in for the search row until the next action.
    - Shared by all three options: a 48pt Undo capsule tinted like the tab bar's selected pill (accent at
      `AppTabBarMetrics.chipTint*`), the standard ↶ symbol, a glyph plus words naming what happened, a stacked layout
      at accessibility sizes, and a haptic on appear and on Undo.
    - The draft bar ("Kept in your inbox · Reopen") uses the same design.
    - Rejected: B (a card above the tab bar; the disc jumps ~88pt, breaking research 3.2) and C (a floating pill over
      the list).

**Round 3: Today (2026-09-19; board `55-ROUND-3-today-options.jpg`, stitched frame `56-today-full-length-stitched.jpg`).**

Sim state note: the Today frames for this round were captured after a clean-up. A throwaway 5-minute sprint was
confirmed, and the leftover Home close ("Reply to Priya") was undone. So the ring reads "3 of 5", where frame `47` read 4.
Frame `56` is the first clean full-length Today in the audit: 3,125pt stitched from 350pt slow scrolls, with the
bottom furniture cut out.
- **Structure → "C · One next thing".** Today shows ONE card, then a short "then" list, and nothing else. At a place,
  the live routine takes the slot; elsewhere the hero does (480pt, half a screen). Rejected: B "Today is only 'now'"
  (Recommended, 880pt) and A "Now first, rest below" (1,517pt).
  - Consequences, owed to round 5: what takes the one slot (a pinned task vs a live routine vs a due nudge, in what
    order), where a due nudge goes, and where the Week review door lives now that Today has none.
  - Life areas leave Today (the Areas tab has them), and so does the inbox peek (the Captures tab and its badge).
- **Streaks → "Weekly chain + auto repair".** A week "counts" once the user is active on N days they choose. One
  missed week a month is repaired automatically. The other two streaks go: the closing streak "6 days · Best is 6"
  and the focus "2 Day Streak". The nudge "best 2" goes too. Open detail: the default N.
- **Charts → "One bar chart in Week review".** Keep the Mon–Sun bars and drop the 7-day trend line (its smoothing
  drew values below zero). Both charts come off Today.
- **Preset goals → "Off until you set one".** No ring and no percentage until the user chooses a goal in Settings.
  This covers the daily close goal (5) and the daily focus goal (30m).
- **Today: alternative ideas (E's side request; the list is in `ADHD-UX-AUDIT-WORKING-FINDINGS.md` §K) → E, verbatim:
  *"Add 1, 3, 4, 5, 6, 7, 8, 9, 10."*** Only #2 (work sized to the gap) was left out. Where each goes:
  - **Into the one card (round 5 designs them with the hero):**
    - 1 "Leave by" time card: needs calendar read, a new permission.
    - 3 "Not this one" swap.
    - 4 Resume card.
    - 8 time you can see: a shrinking bar to the next commitment, which needs the calendar or a deadline.
  - **Into Today's states or beside the card:**
    - 5 morning first-open screen: needs wake-event triggers, the Scope C gap, now WANTED.
    - 6 evening "tomorrow's first thing".
    - 7 Fresh Start after 7+ days away: E's Q9, a new flow.
    - 9 one quiet "done today" line under the card. E accepted this bend of C's "nothing else".
  - **Outside the app:** 10 the one card on the Lock Screen, a new accessory-widget family.

**Round 4a: the sprint (2026-09-19; board `57-ROUND-4-sprint-evidence.jpg`).**
- **Lock Screen controls → "+5m only; End in the app".** One control. Ending early happens in the app, where its
  confirm lives (Q10).
  - This retires the Live Activity's unconfirmed Stop (LA-01) and its ~34pt Pause/Stop pair.
  - Shared by every option: a tap opens the sprint (a `widgetURL`, LA-03), and the minimal Dynamic Island shows the
    time left (LA-04).
- **Extending a sprint → E, verbatim:** *"How about: +30 Seconds and +1 Minute and +5 Minute sprint time
  extensions?"* E proposed rather than chose, so round 4b confirms it. The Lock Screen keeps +5 min alone, per the Q1
  answer.
- **5-minute heads-up → "Heads-up replaces checkpoints".** ONE alert at 5 minutes left: in the app a haptic, a soft
  sound and the ring changing colour; when away, a notification. The mid-sprint checkpoints (the "In-Sprint Nudges"
  stepper, `FocusNotificationPlanning.checkpoint`) and their jargon go.
- **Pause → "Keep Pause in the app".** The in-app set is Pause · extensions · End. A paused sprint shows "Paused · N
  min in · Resume", which feeds the Resume card (Today idea 4).

**Round 4b (same board):**
- **The sprint sheet → "Focus screen + Details".** A big ring with the time left, the task title, and the controls
  pinned at the bottom (Q8). One "Details" row reveals the timeline and session stats.
  - Every option carried: the card's timer grows (11pt today), every control gets a haptic, and the grabber stops
    stealing taps from the title.
- **Ending a sprint → "End".** The word is End everywhere, and the confirm reads "End sprint?". "Close it" only ever
  means "the task is done".
- **Calendar access → E, verbatim:** *"Yes - add BOTH read-AND-write capabilities."*
  - Asked in context, never at launch.
  - Build notes:
    - Read + write is FULL calendar access: `requestFullAccessToEvents` on 17+, `requestAccess(to: .event)` on the 16
      floor (§7.1).
    - It needs a privacy-manifest line and a purpose string that says what the app WRITES. That write purpose is
      asked in round 4c.
- **Extensions → E, verbatim:** *"Instead of five controls, Add a sixth control, allowing the user to enter a custom
  time extension"*.
  - The in-app set is Pause · +30 sec · +1 min · +5 min · Custom · End. The Lock Screen keeps +5 min alone (4a).
  - How six controls fit the card (338pt inner width), and how a custom time is entered without a second sheet (Q4
    max-1), are asked in round 4c with renders.

**Round 4c: six controls, custom time, calendar write (board `58-ROUND-4c-sprint-controls.jpg`, frames in
`screenshots/adhd-ux-audit/round-4c-sprint-controls/`; real-token renders from a throwaway probe, deleted after).**
- **The card's six controls → "V2 · two rows".**
  - The four time buttons sit on top (+30 sec · +1 min · +5 min · Custom, text only); big Pause and End sit below.
  - Card 222pt, against 148pt today. At AX3 the time row wraps to 2×2. The collapsed card keeps Pause only.
  - The focus screen uses the same two-row block, taller (56pt).
  - At accessibility sizes the card's ring grows (128pt) and sits above the title, so the timer never truncates.
  - Rejected: V1 (six in one row, 174pt, 11pt labels) and V3 (an "Add time" menu, 166pt, extensions become 2 taps).
- **Custom time → "Inline stepper".** Custom opens a row on the focus screen: − N min + · Add. Tapping Custom on the
  card opens the screen with that row ready. Whole minutes, no keyboard, no second sheet (Q4 max-1).
- **Calendar write → "Block time for a task".** From a task, the user picks a free slot and it becomes an event; the
  event opens the task.
  - The app writes ONLY to its own "ADHD LifeOS" calendar and never edits or deletes the user's existing events.
  - The purpose string says exactly that.
- **Round 4 carry-overs, stated as defaults (no question needed; E may overrule):**
  - **Card timer:** grows from `.caption2` (11pt, the app's smallest text) to `.callout` monospaced semibold (about 16pt)
    on the 70pt ring. At accessibility sizes the ring is 128pt and sits above the title (as rendered in board `58`,
    which E chose from).
  - **Haptics differ by meaning**, through the house `.haptic(_:trigger:)` and `HapticFeel`:
    - start `.solid`;
    - Pause / Resume `.selection`;
    - each extension `.light`;
    - End (after its confirm) `.solid`;
    - the 5-minute heads-up `.light`, paired with the soft sound;
    - a finished sprint keeps `.success`.

    This is a device check (the phone-checks list).
  - **Jargon left in Details:** "Deep entry", "Flow calibration", "Sprint target" and "1 of 15 min logged" live in the
    timeline that "Details" reveals. They are renamed or cut in round 10 (the jargon list).

**Round 5a: Today's one card (board `59-ROUND-5-hero-options.jpg`; real-token renders under the real Today header).**
- **Buttons → "H1 · Start first, Close quiet".** One prominent "Start N min" (56pt, accent). "Close it" is a quiet
  green-tinted button below it.
  - The card also carries: a pin toggle (44pt) in the corner; the title; the next-step line; chips for time and
    area; and the shrinking time bar (idea 8) when a commitment is ahead.
  - The suggested state adds "Not this one" (idea 3).
  - At AX3 the card is taller than the screen, so the build needs a COMPACT AX3 card with Start above the fold.
- **What wins the one slot → "Leave-by first".** Leave by (inside 30 min) > live routine > paused sprint (Resume) >
  pinned task > suggestion. Only a hard deadline outranks where you are.
  - Due nudges sit at the top of the "then" list with a bell. This was stated in the question and E did not object.
- **Next step → "A 'Next step' field".** One optional line on a task, editable from the card and from task detail.
  Time comes from the task's stored sprint length (`focus_duration_seconds`). It is a Firestore change, so E
  republishes the rules.
- **The finished-sprint Confirm → "Keep Confirm"** (Recommended was auto-log + undo). A deliberate "claim it" tap that
  fires the Confirm celebration, as today. It also catches sprints that ran out while the user was away.
  - This is E's call over the audit's undo direction and Q10's friction rule. Recorded, not a finding.

**Round 5b:**
- **Week review door → "Both".** Idea 9's line under the "then" list reads "✓ 3 done today · Week review ›", AND a
  row sits at the top of the Areas tab.
- **Weekly streak N → "3 days"** (the default; changeable in Settings).
- **What counts as an active day → "Anything that moves life on".** Closing a task, finishing a sprint, writing a
  journal line, or sorting a capture.
- **"Not this one" → "Back in the list, not re-suggested today".** The skipped task stays tappable in the "then"
  list, and the card won't offer it again until tomorrow.

**Round 6: the task composers and capture copy (board `60-ROUND-6-composer-options.jpg`; real-token renders).**
- **Doors → "One composer, both doors".** The Tasks "+" and the disc → Task open the SAME composer.
- **What the composer asks → E, verbatim:** *"C1 AND THE C3 chips. I want The options "Not yet", "Today",
  "Tomorrow", "Pick a date" - BUT I want the Chips to be tappable, so that the drop-down options that are shown in
  C1 can be accessed."*
  - Reading: the title field; C3's four tappable "when" chips (Not yet · Today · Tomorrow · Pick a date); and C1's
    area and time pop-up chips (menus, not sheets).
  - The next step, tags, place and notes live on the task.
  - A render of this reading goes to E for confirmation at the start of round 7.
- **A new task's date → "No date + an 'Anytime' row".** New tasks have no date unless one is picked. The Tasks board
  gains one collapsed "Anytime · N" row at the bottom: the tail stays folded, but a new task is visible where it was
  added. This retires the forced "due today" (CAPT-02) and the vanishing undated task (TASKS-03).
- **The capture copy → "Drop the explanations".** No subtitle on the fan and no footnotes on the tiles; the tile
  names say enough.
  - The inbox's own "Anything you capture lands here first" is round 8's (copy).
- **Composer confirm (board `61-ROUND-6b-composer-your-combo.jpg`) → E, verbatim:** *"The chips That you have added
  are correct, but the layout and display of them is quite ugly. A redesigns Suggestions of the layout would be much
  appreciated."*
  - The CONTENT is settled: title, four "when" chips, and the area and time menus.
  - The LAYOUT is re-proposed with renders, keyboard up, in round 7b.

**Round 7: touch targets (board `62-ROUND-7-targets.jpg`, measured from the accessibility tree on the 18 Pro).**
- **Key targets → "Actions that change things".** 48pt for anything that starts, closes, adds, undoes, ends or saves,
  and for each sheet's primary button. 44pt for navigation and filtering (Back, Settings, filter chips, tags).
- **Filter and tag chips → "36pt look, 44pt reach"** (Recommended was 44pt visible). They keep today's 36pt look with
  an invisible 44pt hit area (`contentShape` plus padding). The composer's own chips stay 48 (round 6).
- **Corner controls → "All to 48×48"** (Recommended was 44). The Settings gear (40), Back (36), the composer's Close
  (77×36), the Tasks "+" (27×36) and Journal's "All activity" (38×36) all become 48×48 in their standard places.
  - Stated default: the Live Activity's single +5 min is at least 44pt within its height cap.

**Round 7b: the composer's layout (session 3; board `64-ROUND-7b-composer-layouts.jpg`, frames in
`screenshots/adhd-ux-audit/round-7b-composer-layouts/`; real-token renders from a throwaway probe, deleted after).**

Before E saw it, board `64` was re-rendered with two corrections:
- Session 2's `.lineLimit(1)` fix had only turned L3's "15 / min" wrap into a truncated "15…". L3's menus now use a
  compact 8pt inset with 4pt gaps, and "15 min" shows whole.
- L2 and L3 had drawn the "when" segments at 40 and 44pt. All three are now 48pt, per round 7 ("the composer's own
  chips stay 48").

The `apple-design` review of the three layouts is findings §L.
- **Layout → "L3 · Rides on the keyboard"** (Recommended).
  - The title owns the page. Every choice and Add sit in one bar just above the keyboard: the four "when" segments on
    top; Area | Time | Add below, with Add trailing.
  - With the keyboard up the bar spans 406–518pt of the 874pt screen. L1's choices sat at 252–364pt, and L2's at
    282–440pt.
  - Carried in the question, so part of the choice:
    - **At AX3 the bar cannot share the screen with the keyboard,** and Area and Time overlap in the render. At
      accessibility sizes the build uses L1's stacked form instead: the choices scroll under the title and Add stays
      pinned.
    - **Opening Area, Time or the date picker must NOT dismiss the keyboard,** or the bar drops 336pt and jumps back
      (research §3.2). A test pins it.
  - Build notes (findings §L, Platform notes):
    - The bar rides the keyboard through `safeAreaInset(edge: .bottom)`, which is the 16 floor.
    - The container takes Liquid Glass on 26+ behind `#available`, and a standard material below.
    - `ToolbarItemPlacement.keyboard` is one row, so it cannot hold the bar.
    - The date picker is a popover or menu, never a sheet (Q4). On iPhone a `.popover` needs
      `presentationCompactAdaptation(.popover)` (16.4+) and a floor path.
  - Rejected:
    - L1 · Tidy grid (choices high, 174–286pt above the keyboard).
    - L2 · Form card (Settings-familiar, but grey values and a redundant "When" label).
- **The Date segment → "Text, then the date"** (Recommended).
  - It reads "Date" in LabelPrimary like its neighbours, with no calendar glyph.
  - Once a date is picked, Date becomes the selected segment and shows that date ("Fri 26").
  - This fixes all three `apple-design` findings on it:
    - `segmented-controls.md › Content`: "either text or images — not a mix";
    - an action segment inside a selection control;
    - `color.md › Best practices`: accent meaning both "selected" and "opens a picker".
- **Routed, not decided:** the review's contrast Criticals go to round 9. They are the placeholder, LabelSecondary
  4.25:1 in light, and white on accent (3.93:1 light / 3.65:1 dark at 15–17pt semibold). "Make the labels bold" is
  offered there as a candidate, beside the Q5/Q6 middle option.

**Round 8: shame and pressure words (session 3; board `63-ROUND-8-pressure-copy.jpg`).**

`apple-design` check before asking: pages read were `writing.md`, `color.md › Best practices` and
`tab-bars.md › Best practices`.
- **The word for past-due → "Still open"** (Recommended).
  - It replaces "Overdue" on rows: `Tasks/TaskRowPresentation.swift:72` and `LifeAreaDetail/AreaTaskRow.swift:92`.
  - Carried in the option: every open task is still open, so the word alone doesn't say the task was due earlier.
    Where the row sits in the list must say that, and the build owns it.
- **The header count → "Remove it; the rows say it"** (Recommended).
  - "12 OPEN · 2 OVERDUE" becomes "12 open", and "0 OVERDUE" never prints (`Tasks/MomentumTaskBuckets.swift:67`).
  - Research §5.4; the brief applies `tab-bars.md`'s badge rule by analogy.
- **Quiet areas → "Neutral 'last closed Tue', no colour"** (Recommended).
  - Orange "quiet since Tuesday" and "quiet all week" (`Home/MomentumScoreboard.swift:284-290`, StateWarn via
    `Home/AreaMomentumList.swift:86` and `Areas/AreasComponents.swift:185`) become plain secondary text.
  - The word is "closed" because the app records only `lastClosedAt`. Widening it to any activity, per round 5b's
    active-day rule, is a build choice. `color.md › Best practices`: "Avoid using the same color to mean different
    things."
- **Inbox pressure → E, verbatim (in place of the offered options):** *"The stats section is a very popular thing
  with ADHD users. Gamifiying Set an element throughout the entire of this app is essential"*.
  - The stats stay. What was offered:
    - (Recommended) "5 to sort" with no age line and no health section;
    - neutral words, keeping the stats;
    - removing the stats section only.
  - The note in the question said the age line (M5) and the captured/cleared line (S1) are both Concept C
    counterweights.
  - E's sentence also reads as a standing principle: **gamification is essential throughout the app.** Its framing
    and its reach are asked in the follow-up (round 8, follow-up).
  - **This is E's call over research §5.3,** where the gamification evidence is low quality and 8 of 26 reviews
    reported adverse effects. It follows the precedent of sounds in round 1: a recorded decision, not a contradiction
    to re-raise.

**Round 8, follow-up.** The question quoted E's sentence and invited a correction; E made none.
- **Inbox stats → "Framed as progress"** (Recommended).
  - The section stays, re-headed "This week" (was "INBOX HEALTH"). Its bars and "2 sorted · 7 captured this week"
    lead with what was DONE.
  - The header reads "5 to sort", no longer orange, and keeps its progress bar and kinds line.
  - Gone: the age line "oldest is 13 hours old" (Concept C's M5) and "Four are still sitting here — decide or bin
    them" (`Capture/CaptureInboxSummary.swift:31-41,124-129`).
  - Concept C's S1 capture/clear counterweight survives, reframed done-first.
- **What "gamification throughout" means → E, verbatim: *"Do option 1 & option 3"*.**
  - Option 1: the game layer already chosen IS the game layer. That is the weekly chain with auto repair, Week
    review, the goals the user sets, the celebrations and the inbox stats. Every screen may show what was done; none
    tallies what was missed.
  - Option 3: a **points / levels / badges system, as its own arc AFTER the audit.** The question carried research
    §4: points and variable rewards are weakly supported, and expected tangible rewards reduce intrinsic motivation
    (Deci 1999, d −.28 to −.40).
  - It joins the end-of-audit gaps list as a WANTED new arc. It is not built inside the audit's blocks.
  - Option 2 ("a progress element on every tab", proposed in round 10) was NOT chosen.
  - Round 3's calls stand: the weekly chain, the one Week review chart, and goals off until set.

**Round 8b.**
- **Fresh Start → "Set them aside in one folded row"** (Recommended).
  - After 7+ days away, one tap on Today's "Welcome back. Start fresh?" card moves the PAST-DUE open tasks into one
    collapsed "Set aside · N" row at the bottom of Tasks. It sits beside round 6's "Anytime · N", in the same shape.
  - Nothing is deleted, dates are kept, and one tap brings any task back.
  - Undated tasks already live in Anytime, and future-dated tasks are untouched.
  - Research §5.8 and §5.4 (Dai 2014).
- **The task-detail Close button → "'Close it — makes today count'"** (Recommended).
  - It shows only while today has no activity yet. Once today counts, the button reads plain "Close it".
  - It replaces "Close it — keeps a N-day streak" (`Tasks/MomentumTaskContext.swift:27`).
  - It is the gamification principle framed as a gain toward the weekly chain, never a loss.
- **Today's three day-streak lines → "They go with the scoreboard"** (Recommended).
  - The lines: "One day closed. Keep it alive today.", "N days closed in a row." and "Streak kept. Best is N."
    (`Home/MomentumScoreboard.swift:246-252`).
  - The weekly chain speaks through Week review and the done-today line.

**Round 9: accessibility and colour, an approve-the-list round (session 3; boards `65-ROUND-9-dynamic-type-AX3.jpg`
and `66-ROUND-9-contrast-and-colour.jpg`).**

Before asking, the `apple-skills` iOS `ui-review` and `accessibility-audit` modules ran for the first time in the
audit, as two read-only sub-agents. They are findings §M.
- **Contrast → "Leave it to the colour arc"** (Recommended was "Increase Contrast versions only").
  - Nothing about contrast is built in the audit. That includes the bold-labels-on-blue fix, which rode only with the
    Recommended option.
  - The measured numbers become the colour arc's input, and they include round 7b's composer findings. Light: grey
    meta 4.25, tertiary/placeholder 1.88, orange on card 3.02, on page 2.72, green on page 2.82, blue link 3.55, and
    white on blue 3.93. Dark: tertiary 2.33 and white on blue 3.65. The tab badge (settled) is 4.21 light and 3.41
    dark.
  - This is E's choice of the Q6 hold over Q5's accessibility exception.
  - Consequence to name at the close: until the colour arc lands, Increase Contrast does nothing, and the Sufficient
    Contrast nutrition label cannot be claimed.
- **AX3 layout → "Approve, but keep Areas in 2 columns"**.
  - Approved: at accessibility sizes, task rows stack (the title wraps in full, the meta sits under it, and ▶ and ○
    stay trailing).
  - Approved: the sign-in segments grow; they are AUTH-01 and the only route to Create account.
  - Approved: no button breaks mid-word ("Arran/ge"; icon only if needed).
  - Approved: metric labels wrap to 2 lines (A11Y-09).
  - **Kept:** the Areas grid stays 2 columns at every size (AREAS-01 is E's call). Names wrap inside the cards
    instead of truncating.
- **Colour jobs → "Approve all four"** (Recommended).
  1. **Blue comes off labels that aren't tappable** ("TOMORROW", "WHERE DOES THIS LIVE?", "THEN").
     - The eyebrows become DUE TODAY orange, TOMORROW grey (`MomentumTaskBuckets.swift:75`) and CLOSED TODAY green.
     - Blue always means "tap me".
  2. **The raw `.green`, `.orange` and `.red` become StateGo, StateWarn and StateRisk,** with StateGo shared with the
     widget target.
     - The places: `NotificationPermissionState.swift:72-74`, `WeeklyFocusSummaryWidget.swift:138,141`,
       `FocusSprintPresentation.swift:88` and the widget's `FocusActivityComponents.swift:115`.
     - The notification status cited §4 ("adaptive system colours") on purpose. E chose consistency over that
       reading.
  3. **The "Nudges Due" flame goes neutral.** It is StateRisk in Week review, at `DailySummaryView.swift:223`.
  4. **In the inbox, a disabled "Sorted" looks disabled** beside an enabled "Skip" (INBOX-03).
- **The §M accessibility list → "Approve all, plus automated audits"** (Recommended).
  - **VoiceOver:**
    - labels for the Tasks "+" ("New task"), each tag's remove ("Remove tag Work") and voice Play/Pause;
    - the inbox top card and Home's Due-now rows become one element with a button trait;
    - the promote sheet's chips carry `.isSelected`;
    - the 13 decorative chevrons are hidden;
    - the countdown gets `.updatesFrequently` (§M's list).
  - **Reduce Motion:**
    - the sprint ring stops re-springing every second (§7.2's continuous case, `nil`, as `FocusTimerBarContent`
      already does);
    - the undo bar fades in instead of sliding (§7.2's "appears" case);
    - the Daily Summary and sign-in swaps are covered too;
    - each is a reduced site and owes E's RM-on phone pass when built (§7.3).
  - **Smart Invert:** `accessibilityIgnoresInvertColors` on photos.
  - **Charts:** `accessibilityChartDescriptor` on Week review's chart.
  - **Automated:** `performAccessibilityAudit` per screen in the UI journeys, in its own test plan. UI tests stay out
    of the standard run, and the audit needs a 17+ test runtime (27.0 is fine).
- **Nutrition Labels (advisory, recorded):** none can be claimed today. Findings §M holds the table.

**Round 10a: sheets, Save placement, tap twins and footers (session 3; board `67-ROUND-10a-sheets-save-gestures.jpg`).**

The Places chain was sim-verified this session: Places → Edit place (sheet 1) → Edit action (sheet 2) → Apple's
contact picker (sheet 3). The frames are in board `67`.
- **Sheet depth → "One sheet, pushes inside it"** (Recommended).
  - Edit place stays the one sheet. An action's editor, and the app's own app picker, push INSIDE it, with Back to
    return.
  - Only Apple's system screens (the contact picker, the camera) open over it.
  - sheets.md › Best practices; research §2.3.
- **The fix list → "Approve all four"** (Recommended).
  1. **Save and Add move to the bottom of eight sheets** (REACH-1): Edit place, Edit action, the tag and life-area
     editors, the nudge editor and the capture detail. The sprint sheet is round 4b's.
  2. **The Settings Notifications card loses its ~310pt gap** (SET-01). "Not requested yet" gains an in-place
     "Allow notifications" button (SET-02); the app already asks when the first nudge is created.
  3. **Tasks shows a loading state** instead of "0 open" (TASKS-07).
  4. **The inbox promote sheet's "Create Task" pins to the bottom** (INBOX-04).
- **Tap twins → "↑ ↓ buttons + a Delete button"** (Recommended).
  - Arrange mode (life areas) and a place's action list show ↑ and ↓ on every row (48pt); drag still works.
  - Edit place gains a bottom Delete button with its confirm (GEST-2; Q10 allows the friction). GEST-3 is closed by
    the same buttons.
- **Footers → "One sentence, the rest behind 'More'"** (Recommended).
  - Each Settings footer, and Tools' empty Routines card, becomes one plain sentence. The full text sits behind a
    "More about this" disclosure (SET-03, TOOLS-01).

**Round 10b: the words (session 3; board `68-ROUND-10b-words.jpg`).**
- **Jargon → "Approve all"** (Recommended). Round 4 already retires the checkpoints, "Flow calibration"
  (`Focus/FocusModels.swift:107`) and the "Nudge cadence" card. The renames:
  - "Deep entry" → "Getting started" (`Focus/FocusSprintTimelineCard.swift:202`);
  - "Sprint target 15m · Logged on finish" → "Length 15 min · saved when it ends" (`:212`);
  - "1 of 15 min logged" → "1 of 15 min done" (`Focus/FocusSprintDetailView.swift:167`);
  - "monitoring slots" and "At-Place tasks" → "iOS lets the app watch 20 places" and "tasks for this place"
    (`Places/PlaceEditorView.swift:250-252`, `Places/PlaceActionsSection.swift:111`);
  - "session" → "sprint" everywhere ("Start another session", "1 session · 15 min");
  - "To triage" → "To sort";
  - "Decide later" and "No life area" → **"None"**, as in the round 7b composer
    (`Capture/QuickCaptureComponents.swift:188`, `Tasks/TaskCreateView.swift:141`, `Theme/ComposerChips.swift:256,271`);
  - "WORKSHOP" goes (`Tools/ToolsView.swift:110`);
  - "Entries are append-only — saved means saved" → "Entries can't be changed after saving"
    (`Journal/LogComposerCopy.swift:13`). The line goes once journal edit ships (gaps list);
  - Settings' "…light and dark variants for every token" → "Follows your device"
    (`Settings/AppearancePreference.swift:49`).
- **The inbox's "Promoted" segment → "Tasked"** (Recommended). The segments read To sort · Sorted · Tasked, matching
  round 6's "Task it".
- **Refresh → E, verbatim:** *"I choose option one With the addition of an auto-refresh When a user makes an
  edit/Change Such as logging a new Journal entry - Then the Journal should update automatically. Creating a new
  quick capture - Should update the Capture inbox page automatically"*.
  - Option one: every screen reloads when it appears and whenever the app returns to the front. The pull stays as a
    bonus, with no new button.
  - Returning to the app does not reload data today. Only the sprint sync and the live routine run
    (`RootView.swift:389`, `Home/HomeView.swift:306`).
  - E's addition, and the code fact behind it: every generic Firestore `save`, `delete` and `update` posts
    `DataChangeSignal` (`Firebase/FirebaseManager.swift:326-340`). Journal and the Capture inbox already listen
    (`Journal/JournalView.swift:157`, `Capture/CaptureInboxView.swift:139`), and so do Today, Tasks, Areas, an
    area's page, Nudges, Places and Tools.
  - So the build must PROVE, with tests, that a new journal entry and a new quick capture appear on their screens
    with no pull.
  - Any write path that bypasses the generic methods (a photo upload through `+Storage`, the Shortcut runner) must be
    checked for the signal.
  - **E clarified, 2026-09-19 (asked in the closing text):** *"I don't think I have seen it fail to refresh but I
    stated it to ensure continuity."* So this is NOT a bug report. It is a requirement that the behaviour keeps
    working, which arc G's F-G4 pins with tests rather than hunting a defect.
- **Capitals → "Sentence case everywhere"** (Recommended).
  - It confirms what E approved by sight. "Add to Today", "Delete Task" and "Keep Editing" become sentence case
    (X-CAPS).
  - This is the house style against `buttons.md › Content`'s title-style, under `writing.md › Best practices`
    ("Choose a style for each UI element type and use it consistently").

**Round 10b, the missed item (asked after round 10b; the hand-off listed it, and round 10b had skipped it).**
- **The empty inbox line → "'Captures wait here to be sorted'"** (Recommended).
  - It replaces "Nothing waiting to be triaged. Anything you capture lands here first, so your head doesn't have to
    hold it." (`Capture/CaptureInboxView.swift:286`).
  - That line was untrue, because a Task from the disc skips the inbox (CAPT-04).
  - "Inbox clear" and its "Capture something" button stay (INBOX-05 unchanged).
  - Today's copy of the line (`Home/HomeAccessoryStrips.swift:55`) leaves with the inbox peek (round 3).

**Decision A and the build order (session 3, after round 10).**

The opinion given in the question: build in FRESH sessions, one arc per session (memory `build-in-a-fresh-session`).
- **Where the specs are written → "Specs here, then hand off"** (Recommended).
  - Session 3 writes every decision as a FEATURE block in `TODO-CLAUDE-CODE.md`, then closes the audit and hands the
    first arc to a fresh session.
- **The first arc → "C · Nothing lost first"** (Recommended).
  - It holds the audit's data-loss Criticals (CAPT-01, TASKS-01), and it builds the undo capsule the later arcs
    reuse.
- **The seven arcs, grouped by dependency:**
  - A · Copy and colour jobs.
  - B · Accessibility.
  - C · Nothing lost.
  - D · The composer.
  - E · Today.
  - F · The sprint.
  - G · Places, sheets, refresh and Fresh Start.
  - The order after C is proposed in the opener.
- **The audit's own findings on in-app refresh** (round 10b): journal entries and captures write through the generic
  `save` (`FirebaseManager+Logs.swift:21`, `+Captures.swift:57`), which posts `DataChangeSignal`. In code, both
  screens already refresh; E was asked in the closing text whether they have seen them fail.

**Housekeeping note (session 2 hand-off).** Two throwaway render probes were swept into intermediate commits by `git add -A`:
- the hero probe: in `3f8a187`, removed `952fdd3`;
- the composer probe: in `d62cda0` and `a715d6b`, removed in the hand-off merge `670dbb7`.

No probe remains in the test target. From here on, delete a probe (or move it to `scripts/audit/probes/` as
`.swift.txt`) BEFORE any `git add -A`.

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

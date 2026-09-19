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

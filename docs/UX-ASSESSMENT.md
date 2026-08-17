# ADHD LifeOS — Comprehensive Mobile UX Assessment

**Prepared by:** Multi-disciplinary UX Assessment Panel (Cowork design phase)
**Date:** 19 July 2026
**Scope:** UX assessment only — grounded in the actual Swift views/services in `ADHD LifeOS/ADHD LifeOS/`. No code fixes. No backend/build engineering except where it directly damages user momentum.
**Method:** Simulated two-week lived-use cycle on iPhone, modelling high cognitive fatigue, time blindness, decision paralysis, executive dysfunction, and late-night hyperfocus states.

---

## 📱 What Was Actually Reviewed (Ground Truth)

- **Root shell:** `RootView` — 4-tab `TabView` (Home / Tasks / Journal / Nudges) + a 48pt `plus.circle.fill` floating capture button overlaid bottom-trailing, opening `QuickCaptureView` as a sheet.
- **Home:** `HomeView` — due-nudges strip + adaptive `LazyVGrid` of life-area cards (colour dot, name, open-task count); Inbox button with count in the leading toolbar; Settings gear trailing.
- **Capture:** `QuickCaptureView` (text field + Kind picker note/task/link/voice, Save/Cancel toolbar); `CaptureInboxView` (list, inline expanding "Promote to Task" form: life area, priority, optional due date).
- **Tasks:** `TaskListView` (segmented status filter, life-area-grouped list, `+` toolbar create); `TaskCreateView` (title + "Add More Info" DisclosureGroup + countdown-nudge control); `TaskDetailView` (full edit form, Mark Done/Reopen, tags, nudges, explicit **Save** button).
- **Journal:** `JournalView` (life-area filter picker, plain list of Log/Journal capsule-tagged rows); `LogComposerView` (type picker, life-area picker, body field).
- **Nudges:** `NudgesView` (always-expanded "Add Nudge" form at top; Due section with Dismiss; All Nudges with inline Edit/Deactivate); `NudgeDueness` computes dueness **in-app, client-side**; recurring nudges have **no push notification path** — only task countdown nudges use `UNUserNotificationCenter`.
- **Auth/Settings:** `LoginView` (password + magic link), `SettingsView` (Sign Out only).

---

# PART A0 — UI VULNERABILITY & WEAKNESS REGISTER

*A structural scrutiny of the view + model + service layers, performed before the lived-use simulation so every downstream finding is grounded in a known mechanism. IDs (V-1…V-15) are cross-referenced throughout Parts A–C. UX consequences only — no code fixes.*

| ID | Layer | Vulnerability | UX consequence |
|----|-------|--------------|----------------|
| **V-1** | RootView | Quick Capture sheet is constructed with an **empty `onCreated` closure** — success produces no callback whatsoever. | No confirmation, no refresh, "did it save?" doubt. The keystone trust loop is open-circuit. |
| **V-2** | State architecture | **No single source of truth.** `HomeView` and `NudgesView` each own a *separate* `NudgesService`; every `QuickCaptureView` sheet and `CaptureInboxView` spins up its own `CaptureInboxService`. Sibling screens can hold contradictory copies of the same data. | Dismiss a nudge on Home → it's still "due" on the Nudges tab (and vice-versa). Captures saved via FAB never reach Home's count. The app visibly disagrees with itself — corrosive for a user who needs to trust one external brain. |
| **V-3** | Cross-tab staleness | `.task { await load() }` fires on first appearance only; tab switches don't re-run it, and no mutation event propagates across tabs. | Complete tasks in the Tasks tab → Home life-area counts stay wrong indefinitely. The dashboard drifts from reality over a session. |
| **V-4** | CaptureInboxService | `warningMessage` / `errorMessage` are **service-scoped, not per-row** — every expanded row renders the same message. | One failed promote paints error text into unrelated captures' forms (confirmed mechanism for A2-3). |
| **V-5** | CaptureInboxService | Recovery bookkeeping (`pendingTaskIdsByCapture`) is **in-memory per instance**. After "Task created, but couldn't mark the capture as processed," leaving the screen discards the map; the pre-flight check only inspects `processed`, which is still false. | Retrying the same capture later **creates a duplicate task** — the user gets punished for retrying, and the duplicate must be found and deleted manually. |
| **V-6** | Nudge pipeline | Recurring-nudge dueness is computed **in-app only**; nothing is registered with `UNUserNotificationCenter` (only task countdown nudges are). | A "9:00 weekdays" nudge never notifies. The core service promise silently fails (basis of A5-1). |
| **V-7** | Nudge dueness model | A due nudge stays due indefinitely until explicitly dismissed; there is no auto-expiry, coalescing, or cap. | Skip the app for three days → a wall of stale due nudges greets the return, each one a small accusation. Re-entry after absence — the most fragile ADHD moment — is the app's *worst* screen. |
| **V-8** | TaskDetailView | Fields initialise once via `hasInitializedFields` + `onChange(of: state)`; later reloads never re-sync the form, and edits live only in local `@State` with a bottom-of-form Save. | Silent edit loss on interruption; form can display data that no longer matches the store (mechanism for A2-2). |
| **V-9** | Due-date bindings | Toggling "Due Date" on defaults to `Date()` — *now*. In Create/Detail (date **+ time**) the task is instantly "due this minute." | The countdown-nudge control immediately reports "This task is due too soon to schedule nudges," punishing the toggle order rather than the user's intent. A time-blind user meant "today," not "right now." |
| **V-10** | LoginView | The `.linkSent` state renders only "Check your email" — **no back, no resend, no wrong-email escape**. | Typo in the email → hard dead end at the front door; only recourse is killing the app. |
| **V-11** | NudgesView | Weekday selector renders 7 bordered buttons in one `HStack` — sub-44pt targets on 375pt-wide devices. | Mis-taps on exactly the fiddly control that defines when nudges fire; errors here surface days later as "the app nudged me on the wrong day." |
| **V-12** | Mutation pattern | Every post-mutation refresh calls `load()`, which sets `.loading` and replaces the whole list with a spinner. | Momentum-breaking white flash directly after the user's most rewarded actions (create, complete, save). |
| **V-13** | Visual identity | `Color(hex:)` silently falls back to gray on malformed colour strings. | A life area can silently lose its colour identity — the primary pre-attentive scanning cue — with no signal that anything is wrong. |
| **V-14** | RootView overlay | 48pt FAB floats over list content and near the tab bar with no scroll inset. | Occludes last-row actions; one-handed mis-taps toward the Nudges tab (basis of A2-4). |
| **V-15** | Error states | All five `failed` states are text-only — no Retry affordance anywhere. | Recovery requires the undiscoverable tab-switch incantation (basis of A2-7). |

**Reading of the register as a whole:** the individual views are clean, but the *connective tissue* — state sharing, mutation propagation, recovery paths — is where the ADHD-safety contract actually breaks. Nearly every simulated-use failure in Part A traces back to V-1/V-2/V-3 (trust and truth), V-6/V-7 (the nudge promise), or V-12/V-15 (momentum and recovery).

---

# PART A — FIVE-SPECIALTY EVALUATION

## 1. ✍️ UX Writer / Content Designer

### What's working
- **No shame language anywhere.** There is no "overdue," no red badges on stale items, no "You haven't…" constructions. Error copy blames the system, not the user: "Couldn't load your tasks," "Couldn't create tag." This is the correct ADHD-safe register and it is applied consistently.
- **"What's on your mind?"** as the capture and journal placeholder is warm, low-stakes, and identical across both composers — good consistency that lowers the decision cost of "which box do I type into?"
- **Partial-success honesty:** "Task created, but couldn't mark the capture as processed" correctly reassures that the important thing worked before admitting the failure. This ordering matters enormously for an ADHD user's shame circuitry — the win is stated first.

### Findings & fixes

**A1-1 · Empty states are neutral, not encouraging (cognitively inert).**
"Inbox is empty," "No tasks match this filter," "No journal entries match this filter," "No nudges yet." Simulated Day 3, 11:40 pm, low dopamine: E opens Tasks with the Done filter after clearing the day — and gets the same flat grey line as a failure state would show. Empty states are the single cheapest dopamine surface in the app and all four are wasted.
*Fix:* Give each empty state a valence matched to its meaning. Inbox empty = a win: "Inbox zero — everything's been sorted. 🧘". Done filter empty ≠ failure: "Nothing marked done yet today — that's fine, the list is patient." No-logs state should invite: "Nothing here yet. One sentence counts." Never re-use one string for both "you finished" and "you haven't started."

**A1-2 · Technical jargon leaks into user-facing copy.**
"Notifications permission denied — nudges were not scheduled" reads like a log line. "P1/P2/P3/P4" (rendered as raw uppercase enum values) is developer taxonomy; a fatigued user must translate it every time. "Capture content is required." is validation-engine voice.
*Fix:* Permission copy → "To nudge you, the app needs notification permission — you can turn it on in Settings." Priorities → human labels with the code as secondary ("Now · P1", "Soon · P2", "Whenever · P4"). Validation → placeholder-level prevention (Save disabled) already exists, so the string is nearly unreachable; where shown, use "Add a few words first."

**A1-3 · "Promote to Task" is process language.**
"Promote" describes the database operation, not the user's intent. Under decision paralysis, abstract verbs increase hesitation.
*Fix:* "Make this a task" — concrete, imperative, pre-decided.

**A1-4 · The Kind picker labels ("Note / Task / Link / Voice") force a taxonomy decision at capture time.** Capture is supposed to be the zero-decision moment; the picker's very presence is copy asking a question the user shouldn't have to answer while a thought is evaporating. (Interaction fix in §2; the *content* fix is: default silently to Note and demote the picker to an optional afterthought.)

**A1-5 · No onboarding voice exists at all.** First launch lands on "Sign in" with zero framing of the app's philosophy. A first-session ADHD user has no idea that the inbox is guilt-free or that nudges are dismissable without consequence. One sentence of ethos per screen on first run ("Captures have no rules. Sort them later, or never.") would set the anti-shame contract explicitly.

**A1-6 · Dismiss is the only verb offered for a due nudge.** "Dismiss" carries a faint "make it go away" connotation and offers no graceful middle ("Not now"). Copy pair should be "Done" / "Not now" — both exits are dignified.

---

## 2. ✍️ Interaction Designer (IxD)

### What's working
- **Capture is 2 taps to a keyboard** (FAB → sheet with field focused-ish) and the Save button live-validates. That is a competitive baseline.
- **Create/Detail correctly reuse one countdown-nudge control**, and Task Create's "Add More Info" DisclosureGroup is exactly the right progressive-disclosure instinct — title first, everything else optional and folded away.
- Async double-submit protection (`isSubmitting` disables Save) prevents the classic ADHD double-tap duplicate.

### Findings & fixes

**A2-1 · 🐞 The capture confirmation loop is broken — `onCreated` is an empty closure.**
In `RootView`, the sheet is created as `QuickCaptureView(client: captureClient) {}`. Saving a capture dismisses the sheet and *nothing else happens*: no haptic, no toast, and — because `HomeView` only refreshes `inboxCount` when the Inbox screen is dismissed — **the Home inbox count stays stale after a capture.** Simulated Day 2: E captures three thoughts from the sofa, glances at Home, sees "Inbox (0)", and experiences a genuine "did it save?" doubt spike. For a trust-dependent capture system this is the most damaging single defect in the app.
*Fix (spec-level):* capture success must produce (a) a `.success` haptic, (b) a transient confirmation ("Captured ✓" toast or checkmark morph on the FAB), and (c) an inbox-count refresh propagated to Home. Trust in capture is the keystone habit; it must be over-confirmed, not under-confirmed.

**A2-2 · 🐞 Task Detail has two conflicting persistence models on one screen.**
"Mark Done" commits instantly; title/notes/priority/due-date edits sit unsaved until a **Save button at the bottom of the form** is found and tapped. Simulated Day 6, hyperfocus interrupted by a phone call: E edits a title, backgrounds the app, edits are silently lost — and there is no dirty-state indicator, no discard warning, and no Save in the toolbar where iOS muscle memory expects it. Executive-dysfunction users *will* forget a bottom-of-form Save; mixed models also erode the predictive model of "what does tapping do here?"
*Fix:* one model — autosave on field commit (with debounce), or at minimum move Save to the trailing toolbar position, disable-until-dirty, and warn on back-navigation with unsaved edits.

**A2-3 · 🐞 The inline promote form is an interaction cul-de-sac.**
Expanding a capture row injects a life-area picker, priority picker, due-date toggle + DatePicker, and a plain-text "Create Task" button *inside a List row*. Touch targets are default-sized text buttons; the row grows past a screenful on small devices; and — because `warningMessage`/`errorMessage` live on the *service*, not the row — **an error from promoting capture A renders inside capture B's form too** if the user expands another row. Simulated Day 9 triage session: one failed promote made three rows display the same red text.
*Fix:* promote should open a purpose-built sheet (one capture, one decision set, big targets), and messages must be scoped per-operation. Better: reduce promotion to one decision (life area) with priority defaulting to P4 and due date deferred — see Redesign 3.

**A2-4 · FAB placement collides with the tab bar and list content.**
A 48pt button at `bottom-trailing, padding(.bottom, 70)` hovers over the trailing region of every scrollable list, covering the last row's accessory area, and sits close enough to the Nudges tab item to cause mis-taps in one-handed reach. It also floats over sheets' presentation area ambiguity.
*Fix:* dock capture into the tab bar itself as a centre raised button (5-item layout), or use a bottom input bar (Redesign 8). If it stays floating, add scroll-content bottom inset and increase the hit target to ≥56pt with a background material shadow.

**A2-5 · Zero haptic vocabulary.** Not a single `UINotificationFeedbackGenerator`/`sensoryFeedback` use in any view. Completing a task, saving a capture, dismissing a nudge, and hitting an error all feel identical: silent. ADHD motivation systems run on immediate physical feedback loops.
*Fix (spec):* define an app-wide haptic map — success `.success`, task completion `.success` + brief scale animation, nudge dismissed `.light impact`, error `.error`. Feedback must land within 100 ms of the commit gesture.

**A2-6 · Task completion requires navigation.** There is no way to complete a task from `TaskListView` — the user must push into detail, find "Mark Done", then navigate back. That is 4 interactions for the app's most celebrated action, and the return trip triggers a full list reload (`ProgressView` flash — a loading state exactly where a smooth "row strikes through and settles" animation should be).
*Fix:* leading swipe-to-complete and/or a tappable status circle on every row, optimistic UI (strike immediately, reconcile in background), no full-screen reload after mutation. Every mutation currently replacing content with a spinner (`tasksService.load()` after create/update) should become an in-place merge — spinners between the user and their just-taken action break momentum.

**A2-7 · Error states are dead ends.** All five "Couldn't load…" states render text with **no Retry button**. On flaky mobile radio (simulated Day 11, on a train), the only recovery is switching tabs back and forth — an undiscoverable incantation.
*Fix:* every failed state gets a prominent Retry; ideally cached last-good content stays visible beneath a "showing offline copy" note rather than being replaced.

**A2-8 · Due-date pickers are inconsistent across surfaces.** Promote-capture offers `.date` only; Task Create/Detail offer `.date + .hourAndMinute`. Same concept, different precision, different muscle memory — and time-blind users anchor hard to whichever model they meet first.
*Fix:* one shared due-date component everywhere; lead with coarse chips (Today / Tomorrow / Weekend / Pick…) before exposing the wheel.

---

## 3. ✍️ Voice User Interface (VUI) Designer

### Current state
`CaptureKind.voice` exists in the schema and is selectable in the Quick Capture picker — but selecting it does nothing different: the user still types into a text field. There is no recording UI, no transcription, no Siri integration, no App Intents. The `voice` kind is currently a **label without a modality**, which is worse than absence: a user who selects "Voice" expecting a microphone experiences a small trust breach.

### Recommendations

**A3-1 · Ship an App Intents / Siri Shortcut path before any in-app mic UI.** The highest-value voice capture for an ADHD user happens when the phone is *not open*: walking, driving, mid-shower thought via watch. A `CaptureThoughtIntent` ("Hey Siri, capture: …") that writes a `kind: voice` capture with transcribed text is the true zero-friction path — no unlock, no app launch, no visual attention. This also feeds the existing Inbox exactly as designed. (E already lives in iOS Shortcuts; this meets him where his automation muscle is.)

**A3-2 · In-app: hold-to-talk on the capture button.** Tap FAB = text sheet (current). *Long-press* FAB = immediate recording overlay with live waveform, release to save. One gesture, no navigation, transcription async in background — the capture is saved as audio instantly and the text arrives when it arrives. Never make the user wait on transcription to confirm the save.

**A3-3 · Design for "voice as raw material," not dictation-into-a-form.** Neurodivergent voice capture is rambling by nature. The inbox row for a voice capture should show the audio chip + transcript preview, and the promote flow should let the user split one ramble into multiple tasks. Do not force a voice capture through the same single-content promote path unchanged.

**A3-4 · Confirmation must be non-visual.** Voice capture happens eyes-free; success feedback must be an earcon + haptic pair ("plink" + `.success`), with the *absence of sound* meaning failure — the inverse of visual-first design.

**A3-5 · Nudge → voice reply loop.** A countdown nudge notification should offer a "Reply by voice" action: speak a status ("done", "need 10 more minutes", "moved to tomorrow") that becomes a log entry or reschedule. This turns notifications from broadcast into dialogue (see Redesign 9) and gives Logs a capture modality that survives low-typing-energy states.

---

## 4. 🛠️ Product Designer (UX/UI Strategy)

### What's working
- The **life-area grid is the correct core metaphor**: chunked, colour-coded, count-first. `LazyVGrid(adaptive: 150)` produces a natural 2-column layout on all current iPhones. Structure is genuinely visible before starting — the stated philosophy survives contact with the implementation.
- Grouping the task list by life area (with "Unassigned" handled) keeps the same mental model across screens — one taxonomy everywhere.

### Findings & fixes

**A4-1 · Life-area cards are informational, not navigational — a cognitive dead end at the app's centre of gravity.**
`LifeAreaCardView` has no tap action. Simulated Day 1: E sees "Legacy: 7", taps the card — nothing. The dashboard promises "see your life" then refuses the obvious next step (see the 7). Every count shown must be a door.
*Fix:* card tap → Tasks tab pre-filtered to that life area. This single change converts Home from a poster into a control surface.

**A4-2 · The number on each card is a raw open-task count — an anxiety meter with no ceiling.**
Counts only ever grow between triage sessions. By simulated Day 12, cards read 11 / 9 / 14; the dashboard now *displays accumulating debt*, which for ADHD users converts the home screen into an avoidance trigger — the precise failure mode the app exists to prevent.
*Fix:* lead with the **next action**, not the total: card shows the single top-priority task title, with the count demoted to a small secondary chip. "One thing" is actionable; "fourteen things" is a wall. Optionally cap display at "9+".

**A4-3 · Home shows counts of work but no evidence of life.** Logs/Journal — the positive-reinforcement half of the system — have zero presence on Home. The dashboard therefore answers "what do I owe?" but never "what have I done?", biasing the emotional valence of every open negative.
*Fix:* one "Today so far" line under the nudge strip (last log snippet, or captures + completions today). See Redesigns 1 and 5.

**A4-4 · The Nudges screen violates the app's own progressive-disclosure standard.** An always-expanded creation form (label field + time picker + 7 weekday toggle buttons) sits *above* the Due and All sections — the most cluttered screen in the app is the one meant to be glanced at. Task Create hides its complexity behind a DisclosureGroup; Nudges should too (`+` toolbar button → sheet), with Due content first.

**A4-5 · Four tabs + hidden Inbox misallocates navigational real estate.** The Capture Inbox — the daily-triage heart of the methodology — is buried behind a toolbar button on Home, while Nudges (a configure-rarely surface) owns a permanent tab. Simulated behaviour: by Day 8 the Nudges tab is opened only when a nudge misbehaves, and inbox triage frequency has dropped because it isn't visible. Frequency should buy visibility: Inbox deserves the tab (with count badge); Nudge management can live inside Settings/Home.

**A4-6 · Segmented control wastes its slot on Done/All.** The status filter (Open/Done/All) optimises for archaeology, not action. The scarce top-of-screen slot would serve better as a life-area filter chip row; Done is a rare destination reachable from a menu.

---

## 5. 🛠️ Service Designer

### The system beyond the screen — findings & fixes

**A5-1 · 🐞 Recurring nudges do not actually reach the user.** `NudgeDueness` computes dueness **client-side, in-app only**. There is no `UNUserNotificationCenter` scheduling for recurring nudges (only task countdown nudges get real notifications). A "9:00 every weekday" nudge therefore fires *only if the user happens to open the app after 9:00* — the service promise ("the app will nudge me, so I can stop holding it in my head") is structurally unmet, and the strip on Home silently accumulates. For a time-blind user this is the difference between an external brain and a diary of missed intentions.
*Fix (spec):* mirror every active recurring nudge into scheduled local notifications (`UNCalendarNotificationTrigger` supports exactly the hour/minute/weekday model already parsed); reconcile on app launch; dismissal in-app cancels the day's pending delivery.

**A5-2 · Nudge lifecycle has two exits, both terminal.** Due nudges offer Dismiss (Home strip) or Deactivate (Nudges list). There is no snooze, no "done today", no reschedule-once. Real routines flex daily; a system whose only responses are "gone" or "dead" trains the user to deactivate nudges the first week they're inconvenient — the classic alert-fatigue death spiral, arrived at by Day 10 of the simulation.
*Fix:* nudge actions = **Done · Not now (re-offer in N hours) · Skip today** — with Deactivate demoted to the management screen. Notification actions should mirror the same three verbs so the phone can be answered from the wrist/lock screen without opening the app.

**A5-3 · No anti-fatigue governance.** Nothing limits how many nudges can be due at once, bundles simultaneous fires, or notices sustained ignoring. Service rule set to add: (a) coalesce multiple simultaneous nudges into one summary notification; (b) quiet hours honoring the user's sleep window; (c) if a nudge is dismissed-without-action ~5 consecutive times, the *app* opens a gentle renegotiation ("This one keeps not fitting — move it, shrink it, or retire it?") — shame-free self-tuning instead of silent decay.

**A5-4 · The physical-ecosystem surface area is untouched.** No widgets, no Lock Screen presence, no watch, no Shortcuts donations, no share extension. For a momentum-dependent user, the app currently exists only when deliberately launched — which is exactly when executive function is already available. The service must reach the moments when it isn't: Home/Lock Screen widget = today's Now card + capture button; share sheet extension = capture links from Safari (the `link` kind currently has no natural entry path at all); App Intents = capture and complete by voice.

**A5-5 · No daily rhythm scaffolding.** The methodology implies a loop — morning glance → capture all day → evening triage + log — but the service never teaches or anchors it. A single system-provided "Evening sweep" nudge (on by default, editable) that deep-links into a triage flow would convert the app's features into a *routine*. Without it, each feature waits for the user's initiative — the resource ADHD most lacks. This is the single highest-leverage service-level addition available.

**A5-6 · Sign-out is one tap from Settings with no confirmation** — a momentum landmine (magic-link re-auth requires an email round trip). Add a confirm step.

---

# PART B — 🚀 System Innovations & Elevating Enhancements

*(Forward-looking only — no bugs restated. Everything below composes from the five existing features.)*

**B-1 · The "Now Card" primitive.** Introduce a single computed object — the one thing the system believes matters right now (due nudge > due-today P1 task > inbox-triage suggestion, by precedence) — and surface the *same* card on Home, in the widget, and in the watch complication. One decision, pre-made, everywhere. This is the deepest possible counter to decision paralysis and becomes the anchor for Redesign 1.

**B-2 · Interactive Live Activity for countdown nudges.** A task with countdown nudges gets a Dynamic Island / Lock Screen Live Activity showing time-remaining as a shrinking bar — ambient time-visibility that treats time blindness with *presence* rather than interruption, and a "Done ✓" button that completes the task from the Lock Screen.

**B-3 · Capture anywhere, in-app too.** Global pull-down-to-capture from any tab (a la spotlight): drag any screen downward past a threshold → capture field drops in, type, release. Capture stops being a place and becomes a gesture available mid-anything — matching how intrusive thoughts actually arrive.

**B-4 · Triage as a bounded ritual, not a chore.** "Sweep 5" mode: the inbox offers exactly five captures, one at a time, full-screen, then *stops and celebrates* even if items remain. Bounded scope converts an unbounded guilt pile into a completable game (full design: Redesign 3).

**B-5 · Completion → Log auto-bridge.** Marking a task done offers a one-tap "log it" chip pre-filled with "Finished: {title}" into the task's life area. The Journal stops being a separate discipline and becomes a byproduct of action — history accretes with zero extra executive cost, powering B-6.

**B-6 · The "Done pile" as a first-class dopamine surface.** An always-reachable reverse-chronological view of everything completed/logged/captured today, rendered generously (big type, colour, satisfying stack). ADHD memory under-records its own wins; the system should over-display them (full design: Redesign 5).

**B-7 · Time-of-day adaptive shell.** The app already knows the clock; let the *same* dashboard re-weight by daypart — morning: today's tasks first; afternoon: Now card; late night: capture + micro-journal first, task counts de-emphasised (protecting sleep-adjacent hours from list-anxiety). Full design: Redesign 6.

**B-8 · Body-doubling timer on any task.** Tap "Sit with this" on a task → full-screen soft timer (no countdown pressure, just elapsed presence) + optional end-of-session auto-log. Converts the app from a list manager into a focus companion using only the Task + Log primitives.

**B-9 · Weekly "Life Review" postcard.** Sunday evening, one screen: per-life-area — captures sorted, tasks completed, logs written, rendered as colour-proportional art rather than tables. No metrics-of-shame (no streaks, no "down 40%"); purely additive evidence that life happened. Shareable as an image.

**B-10 · Progressive personalisation of defaults.** The system quietly learns per-context defaults — which life area E promotes captures into at 11 pm, which priority he actually uses (P4 default is already correct) — and pre-selects them, turning every form into a confirm-not-configure surface. All learning on-device; no new features required, only smarter defaults inside existing ones.

---

# PART C — 10 MOBILE REDESIGN PARADIGMS

*All designs use only the existing five features (Quick Capture, Tasks, Logs/Journal, Life Areas, Nudges) and the existing data model. What changes is layout, spatial hierarchy, and interaction grammar.*

---

## PHASE 1 — PRIMARY PARADIGMS

---

### Example 1 · The Ambient Chrono-Feed

**🗺️ Spatial Philosophy.** Time, not entity type, is the organising axis. The screen is a single vertical feed with three gravity bands — **NOW** (huge, centred, one card), **SOON** (medium, next few hours), **LATER / EOD** (small, folded). Tasks, nudges, and journal prompts lose their tab identities and appear *wherever their time-relevance puts them*. The Now Card (B-1) is the app's centre of gravity; everything else recedes by temporal distance, giving a time-blind user a felt sense of "temporal depth of field."

**📟 Visual Mockup.**

```
┌─────────────────────────────┐
│  Mon 20 · morning      ⚙︎  │   ← thin ambient header
│                             │
│  ╔═════════════════════╗    │
│  ║        NOW          ║    │
│  ║  🟣 Legacy          ║    │   ← ONE card. Huge type.
│  ║  Send pension form  ║    │     Fills ~45% of screen.
│  ║  due ~2h · P2       ║    │
│  ║ [ Done ✓ ] [ Later ]║    │   ← two thumb-size actions
│  ╚═════════════════════╝    │
│                             │
│  SOON ────────────────      │
│  🔔 Meds check · 12:00      │   ← nudge, medium row
│  🟢 Gym kit out · today     │   ← task, medium row
│                             │
│  LATER ▸ 3 things           │   ← collapsed, count only
│  EVENING ▸ journal prompt   │   ← folded EOD reflection
│                             │
│         ( ⊕ capture )       │   ← fixed bottom-centre bar
└─────────────────────────────┘
```

**🕹️ Interaction Walkthrough.**
- *Quick Capture:* tap the fixed bottom bar → capture field slides up over the feed (feed dims, stays visible behind); type; swipe the field upward to "throw" it into the inbox. Haptic `.success` + the bar briefly shows "Captured ✓".
- *Complete a task:* the Now Card's `Done ✓` is a 60pt-tall button — one tap, card performs a satisfying scale-and-dissolve, the next Now candidate slides up from the Soon band. No navigation ever occurs.
- *Handle a nudge:* nudges surface as Now/Soon cards with `Done · Not now` chips. "Not now" slides the card down into Soon with a gentle physics settle — visibly *deferred, not deleted*.
- *Reach the old structure:* pull the header down → life-area grid drops in as an overlay lens (see Example 2) for when the user wants the map rather than the moment.

**🧠 Cognitive Rationale.** Executive dysfunction is worst at the "what now?" decision; this layout answers it before it's asked. Temporal banding externalises time itself (treating time blindness with visible depth), the single-card focus makes decision paralysis structurally impossible on the default screen, and folding EOD reflection into the same feed teaches the daily rhythm (A5-5) without a manual. Directly resolves A4-1/A4-2 (counts replaced by one next action) and V-7 (stale nudges age down the feed instead of stacking as accusations).

---

### Example 2 · The Monastic Focus Lens

**🗺️ Spatial Philosophy.** Structural subtraction: the app shows **one Life Area at a time, full-bleed**, saturated in that area's colour. All other areas exist only as a thin "spine" of coloured dots along the screen edge. Within the lens, that area's tasks, recent logs, and nudges are the *only* content in the universe. The dashboard-of-everything becomes a place you *pass through* (a fast switcher), not a place you *stand in*.

**📟 Visual Mockup.**

```
┌─────────────────────────────┐
│ ●                           │
│ ●   🟣  L E G A C Y         │   ← area name, huge, its
│ ◉ ─────────────────────     │     colour floods the bg
│ ●   NEXT                    │   ← spine: other areas
│ ●   ▢ Send pension form     │     as dots; ◉ = current
│     ▢ Call solicitor        │
│                             │
│     RECENTLY (2)            │
│     ✓ Scanned documents     │   ← that area's logs/wins
│     ✎ "Felt good sorting…"  │
│                             │
│     NUDGE  🔔 Sun 18:00     │   ← area's nudge, inline
│                             │
│   [ ✎ log ]      [ ⊕ task ] │   ← area-scoped actions
└─────────────────────────────┘
```

**🕹️ Interaction Walkthrough.**
- *Switch lens:* tap any spine dot, or swipe horizontally anywhere — the whole screen cross-fades to the next area's colour world. Long-press the spine → mini-grid overlay of all areas with counts, tap to jump.
- *Quick Capture:* global two-finger swipe-down (or spine-bottom ⊕) opens capture *pre-tagged to the current lens's life area* — context is inherited, not asked for. A capture made in the Legacy lens lands promotable with Legacy pre-selected.
- *Complete a task:* tap the task's `▢` directly — it fills with the area colour, strikes through, and slides down into RECENTLY. Completion physically *feeds the history section on the same screen* — the win stays visible instead of vanishing.
- *Handle a nudge:* the area's nudge row shows its next fire time ambiently; when due, it pulses at the top of the lens with `Done · Not now` inline.

**🧠 Cognitive Rationale.** ADHD attention is serial, not parallel; this makes the interface serial too. One colour context = one working-memory frame; the spine keeps global awareness at pre-attentive cost (dots, not words — no reading required). Capture inheriting the lens context removes the life-area decision from promotion entirely (the single biggest friction in the current promote form, A2-3). Watching completions accumulate in RECENTLY converts the same screen from debt-display into evidence-of-life (A4-3).

---

### Example 3 · The Rapid-Fire Triage Screen

**🗺️ Spatial Philosophy.** The Capture Inbox stops being a list and becomes a **deck of one**. Exactly one capture occupies the centre as a large card; the remaining count is a soft "…and 4 more" beneath it, never itemised. The four compass directions are the four decisions, so triage becomes a body rhythm rather than a form. Sessions are bounded: five cards, then the app *stops you* with a celebration ("Sweep 5", B-4).

**📟 Visual Mockup.**

```
┌─────────────────────────────┐
│  Inbox sweep · 2 of 5   ✕  │   ← bounded session header
│                             │
│        ▲ make it a task     │   ← gesture legend fades
│                             │     after first session
│  ┌───────────────────────┐  │
│  │                       │  │
│  │  "book dentist —      │  │   ← ONE capture, big type,
│  │   the molar thing"    │  │     centred card
│  │                       │  │
│  │  note · yesterday     │  │
│  └───────────────────────┘  │
│ ◀ journal it     archive ▶ │
│        ▼ keep for later     │
│                             │
│        …and 3 more          │   ← pile stays abstract
│  ●●○○○                      │   ← sweep progress dots
└─────────────────────────────┘
```

**🕹️ Interaction Walkthrough.**
- *Triage:* **swipe up** = becomes a task → a single life-area chip row appears for one tap (priority defaults P4, due date deferred — one decision only, per A2-3's fix); **swipe left** = becomes a journal/log entry as-is; **swipe right** = archive (processed, no artifact); **swipe down** = keep — returns to the bottom of the pile guilt-free. Every swipe = distinct haptic; card physically flies off in the chosen direction.
- *Quick Capture:* not on this screen by design — triage is a consumption mode. The global capture gesture still works and feeds the pile.
- *Session end:* after 5 cards a full-screen moment: "Sweep done — 5 sorted. 🎉 [One more sweep] [Enough]". "Enough" is styled *equally* prominently — stopping is a sanctioned outcome, not a failure exit.
- *Failure handling:* a failed promote keeps the card in place with a shake + inline "Didn't stick — again?" chip (per-card scope, resolving V-4; retry-safety resolving V-5 is a spec requirement of this design).

**🧠 Cognitive Rationale.** Serial single decisions eliminate comparative paralysis (a list invites ranking; a deck permits only yes/no/where). Gesture-mapped verbs move the decision from language into motor memory — sustainable even at cognitive-fatigue floor. The abstract pile ("…and 3 more") prevents the queue-length dread that makes inboxes avoidance triggers, and the bounded sweep converts an unbounded obligation into a completable, dopamine-paying game.

---

### Example 4 · The Minimalist HUD

**🗺️ Spatial Philosophy.** Radical density reduction: the default screen is a **heads-up display of exactly three glanceable instruments** — Now (one line), Areas (a row of emoji-coded dots), Today (a tally of wins). *No entry form, no list, no picker is ever visible at rest.* Every data-entry surface is summoned by a single tap on its trigger and dismissed by completion. The screen is calm because everything on it is either a signal or a door — never a form.

**📟 Visual Mockup.**

```
┌─────────────────────────────┐
│                             │
│   NOW                       │
│   ▸ Send pension form       │   ← one line. Tap = detail
│                             │      sheet. 64pt tall row.
│                             │
│   AREAS                     │
│   🟣  🟢  🔵  🟠  ⚪️        │   ← emoji/colour dots only.
│   ·2  ·   ·5  ·1  ·        │      tiny count ticks. Tap
│                             │      a dot = that area sheet
│   TODAY                     │
│   ✓✓✓ ✎ ⚡️                 │   ← 3 done, 1 log, 1 capture
│                             │      — icons, not numbers
│                             │
│                             │
│  ┌───────────────────────┐  │
│  │      ⊕  capture       │  │   ← 72pt full-width bar,
│  └───────────────────────┘  │      thumb-anchored
└─────────────────────────────┘
```

**🕹️ Interaction Walkthrough.**
- *Quick Capture:* tap the 72pt bottom bar → sheet with keyboard already raised, one field, Save. Kind defaults to note (picker demoted to a small trailing chip, per A1-4). Long-press the same bar = voice capture (A3-2).
- *Complete a task:* tap NOW row → half-height detail sheet with a dominant `Done ✓` button; tap → sheet collapses, the TODAY tally gains a ✓ with a spring animation and `.success` haptic — the HUD itself visibly banks the win.
- *Handle a nudge:* a due nudge takes over the NOW slot (highest precedence) with inline `Done · Not now` chips; "Not now" returns the previous NOW.
- *Open an area:* tap its dot → 80%-height sheet containing that area's task list (Example 2's lens content in sheet form). The HUD never navigates away — everything is a sheet over home, so "where am I?" always has the same answer.

**🧠 Cognitive Rationale.** Visual noise is cognitive load; a resting screen with three instruments has a scan cost near zero and can be read pre-attentively (emoji + colour, A4-2's count-wall dissolved into ticks). Massive touch targets (64–72pt) respect fatigued motor control. Sheets-over-home preserves spatial constancy — no navigation stack to reconstruct after an interruption, which is the single most common ADHD context-loss event. The TODAY tally makes the HUD emotionally net-positive: the calmest screen in the app is also the one that shows your wins.

---

## PHASE 2 — RIGOROUS SELF-CRITIQUE & GAP ANALYSIS

**C1 · The Now Card is an oracle problem (Examples 1, 4).** Both designs stake everything on the system choosing the right "one thing." The precedence rule (due nudge > due-today P1 > triage suggestion) is deterministic but *dumb* — it can't feel energy state, and on a task-avoidance day the Now Card becomes a single point of confrontation: one big card the user is specifically avoiding, now unavoidable. Repeated "Later" taps risk becoming a new micro-shame loop ("I deferred it six times"). **Gap:** no pressure-release valve; no learning from deferral patterns; no way to say "not this *kind* of thing right now."

**C2 · Serial interfaces hide the map (Examples 2, 3).** The Focus Lens and Triage Deck both buy focus by removing overview — but ADHD planning deficits sometimes need the map (weekly review, "what's colliding on Thursday?"). The lens also makes cross-area comparison a multi-swipe archaeology task. Over a long timeline, hidden inventory quietly grows: the deck's "…and 3 more" becomes "…and 61 more" after a two-week lapse, and *abstractness flips from mercy to denial* — the pile is unknowable until entered. **Gap:** no honest-but-kind bulk state; no overview mode that isn't a regression to the wall-of-lists.

**C3 · Gesture grammars decay (Examples 3, and Example 1's throw-to-save).** Four-direction swipe vocabularies are elegant in week one and ambiguous in week six — especially for a user whose medication state varies motor precision across the day. A mis-swipe in the triage deck (archive instead of task) is a *destructive* error made at the app's highest-velocity moment, and iOS system edge gestures compete for left/right swipes. **Gap:** no gesture-error forgiveness (undo), no redundant button path for every gesture verb.

**C4 · Calm can curdle into under-stimulation (Example 4).** The Minimalist HUD's near-empty resting state assumes calm = good. For a dopamine-seeking brain at 11 pm, a nearly blank screen offers nothing to *engage* — the user bounces to a louder app. Minimalism serves the overwhelmed state but under-serves the under-aroused state; the HUD has no texture to reward a second glance. **Gap:** none of the four designs adapts to *arousal state* — they each pick one cognitive weather and optimise for it permanently.

**C5 · Late-night and re-entry states are unmodelled everywhere.** All four primary designs implicitly assume daytime, in-rhythm use. None changes posture at 1 am (when task-confrontation harms sleep and capture/journal should dominate), and none has a designed "welcome back after 5 days away" state — the moment where V-7's stale-nudge wall currently does its damage and where every one of these layouts would still greet the user with accumulated obligation. **Gap:** temporal asymmetry and absence-recovery are missing as first-class design states.

**C6 · Completion feedback is still terminal, not cumulative (Examples 1–3).** Cards dissolve, rows strike through — the win *disappears*. Only Example 4's tally banks it. Dopamine design needs wins to *accrete somewhere visible*, or completion remains a net subtraction from the screen. **Gap:** a persistent, ambient momentum surface.

*Examples 5–10 are engineered specifically against C1–C6.*

---

## PHASE 3 — NEXT-GENERATION PARADIGMS

---

### Example 5 · The Dopamine Momentum Tracker *(answers C6, C1's shame loop)*

**🗺️ Spatial Philosophy.** The home surface is a **garden of accretion**: a horizontal "momentum river" across the screen's midline that grows a glyph for every win — task done, log written, capture sorted, nudge honoured — coloured by life area. No numbers, no streaks, no per-day comparison: the river only ever *gains*. Above it, one gentle next-action; below it, capture. History isn't a report you visit; it's the landscape you stand on.

**📟 Visual Mockup.**

```
┌─────────────────────────────┐
│  Mon evening                │
│                             │
│   maybe next ─────────      │
│   ▸ Send pension form  [✓]  │   ← ONE suggestion + inline
│     or not — river's full   │      done btn. Copy defuses
│                             │      C1 confrontation.
│  ── the river ──────────    │
│   ❋ ● ✎ ❋ ❋ ● ⚡ ✎ ●       │   ← today grows rightward;
│  ◂ scroll back through days │      glyph = win, colour =
│   ~~~~~~~~~~~~~~~~~~~~~     │      life area. Tap glyph =
│                             │      its story (log/task)
│   RIVERBANK                 │
│   🟣2  🟢·  🔵5  🟠1        │   ← areas as pebbles w/ tiny
│                             │      counts (doors, not debt)
│  ┌───────────────────────┐  │
│  │      ⊕  capture       │  │
│  └───────────────────────┘  │
└─────────────────────────────┘
```

**🕹️ Interaction Walkthrough.**
- *Complete a task:* tap `[✓]` on the suggestion (or inside an area sheet) → a glyph *physically drops into the river* with a two-stage haptic (impact, then settle) and a brief colour bloom. The win is banked in view, permanently.
- *Quick Capture:* bottom bar as in Example 4; a saved capture adds a small ⚡ glyph to the river immediately — *capturing itself is honoured as a win*, reinforcing the keystone habit.
- *Handle a nudge:* due nudge appears above the suggestion slot; `Done` drops a ring-glyph into the river; `Not now` fades it with zero river penalty — the river has no gaps, only presence. Nothing ever removes a glyph.
- *Reflect:* scroll the river leftward through past days — density varies, but sparse days render as calm water, not empty cells; long-press a glyph → the log/task it represents, making the river the Journal's ambient index.

**🧠 Cognitive Rationale.** ADHD motivation responds to *visible accumulation* and collapses under *comparison*. Removing all numeric framing (no streaks, no counts-per-day) makes bad days uncomparable and therefore unshameful, while the physics of the glyph-drop delivers the immediate payoff completion needs (A2-5). "Or not — river's full" is language engineering against C1: the suggestion is an offer, not a summons.

---

### Example 6 · The Body-Clock Canvas *(answers C4, C5's temporal asymmetry)*

**🗺️ Spatial Philosophy.** One screen, three **posture states** keyed to daypart (user-tunable boundaries, honouring E's night-owl rhythm — "morning" can start at 11:00). The layout doesn't re-theme; it *re-weights*: the same five features change size, order, and default action. Morning = orient (structure first), Midday = drive (Now first), Night = release (capture/journal first, tasks folded to a whisper). The app has a circadian body.

**📟 Visual Mockup.**

```
  MORNING (orient)          MIDDAY (drive)           NIGHT (release)
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│ morning, E        │     │ ╔══════════════╗ │     │ 🌙 late          │
│                  │     │ ║     NOW      ║ │     │                  │
│ TODAY'S SHAPE    │     │ ║ Pension form ║ │     │ ┌──────────────┐ │
│ 🟣▪▪ 🔵▪ 🟠▪     │     │ ║ [✓]  [later] ║ │     │ │ empty your   │ │
│ 3 things, 1 nudge│     │ ╚══════════════╝ │     │ │ head…    ⊕   │ │
│                  │     │                  │     │ └──────────────┘ │
│ FIRST MOVE       │     │ river ❋●✎❋      │     │ ┌──────────────┐ │
│ ▸ Gym kit out    │     │                  │     │ │ ✎ one line   │ │
│                  │     │ areas 🟣🟢🔵🟠   │     │ │ about today? │ │
│ [start the day ▸]│     │                  │     │ └──────────────┘ │
│                  │     │ [ ⊕ capture ]    │     │ tomorrow ▸ folded│
│ [ ⊕ capture ]    │     │                  │     │ (no task counts) │
└──────────────────┘     └──────────────────┘     └──────────────────┘
```

**🕹️ Interaction Walkthrough.**
- *Morning:* "start the day ▸" is one tap that walks Today's Shape → First Move → done (a 3-screen guided glance, ~10 s) — the startup-mandate problem answered with a rail, not a wall.
- *Midday:* Example 1's Now Card grammar; completions feed the river strip.
- *Night:* capture and one-line journal are the *only* raised surfaces; the task world is a single folded "tomorrow ▸" row (peekable, never pushed). Nudges due after the user's sleep boundary auto-hold until morning (A5-3 quiet hours made spatial).
- *Manual override:* the daypart chip (🌙/☀️) in the corner is tappable — the user can always summon another posture; the canvas *suggests*, never traps (feeds C1's fix: state, not oracle, chooses emphasis).

**🧠 Cognitive Rationale.** Executive capacity is rhythmic; a static layout is wrong twice a day. Front-loading structure in the morning (visible shape before starting — the app's founding philosophy, made literal), single-focus at midday, and de-weaponising the task list at night (protecting sleep from list-anxiety, C5) each match interface posture to the brain state actually present. Under-arousal (C4) is met by the night state's *invitational* texture — prompts to engage with, not blankness.

---

### Example 7 · The Spatial Card Deck *(answers C2's lost map + C3, without scrolling)*

**🗺️ Spatial Philosophy.** The entire app is **five full-screen cards on a horizontal rail** — Today · Areas · Inbox · Journal · Nudges — with *zero vertical scrolling anywhere*. Each card shows at most seven large elements; overflow lives behind an explicit "+N more ▸" flip, never a scroll. Position on the rail *is* the information architecture: a persistent dot-rail at the bottom is the map that serial designs lost. One thumb, one axis, one card of content at a time.

**📟 Visual Mockup.**

```
        ◂ swipe ▸
┌─────────────────────────────┐
│  TODAY              ◦◉◦◦◦  │   ← dot-rail = you are here
│ ┌─────────────────────────┐ │
│ │ 🔔 Meds · now  [✓][not] │ │
│ │ ─────────────────────── │ │
│ │ ▢ Pension form    🟣 P2 │ │   ← max 7 rows, 56pt each,
│ │ ▢ Call solicitor  🟣 P3 │ │      fits without scroll
│ │ ▢ Gym kit out     🟢    │ │
│ │                         │ │
│ │        +2 more ▸        │ │   ← explicit flip, not scroll
│ └─────────────────────────┘ │
│                             │
│ ═══════════ ⊕ ═══════════  │   ← capture bar on EVERY card
│  today areas inbox jrnl 🔔  │   ← labelled dot-rail (map)
└─────────────────────────────┘
```

**🕹️ Interaction Walkthrough.**
- *Navigate:* horizontal swipe or tap a rail label — card slides with a physical snap; the rail dot fills. Every verb also exists as a visible button (C3's redundancy rule); horizontal-only motion avoids iOS edge-gesture conflicts by using a 90%-width card with snap points.
- *Quick Capture:* the ⊕ bar is *identical on all five cards* — capture is positionally invariant, so the motor program never varies. Tap → field rises over the current card; save drops a chip that visibly flies toward the Inbox rail dot, which ticks up. (Answers V-1's trust loop with spatial evidence.)
- *Complete a task:* tap the row's `▢` in place — fill, strike, settle; row stays (struck) until the card is next re-entered, so the win remains visible (C6). Mis-taps are one-tap reversible in place.
- *Handle a nudge:* due nudges pin to the top of TODAY with button verbs `[✓][not now]` — no gesture required at all.

**🧠 Cognitive Rationale.** Vertical scrolling is where ADHD attention dissolves — a scroll position is an unmarked location in an unbounded space. Cards make every location *named, bounded, and re-findable* (the dot-rail is a constant external map, answering C2), and the 7-element cap enforces subitizable screens. Buttons-plus-gestures keeps week-six usability where gesture memory alone would decay (C3). Positional invariance of capture makes the keystone habit purely mechanical.

---

### Example 8 · The Action Sheet Matrix *(answers C3's precision problem; one-handed reality)*

**🗺️ Spatial Philosophy.** The top 60% of the screen is a **read-only glance zone** (never houses a control); the bottom 40% is a **fixed command deck** of four large keys plus a capture bar. All input happens in native iOS action sheets and context menus that rise *from the bottom* — the OS's own thumb-native grammar. The phone is assumed held one-handed, on a bus, with a coffee: no target above thumb reach, ever.

**📟 Visual Mockup.**

```
┌─────────────────────────────┐
│  GLANCE ZONE (no controls)  │
│  🔔 Meds · due now          │
│  ▸ Pension form · 🟣 P2     │   ← read-only status stack:
│  river ❋●✎❋●               │      nudge, next task, wins
│  🟣2 🟢· 🔵5 🟠1            │
│─────────────────────────────│
│  COMMAND DECK               │
│ ┌──────┐ ┌──────┐          │
│ │  ✓   │ │  🔔  │          │   ← 4 keys, ~76pt square:
│ │ done │ │nudges│          │      done, nudges,
│ └──────┘ └──────┘          │      areas, journal
│ ┌──────┐ ┌──────┐          │
│ │  ▦   │ │  ✎   │          │
│ │areas │ │ log  │          │
│ └──────┘ └──────┘          │
│ ┌───────────────────────┐  │
│ │      ⊕  capture       │  │   ← always the closest thing
│ └───────────────────────┘  │      to the thumb
└─────────────────────────────┘
```

**🕹️ Interaction Walkthrough.**
- *Quick Capture:* thumb taps the bar (it's the nearest control on screen) → keyboard + field; long-press = voice. Sheet, save, haptic — thumb never travels above mid-screen.
- *Complete a task:* tap `✓ done` → an action sheet lists **only today's open tasks** (large rows, max ~6): tap one → sheet collapses, glance zone's river gains a glyph. Two taps, zero navigation, zero precision demands.
- *Handle a nudge:* tap `🔔` (badged when due) → action sheet: "Meds check — **Done · Not now · Skip today**" as full-width native buttons. The A5-2 verb set, rendered in the OS's own muscle memory.
- *Deep work:* long-press any deck key = context menu of secondary verbs (e.g., long-press `✎ log` → "Journal entry / Quick log / Voice note"); the matrix scales in depth without ever adding visible chrome.

**🧠 Cognitive Rationale.** Motor accessibility *is* cognitive accessibility: when targets are huge, native, and always in the same place, action cost approaches zero even at fatigue floor — and native action sheets inherit years of OS muscle memory instead of asking the user to learn a bespoke grammar (C3 dissolved rather than mitigated). Separating glance (top) from command (bottom) means the eyes and thumb each have a fixed home — no visual search, no reach, no re-orientation after interruption.

---

### Example 9 · The Conversational Mirror *(answers C1's oracle problem + C5's re-entry)*

**🗺️ Spatial Philosophy.** The app becomes a **single chat thread with the system**. Nudges arrive as incoming messages; capture is just… typing; task completion, logging, and triage are chip-replies to the system's questions. Time flows downward like any conversation, giving the day a narrative spine. Crucially the system *asks* rather than *tells* — an interrogative interface can be wrong gracefully ("Not that? What instead?"), which a Now Card oracle cannot.

**📟 Visual Mockup.**

```
┌─────────────────────────────┐
│  Life OS               ▦   │   ← ▦ = classic view escape
│                             │
│ ┌───────────────────────┐   │
│ │ Morning ☀️ 3 things    │   │   ← system message
│ │ today. Feel like       │   │
│ │ starting with the      │   │
│ │ pension form?          │   │
│ │ [yes ▸] [something     │   │   ← chip replies
│ │  smaller] [not today]  │   │
│ └───────────────────────┘   │
│                             │
│      ┌────────────────────┐ │
│      │ done ✓             │ │   ← user reply, right side
│      └────────────────────┘ │
│ ┌───────────────────────┐   │
│ │ Banked. ❋ That's 2    │   │
│ │ today. 🔔 Meds at 12 — │   │   ← nudge as dialogue
│ │ I'll ask then.        │   │
│ └───────────────────────┘   │
│                             │
│ [ type / talk / ⚡capture ] │   ← composer = capture field
└─────────────────────────────┘
```

**🕹️ Interaction Walkthrough.**
- *Quick Capture:* type anything into the composer and send — free text defaults to a capture (⚡ chip confirms: "caught it — inbox'd"). No mode switch: *the message box is the capture box.* Mic button = voice capture (A3-2) inline.
- *Complete a task:* reply to the system's morning question with a chip, or type "done" after any task mention; the system confirms with a river-glyph line (C6 accretion in message form).
- *Handle a nudge:* nudges arrive as messages with `[Done] [Not now] [Skip today]` chips — and the same message appears as a real push notification with identical actions (V-6's fix given a face). Answering from the Lock Screen back-fills the thread.
- *Re-entry after absence:* the killer scene. Instead of a stale-nudge wall, the thread greets: "Been a few days — no ledger kept. 🌱 Want the one thing that matters, or just to empty your head?" `[one thing] [brain dump] [show me everything]`. Absence is narratively absorbed, not itemised (C5/V-7 resolved at the emotional layer).
- *Journal:* at night the system asks one question ("One line about today?") — replying *is* the journal entry, typed into a box the user has already used twenty times that day.

**🧠 Cognitive Rationale.** Conversation is the one interface pattern requiring zero learned structure — turn-taking is pre-loaded in every human. Questions externalise executive initiation (the system opens every loop; the user only ever *responds*, which is neurologically cheaper than *initiating*), chips constrain decisions to 2–3 pre-made options, and the dialogue frame gives the system a *repairable* voice — it can offer, miss, apologise, and re-offer without the authority of a dashboard that "knows." This is the shame-free failure mode none of the spatial designs could reach.

---

### Example 10 · The Multi-Sensory Horizon *(answers C2's overview gap + C4, via pre-attentive design)*

**🗺️ Spatial Philosophy.** The overview screen the serial designs lost — rebuilt so it can be read **without reading**. The day is a left-to-right *horizon band* (morning → night) across the screen's upper third; life areas are colour *terrain blocks* in the middle; wins are *texture* accumulating at the bottom. Shape, colour, and weight carry all first-pass meaning: circles = nudges, squares = tasks, soft blobs = journal; size = priority; saturation = urgency. Words appear only on touch — the screen is an instrument panel first and a document never.

**📟 Visual Mockup.**

```
┌─────────────────────────────┐
│ HORIZON  ☀️───────────🌙   │
│      ●     ■        ◍       │   ← today's objects sit at
│    meds  BIG task  soft     │      their time positions;
│    12:00 (P1=big) journal   │      NOW-line glows ┃
│          ┃now               │
│─────────────────────────────│
│ TERRAIN                     │
│ ▓▓▓▓▓▓▓ ▓▓▓ ▓▓▓▓▓ ▓        │   ← life areas as colour
│ 🟣      🟢  🔵    🟠        │      blocks; width = open
│                             │      load (capped visual,
│                             │      never a number)
│─────────────────────────────│
│ SEDIMENT  ❋❋●✎❋            │   ← today's wins as texture
│                             │
│ ┌───────────────────────┐  │
│ │      ⊕  capture       │  │
│ └───────────────────────┘  │
└─────────────────────────────┘
```

**🕹️ Interaction Walkthrough.**
- *Read the day:* one sweep of the horizon answers "what's coming?" spatially — a big square before the glowing now-line means a heavy task is imminent; nothing after 🌙 by design (night is visually protected, per Example 6). Tap any shape → 40%-height sheet with words and actions.
- *Complete a task:* tap its ■ → sheet → `Done ✓` → the square *falls* from the horizon into the sediment layer with a settling haptic — gravity as completion metaphor, accretion per C6.
- *Handle a nudge:* due ● pulses gently at the now-line (motion is reserved *exclusively* for dueness — the only animated thing on a resting screen is the thing that wants you); tap → `Done · Not now · Skip today`. "Not now" slides the circle rightward along the horizon — deferral made visibly spatial, not shameful.
- *Quick Capture:* bottom bar as ever; captures surface as small ◇ diamonds at the horizon's right edge (unplaced in time) — a visible-but-unpressured queue that doubles as the triage entry point (tap a ◇ cluster → Example 3's deck).

**🧠 Cognitive Rationale.** Pre-attentive channels (colour, shape, size, position, motion) process in <250 ms with near-zero working-memory cost — this screen moves the entire first read below the reading threshold, which is transformative under fatigue or medication troughs (C4's under-arousal is met with rich-but-calm visual texture rather than blankness). Terrain width capped as *visual* proportion rather than numerals keeps load-awareness honest without manufacturing an anxiety meter (A4-2). The horizon is time blindness treated spatially: duration and sequence become *distance*, the one format the ADHD time-sense reliably parses.

---

## CLOSING SYNTHESIS

The five paradigm families are composable, not competing. A coherent v2 shell could be: **Body-Clock Canvas** (Ex. 6) as the temporal skeleton · **Momentum River** (Ex. 5) as the persistent win-surface · **Triage Deck** (Ex. 3) behind the inbox · **Action-Sheet command deck** (Ex. 8) as the interaction floor · **Conversational re-entry** (Ex. 9) as the absence-recovery mode · **Horizon** (Ex. 10) as the pull-down overview lens. Before any of that, the trust layer must be sealed: V-1/V-2/V-3 (one source of truth + confirmed capture), V-6 (nudges that actually notify), V-5 (retry safety), and A2-5 (a haptic vocabulary). Structure visible before starting; wins visible after finishing; shame structurally impossible in between.

*— End of assessment. No FEATURE blocks drafted; per workflow, each renovation candidate awaits explicit green light before entering `TODO-CLAUDE-CODE.md`.*

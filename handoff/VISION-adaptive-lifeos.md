# The adaptive LifeOS — vision map (2026-09-03)

*Product of E's pre-written vision brief ("pause on writing code… genuinely forward-thinking,
innovative, and groundbreaking for ADHD and neurodivergent individuals") plus four deep
questions E answered the same day. This is a VISION record, not a build plan: nothing here is
scoped, sequenced, or authorised. It sits above `SESSION-OPENER-routines-design.md` (the
settled Routines arc) and deliberately builds on it. Public launch intent
(`public-launch-intent` memory) governs throughout: designed for many users, not for E alone.*

---

## 1. The Island — one organ, four roles, a precedence law

E's answer to "what should the always-visible surface hold?" was ALL FOUR roles —
context-shifting, the one next thing, the catcher, the anchor. The synthesis is not a
compromise; it is a **state machine with a published precedence law**, so the surface is
smart AND predictable (the trap E was warned about, solved by making the rotation legible):

```
1. ANCHOR    — an open loop exists (routine mid-run, sprint live, capture half-triaged):
               the island holds the way BACK. Highest precedence: return beats novelty.
2. NEXT      — no open loop, but context nominates exactly one action (arrived at a place,
               morning routine due): the island IS the decision, pre-made.
3. CATCHER   — otherwise: a permanent capture affordance. The resting state is the net,
               because a thought in flight is the thing ADHD loses first.
```

The law in one sentence a user can hold: **"If I left something open it shows me the way
back; if the moment knows my next move it shows me that; otherwise it catches what I throw
at it."** The routines display-LA (already settled into Arc 1) is state 1's first shipped
citizen; the sprint LA already exists. The roadmap is: generalise, never multiply — ONE
Activity design with three faces, not three Activities fighting for the island.

Non-linear thinking is served by exactly this: jumping threads is safe when every glance at
the top of the screen offers the way back to the dropped one.

## 2. The sensing stack — what the app can honestly know

E validated all three behavioral signals and asked for the full permission-gated catalogue
("assuming the user gives full permission via the appropriate guidelines set by Apple or
data protection laws").

**Tier 0 — already witnessed, no permission beyond what's granted (ships with existing data):**
- **Capture-burst rhythm** — racing mind vs flat/hyperfocus (capture timestamps exist today).
- **Avoidance patterns** — the same task deferred repeatedly; sprints started-then-abandoned
  (task events + focus_sessions exist; routine tapped-vs-skipped records arrive with the
  smart-skip direction).
- **Rhythm breaks** — the usual morning movement absent (location_events exist today).
- Notification response latency (own notifications only), journal cadence, time-of-day usage
  shape.

**Tier 1 — permission-gated, real Apple APIs, HIGH value (verify entitlements at build time —
this list is from model knowledge, not checked docs):**
- **HealthKit sleep** (duration, consistency, bedtime drift) — the single strongest
  next-day-capacity predictor for ADHD; read-only, standard permission.
- **HealthKit State of Mind** (iOS 18+) — Apple's own system-level mood/valence record; other
  apps (incl. Apple Journal/Mindfulness) write it, we can read AND write it. The app's energy
  chips could sync both ways — the self-report becomes system-wide, not siloed.
- **HealthKit HRV / resting heart rate / exercise minutes** — physiological load and the
  post-exercise dopamine window (a routine that fires "after a workout" becomes possible).
- **Journaling Suggestions API** (iOS 17.2+) — Apple hands over "moments" (outings, photos,
  workouts, music) as journaling prompts; a native fit for the Journal tab and passive
  context without us collecting anything.
- **CoreMotion activity** (stationary/walking/running) — sedentary-stretch detection, cheap.
- **EventKit calendar density** — a wall-to-wall meeting day IS a low-capacity day; no
  inference needed, just arithmetic.
- **Weather (WeatherKit)** — daylight/pressure correlate with energy for many; cheap garnish.
- **MusicKit recently played** — tempo/mood of chosen music as a self-selected state signal.

**Tier 2 — exists but honestly hard; name the ceiling before anyone dreams:**
- **Screen Time / DeviceActivity** — app-usage categories need the FamilyControls entitlement
  (parental-control track, Apple-approval-gated); treat as likely unavailable.
- **Focus mode status** (`INFocusStatus`) — needs a communication-app entitlement; likely out.
- Keyboard cadence outside our own app, screen unlocks, ambient audio — not available to
  third-party apps; never promise them.

**The trust architecture (public-launch grade):** every signal is opt-in per-signal with a
plain-words "what this lets the app notice" line; ALL inference runs on-device; raw signals
never leave the phone (Firestore holds conclusions the user chose to keep, not sensor
streams); a visible "what the app currently believes and why" screen makes the model
auditable — inference you can SEE is a feature, inference you can't is surveillance. UK/EU
data-protection posture: health data is special-category — on-device processing and explicit
granular consent is the compliant shape as well as the right one.

## 3. The adaptation vocabulary — what a low-capacity day changes

E chose: **offer, never impose** (the constitution — adaptation is always consented, one
tap, never silent) + **shrink the surface** + **change the ask**. E asked for a secondary
think on further facilitations; here is the vocabulary, each item consent-first:

- **The lighter path on routines** *(nearest-term; touches the settled arc's data model)* —
  a routine step can be marked "core"; the low-day offer runs just the core steps ("Just the
  gym app today?"). One boolean per step, designed into Arc 1's editor or retrofitted.
- **Capture-led mode** (E's "change the ask") — the app stops requesting and starts
  receiving: Today leads with the composer and the inbox, tasks recede to a drawer, nudges
  hold. The app's posture flips from coach to companion.
- **Postpone with dignity** — a one-tap "not today" on anything, which reschedules WITHOUT
  red, without "overdue", and without asking when. Deferral as a first-class verb, not a
  failure state.
- **Keep-company mode (body doubling)** — a sprint variant with no task and no target: the
  timer just sits with you ("working alongside"). ADHD body-doubling is one of the best
  attested interventions and costs almost nothing on top of the sprint engine.
- **Micro-launch** — on low days the ask shrinks to opening things: "open the doc" is the
  whole task; the sprint starts at 5 minutes not 15 (settings exist); completion celebrates
  the START, honouring that initiation is the disorder's core tax.
- **Sensory dial** — reduced motion, warmer palette, fewer numbers on low days (the token
  layer makes this cheap); loud celebration only when capacity is high.
- **Time-dilation honesty** — on low days, shown durations get padding ("~40 min today")
  because time blindness worsens under load; estimates adapt to the person, not the average.

## 4. Bad days — one cohesive system, in the settled Routines grammar

E chose **honest-never-judging + celebrate-the-return + the fresh-start gesture**, "combined
into one cohesive system" (amnesty-as-neutral-rendering deliberately not chosen — truth over
airbrushing). The cohesive system:

1. **The record tells the truth**: gaps appear as gaps — hiding them would gaslight the
   person who lived them. But the app renders data, never verdicts: no red, no "you missed",
   no streak-broken iconography. (Corollary kept from amnesty's spirit: the app only ever
   counts UP; nothing anywhere counts what didn't happen.)
2. **The return is the celebrated event**: opening the app after silence is greeted
   ("good to see you") and Momentum treats resumption as the headline metric — the thing
   ADHD actually needs measured is recovery speed, not continuity.
3. **The fresh-start gesture** is the bridge between them: one explicit tap sweeps the
   accumulated pressure (overdue, stale inbox) into a parked, recoverable archive — the
   day-one feeling as a renewable resource. It is the routines grammar again: undo-friendly,
   explicit, never automatic.

## 5. How this layers onto what's already settled

Nothing above disturbs the Routines sequence. It gives it a destination:

- **Arc 1** (place-scoped routines + display LA) ships the island's state 1 and, with one
  boolean, can carry the lighter-path hook.
- **Arc 2** (first-class + time triggers) creates the object the island's state 2 nominates.
- **Smart-skip's per-run records** are the first Tier-0 sensing stream.
- The bad-day system is a design CONSTITUTION applicable immediately: nothing shipped so far
  violates it (no streaks exist), and every future Momentum/analytics block gets held to it.

*Next mapping steps when E wants them: pick the first adaptation verb to prototype, decide
whether the island state machine becomes its own arc after Routines Arc 2, and put the
Tier-1 sensing list through a real entitlement/docs verification pass.*

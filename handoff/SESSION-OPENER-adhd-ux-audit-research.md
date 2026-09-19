# ADHD / neurodivergent executive-function research — for the ADHD LifeOS UX audit

*2026-09-19. Produced by a research sub-agent (web search + fetch, no repo access) at E's request,
before the question round of the ADHD UX audit (`feature/adhd-ux-audit`). Scratchpad copy; to be
filed under `handoff/` as a design record when the audit opens (a permanent record, like the
`SESSION-OPENER-*` design records — never archived).*

**Grade key:** STRONG (meta-analyses / replicated) · MODERATE (several studies, or one
meta-analysis with caveats) · WEAK (single / small-n / indirect) · FOLK (community or lived
experience, little peer review) · CONSENSUS (standards or vendor guidance — expert consensus, not
experimental evidence) · **[child]** child-only evidence · **[gen]** general population, not ND
samples.

---

## 1. Summary

1. **The core deficits are real in adults, but moderate and uneven.** Working memory d≈.54
   (Alderson 2013); mean across neurocognitive domains d≈.45 (Pievsky & McGrath 2018). Not every
   person with ADHD has every deficit (Willcutt 2005): there is no single "ADHD user", so letting
   people turn features down is a requirement, not polish.
2. **Four findings are both strong and actionable:**
   - Timing is impaired — "time blindness" is one folk term the research supports (Marx 2021, 55
     studies).
   - Clock-based remembering is the reliable weakness (time-based prospective memory consistently
     impaired; event-based mixed) → favour location/event triggers over clock reminders.
   - Immediate rewards dominate (small-to-medium preference for small-immediate over large-delayed).
   - Emotional dysregulation is large in adults (g=1.17).
3. **RSD is FOLK as a construct; the shame/criticism research is not.** Adults with ADHD report more
   perceived criticism and less self-compassion; self-forgiveness reduces later procrastination. Red
   overdue states, broken streaks and blaming copy carry real risk.
4. **"Minimal UI" is supported only for irrelevant salience** (motion, flashing, decoration). Adults
   with ADHD are not captured more by distractors; they linger on them longer. Load theory warns
   against stripping the task in focus down to nothing.
5. **Rewards follow an inverted U.** Frequent, immediate, informational feedback helps [child];
   infrequent/variable reinforcement hurts [child]; extreme "juice" performs as badly as none;
   expected tangible rewards reduce intrinsic motivation. ~40% of autistic people currently have
   reduced sound tolerance (matters for any chime).
6. **Motor co-occurrence is common** (30–50% in children with ADHD; autism d=1.20). Every swipe,
   long-press or drag needs a tap alternative (Apple HIG; WCAG 2.5.1, 2.5.7).
7. **Abandonment is the dominant real-world outcome.** Median 15-day retention for mental-health apps
   3.9%; ~70% of health-app users stop within 100 days; in 2020 none of 109 ADHD apps had efficacy
   evidence. How the app treats someone who has lapsed matters more than any feature.
8. **Weak or folk claims:** ego depletion / decision fatigue, choice paralysis as an ADHD trait,
   dyslexia fonts, body doubling, hyperfocus as ADHD-specific, variable rewards "for dopamine".

---

## 2. Findings

**Cross-cutting facts:** adult ADHD deficits — RT variability d=.53–.66, response inhibition .52,
planning .51, set-shifting .35 (smallest) (Pievsky & McGrath 2018), STRONG. ~80% of children with
ADHD vs ~50% of controls show ≥1 EF weakness (Nigg 2005 via Willcutt 2005) [child]. Co-occurrence:
ADHD in autistic people 38.5% current / 40.2% lifetime (Rong 2021); reading disability in ADHD 25–40%
(Willcutt & Pennington 2000); motor problems in children with ADHD 30–50% (Kaiser 2015) [child].

### (1) Visual density and noise reduction

**1.1 Distractibility is a failure to disengage, not greater capture.** MODERATE (adult lab, small n).
Forster 2014 (more distraction in ADHD; raising focal perceptual load cut interference equally in both
groups); Zhang 2024 (36 vs 82: same oculomotor capture, longer dwell); Mullane & Klein 2008 [child]
(automatic search intact, effortful serial search less efficient).
- Sort every element into "needed for the current task" vs "peripheral"; peripheral gets no accent,
  no badge, no motion. Test: at rest on Home, zero elements animate.
- Recovery beats prevention: after any attention pull (toast, sheet, LA update) the screen says where
  the user was. Test: after dismissing any overlay, the next action is identifiable within 2 s.
- Don't strip the focal task to something perceptually trivial (see Tensions).

**1.2 Irrelevant motion and salience cost everyone; ADHD raises the cost.** STRONG that motion onset
captures [gen]; MODERATE that animated/flashing elements slow search and raise workload [gen]; WEAK
for ADHD-specific density. Abrams & Christ 2003; Burke 2005 (flashing banners raised NASA-TLX);
Kasatskii 2023 (noisy code editor, effect varied with ADHD symptoms); Fisher 2014 [child, gen]
(decorated classroom → more off-task); Tuch 2012 [gen] (low complexity + high prototypicality judged
attractive in 17–50 ms).
- Motion only on state change, never looping. Test: 10 s recording at rest shows no moving pixels
  outside the timer.
- One accent colour per screen, for the primary action. Test: count saturated hues per screen.
- Reduce Motion → fades, per the HIG.

**1.3 Working memory, and externalising at the point of performance (Barkley).** Deficit STRONG
(adults d=.54, 38 studies, Alderson 2013; 75–81% of children impaired central-executive WM, Kofler
2020 [child]). Externalisation is expert clinical theory; indirect support MODERATE (adult CBT built on
calendars/lists/cues beat active controls: Safren 2010 JAMA; Solanto 2010 AJP n=88).
- Active Goal hero shows the single concrete next step, not only a title. Test: a new user can say
  what to do next without tapping.
- Capture is a one-step dump with no required fields. Test: any screen → saved thought in ≤2 taps, or
  widget/Shortcut.
- Never make the user remember something across screens (COGA Objective 6).

**1.4 Sensory over-responsivity.** STRONG for autism; MODERATE–WEAK for ADHD. Ben-Sasson 2009
(meta); Williams 2021 (meta: decreased sound tolerance in autism ~40% current, ~60% lifetime);
Panagiotidi 2018 (n=234, ADHD traits ↔ sensitivity in every modality); Bijlenga 2017.
- Any sound is off by default or offered once with a clear choice; respects the silent switch. Test:
  fresh install makes no sound without opt-in.
- Separate switches for sound, haptics, visual celebration.

**1.5 Reading and dyslexia.** Comorbidity STRONG; typography MODERATE–WEAK. Willcutt & Pennington
2000 (25–40%); Rello 2013 (n=104 incl. dyslexia: ≥18pt helped, line spacing no effect); Zorzi 2012
[child] (extra-wide letter spacing helped); Marinus 2016, Kuster 2018 [child] (Dyslexie font no benefit
once spacing matched).
- Full Dynamic Type to AX sizes, no truncation. Test: at AX5 every primary label is readable.
- Short, literal copy, one idea per line (COGA Obj. 3). No dyslexia font.

### (2) Navigation and exit paths

**2.1 Impulsive errors, noticed less.** MODERATE. Balogh & Czobor 2016 (meta, 26 comparisons):
post-error slowing reduced in ADHD, d=.42; deficient error awareness implicated.
- Every destructive action undoable well beyond a toast (e.g. "Recently deleted"). Test: item deleted
  1 min ago is recoverable.
- Destructive swipes never auto-commit on a full swipe without undo (WCAG 3.3.4).
- Show the result of an undo (HIG: highlight it "to keep people from thinking that the action had no
  effect").

**2.2 Confirmations wear off; undo does not.** MODERATE [gen]. Anderson 2015 (fMRI): processing of a
repeated warning drops sharply after the second exposure.
- Undo for routine reversible actions; "Are you sure?" only for the irreversible (account deletion).
  Test: confirmation dialogs met in a normal day → near zero.

**2.3 Modality and working memory.** CONSENSUS. HIG Modality: "keep modal tasks simple, short, and
streamlined"; avoid "an app within your app"; "Always give people an obvious way to dismiss a modal
view"; "help people avoid data loss by getting confirmation before closing"; "Let people dismiss a
modal view before presenting another one".
- Max modal depth 1. Test: map every flow's layers.
- Dismissing a capture/journal sheet with text never silently loses it (draft, or Save/Discard). Test:
  type, swipe down, reopen → text is there.
- Each sheet's title names its task.

**2.4 Timers on UI conflict with forgiveness.** CONSENSUS. HIG Cognitive: "Minimize use of
time-boxed interface elements… Prefer dismissing views with an explicit action." WCAG 2.2.1 (A); COGA
"Avoid Data Loss and 'Timeouts'".
- An undo that lives only in a 4 s auto-dismissing toast fails this. Test: with VoiceOver on, the undo
  is still reachable.
- Celebrations never block input or require waiting.

**2.5 Resuming after interruption.** MODERATE for mechanism [gen]; no ADHD-specific interruption study
found (gap). Altmann & Trafton 2002/2004: environmental cues cut resumption time; higher WM buffers
interruptions (so larger costs predicted in ADHD — inferred).
- On return, show "you were on step 3, 12 minutes in". Test: background 30 min mid-sprint → resume
  point explicit.

**2.6 Authentication.** CONSENSUS. WCAG 3.3.8 (AA) "Don't make people solve, recall, or transcribe
something to log in"; 3.3.7 Redundant Entry (A); COGA Obj. 6.
- Paste + password managers accepted, codes autofill. SIWA and passkeys are accessibility features.

### (3) Consistency and predictability

**3.1 Uncertainty and anxiety in autistic users.** STRONG correlation; design implication inferred.
Jenkinson 2020 (meta, 10 studies, 4–24 yrs): intolerance of uncertainty ↔ anxiety r=.62.
- Nothing moves or reorders itself; life-area grid order changes only when the user changes it.
- Announce layout changes between versions rather than silently relocating things.

**3.2 Stable positions build expertise.** MODERATE [gen]. Findlater & McGrenere 2004 (n=27: static
faster than adaptive; user-controlled ≈ static); Scarr 2012 (CommandMaps: fixed positions → spatial
memory, skip search).
- Tab items and capture button keep fixed positions in every state.
- User-controlled settings over automatic rearrangement. Test: does any list/grid sort itself by usage
  or time without user action?

**3.3 Platform conventions vs custom UI.** CONSENSUS + MODERATE [gen]. HIG Cognitive: "Prefer system
gestures and behaviors people are already familiar with over creating custom gestures." HIG Tab bars:
"easier to navigate among fewer tabs"; "to support navigation, not to provide actions"; "If you hide
the tab bar, people can forget which area of the app they're in"; "Don't disable or hide tab bar
buttons… makes your app's interface appear unstable". COGA "Use a Familiar Hierarchy and Design",
"Use a Consistent Visual Design". Counterpoint: Grudin 1989 — consistency with the user's task beats
consistency for its own sake (expert argument).
- A custom tab bar must reproduce every system behaviour users rely on: persistent visibility, re-tap
  to scroll-top/pop-root, VoiceOver tab traits, Dynamic Type. Test each against the system bar.
- A tab slot that acts rather than navigates breaks "navigation, not actions" — be able to say why.
- >5 items on the narrowest iPhone at the largest text size is a test case.
- Token audit: one meaning per colour and per gesture app-wide.

**3.4 Consistency vs habituation.** MODERATE [gen]. Anderson 2015: polymorphic warnings resist
habituation. → Keep navigation and controls identical everywhere; vary only content that must be
noticed (e.g. nudge wording). Never vary controls.

**3.5 Heterogeneity means personalisation.** STRONG heterogeneity; COGA Obj. 8.
- Per-feature switches: streaks, celebrations, sound, reminders, badge counts.
- Defaults chosen for the most sensitive user, because setup burden drives abandonment (Kidman 2024).

### (4) Touch and ergonomics

**4.1 Motor co-occurrence.** STRONG [child]; MODERATE adults (extrapolated). Kaiser 2015 (30–50% of
children with ADHD, not fully resolved by medication); Kadesjö & Gillberg (~50% ADHD–DCD overlap); DCD
persists into adulthood in 50–70%, adult prevalence ~5–6%; Fournier 2010 (autism motor SMD=1.20).
- Targets ≥44×44pt with spacing (HIG: ~12pt padding bezelled, ~24pt unbezelled).
- Highest-frequency actions (complete, start sprint, capture): consider ~55pt+. Parhi 2006: 9.2 mm
  sufficient for one-handed discrete thumb taps; 44pt ≈ 7 mm on current iPhones (agent's conversion).

**4.2 Gestures.** CONSENSUS; WEAK empirical. Trewin 2013 (dexterity demands of accessibility features
made them unusable for many); HIG "Offer alternatives to gestures… if you use a swipe gesture to
dismiss a view, also make a button available"; WCAG 2.5.1 (A), 2.5.7 (AA), 2.5.2 (A).
- Every task-card swipe action has a visible tap equivalent. Test: complete/snooze/delete reachable
  with Voice Control, no swipe.
- Drag-to-reorder has Move up/down alternatives.
- Long-press menus duplicate visible actions.
- Deliberate swipe thresholds + undo. Test: an accidental partial swipe while scrolling never commits.

**4.3 One-handed reach.** MODERATE [gen], dated. Hoober 2013 (~1,333 obs, 49% one-handed, 2013-size
phones); Bergstrom-Lehtovirta & Oulasvirta 2014 (thumb functional-area model).
- Primary and destructive-undo actions in the bottom half; no critical control only in a top corner.
  Test: every primary action reachable one-handed on a Pro Max.

### (5) Cognitive friction and motivation

**5.1 Initiation, time and remembering.** STRONG timing deficits; MODERATE prospective memory; WEAK
procrastination. Marx 2021 JAACAP (55 studies, mean ages 8–42: discrimination/reproduction medium,
estimation small–medium, production small; no publication bias); Zheng 2022 [child]; Talbot & Kerns
[child] (time-based PM consistent, event-based mixed); Altgassen 2019 (29 vs 24: everyday PM mediated
ADHD→procrastination); Niermann & Scheres 2014 (n=54: procrastination tracks inattention).
- Make time visible (shrinking shape as well as digits; elapsed time on tasks and routines). Test: time
  left readable at a glance with no numerals.
- Prefer event/location triggers over clock reminders — but Ludford 2006 (PlaceMail): plain geofence
  radius insufficient, delivery depends on movement. Test trigger timing in the field.
- "Just start" path: 5-min sprint from a task in one tap.

**5.2 Delay, reward and reinforcement schedules.** Delay discounting MODERATE–STRONG; blunted ventral
striatal anticipation MODERATE; DTD theory WEAK, its behavioural predictions MODERATE [child]. Marx
2021 J Atten Disord (37 comparisons, n=3,763; real rewards nearly doubled the odds); Sonuga-Barke 2003;
Plichta & Scheres 2014 (d=.48–.58, anticipation-specific); Tripp & Wickens 2008; Aase & Sagvolden 2006
[child] (infrequent reinforcers → variable responding); Luman 2005 [child] (not more sensitive to
negative outcomes).
- Immediate, certain feedback on every completion; no random/loot rewards. Test: identical actions →
  identical feedback.
- Show in-session progress, not weekly totals only.

**5.3 Celebrations, gamification, crowding-out.** MODERATE [gen]; ADHD gamification evidence low
quality, mostly [child]. Kao 2020 (four juice levels: medium and high beat none AND extreme); Deci,
Koestner & Ryan 1999 (128 studies: expected tangible rewards undermine intrinsic motivation, d −.28 to
−.40; informational verbal feedback enhances it in adults; contested by Cameron & Pierce); Hamari 2014;
Koivisto & Hamari 2014 (novelty wear-off); Gabarron 2025 (26 reviews, low quality, adverse effects in 8
of 26 incl. addictive use).
- Scale celebration to achievement size: full-screen for rare milestones; routine completions get a
  tick + haptic. Test: full-screen celebrations per day for a heavy user → low single digits.
- Informational copy ("3 sprints done, 75 minutes of focus"), not points.
- One-tap global off; a celebration that ignores Reduce Motion should be a named, user-overridable
  exception.

**5.4 Streaks, overdue states, shame.** Emotional dysregulation STRONG; RSD term FOLK;
criticism/self-compassion MODERATE; streak effects MODERATE [gen], no ADHD evidence. Beheshti 2020
(adults g=1.17, lability 1.20, prevalence 30–70%); Shaw 2014; RSD (Dodson) — only a 2024 case series,
qualitative work (Rowney-Smith, PLOS One; Sandland 2025 n=7), a college survey (Müller 2024); Beaton
2020/2022 (lower self-compassion ↔ perceived criticism); Wohl 2010 (n=119, self-forgiveness →
less later procrastination); Silverman & Barasch 2023 (7 studies: showing a broken streak lowers later
engagement vs intact; amplified by self-blame, attenuated when repairable); Dai 2014 (fresh start).
- No accumulating red "overdue" counts (HIG: "Reserve badges for critical information"). Overdue →
  neutral "Still open". Test: open after 7 days away; count red elements and failure words.
- Streaks: opt-in, repair/grace days, framed as "days active this week" not an unbroken chain.
- Return-after-lapse copy welcomes and offers a fresh start; never tallies what was missed.

**5.5 Friction as a tool.** Self-nudge friction MODERATE [gen]; implementation intentions MODERATE
general, WEAK adult ADHD; hassle factors MODERATE–STRONG [gen]. Grüning 2023 PNAS ("one sec": 36% of
target-app opens dismissed, 37% fewer attempts; the dismiss option most effective); Sheeran 2024 (642
tests, d=.27–.66, substantial publication bias); Toli 2016 (clinical/analogue d+=.99, k=28);
Breitwieser 2026 [child] (g=.31, stronger in ADHD subsamples); Gawrilow & Gollwitzer 2008 [child];
Bettinger 2012 QJE (FAFSA friction removal raised enrolment).
- Asymmetric friction: zero added steps on wanted paths (capture, start, complete); deliberate friction
  only on paths the user asked to be protected from.
- Routines and nudges as if-then plans. Test: every routine stores a trigger + a first action.

**5.6 Notifications and reminders.** MODERATE [gen]; no ADHD habituation study found. Stothart 2015
(a notification alone disrupts about as much as phone use); Kushlev 2016 (n=221: notifications on →
more self-reported inattention/hyperactivity); Fitz 2019 (batching 3×/day → more attentive, productive,
in control); Ancker 2017 (each +5 pts repeated alerts → −10% acceptance); ADHD ↔ problematic internet /
social-media use (meta); Wilson 2001 RCT (NeuroPage pager reminders improved everyday memory after
brain injury).
- One notification per trigger, no repeats, a daily cap. Test: max notifications per day.
- Digest/batching mode. Vary reminder wording, not controls. No guilt re-engagement pushes.

**5.7 Hyperfocus, breaks, body doubling, accountability.** Hyperfocus WEAK/contested; break structure
WEAK [gen, students]; body doubling FOLK/WEAK; coaching WEAK. Hupfeld 2019 (self-report n=251 + 372
replication); Groen 2020 (no frequency difference vs controls); Ashinoff & Abu-Akel 2021 (construct
poorly defined); Biwer 2023 (fixed Pomodoro breaks → less fatigue, equal completion); Eagle 2023/2024
(n=220 survey); Bond & Titus 1983 (presence of others 0.3–3% variance, impairs complex-task accuracy);
Ahmann 2018.
- Sprints end with a soft "keep going?" and never force-stop someone in flow.
- Don't market body doubling / accountability as evidence-based.

**5.8 Efficacy and abandonment.** Abandonment STRONG; efficacy WEAK–MODERATE. Baumel 2019 (93 apps:
median 15-day retention 3.9%, 30-day 3.3%); Kidman 2024 (18 studies, n=525,824: 70% stop within 100
days; six reason groups incl. poor UX, time cost, changing needs); Păsărelu 2020 (109 ADHD apps, none
with efficacy evidence); Antshel, McBride & Knouse (n=154 adults, 8 wk CBT-informed app beat waitlist,
η²=.15 — waitlist inflates); Selaskowski 2022 (n=60); Spiel 2022 (deficit framing, rarely co-designed).
- Design the return after 2 weeks away as a first-class flow: no backlog wall, one suggested action.
- Recruit ND adults for usability testing before launch.

---

## 3. Tensions and trade-offs

1. **Minimal UI vs point-of-performance externalising.** Settle per element: needed for the current
   task, or peripheral? Hiding the next step behind a tap for cleanliness violates externalisation.
2. **Minimalism vs load theory.** A richer focal task reduces distraction (Forster 2014). Quiet
   periphery, engaging focal content.
3. **Celebrations: motivation vs sensory load vs crowding-out.** "None" is also wrong (Kao); the chime
   is the specific sensory exposure; novelty fades. Resolution: small and informational by default, big
   only when rare, separate switches.
4. **Streaks: engagement vs shame.** Intact streaks lift engagement [gen], broken ones deter. Preliminary
   evidence of *reduced* loss aversion in adult ADHD (Tanaka 2018, small fMRI) → loss-framed streaks may
   motivate less while the affective cost stays high.
5. **Friction to deter vs friction that blocks starting.** Any added step on a desired path will be
   abandoned. Friction must be asymmetric and user-chosen.
6. **Reminders are needed but decay.** Varying wording resists habituation but conflicts with
   predictability for autistic users.
7. **Predictability vs novelty.** AuDHD users sit on both sides. Vary content, never structure.
8. **Protecting hyperfocus vs structured breaks.** Weak evidence both ways → user chooses.
9. **Undo toasts: forgiveness vs time-boxed UI.** A persistent undo location solves both.
10. **Personalisation vs setup burden.** Sensitive-safe defaults + progressive disclosure.
11. **Body doubling vs social evaluation.** Ambient presence safer than performance-style
    accountability.

---

## 4. Commonly repeated claims the evidence does not support (or only weakly)

- "ADHD brains crave dopamine, so use variable rewards." Anticipation is blunted; infrequent
  reinforcement worsens performance [child]; variable-ratio aligns with problematic-use risk.
- "Decision fatigue / ego depletion; choice paralysis." Ego depletion failed multi-lab replication
  (Hagger 2016 d=.04; Vohs 2021 d=.06); judges study confounded; choice overload averages ~0
  (Scheibehenne 2010), moderated by complexity (Chernev 2015); no ADHD choice-overload study. Fewer
  options is still sensible — for working-memory reasons.
- "RSD is a core ADHD symptom." FOLK. Emotion dysregulation IS supported.
- "Hyperfocus is an ADHD hallmark." Contested (Groen 2020 null).
- "Body doubling works." Survey + lived experience; no controlled trial.
- "Dyslexia fonts help." Not once spacing is matched.
- "Minimal UI is always better for ADHD." Only for irrelevant salience.
- "Streaks motivate ADHD users." No ADHD evidence; broken streaks demotivate in general.
- "Gamification solves engagement." Novelty decays; adverse effects in ~30% of reviews.
- "ADHD apps are evidence-based." 109 apps, no efficacy evidence (2020).
- "Pomodoro is proven for ADHD." Students only.
- "More reminders help." Habituation and notification costs point the other way.
- Counter-example, supported despite being folk: "time blindness" (Marx 2021).

---

## 5. Addendum — the "Executive Dysfunction & Paralysis Master List", graded item by item

*The agent reports receiving this list from E after the main report and grading it against the same
key.*

**Headline:** the list describes real mechanisms correctly but wraps several in community labels with
no research base ("waiting mode", "object permanence", "dopamine deficiency deficit", "activation
freeze", "comfort anchoring"). One item points at the wrong mechanism: bed-lock is better explained by
a delayed body clock plus sleep inertia than "waking with low dopamine" — which also exposes a gap in
the main report: **sleep and circadian timing.**

**Already covered (grade only):** activation freeze ("activation" is Brown's clinical model;
ADHD–procrastination WEAK–MODERATE) → one tap from any task to "start 5 minutes"; choice/decision
paralysis FOLK as ADHD-specific; working-memory overload STRONG; vulnerability to friction MODERATE;
shame spiral (dysregulation STRONG, criticism/self-compassion MODERATE, self-forgiveness helps); time
blindness STRONG; sensory overwhelm STRONG autism / MODERATE–WEAK ADHD.

1. **"Object permanence" / out of sight, out of mind.** Label FOLK and a misnomer (an infant milestone
   adults with ADHD have). Real mechanism — WM/PM failure without an external cue — STRONG–MODERATE.
   → Put commitments where the eye already is: Lock/Home Screen widgets, Live Activities. Test: today's
   first task visible without opening the app. Inbox count visible but neutral, not red.
2. **"Waiting mode."** FOLK term; rests on STRONG–MODERATE time-perception and time-based PM deficits;
   2025 VR study [child]: less strategic clock-watching. → Let the app watch the clock ("leave by
   14:20" + guaranteed alert); offer work sized to the gap ("You have 50 min. A 25-min sprint ends 25
   min before you leave"). Test: appointment 2 h away → Home shows free time and a safe stop time.
3. **Transition friction.** ADHD set-shifting d=.35 (smallest domain) → WEAK–MODERATE driver; autism
   IU↔anxiety STRONG (r=.62). → Heads-up before a sprint/routine ends ("5 min left"); clear "next up"
   at every end state; no abrupt screen changes. Test: no flow ends on an empty screen.
4. **All-or-nothing trap.** MODERATE [child, gen] — Bandura & Schunk 1981 (near-term subgoals →
   mastery, self-efficacy, interest; one distant goal ≈ no goal); adult CBT teaches step-breaking
   (component untested alone). → Active Goal shows the single next step; breakdown available, never
   required before starting. Test: a task can be started without being broken down.
5. **Perfectionism stalling.** MODERATE [gen], no ADHD-specific evidence. Sirois, Molnar & Hirsch 2017:
   perfectionistic concerns ↔ procrastination r=.23 (k=43, N≈10,000); strivings r=−.22. → Rough-first
   everywhere: fragments accepted, no required fields, everything editable later; "rough is fine" copy.
   Test: a one-word capture/journal entry saves with no validation prompt.
6. **Physical discomfort with boring tasks.** WEAK–MODERATE (Malkovsky 2012: agitated boredom profile ↔
   more adult ADHD symptoms, poorer sustained attention); fits delay aversion. Temptation bundling
   (Milkman 2014, from memory, not re-checked) raised gym attendance, faded after a break. → Let short
   sprints pair with a user-chosen treat/playlist; visible in-sprint progress; don't lengthen defaults
   for boring tasks.
7. **Delayed body clock and bed-lock (the gap).** MODERATE, consistent. Coogan & McGowan 2017 (62
   studies, 4,462 patients: eveningness, later melatonin/sleep onset); Bijlenga 2019 (delayed sleep
   phase est. 73–78%, small samples); Van Veen 2010 (31/40 adults sleep-onset insomnia, delayed
   melatonin). → Never assume a standard morning; anchor morning routines to events (alarm dismissed,
   first unlock, leaving home), not clock times; no "you're late" framing. Test: an "after I wake up"
   routine fires on the wake event, not at 07:00.
8. **Waking "executive amnesia" / post-waking freeze.** ADHD framing FOLK; sleep inertia STRONG [gen]
   (most clears in 15–30 min, full recovery up to an hour; worse after sleep loss and at the wrong
   circadian point — Hilditch & McHill 2019; Tassi & Muzet 2000). → The first morning surface shows
   today's one first step, no decisions, no recall. Test: within 30 s of first unlock, what to do first
   is visible without typing or choosing.
9. **"Dopamine deficiency deficit" (waking low).** FOLK as stated. Dopamine involvement in adult ADHD
   supported (Volkow 2009 JAMA), but no morning-specific trough shown. → Don't build copy on "morning
   dopamine hits"; design for grogginess and a late clock.
10. **Comfort anchoring (in-bed scrolling).** Bedtime procrastination MODERATE [gen] (Kroese 2014;
    original ego-depletion mechanism now unsettled); ADHD ↔ problematic smartphone use MODERATE; ADHD ↔
    bedtime procrastination WEAK (one small study). → The app never becomes the in-bed scroll (no
    infinite feeds, lists end); morning/evening nudges one-shot; optional wind-down routine. Test:
    nothing scrolls indefinitely; no notification between bedtime and wake event unless user-set.

---

## 6. Sources

**EF, WM, reward, time:** Barkley 1997 https://pubmed.ncbi.nlm.nih.gov/9276836/ · Barkley fact sheet
https://www.russellbarkley.org/factsheets/ADHD_EF_and_SR.pdf · Alderson 2013
https://pubmed.ncbi.nlm.nih.gov/23688211/ · Pievsky & McGrath 2018
https://academic.oup.com/acn/article/33/2/143/3926568 · Willcutt 2005
https://pubmed.ncbi.nlm.nih.gov/15950006/ · Kofler 2020 https://pmc.ncbi.nlm.nih.gov/articles/PMC7483636/
· Marx 2021 (discounting) https://journals.sagepub.com/doi/10.1177/1087054718772138 · Marx 2021 (timing)
https://www.sciencedirect.com/science/article/abs/pii/S0890856721020451 · Zheng 2022
https://journals.sagepub.com/doi/abs/10.1177/1087054720978557 · Plichta & Scheres 2014
https://pubmed.ncbi.nlm.nih.gov/23928090/ · Tripp & Wickens 2008
https://acamh.onlinelibrary.wiley.com/doi/10.1111/j.1469-7610.2007.01851.x · Aase & Sagvolden 2006
https://pubmed.ncbi.nlm.nih.gov/16671929/ · Luman 2005 https://pubmed.ncbi.nlm.nih.gov/15642646/ ·
Sonuga-Barke 2003, Neurosci Biobehav Rev 27:593–604 · Tanaka 2018
https://www.nature.com/articles/s41598-018-24944-5 · Dekkers 2021
https://journals.sagepub.com/doi/10.1177/1087054718815572

**Initiation, PM, planning:** Niermann & Scheres 2014 https://pubmed.ncbi.nlm.nih.gov/24992694/ ·
Altgassen 2019 https://pubmed.ncbi.nlm.nih.gov/30927231/ · Talbot & Kerns (via)
https://www.mdpi.com/1660-4601/18/11/5849 · Gawrilow & Gollwitzer 2008
https://link.springer.com/article/10.1007/s10608-007-9150-1 · Sheeran 2024
https://www.tandfonline.com/doi/abs/10.1080/10463283.2024.2334563 · Toli 2016
https://pubmed.ncbi.nlm.nih.gov/25965276/ · Breitwieser 2026 https://pubmed.ncbi.nlm.nih.gov/41784001/ ·
Safren 2010 https://pubmed.ncbi.nlm.nih.gov/20736471/ · Solanto 2010
https://www.medscape.com/viewarticle/718932 · Ludford 2006 https://dl.acm.org/doi/10.1145/1124772.1124903
· Biwer 2023 https://pubmed.ncbi.nlm.nih.gov/36859717/

**Emotion, shame, hyperfocus:** Shaw 2014 https://psychiatryonline.org/doi/10.1176/appi.ajp.2013.13070966 ·
Beheshti 2020 https://pmc.ncbi.nlm.nih.gov/articles/PMC7069054/ · RSD qualitative
https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0314669 · Sandland 2025
https://journals.sagepub.com/doi/10.1177/27546330251394516 · Müller 2024
https://journals.sagepub.com/doi/10.1177/09388982241271511 · Beaton 2020
https://eprints.whiterose.ac.uk/id/eprint/165039/ · Beaton 2022
https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0263366 · Wohl 2010
https://www.sciencedirect.com/science/article/abs/pii/S0191886910000474 · Hupfeld 2019
https://pubmed.ncbi.nlm.nih.gov/30267329/ · Groen 2020 https://pubmed.ncbi.nlm.nih.gov/33126147/ ·
Ashinoff & Abu-Akel 2021 https://pubmed.ncbi.nlm.nih.gov/31541305/

**Attention, clutter, sensory:** Forster 2014 https://pubmed.ncbi.nlm.nih.gov/24219607/ · Zhang 2024
https://pubmed.ncbi.nlm.nih.gov/40778335/ · Mullane & Klein 2008 https://pubmed.ncbi.nlm.nih.gov/17712165/
· Kasatskii 2023 https://arxiv.org/abs/2302.06376 · Abrams & Christ 2003
https://pubmed.ncbi.nlm.nih.gov/12930472/ · Burke 2005 http://ix.cs.uoregon.edu/~hornof/downloads/TOCHI04.pdf
· Fisher 2014 https://journals.sagepub.com/doi/abs/10.1177/0956797614533801 · Tuch 2012
https://research.google/pubs/the-role-of-visual-complexity-and-prototypicality-regarding-first-impression-of-websites-working-towards-understanding-aesthetic-judgments/
· Ben-Sasson 2009 https://pubmed.ncbi.nlm.nih.gov/18512135/ · Williams 2021
https://pubmed.ncbi.nlm.nih.gov/33577214/ · Panagiotidi 2018 https://pubmed.ncbi.nlm.nih.gov/29121555/ ·
Jenkinson 2020 https://pubmed.ncbi.nlm.nih.gov/32564625/ · Rong 2021
https://www.sciencedirect.com/science/article/abs/pii/S1750946721000349

**Reading and motor:** Willcutt & Pennington 2000 https://journals.sagepub.com/doi/10.1177/002221940003300206
· Zorzi 2012 https://www.pnas.org/doi/10.1073/pnas.1205566109 · Marinus 2016
https://onlinelibrary.wiley.com/doi/10.1002/dys.1527 · Kuster 2018 https://pubmed.ncbi.nlm.nih.gov/30094714/
· Rello 2013 https://pielot.org/pubs/Rello2013-W4A-SizeMatters.pdf · Kaiser 2015
https://research.rug.nl/en/publications/what-is-the-evidence-of-impaired-motor-skills-and-motor-control-a
· DCD adults https://www.sciencedirect.com/science/article/pii/S2773021223000469 · Fournier 2010
https://link.springer.com/article/10.1007/s10803-010-0981-3 · Trewin 2013
https://dl.acm.org/doi/10.1145/2513383.2513446 · Parhi 2006
https://www.microsoft.com/en-us/research/wp-content/uploads/2006/01/parhi-mobileHCI06.pdf · Hoober 2013
https://www.uxmatters.com/mt/archives/2013/02/how-do-users-really-hold-mobile-devices.php ·
Bergstrom-Lehtovirta & Oulasvirta 2014 https://old.hiit.fi/thumb_functional_area.html

**Errors, habituation, interruption, consistency:** Balogh & Czobor 2016
https://pubmed.ncbi.nlm.nih.gov/24695437/ · Anderson 2015 https://dl.acm.org/doi/10.1145/2702123.2702322 ·
Ancker 2017 https://pmc.ncbi.nlm.nih.gov/articles/PMC5387195/ · Altmann & Trafton 2004
https://www.interruptions.net/literature/Altmann-CogSci04.pdf · Findlater & McGrenere 2004
https://dl.acm.org/doi/10.1145/985692.985704 · Scarr 2012 https://dl.acm.org/doi/10.1145/2207676.2207713 ·
Grudin 1989 https://dl.acm.org/doi/10.1145/67933.67934

**Motivation and friction:** Deci, Koestner & Ryan 1999
https://home.ubalt.edu/tmitch/642/articles%20syllabus/Deci%20Koestner%20Ryan%20meta%20IM%20psy%20bull%2099.pdf
· Silverman & Barasch 2023 https://academic.oup.com/jcr/article-abstract/49/6/1095/6623414 · Dai 2014
https://pubsonline.informs.org/doi/10.1287/mnsc.2014.1901 · Kao 2020
https://www.sciencedirect.com/science/article/pii/S1875952118300879 · Hicks 2019
https://dl.acm.org/doi/abs/10.1145/3311350.3347171 · Hamari 2014 https://dl.acm.org/doi/10.1109/HICSS.2014.377
· Koivisto & Hamari 2014 https://www.sciencedirect.com/science/article/abs/pii/S0747563214001289 · Grüning
2023 https://pubmed.ncbi.nlm.nih.gov/36795756/ · Bettinger 2012, QJE 127(3) · Hagger 2016
https://pubmed.ncbi.nlm.nih.gov/27474142/ · Vohs 2021 https://pmc.ncbi.nlm.nih.gov/articles/PMC12422598/ ·
Scheibehenne 2010 https://scheibehenne.com/ScheibehenneGreifenederTodd2010.pdf · Chernev 2015
https://chernev.com/wp-content/uploads/2017/02/ChoiceOverload_JCP_2015.pdf · Weinshall-Margel & Shapard 2011
https://www.pnas.org/doi/10.1073/pnas.1110910108 · Bond & Titus 1983
https://www.semanticscholar.org/paper/Social-facilitation:-a-meta-analysis-of-241-Bond-Titus/b0c7e392f24446279a65f30f8fb0d25e6e4d1ce7
· Eagle 2023 https://dl.acm.org/doi/abs/10.1145/3597638.3614486 · Eagle 2024
https://leyabreanna.com/papers/body_double_taccess.pdf · Ahmann 2018
https://files.eric.ed.gov/fulltext/EJ1182373.pdf

**Notifications and apps:** Stothart 2015 https://pubmed.ncbi.nlm.nih.gov/26121498/ · Kushlev 2016
https://dl.acm.org/doi/10.1145/2858036.2858359 · Fitz 2019
https://www.sciencedirect.com/science/article/abs/pii/S0747563219302596 · ADHD ↔ internet addiction
https://bmcpsychiatry.biomedcentral.com/articles/10.1186/s12888-017-1408-x · Baumel 2019
https://www.jmir.org/2019/9/e14567/ · Kidman 2024 https://www.jmir.org/2024/1/e56897 · Păsărelu 2020
https://pubmed.ncbi.nlm.nih.gov/32283479/ · Antshel, McBride & Knouse
https://journals.sagepub.com/doi/abs/10.1177/10870547251384462 · Selaskowski 2022
https://pubmed.ncbi.nlm.nih.gov/36041353/ · Gabarron 2025
https://bmcpsychiatry.biomedcentral.com/articles/10.1186/s12888-025-06825-0 · Spiel 2022
https://dl.acm.org/doi/10.1145/3491102.3517592

**Addendum:** Coogan & McGowan 2017 https://pubmed.ncbi.nlm.nih.gov/28064405/ · Bijlenga 2019
https://pubmed.ncbi.nlm.nih.gov/30927228/ · Van Veen 2010 https://pubmed.ncbi.nlm.nih.gov/20163790/ ·
Hilditch & McHill 2019 https://www.dovepress.com/sleep-inertia-current-insights-peer-reviewed-fulltext-article-NSS
· Tassi & Muzet 2000, Sleep Med Rev · Malkovsky 2012 https://link.springer.com/article/10.1007/s00221-012-3147-z
· Sirois, Molnar & Hirsch 2017 https://eprints.whiterose.ac.uk/id/eprint/112533/ · Bandura & Schunk 1981
https://www.semanticscholar.org/paper/Cultivating-competence,-self-efficacy,-and-interest-Bandura-Schunk/b1e4d476c857333b9a0afdb1428eda27f6d26940
· Kroese 2014 https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2014.00611/full ·
object-permanence explainer https://www.getinflow.io/post/object-permanence-constancy-adhd-symptom ·
waiting mode https://www.healthline.com/health/adhd/adhd-waiting-mode · VR time-based PM [child]
https://www.nature.com/articles/s41598-025-08944-w · Volkow 2009, JAMA 302(10):1084–1091 · Milkman,
Minson & Volpp 2014, Management Science (from memory, not re-checked)

**Standards / vendor:** W3C COGA https://www.w3.org/TR/coga-usable/ · WCAG 2.2
https://www.w3.org/TR/WCAG22/ · Apple HIG Accessibility
https://developer.apple.com/design/human-interface-guidelines/accessibility · Modality
https://developer.apple.com/design/human-interface-guidelines/modality · Tab bars
https://developer.apple.com/design/human-interface-guidelines/tab-bars · Undo and redo
https://developer.apple.com/design/human-interface-guidelines/undo-and-redo · Assistive Access
https://developer.apple.com/documentation/accessibility/assistive-access

**Could not retrieve:** ASSETS 2025 EEG body-doubling study (HTTP 403).

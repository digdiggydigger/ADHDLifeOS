# Routines — the design record (scoping session, 2026-09-03)

*Written by the scoping session that ran off `main` @ `218d289`. This is the design record and
the why — the sibling of `SESSION-OPENER-tools-tab.md` for the Routines arc. The scoping opener
that produced it is `START-HERE-routines-scoping.md`; read that first in a fresh session.*

**Status: SETTLED — E answered all four questions on 2026-09-03, taking every recommendation.**
See "E's answers" at the bottom. The BUILD is still not authorised — E has not green-lit a
branch; a build session needs its own go-ahead and (per house pattern) a build plan with
FEATURE blocks E authorises into `TODO-CLAUDE-CODE.md`.

**The canvas E judges from: https://claude.ai/code/artifact/3a932048-d940-4469-bc91-904d2906034f**
(working files in `../routines-concepts/`, regenerate with `python3 gen.py` and re-seed — same
palette and mechanism as `../tabbar-concepts/`). Six boards: Before (today's notification spray,
shipped copy verbatim), After (one notification), **Main = the routine screen**, HomeCard (the
way back in), OptionA (place-scoped), OptionB (first-class). Every board has a Dark tweak.

## What Routines is

E's example, verbatim (2026-09-02): **"Open Snapchat at the gym > Open gym app + Open Spotify
playlist called 'Gym Music'"** — a location trigger firing an **ordered routine of steps**. E's
declared top-priority feature. The app-directory's 152 entries are the vocabulary of routine
steps (E's correction — the reason the directory was not culled).

**E's requirements file `Es doc dump/adhd-routines-reqs.txt` governs the design** — five
directives: zero-friction initiation, working-memory externalization, undo-over-confirm,
aggressive whitespace / unambiguous affordances, time-blindness mitigation. The mapping is at
the bottom of this file.

## The ceiling (do not re-litigate)

**iOS cannot chain app-opens.** A backgrounded app cannot launch another app; each open needs
its own user tap, and each tap opens exactly one. N app-opens = N taps, always. The design makes
the taps visible as an ordered checklist instead of pretending to remove them. Related: the
first `UIApplication.open` must stay SYNCHRONOUS on the notification-response callback
(the `0c65ca5` attribution lesson) — but note the routine screen largely **sidesteps** that
fragility: steps are opened by foreground button taps, which carry their own attribution.

## Verified code facts the design stands on (tree @ `218d289`)

- `Place.actions` is `[PlaceAction]` (`PlaceModels.swift:56`), encoded as an **embedded array
  on the `places` doc** (`CodingKeys` :122, encode :161). **Firestore preserves array order and
  nothing in the app sorts actions** (grep-verified) — so step order = array order, already
  persisted. **Ordering needs NO schema change and NO rules republish.** The opener's "adding
  ordering is a schema change" was wrong.
- The editor (`PlaceActionsSection.swift`, 141 lines) lists ALL actions in one `ForEach`
  (not grouped by direction), with `.onDelete`. **No `.onMove` anywhere in Places** — adding it
  is a straight array move, no index mapping. Nearest precedent: Home's arrange-mode `List`
  (`HomeView.swift:347`).
- `PlaceActionPlan.split` (`PlaceActionExecution.swift:23`) divides a crossing's actions into
  autoRun (`journalLine`, `createCapture` — run silently) and external (everything else — today
  **one notification EACH**, the loop at `PlaceTriggerEventHandler.swift:95`). The routine
  replaces that loop. The file's own comment ("one notification EACH rather than one shared
  nudge", :16-17) states the constraint being deliberately inverted — a routine screen is what
  makes one shared notification workable, because the tap opens a chooser, not one action.
- `AtPlaceSnapshot.PlaceEntry` **already carries `actions`** (`ArrivalNudgeContent.swift:31`) —
  the routine screen can be built from the snapshot on a background wake, no network needed.
- The crossing nudge (`ArrivalNudgeContent`) is a separate, test-pinned concern: custom
  message + open-task counts, stable identifier per place+direction (replaces, never stacks),
  empty-never-fires.
- Tap routing: notifications carry their payload as JSON in userInfo (cold-launch-safe);
  `PlaceActionNotificationRouter` uses the pending-door replay pattern; RootView drains doors
  after the tabs mount. **The `placeAction-` identifier prefix is GREEDY** (claims anything
  prefixed, even broken payloads — pinned by test), so a routine notification needs its **own
  prefix** (e.g. `placeRoutine-`) and its own branch in `ADHD_LifeOSApp.swift`.
- **`extraPayload` preservation covers flat scalars ONLY** (`PlaceActionValue` is
  string/number/bool; nested maps are dropped by `capturePayload`, doc at
  `PlaceActionModels.swift:249-251`). **A routine cannot be a new `PlaceAction` kind carrying a
  nested step list** — an old build's re-save would strip it. First-class routines therefore
  need a new top-level shape: a new `routines` collection (+ rules publish by E) or a new
  hand-coded field on the `places` doc.
- `ToolsCatalog` holds two cards, doc comment says sparse-for-Routines, and
  `ToolsCatalogTests.testThePageStaysSparse` pins `count == 2` with a failure message that
  names this exact arrival. A third card is a 4-part change + that test + both doc comments.
- Places UI is `@available(iOS 17.0, *)` against the app's 16.0 floor — a routine screen built
  on place actions inherits the same gate; mirror the `placesSupported` pattern.

## The proposal (the shape on the canvas)

**One notification per qualifying crossing → the routine screen.**

1. **Notification**: when a crossing has **2+ tap-steps**, post ONE notification (own
   identifier prefix, routine payload in userInfo, stable per place+direction like the nudge).
   It **absorbs** the place's custom message and the auto-run report, so the crossing
   interrupts once. A crossing with exactly **one** tap-step keeps today's direct one-tap
   notification (routing one step through a screen adds a tap for nothing). Places with no
   routine are untouched. (This is Q2 — E may choose differently.)
2. **The routine screen** (full-screen, arrives via the door-drain pattern): sticky header with
   place + custom message + relative arrival time; visual progress bar + "2 of 4 done";
   autoRun steps pre-ticked ("Ran by itself when you arrived"); ONE dominant current-step card
   with a 48pt accent button; upcoming steps dimmed below; **Undo on a ticked step, Skip on the
   current one — no confirmation dialogs anywhere**. Each tap opens one app; returning
   mid-routine is the normal path and the screen holds your place.
3. **The way back in**: while a routine is live, Today carries a card ("At Gym · routine live ·
   2 steps left · Continue"). A swiped-away notification is otherwise a dead end — the
   dead-shared-component lesson applied at design level. Card disappears when the routine ends.
4. **Lifetime**: recommended — a routine stays live until you **leave the place** (the
   departure crossing ends it), with an end-of-day sweep as the safety net for a missed exit.
   (Q3 — E may choose differently.)

**Cheap wins to note:** `startSprint` as a routine step improves (started from a foreground
tap, so ActivityKit just works); step opens are foreground button taps, so the `0c65ca5`
attribution fragility mostly disappears; completion is done-on-tap (tap the step = it ran —
no verification problem iOS won't let us solve anyway).

**Explicit v2 non-goals:** a Live Activity for a running routine; non-location triggers
(time-of-day, manual-only routines beyond Option B's "Run now"); any auto-advance mechanism.

## The fork (Q1 — the decision that shapes everything else)

The routine screen, notification, and Home card are IDENTICAL in both options. A and B differ
only in where steps live and what edits them.

- **Option A — the place's steps, ordered** (recommended). The routine IS `plan.external` in
  array order. Editor = the existing actions editor + drag handles + "runs in this order"
  footer. No new data, no new screens, no rules publish. Ships soonest. Trade: no routine
  apart from a place, no reuse across places. **A grows into B later** — the screen never
  knows where its steps came from.
- **Option B — first-class routines.** Named, reusable, runnable by hand ("Run now"), lands on
  Tools (kept sparse for exactly this). Trade: new collection + rules publish (E's manual
  step), a second editor, and the "do the gym's steps live on the place or the routine?"
  ambiguity to settle.

## The four questions put to E (2026-09-03)

1. **Model**: A place-scoped (rec) / B first-class / build the shared screen first, decide after.
2. **Notification threshold**: replace per-action notifications only at 2+ tap-steps (rec) /
   always when a routine step exists / per-place opt-in.
3. **Lifetime**: until departure + end-of-day sweep (rec) / fixed window / until finished or
   manually dismissed.
4. **autoRun steps on the list**: shown pre-ticked (rec — instant progress, truth about what
   ran) / hidden (list only what you must do).

## Round 3 — field calibration (2026-09-03, E's answers to the understanding-deepening round)

**Corrections to the record:**
- **The gym trio was never a real routine.** E: "fyi: I never explicitly stated that I have an
  existing routine that consists of 'gym → Snapchat + gym app + Gym Music'" — it was E's
  illustration of the SHAPE, and E confirmed the feature targets a wide variety of use cases.
  Keep it as the canonical worked example; stop treating it as E's lived behaviour.
- **E's real week-one inventory: home arrival, a morning TIME-routine, and a LEAVING-somewhere
  routine.** Consequences: departure routines are REAL (not hypothetical); and the morning
  routine cannot exist in place-scoped v1 at all (no place to hang off) — it needs the
  first-class object, which pulled the sequencing question below.
- **The return-from-drift mechanism is the Live Activity**, by E's own framing: E answered the
  drift question by asking for exactly what ActivityKit provides — a live-updating Activity
  with Dynamic Island quick-nav back to the routine (E's 15 Pro has the island; tap = deep
  link; iOS 17+ adds the buttons). Verify the LA layout/button budget against Apple docs when
  writing the build plan, not from memory.
- **Two notification SPECIES, visually distinct** (settled): tasks keep their own nudge;
  routine notifications must look different at a glance — copy convention + leading glyph +
  their own notification category (its own action buttons) at minimum. Design the distinction
  as a deliverable, don't improvise it per block.
- **Kill-risks: E answered "ALL of these"** (wrong-moment fires, tap fatigue, stale steps,
  forgetting it exists) — so cooldowns, friction-minimisation, pruning and visibility are all
  load-bearing protections to sequence, not polish.

**The settled sequence (E's two scope calls):**
- **Arc 1 (this arc): place-scoped v1 + a DISPLAY Live Activity block** — progress, next
  step, tap-anywhere-returns; fits the widget's 16.1 floor, rides the sprint's ActivityKit
  plumbing. LA BUTTONS (Open next / Skip / Done — iOS 17+ App Intents) are the first
  fast-follow, not in-arc.
- **Arc 2, immediately after: first-class routines + the "at a time" trigger**, reusing the
  same routine screen (which never learns where its steps came from — that property is now
  load-bearing). New collection + rules publish land there.
- Then: LA buttons fast-follow; smart-skip (prune + reorder offers) prioritised next.

## The public-launch lens (E, 2026-09-03: "intended to be a publicly launched application in the near future")

Design for multiple users, not for E's phone. For Routines that means at minimum:
- **First-run and empty states are REAL paths** (the dead-shared-component lesson: first-run
  is the state nothing tests). A new user with no places must be able to DISCOVER routines —
  the Places editor's actions section and its footer copy carry that weight in v1.
- **Constants become sensible defaults, not E-tuned magic**: the 2+ threshold, the departure
  window, cooldowns — name them in one metrics type so a future Settings surface can expose
  them without a hunt.
- **The Always-location permission ladder matters more** (never request Always cold — the
  shipped pattern) because it is now a conversion risk, not a personal annoyance.
- Accessibility (VoiceOver labels, Dynamic Type) on the routine screen is launch surface, not
  nicety — house rules already require it; the LA needs its own a11y pass.
- Launch readiness beyond this arc (paid developer account — the free one means 7-day
  profiles and dormant SIWA — App Store review's location justification, TestFlight) is its
  own conversation, deliberately not folded into this arc.

## Open at build-plan time — narrowed by round 3

1. **Departure-routine lifetime** — now a REAL v1 case (E's leaving-somewhere routine).
   Candidate stands: a short fixed window after the crossing; and the same crossing that ends
   an arrival routine may start a departure one — define the collision order. Ask E in the
   build-plan round with a concrete number.
2. ~~Routine vs task nudge~~ **RESOLVED round 3: two notifications, visually distinct
   species.** Design the distinction (copy + glyph + category) as a deliverable.
3. **The end-of-day sweep needs no background wake** — lazy expiry on next launch / next Today
   render is the honest mechanism; say so in the plan rather than inventing a timer.

## Build traps recorded for whoever builds this

- **`RootView.swift` is at 396/400** — routine-door plumbing lands there; split first or give
  the routine screen its own presenter object.
- **`PlaceActionModels.swift` is at 357/400** — a new wire shape tips it.
- The `placeAction-` prefix greed (above): new prefix + new branch, and the delegate's
  place-action-first ordering must stay.
- `ToolsCatalogTests.testThePageStaysSparse` + both sparse-for-Routines doc comments move
  together with any third card.
- The routine notification should use a **stable identifier per place+direction** so a repeat
  crossing replaces, never stacks (the nudge's own rule, `ArrivalNudgeStateStore.swift:80-83`).
- **Pre-existing copy bug found while reading (not fixed — scoping session):** the editor's
  sprint footer says "Runs by itself when the crossing fires — no tap needed"
  (`PlaceActionsEditorView.swift:207`) while `PlaceActionPlan.split` makes `startSprint`
  tap-only (ActivityKit refuses background starts). Fix it in the first Routines block, or
  sooner.
- The unit-test sim must stay signed out; any drive that needs data means asking E to sign in
  (standing rule).

## The ADHD-directives mapping (why the screen looks like it does)

| Directive (adhd-routines-reqs.txt) | Where it lands |
|---|---|
| Zero-friction initiation | One notification, one tap to the screen; the next step is THE dominant element with a 48pt button; defaults everywhere (no forms) |
| Working-memory externalization | The screen IS the externalized memory: sticky place header, visible order, progress held across app-switches and relaunches; snapshot-backed, no network |
| Graceful recovery / impulsivity | Undo on ticked steps, Skip non-destructive, no "Are you sure?"; swiped notification recoverable via the Today card |
| Visual hierarchy vs load | One current-step card, done steps compressed, upcoming dimmed; 16pt-radius bento cards, aggressive whitespace |
| Time blindness | "arrived 2 min ago" relative time; visual progress bar, not text-only counts |

## Three new directions (E's 2026-09-03 ask), rendered as canvas row 3 — none is v1

Each builds on the settled scoping AND on machinery the app already ships.

**E's shaping answers (2026-09-03, second question round): ALL THREE are queued behind the
settled arc.** Per-direction:

- **Direction 1 — DEEP from day one, and wider than the mock.** E rejected glanceable-first
  and asked for **more interactive buttons on the Live Activity, "with more purposes, related
  to the activity it is displaying"** — so the routine LA carries purposeful controls (Open
  next / Skip / Done-without-opening are the candidates to design), not a single Open. That
  is iOS 17+ interactive-widget App Intents in the extension (16.1 floor stays for display).
  Read E's ask as a GENERAL interactive-LA capability: the sprint's Live Activity (pause /
  end) is the natural second beneficiary. Apple caps how much fits on an LA — the button set
  must be designed against the real layout budget, not assumed.
- **Direction 2 — "At a time" is the first non-location trigger.** 7:00-weekdays morning
  routines, riding the Nudges weekday scheduler. (Chaining "after another routine" noted as
  interesting but needs Direction 3's per-run records first.)
- **Direction 3 — prune AND reorder offers.** Skip-streaks earn a "remove it?" card, and
  observed tap order earns a "reorder to match how you run it?" offer. Always offers with
  undo, never automatic.

1. **The routine follows you to the lock screen** (board "Direction 1 · Lock screen"). The
   focus sprint already has a Live Activity — ActivityKit, `FocusTimerWidget` and the
   app-group plumbing are shipped. A running routine rides the same rails: progress + next
   step on the lock screen and Dynamic Island, one tap away while you're inside another app.
   The strongest time-blindness answer available. Cost: widget-extension work (16.1 floor),
   routine state crossing the app group like the sprint's.
2. **Triggers beyond location** (board "Direction 2 · Any trigger"). Location was the first
   trigger, not the definition: the Nudges rebuild already ships weekday scheduling, so
   "morning reset at 7:00" needs no geofence — the trigger becomes a choice on the routine
   (arrive / leave / at a time / only by hand). This IS Option B's shelf made concrete, so it
   rides the A→B growth path: new collection + rules publish when it comes.
3. **The routine maintains itself** (board "Direction 3 · Smart skip"). Steps rot — an app
   deleted, a habit changed — and one stale step teaches you to ignore the whole routine (the
   empty-never-fires lesson at step level). If each run records tapped-vs-skipped per step,
   the app can OFFER the pruning ("Snapchat skipped on your last 5 gym arrivals — remove
   it?"). Always an offer with an undo, never automatic. Cost: a small per-run record + one
   honest threshold. The run record doubles as the data Momentum analytics would want anyway.

## Verification record (2026-09-03, E's "self verify" pass)

- **Copy cross-checked against the shipped Swift**: every Before-board string matches
  `PlaceActionRowLabel.title` ("Open \(displayName)" for openApp AND openLink) and
  `PlaceActionNotificationContent` / `ArrivalNudgeContent` composition ("You're at Gym 🏋️ —
  tap to open.", "Time to train · Journaled "Leg day""). One deliberate mock addition:
  Option A's journal row subtitle adds "runs by itself" (shipped subtitle is direction only).
- **All 9 boards rendered and inspected in BOTH themes** (18 renders). The Chrome extension
  was not connected, so the render harness is `../routines-concepts/render_preview.py`:
  it resolves the `{{c.*}}` holes with the palette maps copied verbatim from the boards'
  own logic (no drift), then headless Chrome screenshots at frame size. The published
  editor page itself was checked by the seeder's `--check` + a file-level review pass, not
  driven in a browser.
- **Fixed from the passes**: step-count mismatch between boards (notification now shows the
  absorbed "Journaled" line and a note explains 3-taps-vs-4-rows); duplicated "Today" eyebrow;
  Undo turned from a 12px bare link into a chip (unambiguous affordance, directive #4);
  "Run now" pill 34→44pt; straight→curly quotes; notification chip's doubled border-radius;
  Home note given clearance from the capture disc; three frames trimmed (Before 640→470,
  After 470→350, OptionA 780→710) after renders showed dead space.

## Process notes for the record

- The brainstorming skill's spec-location step (`docs/superpowers/specs/`) was overridden per
  CLAUDE.md precedence: `/docs/` is Cowork-owned and this session makes no repo writes — the
  handoff directory is the house home for design records.
- No CLAUDE.md §7 design-skill conflicts arose; the canvas reuses the palette E already
  approved on the tab-bar canvas.

## E's answers (2026-09-03, via the four-question batch — all four recommendations taken)

1. **Model: A — place-scoped.** The routine is the place's actions in saved array order; the
   editor is the existing actions editor + drag-to-reorder + "runs in this order" footer. No
   new collection, no rules publish, no second editor. **Option B stays on the shelf as the
   growth path** — the routine screen must never learn where its steps came from, so B can
   arrive later without touching it.
2. **Notification: at 2+ tap-steps.** One routine notification (absorbing custom message +
   auto-run report) only when a crossing has two or more tap-steps; exactly one tap-step keeps
   today's direct one-tap notification; no-routine places untouched.
3. **Lifetime: until you leave.** The departure crossing ends a live routine; an end-of-day
   sweep catches a missed exit. The Today card exists exactly while a routine is live.
4. **autoRun steps: shown pre-ticked.** The list opens with the silent steps already done and
   labelled ("Ran by itself when you arrived") — instant progress and an honest record.

**Consequence worth stating:** with A chosen, the Tools page stays at TWO cards for now —
`ToolsCatalogTests.testThePageStaysSparse` stays at 2, and the sparse-for-Routines doc comments
stay true for a future Option-B growth. The canvas carries a "SETTLED" annotation with these
four calls; version label `settled-by-E`.

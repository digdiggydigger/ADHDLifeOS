# Routines — the build plan (Arc 1, written 2026-09-03)

*Self-contained plan for the build session. The design it implements was settled by E on
2026-09-03 — the record with E's answers is `SESSION-OPENER-routines-design.md` (same
directory; read it once, it is the WHY). The canvas E approved:
`https://claude.ai/code/artifact/3a932048-d940-4469-bc91-904d2906034f`. The wider vision this
arc feeds is `VISION-adaptive-lifeos.md` — read for direction, build NONE of it here.*

## The one-paragraph brief

A place's tap-actions, run in saved order, become a **routine**: when a crossing has **2+
tap-steps** for its direction, the N per-action notifications collapse into **ONE routine
notification** whose tap opens a full-screen **routine screen** — ordered steps, auto-run
steps pre-ticked, one dominant next-step card, Undo/Skip, progress bar. The run stays live
until you **leave the place** (departure routines: a 30-minute window), with a **Today card**
as the way back in and, in the final block, a **display Live Activity** anchoring the
Dynamic Island. Place-scoped only (Option A) — first-class routines + time triggers are the
NEXT arc, and the routine screen must never learn where its steps came from.

## Hard constraints (violating any of these is a stop-and-report)

- **iOS cannot chain app-opens.** N opens = N taps, always. Nothing auto-advances.
- **ActivityKit cannot START an Activity from the background** (the startSprint lesson). The
  crossing arrives with the app backgrounded, so the Live Activity starts when the routine
  SCREEN opens (foreground), not at the crossing. Updates/ends from the running process are
  fine — verify end-from-background behaves during the block.
- **ZERO wire/schema changes in this arc.** Step order = the existing `actions` array order
  (encode/decode preserves it — pin that with a codec round-trip test). No new `PlaceAction`
  kind, no new collection, no `firestore.rules` change, nothing for E to publish.
- **`extraPayload` preserves flat scalars only** — do not hang structured routine data off
  `PlaceAction`. (The vision's per-step "core" boolean is deliberately DEFERRED: as a flat
  scalar it retrofits safely later, so no forward-compat work now.)
- **The `placeAction-` notification prefix is GREEDY** — `PlaceActionNotificationRouter.handle`
  claims anything with that prefix even when broken (test-pinned). Routine notifications use
  their own prefix (`placeRoutine-`) and their own branch in `ADHD_LifeOSApp.swift`'s
  delegate chain.
- **`RootView.swift` is at 396/400** (SwiftLint default file_length). Before adding the
  routine door, move the existing door-handling funcs (`openWidgetDoor` :83-93,
  `openActionDoor` :97-105, the drain `.task` body) to a `RootView+Doors.swift` extension
  file in the same commit — **and know the catch (audited): those funcs touch `private`
  `@State`/`@StateObject` members, and Swift `private` is file-scoped, so the split requires
  demoting the touched members (`selectedTab`, `isFabOpen`, `composerKind`,
  `pendingWidgetLink`, `pendingActionDoor`, `focusService`/`startFocus`) to internal.** That
  is the established house pattern: `HomeView.arrangeAreas` is internal with an "Internal,
  not private: HomeAccessoryStrips reaches it" comment, mutated from `extension HomeView` in
  another file. The split only buys ~25 lines and the routine door spends most of them —
  it fits, barely; don't add anything else to RootView this arc.
- **Places UI is `@available(iOS 17.0, *)`** against the 16.0 app floor — but the TRIGGER
  machinery is not gated, and an account's places can come from another device. So a 16.x
  device CAN receive a qualifying crossing while being unable to show the 17-gated routine
  screen. **Below iOS 17 the handler keeps today's per-action notifications** (one
  `#available` at the threshold branch, pinned via an injected flag) — never a notification
  whose tap can do nothing.
- Suite green (expected baseline 2,202/0 + 56 emulator skips), `swiftlint lint` 0, red-check
  every block (commit FIRST — never-destroy-uncommitted-work rule), commit AND push per
  block with the close-out triple pasted.

## Settled design decisions (do NOT re-litigate — E answered these)

1. **Model**: place-scoped. Routine = the crossing direction's external actions in array
   order (`PlaceActionPlan.split` already computes them).
2. **Threshold**: routine notification at **2+ tap-steps**; exactly 1 keeps today's direct
   per-action notification byte-for-byte; 0 unchanged.
3. **Lifetime**: an ARRIVAL run lives until the same place's departure crossing; a
   DEPARTURE run lives `RoutineDefaults.departureRunWindow` = **30 minutes** (matches the
   shipped cooldown constant; a named default, not magic — public-launch lens). One live run
   globally, **newest wins**: a crossing that ends one run and starts another does it in
   that order. **End-of-day lazy sweep**: expiry is evaluated on read (app launch / Today
   render / store access) — NO timer, NO background wake.
4. **autoRun steps are shown pre-ticked** ("Ran by itself when you arrived").
5. **Two notification SPECIES, visually distinct**: task nudges keep their own notification;
   routine notifications get their own `UNNotificationCategory`, their own copy convention,
   and their own identifier scheme. When a routine fires, it ABSORBS the place's custom
   message and the auto-run report; the task nudge then carries tasks ONLY (and stays silent
   when there are none — empty-never-fires holds).
6. **Undo over confirm, everywhere.** No "Are you sure?" anywhere in the arc.

**Semantics pinned here so tests can't contradict each other:**
- **Progress**: the label "N of M done" counts auto-done + tapped-done; a SKIPPED step shows
  as skipped and counts toward the bar's RESOLVED fraction (resolved = done + auto + skipped
  over M) but not toward the "done" wording. Completion = no pending steps.
- **Undo** returns a tapped-done or skipped step to pending (progress recomputes); auto-done
  steps have no Undo (they ran — the record tells the truth).
- **Run end on completion**: a fully-resolved run ends when the user LEAVES the screen
  (dismiss or background), not at the final tap — so Undo stays available until then. Ends
  by departure/window/sweep behave as settled regardless of screen state.
- **Run lifecycle placement (the audit's #1 — a field-walk killer if missed)**: run END and
  newest-wins REPLACEMENT transitions execute **BEFORE the cooldown guard and OUTSIDE
  `isEnabled()`** in `PlaceTriggerEventHandler.handle`. Lifecycle is a RECORD, like the
  auto-runs — a departure crossing swallowed by its own 30-min cooldown must STILL end the
  arrival run, or "routine live" sits on Today until midnight. Pin with a stacked-cooldown
  fixture (arrive → leave → return → leave inside 30 min).
- **Kill-switch OFF still writes the run** (decided here so blocks 2 and 4 cannot pin
  contradictory tests): the run record and its Today card are PULL surfaces, records like
  the auto-runs; only the NOTIFICATION honours the switch (fire-time re-check, inside
  `isEnabled()` where the loop lives today). State this at the block-2 stop so E can veto.
- **Stale tap**: the run key is a **minted run UUID** riding both the store and the
  userInfo — never a composed placeId|direction|Date key (a Date serialised two ways makes
  EVERY tap mismatch, which looks exactly like block 2's inert interim). Key mismatch →
  open the app on Today, nothing else — pinned, never a blank routine screen.
- **Tray hygiene**: posting a routine notification removes that place's still-delivered
  per-action notifications — identifiers are `placeAction-<actionUUID>`, computed from the
  snapshot entry's external action ids. **No removal API exists on the notifier seam today**
  (grep: zero `removeDeliveredNotifications` call sites), so this is a SECOND named widening
  of `ImmediateNotifying` alongside the category one. **Widen as protocol requirements and
  update all four conformers** (`NotificationCenterImmediateNotifier` + the three test
  fakes) — extension defaults would leave the fakes unable to record. Budget ~45 min.
- Category registration: `setNotificationCategories` REPLACES the whole set — write the one
  call as the app's single category registry (nothing else registers categories today).

## Blocks (five; each: failing tests first, green, lint 0, red-check, commit+push, STOP for E)

### F-Routines-1-Order — drag-to-reorder + the pure core
- `.onMove` on the actions `ForEach` in `PlaceActionsSection.swift` (141 lines — room).
  The section has a SECOND ForEach (automation guide rows) — only the actions ForEach moves.
  Footer copy: "Steps run top to bottom on the crossing. Drag to reorder."
  **Known unknown, do not thrash on it**: `.onMove` inside a `Form` section classically needs
  edit mode, and `\.editMode` is an ENVIRONMENT value — scoping it to one section of the
  place editor's Form is untested in this repo. The real precedent (audited) is
  **`Home/HomeAccessoryStrips.swift:13-27`**: a plain `List` with `.onMove` and
  `.environment(\.editMode, .constant(.active))`, swapped in for the grid while arranging —
  NOT a sheet. Try scoped-environment on the section first; if it fights (edit accessories
  leaking to other sections, drag not engaging), fall back WITHOUT redesign to a "Reorder"
  row presenting that forced-editMode List — the List technique verbatim, the sheet
  packaging new (and on a Button, never the Section). Either way the pure order logic and
  codec pin are identical.
- Pin with tests: reorder round-trips through the REAL Firestore codec preserving order
  (order IS the feature); `PlaceEditorValidation.makePlace` keeps threading actions (it
  rebuilds the place on save — the known strip risk).
- New pure type `PlaceRoutinePlan` (own file): given (actions, direction) → ordered steps
  (auto + external), counts, and the ≥2 decision via `RoutineDefaults.stepThreshold`.
  `RoutineDefaults` holds every named number in the arc (threshold 2, departure window
  30 min) so a Settings surface can expose them later.
- Drive-by fix (one line + pin): `PlaceActionsEditorView.swift:207` claims startSprint
  "Runs by itself when the crossing fires — no tap needed" — false (`split` makes it
  external/tap-only). Correct the footer copy.

### F-Routines-2-Notify — the run store + one notification for 2+, two species
- **`RoutineRunStore` lands HERE, not in block 3** (the screen consumes what the handler
  creates — a notification keyed to a store that doesn't exist yet would be the plan's own
  bug). UserDefaults, the snapshot/cooldown precedent: one live run — place, direction,
  startedAt, ordered steps (id, kind label, auto/external), per-step state (autoDone / done /
  skipped / pending). Transitions as pure pinned logic: create on qualifying crossing
  (**write the store BEFORE posting**); departure-of-place ends an arrival run; newest-wins
  replacement; the 30-min departure window; lazy end-of-day sweep evaluated on read. **Name
  it as the future sensing seam** — these records become smart-skip's per-run data later.
- In `PlaceTriggerEventHandler.handle` (the `for action in plan.external` loop at :95):
  when the direction's externals ≥ threshold (and `#available(iOS 17.0, *)`), write the run
  and post ONE routine notification instead; below threshold or below iOS 17, the existing
  paths run UNCHANGED (regression-pin all three branches).
- Identifier `placeRoutine-<placeId>-<direction>` — stable per place+direction so an
  undelivered predecessor is REPLACED, never stacked (the nudge's own rule,
  `ArrivalNudgeStateStore.swift:80-84`). **userInfo carries only the minted run UUID** —
  the screen reads steps from the store, which exists by post time and is readable on a
  cold launch; one source of truth, and the stale-tap rule falls out of the key mismatch.
- The `compose` fifth path enters through `notification(for:snapshot:executedLines:)`'s
  public seam (`compose` itself is private static — the tests already pin at the right
  level). The DEBUG test-fire path constructs the handler without injection — give the run
  store a **defaulted init parameter** so test-fire exercises the routine branch for free.
- **Interim behaviour to tell E at this block's stop**: the routine notification's tap is
  deliberately INERT until block 3 lands the router (it falls through the delegate chain to
  no-op) — a device carrying the block-2 build shows the one notification but tapping it
  just opens the app.
- Content via a pure `PlaceRoutineNotificationContent` (every phrasing pinned): title stays
  the place moment ("You're at Gym 🏋️"); body = custom message · auto-run report · "N steps
  ready — <first names>. Tap to run." (the canvas's After board is the spec).
- The species split: routine notifications get their own `UNNotificationCategory`
  (registered ONCE via `setNotificationCategories` in the AppDelegate wiring — registration
  is app-level, not per-post). `ImmediateNotifying.post` has no category parameter — widen
  via a NAMED addition (house seam rule), don't change existing call sites.
  `ArrivalNudgeContent` learns that when a routine claims message+ranLines, the nudge
  composes TASKS ONLY (nil when no tasks — the 4-case compose gains its pinned fifth path).
- The DEBUG test-fire button (kept by E for exactly this) exercises the branch from the couch.

### F-Routines-3-Screen — the door and the screen
- `PlaceRoutineNotificationRouter` — the third pending-door replay (copy
  `PlaceActionNotificationRouter`'s shape; delegate branch in `ADHD_LifeOSApp.swift`
  alongside, not inside, the greedy placeAction branch; **signed-out taps go pending and
  drain after the tabs mount**, the openActionDoor pattern verbatim).
  `RootView+Doors.swift` split lands here, and the routine door presents a full-screen
  cover (17+ gated; the door resolves the run key against the store — key mismatch = the
  stale-tap rule).
- The routine screen (the canvas's Main board is the spec): eyebrow ROUTINE + close;
  large title = place moment; "message" · relative arrival time; progress bar + "N of M
  done"; pre-ticked auto rows; one dominant next-step card (48pt accent button, §3 targets);
  quiet Skip; Undo chip on done steps. Step taps run through the EXISTING plumbing
  (`PlaceActionTapRoute` / `PlaceLinkOpener` / sprint plan) — these are foreground button
  taps, so attribution is the simple case, and sprint steps start properly (foreground
  ActivityKit).
- Copy switches by direction ("arrived 2 min ago" / "left 2 min ago"); relative time via
  `Text(_:style:)` so it ticks without a timer.
- The screen is a fullScreenCover, so it sits ABOVE the capture disc and tab bar — no
  clearance calls; `CaptureDiscClearanceCallSiteTests`' table is untouched (assert nothing
  new joins it).
- A11y is launch surface: rows as combined elements, state never colour-alone, Dynamic Type.
- Sim drive end-to-end via test-fire; **the field gate is E's**: real crossing → one
  notification → tap → screen → taps → return → departure ends it.

### F-Routines-4-HomeCard — the way back in
- Today card while a run is live (canvas HomeCard board): "At <place> · routine live",
  "N steps left", next-step line, Continue → the routine screen. Gone when no live run —
  and prove REACHABILITY, not just correctness: grep call sites, render first-run and
  live-run states on the sim (the dead-shared-component rule; first-run is the state
  nothing tests).
- **`HomeView.swift` is at 391/400 (audited)** — the card mounts beside `ArrivalSurfaceCard`
  (:295-296) and even a small addition tips the lint bar. Put the card's content in its own
  file and, if needed, extract in the same commit (`HomeAccessoryStrips` /
  `HomeMomentumSections` exist for exactly this).
- **`ArrivalSurfaceCard` collision, decided here**: Home already shows "You're at <place> —
  N things live here" while at a place with open tasks. While a live run exists for the
  SAME place, the routine card takes the slot and the arrival card is suppressed (two
  stacked cards about one place is noise; tasks are the separate species and keep their
  notification). Arrival card returns when the run ends. Pin it; state it at the block-4
  stop so E can veto.

### F-Routines-5-LiveActivity — the display anchor
- Second `ActivityConfiguration` in `FocusTimerWidget` (16.1 floor): place name/emoji,
  done/total, next-step label, progress bar. **Starts when the routine screen opens**
  (foreground — the ActivityKit constraint above), updates on step changes, ends on run end
  (verify end works from the background handler when a departure crossing ends the run).
- Tap-to-return via `widgetURL` riding the existing widget-link door (`AppDeepLink`).
- **The shared `ActivityAttributes` type must compile into BOTH targets**: the mechanism is
  the pbxproj `PBXFileSystemSynchronizedBuildFileExceptionSet` whose `membershipExceptions`
  already lists `FocusActivityAttributes.swift` and peers — add the routine attributes file
  THERE (a pbxproj text edit, no Xcode GUI needed). A "cannot find type" error in the
  extension means this step was missed, not that the type is wrong.
- Known traps from the sprint LA (see `live-activity-gotchas` memory): the LA IGNORES the
  widget's global accent — use `Color("AccentColor")` explicitly; asset sharing across
  targets uses the synchronized-group exception sets; `idb` LOCK to photograph the sim lock
  screen. NO buttons in this block — interactive App Intents are the settled fast-follow.

## After block 5
E's field walk gates the merge (the same gate every location arc has used). Then: full
re-run, `--no-ff` merge, **re-verify ON main**, push, reinstall `wishwashwacky15` from main,
ask E before deleting the branch, and update the memory (`routines-next-arc`) with the
close-out. Arc 2 (first-class + "at a time" trigger) is already designed in outline — do NOT
start it; raise it.

## What is deliberately NOT in this arc (recorded so it isn't "forgotten")
LA buttons (fast-follow #1); smart-skip prune/reorder (needs run records this arc creates);
first-class routines + time triggers (Arc 2 — E's morning routine depends on it); the
lighter-path "core" boolean (safe scalar retrofit); island states 2/3 beyond routines; any
sensing/adaptation from the vision doc.

# The routine record — design record (2026-09-06)

*This is the design record and the why, the sibling of `SESSION-OPENER-routines-design.md`. It
is permanent; never archive it. E answered eleven questions in three rounds on 2026-09-06 and
approved the design below as written. Branch `feature/routine-record`, off `main` @ `ebc5865`.*

## The gap this closes

E's ask, raised mid-walk of the Block A checklist on 2026-09-05: *"there should be something
clearly differentiating between a Routines Arrival, a Routines Accepted and when a Routine is
completed. Ensuring genuine clarity over what was offered, what & when it was actually done and
whether it was actually completed or not."*

Verified at `ebc5865`: no routine path writes anything durable. A crossing writes a
`location_events` row and nothing else (Block A). The tap creates the run in app-local
`UserDefaults`; step states live there; completion DELETES the run. A routine of pure tap-steps
leaves the same trace whether you finish it or never open it: none.

## E's decisions, in the order they were made

**Round 0 — the fork.** A real `routine_runs` Firestore collection, not journal `Log` rows of a
new type. The reason to build the real one first: the cheap one and then the real one is
building it twice, and smart-skip, Arc 2 and Momentum all want the per-run record.

**Round 1 — E's own guidelines, verbatim in substance:**
1. **Override Block A's "no trace" for OFFERS.** An offered banner that is swiped away or
   ignored records a state in `routine_runs`, with a `dismissed_at`. *This is an explicit
   exception to Block A's rule.* Block A's other half — the crossing runs no auto-step and
   writes no journal line until the tap — stands.
2. **Journal visibility.** With the "everything" overlay ON, offered and ignored runs are
   visible in the timeline, so the user can see a routine was presented even if not done.
3. **UI distinction.** Ignored runs read muted (faded / secondary) so the timeline stays clean
   but accurate; they are hidden by default and shown only when the user toggles the filter.
4. **Schema for edge cases:** `offered_at`, `started_at`, `dismissed_at`, `expired_at`;
   `completed_steps_count`, `time_spent_seconds`; `dismissal_method` (swipe / tap / timeout).

**Round 2:**
- The overlay is a **header switch, independent of the chips** — "All activity", off by default.
- Beyond the Journal, the record surfaces on the **Tools Routines section as a last-run line**.
  (Not chosen: a done card on Today until end of day.)
- A started run that ends with steps pending is **recorded fully, read gently**: the row says
  what happened — "Routine at Gym · 2 of 4 done" — never "abandoned". Count up only, the
  bad-day constitution in `VISION-adaptive-lifeos.md`.
- **The run-store sign-out leak is folded in** (register item B2).

**Round 3:**
- **Two Journal rows per run**, started and finished, each at its own timestamp.
- **The arrival row stays beside them.** "Arrived at Gym" is the fact of the crossing; the
  routine rows sit next to it. A completed routine is therefore THREE lines per crossing.
  Stated to E plainly against the register's note that the Journal already reads repetitive;
  E chose it.
- **Swiped and timed-out offers share one muted row with different subtitles**: "· cleared"
  for a swipe, "· not opened" for a timeout.

## What iOS can and cannot tell us (verified, not assumed)

- The routine notification category is registered with `options: []`
  (`ADHD_LifeOSApp.swift`). Adding `.customDismissAction` makes iOS deliver a response with
  `UNNotificationDismissActionIdentifier` when the banner is cleared by swipe or Clear All.
  That is the ONLY dismissal signal iOS offers.
- A banner that is never touched sends nothing. "Ignored" is therefore always PASSIVE: derived
  when the offer's lifetime lapses, by the same rules a live run already obeys
  (`RoutineRunLifecycle.isLive` — arrival: until the place's departure or the end of the day;
  departure: `RoutineDefaults.departureRunWindow`).
- The notification identifier is stable per place+direction, so a second crossing REPLACES an
  undelivered banner. The earlier offer then gets neither tap nor swipe and times out. Honest.
- A Firestore write from the background wake is established practice: the handler already
  awaits `location_events` there.

## Schema — `users/{uid}/routine_runs/{runId}`

The document id IS the minted `RoutineRun.id`, so the banner payload, the local live-run cache
and the document share one key. Snake_cased on the wire (the `tasks` / `places` /
`location_events` convention). Hand-written field dictionaries live in `FirestoreFieldPayloads`.

| field | type | written when |
|---|---|---|
| `id`, `place_id`, `direction` (`arrival`/`departure`), `display_name`, `custom_message` | frozen | offered |
| `status` | `offered` / `dismissed` / `expired` / `started` / `ended` | every transition |
| `offered_at` | timestamp (the crossing's `occurredAt`) | offered — only when the banner was actually POSTED |
| `started_at` | timestamp | the tap; `dismissal_method` = `tap` |
| `dismissed_at` | timestamp | swipe / Clear All; `dismissal_method` = `swipe` |
| `expired_at` | timestamp | the offer's lifetime lapsed unopened; `dismissal_method` = `timeout` |
| `dismissal_method` | `tap` / `swipe` / `timeout` | how the OFFER was resolved |
| `steps` | array of `{action_id, title, kind, state, resolved_at}` | offered, then every tap / skip / undo |
| `total_steps_count`, `auto_steps_count`, `completed_steps_count`, `skipped_steps_count` | int | every step change |
| `time_spent_seconds` | int | every step change; = `last_interaction_at − started_at` |
| `last_interaction_at` | timestamp | every step change |
| `ended_at`, `end_reason` | `completed` / `left_place` / `window_lapsed` / `day_ended` / `replaced` | the run ends |
| `created_at`, `updated_at` | timestamp | as every collection |

Definitions that stop two screens disagreeing:
- `completed_steps_count` = auto-done + tapped-done, exactly `PlaceRoutineProgress.doneCount`.
- `time_spent_seconds` runs to the LAST STEP INTERACTION, not to the end stamp — a run left
  open on a screen, or ended by a departure an hour later, must not inflate it.
- `status` is stored for the console's sake; the app derives phase from the stamps
  (`RoutineRunRecord.phase`), so a document with `started_at` and a stray `dismissed_at`
  reads as started.

**Rules:** `routine_runs` joins the generic full-CRUD list in `firestore.rules` — it is updated,
so it cannot take the append-only shape. **E republishes; the change is not live until then.**
Account deletion cascades automatically: `FirebaseManager.Collection` is `CaseIterable` and the
wipe iterates it.

## The write points — one seam, six sites

`RoutineRunRecording` (async, narrow — the house adapter rule) with `FirebaseRoutineRunRecorder`
over a `RoutineRunsBackingStore` protocol that `FirebaseManager+RoutineRuns` satisfies, and a
recording fake in tests. Every site pinned by a call-site guard, because this repo's most
repeated defect is a helper that nothing calls.

| # | moment | site | writes |
|---|---|---|---|
| 1 | offered | `PlaceTriggerEventHandler`, after the routine banner posts | `offered(run)` — suppressed crossings (cooldown, kill-switch, below threshold) offered nothing and write nothing |
| 2 | started | `PlaceRoutineActivator.start` | `started(run, at:)`; a second tap is `.open` and writes nothing |
| 3 | swiped | `ForegroundNotificationPresenter` — new routine-dismiss branch, category gains `.customDismissAction` | `dismissed(runId, at:)` |
| 4 | step change | `PlaceRoutineScreen.apply` | `progressed(run, at:)` — steps, counts, `time_spent_seconds` |
| 5 | ended | screen `leaveScreen` (completed); handler `endLiveRunIfThisCrossingEndsIt` (left_place); activator when a different live run is replaced (replaced) | `ended(run, reason:, at:)` |
| 6 | lapsed | `RoutineRunReconciliation` — pure; runs after each Journal load and Tools load | for every document with no terminal stamp whose lifetime has passed: `expired(...)` (unopened offer) or `ended(..., window_lapsed / day_ended)` (a started run). Written ONCE; no timer, no background wake |

The recorder is fire-and-forget from the UI paths (a `Task` the caller holds, so tests can
await it — the `PlaceRoutineActivator.autoRunTask` lesson) and awaited from the handler, which
already awaits its `location_events` write.

## The surfaces

**Journal.** `JournalTimeline.Entry` gains `.routineOffered`, `.routineStarted`,
`.routineEnded`. One document yields up to two visible rows, so `Entry.id` becomes a composite
`String` — the "no two entries collide" contract the enum's own doc comment states.

| row | when shown | reads |
|---|---|---|
| started | Everything, always | "Started routine at Gym 🏋️" at `started_at` |
| ended | Everything, always | "Finished routine at Gym 🏋️ · 3 of 4 done" when `end_reason == completed`; otherwise "Routine at Gym 🏋️ · 2 of 4 done" |
| offered | ONLY with the header switch on | "Routine offered at Gym 🏋️ · cleared" (swipe) / "· not opened" (timeout); muted: secondary ink, no accent tint |

A run still live shows its started row only. Place names resolve through the CURRENT place
record like `locationEventLine`, so a rename updates every row; a dangling place drops the row.
Like location rows, routine rows appear under Everything and never under a life-area filter.

The switch: "All activity" in the Journal header, `@State`, off on every launch, not persisted —
E's "hidden by default" read literally.

**Tools Routines section.** `ToolsRoutinesCatalog.rows(from:runs:)` — the subtitle gains
"· last run Tue, 3 of 3" from the newest STARTED record for that place+direction. Rows with no
history are byte-identical to today. The catalog still decides nothing about membership.

## The sign-out leak (register B2, folded in)

`UserDefaultsRoutineRunStore.runKey` becomes per-user: `places.routine.liveRun.<uid>`, the uid
supplied by an injected `userScope: () -> String?` (default reads `FirebaseManager.shared`'s
current user at call time, never at construction, so the store built at launch follows the
session). Signed out → no read, no write. `AuthService.signOut()` and
`completeAccountDeletion()` also clear the live run through an injected hook.

**Found, not folded (E's call pending):** `UserDefaultsArrivalNudgeStateStore` holds the
at-place SNAPSHOT — place names and custom messages — under the same app-local key and leaks
the same way. On the register.

## Blocks

Two FEATURE blocks on one branch, each ending at E's review:

- **F-RoutineRecord-1-Ledger** — schema, rules, `RoutineRunRecord` + codec round-trip,
  payloads, the recorder seam, all six write points, the reconciler, the sign-out leak. An
  emulator test proves the live rules allow the update.
- **F-RoutineRecord-2-Surfaces** — the Journal rows and switch, the Tools last-run line, and
  a UI journey that fires a crossing, walks the routine, and finds the rows.

## Traps for whoever builds this

- `PlaceRoutineScreen.swift` is 357/400 and `HomeView.swift` 398/400. The screen gains one
  recorder call in `apply` and one in `leaveScreen`; anything more moves out.
- `HomeRoutineCardCallSiteTests.testEveryExitFromTheScreenEndsTheRunItself` counts
  `leaveScreen()` occurrences in the screen source (= 5). A new mention in a comment breaks it.
- `RoutineFakeRunStore` in `RoutineHandlerHarness` must gain the recorder; every scenario in
  `RoutineDeferredLoggingTests` that says "writes nothing" now means "writes nothing to the
  RUN STORE or the journal" — the OFFER record is the sanctioned exception, and the tests must
  say so in words.
- The dismiss response arrives with the app possibly cold-launched in the background. The
  delegate branch must not touch UI, and must not route through the tap router (which would
  START the routine).
- `setNotificationCategories` replaces the whole set — the option is added to the ONE
  registration, not a second one.
- The reconciler must never write for a document that is the LIVE run in the local store
  (a started run still inside its lifetime), and must never write twice for one document.
- The unit-test sim must stay signed out (standing rule). The journey signs in through the
  emulator like `RoutineJourneyUITests`; erase the sim before any unit run after it.

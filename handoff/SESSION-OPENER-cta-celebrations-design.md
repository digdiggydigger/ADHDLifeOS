# Design record — celebrations for the app's other call-to-action buttons (the CTA celebrations arc)

*This is the design record and the why. It is PERMANENT — never archive it (CLAUDE.md, "Session
handoff": `SESSION-OPENER-*` files are records despite the name). Written 2026-09-11 from E's
answers in chat, question by question, the way the Confirm celebration was designed
(`SESSION-OPENER-confirm-celebration-design.md`). **Nothing in this arc is built. E's direction,
verbatim: "YOU MUST NOT BUILD IT IN THIS SESSION" and "You must start building this in a fresh
claude code terminal session."** Build status lives in `OPEN-ITEMS-REGISTER.md`; this record stays
the design.*

**Everything in "The settled specification" was answered directly by E. Do not re-litigate any of
it without E.** Where a line says E chose, E was shown the options as text and picked; where the
answer is visual (the pop's look, the congratulation view, the chime) the build renders options
first and E picks by looking or listening, as the Confirm prototypes were chosen. **"Claude Code's
recommendations" (R-a … R-h) are NOT E's decisions**; they are here so E can accept or change them
in review, and they are marked as such.

---

## What prompted it

E, at the close of the session that built the Confirm celebration (2026-09-11), verbatim:

> *"I want to focus on assigning animations such as this one we've just created to other CTA
> buttons etc. throughout the app."*

"This one" is the Confirm celebration: a full-screen done-green glow with confetti raining from the
top and fired from both bottom corners, plus the success haptic, on E's phone and passed with Reduce
Motion ON and OFF.

## The settled specification

### E's answers, in the order they were given

"(rec.)" marks the option Claude Code recommended. **E overruled the recommendation seven times**
(F2, F3, F5, F6, R3, R4 and the cooldown at F9), which is why the recommendations are recorded at
all: they are not the design.

#### The eight questions carried in `START-HERE-cta-celebrations.md`

| # | the question E was asked | E's answer, verbatim | options |
|---|---|---|---|
| 1 | Should the fireworks take the confetti's +1.2 s even stretch (≈ 5.0 s → ≈ 6.4 s)? | **"Same stretch"** | Same stretch (rec.) / Own pace / Decide by video |
| 2 | Build the fireworks now, or after this arc's design? | **"Design first, then fireworks"** — the fireworks are the arc's FIRST build block | Design first, then fireworks (rec.) / Build now / After the other CTAs |
| 3 | Add the confetti off switch now? | **"Add it in this arc"** — a "Celebrations" switch in Settings, ON by default, turning off every FULL-SCREEN celebration; haptics and in-place feedback stay | Add it in this arc (rec.) / Keep for pre-launch / Two switches |
| 4 | Is this focus "the second change"? | **"There is no second change"** — the register item was a misreading | (factual) |
| 5 | Which moments earn a celebration, and how big? (the tiering below was proposed) | **"Accept this tiering"** | Accept (rec.) / More full-screen / Smaller |
| 6 | How often should a full-screen milestone fire? | **"Cooldown on milestones"** — in place on every tap; a NEW full-screen milestone fires in full only if no full-screen celebration played inside the cooldown, otherwise it gets the in-place celebration; Confirm keeps "every time" | Cooldown (rec.) / Every time / Milestones only |
| 7 | With Reduce Motion ON, what do the NEW sites do? | **"Fade everywhere new"** — Confirm stays the ONLY waiver; E accepts that the new milestones will not rain on their own phone | Fade everywhere new (rec.) / Full motion at the 3 milestones / Full motion everywhere new |
| 8 | Tidy the four haptic inconsistencies? | **"Tidy all four"** — one small block at the START of the arc | Tidy all four (rec.) / Only the missing ones / Leave them |

#### Follow-ups (E: *"I think you should ask me some more questions"*)

| # | the question | E's answer, verbatim | options |
|---|---|---|---|
| F1 | What does "the day cleared" mean exactly? | **"Drop this milestone"** | Nothing due today or overdue left (rec.) / Home's Today list empty / Every open task closed / Drop |
| F2 | Where should "a routine finished" fire? | **"Add a Finish button"** — later refined by E into the Completed flow (R1–R5 below) | On the last step's tick (rec.) / Add a Finish button / On leaving the screen |
| F3 | Any milestones beyond inbox zero and a finished routine? (multi-select) | **"Nudge streak lands on 7"**, plus, verbatim: *"When dismissing a nudge using the "Done for now" Button. When the user hits their 'daily goal' momentum on the Today tab."* | None beyond the two (rec.) / First task ever closed / Nudge streak lands on 7 / A sprint count milestone |
| F4 | "Done for now": full-screen only when a streak lands on 7, or every time? | **"Option one but also every 'done for now' must be given a different screen animation - We can handle this later."** | Streak only (rec.) / Every Done for now |
| F5 | Sound? | **"Full-screen milestones only"** — one soft chime on the full-screen celebrations (Confirm and the four milestones), behind a NEW "Celebration sounds" switch, OFF by default | No sound (rec.) / Full-screen milestones only / Decide later |
| F6 | What family for the IN-PLACE celebration? | **"Mini confetti pop"** — 12 to 20 pieces from the tap point, the Confirm engine at a tenth of the size; under Reduce Motion a still scatter that fades; rendered in situ before build | Halo + tick (rec.) / Mini confetti pop / Both |
| F7 | When should the Momentum daily-goal celebration fire? | **"The moment the count crosses the goal, any tab"** — about a second after the action that crossed it, on any tab; once per day; no replay after an undo-and-recross | Crosses the goal, any tab (rec.) / Only on the Today tab / Drop |
| F8 | How big are the four new milestones? | **"The every-Confirm size"** — glow + rain + cannons, 5.4 s; fireworks stay reserved for the stack-clearing Confirm | Every-Confirm size (rec.) / Fireworks size / Fireworks for some |
| F9 | *(unprompted, on the 30-minute cooldown proposed at #6)* | **"please reduce that "30-minute cooldown" to 5 seconds for now so i can test it properly. i am undecided about the cooldown at the moment anyway. but adjust it to a 5-second cooldown for testing"** | — |
| ARCH | One drawing layer per presented surface, or one passthrough `UIWindow` above everything? | **"One layer per surface"** | One layer per surface (rec.) / One passthrough UIWindow |

#### The routine "Completed" flow

E, unprompted, verbatim: *"I would also like to build on the plan for the new Routine Finish Button
that we are adding. Because when a routine is finished, I think The user must have to confirm by
manually tapping a "Completed" button before any actions such as logging it to the Journal or
running the animation etc are run."*

| # | the question | E's answer, verbatim | options |
|---|---|---|---|
| R1 | Confirmed reading: the run ends ONLY on the Completed tap, and the Journal record (the completed end-write is what the Journal's routine rows show), the celebration and the haptic all hang off it. What if someone resolves every step and leaves WITHOUT tapping? | **"Right; leaving keeps it open"** | Leaving keeps it open (rec.) / Leaving ends it quietly / Leaving asks first / Not quite |
| R2 | When is Completed available? | **"Appears once every step is resolved"** (done OR skipped, as today) | Appears once resolved (rec.) / Always shown, disabled / Always enabled, finish early |
| R3 | What the tap does, in order: close the screen and celebrate over the app, or stay? | **"I would like to display a temporary full-screen view that's states and congratulate the user For their Completion of the 'Routine' (Using the name they have used in their app settings)"** | Close + celebrate over the app (rec.) / Stay on the routine screen |
| R4 | Which name: the routine's, or the account display name? | **"Your display name"** | Routine's name (rec.) / Your display name / Both |
| R5 | How does the congratulation view leave, and what plays on it? | **"Auto-leave when the confetti ends, tap to skip"** | Auto-leave (rec.) / Done button / Fixed 2 s |

#### Lower-priority register items (asked together)

| item | E's answer, verbatim |
|---|---|
| The widget extension's `MARKETING_VERSION` 1.0 vs the app's 1.3 | **"Set the widget to 1.3"** (done in this record's PR) |
| An older simulator runtime | **"In a number of days in the future, I will install this"** |
| The collapsed card's square bottom corners | **"Round them"** (a small block after this arc) |
| The widget's view-only files testable? | **"Leave it, close the item"** |

### What that adds up to

**The principle E accepted (#5): celebrate DOING, not ADDING** — closing, sorting, completing earn
feedback; creating a task or saving an entry gets a haptic only, so a real win is never diluted by a
capture.

**Four full-screen milestones, each the every-Confirm celebration** (#5, F3, F8): the done-green
glow, 120 rain + 100 cannon confetti, 5.4 s, plus the site's success haptic. No fireworks; those stay
the stack-clearing Confirm's alone.
1. **Inbox zero** — the Sorted, Journal it or Create Task that empties the capture inbox.
2. **A routine completed** — the Completed tap (R1–R5).
3. **A nudge's streak lands on 7** — the "Done for now" that makes seven consecutive days.
4. **The Momentum daily goal** — Home's ring count (tasks closed today, plus cleared captures and
   dismissed nudges when those Settings toggles count them) crossing the goal, on any tab, about a
   second after the action, once per day (F7).

"The day cleared" was dropped (F1). Every Confirm keeps its own celebration exactly as shipped.

**Nine in-place moments get a mini confetti pop** (F6): every task close (the row's circle and swipe,
the detail screen's "Close it", the life-area row, Home's Best-next-move "Close it"), every Sorted /
Journal it / Create Task on a capture, "Done for now" on a nudge, and each routine step's action.
The Best-next-move closure card also springs in instead of popping in unanimated (#8).

**Haptic only** (#5): Add the task, Save entry, Save to inbox / Add to Today, Save a place (new,
`.solid`), create a life area or tag, Sign in; Stop sprint gets a light tap (new). "Got it" stays as
it is (register §C).

**Frequency (#6, F9):** the pop plays on every tap. A milestone fires in full only if no full-screen
celebration has played inside the cooldown; inside it, the milestone gets the pop instead, so the
moment is never unmarked. **The cooldown constant ships at 5 s, for E's testing; both its value and
whether it exists at all are undecided** (register §A). Confirm is never cooled down.

**Reduce Motion (#7):** every new site fades. The pop becomes a still scatter that fades; a
milestone shows the glow (already opacity-only) plus a still confetti field that fades, no falling.
The Confirm celebration remains the ONE waiver of CLAUDE.md §7.2, and the waiver is not extended by
analogy.

**The switches (#3, F5):** "Celebrations", ON by default, turns off every full-screen celebration
(Confirm's included); haptics and pops stay. "Celebration sounds", OFF by default, adds one soft
chime to the full-screen celebrations only. Both read at fire time.

**The routine Completed flow (R1–R5), which REVERSES the routine-record arc's rule that leaving the
screen ends a fully-resolved run:**
- while a step is pending the screen shows the next-step card as today; once every step is done or
  skipped, that slot shows a **Completed card** with the button (R2);
- **Completed** → the success haptic → the run ends and the completed record is written (the Journal
  row) → the screen's content is replaced by a **temporary full-screen congratulation** greeting the
  user by their **account display name** ("Nice one, Ethan"; no name → the greeting drops it), with a
  line about the routine and the done-green glow, and the milestone confetti playing over it
  (R3, R4, R5);
- it leaves on its own when the confetti ends (5.4 s) or on a tap anywhere; under Reduce Motion the
  still confetti fades over the same length; with the Celebrations switch OFF it shows a shorter beat
  of about 2 s with no confetti (R5);
- **leaving without tapping Completed keeps the run LIVE** with every step ticked: the Today recovery
  card can reopen it, Completed can be tapped later, Undo lives until then, and the lifecycle's expiry
  applies as to any live run (R1). Nothing is recorded as completed, nothing celebrates, without the
  tap. The background-with-everything-resolved auto-end goes with the old rule.

**Later, not this arc (F4):** E wants a DIFFERENT, nudge-specific screen animation for every
"Done for now". Parked in register §C.

### Two readings, and where E answered them

- **"When dismissing a nudge using the Done for now Button" (F3)** could have meant every Done for
  now is a full-screen moment. Put to E at F4: **"Option one"** — full-screen only when the streak
  lands on 7; the nudge-specific animation for every Done for now is a later design.
- **"Add a Finish button" (F2)** could have meant a button that ends the run and celebrates over the
  app. E refined it unprompted into the Completed flow, and R3 overruled "close the screen and
  celebrate over the app" with the temporary congratulation view. R1–R5 are the answer.

---

## The design

### 1. One app-level owner — `CelebrationCenter` (`ADHD LifeOS/Celebrations/`)

Only two `ObservableObject`s exist at the app root today (`AuthService`, `FocusSessionService`);
every other service is a screen-scoped `@StateObject`, and the Confirm overlay is keyed to one
service stamp. A cross-app trigger needs somewhere app-level to meet.

- **Owned by the App** as a `@StateObject`, passed into `RootView` the way `authService` is
  (`ADHD_LifeOSApp.swift:171/203`). Not created in `RootView`: that file is at 394 of 400 lines and a
  `@StateObject` cannot live in an extension file.
- **Sites see a narrow protocol only** — `CelebrationRequesting` — through a custom environment key
  `\.celebrate` whose default is an inert requester, so no preview, snapshot or test has to provide
  anything and no leaf `init` changes. The two milestone SERVICES (`CaptureInboxService`,
  `NudgesService`) take it as a defaulted `init` parameter from their host views (the
  `*ClientAdapting` shape), so a service test injects a recording fake. Layers read the class via a
  second key `\.celebrationCenter: CelebrationCenter?` (default `nil` → the layer draws nothing).
  Never `.environmentObject` (a missing one crashes previews). A singleton was rejected: untestable,
  the `FirebaseManager.shared` lesson.
- **API:**

  ```swift
  enum CelebrationMilestone { case inboxZero, routineFinished, streakSeven, dailyGoal }
  enum CelebrationKind: Equatable { case confirm(clearedStack: Bool); case milestone(CelebrationMilestone); case pop }
  enum CelebrationSurface { case root, routineCover, tasksSearch, promoteSheet }   // promoteSheet self-dismisses
  enum CelebrationOutcome { case fullScreen, inPlace, nothing }
  protocol CelebrationRequesting {
      @discardableResult func request(_ kind: CelebrationKind, at origin: CGPoint?) -> CelebrationOutcome
      func surfacePresented(_ surface: CelebrationSurface)
      func surfaceDismissed(_ surface: CelebrationSurface)
  }
  struct CelebrationBurst: Equatable, Identifiable { ordinal (id AND seed), kind, surface, start, origin? }
  ```

- **Pure, unit-tested with an injected `Date`:**
  - `CelebrationPolicy.outcome(for:lastFullScreenAt:now:celebrationsEnabled:)` — `.pop` → `.inPlace`
    always; `.confirm` → `.fullScreen` with the switch on, else `.nothing`, never cooled down;
    `.milestone` → `.inPlace` with the switch off or inside the cooldown, else `.fullScreen`.
    **`milestoneCooldown = 5` seconds** (F9), pinned by a test that names it E's testing value.
  - `CelebrationQueue` — full-screen cap 3 (the Confirm record's R1, unchanged), pop cap 8;
    `length(of:)`: pop 1.0 s, cleared-stack Confirm ≈ 6.43 s, every other full-screen 5.4 s;
    `choreographyTime` (pops on raw time, full-screen × the Confirm `pace`); `adding` / `pruned` /
    `nextExpiry`. `ConfirmCelebrationQueue` (`Focus/ConfirmCelebrationRecipe.swift:162-206`) becomes
    `ConfirmCelebrationClock`, holding only the numbers; `ConfirmCelebrationBurst` is replaced.
  - `CelebrationMotion.resolve(reduceMotion:kind:)` → `.full` for Confirm on ANY setting (the one
    waiver), else `.still` under Reduce Motion. In its own file, so the Confirm physics, recipe,
    fireworks and frame files never contain the strings `reduceMotion` / `accessibilityReduceMotion`;
    the waiver pin (`testTheConfirmCelebrationIgnoresReduceMotionByDesign`) becomes "those files are
    RM-free AND the resolver returns `.full` for Confirm".
  - `DailyGoalCrossing.crossed(previous:current:goal:)`, a `DailyGoalTracker` that ignores the first
    load and a goal lowered under the count, and `CelebrationDayMarking` keyed per ACCOUNT and day
    (the `NudgeFirstRunMarker` shape) because a per-device key would let a second account on one
    phone inherit the first's "already celebrated today" (`HomeView.swift:69-72`).
- **The centre:** one ordinal counter for every burst (pops and full-screens share it, so SwiftUI ids
  and confetti seeds never collide); `lastFullScreenAt`; a surface stack (`frontmost`); full-screens
  requested while a self-dismissing surface is frontmost are `held` and released with `start = now`
  on `surfaceDismissed`; the chime hook; `prune(now:)`.
- **The Confirm path is unchanged where E verified it.** `FocusConfirmation` stays the service's
  stamp, written only by `confirmCompletion`; its ordinal keeps driving
  `.haptic(.success, trigger: focusService.confirmationCount)` at `RootBottomOverlay.swift:155`. The
  bridge is one `.onChange(of: focusService.latestConfirmation)` beside that haptic on the
  always-mounted `RootBottomOverlay` (the listener-outlives-the-stack reason recorded there),
  calling `celebrate.request(.confirm(clearedStack:), at: nil)`. The centre's ordinal never reaches
  a haptic; the service's never reaches the layer.

### 2. Drawing — one `CelebrationLayer(surface:)` per presented surface (ARCH)

The shipped root overlay sits BELOW every sheet and cover, and two covers host celebration sites:
the routine screen (a `fullScreenCover`, `RootView.swift:253`) and the Tasks search surface
(`TaskListView.swift:97`; its `TaskRow`s at `TaskSearchSurface.swift:165` close tasks). The Create
Task sheet (`CapturePromoteSheet`) hosts a third. A passthrough `UIWindow` was offered and E chose
layers per surface.

- `RootView.swift:252` becomes `.overlay { CelebrationLayer(surface: .root) }` at the SAME position
  (after `RootBottomOverlay`'s overlay, before the covers), so the Confirm record's R3 still holds.
  Three more mounts: the routine cover (`RootView+Doors.swift:103-117`), `TaskSearchSurface`, and
  `CapturePromoteSheet`. Each presenter's `onDismiss` calls `surfaceDismissed` (not `onDisappear`,
  which `PlaceRoutineScreen.swift:80-83` records as unreliable for that cover). A call-site test
  enumerates the four mounts and the three `onDismiss`es so a fifth cover cannot appear unnoticed.
- The layer draws only the bursts tagged with its surface: `GeometryReader` → `CelebrationStage`
  (pieces generated once per list change, outside the `TimelineView` closure) →
  `CelebrationFrame(scenes:date:originOffset:)`, moved and generalised from
  `Focus/ConfirmCelebrationOverlay.swift:67-137` (that file is deleted). Only the root layer runs the
  expiry `.task`. `.ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)`, as today.
- **The pop's origin** — `onGeometryChange(for:of:action:)` is back-deployed to iOS 16.0 in the 26.5
  SDK, so it needs no gate. `CelebrationPopSource.swift` gives `.celebrationPopOrigin(_:)` (keeps a
  control's GLOBAL centre) and a `CelebrationPopSource` wrapper handing a site `handle.pop()`. The
  row's circle and swipe pop from one point (`TaskRow.swift:34-37`'s shared `close()`); the
  `TaskDetail` Form row is drawn by the ROOT layer, so row clipping is irrelevant. If the sim shows
  no initial delivery, the fallback is the GeometryReader-in-background + preference idiom inside
  the same file.
- **Recipes** (`CelebrationRecipes.swift`; the seven catalog tokens only, §4 and `raw_hue_color`):
  `pop(at:ordinal:)` 12–20 pieces radial from the point, 250–450 pt/s, lives 0.7–1.0 s;
  `stillPop(at:ordinal:)` the same count at rest within 48 pt; `stillField(canvas:ordinal:)` 120
  pieces at rest across the canvas; `CelebrationStillField.state(...)` — geometry pinned from the
  first frame (§7.2's opening-pose rule), opacity in 0.3 s / hold / out over the last 0.7 s.
  Milestones = `ConfettiRecipe.everyConfirm` + `ConfirmCelebrationGlow` at 5.4 s.
- **The fireworks (block 1) plug into the same frame:** `Focus/ConfirmFireworksSchedule.swift` (the
  Confirm record's 14 shells in 9 tokens), `Focus/ConfirmFireworksPhysics.swift` (rise, sparks via a
  `ConfettiPhysics.state(of:at:gravity:drag:)` overload at 150 / 2.4, ring-in-ring at 0.55×, two-tone
  alternation, the flash, `lastSparkTime` 4.79 s), `Focus/ConfirmFireworksDrawing.swift` (the Canvas
  ops and `ConfirmCelebrationDim`: `Scrim` 0.85, light only). Drawn only for `clearedStack`;
  `length(of:)` → `5.0 / pace ≈ 6.43 s` (#1). All on the choreography clock; all three files join
  the waiver pin's list.

### 3. The triggers

- **Inbox zero** — in `CaptureInboxService` (a new `+Celebrations.swift`), after `removeCapture(id:)`
  in `sort`, `logToJournal` and `promoteToTask`: if the capture was waiting and the `.unprocessed`
  list is now empty → `request(.milestone(.inboxZero), at: nil)` (the site already popped). The
  Home and Journal capture doors build a service with no list (`JournalTimelineSections.swift:321-337`),
  so there the answer is one fetch. Create Task from the promote sheet is held until the sheet's
  `onDismiss`, then plays over the empty inbox.
- **A routine completed (R1–R5)** — `PlaceRoutineScreen` is at 379 lines, so the new pieces live in
  `Places/PlaceRoutineCompletedCard.swift`, `Places/PlaceRoutineCongratulationView.swift`, and a
  `PlaceRoutineScreen+Completion.swift` extension for `complete()` if the screen nears 400.
  - The next-step slot (`PlaceRoutineScreen.swift:66-68`) shows the Completed card (eyebrow ALL
    DONE, a title, the primary `Button("Completed")`, id `routineCompletedButton`) when no step is
    pending and the run is fully resolved.
  - `complete()`: `Haptics.play(.success)` → `hasRecordedEnd = true; store.end(runId:);
    recorder.ended(reason: .completed)` → `activity.ended(); DataChangeSignal.post()` →
    `let outcome = celebrate.request(.milestone(.routineFinished), at: buttonOrigin)`, drawn by the
    cover's OWN layer (not held) → the body becomes the congratulation, for 5.4 s on a full-screen
    outcome and about 2 s otherwise.
  - `PlaceRoutineCongratulationView(displayName:routineTitle:length:)`: the greeting with the
    display name from the same source Settings' account-name row reads (threaded into the cover
    from `RootView+Doors.swift` as a `String?`), a line naming the routine's moment, the done-green
    glow; `.task { sleep(length); dismiss() }`; a tap anywhere (`contentShape(Rectangle())`, an
    accessibility action "Skip") dismisses early. §1/§2/§4 throughout; Light and Dark previews.
  - **`leaveScreen()` no longer ends the run** — it ends the Activity and posts the signal only; the
    background-with-everything-resolved auto-end is removed. A live fully-ticked run stays
    reopenable from the Today recovery card and expires under `RoutineRunLifecycle` like any live
    run. Every test that pins the old rule (`isFullyResolved` / `leaveScreen` / `reason: .completed`
    in `ADHD LifeOSTests/`, and the routine UI journey) is updated, and each is named in the block
    report as reversed by E's R1.
- **The streak lands on 7** — in `NudgesService.dismiss` after `replace(updated)`:
  `NudgeStreak.landsOnSeven(before:after:asOf:)`, a new pure function over the existing
  `currentRun` (`Nudges/NudgeStreak.swift:26-43`) → `request(.milestone(.streakSeven), at: nil)`.
  One listener, in the service, because both `NudgeDueCard` hosts share Today's service.
- **The daily goal** — in `HomeView`: `ringCount` (the `HomeMomentumSections.swift:86` sum, named),
  `ringSettled` (every ring input loaded once), `.onChange` of both → `DailyGoalTracker.observe` →
  the per-account day marker → `request(.milestone(.dailyGoal), at: ringOrigin)`. Home is the initial
  tab and `AppTabContent` keeps it, so this runs whichever tab is showing, about a second after the
  action (the 600 ms `DataChangeSignal` debounce plus the refetch).
- **The nine pops**, each wrapped in `CelebrationPopSource` with the pop line INSIDE the same closure
  as the site's haptic: `Tasks/TaskRow.swift:34-37/:110-120`; `Tasks/TaskDetailFormSections.swift:93-95`;
  `LifeAreaDetail/AreaTaskRow.swift:53-56`; `Home/MomentumScoreboardViews.swift:260-262`;
  `Capture/CaptureInboxSections.swift:183-189` and `:155-158`; `Capture/CaptureDetailComponents.swift:286-288`;
  `Capture/CaptureRowComponents.swift:28-54` (post-success, like its haptic); `Nudges/NudgeDueCard.swift:34-37`;
  `Places/PlaceRoutineScreen.swift:201-204`. Line numbers drift; re-read before editing.
- **The closure card's spring-in** (`Home/HomeMomentumSections.swift:22-36`):
  `.transition(reduceMotion ? .opacity : .scale(scale: 0.9).combined(with: .opacity))` and
  `withAnimation(reduceMotion ? .default : .spring(response: 0.35, dampingFraction: 0.8))` around
  the three writers of `celebratedTask` — the house pattern, `Capture/CaptureFanOverlay.swift:89-96`.

### 4. The switches and the chime

- `Home/MomentumPreferences.swift`: `celebrationsEnabled` (default true) and
  `celebrationSoundsEnabled` (default false), each the FOUR-place edit the file documents (stored
  property, memberwise default, `decodeIfPresent ?? default`, `normalized()` — an omitted place
  silently resets the field), pinned by a round-trip test through `normalized()` with both OFF.
  `Settings/AppFeedback.swift` gains `celebrationsEnabled(store:)` and `celebrationSoundsEnabled(store:)`,
  read at FIRE time. `Settings/SettingsPreferenceSections.swift:151-211` gains two Toggles after
  "Haptics" in the identical shape, ids `settingsCelebrationsToggle` / `settingsCelebrationSoundsToggle`,
  one footer sentence each. The Celebrations switch goes live on Confirm in its own block, so the row
  is never a lie.
- `Celebrations/CelebrationSound.swift`: a `CelebrationSoundPlaying` seam (plus an inert one), an
  `AVAudioPlayer` allocated ONCE from `Assets.xcassets/CelebrationChime.dataset` (`.caf` PCM),
  `.ambient` + `.mixWithOthers` re-asserted before EVERY play (the voice recorder's `.playAndRecord`
  category outlives its deactivation), never `setActive(false)`, so the user's music keeps playing
  and the silent switch is respected. Candidates: three `sox`-synthesised chimes plus one or two
  ElevenLabs sound-effect generations, peak-normalised so E compares timbre, sent with
  `SendUserFile`; E picks by ear; the pick goes into the dataset and the candidates into the block's
  evidence folder with its README.

---

## Claude Code's recommendations — for E's review, NOT decisions

Each is the default the build takes unless E changes it.

- **R-a · Discard, Skip and undo-seen never count toward inbox zero.** E named the three doing verbs
  (Sorted, Journal it, Create Task); binning the last capture is tidying, not doing.
- **R-b · The streak milestone fires at exactly 7.** Whether 14 and 21 also fire is E's call, parked.
- **R-c · Confirm counts toward the cooldown** (it stamps `lastFullScreenAt`) but is never itself
  downgraded. E's words at #6 were "no full-screen celebration has played in the last …".
- **R-d · The centre plays `.success` for the daily goal**, because no site does; every other
  milestone's haptic is the site's own, once (the single-owner rule).
- **R-e · The Create Task sheet holds 0.45 s** after a successful promote before dismissing, so its
  pop can be seen; the alternative is no pop there.
- **R-f · A routine whose only resolved steps are auto-done or skipped completes quietly:** the
  celebration needs at least one step the user tapped done (`PlaceRoutineProgress.earnedCelebration`).
- **R-g · Held full-screens drop after 60 s**, so a search surface left open for minutes does not
  release a stale daily-goal burst on close.
- **R-h · With the Celebrations switch OFF a milestone gets its fallback pop** where the site had
  none (the ring, the Completed button), and nothing extra where it already popped.

---

## The numbers

| element | value | source |
|---|---|---|
| every-Confirm / milestone celebration | glow + 120 rain + 100 cannons, **5.4 s** on screen (4.2 s choreography × the Confirm stretch) | Confirm record, #1, F8 |
| stack-clearing Confirm | + 14 fireworks + light-mode 85 % dim, **≈ 6.43 s** (5.0 s choreography / pace) | Confirm record, #1 |
| pop | 12–20 pieces, 250–450 pt/s, lives 0.7–1.0 s, drawn ≤ 1.0 s | F6 |
| still pop (Reduce Motion) | same count at rest within 48 pt, fade in 0.3 s / out over the last 0.7 s | #7 |
| still field (Reduce Motion, milestones) | 120 pieces at rest across the canvas, same envelope, 5.4 s | #7 |
| milestone cooldown | **5 s** (undecided; 30 min was proposed) | F9 |
| full-screen cap / pop cap | 3 / 8 live | Confirm record R1 |
| congratulation view | 5.4 s on a full-screen outcome, ≈ 2 s otherwise; tap to skip | R5 |
| chime | one `.caf`, `.ambient` + `.mixWithOthers`, OFF by default | F5 |
| colours | the seven confetti tokens (`AreaWorkVivid`, `AreaHealthVivid`, `AreaGrowthVivid`, `AreaHobbyVivid`, `AreaOrangeVivid`, `StateGoVivid`, `StateWarnVivid`); the glow `StateGo`; the dim `Scrim` | §4 |

## Engineering constraints — so the build cannot trip on them

- **Files at the 400-line ceiling need room FIRST, as their own commit:** `RootView.swift` 394
  (`:73-93` → `RootView+Furniture.swift`), `HomeView.swift` 399 (`:360-399` → `HomeView+Refresh.swift`),
  `HomeMomentumSections.swift` 399 (`:235-329` → `HomeLifeAreasSections.swift`),
  `CaptureInboxService.swift` 397 (`:266-310` → `CaptureInboxService+Notes.swift`),
  `PlaceRoutineScreen.swift` 379 (the Completed pieces are new files). Stored `@Published` /
  `@StateObject` properties cannot move to an extension; only methods can.
- **Single-implementation site under §7.1.** `Canvas`, `TimelineView(.animation)` (iOS 15) and
  `onGeometryChange` (back-deployed to 16.0) need no `#available`; the report's line is "no tier
  adds value". The one Reduce Motion site that is not the still model (the closure card's transition)
  is by parameter, not availability.
- **The waiver pin changes shape** with a shared layer: the Confirm physics / recipe / fireworks /
  frame files stay RM-free, and `CelebrationMotion.resolve` is pinned to return `.full` for Confirm.
- **Call-site tests that must change, each named in the block report:** the six in
  `ConfirmCelebrationCallSiteTests` that read the mount string, the listener, the hit-testing, the
  single `TimelineView`, the stretched clock and the waiver list; and every routine-record test that
  pins "leaving ends a resolved run".
- **`ordinal` did three jobs** (SwiftUI id, seed, haptic trigger) in the Confirm build; the centre's
  counter takes the first two and the service's keeps the third, so they never meet.
- **Per-frame bound:** a cleared-stack Confirm ≈ 1,130 draw ops; the cap of 3 bounds overlap at
  ≈ 3,400; eight live pops add ≤ 160 fills. E's phone is the measurement; the lever is one particle
  scale on the recipes.
- **The daily goal's ~1 s lag** is the `DataChangeSignal` debounce plus the refetch. A crossing
  detected while the Settings sheet is up draws under it and spends the day; acceptable, or add a
  `.settings` surface if E minds.
- **Sound:** `.ambient` is silenced by the ring switch (E's wish) and mixes under music; the category
  is re-asserted before each play.
- **Tokens only, 4/8/16/24 only** (§2, §4), haptics through `Theme/Haptics.swift`, prose test names,
  loud call-site guards, render probes removed before commit, evidence folders with READMEs.

## The blocks — strictly in order, each closing on E's device verdict

Every block: a written red prediction → red-checks on a committed tree → `swiftlint lint` 0 → the
full suite with the emulator up and 0 `127.0.0.1:9099` hits → the sim build → in-situ renders or a
probe → the PR → the phone from `main` → E's verdict. A Verified-paths line in every report and
README.

1. **`F-ConfirmCelebration-2`** (existing ID; #2) — the fireworks and the light-mode dim, on the
   same stretch (#1). Evidence `screenshots/confirm-celebration-block-2/`.
2. **`F-CTACelebrations-1`** — the haptic tidy and the closure card's spring-in (#8).
3. **`F-CTACelebrations-2`** — the two switches; Celebrations live on Confirm (#3, F5).
4. **`F-CTACelebrations-3`** — the centre, the shared layer, the four surfaces, Confirm re-routed.
   Device verdict: Confirm indistinguishable from today; switch off = nothing.
5. **`F-CTACelebrations-4`** — the nine pops. The pop is rendered in situ on a real `TaskRow` FIRST
   (two or three count/spread variants, full and still) and E picks by looking (F6).
6. **`F-CTACelebrations-5`** — inbox zero, the streak on 7, the daily goal (F3, F7).
7. **`F-CTACelebrations-6`** — the routine Completed flow (R1–R5). The congratulation view is
   rendered (light, dark, Reduce Motion, the switch-off beat) and sent BEFORE wiring.
8. **`F-CTACelebrations-7`** — the chime (F5); E picks by ear.

After the arc: **`F-FocusCard-Corners`** (round the collapsed card's bottom corners and give
`roundsBottomCorners` `animatableData`). Parked in §C: the nudge-specific "Done for now" animation
(F4); 14/21-day streaks (R-b).

## The verification bar, per block

The standard bar: `swiftlint lint` 0; the full unit suite with the emulator up and 0 `9099` hits,
the count matching a written prediction; the sim build; red-checks on a committed tree; the PR and
the four-line close-out; the phone installed from `main`; the evidence folder with its README.

The **Verified paths** line (§7.3) for this arc's single-implementation sites: *runs the same code
on every OS ≥ 16.0; run on the 26.5 simulator and on E's phone; its behaviour on a 16–25 OS is
COMPILE-ONLY — no older runtime installed (E will install one "in a number of days").*

# Design record — the collapsible focus sprint card and its completion confirmation

*This is the design record and the why. It is PERMANENT — never archive it (CLAUDE.md, "Session
handoff": `SESSION-OPENER-*` files are records despite the name). Written 2026-09-09 from E's
annotated screenshot `IMG_8307.jpg` and the design conversation that settled every open question
in it. The arc is `F-FocusCard-1` … `F-FocusCard-5`.*

**Everything in "The settled specification" was answered directly by E. Do not re-litigate any of
it without E.** Where a line says "E chose", E was shown the alternatives and picked.

## Postscript — what shipped differently (added at the arc's close, 2026-09-11)

The arc is CLOSED: all five blocks merged, blocks 1–4 each verified by E on device. **Blocks 1–4
each moved against the specification below, always on E's word and always by looking at the
device.** Read the specification with this table beside it; the specification stays as written
because it is the record of what was asked, and this is the record of what was chosen instead.

| the record says | what actually shipped | who / when |
|---|---|---|
| collapsed card full-bleed to both screen edges | **inset 16pt** (361pt wide), 60pt tall — same inset as expanded, so collapsing changes height only | E, device, 2026-09-09 |
| collapsed card has a chevron | **gone** collapsed; kept expanded | E, 2026-09-09 |
| long-press opens the detail sheet | **single TAP**, in both states; long-press RETIRED | E, 2026-09-09 |
| completion card shares the "full-bleed flush geometry" | **it floats** — inset 16, radius 24, all four corners, 76pt tall | E chose from three, 2026-09-09 |
| Confirm resets collapse | **only when NO sprint is running** | E chose from three rules, 2026-09-09 |
| the stack's peek is 8pt | **14pt** — deliberately OFF §2's grid; CLAUDE.md §2 carries the waiver | E chose from six renders, 2026-09-10 |
| celebration tick is `checkmark.circle.fill` | the ring's existing bare `checkmark`, springing from 0.6 — so the resting card stays the block-2 card E approved | Claude Code, E accepted on device 2026-09-11 |
| (unstated) | the burst and haptic wait **0.3s** for the card to land; the pre-beat is a complete ring with no tick | E: "the pre-beat reads fine", 2026-09-11 |
| "iOS 16 is the floor, which rules out … `.symbolEffect`"; "under Reduce Motion render the FINAL state" | **a 16 / Reduce Motion cross-fade / iOS 26 draw-on ladder** (`F-ModernIOS-2-Celebration`): below 26 the burst above, unchanged; under Reduce Motion the celebration opens with geometry at rest (halo at 1.6, tick at 1) and FADES, where it used to open settled, the hard cut E lived with; on iOS 26 the tick draws itself on (`.drawOn`), whose stroke turned out not to wait for the 0.3s delay | E, 2026-09-11 (CLAUDE.md §7); device verdicts pending |

Two names in block 4's section below did not exist when it was written and were created as
specified: `confirmableCompletionCount` (the haptic's trigger) and, beside it, the record id the
burst keys on — both derived from one stamp, `latestConfirmableCompletion`, written by the push
alone.

---

## What prompted it

The app-wide focus sprint card (`ADHD LifeOS/Focus/FocusTimerBar.swift`) is one fixed
presentation: a 16pt-inset rounded card carrying a 64pt progress ring, the sprint name, a
checkpoint line and four action buttons (Pause / +30s / +5m / Stop). It is always that size, so an
active sprint permanently occupies a substantial band above the tab bar **on every screen**.

E's screenshot (`../Ethan's Screenshot Folder/IMG_8307.jpg`, the Journal tab with a sprint
running) carries three green arrows pointing downward "to symbolise the collapsing of the sprint
session element", and a full-screen-width black box drawn over the action row as "ONLY A ROUGH
EXAMPLE of the sizing of the new collapsed-sprint-session card".

E's own framing of the requirement: *"The user must be able to collapse and expand a sprint session
card however they choose, starting in expanded state and the ability to swipe up and down to switch
between the 2 different states... In the collapsed state the card must still contain: 1. The
progress circle 2. The Sprint sessions name 3. The PAUSE button 4. The full-screen-width card
sizing is important."*

Two features came out of the conversation, tied by one rule:

1. **A collapsed state**, so a running sprint can get out of the way without being abandoned.
2. **A completion confirmation**, so a finished sprint is *verified by the user* rather than
   silently banked.

The tie, in E's words: the card stays collapsed *"until the user has tapped the final, and new,
'Confirmed' button"*. Collapse memory does not expire on a tab switch or a relaunch — it expires on
confirmation.

---

## The settled specification

### State 1 — running, expanded
Today's card, content unchanged. **Every sprint starts here.**

### State 2 — running, collapsed (NEW)
Contains **exactly three things**: the progress ring, the sprint name, the Pause button.
`+30s`, `+5m` and `Stop` are **expanded-only** (E chose "Gone — expand to reach them" over keeping
Stop and over cramming all four in).

**Geometry: full-bleed to both screen edges, rounded TOP corners only, dropped FLUSH onto the tab
bar.** E chose full-bleed-with-rounded-top over a plain inset and over a squared-off strip. Then,
told that top-only rounding 100pt above the screen bottom would leave the square bottom corners
hanging in mid-air, E chose **"Drop it flush to the tab bar"** — the collapsed card loses the 32pt
`gapAboveTabBar` so its bottom corners meet the bar. The expanded card keeps its 16pt inset, its
24pt all-corner radius and the normal lift.

### Toggling — all four affordances
E was asked what should toggle it besides the swipe and selected three of the four offered:

- swipe up (expand) / down (collapse) — **down collapses**, per the screenshot's arrows
- **tap anywhere on the card body**
- **the chevron** — today a decorative `Image` at `FocusTimerBar.swift:59`, not a control at all;
  it becomes a real button that flips direction with the state
- **a grabber / drag handle** at the top of the card

### Long-press opens the full sprint view
Tap-to-collapse takes over the gesture that is currently the app's **only** door to
`FocusSprintDetailView` (379 lines, plus `FocusCadenceEditorCard` and `FocusSprintTimelineCard`).
Offered a Details button, a long-press, tapping the ring, or orphaning the view, **E chose the
long-press.**

### Collapse memory
Survives tab switches, backgrounding and app relaunch. Cleared **only** by Confirm.

### State 3 — completed, unconfirmed (NEW)
E: *"Full ring + name + time done + Confirm + a celebratory screen animation to signify
completion."*

### Only a NATURAL completion produces a card
A manual Stop ends the sprint outright with no card. **E chose this knowing the stated
consequence:** after a manual Stop nothing resets collapse, so the card stays collapsed into the
next sprint until expanded by hand.

### Logging — provisional, then finalised
E chose "Logged provisionally, Confirm finalises it" over logging at completion and over logging
only on Confirm. The record is written when the timer ends, so nothing is lost if the user never
confirms, but it is distinguishable from a confirmed one until they act.

### Stacking
E raised this themselves, thinking about a location-triggered Routine that auto-starts a sprint:
*"If the user already has an unconfirmed AND completed sprint then possibly a stack could be used
here to stack the 'unconfirmed' notification cards."*

- **A new sprint may start while unconfirmed cards exist.** E chose "Both show — new sprint runs".
  Nothing is blocked; nothing is auto-confirmed. A routine firing must never be silently dropped
  because the user had not tidied up.
- **Presentation: iOS-notification style** — newest in front, older ones peeking behind as edges,
  confirming the top one reveals the next.
- **No "confirm all".** E chose one at a time deliberately, so confirmation keeps meaning "I looked
  at this".

### Explicitly out of scope — `OfflineSprintSummaryCard`
E: *"I'm unsure that the 'OfflineSprintSummaryCard' functions properly, I haven't seen it in my
active usage of the app. I would recommend to keep them separate. If there is an issue needing
fixing... unless it ties into this block - I'd suggest queue it."*

**Why E has never seen it, established in this session:** it only fires from
`restorePersistedSprint()` (`FocusSessionService+Persistence.swift:16-60`) — the app must have been
fully killed while a sprint expired, then relaunched. A sprint completing in a live app never
reaches that path. It is not broken so much as **nearly unreachable in normal use**.

It already does *log the record and hold a card until acknowledged* — the same shape as the new
Confirm, on the app-dead path only. **Collision to document, not fix:** it shares
`RootBottomOverlay`'s VStack, so an old unacknowledged offline completion and a new unconfirmed
sprint can be on screen together in two different visual languages.

---

## Architectural decisions, with the reasons that forced them

**Collapse state lives on `FocusSessionService`, persisted through the existing
`FocusSprintPersisting` seam** — not `@AppStorage`, not a new `RootView` `@StateObject`.

- `RootView.swift` is at **399 of 400 lines**, and `@StateObject` cannot live in an extension file,
  so the `TabBarScrollActivity`-on-RootView pattern is simply unavailable.
- Confirm resets collapse, and Confirm is a service operation. On the service that is one line in
  the same method; anywhere else it is a cross-object callback.
- `FocusTimerBar` already `@ObservedObject`s the service, so the "pass a plain `Bool` down" rule
  does not apply — that rule exists for leaves that do *not* observe the model.
- The per-device caveat at `HomeView.swift:70` does **not** bite here, and the doc comment should
  say so to stop it being re-litigated: that warning is about an *account-scoped fact*, where a
  wrong answer changes what content a user sees. Collapse is device furniture posture, and the
  sprint it decorates is already per-device UserDefaults under `focus.sprint.running`.
- **Do NOT copy `RootView.swift:199-202`'s `reset()`-on-tab-change wiring.** Surviving a tab switch
  is the requirement; that is the one thing `TabBarScrollActivity` does that must not be imitated.

**Finalise is a RE-SAVE, not a partial update.** `FirebaseManager.save(_:id:in:)`
(`ADHD LifeOS/Firebase/FirebaseManager.swift:326-330`) is `setData` with no merge — a full upsert
keyed on `id.uuidString`. So `confirmCompletion` just calls the existing
`log(record.confirmed(at:))`. **This matters for correctness, not economy:** if the provisional
write failed (offline — `log` swallows into `logErrorMessage` and the card still shows), a partial
`update` on a nonexistent document would throw, whereas the re-save creates it. Consequences: no
`FocusSessionBackingStore` growth, no `FirestoreFieldPayloads` entry, no new adapter method, and no
new adapter coverage debt.

**Firestore rules need NO change and nothing for E to republish** — verified this session:
`focus_sessions` sits in the generic `match /{collection}/{docId}` block whose
`allow read, write: if isOwner(uid)` already covers create/update/delete. **Say this in the block
report** rather than leaving E wondering.

**Analytics deliberately do NOT filter on the new field.** `FocusAnalytics`, `FocusLoggedToday` and
`FocusWidgetSnapshotBuilder` keep counting every record. Banked time is banked; the confirmation is
a UI acknowledgement, not a data gate. This is what keeps the field inert to every existing reader
and every historic record correct — put it in the field's doc comment.

**A new persistence key, never a migration.** The stack uses
`"focus.sprint.unconfirmedCompletions"`; it never reads, writes or migrates
`"focus.sprint.unacknowledgedCompletion"`, which belongs to the out-of-scope offline flow. Two
keys, two published properties, two cards, zero interaction — a migration would be exactly the
refactor E ruled out.

**`FocusTimerBar.swift` is 250 lines and will blow the 400 ceiling — split preemptively in Block
1**, not reactively when lint fails, following the `FocusSessionService+Persistence` precedent.

---

## The blocks — strictly sequential, E reviews each on device

### F-FocusCard-1 — the collapsed running card and its four toggles

**Create** `Focus/FocusBarCollapse.swift`, `Focus/FocusTimerBarContent.swift`,
`ADHD LifeOSTests/FocusBarCollapseTests.swift`,
`ADHD LifeOSTests/FocusBarCollapseCallSiteTests.swift`.

**Modify** `Focus/FocusTimerBar.swift`, `Focus/FocusSessionService.swift`,
`Focus/FocusSessionService+Persistence.swift`, `Focus/FocusSprintPersistence.swift`, and **both**
recording fakes — `FocusSprintPersistenceTests.swift:27-46` and `FocusLocationStampTests.swift`.
Both conform to `FocusSprintPersisting`, so widening the protocol breaks the whole test target's
compile until both are updated. **That compile break is the red step, not a bug.**

**Pure types** in `FocusBarCollapse.swift`:

- `FocusBarCollapseSwipe` — `threshold: CGFloat = 24`, `enum Outcome { collapse, expand, none }`,
  `outcome(forTranslation:isCollapsed:)`. **Direction-aware, not a toggle**: a downward swipe on an
  already-collapsed card is `.none`. Positive `translation.height` is downward in SwiftUI, and
  down collapses.
- `FocusBarCardShape: Shape, InsettableShape` — `cornerRadius`, `roundsBottomCorners`, and
  `inset(by:)` storing `insetAmount`, shrinking rect *and* radius. **`InsettableShape` is required**
  so the existing `.overlay(shape.strokeBorder(...))` at `FocusTimerBar.swift:119-122` survives
  as-is and the 1pt border stays inside the bounds rather than half outside.
- `FocusBarMetrics` — `expandedInset = 16`, `cornerRadius = 24`, `grabberWidth = 36`,
  `grabberHeight = 5`, and the flush-drop pair **derived, never hard-coded**:
  `expandedBottomLift = AppSearchRowMetrics.bottomFurnitureLift` (100),
  `collapsedBottomLift = AppTabBarMetrics.rowHeight` (68),
  `collapsedDrop = -(AppSearchRowMetrics.gapAboveTabBar)` (−32).
  Off-grid component dimensions belong in a named `*Metrics` enum with why-comments — the
  `CaptureDiscMetrics` / `AppTabBarMetrics` house rule. §2's 4/8/16/24 grid governs SPACING only.

**View changes in `FocusTimerBar.swift`:**

- `isCollapsed` reads `service.isCardCollapsed`; `toggleCollapse()` flips it and plays
  `Haptics.play(.light)` — the sanctioned expand/collapse feel, precedent
  `Theme/CollapsibleSectionHeader.swift:48`. Note `Haptics.swift:13-14` deliberately EXCLUDES
  scroll-driven morphs from haptics; this is a deliberate tap, so it qualifies.
- Collapsed body: grabber, then `HStack(spacing: 8)` of ring + name + `Spacer` + Pause. No `+30s`,
  no `+5m`, no `Stop`, no checkpoint banner.
- Grabber: `Capsule().fill(Color(.tertiaryLabel))` at `grabberWidth × grabberHeight`, wrapped in a
  `Button` with `.frame(minHeight: 44)` and `.contentShape(Rectangle())` for §3's touch floor.
  Present in **both** states. Id `focusBarGrabber`.
- The chevron at `:59` becomes a real `Button`, `chevron.up` / `chevron.down`, id `focusBarExpand`
  (safe to repurpose — **no test anywhere references it**, verified across both test targets), with
  a flipping `.accessibilityLabel`.
- `.onTapGesture { toggleCollapse() }` on the card; `.onLongPressGesture` opens the detail sheet.
- **The swipe MUST be `.simultaneousGesture(DragGesture(minimumDistance: 12))`.** A plain
  `.gesture` swallows the Pause button's taps — the likeliest way to ship a collapsed card whose
  only remaining control is dead.
- Modifier chain: `.padding(.horizontal, isCollapsed ? 0 : FocusBarMetrics.expandedInset)`,
  `.frame(maxWidth: .infinity)`, and `FocusBarCardShape(cornerRadius: 24,
  roundsBottomCorners: !isCollapsed)` in **both** `.background` and `.overlay`, plus a new
  `.animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8),
  value: service.isCardCollapsed)` beside the existing `value: session.isPaused`.
- **The flush drop uses `.offset(y:)`, NOT negative padding.** `RootBottomOverlay`'s VStack pads its
  bottom by `bottomFurnitureLift` (`:93`) and `FocusTimerBar` is its LAST child; negative bottom
  padding there shrinks the stack, which drags the search row and capture disc down 32pt too.
  `.offset` moves rendering *and* hit-testing without touching layout.

**Service / persistence:** `@Published private(set) var isCardCollapsed = false` plus
`setCardCollapsed(_:)`; protocol gains `readCardCollapsed()` / `writeCardCollapsed(_:)`; the store
gains `cardCollapsedKey = "focus.card.collapsed"`.
**The collapse read must sit ABOVE the `guard session == nil, let saved = sprintStore.read()` at
`+Persistence.swift:21`**, beside the `offlineCompletionSummary` read at `:18-20` — below it,
collapse silently fails to restore whenever no sprint is stored.

**Tests first — and what each reads on the BROKEN build:**

| test | broken-build reading |
|---|---|
| `testSwipeDownCollapsesOnlyPastTheThreshold` | returns `.none` where `.collapse` is required |
| `testSwipeIsDirectionAwareNotAToggle` | `(+40, isCollapsed: true)` returns `.expand` — **the test a naive `toggle()` fails** |
| `testCardShapeRoundsOnlyTheTopWhenCollapsed` | assert `contains(1,99) == true` AND `contains(1,1) == false`; a `RoundedRectangle` fails the first, a `Rectangle` the second — **nothing passes both by accident** |
| `testCardShapeRoundsAllFourWhenExpanded` | proves the flag branches rather than being ignored |
| `testInsetShrinksTheShape` | fails if `inset(by:)` returns `self`, the plausible stub |
| `testCollapsedCardSitsFlushOnTheTabBar` | assert `collapsedBottomLift == AppTabBarMetrics.rowHeight` and `collapsedDrop == -gapAboveTabBar`, **derived** — a hard-coded 68 passes while the real relationship rots |
| `testCollapseIsPersistedAndRestored` | a *second* service over the same fake reads `true`; fails if collapse is `@State` or an unpersisted `@Published` |
| `testCollapseSurvivesWithNoSprintStored` | guards the `+Persistence.swift:21` ordering trap |

**Call-site test** (`CaptureDiscPillCallSiteTests` mould — reads the source text, because this
repo's most repeated defect is a correct, tested, *unused* helper). `FocusTimerBar.swift` must
contain `service.isCardCollapsed`, `FocusBarCardShape(`, `FocusBarCollapseSwipe.outcome`,
`simultaneousGesture`, the conditional horizontal padding, and **still** `FocusSprintDetailView(`
— the orphan guard — while **not** containing `RoundedRectangle(cornerRadius: 24`.

**Traps.** Long-press and tap must not fight (give the long-press a `minimumDuration`, keep the tap
a plain `.onTapGesture`). **Block 1 alone has sticky collapse with no reset** — the reset arrives in
Block 2. Say so in the block report and tell E to expect it; do NOT add a temporary escape hatch
that Block 2 then deletes.

### F-FocusCard-2 — provisional record + the completed-unconfirmed card

**Create** `Focus/FocusCompletionCard.swift`, `Focus/FocusSessionService+Completions.swift`, tests
`FocusCompletionRecordTests`, `FocusCompletionStackServiceTests`, `FocusCompletionCallSiteTests`.
**Modify** `Focus/FocusModels.swift`, `Focus/FocusSessionService.swift`,
`Focus/FocusSprintPersistence.swift`, `RootBottomOverlay.swift`, both fakes again.

- `CompletedFocusSession` gains `var confirmedAt: Date?` (`case confirmedAt = "confirmed_at"`),
  `isProvisional`, and `confirmed(at:)` mirroring `stamped(with:)` at `FocusModels.swift:152`.
- Service gains `unconfirmedCompletions: [CompletedFocusSession]` (newest-first via
  `insert(at: 0)`, so "newest in front" reads as `.first` and stack depth is the array index),
  `pushUnconfirmedCompletion`, `confirmCompletion(_:)` (remove → persist → `setCardCollapsed(false)`
  → `await log(confirmed)`), `restoreUnconfirmedCompletions()`.
- **The push happens synchronously BEFORE `await log(...)`** at `FocusSessionService.swift:206`, so
  the card is on screen and persisted even if the Firestore write hangs.
- `FocusCompletionCard` renders `unconfirmedCompletions.first`, same full-bleed flush geometry,
  `ClosureRing(progress: 1, ...)`, and **`FocusTimeFormatting.human(seconds:)` NOT
  `duration(seconds:)`** — `duration` drops seconds, so a `+30s` sprint would read "25m" when
  25m 30s was banked.
- Placed **above** `FocusTimerBar` in the VStack, so the running card keeps its established
  position and stays operable — a card behind another cannot be paused.

**Tests first:** `testLegacyRecordDecodesAsProvisional` (decode a literal legacy JSON payload with
no `confirmed_at` — guards against anyone making the property non-optional and rendering **all
existing history undecodable**); `testConfirmedAtRoundTripsUnderItsSnakeCaseKey` (assert
`"confirmed_at"` present **and `"confirmedAt"` absent** — the house convention, and the only thing
that catches a missing `CodingKeys` line); **`testManualStopPushesNothing`** (**the discriminator
for the whole feature** — an implementation pushing on every `finishCurrentSprint` passes the
natural-completion test and fails this one); `testStartingAReplacementSprintPushesNothing` (guards
the `:109` replacement path); `testThePushLandsBeforeTheLogAwait` (fake logger suspends forever;
the card must already exist — an ordering bug invisible to every other test);
`testConfirmRemovesRePersistsAndLogsAConfirmedCopy` (**same `id`** — proves an upsert, not a
duplicate row — with `placeId`/lat/long preserved); `testConfirmResetsCollapse`;
`testUnconfirmedStackSurvivesRelaunch`; `testTheNewKeyNeverTouchesTheOldOne` (**both directions** —
one alone passes on a merged implementation).

**Traps:** `RootBottomOverlay.swift:94-97` animates on `isActive` only — add a second
`.animation(..., value: unconfirmedCompletions.count)` or the running card's exit and the
completion card's entrance will not be choreographed. `save` posts `DataChangeSignal.post()`, so
Confirm fires a second signal per sprint (new in count, not in kind) — mention it in the report.

### F-FocusCard-3 — the notification-style stack

`Focus/FocusCompletionCardStack.swift` + `FocusCompletionStackLayout` (`maxVisible = 3`,
`isVisible`, `yOffset`, `scale`, `opacity`). No data cap — no auto-confirm, ever — but only three
layers draw.

Tests: front card unoffset / full-scale / opaque (a sign-flip here is the classic bug); deeper
cards peek with **strict** inequalities (a constant stub passes non-strict ones); only three layers
render; **`yOffset(1) < 0`** pins the peek direction so it cannot ship upside-down, which no other
assertion catches; service-level `testConfirmingTheFrontRevealsTheNext` asserting **the logger
received B's confirmed copy, not A's** — which discriminates "removed the right one" from "removed
one"; and a call-site guard that **no `confirmAll` / `removeAll` exists**, because E ruled that out
explicitly.

**Traps:** `ZStack` render order — get it wrong and the *oldest* card is in front, which every
layout test still passes. Keep `id: \.id` stable so insert/remove animates rather than reshuffles.
Cards behind must be `.accessibilityHidden(true)` and non-hit-testable, or VoiceOver reads three
Confirm buttons.

### F-FocusCard-4 — the celebration

`Focus/FocusCompletionCelebration.swift` + `FocusCompletionCelebrationMetrics`. **iOS 16 is the
floor**, which rules out `PhaseAnimator`, `.symbolEffect`, `.keyframeAnimator` and
`.sensoryFeedback` — use the existing `#available`-split `.haptic(_:trigger:)` from
`Theme/Haptics.swift:113-127`.

A two-part burst in the app's existing celebration grammar (`ClosureCelebrationCard`,
`Home/MomentumScoreboardViews.swift:305-357`, and `OfflineSprintSummaryCard`): a radiating
`Circle().stroke` scaling 1 → 1.6 while fading 0.8 → 0 on a long `.easeOut`, plus a
`checkmark.circle.fill` in `Color("StateGo")` springing in from `.scaleEffect(0.6)`.

**Under Reduce Motion render the FINAL state** (checkmark present, no pulse) — never the
pre-animation state, the trap that makes reduce-motion paths look broken.

**The haptic triggers on `confirmableCompletionCount`** — NOT `completedSprintCount`
(`FocusSessionService.swift:30`, bumped on manual stops too) and NOT
`unconfirmedCompletions.count` (which changes on confirm-removal, so it would buzz on dismissal).
Key the burst to the record id so a card revealed by a Confirm does not re-celebrate.

**Evidence is `screenshots/focus-completion-celebration/` with the mandatory README**, not the unit
test. A test over a `reduceMotion ? nil : .easeOut(...)` ternary is near-vacuous, and CLAUDE.md's
rule is that a folder is earned by exactly what a test cannot assert. **The block is not done
without it.**

### F-FocusCard-5 — close-out

Correct `FocusTimerBar.swift:8-25` (its header still says the sheet opens "by tapping the bar's
task row"), `FocusSessionBackingStore.swift`'s "append-only in practice" comment (now false —
records are re-saved on confirm), the `FocusSprintPersistence` protocol doc,
`TODO-CLAUDE-CODE.md` and `handoff/OPEN-ITEMS-REGISTER.md`. Record the `OfflineSprintSummaryCard`
collision as documented and deliberately unfixed.

---

## Verification bar, per block

CLAUDE.md's bar, in full — no block is done without all of it:

1. **Watch the test fail first.** Read the `Executed N tests, with M failures` line; never
   `grep -c 'Test Case.*failed'`, which counts eight test NAMES containing the word.
2. `swiftlint lint` — 0 violations across the tree.
3. Full unit suite, emulator up (`./scripts/emulators.sh`):
   `xcodebuild test -project "ADHD LifeOS.xcodeproj" -scheme "ADHD LifeOS" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -skip-testing:"ADHD LifeOSUITests" -enableCodeCoverage YES -resultBundlePath TestResults.xcresult`
   then `xcrun xccov view --report TestResults.xcresult`, and **delete the bundle after reading**.
4. `xcodebuild build` for the simulator.
5. **Commit, THEN red-check one regression at a time**, predicting the failure count before
   running; restore with `git checkout --` and prove it by re-running.
6. **Device build and install on E's phone.** This arc is almost entirely visual, so E's verdict is
   the real evidence.
7. Land through a PR, then verify `origin/main` actually contains the work.

**Blocks 1–3 want a UI journey where one is reachable** — but the collapsed/expanded morph may be
invisible to XCUITest the way the capture disc's pill is (its outer frame is 60×60 in both states
by design). If so, E's device verdict IS the record, and the block report must say so rather than
shipping a vacuous journey.

**Erase the simulator between any UI run and the next unit run** —
`xcrun simctl erase 9181EBF9-0F54-4A4D-A19C-19945D1BF155` — chained unconditionally after the UI
run, never conditionally on the next suite seeming slow.

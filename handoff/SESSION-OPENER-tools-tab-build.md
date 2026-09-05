# Session opener — BUILDING the Tools tab (four blocks)

*Written 2026-09-02. This is the block-by-block build plan and it is meant to be self-contained —
work through it top to bottom. The design rationale, the six concepts E chose from, and the full
decision record are in `SESSION-OPENER-tools-tab.md` and the canvas at
`https://claude.ai/code/artifact/767eacff-e616-4836-ab3a-ac842ddf42c9`; read those only if you
need the WHY behind a decision below.*

Read `claudecode.md` and `CLAUDE.md` first, plus auto-memories `tools-tab-and-custom-bar`,
`capture-disc-design`, `dead-shared-component-pattern`, `never-destroy-uncommitted-work`.

**A note on ownership.** These four blocks are written here, OUTSIDE the repo, because
`TODO-CLAUDE-CODE.md` is Cowork-owned and Claude Code only ticks its checkboxes. If E wants them
tracked there, E either has Cowork transcribe them or explicitly authorises Claude Code to add
them — do not add them unasked.

---

## Start here

```bash
git status --short            # must be empty
git log --oneline -1          # expect efd72af (the app-directory merge)
git checkout -b feature/tools-tab main
```

`main` is the only branch that exists — `feature/app-directory` and the stale
`claude/test-coverage-analysis-hu9auv` are both deleted. State at handoff: suite **2,100 / 0**
(56 skipped = emulator suites, by design), SwiftLint **0 / 606 files**, sim + device builds green,
E's phone on `efd72af` from main.

## Standing rules (they bit this project; they will bit you)

- **TDD.** Failing test FIRST for every piece of new pure logic. SwiftUI view bodies are not
  unit-testable here (~0% by design) — push every testable rule into a pure type, the way
  `PlaceAppPickerPresentation` does. Each block below names its pure-logic targets.
- **Commit BEFORE any deliberate-regression red-check**, restore with `git checkout --`, and prove
  the restore by REBUILDING.
- **Never `&&` a commit onto a piped build** — `| tail` masks the exit code.
- **Never pipe a long `xcodebuild` through `grep`.** It buffers; you cannot tell progress from a
  hang. Redirect to a log file and grep the file.
- **A crawling suite means a poisoned simulator**, not slow tests: host alive at ~0.1% CPU,
  nothing written into the `.xcresult` for 90s. `xcrun simctl erase <udid>` fixes it; rebooting
  does not. A healthy full run is **~5 seconds for ~2,100 tests**.
- **`swiftlint lint` must be 0 violations.** Watch `file_length` (400) and `type_body_length`
  (250). **`RootView.swift` is ~397 lines before you add anything — plan to split it in block 1.**
- Every block ends with a landed commit AND push, verified by pasting `git status --short`,
  `git log --oneline -1`, and `git log --oneline -1 origin/feature/tools-tab` showing the SAME SHA.
- **Never script an auth flow.** Need a signed-in session? Stop and ask E.
- Device `wishwashwacky15`, id `3DBC979A-3255-5456-8C30-172DB19B99B3`:
  `xcodebuild build -destination 'platform=iOS,id=<id>' -allowProvisioningUpdates
  -derivedDataPath <scratch>` → `devicectl device install app` → `devicectl device process launch`.
  Scratch derivedDataPath so the device build doesn't churn the simulator's.
- **Report the §7 conflict in every build report:** `ui-ux-pro-max` rates "bottom nav ≤5" HIGH
  severity with "overloaded nav" as an anti-pattern. **E was shown this and chose six knowingly.**
  Say so; never silently comply or silently ignore.

---

# BLOCK 1 — `F-Tools-1-Bar`: six slots, resting state only

**Goal.** Replace the system tab bar with a custom six-item bar in its RESTING state only
(Design F: full width, icons only, an accent dot under the selected icon). No motion yet.

**Why resting-only first:** E should judge whether six slots feel right on a real screen before
any morph logic exists to confuse the verdict.

### Files

- `RootView.swift` — add `.tools` to `AppTab`; **rewrite the enum's doc comment** (it still
  asserts *"Five stays five … a sixth would bury one of these"*, a decision E has reversed);
  hide the system bar; add the custom bar via `.safeAreaInset(edge: .bottom)`; **delete
  `minimizesTabBarOnScrollDown()` and its `View` extension** (superseded — see block 2).
- NEW `ADHD LifeOS/Theme/AppTabBar.swift` — the bar view.
- NEW `ADHD LifeOS/Theme/AppTabBarPresentation.swift` — the pure rules.
- NEW `ADHD LifeOS/Tools/ToolsView.swift` — a deliberately empty stub with the nav title. Block 3
  fills it. Do not build the page here.
- `Places/PlaceActionExecution.swift` — confirm the `appTab` switch still compiles exhaustively.

### Architecture (settled — do not redesign)

Keep `TabView` for content, hide only its bar, add yours in a `safeAreaInset`:

```
TabView(selection: $selectedTab) { …six tabs… }
    // .toolbar(.hidden, for: .tabBar) generally has to go on the views INSIDE the TabView
    .safeAreaInset(edge: .bottom) { AppTabBar(...) }
```

**Do NOT replace `TabView` with `switch selectedTab`** — that rebuilds the view on every switch
and discards each tab's scroll position and `NavigationStack` depth. A `ZStack` preserves state
but renders all six at once. `TabView` + hidden bar is the only shape keeping laziness AND state.

### Pure logic to test (write these tests first)

In `AppTabBarPresentation`:
- `tabs` — the six in order (today, tasks, areas, journal, captures, tools), each with label and
  SF Symbol. Pin the ORDER and that Tools is last with `wrench.and.screwdriver`.
- `showsBadge(count:)` — `false` for 0, `true` above it. **Pin that 0 shows nothing**: an empty
  inbox must stay silent rather than display a zero.
- `slotWidth(barWidth:count:)` — and a test that six slots on the NARROWEST supported iPhone
  (375pt, iPhone SE) still clear the 44pt floor (62.5pt — it does). This is the test that stops a
  seventh tab being added casually later.

### Acceptance

- [ ] Six tabs render, Tools last with the wrench glyph.
- [ ] **The system bar is genuinely GONE, not merely covered** — a covered bar still eats touches.
      Verify by tapping where it used to be and confirming your bar receives it.
- [ ] Captures badge renders; a count of 0 renders nothing.
- [ ] **A failed inbox refresh keeps the LAST KNOWN count** rather than dropping to zero — this
      behaviour exists today via `.badge()`; do not lose it. ("Never having looked ≠ nothing there.")
- [ ] The tab-change haptic still fires, including on a programmatic switch.
- [ ] A place-action `openScreen` door still switches tabs (`PlaceActionScreen.appTab`).
- [ ] The capture disc is visually unchanged and still reachable.
- [ ] Compiles at the iOS 16.0 floor; any 17+ API is `#available`-gated.
- [ ] `RootView.swift` under 400 lines (split it if not).

### Then

Commit, push, install to device, and **ask E whether six slots feel right before starting
block 2.** This is the natural stop point.

---

# BLOCK 2 — `F-Tools-2-Morph`: the momentary scroll signal and Design B

**Goal.** The bar morphs to Design B (a floating card) while the page is actually moving, and
back to F when motion settles. The selected indicator morphs with it: **dot → tinted chip.**

**Design B, precisely:** inset 12pt left/right, lifted ~22pt off the bottom, 22pt corner radius,
`CardSurface` fill, 1pt `CardBorder` stroke, soft shadow, icons only, no dot. The selected icon
sits in a tinted chip (accent at ~12% light / ~20% dark) on a 44×34 rounded rect.

### The two findings that decide this block

**1. You cannot reuse `CaptureDiscScrollActivity`.** It is directional and **STICKY by
construction** — E's 2026-08-31 verdict was *"stay in pill form until the page is scrolled
upwards again"*, and the file states outright that nothing runs on a timer. It cannot express
"momentary". **Write a second model (`TabBarScrollActivity`). Never edit the disc's** — that
behaviour is settled and `capture-disc-design` says do not re-litigate it.

**2. `CaptureDiscPanObserver.installOnKeyWindow` is idempotent via `guard shared == nil` — the
FIRST install's callbacks win.** So a second consumer CANNOT simply call install again; it would
silently no-op. `RootView` already owns the single install, so **make its existing callbacks feed
BOTH models** (`discScrollActivity` and the new `tabBarScrollActivity`) rather than installing a
second recogniser. Getting this wrong fails silently — the bar just never moves.

### THE RISK — solve this first: momentum

A `UIPanGestureRecognizer` tracks **the finger, not the page**, and the observer deliberately does
not forward terminal states (`.ended`/`.cancelled`). After the user lifts, the scroll view keeps
gliding while **nothing reports movement** — so a naive momentary signal snaps the bar back to F
*while the page is still visibly scrolling*, which is precisely the wrong moment.

Approaches, in the order worth trying:

1. **A settle timer restarted on every `dragMoved`** (~250–350ms). The bar stays in B through the
   lift and most of the deceleration. Cheapest, touches no shared component, tunable. **Start here.**
2. Forward terminal states from the observer too — but that edits a component the disc depends on.
   If you do, leave the disc's model reading exactly what it reads today.
3. Observe real scroll offsets per screen — accurate, and exactly the per-screen drift the
   clearance work already stamped out. **Avoid.**

**The settle constant is a guess until E sees it.** Ship it as one named constant, say so in the
report, and expect a round of tuning.

### Pure logic to test (write these first)

In `TabBarScrollActivity`:
- `dragMoved` sets `isMoving` true.
- After `settleInterval` with no further movement, `isMoving` returns to false.
- A further `dragMoved` inside the interval RESTARTS it (does not let it fire early).
- `reset()` returns to false immediately — RootView calls it on tab change, same reason the disc
  does: a bar stuck mid-morph on a screen the user never scrolled reads as a bug.
- `settleInterval` is a named constant, not a literal at the call site.

Use an injected clock/scheduler so the timer is testable without real waiting.

### Acceptance

- [ ] Scrolling morphs the bar F → B; settling morphs it back.
- [ ] The indicator morphs dot → chip with the container.
- [ ] Animated with the house spring `.spring(response: 0.35, dampingFraction: 0.8,
      blendDuration: 0)` (§5), and **Reduce Motion is respected**.
- [ ] The capture disc still does its own sticky disc↔pill thing, **unchanged** — the two are
      deliberately no longer in lockstep, which is the trade E accepted when choosing momentary.
- [ ] Switching tabs resets the bar to F.
- [ ] The badge survives the morph in both states.

### Then

Commit, push, install. **Ask E two things on device:** does the settle timing feel right, and
does the floating bar sit correctly against the capture disc? E's standing answer on the disc's
clearance is *"show me on device, then decide"* — so change **no** clearance numbers until E has
looked. `CaptureDiscMetrics.clearance` is computed from the disc, not the bar, so it may need
nothing at all.

---

# BLOCK 3 — `F-Tools-3-Page`: the Tools page and the Settings split

**Goal.** Fill the Tools tab with bento cards, and move Places out of Settings.

### The Settings change is ASYMMETRIC — read this twice

E's exact words: *"only leave life areas in settings so Life Areas is in both places"*.

- **Places moves OUT of Settings entirely.** One door, in Tools.
- **Life Areas STAYS in Settings AND gains a card in Tools.** Two doors, deliberately.

This is knowingly the opposite of the de-duplication the Captures rethink spent two blocks on.
E chose it — Life Areas is genuinely both a setting and a tool. **Do not "fix" it, and do not
quietly make it symmetrical.**

### Files

- `ADHD LifeOS/Tools/ToolsView.swift` — replace the block-1 stub. **Bento cards, like Today**
  (E's explicit choice over Settings-style grouped rows): use `.bentoCard()` from `Theme.swift`.
- NEW `ADHD LifeOS/Tools/ToolsCatalog.swift` — the pure list.
- `Settings/SettingsView.swift` — delete `placesSection` and its call site; **leave
  `settingsLifeAreasRow` exactly as it is.**
- `RootView.swift` — pass `placesClient` and `lifeAreaEditorClient` through to `ToolsView`.
  **Trace where those are constructed before moving anything.**

### The gate that is easy to miss

`placesSection` is wrapped in `if #available(iOS 17.0, *)` and **the app floor is iOS 16.0**. So
**Tools must handle Places being absent on iOS 16**, showing only Life Areas. Do not let this
become an unconditional call — it compiles on the 26.5 simulator and breaks the floor.

### Pure logic to test (write first)

In `ToolsCatalog`:
- `available(placesSupported: true)` → both entries, Places first.
- `available(placesSupported: false)` → Life Areas only. **This is the iOS 16 test.**
- Each entry carries a title, a caption and a glyph, none empty.

### Acceptance

- [ ] Tools shows two bento cards on iOS 17+; **one on iOS 16**.
- [ ] Both cards open their real destinations (`PlacesListView`, `LifeAreaEditorListView`).
- [ ] Places is GONE from Settings; **Life Areas is still there**.
- [ ] The page is deliberately sparse — E wants room for Routines later. **Do not add filler.**
- [ ] No test or UI journey breaks. (Verified 2026-09-02: nothing references `settingsPlacesRow`
      or `settingsLifeAreasRow`, but re-grep — that was two blocks ago.)

### A trap that is NOT a success

Moving Places out of the Settings sheet may make the parked
[[places-backgrounding-dismiss-bug]] appear to vanish. **That is not a fix.** Those screens simply
no longer live under the sheet that was being rebuilt. The bug stays parked pending E's iOS
update; say so explicitly in the report if you notice the symptom change.

---

# BLOCK 4 — `F-Tools-4-Headers`: one pinned-header treatment

**Goal.** Fix the pinned section headers everywhere, as a single pass.

**The defect:** a pinned header is currently a near-white `.bar` strip with square corners sitting
against rounded cards — it reads unfinished. E asked for it fixed **everywhere at once** so the
treatment cannot diverge screen to screen.

**Sequenced last on purpose:** a chrome change tangled into a navigation rewrite makes both harder
to judge and harder to revert.

### Files

- `Theme/Theme.swift` — add ONE shared treatment (e.g. `pinnedSectionHeader()`) beside
  `sectionLabel()` and `bentoCard()`. This is the point of the block: a shared home so a future
  screen cannot invent its own.
- `Tasks/TaskListView.swift` — adopt it (currently hand-rolls `.padding(.vertical, 8).background(.bar)`).
- `Places/PlaceAppPickerView.swift` — adopt it (`pinnedHeader(_:)`).
- Any header Tools grew in block 3.

### The trap this repo keeps repeating

`dead-shared-component-pattern` is this codebase's **most repeated defect**: a helper gets
written, documented, unit-tested — and then nothing calls it, or the section holding it is gated
off. **Tests prove correctness, never REACHABILITY.**

So: after writing the shared modifier, **grep the CALL SITES, not the definition**, and prove no
screen still hand-rolls a header background:

```bash
grep -rn "background(.bar)" "ADHD LifeOS/" --include="*.swift"
```

Every remaining hit must be a deliberate non-header use, named in the report.

### Acceptance

- [ ] One shared header treatment exists in `Theme.swift`.
- [ ] `TaskListView` and `PlaceAppPickerView` both use it; neither hand-rolls a header background.
- [ ] The grep above returns only deliberate non-header uses.
- [ ] Headers still pin (opaque, so rows cannot show through the letters) and still read correctly
      in both themes.

---

## Close-out for the arc

When all four are done and E has judged them on device:

1. Full suite re-run, lint, sim build, device build — pasted output, not a summary.
2. `--no-ff` merge into `main`, then **re-verify ON main** (the merge succeeding says nothing
   about the suite), push, and paste the close-out triple.
3. Reinstall E's device **from main** so the phone stops carrying a branch build.
4. Update `tools-tab-and-custom-bar` memory with what actually shipped, and **ask E before
   deleting `feature/tools-tab`** — never delete a branch unasked.
5. **Then** raise Routines: it is E's declared top-priority next arc, and Tools is where its
   editor would land.

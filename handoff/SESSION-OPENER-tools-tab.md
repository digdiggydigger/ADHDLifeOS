# Session opener — the Tools tab & the morphing six-item tab bar

*Rewritten 2026-09-02 after E judged six design concepts and picked. E asked for this build to
get its own dedicated session "to provide as big of a context window as we can" — so this
document carries every decision and every code finding the designing session made.*

Read `claudecode.md`, `CLAUDE.md`, and auto-memories `tools-tab-and-custom-bar`,
`capture-disc-design`, `app-directory-arc-design`, `routines-next-arc` first.

**The design lives at** `https://claude.ai/code/artifact/767eacff-e616-4836-ab3a-ac842ddf42c9` —
it opens on "The pick" page; flip the **Scrolling** tweak to see the morph, and **Dark** to
check both themes. Working files are in `../tabbar-concepts/`.

---

## THE STATE GATE

1. **`main` should be at `efd72af`** (the app-directory merge) with a clean tree. Verify before
   anything: `git status --short` empty, `git log --oneline -1`.
2. **Branch fresh off main**: `git checkout -b feature/tools-tab main`. The app-directory branch
   is merged AND deleted (local + remote) — do not look for it.
3. Nothing about Tools has been built. Not one line.

---

## What E decided — settled, do NOT re-ask

### The bar

- **A CUSTOM six-item tab bar.** E was told the system bar caps at five and chose this
  explicitly over "replace an existing tab" and "Tools off Today".
- **Order: Today, Tasks, Areas, Journal, Captures, Tools.** Tools LAST; nothing else moves.
  Glyph `wrench.and.screwdriver`, label "Tools".
- **The bar has TWO STATES and morphs between them** (E picked from six concepts):
  - **AT REST → Design F "Minimal Dot".** Full width, icons only, no labels, one accent dot
    under the selected icon. Quiet and roomy.
  - **MID SCROLL → Design B "Bento Bar".** The bar contracts to a floating card — inset 12pt
    left/right, lifted ~22pt off the bottom, 22pt radius, `CardSurface` + `CardBorder` + a soft
    shadow — icons only, no dot.
  - **The selection indicator MORPHS with it: dot at rest → tinted chip when floating.** E chose
    this over keeping one indicator constant.
- **The trigger is MOMENTARY, not sticky.** B only while the page is actually moving; back to F
  when motion settles. **E was told this needs a new signal and chose it anyway**, over sharing
  the capture disc's existing sticky flag.

**This morph REPLACES `tabBarMinimizeBehavior(.onScrollDown)`.** E's earlier "rebuild
minimise-on-scroll too" answer is SUPERSEDED — it was the same need, and the morph answers it
better. Delete `minimizesTabBarOnScrollDown()` rather than building both.

### The Tools page

- **Bento cards, like Today** — each tool a tappable card in v3's card language, not Settings-style
  grouped rows.
- **It holds Places and the Life Areas editor. Nothing else.** E wants the page left sparse so
  [[routines-next-arc]] has an obvious home. **Tag Editor stays in Settings** (offered, declined).

### Settings — read this carefully, it is not symmetrical

E's exact words: *"only leave life areas in settings so Life Areas is in both places"*.

- **Places moves OUT of Settings entirely.** One door, in Tools.
- **Life Areas stays in Settings AND gains a door in Tools.** Two doors, deliberately.

This is knowingly the opposite of the de-duplication the Captures rethink spent two blocks on.
E chose it — Life Areas is genuinely both a setting and a tool. Do not "fix" it.

### The pinned-header pass

The pinned section headers are a near-white `.bar` strip with square corners against rounded
cards — slightly unfinished. **E asked for this fixed EVERYWHERE as one pass:** `TaskListView`,
`PlaceAppPickerView`, and Tools if it grows headers. **Sequence it AFTER the tab bar works** so a
chrome change is not tangled up in a navigation rewrite.

---

## Code findings (first-hand, from reading — trust these)

### The scroll signal: what exists, and why it is NOT enough

`ADHD LifeOS/Theme/CaptureDiscScrollActivity.swift` + `CaptureDiscPanObserver.swift` already give
the app a window-level scroll signal with zero per-screen wiring. **Reuse the OBSERVER; you
cannot reuse the MODEL.**

- `CaptureDiscPanObserver` installs ONE `UIPanGestureRecognizer` on the key window
  (`installOnKeyWindow`, idempotent, holds a static `shared`). `cancelsTouchesInView = false` and
  recognition is always simultaneous, so it blocks nothing. **This is the part to reuse.**
- `CaptureDiscScrollActivity` is **directional and STICKY by design** — E's 2026-08-31 verdict
  was *"stay in pill form until the page is scrolled upwards again"*, and the file says outright
  that nothing runs on a timer. **It cannot express "momentary".** Write a SECOND model
  (e.g. `TabBarScrollActivity`) rather than changing this one — the disc's behaviour is settled
  and `capture-disc-design` says do not re-litigate it.

**THE REAL RISK, and the thing to solve first — momentum.** `CaptureDiscPanObserver` deliberately
does **not forward terminal states** (`.ended`/`.cancelled`), and a pan recogniser tracks **the
finger, not the page**. After the user lifts, the scroll view keeps gliding but nothing reports
movement. A naive momentary signal therefore snaps the bar back to F **while the page is still
visibly scrolling** — exactly the wrong moment.

Options, in the order worth trying:
1. **A settle timer restarted on every `dragMoved`** (~250–350ms), so the bar stays in B through
   the lift and most of the deceleration. Cheapest, no change to the shared observer, and tunable
   on device. **Start here.**
2. Forward terminal states from the observer as well — but that edits a component the disc
   depends on; if you do, leave the disc's model reading exactly what it reads today.
3. Observe real scroll offsets per screen — genuinely accurate, and exactly the per-screen drift
   the clearance work already stamped out. **Avoid.**

Whatever you build, the number is a guess until E sees it. Ship it tunable and ask.

### The tab bar today

`ADHD LifeOS/RootView.swift`:
- `enum AppTab: Hashable { case today, tasks, areas, journal, captures }` (~line 16). **Its doc
  comment still asserts "Five stays five … a sixth would bury one of these" — rewrite it, don't
  extend it.** It is the record of a decision E has now reversed.
- A system `TabView(selection: $selectedTab)` with five `.tabItem` + `.tag`.
- Modifiers that matter: `.haptic(HapticFeel.tabChange, trigger: selectedTab)`,
  `.onChange(of: selectedTab) { _ in discScrollActivity.reset() }`,
  `.minimizesTabBarOnScrollDown()` (**delete — superseded by the morph**),
  `.blur(radius: isFabOpen ? 4 : 0)`, the `CaptureFanOverlay`, and `.badge(captureInboxCount)` on
  Captures only.

### Hit-target maths (why six is fine and E's first idea wasn't)

The bar is **393pt** on an iPhone 15 Pro. Six equal slots → **65.5pt each**, well past the 44pt
floor. E originally asked about splitting one slot into two boxes: that gives **~33pt each,
below the floor**, and was rejected on that basis. Do not resurrect it.

### What the custom bar must REIMPLEMENT

**The Captures badge.** `.badge(captureInboxCount)` is a system feature. Hand-draw it, and keep
both of its current behaviours: `.badge(0)` renders nothing, so an empty inbox is **silent rather
than a zero**; and a failed refresh **keeps the last known number** rather than claiming zero
("never having looked ≠ nothing there").

### What SURVIVES untouched (verified)

- `.haptic(HapticFeel.tabChange, trigger: selectedTab)` — fires on the selection value.
- `PlaceActionScreen.appTab` (`Places/PlaceActionExecution.swift:226`) → `RootView:102`
  `selectedTab = screen.appTab`. Adding `.tools` does not break it — **but check the switch is
  still exhaustive**, and decide whether any screen should target `.tools`.
- **The capture disc's clearance** — `CaptureDiscMetrics.clearance = discDiameter + edgeMargin + 8`
  (`Theme/Theme.swift:154-158`) is computed from the DISC, not the bar. **E's instruction: change
  nothing, show it on device, then decide.** The disc is already morphing to a pill at the same
  moment, so it may need no help at all.

### Architecture call

**Keep `TabView` for content, hide only its bar, add the custom one via
`.safeAreaInset(edge: .bottom)`.**

```
TabView(selection: $selectedTab) { …six tabs… }
    // hide the system bar (applied to the tab CONTENT, not the TabView, on iOS 16/17)
    .safeAreaInset(edge: .bottom) { customTabBar }
```

**Do NOT replace `TabView` with `switch selectedTab`** — that rebuilds the view on every switch
and throws away each tab's scroll position and `NavigationStack` depth. A `ZStack` keeps state
but renders every tab at once. `TabView` + hidden bar is the only shape that keeps laziness AND
state. Expect `.toolbar(.hidden, for: .tabBar)` to need applying to the views INSIDE the
`TabView`, and **verify the system bar is genuinely gone rather than merely covered — a covered
bar still eats touches.**

**Animate the morph with the house spring** (§5): `.spring(response: 0.35, dampingFraction: 0.8,
blendDuration: 0)`, and respect Reduce Motion.

### Moving the two screens

`ADHD LifeOS/Settings/SettingsView.swift`:
- **Life Areas** — closure `NavigationLink` → `LifeAreaEditorListView(client:)`, a11y id
  `settingsLifeAreasRow` (~line 165). **STAYS, and is also added to Tools.**
- **Places** — `private var placesSection`, `NavigationLink` → `PlacesListView(client:)`, a11y id
  `settingsPlacesRow` (~line 297). **MOVES OUT.**

Two facts that de-risk this, both verified:
- **No test or UI journey references either identifier** — grepped both targets, zero hits.
- **`placesSection` is wrapped in `if #available(iOS 17.0, *)`** and the app floor is **iOS 16.0**,
  so **Tools must handle Places being absent on 16** (Tools would then show only Life Areas). Easy
  to miss; do not let it become an unconditional call.

Trace where `placesClient` and `lifeAreaEditorClient` are constructed before moving anything.

---

## Suggested block sequence

1. **F-Tools-1-Bar** — `AppTab.tools`, the custom six-item bar in its RESTING state (F) only,
   system bar hidden, badge reimplemented, `minimizesTabBarOnScrollDown()` deleted. Verify on
   device that six slots feel right before adding motion.
2. **F-Tools-2-Morph** — `TabBarScrollActivity` (momentary, settle-timer), the B state, and the
   dot→chip indicator morph. Ship the settle constant tunable; ask E for a device verdict on both
   the timing and the disc pairing.
3. **F-Tools-3-Page** — the Tools tab itself: bento cards for Places and Life Areas, Places
   removed from Settings, Life Areas left in both, iOS-16 gating handled.
4. **F-Tools-4-Headers** — the pinned-header pass across `TaskListView`, `PlaceAppPickerView` and
   anything else using the treatment. **After the bar works**, never tangled with it.

---

## Close-out rules (strict)

- TDD: failing test first for every piece of new pure logic. View bodies are not unit-testable
  (~0% by design) — put the testable rules in a pure type, the way `PlaceAppPickerPresentation`
  does. **The scroll-activity model and the bar's metrics are exactly that kind of pure logic —
  test them.**
- **Commit BEFORE any deliberate-regression red-check**, restore with `git checkout --`, and
  prove it by rebuilding.
- Every block ends with a landed commit AND push, verified by pasting `git status --short` +
  `git log --oneline -1` + `git log --oneline -1 origin/<branch>` showing the SAME SHA.
- `swiftlint lint` must be 0 violations. Watch `file_length` (400) and `type_body_length` (250) —
  both bit the last arc, and **`RootView.swift` is ~397 lines before you add anything. Budget for
  splitting it.**
- **Never pipe a long `xcodebuild` through `grep`** — it buffers, and you cannot tell progress
  from a hang. Redirect to a log file and grep the file.
- **If the suite suddenly crawls, the simulator is poisoned:** host alive at ~0.1% CPU, nothing
  written to the `.xcresult` for 90s. `xcrun simctl erase <udid>` fixes it; rebooting does not. A
  healthy full run is **~5 seconds for ~2,100 tests**.
- Device `wishwashwacky15`, id `3DBC979A-3255-5456-8C30-172DB19B99B3`:
  `xcodebuild build -destination 'platform=iOS,id=<id>' -allowProvisioningUpdates
  -derivedDataPath <scratch>` → `devicectl device install app` → `devicectl device process launch`.
  Use a scratch derivedDataPath so the device build doesn't churn the simulator's.
- The project uses `PBXFileSystemSynchronizedRootGroup` — **new .swift files are picked up
  automatically, no `project.pbxproj` edit.**
- **Never script an auth flow.** If a signed-in session is needed, stop and ask E.

## Conflicts to report (CLAUDE.md §7 requires it)

- **`ui-ux-pro-max` rates "bottom nav ≤5" a HIGH-severity rule** and lists "overloaded nav" as an
  anti-pattern. **E's six-tab decision overrides it knowingly** — E was shown this before choosing.
  Report it in the build report; do not silently comply or silently ignore.

## Related open threads (context, not scope)

- **The Settings backgrounding bug is PARKED** (`places-backgrounding-dismiss-bug`) — device-only,
  reproduced on iOS 26.4, absent on the 26.5 simulator; E is still on 26.4 and updating soon, and
  the standing instruction is **write no fix until the update lands**. Relevant here because
  moving Places OUT of the Settings sheet may make the symptom appear to vanish. **That would not
  be a fix** — those screens would simply no longer live under the sheet being rebuilt.
- **Routines is E's declared TOP-priority next arc** (`routines-next-arc`) — location-triggered
  ordered step lists. Tools is where its editor would plausibly land; that is part of why E wants
  the page sparse.

## State at handoff (verified 2026-09-02)

- `main` at **`efd72af`**, clean, pushed. Suite **2,100 / 0** (56 skipped = emulator suites, by
  design), SwiftLint **0 violations in 606 files**, sim + device builds green.
- E's iPhone carries `efd72af` **from main** (install + launch verified).
- `feature/app-directory` is merged and **deleted**, local and remote.
- One stale remote branch remains untouched: `origin/claude/test-coverage-analysis-hu9auv`.

# Session opener — BUILDING the bottom search row (three blocks)

*Written 2026-09-03, off `main` @ `8d895d1` (the Tools-arc merge). Self-contained: work through it
top to bottom. The design was settled by E in chat on 2026-09-03 via four questions; the answers
are recorded below and are **not to be re-litigated**.*

Read `claudecode.md` and `CLAUDE.md` first, plus auto-memories `tools-tab-and-custom-bar`,
`tabview-folds-past-five`, `capture-disc-design`, `dead-shared-component-pattern`,
`never-destroy-uncommitted-work`, `never-automate-auth-flows`.

---

## Why this arc exists

E photographed "a peculiar box below the menu nav tab bar" on Tasks. It is **iOS 26's
`.searchable` field**.

iOS 26 renders that field as a floating capsule pinned to the **bottom** of the screen, and where
a `TabView` exists it docks into the tab bar. **The Tools arc's block 1 deleted the `TabView`** —
it is a `UITabBarController` and folds a sixth tab into "More" (see `tabview-folds-past-five`) —
so the capsule falls back to standing on its own, and lands *underneath* the custom bar.

Measured off E's iPhone 15 Pro screenshot:

```
bar (Design B, floating)   inset 12pt    bottom 809pt
the stray outline          inset ~30pt   bottom 823pt
```

Reproduced on the simulator with a probe — a custom bar in a `safeAreaInset`, `.searchable`, no
`TabView` — and removed again by deleting `.searchable`. Controlled both ways.

**Two consequences that make this more than cosmetic:**

- **Tasks search is currently UNREACHABLE.** The field is under our bar; it cannot be tapped.
- **It is a block-1 regression that only became VISIBLE in block 2.** The resting bar is a
  full-width opaque plane and covers the capsule completely; it peeks out only once the bar
  contracts to the floating card.

Scope check, already done: `.searchable` appears exactly twice — `TaskListView` (affected) and
`PlaceAppPickerView` (presented as a `.sheet`, so no tab bar sits under it — **leave it alone**).

## E's design, settled — do not re-open

E was offered "move search to the navigation bar" and **rejected it**. Search stays at the bottom
and moves **above** the custom tab bar, into the band the capture disc occupies.

- **One row: field fills the leading width, disc at the trailing end, centres aligned.** The disc
  keeps its 24pt trailing margin.
- **The 60pt gap between the top of the tab bar and the capture stack is preserved** —
  `RootBottomOverlay.bottomPadding`, E's 2026-08-31 margin pass. E asked for this explicitly.
- **Always visible** on a screen that has search.
- **Scope: Tasks, Captures AND Journal.** Captures and Journal have **no search state of any kind
  today** (grepped) — that is real filtering logic and its own tests on each, not just a field.
- **Tapping the field opens a FULL-SCREEN search surface** — field at top, results below, Cancel.
  E chose this over the cheaper in-place filter.

### The two facts that shape the whole build

**1. The field must be OURS, not Apple's.** iOS 26 owns that capsule's placement and will not move
it. `.searchable(placement: .navigationBarDrawer(...))` does clear the stray box — verified, both
`.always` and `.automatic` — but it puts the field at the top, which E rejected. So `.searchable`
comes off `TaskListView` and a `TextField`-shaped control of our own takes its place.

*(A trap from the investigation, worth not repeating: the first diff said `.navigationBarDrawer`
did NOT fix it. The diff was against a no-search build, and the drawer adds ~50pt at the top which
shifts ALL content, so the bottom region differed for layout reasons. **Cropping and looking at
the render corrected it.** Diff bounds are a hint; the picture is the evidence.)*

**2. Because focus opens a full-screen surface, the row's field never hosts a keyboard.** It is a
**Button styled as a search field**, not a live text field. Nothing in the row ever becomes first
responder, so there is no keyboard-avoidance problem in the row at all, and the tab bar and disc
never have to move out of the way. This is the single biggest simplification in the arc — do not
build a live `TextField` into the row.

---

# BLOCK 1 — `F-Search-1-Row`: the row, the surface, and Tasks

**Goal.** The search row exists above the tab bar, aligned with the capture disc; Tasks uses it;
tapping it opens the full-screen search surface; the stray iOS 26 capsule is gone.

This block also builds every shared piece blocks 2 and 3 merely adopt.

### Architecture (decided — do not redesign)

**The ROW is app-level; the SURFACE is screen-level.** That split is what keeps it simple:

- The row has to line up with the capture disc, which is drawn app-level in `RootBottomOverlay`.
  So the row lives **there**, laid out as one `HStack` with the disc — alignment by construction
  rather than by two views agreeing on a number.
- The surface needs the screen's DATA (tasks, captures, logs). Hoisting `TasksService` up to
  `RootView` to reach it would be a large, invasive change for nothing. So the screen presents its
  **own** full-screen surface when the app-level model says search opened.

That gives one shared control, one shared trigger, and per-screen results with no service hoisting.

### The trap that will bite you first

**`AppTabContent` keeps every visited tab alive** (that is the whole point of it — scroll position
and `NavigationStack` depth survive a tab switch). So **`.onAppear` / `.onDisappear` fire once on
first build and then effectively never again.** Any "register my search scope when I appear, clear
it when I leave" design is silently broken: the second tab to register wins forever.

**Drive the scope from `selectedTab`, which `RootView` already owns.** It is a pure function of a
value that changes on every switch.

### Files

- NEW `ADHD LifeOS/Theme/AppSearchScope.swift` — the pure rules: which tab has search, the
  placeholder copy, and the clearance arithmetic.
- NEW `ADHD LifeOS/Theme/AppSearchModel.swift` — the app-level observable: active scope, whether
  the surface is open. Small on purpose.
- NEW `ADHD LifeOS/Theme/AppSearchRow.swift` — the field-shaped Button.
- NEW `ADHD LifeOS/Tasks/TaskSearchSurface.swift` — the full-screen surface for Tasks.
- `RootBottomOverlay.swift` — the row joins the disc in one `HStack`.
- `RootView.swift` — owns the `AppSearchModel`; feeds it `selectedTab`.
- `Tasks/TaskListView.swift` — **delete `.searchable`**; present `TaskSearchSurface`; ask for the
  taller clearance.
- `Theme/Theme.swift` — the clearance becomes scope-aware (see below).

### The clearance problem, and its one answer

`CaptureDiscMetrics.clearance` is **92** (`discDiameter 60 + edgeMargin 24 + 8`) and **eleven
files** lean on it through `.captureDiscClearance()`. A search row in that same band means the
three searchable screens need MORE bottom room than the other eight — and silently reusing one
number would put the last row of Tasks under the new field.

**Do not add a second spelling.** Extend the existing one so there is still exactly one home and
one call:

```swift
// Theme.swift, beside captureDiscClearance()
func captureDiscClearance(hasSearchRow: Bool = false) -> some View
```

with the arithmetic in a named metric, derived rather than typed:
`clearance + (hasSearchRow ? searchRowHeight + rowSpacing : 0)`.

`CaptureDiscClearanceCallSiteTests` already enumerates every call site and asserts nobody
hand-rolls the padding — **it must keep passing, and its list must grow if a screen changes which
form it calls.**

### Pure logic to test (write these first)

In `AppSearchScope`:
- `scope(for:)` — `.tasks` for the Tasks tab, `.none` for every other tab. **Only add `.captures`
  and `.journal` in blocks 2 and 3**, so the surface's exhaustive `switch` forces each screen to
  be handled when its case arrives. Adding all three now would ship two cases nothing renders —
  `dead-shared-component-pattern`, the gated-off variant.
- Every scope has a non-empty placeholder, and `.none` has no field.
- Totality: every `AppTab` maps to some scope (no tab is unanswered).

In `AppSearchModel`:
- Changing scope **clears the query** — a query left over from another tab is a bug, and it is the
  same reasoning as `TabBarScrollActivity.reset()` on tab change.
- Changing scope **closes the surface**.
- Opening on `.none` is a no-op — the surface cannot be opened where there is nothing to search.

In the metrics:
- The row's field is **≥44pt tall** (§3's floor).
- The search-row clearance is **strictly greater** than the plain one, and the difference is
  exactly the row plus its spacing — derived, not a second typed number.
- The disc's trailing margin is unchanged at 24 (a guard: E's settled `capture-disc-design`).

### Acceptance

- [ ] The stray iOS 26 capsule is **gone from Tasks** — `.searchable` is off the screen, verified
      by rendering the bottom band, not by reasoning.
- [ ] The row sits above the tab bar, field filling the leading width, disc at the trailing end,
      **centres aligned**. The disc's outer frame is 60×60 in BOTH disc and pill states (only the
      visual capsule shrinks to 60×48), so no anchoring trick is needed — the centre never moves.
- [ ] **The 60pt gap between the bar's top and the capture stack is unchanged.** E asked for this
      by name; assert it.
- [ ] Tapping the field opens the full-screen surface; Cancel returns; the query filters tasks
      through the EXISTING `TaskListRefinement.apply(tasks:searchText:)` — do not write a second
      filter.
- [ ] The row appears on Tasks and **nowhere else** in this block.
- [ ] Last row of Tasks clears the new furniture — the taller clearance is applied and tested.
- [ ] The row's control never takes focus (it is a Button), so the tab bar and disc never move.
- [ ] Reduce Motion respected; house spring (§5); haptic on open, per `Theme/Haptics.swift`.
- [ ] iOS 16.0 floor; any 17+ API `#available`-gated.
- [ ] Suite green, lint 0, sim + device builds green, red-checked, committed and pushed.

### A guard worth writing while the reason is fresh

`.searchable` on a tab-root screen is now a **bug**, not a style choice — it produces an
unreachable field under the bar. Add a call-site test in the house idiom (strip comment lines
first — `ToolsPageCallSiteTests`' scar) asserting `.searchable(` appears in **no** file that is a
tab root, while explicitly permitting `PlaceAppPickerView.swift`, which is sheet-presented and
named with its reason.

### Then

Commit, push, install, and **stop for E's device verdict on the row's position and spacing before
starting block 2.** This is the shape E designed from an ASCII mock; the real thing is the first
chance to judge it.

---

# BLOCK 2 — `F-Search-2-Captures`: Captures adopts the row

**Goal.** The Captures inbox gains search and uses the shared row and surface.

**This is new behaviour, not a wiring job.** `CaptureInboxService` has no search state and there is
no capture filter anywhere in the tree — confirmed by grep.

### Files

- NEW `ADHD LifeOS/Capture/CaptureSearchRefinement.swift` — the pure filter, `TaskListRefinement`'s
  shape.
- NEW `ADHD LifeOS/Capture/CaptureSearchSurface.swift`.
- `Theme/AppSearchScope.swift` — add `.captures`; the surface's `switch` will refuse to compile
  until it is handled, which is the point.
- `Capture/CaptureInboxView.swift` — present the surface; taller clearance.

### Pure logic to test first

- **What a capture matches on.** A capture has a title OR content and may have neither (photo
  captures) — `CaptureRowPresentation.primaryText` already owns that fallback and **a photo capture
  rendering blank is a bug this repo has already shipped once** (`eddef9b`). Search must go through
  the same presentation rule, not re-derive it. That is the whole test.
- Case- and diacritic-insensitive, whitespace-trimmed, empty query returns everything — match
  `TaskListRefinement` exactly rather than inventing a second convention.

### Acceptance

- [ ] Search on Captures matches title and content, and a photo capture with neither is matched by
      whatever `CaptureRowPresentation` shows for it — never silently unmatchable.
- [ ] The row and surface are the SHARED ones from block 1; no second copy.
- [ ] Suite green, lint 0, builds green, red-checked, committed, pushed.

---

# BLOCK 3 — `F-Search-3-Journal`: Journal adopts the row

**Goal.** The Journal timeline gains search on the same shared machinery.

### Files

- NEW `ADHD LifeOS/Journal/JournalSearchRefinement.swift`
- NEW `ADHD LifeOS/Journal/JournalSearchSurface.swift`
- `Theme/AppSearchScope.swift` — add `.journal`.
- `Journal/JournalView.swift` — present the surface; taller clearance.

### The wrinkle this screen has and the others do not

The Journal timeline is **not one list of one type** — it interleaves logs, tasks and focus
sprints (`JournalTimeline`). Decide and record what search covers: log text only, or the whole
timeline. **Log text only is the honest default** (it is what a person means by "search my
journal"), and it should be stated in the surface's empty state rather than left ambiguous.

Also: the Journal composer is a `safeAreaInset` inside its own `NavigationStack` and already calls
`appTabBarClearance()` — it now has to clear the search row too. `AppTabBarCallSiteTests`
enumerates that call site; **grow it in the same commit** or the composer's caption line goes back
under the furniture, which is exactly what E photographed in the Tools arc.

### Acceptance

- [ ] Journal search covers log text, and the surface says so where results are empty.
- [ ] The composer bar clears the tab bar AND the search row; the call-site test is updated.
- [ ] Suite green, lint 0, builds green, red-checked, committed, pushed.

---

## Standing rules (they bit this project; they will bite you)

- **TDD.** Failing test FIRST for every piece of new pure logic. View bodies are ~0% covered by
  design — push every testable rule into a pure type.
- **Commit BEFORE any deliberate-regression red-check**, restore with `git checkout --`, and prove
  the restore by REBUILDING.
- **A source-reading guard must assert a whole LINE of Swift, not a bare name.** Two scars:
  `contains("settingsLifeAreasRow")` still matches `…RowX`, and a doc comment in the same file can
  satisfy a `contains` all by itself. Strip comment lines before searching.
- **Never pipe a long `xcodebuild` through `grep`** — log to a file and grep the file. Run it
  backgrounded; the result-bundle step often outlives a 2-minute foreground timeout even when the
  tests finished in ~6s.
- **A crawling suite means a poisoned simulator**, not slow tests. `xcrun simctl erase <udid>`;
  rebooting does not fix it. Healthy is ~5s for ~2,180 tests.
- `swiftlint lint` at 0. Watch `file_length` (400) and `type_body_length` (250).
- Every block ends with a landed commit AND push, verified by pasting `git status --short`,
  `git log --oneline -1` and `git log --oneline -1 origin/feature/bottom-search` at the SAME SHA.
- **Never script an auth flow.** There is no signed-in simulator; if you need one, stop and ask E.
- **MEASURE THE RENDER.** This is the habit that fixed the Tools arc and found this arc's bug.
  Decode the PNG in Python (`zlib` + the filter loop — no PIL on this machine), sample a row or a
  column, quantise, and print colour BANDS with point ranges. To see a state you cannot reach by
  launching, use the auth-free `swiftc` probe from `tabview-folds-past-five` compiled against the
  REAL `Assets.xcassets` via `xcrun actool`, with a shim declaring `Color.pageBackground` etc.
  **A probe proves nothing until it actually scrolls** — give it enough content to overflow and
  drive it with `idb ui swipe <udid> x1 y1 x2 y2 --duration` (POINTS, not pixels).
- Device `wishwashwacky15`, id `3DBC979A-3255-5456-8C30-172DB19B99B3`. Build with a scratch
  `-derivedDataPath` so the device build does not churn the simulator's, then
  `devicectl device install app` → `devicectl device process launch --terminate-existing`.
  **Force-quit before judging an install-over-running app** — a phantom bug cost a session once.
- **Report the §7 conflict in every block report:** `ui-ux-pro-max` rates "bottom nav ≤5" HIGH
  severity with "overloaded nav" as an anti-pattern. **E was shown this and chose six knowingly.**

## Close-out for the arc

1. Full suite, lint, sim build, device build — pasted output, not a summary.
2. `--no-ff` merge into `main`, **re-verify ON main** (the merge succeeding says nothing about the
   suite), push, paste the close-out triple.
3. Reinstall E's device from main.
4. Update the `tools-tab-and-custom-bar` memory (or split a `bottom-search` one) with what actually
   shipped, and **ask E before deleting the branch** — E kept `feature/tools-tab` deliberately.
5. **Then raise Routines** — location-triggered ordered step lists, still E's declared
   top-priority feature, parked since 2026-09-02. Tools is where its editor lands.

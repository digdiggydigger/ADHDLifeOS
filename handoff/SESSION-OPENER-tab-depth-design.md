# Design record — tab depth: the re-tap rule, the Nudges way back, and the search row (2026-09-08)

*This is the design record and the why, not a session opener. It stays. Written the same morning
E raised both asks, after the questions E answered and the simulator probe that settled the
mechanism.*

## E's two asks, in E's words

06:20, with a screenshot of a pushed task detail: *"we need to remove the 'search tasks' search
bar from a full view task screen such as the one shown in one of the screenshots."*

~07:00: *"The nav bar tab items need to direct the user back to that tab item's top-level page.
Example: when on the Today tab, if the user navigates into 'Nudges', there is no way to get back
to the Today main page. If the user taps the tab they are already on, BUT THEY ARE NOT AT THE
TOP-LEVEL PAGE then that tab needs to return to the top-level page. Ask me questions if you need
more information."*

## The four questions, and E's answers (all the recommended option)

| question | E's answer |
|---|---|
| Re-tap when already at the top-level page? | **Scroll to top** — the iOS convention. |
| Nudges hides the bar and draws no back control; add one? | **Yes** — Task detail's chevron, the house pattern. |
| Should a re-tap also close a sheet or cover on that tab? | **No** — pushed screens only; sheets keep their own dismissal. |
| One arc with the search-row ask, pop-to-root first? | **Yes** — both need the root to know a tab's depth. |

## What the code was doing

- `AppTabBar`'s button did `selection = slot.tab` and nothing else. A tap on the selected tab
  was a no-op by construction — `TabView` used to pop to root and scroll to top for free, and
  the custom bar (F-Tools-1-Bar) had silently lost both.
- No tab held a `NavigationPath`. Every push was a per-screen `isPresented` flag, plus value
  links on Today and Areas (life-area rows) and closure links on Tools. The root had nothing it
  could reset.
- `NudgesView` applied `.toolbar(.hidden, for: .navigationBar)` — copied from the tab roots,
  which hide theirs on purpose because they draw their own large titles — and drew nothing in
  its place. The edge swipe was the only way out, which is E's "no way to get back".

## The probe that settled the design (iOS 26.5 simulator, `scratchpad/navprobe`, photographed)

Two path-bound stacks, one with closure links and a flag push, one with value links and a flag
push, every screen printing `path.count`:

| push form | `path.count` while pushed | `path = NavigationPath()` pops it | clearing its flag pops it |
|---|---|---|---|
| closure `NavigationLink { }` | 0 | **no** | n/a |
| `navigationDestination(isPresented:)` | 0 | **no** | yes |
| `NavigationLink(value:)` | 1 | yes | n/a |
| closure link nested ABOVE a value or flag screen | unchanged | collapses with the screen below | collapses with the screen below |

Two consequences, both load-bearing:

1. **The root cannot pop a tab from outside.** The only levers that pop are the tab's own flags
   and the tab's own path. So the re-tap travels DOWN to the root screen as a signal, and each
   root clears its own pushes. This is also why the depth travels UP: the root-level furniture
   (the search row) can only learn a tab's depth from the tab.
2. **Tools could not be popped at all** — its two top-level pushes were closure links. They are
   one flag push now (`pushedDestination`), and the closure links deeper in that stack (the
   Life Areas editor's rows) collapse with it, per row four. Flag pushes coexist with closure
   links in one stack — the probe pushed both in stack A — where value links do not (trap b,
   `LifeAreaEditorListView`), which is why Tools moved to a flag and not a value.

## What shipped (block 1, F-TabDepth-1-PopToRoot)

- `TabReselectionResponse.response(isAtRoot:)` — deep: pop to root; at root: scroll to top.
- `TabNavigationCoordinator` — `reselect(tab)` bumps a per-tab count the roots watch;
  `report(tab, isAtRoot:)` records depth; `isAtRoot` defaults **true** (an unvisited tab can
  only be at its root — and block 2's row must not hide on tabs never visited).
- `AppTabBarPresentation.tapOutcome(current:tapped:)` — select vs reselect; the bar calls
  `onReselect`, `RootView` routes it into the coordinator and injects the coordinator.
- `.tabRoot(_:isAtRoot:onPopToRoot:)` — a `ScrollViewReader` modifier applied INSIDE each tab's
  stack on the root content; `.tabRootScrollAnchor()` on each padded scroll content root.
- Six roots wired, each listing its own pushes; Today's list lives in `HomeView+TabRoot.swift`
  because `HomeView.swift` sits at the 400-line budget.
- `NudgesView` keeps the bar with an empty inline title, hidden background, and the house Back
  chevron (`nudgesBackButton`).

## What the UI journey caught that nothing else could

`TabReselectionJourneyUITests`, against the emulator, three tests:

- **The harness, not the app, on the first run.** `UITestSession.openTab` returns early when the
  slot is already selected — correct for every other journey, and exactly what a re-tap test
  must not do. The journey taps the selected slot directly (`reTapToday`).
- **`staticTexts["Today"]` also matches the tab bar's pill label** (y = 794). The page title
  now carries `homeTitle`.
- **The first anchor overshot by 16pt.** A zero-height anchor view INSIDE the page's padded
  `VStack` was 16pt below the true top (spacing), so scrolling it to the edge dragged the page
  16pt past its resting position — and, worse, its spacing added 16pt of dead space at the top
  of every tab. The anchor is an `id` on the padded content root now, whose frame includes the
  padding; the title returns to within 4pt of where it rested at launch, measured.
- **A fresh account's Today is too short to scroll until its sections load.** The scroll test
  waits for the last card before swiping.

## Alternatives considered

- **Give every tab a `NavigationStack(path:)` and reset it from the root.** The probe killed it:
  a path reset pops neither flag nor closure pushes, which is most of the app's pushes.
- **Convert every push to a value push.** Correct in principle and the largest diff in the app;
  trap b makes each stack an all-or-nothing migration. Not needed once each root pops itself.
- **Have the re-tap also dismiss sheets.** E said no; the composer, the search surface and the
  New-nudge sheet keep their own dismissal.

## Block 2 (queued): the search row at root

`RootView` derives `AppSearchScope` from `selectedTab` alone. With the coordinator's
`isAtRoot(tab)` it becomes `scope(for:isAtRoot:)`, and the row leaves with the overlay's
spring while a task detail is pushed. The seam is the same one block 1 built, which is why E
chose this order.

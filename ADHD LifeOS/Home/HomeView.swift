//
//  HomeView.swift
//  ADHD LifeOS
//

import Combine
import SwiftUI

struct HomeView: View {
    @ObservedObject var authService: AuthService
    /// Internal, not private: `HomeAccessoryStrips` reaches it for the reorder list.
    @StateObject var homeService: HomeService
    /// Internal, not private: `HomeAccessoryStrips` reads it from its own file.
    @StateObject var nudgesService: NudgesService
    /// Internal, not private: `HomeMomentumSections` refreshes the inbox count.
    let captureClient: CaptureClientAdapting
    /// Internal, not private: the capture door moved to `HomeCaptureDoor.swift` when this file
    /// crossed its 400-line budget, and it needs this to build the pushed detail.
    let journalClient: JournalClientAdapting?
    private let lifeAreaDetailClient: LifeAreaDetailClientAdapting
    /// Internal, not private: `HomeMomentumSections` drives the close-from-Home flow.
    let taskDetailClient: TaskDetailClientAdapting
    /// Internal, not private: `HomeMomentumSections` builds the pushed task detail.
    /// Threaded Home → LifeAreaDetail → TaskDetail so the detail screen reached from a life-area
    /// card can launch a sprint on `RootView`'s app-level `FocusSessionService`. Internal for
    /// `HomeMomentumSections`.
    let onStartFocus: ((FocusSprintPlan) -> Void)?
    /// `RootView` passes `focusService.completedSprintCount` here; combined with the local
    /// pull-to-refresh count it forms the analytics reload token, so finished sprints AND pulls
    /// both refetch focus history without waiting for a cold launch.
    private let focusReloadToken: Int
    /// The app-wide sprint, so the Best-next-move card hides Start Session rather than offering
    /// a second sprint over the top. Internal for `HomeMomentumSections`.
    let activeSprint: ActiveSprintStatus?
    /// The same sprint, projected for the Home Screen widget. Separate from `activeSprint` because
    /// the two answer different questions: the hero only needs "is THIS task's sprint running", the
    /// widget needs the whole deadline-derived payload. Kept deadline-derived and therefore stable
    /// while a sprint merely counts down, so `onChange` fires on real events, not on every tick.
    /// Internal, not private: `HomeView+Refresh` republishes with it.
    let widgetSprint: FocusWidgetSnapshot.ActiveSprint?
    private let onToggleSprintPause: () -> Void
    /// Crosses to the Captures tab — the inbox peek card's header and "Clear the deck" both
    /// select it rather than pushing Home's own private copy of the inbox. Wired by `RootView`
    /// through its tab selection, the way the nudges row used to reach the Nudges tab.
    let onOpenCaptures: (() -> Void)?
    /// For the area screen's "Add to <area>" CTA; `nil` hides it (F-V3-AreaDetail).
    private let taskCreateClient: TaskCreateClientAdapting?
    /// Publishes the Home Screen widget's snapshot. Home is the right owner: it is the one screen
    /// holding BOTH halves of what the widget shows — the Active Goal and the week's focus history.
    /// Internal, not private: `HomeView+Refresh` publishes through it.
    let widgetPublisher: FocusWidgetPublishing
    /// The most recent history read, kept so a life-areas reload can republish without refetching.
    /// Internal, not private: the week review reads it from `HomeMomentumSections`.
    @State var publishedHistory: [CompletedFocusSession] = []
    /// Internal, not private: `HomeView+Refresh` bumps it to fold the analytics section
    /// into every reload.
    @State var pullRefreshCount = 0
    /// Internal, not private: the v3 header lives in `HomeMomentumSections.swift`.
    @State var showSettings = false
    /// Re-read each time Settings closes — the sheet is the only writer. Internal for
    /// `HomeMomentumSections`.
    let momentumPreferencesStore: MomentumPreferencesStoring
    @State var momentumPreferences: MomentumPreferences = .default
    /// Today's nudges section pushes the full manager. Internal, not private: the section lives
    /// in `HomeAccessoryStrips.swift`.
    @State var isPresentingNudges = false
    /// Today's life-area list, folded or not (E, 2026-08-28). A stored preference, not view state:
    /// you fold it because you do not want to see it, so it must survive a relaunch. Internal, not
    /// private — the section lives in `HomeMomentumSections.swift`.
    @AppStorage("home.lifeAreasCollapsed") var lifeAreasCollapsed = false
    /// Whether the SIGNED-IN ACCOUNT has ever had a nudge. Drives the first-run door — see
    /// `HomeNudgesSection.shouldRenderSection` and `NudgeFirstRunMarker`.
    ///
    /// Not `@AppStorage`: that is per device, so a second account on one phone would inherit the
    /// first account's answer and a genuinely new user would never see their door. Read and
    /// latched per uid instead.
    @State var hasEverHadNudges = false
    @State var inboxCount = 0
    /// The newest waiting captures for Today's inbox card (E's 2026-08-25 note) — refreshed with
    /// the count, from the same fetch.
    @State var inboxPeek: [Capture] = []
    /// Captures promoted, journaled or archived TODAY — the card's throughput line. Ungated,
    /// unlike `capturesClearedToday`: the scoreboard toggle governs what counts toward the ring,
    /// not what the card may say.
    @State var inboxHandledToday = 0
    /// A peek row's pushed capture — the card's rows are doors straight into their capture.
    @State var inspectingHomeCapture: Capture?
    /// M7: captures whose exit stamp is today, feeding the ring when the Settings toggle counts
    /// them. Refreshed with the inbox count; 0 whenever the toggle is off.
    @State var capturesClearedToday = 0
    /// Whether BOTH capture fetches behind `capturesClearedToday` last succeeded. 0 is a real
    /// count as well as the value a failed `try?` leaves, so without this the daily goal cannot
    /// tell a quiet day from a dropped connection. Internal: `HomeView+DailyGoal` reads it.
    @State var hasLoadedClearedCaptures = false
    /// Home's memory of the ring between reloads (`F-CTACelebrations-5`, E's F7). `@State`, so it
    /// starts again on relaunch — the once-per-day rule is `CelebrationDayMarking`'s, not this.
    @State var dailyGoalTracker = DailyGoalTracker()
    /// Where the closure ring is, in global coordinates, so R-h's fallback pop leaves from the
    /// ring rather than the middle of the screen. `nil` until the ring has been laid out.
    @State var ringOrigin: CGPoint?
    /// Home's mode-scoped reorder state. `isArranging` swaps the grid for an `.onMove` `List` (E's
    /// settled mechanism); `arrangeAreas` is the live, optimistic ordering the drag mutates. This is
    /// NOT the parked `List`→`LazyVStack` container item — it is a new, separate container.
    /// Internal, not private: the arrange header lives in `HomeMomentumSections.swift`.
    @State var isArranging = false
    @State var arrangeAreas: [LifeArea] = []
    /// The Momentum close-from-Home flow: the just-closed task (drives the celebration card and
    /// its Undo), the in-flight guard, and the surfaced failure. Internal, not private — the
    /// sections live in `HomeMomentumSections.swift` to keep this type inside its body budget.
    @State var celebratedTask: TaskSummary?
    @State var isClosingTask = false
    @State var closeTaskErrorMessage: String?
    /// A Due-now row's pushed task detail — optional-state + `navigationDestination`, the
    /// TaskListView pattern, since the rows live in a LazyVStack inside this stack.
    @State var inspectingTask: TaskSummary?
    @State var isPresentingWeekReview = false
    @State var homePath = NavigationPath()  // The life-area rows push by value; see +TabRoot.
    /// Variation B's arrival card (block 4c) — `nil` away from every place, or when the place
    /// has nothing open. Internal for `HomeMomentumSections`, which refreshes it.
    @State var arrivalSurface: ArrivalSurface?
    /// The one live routine run, re-read wherever `arrivalSurface` is (F-Routines-4).
    @State var liveRoutineRun: RoutineRun?
    /// Foregrounding refreshes the routine card — see `refreshLiveRoutine` for why nothing
    /// else covers that case.
    @Environment(\.scenePhase) private var homeScenePhase
    /// Internal, not private: the closure card's arrival is built in `HomeMomentumSections`,
    /// and §7.2 has the PARENT read the setting rather than each leaf reaching for it.
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let routineRunStore: RoutineRunStoring = UserDefaultsRoutineRunStore()
    /// **The centre, threaded by hand rather than read from `\.celebrate`** (`F-CTACelebrations-5`).
    /// Home builds its `NudgesService` as a `@StateObject` in `init`, where an `@Environment` value
    /// is not available — and the same value has three more jobs here: the daily-goal request, and
    /// the pushed capture door in `HomeCaptureDoor`. Internal, not private: those live in the
    /// extension files this type is split across.
    let celebrate: any CelebrationRequesting

    init(
        authService: AuthService,
        homeClient: HomeClientAdapting,
        captureClient: CaptureClientAdapting,
        journalClient: JournalClientAdapting? = nil,
        nudgesClient: NudgesClientAdapting,
        nudgeNotificationSchedulingClient: NudgeNotificationSchedulingAdapting,
        lifeAreaDetailClient: LifeAreaDetailClientAdapting,
        taskDetailClient: TaskDetailClientAdapting,
        onStartFocus: ((FocusSprintPlan) -> Void)? = nil,
        focusReloadToken: Int = 0,
        activeSprint: ActiveSprintStatus? = nil,
        widgetSprint: FocusWidgetSnapshot.ActiveSprint? = nil,
        onToggleSprintPause: @escaping () -> Void = {},
        onOpenCaptures: (() -> Void)? = nil,
        taskCreateClient: TaskCreateClientAdapting? = nil,
        widgetPublisher: FocusWidgetPublishing = AppGroupFocusWidgetPublisher(),
        momentumPreferencesStore: MomentumPreferencesStoring = UserDefaultsMomentumPreferencesStore(),
        celebrate: any CelebrationRequesting = InertCelebrationRequester()
    ) {
        self.celebrate = celebrate
        self.momentumPreferencesStore = momentumPreferencesStore
        self.authService = authService
        self.captureClient = captureClient
        self.journalClient = journalClient
        self.lifeAreaDetailClient = lifeAreaDetailClient
        self.taskDetailClient = taskDetailClient
        self.onStartFocus = onStartFocus
        self.focusReloadToken = focusReloadToken
        self.activeSprint = activeSprint
        self.widgetSprint = widgetSprint
        self.onToggleSprintPause = onToggleSprintPause
        self.onOpenCaptures = onOpenCaptures
        self.taskCreateClient = taskCreateClient
        self.widgetPublisher = widgetPublisher
        _homeService = StateObject(wrappedValue: HomeService(client: homeClient))
        _nudgesService = StateObject(
            wrappedValue: NudgesService(
                client: nudgesClient,
                notificationSchedulingClient: nudgeNotificationSchedulingClient,
                celebrate: celebrate
            )
        )
    }

    var body: some View {
        NavigationStack(path: $homePath) {
            Group {
                switch homeService.state {
                case .loading:
                    ProgressView()
                        .accessibilityIdentifier("homeLoadingIndicator")
                case .loaded(let counts):
                    loadedContent(counts: counts)
                case .failed(let message):
                    VStack(spacing: 12) {
                        Text("Couldn't load your life areas")
                            .font(.headline)
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .accessibilityIdentifier("homeErrorMessage")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.pageBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .tabRoot(.today, isAtRoot: isAtTabRoot, onPopToRoot: popToTabRoot)
            .sheet(isPresented: $showSettings) {
                SettingsView(authService: authService)
                    .keyboardDismissal()
            }
            .onAppear { momentumPreferences = momentumPreferencesStore.read() }
            .onChange(of: showSettings) { isPresented in
                if !isPresented { momentumPreferences = momentumPreferencesStore.read() }
            }
            // The full nudge surface, sharing Today's own service so a dismissal on either side
            // is the same list (the `CaptureDetailView` precedent).
            .navigationDestination(isPresented: $isPresentingNudges) {
                NudgesView(service: nudgesService)
            }
            .navigationDestination(isPresented: Binding(
                get: { inspectingHomeCapture != nil },
                set: { if !$0 { inspectingHomeCapture = nil } }
            )) {
                inspectedCaptureDoor
            }
            .onChange(of: inspectingHomeCapture) { capture in
                // Coming back from a capture the user may have promoted, journaled or binned —
                // the card must not keep showing it as waiting.
                if capture == nil { Task { await refreshInboxCount() } }
            }
            .navigationDestination(isPresented: Binding(
                get: { inspectingTask != nil },
                set: { if !$0 { inspectingTask = nil } }
            )) {
                if let task = inspectingTask {
                    inspectedTaskDetail(task)
                }
            }
            .alert(
                "Couldn't update the task",
                isPresented: Binding(
                    get: { closeTaskErrorMessage != nil },
                    set: { if !$0 { closeTaskErrorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(closeTaskErrorMessage ?? "")
            }
            .navigationDestination(isPresented: $isPresentingWeekReview) {
                weekReviewDestination
            }
            .navigationDestination(for: LifeArea.self) { lifeArea in
                LifeAreaDetailView(
                    lifeArea: lifeArea,
                    client: lifeAreaDetailClient,
                    taskDetailClient: taskDetailClient,
                    onStartFocus: onStartFocus,
                    allAreas: homeService.activeAreas,
                    captureClient: captureClient,
                    taskCreateClient: taskCreateClient
                )
            }
            // Start, pause, resume, extend, re-plan, end — every event that changes the sprint's
            // deadline or its checkpoint PLAN. Nothing else: the projection is deadline-derived, so
            // neither a sprint counting down nor a checkpoint being crossed moves this value, and
            // WidgetKit is never asked to reload for the passage of time.
            // The NEW value is republished, never `self.widgetSprint`. `onChange`'s action closure
            // captures the view value it was installed with, so re-reading the stored `let` here
            // publishes the sprint as it was BEFORE the change — which shipped an `activeSprint` of
            // `nil` to the Home Screen at the exact moment a sprint started (caught in-simulator by
            // reading the App Group container, 2026-08-20). `@State`/`@StateObject` reads below are
            // unaffected: those go through storage that is always current.
            .onChange(of: widgetSprint) { publishWidgetSnapshot(sprint: $0) }
            .task {
                await homeService.load()
                // The Active Goal may have changed (a task closed, a new one topping the list),
                // so republish even though the history hasn't moved.
                publishWidgetSnapshot(sprint: widgetSprint)
                // After the tasks land, deliberately — the card is built from them.
                await refreshArrivalSurface()
            }
            .task {
                await refreshInboxCount()
            }
            .task {
                await nudgesService.load()
            }
            .alert(
                "Couldn't save the new order",
                isPresented: Binding(
                    get: { homeService.reorderErrorMessage != nil },
                    set: { if !$0 { homeService.reorderErrorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(homeService.reorderErrorMessage ?? "")
            }
            .onChange(of: homeService.reorderErrorMessage) { message in
                // A rejected reorder reloads the server's order in `HomeService`; leave arrange mode
                // so the grid reflects that order rather than the one the backend refused.
                if message != nil { isArranging = false }
            }
            // E's F7, and BOTH inputs are load-bearing — see `HomeView+DailyGoal`.
            .onChange(of: ringCount) { _ in observeDailyGoal() }
            .onChange(of: ringSettled) { _ in observeDailyGoal() }
            .onChange(of: homeScenePhase) { phase in
                // Cheap and synchronous — one UserDefaults read, no network. See the property.
                if phase == .active { refreshLiveRoutine() }
            }
        }
    }

    /// Active areas share the grid and the reorder list; `HomeService` has already filtered archived
    /// areas out of `counts`, so `counts.map(\.lifeArea)` is exactly the active set.
    @ViewBuilder
    private func loadedContent(counts: [LifeAreaTaskCount]) -> some View {
        let activeAreas = counts.map(\.lifeArea)
        if isArranging {
            VStack(alignment: .leading, spacing: 16) {
                lifeAreasHeader(activeAreas: activeAreas, showArrangeControl: true)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                reorderList
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    todayHeader
                    // The place-aware slot: a live routine, else the arrival card. Both
                    // live in HomeRoutineCard.swift, with the suppression rule between them.
                    arrivalAndRoutineCards
                    // Concept C's scoreboard leads (2026-08-24, Momentum block M1): the closure
                    // ring and streak, then the one task worth doing next. The Active Goal hero's
                    // slot and start-session funnel live on in BestNextMoveCard.
                    scoreboardSection
                    momentumLeadSection
                    // "Arrange" is a reorder affordance over ≥2 cards; hidden below that (§ notes).
                    lifeAreasSection(activeAreas: activeAreas)
                    dueNowSection
                    // Nudges live here now, not in a tab (E, 2026-08-28): the due ones as
                    // dismissable cards, the manager one push away.
                    nudgesSection
                    // The inbox as a Today card (E's 2026-08-25 note): the count and the newest
                    // waiting thoughts, one tap from triage — which is now the Captures tab.
                    inboxPeekCard
                    if !closedToday.isEmpty {
                        Text("Closed today")
                            .sectionLabel()
                            .foregroundStyle(.secondary)
                        MomentumClosedTodayCard(tasks: closedToday)
                    }
                    closedWeekChartSection
                    // The AI summary lives in the week review now (F-V3-WeekReview) — Today
                    // stays the scoreboard, the review carries the recap.
                    weekReviewRow
                    FocusAnalyticsSection(reloadToken: focusReloadToken + pullRefreshCount) { sessions in
                        // Fires on first load, on pull-to-refresh, and on every finished sprint
                        // (`focusReloadToken` is RootView's completedSprintCount) — so the Home
                        // Screen widget follows the same three triggers the in-app charts do.
                        publishedHistory = sessions
                        publishWidgetSnapshot(sprint: widgetSprint)
                    }
                }
                .padding()
                .tabRootScrollAnchor()
            }
            // Today's last card — the week-review door — ended flush against the tab bar, which
            // is where the capture disc floats (E, 2026-08-29).
            .captureDiscClearance()
            // Pull-to-refresh reloads every Home data source in parallel; the analytics section
            // refetches through its reload token rather than a service reference (it owns its
            // own service by design).
            .refreshable { await refreshEverything() }
            // The app-wide write signal (SUGG-b4/b1): any Firestore write — a capture from the
            // global fan, an area recoloured in Settings — refetches Today without a pull.
            .onReceive(DataChangeSignal.changes) { _ in
                Task { await refreshEverything() }
            }
        }
    }

    /// The reorder mode's `List` with `.onMove`, forced into edit mode so the drag grabbers appear.
    /// Chosen over a hand-rolled grid drag because `.onMove` supplies native drag, auto-scroll,
    /// haptics and VoiceOver's reorder rotor for free — and can be driven by `idb` for device proof.
}

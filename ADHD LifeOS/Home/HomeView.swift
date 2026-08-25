//
//  HomeView.swift
//  ADHD LifeOS
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var authService: AuthService
    /// Internal, not private: `HomeAccessoryStrips` reaches it for the reorder list.
    @StateObject var homeService: HomeService
    /// Internal, not private: `HomeAccessoryStrips` reads it from its own file.
    @StateObject var nudgesService: NudgesService
    /// Internal, not private: `HomeMomentumSections` refreshes the inbox count.
    let captureClient: CaptureClientAdapting
    private let journalClient: JournalClientAdapting?
    private let lifeAreaDetailClient: LifeAreaDetailClientAdapting
    /// Internal, not private: `HomeMomentumSections` drives the close-from-Home flow.
    let taskDetailClient: TaskDetailClientAdapting
    /// Internal, not private: `HomeMomentumSections` builds the pushed task detail.
    let schedulingClient: TaskCountdownNudgeSchedulingAdapting
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
    private let widgetSprint: FocusWidgetSnapshot.ActiveSprint?
    private let onToggleSprintPause: () -> Void
    /// Crosses to the Nudges tab — v3's "Nudges waiting" row navigates there instead of
    /// dismissing inline. Wired by `RootView` through its tab selection.
    let onOpenNudges: (() -> Void)?
    /// For the area screen's "Add to <area>" CTA; `nil` hides it (F-V3-AreaDetail).
    private let taskCreateClient: TaskCreateClientAdapting?
    /// Publishes the Home Screen widget's snapshot. Home is the right owner: it is the one screen
    /// holding BOTH halves of what the widget shows — the Active Goal and the week's focus history.
    private let widgetPublisher: FocusWidgetPublishing
    /// The most recent history read, kept so a life-areas reload can republish without refetching.
    /// Internal, not private: the week review reads it from `HomeMomentumSections`.
    @State var publishedHistory: [CompletedFocusSession] = []
    @State private var pullRefreshCount = 0
    /// Internal, not private: the v3 header lives in `HomeMomentumSections.swift`.
    @State var showSettings = false
    /// Re-read each time Settings closes — the sheet is the only writer. Internal for
    /// `HomeMomentumSections`.
    let momentumPreferencesStore: MomentumPreferencesStoring
    @State var momentumPreferences: MomentumPreferences = .default
    /// Internal, not private: the v3 header lives in `HomeMomentumSections.swift`.
    @State var isPresentingInbox = false
    @State var inboxCount = 0
    /// M7: captures whose exit stamp is today, feeding the ring when the Settings toggle counts
    /// them. Refreshed with the inbox count; 0 whenever the toggle is off.
    @State var capturesClearedToday = 0
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

    init(
        authService: AuthService,
        homeClient: HomeClientAdapting,
        captureClient: CaptureClientAdapting,
        journalClient: JournalClientAdapting? = nil,
        nudgesClient: NudgesClientAdapting,
        nudgeNotificationSchedulingClient: NudgeNotificationSchedulingAdapting,
        lifeAreaDetailClient: LifeAreaDetailClientAdapting,
        taskDetailClient: TaskDetailClientAdapting,
        schedulingClient: TaskCountdownNudgeSchedulingAdapting,
        onStartFocus: ((FocusSprintPlan) -> Void)? = nil,
        focusReloadToken: Int = 0,
        activeSprint: ActiveSprintStatus? = nil,
        widgetSprint: FocusWidgetSnapshot.ActiveSprint? = nil,
        onToggleSprintPause: @escaping () -> Void = {},
        onOpenNudges: (() -> Void)? = nil,
        taskCreateClient: TaskCreateClientAdapting? = nil,
        widgetPublisher: FocusWidgetPublishing = AppGroupFocusWidgetPublisher(),
        momentumPreferencesStore: MomentumPreferencesStoring = UserDefaultsMomentumPreferencesStore()
    ) {
        self.momentumPreferencesStore = momentumPreferencesStore
        self.authService = authService
        self.captureClient = captureClient
        self.journalClient = journalClient
        self.lifeAreaDetailClient = lifeAreaDetailClient
        self.taskDetailClient = taskDetailClient
        self.schedulingClient = schedulingClient
        self.onStartFocus = onStartFocus
        self.focusReloadToken = focusReloadToken
        self.activeSprint = activeSprint
        self.widgetSprint = widgetSprint
        self.onToggleSprintPause = onToggleSprintPause
        self.onOpenNudges = onOpenNudges
        self.taskCreateClient = taskCreateClient
        self.widgetPublisher = widgetPublisher
        _homeService = StateObject(wrappedValue: HomeService(client: homeClient))
        _nudgesService = StateObject(
            wrappedValue: NudgesService(
                client: nudgesClient, notificationSchedulingClient: nudgeNotificationSchedulingClient
            )
        )
    }

    /// The FULL set including archived areas — so the Capture triage picker can grey archived areas
    /// rather than being starved of them (they used to be absent entirely here). The grid itself
    /// still shows active areas only, filtered in `HomeService`.
    private var lifeAreasForPicker: [LifeArea] {
        homeService.lifeAreas
    }

    var body: some View {
        NavigationStack {
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
            .sheet(isPresented: $showSettings) {
                SettingsView(authService: authService)
            }
            .onAppear { momentumPreferences = momentumPreferencesStore.read() }
            .onChange(of: showSettings) { isPresented in
                if !isPresented { momentumPreferences = momentumPreferencesStore.read() }
            }
            .navigationDestination(isPresented: $isPresentingInbox) {
                CaptureInboxView(client: captureClient, journalClient: journalClient, lifeAreas: lifeAreasForPicker)
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
                    schedulingClient: schedulingClient,
                    onStartFocus: onStartFocus,
                    allAreas: homeService.activeAreas,
                    captureClient: captureClient,
                    taskCreateClient: taskCreateClient
                )
            }
            .onChange(of: isPresentingInbox) { isPresented in
                if !isPresented {
                    Task { await refreshInboxCount() }
                }
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
            .onChange(of: widgetSprint) { sprint in
                publishWidgetSnapshot(sprint: sprint)
            }
            .task {
                await homeService.load()
                // The Active Goal may have changed (a task closed, a new one topping the list),
                // so republish even though the history hasn't moved.
                publishWidgetSnapshot(sprint: widgetSprint)
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
                    // Concept C's scoreboard leads (2026-08-24, Momentum block M1): the closure
                    // ring and streak, then the one task worth doing next. The Active Goal hero's
                    // slot and start-session funnel live on in BestNextMoveCard.
                    scoreboardSection
                    momentumLeadSection
                    // "Arrange" is a reorder affordance over ≥2 cards; hidden below that (§ notes).
                    lifeAreasSection(activeAreas: activeAreas)
                    dueNowSection
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
            }
            // Pull-to-refresh reloads every Home data source in parallel; the analytics section
            // refetches through its reload token rather than a service reference (it owns its
            // own service by design).
            .refreshable {
                pullRefreshCount += 1
                async let home: Void = homeService.load()
                async let nudges: Void = nudgesService.load()
                async let inbox: Void = refreshInboxCount()
                _ = await (home, nudges, inbox)
                publishWidgetSnapshot(sprint: widgetSprint)
            }
        }
    }

    /// Rebuilds and publishes the Home Screen widget's payload. Cheap, pure and idempotent, so
    /// calling it from every path that changes either half beats working out which half moved.
    /// The sprint is passed in rather than read off `self` — and required, not defaulted, because
    /// "no sprint" is a real value here (a sprint ENDING is exactly when the live section must
    /// disappear) and a default would quietly re-read the stale stored property instead.
    private func publishWidgetSnapshot(sprint: FocusWidgetSnapshot.ActiveSprint?) {
        widgetPublisher.publish(
            FocusWidgetSnapshotBuilder.snapshot(
                activeGoal: homeService.activeGoal,
                lifeAreas: homeService.lifeAreas,
                sessions: publishedHistory,
                activeSprint: sprint
            )
        )
    }

    /// The reorder mode's `List` with `.onMove`, forced into edit mode so the drag grabbers appear.
    /// Chosen over a hand-rolled grid drag because `.onMove` supplies native drag, auto-scroll,
    /// haptics and VoiceOver's reorder rotor for free — and can be driven by `idb` for device proof.
}

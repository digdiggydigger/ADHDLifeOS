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
    private let captureClient: CaptureClientAdapting
    private let journalClient: JournalClientAdapting?
    private let lifeAreaDetailClient: LifeAreaDetailClientAdapting
    private let taskDetailClient: TaskDetailClientAdapting
    private let schedulingClient: TaskCountdownNudgeSchedulingAdapting
    /// Threaded Home → LifeAreaDetail → TaskDetail so the detail screen reached from a life-area
    /// card can launch a sprint on `RootView`'s app-level `FocusSessionService`.
    private let onStartFocus: ((FocusSprintPlan) -> Void)?
    /// `RootView` passes `focusService.completedSprintCount` here; combined with the local
    /// pull-to-refresh count it forms the analytics reload token, so finished sprints AND pulls
    /// both refetch focus history without waiting for a cold launch.
    private let focusReloadToken: Int
    /// The app-wide sprint, so the Active Goal hero can show it is running rather than offering
    /// to start a second one over the top.
    private let activeSprint: ActiveSprintStatus?
    /// The same sprint, projected for the Home Screen widget. Separate from `activeSprint` because
    /// the two answer different questions: the hero only needs "is THIS task's sprint running", the
    /// widget needs the whole deadline-derived payload. Kept deadline-derived and therefore stable
    /// while a sprint merely counts down, so `onChange` fires on real events, not on every tick.
    private let widgetSprint: FocusWidgetSnapshot.ActiveSprint?
    private let onToggleSprintPause: () -> Void
    /// Publishes the Home Screen widget's snapshot. Home is the right owner: it is the one screen
    /// holding BOTH halves of what the widget shows — the Active Goal and the week's focus history.
    private let widgetPublisher: FocusWidgetPublishing
    /// The most recent history read, kept so a life-areas reload can republish without refetching.
    @State private var publishedHistory: [CompletedFocusSession] = []
    @State private var pullRefreshCount = 0
    @State private var showSettings = false
    @State private var isPresentingInbox = false
    @State private var inboxCount = 0
    /// Home's mode-scoped reorder state. `isArranging` swaps the grid for an `.onMove` `List` (E's
    /// settled mechanism); `arrangeAreas` is the live, optimistic ordering the drag mutates. This is
    /// NOT the parked `List`→`LazyVStack` container item — it is a new, separate container.
    @State private var isArranging = false
    @State var arrangeAreas: [LifeArea] = []

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

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
        widgetPublisher: FocusWidgetPublishing = AppGroupFocusWidgetPublisher()
    ) {
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
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isPresentingInbox = true
                    } label: {
                        Label("Inbox (\(inboxCount))", systemImage: "tray")
                    }
                    .accessibilityIdentifier("inboxButton")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityIdentifier("settingsButton")
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(authService: authService)
            }
            .navigationDestination(isPresented: $isPresentingInbox) {
                CaptureInboxView(client: captureClient, journalClient: journalClient, lifeAreas: lifeAreasForPicker)
            }
            .navigationDestination(for: LifeArea.self) { lifeArea in
                LifeAreaDetailView(
                    lifeArea: lifeArea,
                    client: lifeAreaDetailClient,
                    taskDetailClient: taskDetailClient,
                    schedulingClient: schedulingClient,
                    onStartFocus: onStartFocus
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
                    // Web bento Card 1: the Active Goal hero leads the screen. Hidden when no
                    // task is open — never a fabricated placeholder (see ActiveGoalHeroCard).
                    activeGoalHero
                    DailySummaryView(
                        openTaskCount: counts.reduce(0) { $0 + $1.openTaskCount },
                        lifeAreaCount: counts.count,
                        inboxCount: inboxCount,
                        dueNudgeCount: nudgesService.dueNudges().count
                    )
                    dueNudgesStrip
                    // "Arrange" is a reorder affordance over ≥2 cards; hidden below that (§ notes).
                    lifeAreasHeader(activeAreas: activeAreas, showArrangeControl: activeAreas.count >= 2)
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(counts) { count in
                            NavigationLink(value: count.lifeArea) {
                                LifeAreaCardView(count: count)
                            }
                            .buttonStyle(.plain)
                        }
                    }
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

    /// The Active Goal hero for the current top open task (see `ActiveGoalSelection` for the
    /// rule). Start Session resolves the task's own focus config into a `FocusSprintPlan` and
    /// hands it to `RootView`'s app-level `FocusSessionService` — the same funnel (and success
    /// haptic) as every other start path. Manage pushes the task's ACTIVE life area; archived or
    /// unassigned resolve to `nil`, which hides that button.
    @ViewBuilder
    private var activeGoalHero: some View {
        if let goal = homeService.activeGoal {
            let area = homeService.activeAreas.first { $0.id == goal.lifeAreaId }
            ActiveGoalHeroCard(
                task: goal,
                lifeArea: area,
                onStartSession: { onStartFocus?(FocusSprintPlan(summary: goal, lifeArea: area)) },
                activeSprint: activeSprint,
                onToggleSprintPause: onToggleSprintPause
            )
        }
    }

    /// Inline section-header row directly above the grid: a "Life Areas" title and a trailing text
    /// button reading "Arrange" / "Done". Deliberately NOT a toolbar item — the toolbar carries
    /// screen-level navigation (`inboxButton`, `settingsButton`), and a content-mutating mode control
    /// belongs beside the content it mutates. A real text label, never a third competing glyph (§4).
    @ViewBuilder
    private func lifeAreasHeader(activeAreas: [LifeArea], showArrangeControl: Bool) -> some View {
        HStack {
            Text("Life Areas")
                .font(.headline)
            Spacer()
            if showArrangeControl {
                Button(isArranging ? "Done" : "Arrange") {
                    if isArranging {
                        isArranging = false
                        Task { await homeService.load() }
                    } else {
                        arrangeAreas = activeAreas
                        isArranging = true
                    }
                }
                .font(.body.weight(.semibold))
                .frame(minHeight: 44)
                .contentShape(Rectangle())
                .accessibilityIdentifier("homeArrangeButton")
            }
        }
    }

    /// The reorder mode's `List` with `.onMove`, forced into edit mode so the drag grabbers appear.
    /// Chosen over a hand-rolled grid drag because `.onMove` supplies native drag, auto-scroll,
    /// haptics and VoiceOver's reorder rotor for free — and can be driven by `idb` for device proof.
    private func refreshInboxCount() async {
        inboxCount = (try? await captureClient.fetchUnprocessedCaptures().count) ?? inboxCount
    }
}

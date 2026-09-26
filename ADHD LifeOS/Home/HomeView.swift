//
//  HomeView.swift
//  ADHD LifeOS
//

import Combine
import SwiftUI

struct HomeView: View {
    @ObservedObject var authService: AuthService
    /// Internal, not private: the extension files this type is split across read it.
    @StateObject var homeService: HomeService
    /// Internal, not private: the "then" list's due nudges read it from `HomeView+Today`.
    @StateObject var nudgesService: NudgesService
    /// Internal, not private: `HomeMomentumSections` refreshes the inbox count.
    let captureClient: CaptureClientAdapting
    /// Internal, not private: `HomeView+WeeklyChain` reads the journal's lines.
    let journalClient: JournalClientAdapting?
    /// Internal, not private: the one card closes tasks and saves their next step through it.
    let taskDetailClient: TaskDetailClientAdapting
    /// `RootView`'s app-level sprint launcher: the one card's Start and the pushed task detail.
    let onStartFocus: ((FocusSprintPlan) -> Void)?
    /// `RootView` passes `focusService.completedSprintCount` here; combined with the local
    /// pull-to-refresh count it forms the analytics reload token, so finished sprints AND pulls
    /// both refetch focus history without waiting for a cold launch.
    private let focusReloadToken: Int
    /// The app-wide sprint: the one card hides Start while one runs, and a PAUSED one takes the
    /// card as the Resume card (`TodayPausedSprint`). Internal for `HomeView+Today`.
    let activeSprint: ActiveSprintStatus?
    /// The same sprint, projected for the Home Screen widget. Separate from `activeSprint` because
    /// the two answer different questions: the hero only needs "is THIS task's sprint running", the
    /// widget needs the whole deadline-derived payload. Kept deadline-derived and therefore stable
    /// while a sprint merely counts down, so `onChange` fires on real events, not on every tick.
    /// Internal, not private: `HomeView+Refresh` republishes with it.
    let widgetSprint: FocusWidgetSnapshot.ActiveSprint?
    /// The Resume card's action (`F-E3`) — the app-wide sprint's pause TOGGLE, which is why the
    /// Resume card exists only while the sprint is paused.
    let onToggleSprintPause: () -> Void
    /// Publishes the Home Screen widget's snapshot. Home is the right owner: it is the one screen
    /// holding BOTH halves of what the widget shows — the Active Goal and the week's focus history.
    /// Internal, not private: `HomeView+Refresh` publishes through it.
    let widgetPublisher: FocusWidgetPublishing
    /// The most recent history read (`HomeView+FocusHistory`), kept so a life-areas reload can
    /// republish without refetching. Internal: the chain, the week review and the widget read it.
    @State var publishedHistory: [CompletedFocusSession] = []
    /// `F-E3`: Home's own read of the focus history, now that the charts that used to fetch it
    /// have left Today. Internal for `HomeView+FocusHistory`.
    let focusHistoryReader: FocusHistoryReading
    /// Internal, not private: `HomeView+Refresh` bumps it to fold the focus-history read
    /// into every reload.
    @State var pullRefreshCount = 0
    /// Internal, not private: the v3 header lives in `HomeMomentumSections.swift`.
    @State var showSettings = false
    /// Re-read each time Settings closes — the sheet is the only writer. Internal for
    /// `HomeMomentumSections`.
    let momentumPreferencesStore: MomentumPreferencesStoring
    @State var momentumPreferences: MomentumPreferences = .default
    /// The one card's pin and today's "Not this one" set (`F-E3`), read from their per-account
    /// stores by `refreshTodayChoices()`. Internal for `HomeView+Today`.
    @State var pinnedTaskId: UUID?
    @State var skippedTaskIds: Set<UUID> = []
    /// Every waiting capture, for the week review's summary. Internal for `HomeMomentumSections`.
    @State var inboxCount = 0
    /// Captures promoted, journaled or archived TODAY. Ungated, unlike `capturesClearedToday`: the
    /// Settings toggle governs what COUNTS toward the daily goal.
    @State var inboxHandledToday = 0
    /// Whether BOTH capture fetches behind `capturesClearedToday` last succeeded. 0 is a real
    /// count as well as the value a failed `try?` leaves, so without this the daily goal cannot
    /// tell a quiet day from a dropped connection. Internal: `HomeView+DailyGoal` reads it.
    @State var hasLoadedClearedCaptures = false
    /// `F-E1`: the capture and journal stamps behind the weekly chain (`HomeView+WeeklyChain`).
    @State var clearedCaptureStamps: [Date] = []
    @State var journalLineStamps: [Date] = []
    /// Home's memory of the ring between reloads (`F-CTACelebrations-5`, E's F7). `@State`, so it
    /// starts again on relaunch — the once-per-day rule is `CelebrationDayMarking`'s, not this.
    @State var dailyGoalTracker = DailyGoalTracker()
    /// Where the done line's count is, in global coordinates, so R-h's fallback pop leaves from the
    /// count rather than the middle of the screen (the ring's job until `F-E3` retired the ring).
    /// `nil` until the line has been laid out.
    @State var doneLineOrigin: CGPoint?
    /// The close-from-Today flow: the in-flight guard and the surfaced failure. Internal, not
    /// private — `closeTask` lives in `HomeMomentumSections.swift` to keep this type inside its
    /// body budget.
    ///
    /// **`celebratedTask` and the in-place `ClosureCelebrationCard` it drove were retired by
    /// `F-C1-UndoCapsule`** (2026-09-20): with one undo capsule everywhere, Home's lead section has
    /// no reason to hold a celebration state of its own — the closed task drops out of
    /// `homeService.openTasks` on the next `load()` and the next best move recomputes, exactly as
    /// it already did after an Undo.
    @State var isClosingTask = false
    @State var closeTaskErrorMessage: String?
    /// `F-C1-UndoCapsule`: the app's one undo slot. Internal, not private — `closeTask` lives in
    /// `HomeMomentumSections.swift`, and Swift `private` is file-scoped.
    @Environment(\.recordAction) var recordAction
    /// A "then" row's (or an arrival row's) pushed task detail — optional-state +
    /// `navigationDestination`, the TaskListView pattern.
    @State var inspectingTask: TaskSummary?
    @State var isPresentingWeekReview = false
    /// Variation B's arrival card (block 4c) — `nil` away from every place, or when the place
    /// has nothing open. With the live routine it is the one card's place slot (`F-E3`).
    @State var arrivalSurface: ArrivalSurface?
    /// The one live routine run, re-read wherever `arrivalSurface` is (F-Routines-4).
    @State var liveRoutineRun: RoutineRun?
    /// Foregrounding refreshes the routine card — see `refreshLiveRoutine` for why nothing
    /// else covers that case.
    @Environment(\.scenePhase) private var homeScenePhase
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
        taskDetailClient: TaskDetailClientAdapting,
        onStartFocus: ((FocusSprintPlan) -> Void)? = nil,
        focusReloadToken: Int = 0,
        activeSprint: ActiveSprintStatus? = nil,
        widgetSprint: FocusWidgetSnapshot.ActiveSprint? = nil,
        onToggleSprintPause: @escaping () -> Void = {},
        widgetPublisher: FocusWidgetPublishing = AppGroupFocusWidgetPublisher(),
        momentumPreferencesStore: MomentumPreferencesStoring = UserDefaultsMomentumPreferencesStore(),
        focusHistoryReader: FocusHistoryReading = FirebaseFocusSessionAdapter(),
        celebrate: any CelebrationRequesting = InertCelebrationRequester()
    ) {
        self.celebrate = celebrate
        self.focusHistoryReader = focusHistoryReader
        self.momentumPreferencesStore = momentumPreferencesStore
        self.authService = authService
        self.captureClient = captureClient
        self.journalClient = journalClient
        self.taskDetailClient = taskDetailClient
        self.onStartFocus = onStartFocus
        self.focusReloadToken = focusReloadToken
        self.activeSprint = activeSprint
        self.widgetSprint = widgetSprint
        self.onToggleSprintPause = onToggleSprintPause
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
        NavigationStack {
            Group {
                switch homeService.state {
                case .loading:
                    ProgressView()
                        .accessibilityIdentifier("homeLoadingIndicator")
                case .loaded:
                    loadedContent
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
            .onChange(of: showSettings) { _, isPresented in
                if !isPresented { momentumPreferences = momentumPreferencesStore.read() }
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
            .onChange(of: widgetSprint) { _, sprint in publishWidgetSnapshot(sprint: sprint) }
            // The widget's Active Goal IS the card's headline (`F-E3`), so a pin, a skip or a
            // closed task that changes it republishes — the widget and the card never disagree.
            .onChange(of: todayPlan.headlineTask?.id) { publishWidgetSnapshot(sprint: widgetSprint) }
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
            .task(id: focusReloadToken + pullRefreshCount) { await loadFocusHistory() }
            .task {
                // `F-C1-UndoCapsule`: the service owns the recording rule (both `NudgeDueCard`
                // hosts share this one service), and an `@Environment` value cannot be read in the
                // `init` that builds it — so the wiring happens here, before anything can be
                // dismissed. `UndoCapsuleCallSiteTests` holds this line.
                nudgesService.recordAction = recordAction
                await nudgesService.load()
            }
            .task { refreshTodayChoices() }
            // E's F7, and BOTH inputs are load-bearing — see `HomeView+DailyGoal`.
            .onChange(of: ringCount) { observeDailyGoal() }
            .onChange(of: ringSettled) { observeDailyGoal() }
            .onChange(of: homeScenePhase) { _, phase in
                // Cheap and synchronous — one UserDefaults read, no network. See the property.
                if phase == .active { refreshLiveRoutine() }
            }
            // A new day drops yesterday's "Not this one" set; the stores decide, this re-reads.
            .onChange(of: homeScenePhase) { _, phase in
                if phase == .active { refreshTodayChoices() }
            }
        }
    }

    /// Round 3's Structure C: the header, then ONE card, a short "then" list and one quiet done
    /// line — and nothing else (E accepted the done line as the one bend of "nothing else"). The
    /// three are 24pt apart, §2's group separation, as board `59` spaced them.
    private var loadedContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                todayHeader
                VStack(alignment: .leading, spacing: 24) {
                    oneCardSection
                    thenSection
                    doneTodayLine
                }
            }
            .padding()
            .tabRootScrollAnchor()
        }
        // The card's next-step field raises the keyboard; a scroll puts it away.
        .scrollDismissesKeyboard(.interactively)
        // Today's last line — the week-review door — would otherwise end flush against the tab
        // bar, which is where the capture disc floats (E, 2026-08-29).
        .captureDiscClearance()
        // Pull-to-refresh reloads every Home data source in parallel, the focus history with them.
        .refreshable { await refreshEverything() }
        // The app-wide write signal (SUGG-b4/b1): any Firestore write — a capture from the
        // global fan, a next step saved on the card — refetches Today without a pull.
        .onReceive(DataChangeSignal.changes) { _ in
            Task { await refreshEverything() }
        }
    }
}

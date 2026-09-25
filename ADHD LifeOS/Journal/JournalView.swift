//
//  JournalView.swift
//  ADHD LifeOS
//
//  The v3 Journal (F-V3-Journal): one day-grouped stream where written entries and closed tasks
//  sit together — the day as it actually went, not just what was typed. Closed nudges are absent
//  until real completion stamps exist (V3-Nudges). The composer stays a sheet. Its door was a header
//  pencil, sharing the job with a pinned "One line about today…" bar until 2026-09-18, when E chose
//  option 04 from five rendered options — nothing pinned — because the bar *"gets in the way … and
//  reduces viewing space"* (`F-JournalDoorUnpinned`, `screenshots/journal-door-options/`).
//
//  **Since `F-JournalPencilDisc` (the same day) the door is a 42pt disc beside the capture disc**,
//  mounted by `RootBottomOverlay` so it never scrolls away, and this screen keeps the system nav
//  bar: E's *"Keep the nav bar"* — the large title, with the "All activity" eye ALONE top right.
//  The disc's tap arrives here as a request (`onJournalEntryRequest`), because the composer is
//  this screen's private sheet.
//

import Combine
import SwiftUI

/// Internal, not private, wherever the timeline sections need it: the day stream and its rows
/// live in `JournalTimelineSections.swift` for this file's length budget (the
/// `CaptureInboxSections` arrangement).
struct JournalView: View {
    @StateObject var journalService: JournalService
    /// Retained for the capture rows' door — `CaptureInboxService` wants it so "Journal it"
    /// keeps working from a capture opened out of the journal itself.
    let journalClient: JournalClientAdapting
    /// Closed tasks for the interleaved stream — optional so old call sites and previews keep
    /// working without one (the timeline then simply shows written entries only).
    let homeClient: HomeClientAdapting?
    /// The row doors (E's 2026-08-25 review: "the journal becomes a door, not just a record").
    /// All optional: a missing client simply leaves that row kind un-tappable, which is exactly
    /// what previews and the composer's service want.
    let captureClient: CaptureClientAdapting?
    let taskDetailClient: TaskDetailClientAdapting?
    let onStartFocus: ((FocusSprintPlan) -> Void)?
    @State private var isPresentingComposer = false
    @State var filter: JournalTimeline.Filter = .everything
    /// "All activity" (F-RoutineRecord-2, E's call): reveals every routine row — offered, started
    /// and finished. Off on every launch and deliberately NOT persisted — "hidden by default".
    @State var showAllActivity = false
    @State var tasks: [TaskItem] = []
    /// The pushed doors — optional-state + `navigationDestination`, the `CaptureInboxView`
    /// pattern, because the rows live in a `LazyVStack`.
    @State var inspectingTaskId: UUID?
    @State var inspectingCapture: Capture?
    /// The FOLDED days, keyed by their start-of-day date (E, 2026-08-28). Held by exception so an
    /// untouched day is open, and in memory only — which day you folded yesterday is not a
    /// preference worth outliving the session. Internal, not private: the day sections live in
    /// `JournalTimelineSections.swift`.
    @State var collapsedDays: Set<Date> = []
    /// Honoured by the fold animation — §5's Reduce Motion rule.
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    /// `F-CTACelebrations-5`: handed to the pushed capture door, whose service can empty the inbox.
    @Environment(\.celebrate) private var celebrate

    init(
        client: JournalClientAdapting,
        homeClient: HomeClientAdapting? = nil,
        captureClient: CaptureClientAdapting? = nil,
        taskDetailClient: TaskDetailClientAdapting? = nil,
        onStartFocus: ((FocusSprintPlan) -> Void)? = nil
    ) {
        _journalService = StateObject(wrappedValue: JournalService(client: client))
        self.journalClient = client
        self.homeClient = homeClient
        self.captureClient = captureClient
        self.taskDetailClient = taskDetailClient
        self.onStartFocus = onStartFocus
    }

    var canOpenTasks: Bool { taskDetailClient != nil }
    var canOpenCaptures: Bool { captureClient != nil }

    var filteredTasks: [TaskItem] {
        guard let areaId = journalService.selectedLifeAreaId else { return tasks }
        return tasks.filter { $0.lifeAreaId == areaId }
    }

    /// Area-filtered by the EMOJI the sprint stamped at run time — a focus session document
    /// carries no life-area id, only `life_area_emoji`, so this is the honest match available.
    /// A sprint run before an area's emoji changed simply stops matching; history is not rewritten.
    var filteredSprints: [CompletedFocusSession] {
        guard let areaId = journalService.selectedLifeAreaId,
              let emoji = journalService.lifeAreas.first(where: { $0.id == areaId })?.colour
        else { return journalService.focusSessions }
        return journalService.focusSessions.filter { $0.lifeAreaEmoji == emoji }
    }

    var filteredCaptures: [Capture] {
        guard let areaId = journalService.selectedLifeAreaId else { return journalService.captures }
        return journalService.captures.filter { $0.lifeAreaId == areaId }
    }

    func reload() async {
        await journalService.load()
        if let homeClient {
            tasks = (try? await homeClient.fetchAllTasks()) ?? []
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                switch journalService.state {
                case .loading:
                    ProgressView()
                        .accessibilityIdentifier("journalLoadingIndicator")
                case .loaded(let logs):
                    timeline(logs: logs)
                case .failed(let message):
                    VStack(spacing: 8) {
                        Text("Couldn't load your journal")
                            .font(.headline)
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(16)
                    .accessibilityIdentifier("journalErrorMessage")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.pageBackground.ignoresSafeArea())
            // E's "Keep the nav bar" (F-JournalPencilDisc): the system large title replaces the
            // drawn "Journal". §1's `.tracking(-0.5)` cannot reach it without a global
            // `UINavigationBarAppearance`; E chose this by looking at exactly that render.
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    JournalAllActivityButton(isOn: $showAllActivity)
                        // Safe on the container: the button is the ONLY element inside, so
                        // inheritance renames nothing out from under itself.
                        .accessibilityIdentifier("journalAllActivitySwitch")
                }
            }
            // The pencil disc beside the capture disc — its tap is this.
            .onJournalEntryRequest { isPresentingComposer = true }
            // The tab re-tap (E, 2026-09-08): the two pushed doors are the Journal's only depth.
            .tabRoot(.journal, isAtRoot: inspectingTaskId == nil && inspectingCapture == nil) {
                inspectingTaskId = nil
                inspectingCapture = nil
            }
            .sheet(isPresented: $isPresentingComposer) {
                LogComposerView(
                    journalService: journalService,
                    lifeAreas: journalService.lifeAreas,
                    captureClient: captureClient
                ) {
                    Task { await journalService.load() }
                }
                .keyboardDismissal()
            }
            .task {
                await reload()
            }
            .onReceive(DataChangeSignal.changes) { _ in
                Task { await reload() }
            }
            .navigationDestination(isPresented: Binding(
                get: { inspectingTaskId != nil },
                set: { if !$0 { inspectingTaskId = nil } }
            )) {
                if let taskId = inspectingTaskId, let taskDetailClient {
                    TaskDetailView(
                        taskId: taskId,
                        lifeAreas: journalService.lifeAreas,
                        client: taskDetailClient,
                        onStartFocus: onStartFocus,
                        momentumContext: MomentumTaskContext.build(
                            lifeAreaId: tasks.first { $0.id == taskId }?.lifeAreaId,
                            tasks: tasks,
                            lifeAreas: journalService.lifeAreas,
                            showStreaks: UserDefaultsMomentumPreferencesStore().read().showStreaks,
                            // Journal holds all four of the chain's signals — the line the user
                            // just wrote among them — so its door answers from every one.
                            hasCountedToday: WeeklyActiveChain.hasCountedToday(
                                WeeklyActiveChain.Signals(
                                    tasks: tasks,
                                    sessions: journalService.focusSessions,
                                    capturesCleared: journalService.captures.compactMap(\.clearedAt),
                                    journalLines: allLogs.map(\.createdAt)
                                )
                            )
                        )
                    ) {
                        Task { await reload() }
                    }
                }
            }
            .navigationDestination(isPresented: Binding(
                get: { inspectingCapture != nil },
                set: { if !$0 { inspectingCapture = nil } }
            )) {
                if let capture = inspectingCapture, let captureClient {
                    JournalCaptureDoor(
                        captureId: capture.id,
                        lifeAreas: journalService.lifeAreas,
                        client: captureClient,
                        journalClient: journalClient,
                        celebrate: celebrate
                    )
                }
            }
        }
    }

    // MARK: - Header + chips

    /// The day's summary line, first under the large title. It sat above a drawn "Journal" with the
    /// eye and the pencil beside it until `F-JournalPencilDisc`: the title is the system's now, the
    /// eye is in its toolbar, and the pencil is a disc beside the capture disc.
    var header: some View {
        Text(JournalTimeline.headerLine(
            logs: allLogs, tasks: tasks, sprints: journalService.focusSessions
        ))
            .sectionLabel()
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var allLogs: [Log] {
        if case .loaded(let logs) = journalService.state { return logs }
        return []
    }

    var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(JournalTimeline.Filter.allCases, id: \.title) { option in
                    filterChip(option)
                }
                areaChip
            }
        }
    }

    private func filterChip(_ option: JournalTimeline.Filter) -> some View {
        let selected = filter == option
        return Button {
            filter = option
        } label: {
            Text(option.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(selected ? AreaPalette.work.onColor : Color("LabelSecondary"))
                .padding(.horizontal, 16)
                .frame(minHeight: 36)
                .background(
                    selected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color("CardSurfaceSecondary")),
                    in: Capsule()
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    /// The area filter as v3's trailing chip — a menu over the same service selection the old
    /// picker drove.
    private var areaChip: some View {
        Menu {
            Picker("Life Area", selection: $journalService.selectedLifeAreaId) {
                Text("All areas").tag(UUID?.none)
                ForEach(journalService.lifeAreas) { area in
                    Text("\(area.colour) \(area.name)").tag(UUID?.some(area.id))
                }
            }
        } label: {
            let selectedName = journalService.lifeAreas
                .first { $0.id == journalService.selectedLifeAreaId }
                .map { "\($0.colour) \($0.name)" } ?? "All areas"
            Text(selectedName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("LabelSecondary"))
                .padding(.horizontal, 16)
                .frame(minHeight: 36)
                .background(Color("CardSurfaceSecondary"), in: Capsule())
                .contentShape(Capsule())
        }
        .accessibilityIdentifier("journalLifeAreaFilter")
    }
}

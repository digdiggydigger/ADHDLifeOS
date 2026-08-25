//
//  JournalView.swift
//  ADHD LifeOS
//
//  The v3 Journal (F-V3-Journal): one day-grouped stream where written entries and closed tasks
//  sit together — the day as it actually went, not just what was typed. Closed nudges are absent
//  until real completion stamps exist (V3-Nudges). The composer stays a sheet; the bottom bar's
//  "One line about today…" is its door.
//

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
    let schedulingClient: TaskCountdownNudgeSchedulingAdapting?
    let onStartFocus: ((FocusSprintPlan) -> Void)?
    @State private var isPresentingComposer = false
    @State var filter: JournalTimeline.Filter = .everything
    @State var tasks: [TaskItem] = []
    /// The pushed doors — optional-state + `navigationDestination`, the `CaptureInboxView`
    /// pattern, because the rows live in a `LazyVStack`.
    @State var inspectingTaskId: UUID?
    @State var inspectingCapture: Capture?

    init(
        client: JournalClientAdapting,
        homeClient: HomeClientAdapting? = nil,
        captureClient: CaptureClientAdapting? = nil,
        taskDetailClient: TaskDetailClientAdapting? = nil,
        schedulingClient: TaskCountdownNudgeSchedulingAdapting? = nil,
        onStartFocus: ((FocusSprintPlan) -> Void)? = nil
    ) {
        _journalService = StateObject(wrappedValue: JournalService(client: client))
        self.journalClient = client
        self.homeClient = homeClient
        self.captureClient = captureClient
        self.taskDetailClient = taskDetailClient
        self.schedulingClient = schedulingClient
        self.onStartFocus = onStartFocus
    }

    var canOpenTasks: Bool { taskDetailClient != nil && schedulingClient != nil }
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
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) { composerBar }
            .sheet(isPresented: $isPresentingComposer) {
                LogComposerView(journalService: journalService, lifeAreas: journalService.lifeAreas) {
                    Task { await journalService.load() }
                }
            }
            .task {
                await reload()
            }
            .navigationDestination(isPresented: Binding(
                get: { inspectingTaskId != nil },
                set: { if !$0 { inspectingTaskId = nil } }
            )) {
                if let taskId = inspectingTaskId, let taskDetailClient, let schedulingClient {
                    TaskDetailView(
                        taskId: taskId,
                        lifeAreas: journalService.lifeAreas,
                        client: taskDetailClient,
                        schedulingClient: schedulingClient,
                        onStartFocus: onStartFocus,
                        momentumContext: MomentumTaskContext.build(
                            lifeAreaId: tasks.first { $0.id == taskId }?.lifeAreaId,
                            tasks: tasks,
                            lifeAreas: journalService.lifeAreas,
                            showStreaks: UserDefaultsMomentumPreferencesStore().read().showStreaks
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
                        journalClient: journalClient
                    )
                }
            }
        }
    }

    // MARK: - Header + chips

    var header: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(JournalTimeline.headerLine(
                    logs: allLogs, tasks: tasks, sprints: journalService.focusSessions
                ))
                    .sectionLabel()
                    .foregroundStyle(.secondary)
                Text("Journal")
                    .font(.largeTitle.bold())
                    .tracking(-0.5)
            }
            Spacer()
            Button {
                isPresentingComposer = true
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.body)
                    .foregroundStyle(Color("LabelSecondary"))
                    .frame(width: 40, height: 40)
                    .background(Color.cardSurface, in: Circle())
                    .overlay(Circle().strokeBorder(Color.cardBorder, lineWidth: 1))
                    .contentShape(Circle())
            }
            .accessibilityLabel("Write an entry")
            .accessibilityIdentifier("journalComposeButton")
        }
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

    // MARK: - Composer bar

    /// Trailing room for the capture disc: its 60pt circle plus its 16pt margin plus an 8pt gap.
    /// Without it the global FAB floats over this bar's corner and the caption under it
    /// (E's screenshot, 2026-08-25).
    private static let captureDiscClearance: CGFloat = 60 + 16 + 8

    private var composerBar: some View {
        VStack(spacing: 4) {
            Button {
                isPresentingComposer = true
            } label: {
                Text("One line about today…")
                    .font(.callout)
                    .foregroundStyle(Color("LabelSecondary"))
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.cardBorder, lineWidth: 1)
                            .background(
                                Color.cardSurface,
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("journalComposerBar")
            Text("Entries are append-only. Energy and mood are asked once, on save.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.leading, 16)
        .padding(.trailing, Self.captureDiscClearance)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity)
        .composerFooterSurface()
    }
}

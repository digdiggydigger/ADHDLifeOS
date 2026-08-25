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

struct JournalView: View {
    @StateObject private var journalService: JournalService
    /// Closed tasks for the interleaved stream — optional so old call sites and previews keep
    /// working without one (the timeline then simply shows written entries only).
    private let homeClient: HomeClientAdapting?
    @State private var isPresentingComposer = false
    @State private var filter: JournalTimeline.Filter = .everything
    @State private var tasks: [TaskItem] = []

    init(client: JournalClientAdapting, homeClient: HomeClientAdapting? = nil) {
        _journalService = StateObject(wrappedValue: JournalService(client: client))
        self.homeClient = homeClient
    }

    private var filteredTasks: [TaskItem] {
        guard let areaId = journalService.selectedLifeAreaId else { return tasks }
        return tasks.filter { $0.lifeAreaId == areaId }
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
                await journalService.load()
                if let homeClient {
                    tasks = (try? await homeClient.fetchAllTasks()) ?? []
                }
            }
        }
    }

    // MARK: - Header + chips

    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(JournalTimeline.headerLine(logs: allLogs, tasks: tasks))
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

    private var chips: some View {
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
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(.bar)
    }
}

// MARK: - Timeline

extension JournalView {

    func timeline(logs: [Log]) -> some View {
        let days = JournalTimeline.days(logs: logs, tasks: filteredTasks, filter: filter)
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                header
                chips
                if days.isEmpty {
                    Text("Nothing here yet — one line about today is enough to start.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                        .accessibilityIdentifier("journalEmptyState")
                }
                ForEach(days) { day in
                    daySection(day)
                }
            }
            .padding(16)
        }
        .refreshable {
            await journalService.load()
            if let homeClient {
                tasks = (try? await homeClient.fetchAllTasks()) ?? []
            }
        }
    }

    private func daySection(_ day: JournalTimeline.Day) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(day.title)
                .sectionLabel()
                .foregroundStyle(.secondary)
            ForEach(day.entries) { entry in
                switch entry {
                case .log(let log):
                    logRow(log)
                case .closedTask(let task):
                    closedTaskRow(task)
                }
            }
        }
    }

    private func logRow(_ log: Log) -> some View {
        HStack(alignment: .top, spacing: 8) {
            timeGutter(log.entryDate)
                .padding(.top, 16)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(logKindLine(log))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if let mood = log.moodEmoji {
                        Text(mood)
                            .font(.footnote)
                    }
                    if let energy = log.energyLevel {
                        MomentumChip(
                            text: energy.rawValue,
                            background: Color("CardSurfaceSecondary"),
                            foreground: Color("LabelSecondary")
                        )
                    }
                }
                Text(log.body)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .bentoCard()
        }
    }

    private func closedTaskRow(_ task: TaskItem) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            timeGutter(task.completedAt ?? .now)
            Image(systemName: "checkmark")
                .font(.footnote.bold())
                .foregroundStyle(Color("StateGoVivid"))
            Text(task.title)
                .font(.footnote)
                .lineLimit(2)
            Text("task\(areaEmoji(for: task.lifeAreaId).map { " · \($0)" } ?? "")")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .frame(minHeight: 32)
    }

    private func timeGutter(_ date: Date) -> some View {
        Text(date.formatted(date: .omitted, time: .shortened))
            .font(.footnote)
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .frame(width: 52, alignment: .leading)
    }

    private func logKindLine(_ log: Log) -> String {
        let kind = log.type == .journal ? "Journal" : "Log"
        guard
            let areaId = log.lifeAreaId,
            let area = journalService.lifeAreas.first(where: { $0.id == areaId }), !area.archived
        else { return kind }
        return "\(kind) · \(area.colour) \(area.name)"
    }

    private func areaEmoji(for areaId: UUID?) -> String? {
        guard let areaId else { return nil }
        return journalService.lifeAreas.first { $0.id == areaId }?.colour
    }
}

#if DEBUG
private struct PreviewJournalClientAdapting: JournalClientAdapting {
    let lifeArea = LifeArea(id: UUID(), name: "Health", colour: "🫀", sortOrder: 0)

    func fetchLifeAreas() async throws -> [LifeArea] { [lifeArea] }

    func fetchLogs() async throws -> [Log] {
        [
            Log(
                id: UUID(), lifeAreaId: lifeArea.id, type: .journal,
                body: "Feeling a bit foggy today. Drank tea, set 15-minute timers.",
                entryDate: .now, createdAt: .now,
                energyLevel: .medium, moodEmoji: "⚡"
            )
        ]
    }

    func createLog(_ input: NormalizedCreateLogInput) async throws -> Log { fatalError("unused in preview") }
}

#Preview("Light") {
    JournalView(client: PreviewJournalClientAdapting())
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    JournalView(client: PreviewJournalClientAdapting())
        .preferredColorScheme(.dark)
}
#endif

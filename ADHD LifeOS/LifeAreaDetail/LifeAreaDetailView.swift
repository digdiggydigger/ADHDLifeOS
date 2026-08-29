//
//  LifeAreaDetailView.swift
//  ADHD LifeOS
//
//  The v3 area screen (F-V3-AreaDetail): the life area as a place — identity-washed header with
//  the avatar rail, entity-kind filter chips, the task list with tick-to-close, the area's own
//  momentum ring, waiting captures with a real "File here", and an add CTA already filed here.
//  Adaptation, flagged: the system navigation bar stays (inline, untitled) rather than v3's
//  custom back row, so the interactive pop gesture keeps working.
//

import Combine
import SwiftUI

struct LifeAreaDetailView: View {
    /// Internal, not private: the section builders live in `LifeAreaDetailComponents.swift`.
    @StateObject var service: LifeAreaDetailService
    let lifeArea: LifeArea
    /// Every active area, for the rail. Empty hides the rail (old call sites, previews).
    let allAreas: [LifeArea]
    private let taskDetailClient: TaskDetailClientAdapting
    private let taskCreateClient: TaskCreateClientAdapting?
    /// Threaded through to the pushed `TaskDetailView` so its launch row can start an app-level
    /// sprint; `nil` hides that row (previews and hosts with no `FocusSessionService`).
    private let onStartFocus: ((FocusSprintPlan) -> Void)?
    private let momentumPreferencesStore: MomentumPreferencesStoring

    /// Internal, not private: `LifeAreaDetailComponents.swift` reads these.
    @State var filter: AreaDetailFilter = .tasks
    @State var momentumPreferences: MomentumPreferences = .default
    @State var isPresentingAdd = false
    @State var togglingTaskId: UUID?
    @State var toggleErrorMessage: String?

    var family: AreaPalette { AreaPalette.family(for: lifeArea) }

    init(
        lifeArea: LifeArea,
        client: LifeAreaDetailClientAdapting,
        taskDetailClient: TaskDetailClientAdapting,
        onStartFocus: ((FocusSprintPlan) -> Void)? = nil,
        allAreas: [LifeArea] = [],
        captureClient: CaptureClientAdapting? = nil,
        taskCreateClient: TaskCreateClientAdapting? = nil,
        momentumPreferencesStore: MomentumPreferencesStoring = UserDefaultsMomentumPreferencesStore()
    ) {
        _service = StateObject(wrappedValue: LifeAreaDetailService(
            lifeAreaId: lifeArea.id, client: client, captureClient: captureClient
        ))
        self.lifeArea = lifeArea
        self.allAreas = allAreas
        self.taskDetailClient = taskDetailClient
        self.taskCreateClient = taskCreateClient
        self.onStartFocus = onStartFocus
        self.momentumPreferencesStore = momentumPreferencesStore
    }

    var body: some View {
        Group {
            switch service.state {
            case .loading:
                ProgressView()
                    .accessibilityIdentifier("lifeAreaDetailLoadingIndicator")
            case .loaded:
                loadedContent
            case .failed(let message):
                VStack(spacing: 8) {
                    Text("Couldn't load this life area")
                        .font(.headline)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(16)
                .accessibilityIdentifier("lifeAreaDetailErrorMessage")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pageBackground.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .tint(family.color)
        .onReceive(DataChangeSignal.debouncedPublisher()) { _ in
            Task { await service.load() }
        }
        .task {
            // The v3 screen shows open AND closed together (closed rows dim and strike).
            service.statusFilter = .all
            await service.load()
            momentumPreferences = momentumPreferencesStore.read()
        }
        .alert(
            "Couldn't update",
            isPresented: Binding(
                get: { toggleErrorMessage != nil },
                set: { presented in
                    if !presented { toggleErrorMessage = nil }
                }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(toggleErrorMessage ?? "")
        }
        .sheet(
            isPresented: $isPresentingAdd,
            onDismiss: { Task { await service.load() } },
            content: {
            if let taskCreateClient {
                TaskCreateView(
                    client: taskCreateClient,
                    lifeAreas: allAreas.isEmpty ? [lifeArea] : allAreas,
                    preselectedLifeAreaId: lifeArea.id
                ) {
                    isPresentingAdd = false
                }
                .keyboardDismissal()
            }
            }
        )
    }

    private var loadedContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                washHeader
                filterChips
                if filter == .tasks || filter == .all {
                    tasksSection
                    momentumSection
                }
                if filter == .journal || filter == .all {
                    journalSection
                }
                if filter == .captures || filter == .all {
                    capturesSection
                }
                if taskCreateClient != nil {
                    addSection
                }
            }
            .padding(16)
        }
        .captureDiscClearance()
        .refreshable { await service.load() }
        .navigationDestination(for: TaskItem.self) { task in
            TaskDetailView(
                taskId: task.id,
                lifeAreas: allAreas.isEmpty ? [lifeArea] : allAreas,
                client: taskDetailClient,
                onStartFocus: onStartFocus
            ) {
                Task { await service.load() }
            }
        }
    }

    // MARK: - Actions (the components call these)

    /// One-way close (F-V3-Tasks-rebuild, E's addendum): a done row's tick is display-only, so
    /// this only ever sends `.done` — and guards anyway, in case a stale row calls through.
    func closeTask(_ task: TaskItem) {
        guard togglingTaskId == nil, task.status == .open else { return }
        togglingTaskId = task.id
        Task {
            defer { togglingTaskId = nil }
            do {
                _ = try await taskDetailClient.updateStatus(id: task.id, status: .done)
                await service.load()
            } catch {
                toggleErrorMessage =
                    (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }
}

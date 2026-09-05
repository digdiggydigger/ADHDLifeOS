//
//  TaskListView.swift
//  ADHD LifeOS
//

import Combine
import SwiftUI

struct TaskListView: View {
    @StateObject private var tasksService: TasksService
    /// The shared search state, injected by `RootView`. The ROW that opens this lives beside the
    /// capture disc app-level; the SURFACE is presented here, because the tasks are here.
    /// Defaulted through the environment so previews and the UI journeys need no extra wiring.
    @EnvironmentObject private var searchModel: AppSearchModel
    private let taskCreateClient: TaskCreateClientAdapting
    private let taskDetailClient: TaskDetailClientAdapting
    /// Starts an app-level focus sprint from a resolved plan. Owned by `RootView` (which holds
    /// the `FocusSessionService`), so the running bar outlives this screen.
    private let onStartFocus: (FocusSprintPlan) -> Void
    @State private var isPresentingTaskCreate = false
    /// Non-nil while a task's detail screen is pushed. Drives `navigationDestination(isPresented:)`
    /// — the row can't be a `NavigationLink` (its own swipe `DragGesture` would fight the link's
    /// tap), so tap-to-inspect is programmatic.
    @State private var inspectingTask: TaskItem?

    init(
        tasksClient: TasksClientAdapting,
        taskCreateClient: TaskCreateClientAdapting,
        taskDetailClient: TaskDetailClientAdapting,
        onStartFocus: @escaping (FocusSprintPlan) -> Void = { _ in }
    ) {
        _tasksService = StateObject(wrappedValue: TasksService(client: tasksClient))
        self.taskCreateClient = taskCreateClient
        self.taskDetailClient = taskDetailClient
        self.onStartFocus = onStartFocus
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // v3's eyebrow + filter chips (F-V3-Tasks); the sort/priority refinement menu was
                // retired with the F-V3-Tasks-rebuild dense rows — E confirmed it was unused.
                VStack(alignment: .leading, spacing: 8) {
                    Text(MomentumTaskBuckets.headerLine(tasks: tasksService.tasks))
                        .sectionLabel()
                        .foregroundStyle(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(TaskStatusFilterOption.allCases) { option in
                                filterChip(option)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .accessibilityIdentifier("taskStatusFilter")

                Group {
                    switch tasksService.state {
                    case .loading:
                        ProgressView()
                            .accessibilityIdentifier("tasksLoadingIndicator")
                    case .loaded(let groups):
                        if groups.isEmpty {
                            emptyState
                        } else {
                            taskList(groups: groups)
                        }
                    case .failed(let message):
                        VStack(spacing: 12) {
                            Text("Couldn't load your tasks")
                                .font(.headline)
                            Text(message)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .accessibilityIdentifier("tasksErrorMessage")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color.pageBackground.ignoresSafeArea())
            .navigationTitle("Tasks")
            // `.searchable` is GONE, and its absence is the bug fix (F-Search-1-Row). iOS 26
            // renders that field as a capsule pinned to the bottom of the screen and docks it into
            // a `TabView`'s bar; this app has no `TabView` — one folds a sixth tab into "More" —
            // so the capsule stood alone UNDER the custom tab bar, where E photographed it and
            // where it could not be tapped. Search is ours now: the row lives beside the capture
            // disc in `RootBottomOverlay`, and this screen presents the surface it opens.
            .fullScreenCover(isPresented: searchModel.surfacePresentation) {
                TaskSearchSurface(
                    service: tasksService,
                    searchModel: searchModel,
                    onInspect: { inspectingTask = $0 }
                )
            }
            // One writer: the shared query drives this screen's filter, which still runs through
            // `TaskListRefinement` exactly as it did when `.searchable` fed it.
            .onChange(of: searchModel.query) { tasksService.searchText = $0 }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingTaskCreate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityIdentifier("taskCreateButton")
                }
            }
            .sheet(isPresented: $isPresentingTaskCreate) {
                TaskCreateView(
                    client: taskCreateClient,
                    lifeAreas: tasksService.lifeAreas
                ) {
                    Task { await tasksService.load() }
                }
                .keyboardDismissal()
            }
            .task {
                await tasksService.load()
            }
            // BUG-b7's belt-and-braces: the composer's completion already reloads, but ANY write
            // from ANY surface (the fan, Settings, a widget-launched capture) lands here too.
            .onReceive(DataChangeSignal.changes) { _ in
                Task { await tasksService.load() }
            }
            .navigationDestination(isPresented: Binding(
                get: { inspectingTask != nil },
                set: { if !$0 { inspectingTask = nil } }
            )) {
                if let task = inspectingTask {
                    TaskDetailView(
                        taskId: task.id,
                        lifeAreas: tasksService.lifeAreas,
                        client: taskDetailClient,
                        onStartFocus: onStartFocus,
                        momentumContext: MomentumTaskContext.build(
                            lifeAreaId: task.lifeAreaId,
                            tasks: tasksService.tasks,
                            lifeAreas: tasksService.lifeAreas,
                            showStreaks: UserDefaultsMomentumPreferencesStore().read().showStreaks
                        )
                    ) {
                        Task { await tasksService.load() }
                    }
                }
            }
            .alert(
                "Couldn't update the task",
                isPresented: Binding(
                    get: { tasksService.mutationErrorMessage != nil },
                    set: { if !$0 { tasksService.mutationErrorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(tasksService.mutationErrorMessage ?? "")
            }
        }
    }

    /// The grouped list as the design frame draws it (F-V3-Tasks-rebuild): each bucket's dense
    /// `TaskRow`s inside ONE bordered card with inset dividers, under a coloured pinned header.
    /// `ScrollView` + `LazyVStack` per CLAUDE.md §2 — `List` also can't host the row's horizontal
    /// swipe `DragGesture` without its own row-swipe intercepting it.
    private func taskList(groups: [LifeAreaTaskGroup]) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24, pinnedViews: [.sectionHeaders]) {
                ForEach(groups) { group in
                    Section {
                        rowCard(for: group)
                    } header: {
                        // v3's coloured bucket voice: warn for due-today, motion-blue for
                        // tomorrow, closure-green for closed-today; everything else secondary.
                        // The SURFACE is shared (`pinnedSectionHeader()`); only the tone is
                        // this screen's, because only this screen's buckets speak in colour.
                        Text(group.lifeAreaName)
                            .foregroundStyle(headerTone(for: group))
                            .pinnedSectionHeader()
                    }
                }
            }
            .padding(16)
        }
        // Tasks carries the search row, so it reserves the row's height on top of the disc's.
        .captureDiscClearance(hasSearchRow: true)
    }

    private func rowCard(for group: LifeAreaTaskGroup) -> some View {
        // The ▶ sprint launcher rides only the Momentum board's Due-today bucket (E's b11 call:
        // sprint-starting is a today thing; other buckets keep the quieter tap-circle only).
        let showsSprintStart = group.customId == "momentum-dueToday"
        return VStack(spacing: 0) {
            ForEach(Array(group.tasks.enumerated()), id: \.element.id) { index, task in
                let area = tasksService.lifeAreas.first { $0.id == task.lifeAreaId }
                TaskRow(
                    task: task,
                    lifeArea: area,
                    showsSprintStart: showsSprintStart,
                    onClose: { Task { await tasksService.close(task) } },
                    onInspect: { inspectingTask = task },
                    onStartFocus: {
                        onStartFocus(FocusSprintPlan(
                            task: task, lifeArea: area,
                            defaultDurationSeconds:
                                UserDefaultsMomentumPreferencesStore().read().defaultSprintMinutes * 60
                        ))
                    }
                )
                if index != group.tasks.indices.last {
                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.cardBorder, lineWidth: 1)
        )
    }

    /// Momentum's board deliberately holds only today/tomorrow/closed-today, so its empty state
    /// says where the rest went instead of implying there are no tasks at all.
    private var emptyState: some View {
        Text(tasksService.statusFilter == .momentum
                ? "Nothing due today or tomorrow — the rest lives under Open"
                : "No tasks match this filter")
            .font(.headline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityIdentifier("tasksEmptyState")
    }

    private func filterChip(_ option: TaskStatusFilterOption) -> some View {
        let selected = tasksService.statusFilter == option
        return Button {
            Haptics.play(.selection)
            tasksService.statusFilter = option
        } label: {
            Text(option.label)
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

    private func headerTone(for group: LifeAreaTaskGroup) -> Color {
        MomentumTaskBuckets.headerToneAssetName(customId: group.customId)
            .map { Color($0) } ?? Color("LabelSecondary")
    }
}

#if DEBUG
private struct PreviewTasksClientAdapting: TasksClientAdapting {
    let lifeArea = LifeArea(id: UUID(), name: "Health", colour: "🫀", sortOrder: 0)

    func fetchLifeAreas() async throws -> [LifeArea] { [lifeArea] }

    func fetchAllTasks() async throws -> [TaskItem] {
        [
            TaskItem(
                id: UUID(), lifeAreaId: lifeArea.id, title: "Drink water",
                status: .open, priority: .p2, dueDate: .now
            ),
            TaskItem(
                id: UUID(), lifeAreaId: lifeArea.id, title: "Morning walk",
                status: .done, priority: .p4, dueDate: nil, completedAt: .now
            )
        ]
    }

    func setStatus(taskId: UUID, status: TaskStatus) async throws {}
}

private struct PreviewTaskCreateClientAdapting: TaskCreateClientAdapting {
    func fetchTags() async throws -> [Tag] { [] }
    func createTag(name: String) async throws -> Tag { fatalError("unused in preview") }
    func createTask(_ input: NormalizedCreateTaskInput) async throws -> TaskItem { fatalError("unused in preview") }
    func attachTags(taskId: UUID, tagIds: [UUID]) async throws {}
}

private struct PreviewTaskDetailClientAdapting: TaskDetailClientAdapting {
    func fetchTask(id: UUID) async throws -> TaskDetail { fatalError("unused in preview") }
    func fetchTagsForTask(taskId: UUID) async throws -> [Tag] { [] }
    func fetchAllTags() async throws -> [Tag] { [] }
    func updateTask(id: UUID, payload: TaskUpdatePayload) async throws -> TaskDetail {
        fatalError("unused in preview")
    }
    func updateStatus(id: UUID, status: TaskStatus) async throws -> TaskDetail { fatalError("unused in preview") }
    func deleteTask(id: UUID) async throws {}
    func createTag(name: String) async throws -> Tag { fatalError("unused in preview") }
    func addTagToTask(taskId: UUID, tagId: UUID) async throws {}
    func removeTagFromTask(taskId: UUID, tagId: UUID) async throws {}
}

#Preview {
    TaskListView(
        tasksClient: PreviewTasksClientAdapting(),
        taskCreateClient: PreviewTaskCreateClientAdapting(),
        taskDetailClient: PreviewTaskDetailClientAdapting()
    )
    // Required, not decoration: an `@EnvironmentObject` with nothing to resolve traps the moment
    // the body is built, so a preview without this is a preview that cannot render.
    .environmentObject(AppSearchModel())
}
#endif

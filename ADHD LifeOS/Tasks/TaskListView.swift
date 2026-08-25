//
//  TaskListView.swift
//  ADHD LifeOS
//

import SwiftUI

struct TaskListView: View {
    @StateObject private var tasksService: TasksService
    private let taskCreateClient: TaskCreateClientAdapting
    private let taskDetailClient: TaskDetailClientAdapting
    private let schedulingClient: TaskCountdownNudgeSchedulingAdapting
    /// Starts an app-level focus sprint from a resolved plan. Owned by `RootView` (which holds
    /// the `FocusSessionService`), so the running bar outlives this screen.
    private let onStartFocus: (FocusSprintPlan) -> Void
    @State private var isPresentingTaskCreate = false
    /// Non-nil while a task's detail screen is pushed. Drives `navigationDestination(isPresented:)`
    /// — the swipe card can't be a `NavigationLink` (its own `DragGesture` would fight the link's
    /// tap), so tap-to-inspect is programmatic.
    @State private var inspectingTask: TaskItem?

    init(
        tasksClient: TasksClientAdapting,
        taskCreateClient: TaskCreateClientAdapting,
        taskDetailClient: TaskDetailClientAdapting,
        schedulingClient: TaskCountdownNudgeSchedulingAdapting,
        onStartFocus: @escaping (FocusSprintPlan) -> Void = { _ in }
    ) {
        _tasksService = StateObject(wrappedValue: TasksService(client: tasksClient))
        self.taskCreateClient = taskCreateClient
        self.taskDetailClient = taskDetailClient
        self.schedulingClient = schedulingClient
        self.onStartFocus = onStartFocus
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // v3's eyebrow + filter chips replace the segmented picker (F-V3-Tasks).
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
            .searchable(text: $tasksService.searchText, prompt: "Search tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    refinementMenu
                }
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
                    schedulingClient: schedulingClient,
                    lifeAreas: tasksService.lifeAreas
                ) {
                    Task { await tasksService.load() }
                }
            }
            .task {
                await tasksService.load()
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
                        schedulingClient: schedulingClient,
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

    /// The grouped task list, rendered as a `ScrollView` + `LazyVStack` of `SwipeableTaskCard`s
    /// (CLAUDE.md §2 favours this over `List` for non-Settings screens) — `List` also can't host
    /// the card's horizontal `DragGesture` without its own row-swipe intercepting it.
    private func taskList(groups: [LifeAreaTaskGroup]) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24, pinnedViews: [.sectionHeaders]) {
                ForEach(groups) { group in
                    Section {
                        VStack(spacing: 8) {
                            ForEach(group.tasks) { task in
                                let area = tasksService.lifeAreas.first { $0.id == task.lifeAreaId }
                                SwipeableTaskCard(
                                    task: task,
                                    lifeArea: area,
                                    onToggle: { Task { await tasksService.toggleStatus(task) } },
                                    onDelete: { Task { await tasksService.delete(task) } },
                                    onInspect: { inspectingTask = task },
                                    onStartFocus: { onStartFocus(FocusSprintPlan(task: task, lifeArea: area)) }
                                )
                            }
                        }
                    } header: {
                        // v3's coloured bucket voice: warn for due-today, motion-blue for
                        // tomorrow, closure-green for closed-today; everything else secondary.
                        Text(group.lifeAreaName)
                            .sectionLabel()
                            .foregroundStyle(headerTone(for: group))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .background(.bar)
                    }
                }

                if UserDefaultsMomentumPreferencesStore().read().showCharts {
                    TasksFocusWeekSection()
                }
            }
            .padding(16)
        }
    }

    private var emptyState: some View {
        Text("No tasks match this filter")
            .font(.headline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityIdentifier("tasksEmptyState")
    }

    /// Web-parity sort + urgency refinement (`TaskListView.tsx`'s dropdowns), as a native toolbar
    /// menu of inline pickers. The glyph fills in when a non-default refinement is active, so the
    /// state is visible without opening the menu (never colour alone — the fill is a shape change).
    private var refinementMenu: some View {
        Menu {
            Picker("Sort", selection: $tasksService.sortOption) {
                ForEach(TaskSortOption.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
            Picker("Priority", selection: $tasksService.priorityFilter) {
                Text("All Priorities").tag(TaskPriority?.none)
                ForEach(TaskPriority.allCases, id: \.self) { option in
                    Text(option.rawValue.uppercased()).tag(TaskPriority?.some(option))
                }
            }
        } label: {
            Image(systemName: isRefinementActive
                ? "line.3.horizontal.decrease.circle.fill"
                : "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel("Sort and filter")
        .accessibilityIdentifier("taskRefinementMenu")
    }

    private var isRefinementActive: Bool {
        tasksService.sortOption != .standard || tasksService.priorityFilter != nil
    }

    private func filterChip(_ option: TaskStatusFilterOption) -> some View {
        let selected = tasksService.statusFilter == option
        return Button {
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
                status: .open, priority: .p2, dueDate: nil
            ),
            TaskItem(
                id: UUID(), lifeAreaId: lifeArea.id, title: "Morning walk",
                status: .done, priority: .p4, dueDate: nil
            )
        ]
    }

    func setStatus(taskId: UUID, status: TaskStatus) async throws {}
    func deleteTask(taskId: UUID) async throws {}
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
    func createTag(name: String) async throws -> Tag { fatalError("unused in preview") }
    func addTagToTask(taskId: UUID, tagId: UUID) async throws {}
    func removeTagFromTask(taskId: UUID, tagId: UUID) async throws {}
}

private struct PreviewNudgeSchedulingClientAdapting: TaskCountdownNudgeSchedulingAdapting {
    func requestAuthorizationIfNeeded() async -> Bool { false }
    func scheduleNudges(taskId: UUID, taskTitle: String, fireDates: [ScheduledCountdownNudge]) async {}
    func cancelNudges(taskId: UUID) async {}
    func hasScheduledNudges(taskId: UUID) async -> Bool { false }
    func scheduleDueMomentNotification(taskId: UUID, taskTitle: String, dueDate: Date) async {}
    func cancelDueMomentNotification(taskId: UUID) async {}
    func hasDueMomentNotificationScheduled(taskId: UUID) async -> Bool { false }
}

#Preview {
    TaskListView(
        tasksClient: PreviewTasksClientAdapting(),
        taskCreateClient: PreviewTaskCreateClientAdapting(),
        taskDetailClient: PreviewTaskDetailClientAdapting(),
        schedulingClient: PreviewNudgeSchedulingClientAdapting()
    )
}
#endif

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
    @State private var isPresentingTaskCreate = false

    init(
        tasksClient: TasksClientAdapting,
        taskCreateClient: TaskCreateClientAdapting,
        taskDetailClient: TaskDetailClientAdapting,
        schedulingClient: TaskCountdownNudgeSchedulingAdapting
    ) {
        _tasksService = StateObject(wrappedValue: TasksService(client: tasksClient))
        self.taskCreateClient = taskCreateClient
        self.taskDetailClient = taskDetailClient
        self.schedulingClient = schedulingClient
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Status", selection: $tasksService.statusFilter) {
                    ForEach(TaskStatusFilterOption.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
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
                            List {
                                ForEach(groups) { group in
                                    Section(group.lifeAreaName) {
                                        ForEach(group.tasks) { task in
                                            NavigationLink(value: task) {
                                                TaskRowView(task: task)
                                            }
                                        }
                                    }
                                }
                            }
                            .listStyle(.insetGrouped)
                            .navigationDestination(for: TaskItem.self) { task in
                                TaskDetailView(
                                    taskId: task.id,
                                    lifeAreas: tasksService.lifeAreas,
                                    client: taskDetailClient,
                                    schedulingClient: schedulingClient
                                ) {
                                    Task { await tasksService.load() }
                                }
                            }
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
            .navigationTitle("Tasks")
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
                    schedulingClient: schedulingClient,
                    lifeAreas: tasksService.lifeAreas
                ) {
                    Task { await tasksService.load() }
                }
            }
            .task {
                await tasksService.load()
            }
        }
    }

    private var emptyState: some View {
        Text("No tasks match this filter")
            .font(.headline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityIdentifier("tasksEmptyState")
    }
}

private struct TaskRowView: View {
    let task: TaskItem

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.status == .done)
                    .foregroundStyle(task.status == .done ? .secondary : .primary)
                if let dueDate = task.dueDate {
                    Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(task.priority.rawValue.uppercased())
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
    }
}

#if DEBUG
private struct PreviewTasksClientAdapting: TasksClientAdapting {
    let lifeArea = LifeArea(id: UUID(), name: "Health", colour: "#4A90D9", sortOrder: 0)

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

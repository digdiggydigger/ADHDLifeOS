//
//  LifeAreaDetailView.swift
//  ADHD LifeOS
//

import SwiftUI

struct LifeAreaDetailView: View {
    @StateObject private var service: LifeAreaDetailService
    let lifeArea: LifeArea
    private let taskDetailClient: TaskDetailClientAdapting
    private let schedulingClient: TaskCountdownNudgeSchedulingAdapting
    /// Threaded through to the pushed `TaskDetailView` so its launch row can start an app-level
    /// sprint; `nil` hides that row (previews and hosts with no `FocusSessionService`).
    private let onStartFocus: ((FocusSprintPlan) -> Void)?

    init(
        lifeArea: LifeArea,
        client: LifeAreaDetailClientAdapting,
        taskDetailClient: TaskDetailClientAdapting,
        schedulingClient: TaskCountdownNudgeSchedulingAdapting,
        onStartFocus: ((FocusSprintPlan) -> Void)? = nil
    ) {
        _service = StateObject(wrappedValue: LifeAreaDetailService(lifeAreaId: lifeArea.id, client: client))
        self.lifeArea = lifeArea
        self.taskDetailClient = taskDetailClient
        self.schedulingClient = schedulingClient
        self.onStartFocus = onStartFocus
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
                VStack(spacing: 12) {
                    Text("Couldn't load this life area")
                        .font(.headline)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .accessibilityIdentifier("lifeAreaDetailErrorMessage")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pageBackground.ignoresSafeArea())
        .navigationTitle(lifeArea.name)
        .task {
            await service.load()
        }
    }

    private var loadedContent: some View {
        VStack(spacing: 0) {
            Picker("Status", selection: $service.statusFilter) {
                ForEach(TaskStatusFilterOption.standardOptions) { option in
                    Text(option.label).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .accessibilityIdentifier("lifeAreaDetailTaskStatusFilter")

            List {
                Section("Tasks") {
                    if service.filteredTasks.isEmpty {
                        Text("No tasks match this filter")
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("lifeAreaDetailTasksEmptyState")
                    } else {
                        ForEach(service.filteredTasks) { task in
                            NavigationLink(value: task) {
                                LifeAreaDetailTaskRowView(task: task)
                            }
                        }
                    }
                }
                .listRowBackground(Color.cardSurface)
                Section("Journal") {
                    if service.logs.isEmpty {
                        Text("No journal entries for this area")
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("lifeAreaDetailLogsEmptyState")
                    } else {
                        ForEach(service.logs) { log in
                            LifeAreaDetailLogRowView(log: log)
                        }
                    }
                }
                .listRowBackground(Color.cardSurface)
            }
            .listStyle(.insetGrouped)
            // 2026-08-19 bento token pass: prototype page + card-surface rows.
            .scrollContentBackground(.hidden)
            .navigationDestination(for: TaskItem.self) { task in
                TaskDetailView(
                    taskId: task.id,
                    lifeAreas: [lifeArea],
                    client: taskDetailClient,
                    schedulingClient: schedulingClient,
                    onStartFocus: onStartFocus
                ) {
                    Task { await service.load() }
                }
            }
        }
    }
}

private struct LifeAreaDetailTaskRowView: View {
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

private struct LifeAreaDetailLogRowView: View {
    let log: Log

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(log.type == .journal ? "Journal" : "Log")
                    .sectionLabel()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
                Spacer()
                Text(log.entryDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(log.body)
                .font(.body)
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
private struct PreviewLifeAreaDetailClientAdapting: LifeAreaDetailClientAdapting {
    let lifeAreaId: UUID

    func fetchTasks(lifeAreaId: UUID) async throws -> [TaskItem] {
        [
            TaskItem(
                id: UUID(), lifeAreaId: lifeAreaId, title: "Drink water",
                status: .open, priority: .p2, dueDate: nil
            ),
            TaskItem(
                id: UUID(), lifeAreaId: lifeAreaId, title: "Morning walk",
                status: .done, priority: .p4, dueDate: nil
            )
        ]
    }

    func fetchLogs(lifeAreaId: UUID) async throws -> [Log] {
        [
            Log(
                id: UUID(), lifeAreaId: lifeAreaId, type: .journal,
                body: "Went for a run and felt great afterwards.", entryDate: Date(), createdAt: Date()
            )
        ]
    }
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
    let lifeArea = LifeArea(id: UUID(), name: "Health", colour: "#4A90D9", sortOrder: 0)
    NavigationStack {
        LifeAreaDetailView(
            lifeArea: lifeArea,
            client: PreviewLifeAreaDetailClientAdapting(lifeAreaId: lifeArea.id),
            taskDetailClient: PreviewTaskDetailClientAdapting(),
            schedulingClient: PreviewNudgeSchedulingClientAdapting()
        )
    }
}
#endif

//
//  TasksService.swift
//  ADHD LifeOS
//

import Combine
import Foundation

enum TasksLoadState: Equatable {
    case loading
    case loaded([LifeAreaTaskGroup])
    case failed(String)
}

enum TasksServiceError: LocalizedError, Equatable {
    case fetchFailed(String)

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return message
        }
    }
}

@MainActor
final class TasksService: ObservableObject {
    @Published private(set) var state: TasksLoadState = .loading
    @Published var statusFilter: TaskStatusFilterOption = .open {
        didSet {
            guard hasLoadedOnce else { return }
            recomputeGroups()
        }
    }
    /// Web-parity client-side refinement (`TaskListView.tsx`): title search, urgency filter and
    /// sort, recomputed like `statusFilter` so the list responds as the user types/picks.
    @Published var searchText = "" {
        didSet {
            guard hasLoadedOnce else { return }
            recomputeGroups()
        }
    }
    @Published var priorityFilter: TaskPriority? {
        didSet {
            guard hasLoadedOnce else { return }
            recomputeGroups()
        }
    }
    @Published var sortOption: TaskSortOption = .standard {
        didSet {
            guard hasLoadedOnce else { return }
            recomputeGroups()
        }
    }
    /// Set when a swipe mutation (toggle/delete) fails after its optimistic local change has
    /// already been reverted — so the list can surface it without the row silently snapping back
    /// with no explanation.
    @Published var mutationErrorMessage: String?

    private let client: TasksClientAdapting
    private(set) var lifeAreas: [LifeArea] = []
    private var tasks: [TaskItem] = []
    private var hasLoadedOnce = false

    init(client: TasksClientAdapting) {
        self.client = client
    }

    func load() async {
        state = .loading
        do {
            async let lifeAreasResult = client.fetchLifeAreas()
            async let tasksResult = client.fetchAllTasks()
            lifeAreas = try await lifeAreasResult
            tasks = try await tasksResult
            hasLoadedOnce = true
            recomputeGroups()
        } catch {
            hasLoadedOnce = false
            state = .failed((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
        }
    }

    /// Swipe-right: flip a task between open and done. Optimistic — the local flip and regroup
    /// happen immediately (so the row re-sorts under the active filter without waiting on the
    /// network), then the write-through persists to Firestore. A failed write reloads from the
    /// server so the UI never diverges from stored truth.
    func toggleStatus(_ task: TaskItem) async {
        guard hasLoadedOnce, let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        let newStatus: TaskStatus = task.status == .done ? .open : .done
        tasks[index].status = newStatus
        recomputeGroups()
        do {
            try await client.setStatus(taskId: task.id, status: newStatus)
        } catch {
            mutationErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            await load()
        }
    }

    /// Swipe-left: delete a task. Optimistic removal, reverted on a failed delete.
    func delete(_ task: TaskItem) async {
        guard hasLoadedOnce, tasks.contains(where: { $0.id == task.id }) else { return }
        let snapshot = tasks
        tasks.removeAll { $0.id == task.id }
        recomputeGroups()
        do {
            try await client.deleteTask(taskId: task.id)
        } catch {
            tasks = snapshot
            recomputeGroups()
            mutationErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func recomputeGroups() {
        let statusFiltered = TaskStatusFilter.filter(tasks: tasks, by: statusFilter)
        let refined = TaskListRefinement.apply(
            tasks: statusFiltered, searchText: searchText, priorityFilter: priorityFilter, sort: sortOption
        )
        state = .loaded(TaskGrouping.groupTasksByLifeArea(tasks: refined, lifeAreas: lifeAreas))
    }
}

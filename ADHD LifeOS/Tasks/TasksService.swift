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
    @Published var statusFilter: TaskStatusFilterOption = .momentum {
        didSet {
            guard hasLoadedOnce else { return }
            recomputeGroups()
        }
    }
    /// Title search, recomputed like `statusFilter` so the list responds as the user types. The
    /// sort/priority refinement that used to sit beside it was retired in F-V3-Tasks-rebuild.
    @Published var searchText = "" {
        didSet {
            guard hasLoadedOnce else { return }
            recomputeGroups()
        }
    }
    /// Set when a close write fails after its optimistic local change has already been reverted —
    /// so the list can surface it without the row silently snapping back with no explanation.
    @Published var mutationErrorMessage: String?

    private let client: TasksClientAdapting
    private(set) var lifeAreas: [LifeArea] = []
    /// Read by `TaskListView` to build the detail's Momentum context; only this service writes it.
    private(set) var tasks: [TaskItem] = []
    private var hasLoadedOnce = false

    init(client: TasksClientAdapting) {
        self.client = client
    }

    func load() async {
        // Quiet reload (SUGG-b4): only the FIRST load may show the loading state — once content
        // is on screen, a refetch (pull, or the app-wide DataChangeSignal) replaces it in place
        // instead of flashing it away.
        if case .loaded = state {} else { state = .loading }
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

    /// Tap-circle or swipe-right: close an open task. Optimistic: the local flip and regroup
    /// happen immediately (status and `completed_at` move together, so "Closed today" can never
    /// disagree with the list), then the write-through persists to Firestore. A failed write
    /// reloads from the server so the UI never diverges from stored truth.
    ///
    /// **"One-way since F-V3-Tasks-rebuild" was retired on 2026-09-20 by `F-C1-UndoCapsule`** (E's
    /// round 1: *"Every close … shows the same undo, which stays until the user's next action"*).
    /// `reopen(_:)` below is the way back. The close itself is unchanged — the undo is offered by
    /// the capsule, not by this method, and the view records it on this same optimistic edge.
    func close(_ task: TaskItem) async {
        guard hasLoadedOnce, task.status == .open,
              let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index] = TaskCompletionStamp.applying(status: .done, to: tasks[index])
        recomputeGroups()
        do {
            try await client.setStatus(taskId: task.id, status: .done)
        } catch {
            mutationErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            await load()
        }
    }

    /// The undo capsule's way back from `close(_:)` (`F-C1-UndoCapsule`).
    ///
    /// **Not new capability — this path was built for Home's own undo and is reused here.**
    /// `TaskCompletionStamp.applying` already clears `completedAt` on a reopen, and the adapter's
    /// own comment records that a reopen "must not even request a fix". The mirror of `close`
    /// exactly: the same optimistic flip, the same regroup, the same reload-on-failure.
    ///
    /// Guarded on the LOCAL status rather than the caller's copy, so an Undo tapped after a failed
    /// write the reload already reverted is a no-op rather than a second write — which is the
    /// state the capsule is deliberately not modelling with a "pending" flag of its own.
    func reopen(_ task: TaskItem) async {
        guard hasLoadedOnce, let index = tasks.firstIndex(where: { $0.id == task.id }),
              tasks[index].status == .done else { return }
        tasks[index] = TaskCompletionStamp.applying(status: .open, to: tasks[index])
        recomputeGroups()
        do {
            try await client.setStatus(taskId: task.id, status: .open)
        } catch {
            mutationErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            await load()
        }
    }

    private func recomputeGroups() {
        let statusFiltered = TaskStatusFilter.filter(tasks: tasks, by: statusFilter)
        let refined = TaskListRefinement.apply(tasks: statusFiltered, searchText: searchText)
        // Momentum re-groups by dueness; every other filter keeps the life-area grouping.
        state = .loaded(
            statusFilter == .momentum
                ? MomentumTaskBuckets.group(tasks: refined)
                : TaskGrouping.groupTasksByLifeArea(tasks: refined, lifeAreas: lifeAreas)
        )
    }
}

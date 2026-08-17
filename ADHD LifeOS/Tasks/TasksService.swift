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

    private func recomputeGroups() {
        let filtered = TaskStatusFilter.filter(tasks: tasks, by: statusFilter)
        state = .loaded(TaskGrouping.groupTasksByLifeArea(tasks: filtered, lifeAreas: lifeAreas))
    }
}

//
//  LifeAreaDetailService.swift
//  ADHD LifeOS
//

import Combine
import Foundation

@MainActor
final class LifeAreaDetailService: ObservableObject {
    enum LoadState: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    @Published private(set) var state: LoadState = .loading
    @Published var statusFilter: TaskStatusFilterOption = .open {
        didSet {
            guard hasLoadedOnce else { return }
            recomputeFilteredTasks()
        }
    }
    @Published private(set) var filteredTasks: [TaskItem] = []
    @Published private(set) var logs: [Log] = []

    private let lifeAreaId: UUID
    private let client: LifeAreaDetailClientAdapting
    private var tasks: [TaskItem] = []
    private var hasLoadedOnce = false

    init(lifeAreaId: UUID, client: LifeAreaDetailClientAdapting) {
        self.lifeAreaId = lifeAreaId
        self.client = client
    }

    func load() async {
        state = .loading
        do {
            async let tasksResult = client.fetchTasks(lifeAreaId: lifeAreaId)
            async let logsResult = client.fetchLogs(lifeAreaId: lifeAreaId)
            tasks = try await tasksResult
            logs = LogSorting.sortByEntryDateDescending(try await logsResult)
            hasLoadedOnce = true
            recomputeFilteredTasks()
            state = .loaded
        } catch {
            hasLoadedOnce = false
            state = .failed((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
        }
    }

    private func recomputeFilteredTasks() {
        filteredTasks = TaskStatusFilter.filter(tasks: tasks, by: statusFilter)
    }
}

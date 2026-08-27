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
    /// Every waiting capture; the screen keeps the ones filed to THIS area
    /// (`AreaDetailPresentation.capturesFiledHere`). Degrades to empty like the other optional
    /// inputs — losing a capture list must never fail the screen.
    @Published private(set) var captures: [Capture] = []

    let lifeAreaId: UUID
    private let client: LifeAreaDetailClientAdapting
    private let captureClient: CaptureClientAdapting?
    private var tasks: [TaskItem] = []
    private var hasLoadedOnce = false

    /// All of the area's tasks regardless of the filter — the momentum card's input.
    var allTasks: [TaskItem] { tasks }

    init(
        lifeAreaId: UUID,
        client: LifeAreaDetailClientAdapting,
        captureClient: CaptureClientAdapting? = nil
    ) {
        self.lifeAreaId = lifeAreaId
        self.client = client
        self.captureClient = captureClient
    }

    func load() async {
        // Quiet reload (SUGG-b4): only the FIRST load may show the loading state — once content
        // is on screen, a refetch (pull, or the app-wide DataChangeSignal) replaces it in place
        // instead of flashing it away.
        if case .loaded = state {} else { state = .loading }
        do {
            async let tasksResult = client.fetchTasks(lifeAreaId: lifeAreaId)
            async let logsResult = client.fetchLogs(lifeAreaId: lifeAreaId)
            tasks = try await tasksResult
            logs = LogSorting.sortByEntryDateDescending(try await logsResult)
            if let captureClient {
                captures = (try? await captureClient.fetchUnprocessedCaptures()) ?? []
            }
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

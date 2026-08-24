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
    /// Every waiting capture — the v3 screen splits them into filed-here and unfiled
    /// (F-V3-AreaDetail). Degrades to empty like the other optional inputs.
    @Published private(set) var captures: [Capture] = []
    /// Surfaced when a File-here write fails; the view alerts on it.
    @Published var captureFilingErrorMessage: String?

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
        state = .loading
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

    /// The real "File here": writes `life_area_id` through the existing update seam, then
    /// reloads so the capture moves from the unfiled list into filed-here.
    func fileCaptureHere(_ capture: Capture) async {
        guard let captureClient else { return }
        do {
            _ = try await captureClient.updateCapture(
                id: capture.id, changes: CaptureUpdate(lifeAreaId: .some(lifeAreaId))
            )
            await load()
        } catch {
            captureFilingErrorMessage =
                (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

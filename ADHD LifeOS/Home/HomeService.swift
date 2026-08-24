//
//  HomeService.swift
//  ADHD LifeOS
//

import Combine
import Foundation

enum HomeLoadState: Equatable {
    case loading
    case loaded([LifeAreaTaskCount])
    case failed(String)
}

enum HomeServiceError: LocalizedError, Equatable {
    case fetchFailed(String)

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return message
        }
    }
}

@MainActor
final class HomeService: ObservableObject {
    @Published private(set) var state: HomeLoadState = .loading
    /// Set when a reorder is rejected — the view surfaces it and reverts to the server's order.
    @Published var reorderErrorMessage: String?

    private let client: HomeClientAdapting

    /// The FULL fetched set including archived areas. The grid and reorder list use `activeAreas`;
    /// the Capture triage picker (fed from Home) needs the archived ones too, so they are kept here
    /// rather than filtered away in the adapter — the same over-eager filter previously starved that
    /// picker of archived areas entirely.
    private(set) var lifeAreas: [LifeArea] = []

    /// The open tasks behind the counts, retained for the Active Goal hero. `@Published` so the
    /// hero re-renders when a reload changes the headline task.
    @Published private(set) var openTasks: [TaskSummary] = []

    /// Every task, closed ones included — the Momentum scoreboard's raw material. Failure-
    /// tolerant on load: the scoreboard is derived decoration over history, and its fetch failing
    /// must never take the screen down with it.
    @Published private(set) var allTasks: [TaskItem] = []

    /// Serialisation state for TRAP 6 — exactly one reorder in flight at a time.
    private var isReordering = false
    /// The latest ordering produced while a reorder is in flight, coalesced to just the last one
    /// (never a queue of every intermediate state).
    private var pendingOrder: [UUID]?

    init(client: HomeClientAdapting) {
        self.client = client
    }

    /// Active areas in sort order — what the Home grid and the reorder list show.
    var activeAreas: [LifeArea] {
        lifeAreas.filter { !$0.archived }.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Archived areas in their existing relative order — appended to the reorder payload (TRAP 1).
    var archivedAreas: [LifeArea] {
        lifeAreas.filter { $0.archived }.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// The task Home's Active Goal hero headlines; `nil` (hero hidden) when nothing is open.
    var activeGoal: TaskSummary? {
        ActiveGoalSelection.topTask(in: openTasks)
    }

    func load() async {
        state = .loading
        do {
            async let lifeAreasResult = client.fetchLifeAreas()
            async let openTasksResult = client.fetchOpenTasks()
            async let allTasksResult = client.fetchAllTasks()
            lifeAreas = try await lifeAreasResult
            openTasks = try await openTasksResult
            allTasks = (try? await allTasksResult) ?? []
            // The grid excludes archived areas — the filter is applied HERE, at the view/service
            // layer, not in the adapter.
            let counts = LifeAreaTaskCounts.countOpenTasksByLifeArea(
                lifeAreas: lifeAreas.filter { !$0.archived },
                tasks: openTasks
            )
            state = .loaded(counts)
        } catch {
            state = .failed((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
        }
    }

    /// Persist a new ordering of the active areas. Builds the COMPLETE payload (active-first, then
    /// archived) so `validate_reorder` accepts it (TRAP 1), then serialises the write (TRAP 6).
    func submitReorder(activeInNewOrder: [LifeArea]) async {
        let order = LifeAreaReorderPayload.completeOrder(
            activeInNewOrder: activeInNewOrder, archived: archivedAreas
        )
        await submitReorder(order)
    }

    /// Serialised reorder writer. If a write is already in flight, the new ordering is coalesced
    /// into `pendingOrder` (overwriting any earlier pending one) and picked up when the in-flight
    /// write finishes — so two quick drags produce at most two calls, the last carrying the latest
    /// ordering, and the two are never in flight simultaneously.
    func submitReorder(_ order: [UUID]) async {
        if isReordering {
            pendingOrder = order
            return
        }

        isReordering = true
        var current = order
        while true {
            do {
                try await client.reorder(order: current)
            } catch {
                isReordering = false
                pendingOrder = nil
                await handleReorderFailure(error)
                return
            }

            if let next = pendingOrder {
                pendingOrder = nil
                current = next
                continue
            }
            break
        }
        isReordering = false
    }

    /// Never leave the UI showing an order the backend did not accept: reload from the server and
    /// surface a readable message (the adapter has already mapped any error body to plain text).
    private func handleReorderFailure(_ error: Error) async {
        reorderErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        await load()
    }
}

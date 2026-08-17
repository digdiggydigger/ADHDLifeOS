//
//  FakeHomeClientAdapting.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

final class FakeHomeClientAdapting: HomeClientAdapting, @unchecked Sendable {
    var lifeAreasResult: Result<[LifeArea], Error> = .success([])
    var openTasksResult: Result<[TaskSummary], Error> = .success([])
    var reorderResult: Result<Void, Error> = .success(())

    private(set) var fetchLifeAreasCallCount = 0
    private(set) var fetchOpenTasksCallCount = 0
    private(set) var reorderOrders: [[UUID]] = []
    var reorderCallCount: Int { reorderOrders.count }

    /// When `true`, each `reorder` call suspends until `releaseOneReorder()` resumes it — lets a
    /// test hold a reorder "in flight" while it submits a second, proving TRAP 6 serialisation.
    var blocksReorder = false
    private var pending: [CheckedContinuation<Void, Never>] = []
    var pendingReorderCount: Int { pending.count }

    func fetchLifeAreas() async throws -> [LifeArea] {
        fetchLifeAreasCallCount += 1
        return try lifeAreasResult.get()
    }

    func fetchOpenTasks() async throws -> [TaskSummary] {
        fetchOpenTasksCallCount += 1
        return try openTasksResult.get()
    }

    func reorder(order: [UUID]) async throws {
        reorderOrders.append(order)
        if blocksReorder {
            await withCheckedContinuation { pending.append($0) }
        }
        try reorderResult.get()
    }

    /// Resume the oldest suspended reorder, letting it run to completion.
    func releaseOneReorder() {
        guard !pending.isEmpty else { return }
        pending.removeFirst().resume()
    }
}

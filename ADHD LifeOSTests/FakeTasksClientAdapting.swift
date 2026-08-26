//
//  FakeTasksClientAdapting.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

final class FakeTasksClientAdapting: TasksClientAdapting, @unchecked Sendable {
    var lifeAreasResult: Result<[LifeArea], Error> = .success([])
    var tasksResult: Result<[TaskItem], Error> = .success([])

    var setStatusError: Error?

    private(set) var fetchLifeAreasCallCount = 0
    private(set) var fetchAllTasksCallCount = 0
    private(set) var setStatusCalls: [(taskId: UUID, status: TaskStatus)] = []

    func fetchLifeAreas() async throws -> [LifeArea] {
        fetchLifeAreasCallCount += 1
        return try lifeAreasResult.get()
    }

    func fetchAllTasks() async throws -> [TaskItem] {
        fetchAllTasksCallCount += 1
        return try tasksResult.get()
    }

    func setStatus(taskId: UUID, status: TaskStatus) async throws {
        setStatusCalls.append((taskId, status))
        if let setStatusError { throw setStatusError }
    }
}

//
//  FakeTasksClientAdapting.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

final class FakeTasksClientAdapting: TasksClientAdapting, @unchecked Sendable {
    var lifeAreasResult: Result<[LifeArea], Error> = .success([])
    var tasksResult: Result<[TaskItem], Error> = .success([])

    private(set) var fetchLifeAreasCallCount = 0
    private(set) var fetchAllTasksCallCount = 0

    func fetchLifeAreas() async throws -> [LifeArea] {
        fetchLifeAreasCallCount += 1
        return try lifeAreasResult.get()
    }

    func fetchAllTasks() async throws -> [TaskItem] {
        fetchAllTasksCallCount += 1
        return try tasksResult.get()
    }
}

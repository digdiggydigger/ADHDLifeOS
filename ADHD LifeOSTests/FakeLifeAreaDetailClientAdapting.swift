//
//  FakeLifeAreaDetailClientAdapting.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

final class FakeLifeAreaDetailClientAdapting: LifeAreaDetailClientAdapting, @unchecked Sendable {
    var tasksResult: Result<[TaskItem], Error> = .success([])
    var logsResult: Result<[Log], Error> = .success([])

    private(set) var fetchTasksCallCount = 0
    private(set) var fetchLogsCallCount = 0
    private(set) var lastFetchTasksLifeAreaId: UUID?
    private(set) var lastFetchLogsLifeAreaId: UUID?

    func fetchTasks(lifeAreaId: UUID) async throws -> [TaskItem] {
        fetchTasksCallCount += 1
        lastFetchTasksLifeAreaId = lifeAreaId
        return try tasksResult.get()
    }

    func fetchLogs(lifeAreaId: UUID) async throws -> [Log] {
        fetchLogsCallCount += 1
        lastFetchLogsLifeAreaId = lifeAreaId
        return try logsResult.get()
    }
}

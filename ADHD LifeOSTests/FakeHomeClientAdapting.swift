//
//  FakeHomeClientAdapting.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

final class FakeHomeClientAdapting: HomeClientAdapting, @unchecked Sendable {
    var lifeAreasResult: Result<[LifeArea], Error> = .success([])
    var openTasksResult: Result<[TaskSummary], Error> = .success([])
    var allTasksResult: Result<[TaskItem], Error> = .success([])

    private(set) var fetchLifeAreasCallCount = 0
    private(set) var fetchOpenTasksCallCount = 0

    func fetchLifeAreas() async throws -> [LifeArea] {
        fetchLifeAreasCallCount += 1
        return try lifeAreasResult.get()
    }

    func fetchOpenTasks() async throws -> [TaskSummary] {
        fetchOpenTasksCallCount += 1
        return try openTasksResult.get()
    }

    func fetchAllTasks() async throws -> [TaskItem] {
        try allTasksResult.get()
    }
}

//
//  FakeHomeBackingStore.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

/// Recording stand-in for the Firestore surface behind `FirebaseHomeClientAdapter`.
final class FakeHomeBackingStore: HomeBackingStore {
    var lifeAreas: [LifeArea] = []
    var openTasks: [TaskSummary] = []
    var allTasks: [TaskItem] = []

    var fetchLifeAreasError: Error?
    var fetchOpenTasksError: Error?

    private(set) var includeArchivedArguments: [Bool] = []

    func fetchLifeAreas(includeArchived: Bool) async throws -> [LifeArea] {
        includeArchivedArguments.append(includeArchived)
        if let fetchLifeAreasError { throw fetchLifeAreasError }
        return lifeAreas
    }

    func fetchOpenTaskSummaries() async throws -> [TaskSummary] {
        if let fetchOpenTasksError { throw fetchOpenTasksError }
        return openTasks
    }

    func fetchTasks() async throws -> [TaskItem] {
        allTasks
    }
}

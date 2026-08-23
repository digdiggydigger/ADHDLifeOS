//
//  FakeLifeAreaDetailBackingStore.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

/// Recording stand-in for the Firestore surface behind `FirebaseLifeAreaDetailClientAdapter`.
final class FakeLifeAreaDetailBackingStore: LifeAreaDetailBackingStore {
    var tasks: [TaskItem] = []
    var logs: [Log] = []

    var fetchTasksError: Error?
    var fetchLogsError: Error?

    private(set) var taskQueryIds: [UUID] = []
    private(set) var logQueryIds: [UUID] = []

    func fetchTasks(lifeAreaId: UUID) async throws -> [TaskItem] {
        taskQueryIds.append(lifeAreaId)
        if let fetchTasksError { throw fetchTasksError }
        return tasks
    }

    func fetchLogs(lifeAreaId: UUID) async throws -> [Log] {
        logQueryIds.append(lifeAreaId)
        if let fetchLogsError { throw fetchLogsError }
        return logs
    }
}

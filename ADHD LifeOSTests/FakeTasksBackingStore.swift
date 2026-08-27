//
//  FakeTasksBackingStore.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

/// Recording stand-in for the Firestore surface behind `FirebaseTasksClientAdapter`.
/// Same conventions as `FakeLifeAreaEditorBackingStore`: every call is recorded **before** any
/// configured error is thrown, so "called and failed" stays distinguishable from "never called".
final class FakeTasksBackingStore: TasksBackingStore {
    var lifeAreas: [LifeArea] = []
    var tasks: [TaskItem] = []

    var fetchLifeAreasError: Error?
    var fetchTasksError: Error?
    var setStatusError: Error?

    private(set) var includeArchivedArguments: [Bool] = []
    private(set) var fetchTasksCallCount = 0
    /// A named record rather than a tuple — SwiftLint caps tuples at two members, and the stamp
    /// makes this one three.
    struct StatusWrite {
        let id: UUID
        let status: TaskStatus
        let now: Date
    }

    private(set) var statusWrites: [StatusWrite] = []

    func fetchLifeAreas(includeArchived: Bool) async throws -> [LifeArea] {
        includeArchivedArguments.append(includeArchived)
        if let fetchLifeAreasError { throw fetchLifeAreasError }
        return lifeAreas
    }

    func fetchTasks() async throws -> [TaskItem] {
        fetchTasksCallCount += 1
        if let fetchTasksError { throw fetchTasksError }
        return tasks
    }

    func setTaskStatus(id: UUID, status: TaskStatus, now: Date) async throws {
        statusWrites.append(StatusWrite(id: id, status: status, now: now))
        if let setStatusError { throw setStatusError }
    }
}

//
//  FakeRecentlyDeletedBackingStore.swift
//  ADHD LifeOSTests
//
//  `F-C3-RecentlyDeleted`. **With an error hook on every method, deliberately** — F-AdapterDrift's
//  first lesson: `FakeJournalBackingStore` had no error property for its side streams, so those
//  `catch` branches could not be reached by any test and the coverage report blamed the adapter.
//

import Foundation
@testable import ADHD_LifeOS

final class FakeRecentlyDeletedBackingStore: RecentlyDeletedBackingStore, @unchecked Sendable {
    var deletedTasks: [TaskItem] = []
    var deletedCaptures: [Capture] = []
    var fetchTasksError: Error?
    var fetchCapturesError: Error?
    var restoreError: Error?
    var deleteError: Error?

    private(set) var restoredTaskIds: [UUID] = []
    private(set) var restoredCaptureIds: [UUID] = []
    private(set) var hardDeletedTaskIds: [UUID] = []
    private(set) var hardDeletedCaptureIds: [UUID] = []

    func fetchDeletedTasks() async throws -> [TaskItem] {
        if let fetchTasksError { throw fetchTasksError }
        return deletedTasks
    }

    func fetchDeletedCaptures() async throws -> [Capture] {
        if let fetchCapturesError { throw fetchCapturesError }
        return deletedCaptures
    }

    func restoreTask(id: UUID) async throws {
        restoredTaskIds.append(id)
        if let restoreError { throw restoreError }
    }

    func restoreCapture(id: UUID) async throws {
        restoredCaptureIds.append(id)
        if let restoreError { throw restoreError }
    }

    func deleteTask(id: UUID) async throws {
        hardDeletedTaskIds.append(id)
        if let deleteError { throw deleteError }
    }

    func deleteCapture(id: UUID) async throws {
        hardDeletedCaptureIds.append(id)
        if let deleteError { throw deleteError }
    }
}

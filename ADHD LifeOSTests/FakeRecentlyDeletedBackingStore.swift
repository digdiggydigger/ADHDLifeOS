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
    var deletedTags: [Tag] = []
    var liveTags: [Tag] = []
    var fetchTasksError: Error?
    var fetchCapturesError: Error?
    var fetchTagsError: Error?
    var mergeError: Error?
    var restoreError: Error?
    var deleteError: Error?

    private(set) var restoredTaskIds: [UUID] = []
    private(set) var restoredCaptureIds: [UUID] = []
    private(set) var hardDeletedTaskIds: [UUID] = []
    private(set) var hardDeletedCaptureIds: [UUID] = []
    private(set) var restoredTagIds: [UUID] = []
    private(set) var purgedTagIds: [UUID] = []
    private(set) var mergesRestoring: [MergeRestoring] = []
    private(set) var mergesInto: [MergeInto] = []

    /// Named records rather than tuples — SwiftLint caps tuples at two members, and these read
    /// better named anyway: which way round a merge went is the whole assertion.
    struct MergeRestoring: Equatable {
        let survivor: UUID
        let absorbed: UUID
    }

    struct MergeInto: Equatable {
        let tagId: UUID
        let replacement: UUID
    }

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

    func fetchDeletedTags() async throws -> [Tag] {
        if let fetchTagsError { throw fetchTagsError }
        return deletedTags
    }

    func restoreTag(id: UUID) async throws {
        restoredTagIds.append(id)
        if let restoreError { throw restoreError }
    }

    /// Recorded apart from `hardDeletedTaskIds`/`hardDeletedCaptureIds`, because a tag's purge is
    /// not a document delete — it rewrites every referencing task and capture first.
    func purgeTag(id: UUID) async throws {
        purgedTagIds.append(id)
        if let deleteError { throw deleteError }
    }

    func fetchTags() async throws -> [Tag] {
        if let fetchTagsError { throw fetchTagsError }
        return liveTags
    }

    func mergeTagsRestoring(survivor: UUID, absorbed: UUID) async throws {
        mergesRestoring.append(MergeRestoring(survivor: survivor, absorbed: absorbed))
        if let mergeError { throw mergeError }
    }

    func mergeTagInto(_ tagId: UUID, replacement: UUID) async throws {
        mergesInto.append(MergeInto(tagId: tagId, replacement: replacement))
        if let mergeError { throw mergeError }
    }
}

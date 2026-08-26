//
//  FakeTaskDetailBackingStore.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

/// Recording stand-in for the Firestore surface behind `FirebaseTaskDetailClientAdapter`.
///
/// `storedTask` is what a re-read returns. Every mutation here writes to a *different* value than
/// the one the caller supplied, so a test can prove the adapter returns the stored document rather
/// than echoing back the local edit.
final class FakeTaskDetailBackingStore: TaskDetailBackingStore {
    var storedTask: TaskDetail?
    var tags: [Tag] = []
    var tagsForTask: [Tag] = []

    var fetchError: Error?
    var updateError: Error?
    var deleteError: Error?

    private(set) var fetchedIds: [UUID] = []
    private(set) var updates: [TaskUpdateWrite] = []
    private(set) var deletedIds: [UUID] = []
    private(set) var statusWrites: [StatusWrite] = []
    private(set) var createdTagNames: [String] = []
    private(set) var tagLookups: [TagLookup] = []
    private(set) var addedTags: [TagMembershipWrite] = []
    private(set) var removedTags: [TagMembershipWrite] = []

    /// Named records rather than tuples — SwiftLint caps tuples at two members.
    struct TaskUpdateWrite {
        let id: UUID
        let payload: TaskUpdatePayload
    }

    struct StatusWrite {
        let id: UUID
        let status: TaskStatus
        let now: Date
    }

    struct TagLookup {
        let parent: FirebaseTagParent
        let parentId: UUID
    }

    struct TagMembershipWrite {
        let tagId: UUID
        let parent: FirebaseTagParent
        let parentId: UUID
    }

    func fetchTaskDetail(id: UUID) async throws -> TaskDetail {
        fetchedIds.append(id)
        if let fetchError { throw fetchError }
        guard let storedTask else {
            throw FirebaseManagerError.notSignedIn
        }
        return storedTask
    }

    func updateTask(id: UUID, payload: TaskUpdatePayload) async throws {
        updates.append(TaskUpdateWrite(id: id, payload: payload))
        if let updateError { throw updateError }
    }

    func setTaskStatus(id: UUID, status: TaskStatus, now: Date) async throws {
        statusWrites.append(StatusWrite(id: id, status: status, now: now))
        if let updateError { throw updateError }
    }

    func deleteTask(id: UUID) async throws {
        deletedIds.append(id)
        if let deleteError { throw deleteError }
    }

    func fetchTags() async throws -> [Tag] {
        tags
    }

    func createTagDeduplicating(name: String) async throws -> Tag {
        createdTagNames.append(name)
        if let existing = tags.first(where: { $0.name.compare(name, options: [.caseInsensitive]) == .orderedSame }) {
            return existing
        }
        return Tag(id: UUID(), name: name)
    }

    func fetchTags(for parent: FirebaseTagParent, parentId: UUID) async throws -> [Tag] {
        tagLookups.append(TagLookup(parent: parent, parentId: parentId))
        return tagsForTask
    }

    func addTagId(_ tagId: UUID, to parent: FirebaseTagParent, parentId: UUID) async throws {
        addedTags.append(TagMembershipWrite(tagId: tagId, parent: parent, parentId: parentId))
    }

    func removeTagId(_ tagId: UUID, from parent: FirebaseTagParent, parentId: UUID) async throws {
        removedTags.append(TagMembershipWrite(tagId: tagId, parent: parent, parentId: parentId))
    }
}

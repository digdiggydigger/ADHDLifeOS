//
//  FakeTaskCreateBackingStore.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

/// Recording stand-in for the Firestore surface behind `FirebaseTaskCreateClientAdapter`.
final class FakeTaskCreateBackingStore: TaskCreateBackingStore {
    var tags: [Tag] = []

    var createTaskError: Error?
    var addTagError: Error?

    private(set) var createdTasks: [TaskDetail] = []
    private(set) var createdTagNames: [String] = []
    private(set) var tagAttachments: [TagAttachment] = []

    /// Named record rather than a tuple — SwiftLint caps tuples at two members.
    struct TagAttachment {
        let tagId: UUID
        let parent: FirebaseTagParent
        let parentId: UUID
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

    func createTask(_ task: TaskDetail) async throws {
        createdTasks.append(task)
        if let createTaskError { throw createTaskError }
    }

    func addTagId(_ tagId: UUID, to parent: FirebaseTagParent, parentId: UUID) async throws {
        tagAttachments.append(TagAttachment(tagId: tagId, parent: parent, parentId: parentId))
        if let addTagError { throw addTagError }
    }
}

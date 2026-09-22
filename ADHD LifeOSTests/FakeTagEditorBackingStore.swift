//
//  FakeTagEditorBackingStore.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

/// Recording stand-in for the Firestore surface behind `FirebaseTagEditorClientAdapter`.
///
/// `fetchTag(named:)` matches case-insensitively against `tags`, mirroring the manager's real
/// behaviour — the collation is the thing the rename-conflict flow depends on.
final class FakeTagEditorBackingStore: TagEditorBackingStore {
    var tags: [Tag] = []
    var usageCounts: [UUID: Int] = [:]

    var fetchTagsError: Error?
    var usageCountsError: Error?
    var renameError: Error?
    var cascadeError: Error?
    var softDeleteError: Error?
    var restoreError: Error?
    var saveError: Error?

    private(set) var renames: [Rename] = []
    private(set) var cascades: [Cascade] = []
    private(set) var savedTags: [Tag] = []
    private(set) var softDeleted: [UUID] = []
    private(set) var restored: [UUID] = []

    /// Named records rather than tuples — SwiftLint caps tuples at two members.
    struct Rename {
        let id: UUID
        let name: String
    }

    struct Cascade {
        let tagId: UUID
        let replacement: UUID?
    }

    func fetchTags() async throws -> [Tag] {
        if let fetchTagsError { throw fetchTagsError }
        return tags
    }

    func tagUsageCounts() async throws -> [UUID: Int] {
        if let usageCountsError { throw usageCountsError }
        return usageCounts
    }

    func fetchTag(named name: String) async throws -> Tag? {
        if let fetchTagsError { throw fetchTagsError }
        return tags.first { $0.name.compare(name, options: [.caseInsensitive]) == .orderedSame }
    }

    func renameTag(id: UUID, to name: String) async throws {
        renames.append(Rename(id: id, name: name))
        if let renameError { throw renameError }
    }

    func removeTagEverywhere(_ tagId: UUID, replacingWith replacement: UUID?) async throws {
        cascades.append(Cascade(tagId: tagId, replacement: replacement))
        if let cascadeError { throw cascadeError }
    }

    /// **`F-C4-TagsRecentlyDeleted`: what the Tag Editor's delete does now.** Recorded apart
    /// from `cascades` on purpose — the whole point of the block is that these two stopped
    /// being the same write, and a fake that pooled them could not tell a soft delete from
    /// the purge.
    func softDeleteTag(id: UUID, now: Date) async throws {
        softDeleted.append(id)
        if let softDeleteError { throw softDeleteError }
    }

    func restoreTag(id: UUID) async throws {
        restored.append(id)
        if let restoreError { throw restoreError }
    }

    func saveTag(_ tag: Tag) async throws {
        savedTags.append(tag)
        if let saveError { throw saveError }
    }
}

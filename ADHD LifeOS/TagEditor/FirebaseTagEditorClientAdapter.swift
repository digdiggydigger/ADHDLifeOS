//
//  FirebaseTagEditorClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `TagEditorClientAdapting` backed by Firestore through `TagEditorBackingStore`
/// (`FirebaseManager` in the app, a recording fake in tests). The old
/// `GET /tags` computed `usageCount` server-side; here it comes from `tagUsageCounts()` (one
/// read over tasks + captures). Rename `409` → `.needsMerge`, merge, and delete-with-cascade are
/// reproduced client-side with the same typed outcomes, so `TagEditorService`'s alert flows are
/// unchanged.
struct FirebaseTagEditorClientAdapter: TagEditorClientAdapting {
    private let store: TagEditorBackingStore

    init(store: TagEditorBackingStore = FirebaseManager.shared) {
        self.store = store
    }

    func fetchTags() async throws -> [EditableTag] {
        do {
            let tags = try await store.fetchTags()
            let counts = try await store.tagUsageCounts()
            return tags.map { EditableTag(id: $0.id, name: $0.name, usageCount: counts[$0.id] ?? 0) }
        } catch {
            throw TagEditorServiceError.failed(Self.message(for: error))
        }
    }

    func renameTag(id: UUID, to name: String) async throws -> TagRenameOutcome {
        do {
            if let other = try await store.fetchTag(named: name), other.id != id {
                let counts = try await store.tagUsageCounts()
                return .needsMerge(
                    TagRenameConflict(id: other.id, name: other.name, usageCount: counts[other.id] ?? 0)
                )
            }
            try await store.renameTag(id: id, to: name)
            return .renamed
        } catch {
            throw TagEditorServiceError.failed(Self.message(for: error))
        }
    }

    func mergeTag(id: UUID, into name: String) async throws {
        do {
            guard let target = try await store.fetchTag(named: name), target.id != id else {
                throw TagEditorServiceError.failed("There's no other tag named \"\(name)\" to merge into.")
            }
            try await store.removeTagEverywhere(id, replacingWith: target.id)
        } catch let error as TagEditorServiceError {
            throw error
        } catch {
            throw TagEditorServiceError.failed(Self.message(for: error))
        }
    }

    func deleteTag(id: UUID) async throws {
        do {
            try await store.removeTagEverywhere(id, replacingWith: nil)
        } catch {
            throw TagEditorServiceError.failed(Self.message(for: error))
        }
    }

    func createTag(name: String) async throws -> TagCreateOutcome {
        do {
            if let existing = try await store.fetchTag(named: name) {
                let counts = try await store.tagUsageCounts()
                return .alreadyExisted(
                    EditableTag(id: existing.id, name: existing.name, usageCount: counts[existing.id] ?? 0)
                )
            }
            let tag = Tag(id: UUID(), name: name)
            try await store.saveTag(tag)
            return .created(EditableTag(id: tag.id, name: tag.name, usageCount: 0))
        } catch {
            throw TagEditorServiceError.failed(Self.message(for: error))
        }
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}

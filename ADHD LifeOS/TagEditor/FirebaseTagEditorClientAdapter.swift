//
//  FirebaseTagEditorClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `TagEditorClientAdapting` backed by Firestore via `FirebaseManager`. The old
/// `GET /tags` computed `usageCount` server-side; here it comes from `tagUsageCounts()` (one
/// read over tasks + captures). Rename `409` → `.needsMerge`, merge, and delete-with-cascade are
/// reproduced client-side with the same typed outcomes, so `TagEditorService`'s alert flows are
/// unchanged.
struct FirebaseTagEditorClientAdapter: TagEditorClientAdapting {
    private let manager: FirebaseManager

    init(manager: FirebaseManager = .shared) {
        self.manager = manager
    }

    func fetchTags() async throws -> [EditableTag] {
        do {
            let tags = try await manager.fetchTags()
            let counts = try await manager.tagUsageCounts()
            return tags.map { EditableTag(id: $0.id, name: $0.name, usageCount: counts[$0.id] ?? 0) }
        } catch {
            throw TagEditorServiceError.failed(Self.message(for: error))
        }
    }

    func renameTag(id: UUID, to name: String) async throws -> TagRenameOutcome {
        do {
            if let other = try await manager.fetchTag(named: name), other.id != id {
                let counts = try await manager.tagUsageCounts()
                return .needsMerge(
                    TagRenameConflict(id: other.id, name: other.name, usageCount: counts[other.id] ?? 0)
                )
            }
            try await manager.renameTag(id: id, to: name)
            return .renamed
        } catch {
            throw TagEditorServiceError.failed(Self.message(for: error))
        }
    }

    func mergeTag(id: UUID, into name: String) async throws {
        do {
            guard let target = try await manager.fetchTag(named: name), target.id != id else {
                throw TagEditorServiceError.failed("There's no other tag named \"\(name)\" to merge into.")
            }
            try await manager.removeTagEverywhere(id, replacingWith: target.id)
        } catch let error as TagEditorServiceError {
            throw error
        } catch {
            throw TagEditorServiceError.failed(Self.message(for: error))
        }
    }

    func deleteTag(id: UUID) async throws {
        do {
            try await manager.removeTagEverywhere(id, replacingWith: nil)
        } catch {
            throw TagEditorServiceError.failed(Self.message(for: error))
        }
    }

    func createTag(name: String) async throws -> TagCreateOutcome {
        do {
            if let existing = try await manager.fetchTag(named: name) {
                let counts = try await manager.tagUsageCounts()
                return .alreadyExisted(
                    EditableTag(id: existing.id, name: existing.name, usageCount: counts[existing.id] ?? 0)
                )
            }
            let tag = Tag(id: UUID(), name: name)
            try await manager.saveTag(tag)
            return .created(EditableTag(id: tag.id, name: tag.name, usageCount: 0))
        } catch {
            throw TagEditorServiceError.failed(Self.message(for: error))
        }
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}

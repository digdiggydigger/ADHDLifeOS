//
//  FirebaseManager+Tags.swift
//  ADHD LifeOS
//

import FirebaseFirestore
import Foundation

/// Which document kind a tag is attached to. Firestore has no join table — membership is a
/// `tag_ids` string array ON the task/capture document itself (invisible to those models'
/// `Codable`, written only via `arrayUnion`/`arrayRemove` so partial updates never clobber it).
enum FirebaseTagParent {
    case task
    case capture

    var collection: FirebaseManager.Collection {
        switch self {
        case .task: return .tasks
        case .capture: return .captures
        }
    }
}

extension FirebaseManager {
    private static let tagIdsField = "tag_ids"

    // MARK: - Membership

    func addTagId(_ tagId: UUID, to parent: FirebaseTagParent, parentId: UUID) async throws {
        try await collection(parent.collection).document(parentId.uuidString)
            .updateData([Self.tagIdsField: FieldValue.arrayUnion([tagId.uuidString])])
    }

    func removeTagId(_ tagId: UUID, from parent: FirebaseTagParent, parentId: UUID) async throws {
        try await collection(parent.collection).document(parentId.uuidString)
            .updateData([Self.tagIdsField: FieldValue.arrayRemove([tagId.uuidString])])
    }

    /// The parent's current `tag_ids`, resolved against the tags collection so renamed tags show
    /// their current name and dangling ids (tag deleted elsewhere) are silently dropped.
    func fetchTags(for parent: FirebaseTagParent, parentId: UUID) async throws -> [Tag] {
        let document = try await collection(parent.collection).document(parentId.uuidString).getDocument()
        let ids = Set(document.get(Self.tagIdsField) as? [String] ?? [])
        guard !ids.isEmpty else { return [] }
        return try await fetchTags().filter { ids.contains($0.id.uuidString) }
    }

    /// Server-side dedup semantics the old backends provided: an existing tag with the same name
    /// (case-insensitive) is returned as-is instead of creating a duplicate.
    func createTagDeduplicating(name: String) async throws -> Tag {
        if let existing = try await fetchTag(named: name) {
            return existing
        }
        let tag = Tag(id: UUID(), name: name)
        try await saveTag(tag)
        return tag
    }

    func fetchTag(named name: String) async throws -> Tag? {
        try await fetchTags().first { $0.name.compare(name, options: [.caseInsensitive]) == .orderedSame }
    }

    // MARK: - Usage counts / merge / delete (Tag Editor)

    /// Usage per tag id across tasks and captures, from two collection reads — the blank-slate
    /// replacement for the old `GET /tags` server-computed `usageCount`.
    func tagUsageCounts() async throws -> [UUID: Int] {
        var counts: [UUID: Int] = [:]
        for parent in [FirebaseTagParent.task, .capture] {
            let snapshot = try await collection(parent.collection).getDocuments()
            for document in snapshot.documents {
                for raw in document.get(Self.tagIdsField) as? [String] ?? [] {
                    guard let id = UUID(uuidString: raw) else { continue }
                    counts[id, default: 0] += 1
                }
            }
        }
        return counts
    }

    /// Rewrites every reference to `tagId` across tasks and captures — to `replacement` for a
    /// merge, or to nothing for a delete — then removes the tag document itself, mirroring the
    /// old backend's cascade semantics.
    func removeTagEverywhere(_ tagId: UUID, replacingWith replacement: UUID?) async throws {
        let batch = firestoreBatch()
        for parent in [FirebaseTagParent.task, .capture] {
            let referencing = try await collection(parent.collection)
                .whereField(Self.tagIdsField, arrayContains: tagId.uuidString)
                .getDocuments()
            for document in referencing.documents {
                // Compute the final array client-side rather than stacking arrayRemove+arrayUnion
                // writes on one document in one batch — one deterministic write per document.
                let current = document.get(Self.tagIdsField) as? [String] ?? []
                var updated = current.filter { $0 != tagId.uuidString }
                if let replacement, !updated.contains(replacement.uuidString) {
                    updated.append(replacement.uuidString)
                }
                batch.updateData([Self.tagIdsField: updated], forDocument: document.reference)
            }
        }
        try batch.deleteDocument(collection(.tags).document(tagId.uuidString))
        try await batch.commit()
    }

    func renameTag(id: UUID, to name: String) async throws {
        try await update(id: id, fields: ["name": name], in: .tags)
    }
}

// MARK: - Tag documents

/// Moved here from `FirebaseManager.swift` so all tag storage lives in one file.
extension FirebaseManager {
    func fetchTags() async throws -> [Tag] {
        try await fetchAll(Tag.self, from: .tags, orderedBy: "name")
    }

    func saveTag(_ tag: Tag) async throws {
        try await save(tag, id: tag.id, in: .tags)
    }

    func deleteTag(id: UUID) async throws {
        try await delete(id: id, from: .tags)
    }
}

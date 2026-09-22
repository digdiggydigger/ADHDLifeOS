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
        DataChangeSignal.post()
    }

    func removeTagId(_ tagId: UUID, from parent: FirebaseTagParent, parentId: UUID) async throws {
        try await collection(parent.collection).document(parentId.uuidString)
            .updateData([Self.tagIdsField: FieldValue.arrayRemove([tagId.uuidString])])
        DataChangeSignal.post()
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
    /// merge, or to nothing for a purge — then removes the tag document itself.
    ///
    /// **Since `F-C4-TagsRecentlyDeleted` this is no longer what a delete does.** The
    /// `replacingWith: nil` form is the 30-DAY PURGE and "Delete forever": stripping the links is
    /// the irreversible half, and the thirty days exist to buy it back. A screen that wants a tag
    /// gone calls `softDeleteTag(id:)` and this runs later, unchanged, on a tag that has aged out.
    /// The `replacingWith: someId` form is the Tag Editor's merge and is exactly as it was.
    func removeTagEverywhere(_ tagId: UUID, replacingWith replacement: UUID?) async throws {
        let batch = firestoreBatch()
        try await rewriteReferences(to: tagId, as: replacement, in: batch)
        try batch.deleteDocument(collection(.tags).document(tagId.uuidString))
        try await batch.commit()
        DataChangeSignal.post()
    }

    /// **Merge on restore, keeping the tag that was DELETED** (`F-C4-TagsRecentlyDeleted`; E's
    /// Step 0: *"Ask which one survives"*). The live tag's items move onto the survivor, the live
    /// document is destroyed, and the survivor's stamp is erased.
    ///
    /// **One batch, and it has to be one.** Those are two halves of a single user action; split
    /// across two commits, a failure in between leaves the absorbed tag's items pointing at a tag
    /// that is still hidden — worse than either outcome alone. The other direction ("keep the live
    /// one") needs no method of its own: it IS `removeTagEverywhere(deletedId, replacingWith:
    /// liveId)`, the exact call the Tag Editor's rename-clash has always made, which is what the
    /// spec meant by reusing the existing merge.
    ///
    /// **Why this choice is not cosmetic, given both tags wear the same name.** `fetchTag(named:)`
    /// collides case-INSENSITIVELY and the app renders the stored case, so "errand" and "Errand"
    /// are one collision with two spellings. Which document survives decides which spelling the
    /// user is left reading.
    func mergeTagsRestoring(survivor: UUID, absorbed: UUID) async throws {
        let batch = firestoreBatch()
        try await rewriteReferences(to: absorbed, as: survivor, in: batch)
        try batch.deleteDocument(collection(.tags).document(absorbed.uuidString))
        let survivorDocument = try collection(.tags).document(survivor.uuidString)
        batch.updateData(FirestoreFieldPayloads.tagRestore(), forDocument: survivorDocument)
        try await batch.commit()
        DataChangeSignal.post()
    }

    /// Every task and capture carrying `tagId` rewritten to `replacement`, or to nothing.
    ///
    /// Extracted so the cascade and the merge-on-restore share ONE reading of the rule rather than
    /// two — the same argument `live(_:)`/`deleted(_:)` make one file over.
    private func rewriteReferences(
        to tagId: UUID, as replacement: UUID?, in batch: WriteBatch
    ) async throws {
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
    }

    /// The 30-day purge, and "Delete forever" — `removeTagEverywhere`'s no-replacement form under
    /// a name that says when it is allowed to run. Named rather than exposed raw on
    /// `RecentlyDeletedBackingStore`, so that seam cannot reach the MERGE direction.
    func purgeTag(id: UUID) async throws {
        try await removeTagEverywhere(id, replacingWith: nil)
    }

    /// The Tag Editor's merge, and the "keep the live one" half of a merge on restore, under a
    /// name that cannot be confused with `purgeTag`. Same call, one argument apart — which is why
    /// neither seam takes `removeTagEverywhere` directly.
    func mergeTagInto(_ tagId: UUID, replacement: UUID) async throws {
        try await removeTagEverywhere(tagId, replacingWith: replacement)
    }

    func renameTag(id: UUID, to name: String) async throws {
        try await update(id: id, fields: ["name": name], in: .tags)
    }
}

// MARK: - Tag documents

/// Moved here from `FirebaseManager.swift` so all tag storage lives in one file.
extension FirebaseManager {
    /// **The one read every tag surface in the app goes through, which is why one `live(_:)` wrap
    /// hides a deleted tag everywhere** (`F-C4-TagsRecentlyDeleted`). `fetchTags(for:parentId:)`
    /// resolves a parent's ids against this list and `fetchTag(named:)` searches it, so the Tag
    /// Editor, task detail's chip row, the task composer, capture triage, the inbox cards, the
    /// journal timeline, the log composer and Quick Capture all inherit the filter for free.
    ///
    /// **Not `whereField`**, for the reason `FirebaseManager+SoftDelete.swift` records at length:
    /// `isEqualTo: NSNull()` matches only documents where the key is PRESENT and null, and every
    /// tag in the account today has no such key at all.
    func fetchTags() async throws -> [Tag] {
        live(try await fetchAll(Tag.self, from: .tags, orderedBy: "name"))
    }

    /// Recently Deleted's tag list — exactly what `fetchTags()` drops.
    func fetchDeletedTags() async throws -> [Tag] {
        deleted(try await fetchAll(Tag.self, from: .tags, orderedBy: "name"))
    }

    /// Soft delete (`F-C4-TagsRecentlyDeleted`). **The gentlest write in the block: it stamps the
    /// tag document and touches nothing else.**
    ///
    /// Today's delete unlinked and destroyed in one atomic batch (`removeTagEverywhere` below).
    /// This splits that batch in two and defers the second half by thirty days — so what used to
    /// happen at the tap now happens at the purge, and in between the links are all still there.
    /// That is what makes `restoreTag(id:)` able to put the tag back on every item without writing
    /// to a single one of them.
    ///
    /// Going through `update(id:fields:in:)` is load-bearing beyond tidiness: it is the write
    /// plumbing that posts `DataChangeSignal`, which is how a restored tag reappears on every open
    /// chip row at once rather than on the next screen visit.
    func softDeleteTag(id: UUID, now: Date = .now) async throws {
        try await update(id: id, fields: FirestoreFieldPayloads.tagSoftDelete(now: now), in: .tags)
    }

    /// The way back. Erasing the stamp is the ENTIRE restore — see `tagRestore()`.
    func restoreTag(id: UUID) async throws {
        try await update(id: id, fields: FirestoreFieldPayloads.tagRestore(), in: .tags)
    }

    func saveTag(_ tag: Tag) async throws {
        try await save(tag, id: tag.id, in: .tags)
    }

    func deleteTag(id: UUID) async throws {
        try await delete(id: id, from: .tags)
    }
}

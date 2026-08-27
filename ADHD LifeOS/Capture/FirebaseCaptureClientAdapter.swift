//
//  FirebaseCaptureClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `CaptureClientAdapting` backed by Firestore + Firebase Storage through
/// `CaptureBackingStore` (`FirebaseManager` in the app, a recording fake in tests).
///
/// Nothing enriches a capture server-side on Firebase, so `linkPreview`/`aiAssessment` stay `nil`
/// and there are no thumbnails (`photoDisplayURL` already falls back to the full-size image). A
/// new capture is simply `processed: false`, which is the whole of what puts it in the inbox.
struct FirebaseCaptureClientAdapter: CaptureClientAdapting {
    private let store: CaptureBackingStore

    init(store: CaptureBackingStore = FirebaseManager.shared) {
        self.store = store
    }

    func createCapture(_ input: NormalizedCreateCaptureInput) async throws -> Capture {
        // Upload happens before this call (requestUploadURL → uploadMedia → createCapture), so
        // the object exists and its stable download URL can be resolved here.
        var mediaURL: URL?
        if let mediaKey = input.mediaKey {
            mediaURL = try await store.downloadURL(forMediaKey: mediaKey)
        }
        let capture = Capture(
            id: UUID(),
            content: input.content,
            kind: input.kind,
            processed: false,
            createdAt: Date(),
            title: input.title,
            lifeAreaId: input.lifeAreaId,
            mediaURL: mediaURL,
            mediaContentType: input.mediaContentType,
            thumbnailURL: nil,
            linkPreview: nil,
            aiAssessment: nil,
            placeId: input.locationStamp?.placeId,
            latitude: input.locationStamp?.coordinate.latitude,
            longitude: input.locationStamp?.coordinate.longitude
        )
        try await store.saveCapture(capture)
        return capture
    }

    /// `processed == false` minus the seen archive. The query can't express the conjunction
    /// (single-field equality, no composite index), so seen captures are subtracted here — which
    /// also keeps Home's inbox badge honest, since it counts through this method.
    func fetchUnprocessedCaptures() async throws -> [Capture] {
        try await store.fetchUnprocessedCaptures()
            .filter { $0.seen != true }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// The whole collection, every state included — M10's weekly counterweight input. The
    /// manager's query already orders newest-first server-side, so no client-side sort.
    func fetchCaptures() async throws -> [Capture] {
        try await store.fetchCaptures()
    }

    func fetchProcessedCaptures() async throws -> [Capture] {
        try await store.fetchProcessedCaptures()
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Seen-and-not-promoted: a capture archived first and promoted later belongs to the Promoted
    /// slice, so it is dropped here rather than shown in two places.
    func fetchSeenCaptures() async throws -> [Capture] {
        try await store.fetchSeenCaptures()
            .filter { !$0.processed }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func deleteCapture(id: UUID) async throws {
        try await store.deleteCapture(id: id)
    }

    func fetchCapture(id: UUID) async throws -> Capture {
        try await store.fetchCapture(id: id)
    }

    func createTask(_ input: NormalizedPromoteToTaskInput) async throws -> TaskItem {
        let task = TaskDetail(
            id: UUID(),
            lifeAreaId: input.lifeAreaId,
            title: input.title,
            notes: input.notes,
            status: .open,
            priority: input.priority,
            dueDate: input.dueDate,
            createdAt: Date(),
            focusDurationSeconds: input.focusDurationSeconds
        )
        try await store.createTask(task)
        return TaskItem(
            id: task.id,
            lifeAreaId: task.lifeAreaId,
            title: task.title,
            status: task.status,
            priority: task.priority,
            dueDate: task.dueDate
        )
    }

    func markProcessed(captureId: UUID) async throws {
        try await store.markCaptureProcessed(id: captureId)
    }

    func updateCapture(id: UUID, changes: CaptureUpdate) async throws -> Capture {
        try await store.updateCapture(id: id, changes: changes)
        return try await store.fetchCapture(id: id)
    }

    func fetchAllTags() async throws -> [Tag] {
        try await store.fetchTags()
    }

    func createTag(name: String) async throws -> Tag {
        try await store.createTagDeduplicating(name: name)
    }

    func fetchTags(captureId: UUID) async throws -> [Tag] {
        try await store.fetchTags(for: .capture, parentId: captureId)
    }

    func addTag(captureId: UUID, tagId: UUID) async throws {
        try await store.addTagId(tagId, to: .capture, parentId: captureId)
    }

    func removeTag(captureId: UUID, tagId: UUID) async throws {
        try await store.removeTagId(tagId, from: .capture, parentId: captureId)
    }

    func requestUploadURL(kind: CaptureKind, contentType: String) async throws -> CaptureUploadTarget {
        try store.makeUploadTarget(kind: kind, contentType: contentType)
    }

    func uploadMedia(to uploadURL: URL, data: Data, contentType: String) async throws {
        try await store.uploadMedia(to: uploadURL, data: data, contentType: contentType)
    }
}

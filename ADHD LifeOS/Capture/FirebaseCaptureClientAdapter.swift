//
//  FirebaseCaptureClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `CaptureClientAdapting` backed by Firestore + Firebase Storage via
/// `FirebaseManager`. The old backend's server-side jobs don't exist on the blank slate, so:
/// captures are created with `status: .inbox` client-side; `linkPreview`/`aiAssessment` stay
/// `nil` (no enrichment Lambda); and there are no thumbnails (`photoDisplayURL` already falls
/// back to the full-size image).
struct FirebaseCaptureClientAdapter: CaptureClientAdapting {
    private let manager: FirebaseManager

    init(manager: FirebaseManager = .shared) {
        self.manager = manager
    }

    func createCapture(_ input: NormalizedCreateCaptureInput) async throws -> Capture {
        // Upload happens before this call (requestUploadURL → uploadMedia → createCapture), so
        // the object exists and its stable download URL can be resolved here.
        var mediaURL: URL?
        if let mediaKey = input.mediaKey {
            mediaURL = try await manager.downloadURL(forMediaKey: mediaKey)
        }
        let capture = Capture(
            id: UUID(),
            content: input.content,
            kind: input.kind,
            processed: false,
            createdAt: Date(),
            title: input.title,
            status: .inbox,
            lifeAreaId: input.lifeAreaId,
            mediaURL: mediaURL,
            mediaContentType: input.mediaContentType,
            thumbnailURL: nil,
            linkPreview: nil,
            aiAssessment: nil
        )
        try await manager.saveCapture(capture)
        return capture
    }

    func fetchUnprocessedCaptures() async throws -> [Capture] {
        try await manager.fetchUnprocessedCaptures()
            .sorted { $0.createdAt > $1.createdAt }
    }

    func fetchCapture(id: UUID) async throws -> Capture {
        try await manager.fetchCapture(id: id)
    }

    func createTask(_ input: NormalizedPromoteToTaskInput) async throws -> TaskItem {
        let task = TaskDetail(
            id: UUID(),
            lifeAreaId: input.lifeAreaId,
            title: input.title,
            notes: nil,
            status: .open,
            priority: input.priority,
            dueDate: input.dueDate,
            createdAt: Date()
        )
        try await manager.createTask(task)
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
        try await manager.markCaptureProcessed(id: captureId)
    }

    func updateCapture(id: UUID, changes: CaptureUpdate) async throws -> Capture {
        try await manager.updateCapture(id: id, changes: changes)
        return try await manager.fetchCapture(id: id)
    }

    func fetchAllTags() async throws -> [Tag] {
        try await manager.fetchTags()
    }

    func createTag(name: String) async throws -> Tag {
        try await manager.createTagDeduplicating(name: name)
    }

    func fetchTags(captureId: UUID) async throws -> [Tag] {
        try await manager.fetchTags(for: .capture, parentId: captureId)
    }

    func addTag(captureId: UUID, tagId: UUID) async throws {
        try await manager.addTagId(tagId, to: .capture, parentId: captureId)
    }

    func removeTag(captureId: UUID, tagId: UUID) async throws {
        try await manager.removeTagId(tagId, from: .capture, parentId: captureId)
    }

    func requestUploadURL(kind: CaptureKind, contentType: String) async throws -> CaptureUploadTarget {
        try manager.makeUploadTarget(kind: kind, contentType: contentType)
    }

    func uploadMedia(to uploadURL: URL, data: Data, contentType: String) async throws {
        try await manager.uploadMedia(to: uploadURL, data: data, contentType: contentType)
    }
}

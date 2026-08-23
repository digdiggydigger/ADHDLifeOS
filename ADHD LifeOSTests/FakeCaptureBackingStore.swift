//
//  FakeCaptureBackingStore.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

/// Recording stand-in for the Firestore + Storage surface behind `FirebaseCaptureClientAdapter`.
/// Wide because `CaptureClientAdapting` itself is wide — capture owns media upload, triage, tag
/// membership and promotion. Same conventions as the other backing-store fakes: calls are recorded
/// before any configured error is thrown.
final class FakeCaptureBackingStore: CaptureBackingStore {
    var unprocessedCaptures: [Capture] = []
    var processedCaptures: [Capture] = []
    /// What `fetchCapture(id:)` returns — set this to prove a read-after-write returns the *server's*
    /// document rather than a locally assembled one.
    var capturesById: [UUID: Capture] = [:]
    var tags: [Tag] = []
    var tagsByParent: [UUID: [Tag]] = [:]
    var resolvedDownloadURL = URL(string: "https://example.com/media.jpg")!
    var uploadTarget = CaptureUploadTarget(
        uploadURL: URL(string: "gs://bucket/users/uid/captures/object.jpg")!,
        mediaKey: "users/uid/captures/object.jpg",
        thumbnailKey: nil
    )

    var downloadURLError: Error?
    var saveCaptureError: Error?
    var fetchCaptureError: Error?
    var uploadTargetError: Error?

    private(set) var downloadURLKeys: [String] = []
    private(set) var savedCaptures: [Capture] = []
    private(set) var fetchedCaptureIds: [UUID] = []
    private(set) var deletedCaptureIds: [UUID] = []
    private(set) var createdTasks: [TaskDetail] = []
    private(set) var markedProcessedIds: [UUID] = []
    private(set) var captureUpdates: [(id: UUID, changes: CaptureUpdate)] = []
    private(set) var createdTagNames: [String] = []
    private(set) var tagLookups: [(parent: FirebaseTagParent, parentId: UUID)] = []
    private(set) var addedTags: [TagMembershipWrite] = []
    private(set) var removedTags: [TagMembershipWrite] = []
    private(set) var uploadTargetRequests: [(kind: CaptureKind, contentType: String)] = []
    private(set) var uploads: [Upload] = []

    /// Named records rather than tuples — SwiftLint caps tuples at two members.
    struct TagMembershipWrite {
        let tagId: UUID
        let parent: FirebaseTagParent
        let parentId: UUID
    }

    struct Upload {
        let url: URL
        let data: Data
        let contentType: String
    }

    func downloadURL(forMediaKey key: String) async throws -> URL {
        downloadURLKeys.append(key)
        if let downloadURLError { throw downloadURLError }
        return resolvedDownloadURL
    }

    func saveCapture(_ capture: Capture) async throws {
        savedCaptures.append(capture)
        if let saveCaptureError { throw saveCaptureError }
    }

    func fetchUnprocessedCaptures() async throws -> [Capture] {
        unprocessedCaptures
    }

    func fetchProcessedCaptures() async throws -> [Capture] {
        processedCaptures
    }

    func fetchCapture(id: UUID) async throws -> Capture {
        fetchedCaptureIds.append(id)
        if let fetchCaptureError { throw fetchCaptureError }
        guard let capture = capturesById[id] else {
            throw CaptureServiceError.fetchFailed("no capture \(id) in the fake")
        }
        return capture
    }

    func deleteCapture(id: UUID) async throws {
        deletedCaptureIds.append(id)
    }

    func createTask(_ task: TaskDetail) async throws {
        createdTasks.append(task)
    }

    func markCaptureProcessed(id: UUID) async throws {
        markedProcessedIds.append(id)
    }

    func updateCapture(id: UUID, changes: CaptureUpdate) async throws {
        captureUpdates.append((id: id, changes: changes))
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
        tagLookups.append((parent: parent, parentId: parentId))
        return tagsByParent[parentId] ?? []
    }

    func addTagId(_ tagId: UUID, to parent: FirebaseTagParent, parentId: UUID) async throws {
        addedTags.append(TagMembershipWrite(tagId: tagId, parent: parent, parentId: parentId))
    }

    func removeTagId(_ tagId: UUID, from parent: FirebaseTagParent, parentId: UUID) async throws {
        removedTags.append(TagMembershipWrite(tagId: tagId, parent: parent, parentId: parentId))
    }

    func makeUploadTarget(kind: CaptureKind, contentType: String) throws -> CaptureUploadTarget {
        uploadTargetRequests.append((kind: kind, contentType: contentType))
        if let uploadTargetError { throw uploadTargetError }
        return uploadTarget
    }

    func uploadMedia(to uploadURL: URL, data: Data, contentType: String) async throws {
        uploads.append(Upload(url: uploadURL, data: data, contentType: contentType))
    }
}

//
//  FakeCaptureClientAdapting.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

final class FakeCaptureClientAdapting: CaptureClientAdapting, @unchecked Sendable {
    var createCaptureResult: Result<Capture, Error> = .success(
        Capture(id: UUID(), content: "note", kind: .note, processed: false, createdAt: Date())
    )
    var fetchUnprocessedCapturesResult: Result<[Capture], Error> = .success([])
    var fetchProcessedCapturesResult: Result<[Capture], Error> = .success([])
    var deleteCaptureResult: Result<Void, Error> = .success(())
    var fetchCaptureResult: Result<Capture, Error> = .success(
        Capture(id: UUID(), content: "note", kind: .note, processed: false, createdAt: Date())
    )
    var createTaskResult: Result<TaskItem, Error> = .success(
        TaskItem(id: UUID(), lifeAreaId: nil, title: "Task", status: .open, priority: .p4, dueDate: nil)
    )
    var markProcessedResult: Result<Void, Error> = .success(())
    var requestUploadURLResult: Result<CaptureUploadTarget, Error> = .success(
        CaptureUploadTarget(uploadURL: URL(string: "https://example.com/upload")!, mediaKey: "key", thumbnailKey: nil)
    )
    var uploadMediaResult: Result<Void, Error> = .success(())
    var updateCaptureResult: Result<Capture, Error> = .success(
        Capture(id: UUID(), content: "note", kind: .note, processed: false, createdAt: Date())
    )
    var fetchAllTagsResult: Result<[Tag], Error> = .success([])
    var createTagResult: Result<Tag, Error> = .success(Tag(id: UUID(), name: "tag"))
    var fetchTagsResult: Result<[Tag], Error> = .success([])
    var addTagResult: Result<Void, Error> = .success(())
    var removeTagResult: Result<Void, Error> = .success(())

    private(set) var createCaptureCallCount = 0
    private(set) var fetchUnprocessedCapturesCallCount = 0
    private(set) var fetchProcessedCapturesCallCount = 0
    private(set) var deleteCaptureCallCount = 0
    private(set) var lastDeleteCaptureId: UUID?
    private(set) var fetchCaptureCallCount = 0
    private(set) var createTaskCallCount = 0
    private(set) var markProcessedCallCount = 0
    private(set) var requestUploadURLCallCount = 0
    private(set) var uploadMediaCallCount = 0
    private(set) var updateCaptureCallCount = 0
    private(set) var fetchAllTagsCallCount = 0
    private(set) var createTagCallCount = 0
    private(set) var fetchTagsCallCount = 0
    private(set) var addTagCallCount = 0
    private(set) var removeTagCallCount = 0
    private(set) var lastCreateCaptureInput: NormalizedCreateCaptureInput?
    private(set) var lastCreateTaskInput: NormalizedPromoteToTaskInput?
    private(set) var lastMarkProcessedCaptureId: UUID?
    private(set) var lastRequestUploadURLKind: CaptureKind?
    private(set) var lastRequestUploadURLContentType: String?
    private(set) var lastUploadMediaURL: URL?
    private(set) var lastUploadMediaData: Data?
    private(set) var lastUploadMediaContentType: String?
    private(set) var lastUpdateCaptureId: UUID?
    private(set) var lastUpdateCaptureChanges: CaptureUpdate?
    private(set) var lastCreateTagName: String?
    private(set) var lastFetchTagsCaptureId: UUID?
    private(set) var lastAddTagCaptureId: UUID?
    private(set) var lastAddTagTagId: UUID?
    private(set) var lastRemoveTagCaptureId: UUID?
    private(set) var lastRemoveTagTagId: UUID?
    /// Records the name of each protocol method as it's invoked, in order, so tests can assert the
    /// exact call sequence (e.g. requestUploadURL → uploadMedia → createCapture) rather than just
    /// individual call counts.
    private(set) var callLog: [String] = []

    func createCapture(_ input: NormalizedCreateCaptureInput) async throws -> Capture {
        callLog.append("createCapture")
        createCaptureCallCount += 1
        lastCreateCaptureInput = input
        return try createCaptureResult.get()
    }

    func fetchUnprocessedCaptures() async throws -> [Capture] {
        callLog.append("fetchUnprocessedCaptures")
        fetchUnprocessedCapturesCallCount += 1
        return try fetchUnprocessedCapturesResult.get()
    }

    func fetchProcessedCaptures() async throws -> [Capture] {
        fetchProcessedCapturesCallCount += 1
        return try fetchProcessedCapturesResult.get()
    }

    func deleteCapture(id: UUID) async throws {
        deleteCaptureCallCount += 1
        lastDeleteCaptureId = id
        try deleteCaptureResult.get()
    }

    func fetchCapture(id: UUID) async throws -> Capture {
        callLog.append("fetchCapture")
        fetchCaptureCallCount += 1
        return try fetchCaptureResult.get()
    }

    func createTask(_ input: NormalizedPromoteToTaskInput) async throws -> TaskItem {
        callLog.append("createTask")
        createTaskCallCount += 1
        lastCreateTaskInput = input
        return try createTaskResult.get()
    }

    func markProcessed(captureId: UUID) async throws {
        callLog.append("markProcessed")
        markProcessedCallCount += 1
        lastMarkProcessedCaptureId = captureId
        _ = try markProcessedResult.get()
    }

    func requestUploadURL(kind: CaptureKind, contentType: String) async throws -> CaptureUploadTarget {
        callLog.append("requestUploadURL")
        requestUploadURLCallCount += 1
        lastRequestUploadURLKind = kind
        lastRequestUploadURLContentType = contentType
        return try requestUploadURLResult.get()
    }

    func uploadMedia(to uploadURL: URL, data: Data, contentType: String) async throws {
        callLog.append("uploadMedia")
        uploadMediaCallCount += 1
        lastUploadMediaURL = uploadURL
        lastUploadMediaData = data
        lastUploadMediaContentType = contentType
        _ = try uploadMediaResult.get()
    }

    func updateCapture(id: UUID, changes: CaptureUpdate) async throws -> Capture {
        callLog.append("updateCapture")
        updateCaptureCallCount += 1
        lastUpdateCaptureId = id
        lastUpdateCaptureChanges = changes
        return try updateCaptureResult.get()
    }

    func fetchAllTags() async throws -> [Tag] {
        callLog.append("fetchAllTags")
        fetchAllTagsCallCount += 1
        return try fetchAllTagsResult.get()
    }

    func createTag(name: String) async throws -> Tag {
        callLog.append("createTag")
        createTagCallCount += 1
        lastCreateTagName = name
        return try createTagResult.get()
    }

    func fetchTags(captureId: UUID) async throws -> [Tag] {
        callLog.append("fetchTags")
        fetchTagsCallCount += 1
        lastFetchTagsCaptureId = captureId
        return try fetchTagsResult.get()
    }

    func addTag(captureId: UUID, tagId: UUID) async throws {
        callLog.append("addTag")
        addTagCallCount += 1
        lastAddTagCaptureId = captureId
        lastAddTagTagId = tagId
        _ = try addTagResult.get()
    }

    func removeTag(captureId: UUID, tagId: UUID) async throws {
        callLog.append("removeTag")
        removeTagCallCount += 1
        lastRemoveTagCaptureId = captureId
        lastRemoveTagTagId = tagId
        _ = try removeTagResult.get()
    }
}

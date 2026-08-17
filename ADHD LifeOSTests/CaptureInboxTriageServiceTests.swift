//
//  CaptureInboxTriageServiceTests.swift
//  ADHD LifeOSTests
//
//  Covers CaptureInboxService's Stage C.6b-triage additions: updateLifeArea, fetchAllTags,
//  fetchTags, addExistingTag, createAndAddTag, removeTag. Split out from
//  CaptureInboxServiceTests.swift to keep it under SwiftLint's type_body_length ceiling — same
//  precedent as Stage C.5's AWSTaskDetailTagsTests split.
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class CaptureInboxTriageServiceTests: XCTestCase {

    // MARK: - updateLifeArea

    func testUpdateLifeArea_success_callsUpdateCaptureWithOnlyLifeAreaIdAndReplacesCaptureInList() async {
        let fake = FakeCaptureClientAdapting()
        let capture = Capture(id: UUID(), content: "Buy milk", kind: .note, processed: false, createdAt: Date())
        fake.fetchUnprocessedCapturesResult = .success([capture])
        let lifeAreaId = UUID()
        let updated = Capture(
            id: capture.id, content: capture.content, kind: capture.kind, processed: false,
            createdAt: capture.createdAt, lifeAreaId: lifeAreaId
        )
        fake.updateCaptureResult = .success(updated)
        let sut = CaptureInboxService(client: fake)
        await sut.load()

        let result = await sut.updateLifeArea(capture: capture, lifeAreaId: lifeAreaId)

        XCTAssertTrue(result)
        XCTAssertEqual(fake.updateCaptureCallCount, 1)
        XCTAssertEqual(fake.lastUpdateCaptureId, capture.id)
        XCTAssertEqual(fake.lastUpdateCaptureChanges, CaptureUpdate(lifeAreaId: .some(lifeAreaId)))
        XCTAssertEqual(sut.captures, [updated])
        XCTAssertNil(sut.triageErrorMessage)
    }

    func testUpdateLifeArea_clearedToNone_sendsExplicitNull() async {
        let fake = FakeCaptureClientAdapting()
        let capture = Capture(
            id: UUID(), content: "Buy milk", kind: .note, processed: false, createdAt: Date(), lifeAreaId: UUID()
        )
        fake.fetchUnprocessedCapturesResult = .success([capture])
        let sut = CaptureInboxService(client: fake)
        await sut.load()

        _ = await sut.updateLifeArea(capture: capture, lifeAreaId: nil)

        XCTAssertEqual(fake.lastUpdateCaptureChanges, CaptureUpdate(lifeAreaId: .some(nil)))
    }

    func testUpdateLifeArea_failure_surfacesTriageError() async {
        let fake = FakeCaptureClientAdapting()
        let capture = Capture(id: UUID(), content: "Buy milk", kind: .note, processed: false, createdAt: Date())
        fake.fetchUnprocessedCapturesResult = .success([capture])
        fake.updateCaptureResult = .failure(CaptureServiceError.fetchFailed("Network error"))
        let sut = CaptureInboxService(client: fake)
        await sut.load()

        let result = await sut.updateLifeArea(capture: capture, lifeAreaId: UUID())

        XCTAssertFalse(result)
        XCTAssertEqual(sut.triageErrorMessage, "Network error")
        XCTAssertEqual(sut.captures, [capture], "A failed update must not lose the user's other edits")
    }

    // MARK: - tags

    func testFetchAllTags_success_returnsTags() async {
        let fake = FakeCaptureClientAdapting()
        let tags = [Tag(id: UUID(), name: "urgent")]
        fake.fetchAllTagsResult = .success(tags)
        let sut = CaptureInboxService(client: fake)

        let result = await sut.fetchAllTags()

        XCTAssertEqual(result, tags)
    }

    func testFetchAllTags_failure_returnsEmptyListNonBlocking() async {
        let fake = FakeCaptureClientAdapting()
        fake.fetchAllTagsResult = .failure(CaptureServiceError.fetchFailed("Network error"))
        let sut = CaptureInboxService(client: fake)

        let result = await sut.fetchAllTags()

        XCTAssertEqual(result, [])
    }

    func testFetchTagsForCapture_success_returnsTags() async {
        let fake = FakeCaptureClientAdapting()
        let capture = Capture(id: UUID(), content: "Buy milk", kind: .note, processed: false, createdAt: Date())
        let tags = [Tag(id: UUID(), name: "focus")]
        fake.fetchTagsResult = .success(tags)
        let sut = CaptureInboxService(client: fake)

        let result = await sut.fetchTags(for: capture)

        XCTAssertEqual(result, tags)
        XCTAssertEqual(fake.lastFetchTagsCaptureId, capture.id)
    }

    func testAddExistingTag_success_callsAddTag() async {
        let fake = FakeCaptureClientAdapting()
        let capture = Capture(id: UUID(), content: "Buy milk", kind: .note, processed: false, createdAt: Date())
        let tagId = UUID()
        let sut = CaptureInboxService(client: fake)

        let result = await sut.addExistingTag(capture: capture, tagId: tagId)

        XCTAssertTrue(result)
        XCTAssertEqual(fake.addTagCallCount, 1)
        XCTAssertEqual(fake.lastAddTagCaptureId, capture.id)
        XCTAssertEqual(fake.lastAddTagTagId, tagId)
        XCTAssertEqual(fake.createTagCallCount, 0)
    }

    func testAddExistingTag_failure_surfacesTriageError() async {
        let fake = FakeCaptureClientAdapting()
        let capture = Capture(id: UUID(), content: "Buy milk", kind: .note, processed: false, createdAt: Date())
        fake.addTagResult = .failure(CaptureServiceError.fetchFailed("Network error"))
        let sut = CaptureInboxService(client: fake)

        let result = await sut.addExistingTag(capture: capture, tagId: UUID())

        XCTAssertFalse(result)
        XCTAssertEqual(sut.triageErrorMessage, "Network error")
    }

    func testCreateAndAddTag_success_createsThenAddsInOrder() async {
        let fake = FakeCaptureClientAdapting()
        let capture = Capture(id: UUID(), content: "Buy milk", kind: .note, processed: false, createdAt: Date())
        let tag = Tag(id: UUID(), name: "new-tag")
        fake.createTagResult = .success(tag)
        let sut = CaptureInboxService(client: fake)

        let result = await sut.createAndAddTag(capture: capture, name: "new-tag")

        XCTAssertEqual(result, tag)
        XCTAssertEqual(fake.callLog, ["createTag", "addTag"])
        XCTAssertEqual(fake.lastCreateTagName, "new-tag")
        XCTAssertEqual(fake.lastAddTagCaptureId, capture.id)
        XCTAssertEqual(fake.lastAddTagTagId, tag.id)
    }

    func testCreateAndAddTag_createFailure_surfacesTriageErrorAndDoesNotAdd() async {
        let fake = FakeCaptureClientAdapting()
        let capture = Capture(id: UUID(), content: "Buy milk", kind: .note, processed: false, createdAt: Date())
        fake.createTagResult = .failure(CaptureServiceError.fetchFailed("Network error"))
        let sut = CaptureInboxService(client: fake)

        let result = await sut.createAndAddTag(capture: capture, name: "new-tag")

        XCTAssertNil(result)
        XCTAssertEqual(sut.triageErrorMessage, "Network error")
        XCTAssertEqual(fake.addTagCallCount, 0)
    }

    func testCreateAndAddTag_addFailsAfterCreate_surfacesTriageError() async {
        let fake = FakeCaptureClientAdapting()
        let capture = Capture(id: UUID(), content: "Buy milk", kind: .note, processed: false, createdAt: Date())
        fake.addTagResult = .failure(CaptureServiceError.fetchFailed("Network error"))
        let sut = CaptureInboxService(client: fake)

        let result = await sut.createAndAddTag(capture: capture, name: "new-tag")

        XCTAssertNil(result)
        XCTAssertEqual(sut.triageErrorMessage, "Network error")
    }

    func testRemoveTag_success_callsRemoveTag() async {
        let fake = FakeCaptureClientAdapting()
        let capture = Capture(id: UUID(), content: "Buy milk", kind: .note, processed: false, createdAt: Date())
        let tagId = UUID()
        let sut = CaptureInboxService(client: fake)

        let result = await sut.removeTag(capture: capture, tagId: tagId)

        XCTAssertTrue(result)
        XCTAssertEqual(fake.removeTagCallCount, 1)
        XCTAssertEqual(fake.lastRemoveTagCaptureId, capture.id)
        XCTAssertEqual(fake.lastRemoveTagTagId, tagId)
    }

    func testRemoveTag_failure_surfacesTriageError() async {
        let fake = FakeCaptureClientAdapting()
        let capture = Capture(id: UUID(), content: "Buy milk", kind: .note, processed: false, createdAt: Date())
        fake.removeTagResult = .failure(CaptureServiceError.fetchFailed("Network error"))
        let sut = CaptureInboxService(client: fake)

        let result = await sut.removeTag(capture: capture, tagId: UUID())

        XCTAssertFalse(result)
        XCTAssertEqual(sut.triageErrorMessage, "Network error")
    }

    // MARK: - promoteToTask life-area forwarding

    // Guards the contract the Inbox view relies on now that the promoted task inherits the single
    // triage life-area picker: the chosen area must reach the created task's payload, and nil must
    // pass through as nil. The historical bug lived in the view passing the wrong @State, not in the
    // service — these pin the service side so a regression there can't slip by unnoticed.
    func testPromoteToTask_forwardsNonNilLifeAreaId_toCreatedTaskPayload() async {
        let fake = FakeCaptureClientAdapting()
        let capture = Capture(id: UUID(), content: "Buy milk", kind: .note, processed: false, createdAt: Date())
        fake.fetchUnprocessedCapturesResult = .success([capture])
        fake.fetchCaptureResult = .success(capture)
        let lifeAreaId = UUID()
        fake.createTaskResult = .success(
            TaskItem(id: UUID(), lifeAreaId: lifeAreaId, title: "Buy milk", status: .open, priority: .p3, dueDate: nil)
        )
        let sut = CaptureInboxService(client: fake)
        await sut.load()

        let result = await sut.promoteToTask(capture: capture, lifeAreaId: lifeAreaId, priority: .p3, dueDate: nil)

        XCTAssertTrue(result)
        XCTAssertEqual(fake.lastCreateTaskInput?.lifeAreaId, lifeAreaId)
    }

    func testPromoteToTask_forwardsNilLifeAreaId_asNil() async {
        let fake = FakeCaptureClientAdapting()
        let capture = Capture(id: UUID(), content: "Buy milk", kind: .note, processed: false, createdAt: Date())
        fake.fetchUnprocessedCapturesResult = .success([capture])
        fake.fetchCaptureResult = .success(capture)
        fake.createTaskResult = .success(
            TaskItem(id: UUID(), lifeAreaId: nil, title: "Buy milk", status: .open, priority: .p4, dueDate: nil)
        )
        let sut = CaptureInboxService(client: fake)
        await sut.load()

        let result = await sut.promoteToTask(capture: capture, lifeAreaId: nil, priority: .p4, dueDate: nil)

        XCTAssertTrue(result)
        XCTAssertNil(fake.lastCreateTaskInput?.lifeAreaId)
    }
}

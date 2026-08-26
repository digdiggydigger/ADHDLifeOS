//
//  CaptureInboxServiceTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class CaptureInboxServiceTests: XCTestCase {

    func testLoad_success_setsLoadedState() async {
        let fake = FakeCaptureClientAdapting()
        let capture = Capture(id: UUID(), content: "Buy milk", kind: .note, processed: false, createdAt: Date())
        fake.fetchUnprocessedCapturesResult = .success([capture])
        let sut = CaptureInboxService(client: fake)

        await sut.load()

        XCTAssertEqual(sut.state, .loaded([capture]))
        XCTAssertEqual(sut.captures, [capture])
    }

    func testLoad_failure_setsFailedState() async {
        let fake = FakeCaptureClientAdapting()
        fake.fetchUnprocessedCapturesResult = .failure(CaptureServiceError.fetchFailed("Network error"))
        let sut = CaptureInboxService(client: fake)

        await sut.load()

        XCTAssertEqual(sut.state, .failed("Network error"))
    }

    func testRefresh_success_updatesCapturesWithoutTransitioningThroughLoading() async {
        let fake = FakeCaptureClientAdapting()
        let existing = Capture(id: UUID(), content: "Buy milk", kind: .note, processed: false, createdAt: Date())
        fake.fetchUnprocessedCapturesResult = .success([existing])
        let sut = CaptureInboxService(client: fake)
        await sut.load()

        let refreshed = Capture(id: UUID(), content: "New link", kind: .link, processed: false, createdAt: Date())
        fake.fetchUnprocessedCapturesResult = .success([existing, refreshed])
        await sut.refresh()

        XCTAssertEqual(sut.state, .loaded([existing, refreshed]))
    }

    func testRefresh_failure_keepsPreviouslyLoadedCapturesAndDoesNotFail() async {
        let fake = FakeCaptureClientAdapting()
        let existing = Capture(id: UUID(), content: "Buy milk", kind: .note, processed: false, createdAt: Date())
        fake.fetchUnprocessedCapturesResult = .success([existing])
        let sut = CaptureInboxService(client: fake)
        await sut.load()

        fake.fetchUnprocessedCapturesResult = .failure(CaptureServiceError.fetchFailed("Network error"))
        await sut.refresh()

        XCTAssertEqual(
            sut.state, .loaded([existing]),
            "A failed refresh must not blank a list the user can already see, and must not tear down " +
            "the List (and its .refreshable task) by transitioning through .loading or .failed"
        )
    }

    func testCreateCapture_success_createsCaptureAndResetsFields() async {
        let fake = FakeCaptureClientAdapting()
        let sut = CaptureInboxService(client: fake)
        sut.content = "  Buy milk  "
        sut.kind = .task

        let result = await sut.createCapture()

        XCTAssertTrue(result)
        XCTAssertEqual(fake.createCaptureCallCount, 1)
        XCTAssertEqual(fake.lastCreateCaptureInput?.content, "Buy milk")
        XCTAssertEqual(fake.lastCreateCaptureInput?.kind, .task)
        XCTAssertEqual(sut.content, "")
        XCTAssertEqual(sut.kind, .note)
        XCTAssertNil(sut.createCaptureErrorMessage)
    }

    func testCreateCapture_emptyContent_failsWithoutCallingClient() async {
        let fake = FakeCaptureClientAdapting()
        let sut = CaptureInboxService(client: fake)
        sut.content = "   "

        let result = await sut.createCapture()

        XCTAssertFalse(result)
        XCTAssertEqual(sut.createCaptureErrorMessage, CaptureValidationError.emptyContent.errorDescription)
        XCTAssertEqual(fake.createCaptureCallCount, 0)
    }

    func testCreateCapture_failure_surfacesError() async {
        let fake = FakeCaptureClientAdapting()
        fake.createCaptureResult = .failure(CaptureServiceError.fetchFailed("Network error"))
        let sut = CaptureInboxService(client: fake)
        sut.content = "Buy milk"

        let result = await sut.createCapture()

        XCTAssertFalse(result)
        XCTAssertEqual(sut.createCaptureErrorMessage, "Network error")
    }

    func testPromoteToTask_success_createsTaskMarksProcessedAndRemovesFromList() async {
        let fake = FakeCaptureClientAdapting()
        let capture = Capture(id: UUID(), content: "Buy milk", kind: .note, processed: false, createdAt: Date())
        fake.fetchUnprocessedCapturesResult = .success([capture])
        fake.fetchCaptureResult = .success(capture)
        let task = TaskItem(id: UUID(), lifeAreaId: nil, title: "Buy milk", status: .open, priority: .p2, dueDate: nil)
        fake.createTaskResult = .success(task)
        let sut = CaptureInboxService(client: fake)
        await sut.load()

        let result = await sut.promoteToTask(capture: capture, lifeAreaId: nil, priority: .p2, dueDate: nil)

        XCTAssertTrue(result)
        XCTAssertEqual(fake.createTaskCallCount, 1)
        XCTAssertEqual(fake.lastCreateTaskInput?.title, "Buy milk")
        XCTAssertEqual(fake.lastCreateTaskInput?.priority, .p2)
        XCTAssertEqual(fake.markProcessedCallCount, 1)
        XCTAssertEqual(fake.lastMarkProcessedCaptureId, capture.id)
        XCTAssertEqual(sut.captures, [])
        XCTAssertNil(sut.errorMessage)
        XCTAssertNil(sut.warningMessage)
    }

    func testPromoteToTask_photoWithEmptyCaption_usesPlaceholderTitle() async {
        let fake = FakeCaptureClientAdapting()
        let capture = Capture(id: UUID(), content: "", kind: .photo, processed: false, createdAt: Date())
        fake.fetchUnprocessedCapturesResult = .success([capture])
        fake.fetchCaptureResult = .success(capture)
        let task = TaskItem(
            id: UUID(), lifeAreaId: nil, title: "Photo capture", status: .open, priority: .p4, dueDate: nil
        )
        fake.createTaskResult = .success(task)
        let sut = CaptureInboxService(client: fake)
        await sut.load()

        let result = await sut.promoteToTask(capture: capture, lifeAreaId: nil, priority: .p4, dueDate: nil)

        XCTAssertTrue(result)
        XCTAssertEqual(fake.lastCreateTaskInput?.title, "Photo capture")
    }

    func testPromoteToTask_markProcessedFails_taskCreatedButCaptureStaysUnprocessed_warningSurfaced() async {
        let fake = FakeCaptureClientAdapting()
        let capture = Capture(id: UUID(), content: "Buy milk", kind: .note, processed: false, createdAt: Date())
        fake.fetchUnprocessedCapturesResult = .success([capture])
        fake.fetchCaptureResult = .success(capture)
        let task = TaskItem(id: UUID(), lifeAreaId: nil, title: "Buy milk", status: .open, priority: .p4, dueDate: nil)
        fake.createTaskResult = .success(task)
        fake.markProcessedResult = .failure(CaptureServiceError.fetchFailed("Network error"))
        let sut = CaptureInboxService(client: fake)
        await sut.load()

        let result = await sut.promoteToTask(capture: capture, lifeAreaId: nil, priority: .p4, dueDate: nil)

        XCTAssertFalse(result)
        XCTAssertEqual(fake.createTaskCallCount, 1)
        XCTAssertNotNil(sut.warningMessage)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.createdTask, task)
        XCTAssertEqual(sut.captures, [capture], "Capture must remain in the inbox since it wasn't marked processed")
    }

    func testPromoteToTask_retryAfterMarkProcessedFailure_doesNotCreateDuplicateTask() async {
        let fake = FakeCaptureClientAdapting()
        let capture = Capture(id: UUID(), content: "Buy milk", kind: .note, processed: false, createdAt: Date())
        fake.fetchUnprocessedCapturesResult = .success([capture])
        fake.fetchCaptureResult = .success(capture)
        let task = TaskItem(id: UUID(), lifeAreaId: nil, title: "Buy milk", status: .open, priority: .p4, dueDate: nil)
        fake.createTaskResult = .success(task)
        fake.markProcessedResult = .failure(CaptureServiceError.fetchFailed("Network error"))
        let sut = CaptureInboxService(client: fake)
        await sut.load()

        _ = await sut.promoteToTask(capture: capture, lifeAreaId: nil, priority: .p4, dueDate: nil)
        fake.markProcessedResult = .success(())
        let secondResult = await sut.promoteToTask(capture: capture, lifeAreaId: nil, priority: .p4, dueDate: nil)

        XCTAssertTrue(secondResult)
        XCTAssertEqual(fake.createTaskCallCount, 1, "A retry must not create a second task")
        XCTAssertEqual(fake.markProcessedCallCount, 2)
        XCTAssertEqual(sut.captures, [])
    }

    func testPromoteToTask_alreadyProcessed_conflictError_noTaskCreated() async {
        let fake = FakeCaptureClientAdapting()
        let capture = Capture(id: UUID(), content: "Buy milk", kind: .note, processed: false, createdAt: Date())
        fake.fetchUnprocessedCapturesResult = .success([capture])
        let processedCapture = Capture(
            id: capture.id, content: capture.content, kind: capture.kind, processed: true, createdAt: capture.createdAt
        )
        fake.fetchCaptureResult = .success(processedCapture)
        let sut = CaptureInboxService(client: fake)
        await sut.load()

        let result = await sut.promoteToTask(capture: capture, lifeAreaId: nil, priority: .p4, dueDate: nil)

        XCTAssertFalse(result)
        XCTAssertEqual(fake.createTaskCallCount, 0)
        XCTAssertEqual(fake.markProcessedCallCount, 0)
        XCTAssertEqual(sut.errorMessage, CaptureServiceError.alreadyProcessed.errorDescription)
    }

    func testCreatePhotoCapture_success_callsInOrderWithMediaFieldsAndResetsFields() async {
        let fake = FakeCaptureClientAdapting()
        let target = CaptureUploadTarget(
            uploadURL: URL(string: "https://example.com/put")!, mediaKey: "captures/u1/original.jpg",
            thumbnailKey: "captures/u1/thumb.jpg"
        )
        fake.requestUploadURLResult = .success(target)
        let sut = CaptureInboxService(client: fake)
        sut.content = "  A caption  "
        let imageData = Data([0xFF, 0xD8, 0xFF])

        let result = await sut.createPhotoCapture(imageData: imageData)

        XCTAssertTrue(result)
        XCTAssertEqual(fake.callLog, ["requestUploadURL", "uploadMedia", "createCapture"])
        XCTAssertEqual(fake.lastRequestUploadURLKind, .photo)
        XCTAssertEqual(fake.lastRequestUploadURLContentType, "image/jpeg")
        XCTAssertEqual(fake.lastUploadMediaURL, target.uploadURL)
        XCTAssertEqual(fake.lastUploadMediaData, imageData)
        XCTAssertEqual(fake.lastUploadMediaContentType, "image/jpeg")
        XCTAssertEqual(fake.lastCreateCaptureInput?.kind, .photo)
        XCTAssertEqual(fake.lastCreateCaptureInput?.content, "A caption")
        XCTAssertEqual(fake.lastCreateCaptureInput?.mediaKey, target.mediaKey)
        XCTAssertEqual(fake.lastCreateCaptureInput?.mediaContentType, "image/jpeg")
        XCTAssertEqual(fake.lastCreateCaptureInput?.thumbnailKey, target.thumbnailKey)
        XCTAssertEqual(sut.content, "")
        XCTAssertEqual(sut.kind, .note)
        XCTAssertNil(sut.createCaptureErrorMessage)
    }

    func testCreatePhotoCapture_emptyCaption_isAllowed() async {
        let fake = FakeCaptureClientAdapting()
        let sut = CaptureInboxService(client: fake)
        sut.content = ""

        let result = await sut.createPhotoCapture(imageData: Data([0xFF]))

        XCTAssertTrue(result)
        XCTAssertEqual(fake.createCaptureCallCount, 1)
        XCTAssertEqual(fake.lastCreateCaptureInput?.content, "")
    }

    func testCreatePhotoCapture_requestUploadURLFailure_surfacesErrorAndDoesNotUploadOrCreate() async {
        let fake = FakeCaptureClientAdapting()
        fake.requestUploadURLResult = .failure(CaptureServiceError.fetchFailed("Network error"))
        let sut = CaptureInboxService(client: fake)

        let result = await sut.createPhotoCapture(imageData: Data([0xFF]))

        XCTAssertFalse(result)
        XCTAssertEqual(sut.createCaptureErrorMessage, "Network error")
        XCTAssertEqual(fake.uploadMediaCallCount, 0)
        XCTAssertEqual(fake.createCaptureCallCount, 0)
    }

    func testCreatePhotoCapture_uploadMediaFailure_surfacesErrorAndDoesNotCreateCapture() async {
        let fake = FakeCaptureClientAdapting()
        fake.uploadMediaResult = .failure(CaptureServiceError.fetchFailed("Upload failed"))
        let sut = CaptureInboxService(client: fake)

        let result = await sut.createPhotoCapture(imageData: Data([0xFF]))

        XCTAssertFalse(result)
        XCTAssertEqual(sut.createCaptureErrorMessage, "Upload failed")
        XCTAssertEqual(fake.createCaptureCallCount, 0)
    }

    func testCreatePhotoCapture_createCaptureFailure_surfacesError() async {
        let fake = FakeCaptureClientAdapting()
        fake.createCaptureResult = .failure(CaptureServiceError.fetchFailed("Network error"))
        let sut = CaptureInboxService(client: fake)

        let result = await sut.createPhotoCapture(imageData: Data([0xFF]))

        XCTAssertFalse(result)
        XCTAssertEqual(sut.createCaptureErrorMessage, "Network error")
    }

    func testPromoteToTask_taskCreateFailure_surfacesError() async {
        let fake = FakeCaptureClientAdapting()
        let capture = Capture(id: UUID(), content: "Buy milk", kind: .note, processed: false, createdAt: Date())
        fake.fetchUnprocessedCapturesResult = .success([capture])
        fake.fetchCaptureResult = .success(capture)
        fake.createTaskResult = .failure(CaptureServiceError.fetchFailed("Network error"))
        let sut = CaptureInboxService(client: fake)
        await sut.load()

        let result = await sut.promoteToTask(capture: capture, lifeAreaId: nil, priority: .p4, dueDate: nil)

        XCTAssertFalse(result)
        XCTAssertEqual(sut.errorMessage, "Network error")
        XCTAssertEqual(fake.markProcessedCallCount, 0)
        XCTAssertEqual(sut.captures, [capture])
    }

    /// SUGG-b9: Skip is a service-level rotation — the view hands the top capture back and the
    /// next one surfaces. It must survive a refresh: the skip list keys on ids, and the refetch
    /// replaces the array but not the list.
    func testSkip_sendsTheTopToTheBack_andSurvivesRefresh() async {
        let fake = FakeCaptureClientAdapting()
        let first = Capture(id: UUID(), content: "first", kind: .note, processed: false, createdAt: Date())
        let second = Capture(id: UUID(), content: "second", kind: .note, processed: false, createdAt: Date())
        fake.fetchUnprocessedCapturesResult = .success([first, second])
        let sut = CaptureInboxService(client: fake)
        await sut.load()

        sut.skip(first)
        XCTAssertEqual(sut.displayedCaptures, [second, first])

        await sut.refresh()
        XCTAssertEqual(
            sut.displayedCaptures, [second, first],
            "a signal-driven refetch must not undo the skip"
        )
    }
}

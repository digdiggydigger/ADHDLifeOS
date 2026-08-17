//
//  CaptureInboxServiceLinkTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class CaptureInboxServiceLinkTests: XCTestCase {

    func testCreateCapture_linkKind_success_normalizesURLAndCallsCreateCaptureOnly() async {
        let fake = FakeCaptureClientAdapting()
        let sut = CaptureInboxService(client: fake)
        sut.content = "example.com/article"
        sut.kind = .link

        let result = await sut.createCapture()

        XCTAssertTrue(result)
        XCTAssertEqual(fake.callLog, ["createCapture"], "Link capture must save instantly with no upload")
        XCTAssertEqual(fake.lastCreateCaptureInput?.kind, .link)
        XCTAssertEqual(fake.lastCreateCaptureInput?.content, "https://example.com/article")
        XCTAssertEqual(sut.content, "")
        XCTAssertEqual(sut.kind, .note)
        XCTAssertNil(sut.createCaptureErrorMessage)
    }

    func testCreateCapture_linkKind_invalidURL_failsWithoutCallingClient() async {
        let fake = FakeCaptureClientAdapting()
        let sut = CaptureInboxService(client: fake)
        sut.content = "not a url"
        sut.kind = .link

        let result = await sut.createCapture()

        XCTAssertFalse(result)
        XCTAssertEqual(sut.createCaptureErrorMessage, CaptureValidationError.invalidURL.errorDescription)
        XCTAssertEqual(fake.createCaptureCallCount, 0)
    }

    func testCreateCapture_linkKind_createCaptureFailure_surfacesError() async {
        let fake = FakeCaptureClientAdapting()
        fake.createCaptureResult = .failure(CaptureServiceError.fetchFailed("Network error"))
        let sut = CaptureInboxService(client: fake)
        sut.content = "example.com"
        sut.kind = .link

        let result = await sut.createCapture()

        XCTAssertFalse(result)
        XCTAssertEqual(sut.createCaptureErrorMessage, "Network error")
    }

    func testPromoteToTask_linkCapture_withPreviewTitle_usesPreviewTitle() async {
        let fake = FakeCaptureClientAdapting()
        let preview = CaptureLinkPreview(
            url: "https://example.com/article", title: "A Great Article",
            description: "Some description", thumbnailURL: nil
        )
        let capture = Capture(
            id: UUID(), content: "https://example.com/article", kind: .link, processed: false,
            createdAt: Date(), linkPreview: preview
        )
        fake.fetchUnprocessedCapturesResult = .success([capture])
        fake.fetchCaptureResult = .success(capture)
        let task = TaskItem(
            id: UUID(), lifeAreaId: nil, title: "A Great Article", status: .open, priority: .p4, dueDate: nil
        )
        fake.createTaskResult = .success(task)
        let sut = CaptureInboxService(client: fake)
        await sut.load()

        let result = await sut.promoteToTask(capture: capture, lifeAreaId: nil, priority: .p4, dueDate: nil)

        XCTAssertTrue(result)
        XCTAssertEqual(fake.lastCreateTaskInput?.title, "A Great Article")
    }

    func testPromoteToTask_linkCapture_withoutPreview_usesURLAsTitle() async {
        let fake = FakeCaptureClientAdapting()
        let capture = Capture(
            id: UUID(), content: "https://example.com/article", kind: .link, processed: false, createdAt: Date()
        )
        fake.fetchUnprocessedCapturesResult = .success([capture])
        fake.fetchCaptureResult = .success(capture)
        let task = TaskItem(
            id: UUID(), lifeAreaId: nil, title: "https://example.com/article", status: .open, priority: .p4,
            dueDate: nil
        )
        fake.createTaskResult = .success(task)
        let sut = CaptureInboxService(client: fake)
        await sut.load()

        let result = await sut.promoteToTask(capture: capture, lifeAreaId: nil, priority: .p4, dueDate: nil)

        XCTAssertTrue(result)
        XCTAssertEqual(fake.lastCreateTaskInput?.title, "https://example.com/article")
    }
}

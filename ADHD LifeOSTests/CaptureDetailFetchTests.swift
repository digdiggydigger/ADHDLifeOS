//
//  CaptureDetailFetchTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// `fetchCaptureDetail` — the detail screen's re-read. In its own file because
/// `CaptureInboxServiceTests` is at its type-body budget.
@MainActor
final class CaptureDetailFetchTests: XCTestCase {

    /// The detail screen's re-fetch (TaskDetailView precedent: the push carries an id, the screen
    /// re-reads the server's document). Throws rather than routing through a published message —
    /// the failure belongs to the detail screen's own state, not to the list behind it.
    func testFetchCaptureDetail_returnsTheServerDocument() async throws {
        let fake = FakeCaptureClientAdapting()
        let server = Capture(id: UUID(), content: "Server copy", kind: .note, processed: false, createdAt: Date())
        fake.fetchCaptureResult = .success(server)
        let sut = CaptureInboxService(client: fake)

        let fetched = try await sut.fetchCaptureDetail(id: server.id)

        XCTAssertEqual(fetched, server)
        XCTAssertEqual(fake.fetchCaptureCallCount, 1)
    }

    func testFetchCaptureDetail_failurePropagates() async {
        let fake = FakeCaptureClientAdapting()
        fake.fetchCaptureResult = .failure(CaptureServiceError.fetchFailed("offline"))
        let sut = CaptureInboxService(client: fake)

        do {
            _ = try await sut.fetchCaptureDetail(id: UUID())
            XCTFail("expected the fetch error to propagate")
        } catch {
            XCTAssertEqual(CaptureInboxService.message(for: error), "offline")
        }
    }
}

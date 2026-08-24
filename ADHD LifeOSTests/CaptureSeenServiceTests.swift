//
//  CaptureSeenServiceTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The third triage exit: **capture seen** — archive without deleting. Discard throws a thought
/// away and promote turns it into work; seen is for the large middle ground ("noted, nothing to
/// do") that previously had no honest exit. A seen capture moves to the Captures tab, stays
/// unprocessed, and remains fully actionable there — including being sent back to the inbox.
@MainActor
final class CaptureSeenServiceTests: XCTestCase {
    private func capture(_ content: String) -> Capture {
        Capture(id: UUID(), content: content, kind: .note, processed: false, createdAt: Date())
    }

    private struct SUT {
        let service: CaptureInboxService
        let client: FakeCaptureClientAdapting
    }

    private func makeSUT(loaded: [Capture]) async -> SUT {
        let client = FakeCaptureClientAdapting()
        client.fetchUnprocessedCapturesResult = .success(loaded)
        let service = CaptureInboxService(client: client, transcriber: FakeVoiceTranscribing())
        await service.load()
        return SUT(service: service, client: client)
    }

    // MARK: - Mark seen

    func testMarkSeen_writesSeenTrueAndRemovesTheRow() async {
        let noted = capture("Interesting, no action")
        let env = await makeSUT(loaded: [noted, capture("Keep me")])

        let succeeded = await env.service.markSeen(capture: noted)

        XCTAssertTrue(succeeded)
        XCTAssertEqual(env.client.lastUpdateCaptureId, noted.id)
        XCTAssertEqual(env.client.lastUpdateCaptureChanges?.seen, true)
        XCTAssertNotNil(
            env.client.lastUpdateCaptureChanges?.clearedAt.flatMap { $0 },
            "archiving is an inbox exit and must stamp clearedAt (M7)"
        )
        XCTAssertEqual(env.service.captures.map(\.content), ["Keep me"])
    }

    /// Deliberately not optimistic, same as discard: the row leaves only once the write landed. An
    /// optimistic removal that failed would look exactly like a successful archive while the
    /// capture was still in the inbox on the next load.
    func testMarkSeen_failure_keepsTheRowAndSurfacesTheError() async {
        let noted = capture("Interesting")
        let env = await makeSUT(loaded: [noted])
        env.client.updateCaptureResult = .failure(CaptureServiceError.fetchFailed("offline"))

        let succeeded = await env.service.markSeen(capture: noted)

        XCTAssertFalse(succeeded)
        XCTAssertEqual(env.service.captures.count, 1, "a failed archive must not empty the row")
        XCTAssertEqual(env.service.triageErrorMessage, "offline")
    }

    // MARK: - Undo seen

    func testUndoSeen_writesSeenFalseAndRemovesTheRow() async {
        let regretted = capture("Archived too soon")
        let env = await makeSUT(loaded: [regretted, capture("Still seen")])

        let succeeded = await env.service.undoSeen(capture: regretted)

        XCTAssertTrue(succeeded)
        XCTAssertEqual(env.client.lastUpdateCaptureId, regretted.id)
        XCTAssertEqual(env.client.lastUpdateCaptureChanges?.seen, false)
        XCTAssertEqual(
            env.client.lastUpdateCaptureChanges?.clearedAt, .some(.some(nil)),
            "back in the inbox means the exit stamp is deleted, not left stale"
        )
        XCTAssertEqual(env.service.captures.map(\.content), ["Still seen"])
    }

    /// The real undo site: the Captures tab's Seen list. The row leaves THAT list — it belongs to
    /// the Inbox again.
    func testUndoSeen_onTheSeenFilter_removesTheRowFromTheSeenList() async {
        let regretted = capture("Archived too soon")
        let client = FakeCaptureClientAdapting()
        client.fetchSeenCapturesResult = .success([regretted, capture("Still seen")])
        let service = CaptureInboxService(
            client: client, transcriber: FakeVoiceTranscribing(), availableFilters: [.seen, .promoted]
        )
        await service.load()

        let succeeded = await service.undoSeen(capture: regretted)

        XCTAssertTrue(succeeded)
        XCTAssertEqual(service.captures.map(\.content), ["Still seen"])
    }

    func testUndoSeen_failure_keepsTheRowAndSurfacesTheError() async {
        let regretted = capture("Archived too soon")
        let env = await makeSUT(loaded: [regretted])
        env.client.updateCaptureResult = .failure(CaptureServiceError.fetchFailed("offline"))

        let succeeded = await env.service.undoSeen(capture: regretted)

        XCTAssertFalse(succeeded)
        XCTAssertEqual(env.service.captures.count, 1)
        XCTAssertEqual(env.service.triageErrorMessage, "offline")
    }
}

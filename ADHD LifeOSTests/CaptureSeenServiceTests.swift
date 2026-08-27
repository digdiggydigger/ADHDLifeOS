//
//  CaptureSeenServiceTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The `seen` archive, from the one side that still has its own entry point: **undo**.
///
/// The forward direction used to be `markSeen`, a second arealess path into the same state the
/// triage card's **Sorted** reaches under a rule (a life area is required). Two writers of one
/// state is how they came to disagree — the audit's A2/A3 — so `markSeen` is gone and the detail
/// screen's button routes through `sort(capture:into:)` like everything else. `CaptureSortAndUndoTests`
/// owns the forward contract; this file keeps the return leg.
///
/// A seen capture stays unprocessed and remains fully actionable in the Captures archive —
/// including being sent back to the inbox, which is what these cover.
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

    // MARK: - Filing is not clearing

    /// The audit's A2, pinned. THREE gestures wrote a capture's life area and they did not agree:
    /// the triage card's Sorted files it AND clears it in one write, while the detail screen's
    /// "Filed in" picker and the area screen's "File here" wrote `lifeAreaId` alone — so filing
    /// from two of the three left the capture sitting in the inbox afterwards.
    ///
    /// The resolution is not to make them all clear: it is that only **Sorted** clears, and the
    /// picker's job stays "say where this lives". This asserts the picker keeps its hands off the
    /// exit fields, so the two can never quietly become the same gesture.
    func testUpdateLifeArea_filesTheCaptureWithoutClearingTheInbox() async {
        let undecided = capture("Where does this go?")
        let env = await makeSUT(loaded: [undecided])
        let areaId = UUID()

        let succeeded = await env.service.updateLifeArea(capture: undecided, lifeAreaId: areaId)

        XCTAssertTrue(succeeded)
        XCTAssertEqual(env.client.lastUpdateCaptureChanges?.lifeAreaId, .some(.some(areaId)))
        XCTAssertNil(env.client.lastUpdateCaptureChanges?.seen, "naming an area is not an exit")
        XCTAssertNil(
            env.client.lastUpdateCaptureChanges?.clearedAt,
            "only Sorted stamps the inbox exit; a picker change must not"
        )
        XCTAssertEqual(
            env.service.captures.count, 1, "the capture is filed, but it has not been decided"
        )
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

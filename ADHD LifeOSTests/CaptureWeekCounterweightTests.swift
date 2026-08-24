//
//  CaptureWeekCounterweightTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// S1's weekly capture-vs-clear counterweight (Concept C, block M10) end to end: the adapter
/// exposes the whole collection, and the service decorates its screens with the derived line
/// without ever letting that decoration break the load it rides on. The line's own arithmetic
/// is covered beside the other header lines in `CaptureInboxSummaryTests`.
@MainActor
final class CaptureWeekCounterweightTests: XCTestCase {

    // MARK: - Adapter

    /// The manager's query orders newest-first server-side, so the adapter passes the whole
    /// collection through untouched — every state included, nothing filtered.
    func testFetchCaptures_returnsTheWholeCollectionUnfiltered() async throws {
        let store = FakeCaptureBackingStore()
        var archived = capture(content: "Archived")
        archived.seen = true
        var promoted = capture(content: "Promoted")
        promoted.processed = true
        store.allCaptures = [capture(content: "Waiting"), archived, promoted]

        let captures = try await FirebaseCaptureClientAdapter(store: store).fetchCaptures()

        XCTAssertEqual(captures.map(\.content), ["Waiting", "Archived", "Promoted"])
    }

    // MARK: - Service

    /// Load decorates the header with the ledger, fetched from the whole collection after the
    /// list itself.
    func testLoad_populatesTheWeekCounterweightLine() async {
        let fake = FakeCaptureClientAdapting()
        let now = Date()
        fake.fetchCapturesResult = .success([
            capture(content: "New", createdAt: now),
            capture(content: "Old but cleared", createdAt: now.addingTimeInterval(-30 * 86_400), clearedAt: now)
        ])
        let sut = CaptureInboxService(client: fake)

        await sut.load()

        XCTAssertEqual(sut.weekCounterweightLine, "1 captured · 1 cleared this week")
    }

    /// Decoration must never break the meal: a failed counterweight fetch leaves the line unset
    /// and the load itself loaded — the `refreshInactiveCount` contract.
    func testLoad_counterweightFetchFailureLeavesLineNilAndLoadLoaded() async {
        let fake = FakeCaptureClientAdapting()
        let waiting = capture(content: "Buy milk")
        fake.fetchUnprocessedCapturesResult = .success([waiting])
        fake.fetchCapturesResult = .failure(CaptureServiceError.fetchFailed("Network error"))
        let sut = CaptureInboxService(client: fake)

        await sut.load()

        XCTAssertNil(sut.weekCounterweightLine)
        XCTAssertEqual(sut.state, .loaded([waiting]))
    }

    private func capture(content: String, createdAt: Date = Date(), clearedAt: Date? = nil) -> Capture {
        Capture(
            id: UUID(), content: content, kind: .note, processed: clearedAt != nil,
            createdAt: createdAt, clearedAt: clearedAt
        )
    }
}

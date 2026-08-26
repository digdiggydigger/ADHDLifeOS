//
//  CaptureSkipOrderingTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// SUGG-b9 (E's checklist, 2026-08-26): the triage card's Skip sends the top capture to the back
/// of the queue and surfaces the next one. The ordering is a pure stage AFTER
/// `CaptureListRefinement`, keyed by id — so it survives the app-wide DataChangeSignal refetch,
/// which replaces the array but not the skip list. Nothing is written: skipping is a way of
/// looking, not a triage decision.
final class CaptureSkipOrderingTests: XCTestCase {
    private func capture(_ content: String) -> Capture {
        Capture(id: UUID(), content: content, kind: .note, processed: false, createdAt: Date())
    }

    func testNoSkips_leavesOrderAlone() {
        let captures = [capture("a"), capture("b")]
        XCTAssertEqual(CaptureSkipOrdering.apply(captures: captures, skippedIds: []), captures)
    }

    func testSkippingTheTop_sendsItToTheBack() {
        let a = capture("a"), b = capture("b"), c = capture("c")
        XCTAssertEqual(
            CaptureSkipOrdering.apply(captures: [a, b, c], skippedIds: [a.id]),
            [b, c, a]
        )
    }

    func testSkippedOrderIsTheSkipOrder_notTheFetchOrder() {
        let a = capture("a"), b = capture("b"), c = capture("c")
        XCTAssertEqual(
            CaptureSkipOrdering.apply(captures: [a, b, c], skippedIds: [c.id, a.id]),
            [b, c, a]
        )
    }

    /// A skipped capture that was since triaged away (or a stale id after a refetch) must not
    /// resurrect anything or crash — unknown ids simply contribute nothing to the order.
    func testStaleSkippedIds_areIgnored() {
        let a = capture("a"), b = capture("b"), c = capture("c")
        XCTAssertEqual(
            CaptureSkipOrdering.apply(captures: [a, b, c], skippedIds: [UUID(), a.id]),
            [b, c, a]
        )
    }

    func testSkippingEverything_cyclesInSkipOrder() {
        let a = capture("a"), b = capture("b")
        XCTAssertEqual(
            CaptureSkipOrdering.apply(captures: [a, b], skippedIds: [a.id, b.id]),
            [a, b]
        )
    }
}

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
        let first = capture("a"), second = capture("b"), third = capture("c")
        XCTAssertEqual(
            CaptureSkipOrdering.apply(captures: [first, second, third], skippedIds: [first.id]),
            [second, third, first]
        )
    }

    func testSkippedOrderIsTheSkipOrder_notTheFetchOrder() {
        let first = capture("a"), second = capture("b"), third = capture("c")
        XCTAssertEqual(
            CaptureSkipOrdering.apply(captures: [first, second, third], skippedIds: [third.id, first.id]),
            [second, third, first]
        )
    }

    /// A skipped capture that was since triaged away (or a stale id after a refetch) must not
    /// resurrect anything or crash — unknown ids simply contribute nothing to the order.
    func testStaleSkippedIds_areIgnored() {
        let first = capture("a"), second = capture("b"), third = capture("c")
        XCTAssertEqual(
            CaptureSkipOrdering.apply(captures: [first, second, third], skippedIds: [UUID(), first.id]),
            [second, third, first]
        )
    }

    func testSkippingEverything_cyclesInSkipOrder() {
        let first = capture("a"), second = capture("b")
        XCTAssertEqual(
            CaptureSkipOrdering.apply(captures: [first, second], skippedIds: [first.id, second.id]),
            [first, second]
        )
    }
}

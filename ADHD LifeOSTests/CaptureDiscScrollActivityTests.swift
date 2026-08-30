//
//  CaptureDiscScrollActivityTests.swift
//  ADHD LifeOSTests
//

import Combine
import XCTest
@testable import ADHD_LifeOS

/// F-DiscPill's state machine: the capture disc shrinks to a pill the moment a drag starts and
/// grows back only after the finger has been up for a settle delay, so stop-and-go scrolling
/// reads as one continuous pill rather than a disc that flaps between sizes.
///
/// Tests inject a short delay; the production default is asserted separately so a "fix" that
/// zeroes the debounce cannot pass unnoticed.
@MainActor
final class CaptureDiscScrollActivityTests: XCTestCase {

    /// Long enough to observe, short enough not to slow the suite.
    private static let testDelay: TimeInterval = 0.05

    /// Comfortably past `testDelay` — where the restore lands if nothing cancelled it.
    private static let pastTheDelay: TimeInterval = 1.0

    func testStartsAtRest() {
        XCTAssertFalse(CaptureDiscScrollActivity(settleDelay: Self.testDelay).isScrolling)
    }

    func testDragBeganShrinksImmediately() {
        let activity = CaptureDiscScrollActivity(settleDelay: Self.testDelay)
        activity.dragBegan()
        XCTAssertTrue(activity.isScrolling, "The shrink must be synchronous — a pill that arrives"
            + " after a debounce would spend the whole scroll as a disc.")
    }

    func testDragEndedDoesNotRestoreSynchronously() {
        let activity = CaptureDiscScrollActivity(settleDelay: Self.testDelay)
        activity.dragBegan()
        activity.dragEnded()
        XCTAssertTrue(activity.isScrolling, "Lifting the finger must not snap the disc back —"
            + " momentum is still moving content underneath it.")
    }

    func testDragEndedRestoresAfterTheSettleDelay() {
        let activity = CaptureDiscScrollActivity(settleDelay: Self.testDelay)
        activity.dragBegan()
        activity.dragEnded()
        wait(for: [expectRestored(activity)], timeout: Self.pastTheDelay)
        XCTAssertFalse(activity.isScrolling)
    }

    func testNewDragCancelsThePendingRestore() {
        let activity = CaptureDiscScrollActivity(settleDelay: Self.testDelay)
        activity.dragBegan()
        activity.dragEnded()
        activity.dragBegan()

        // Wait out where the cancelled restore WOULD have landed. An inverted expectation is
        // the assertion: `isScrolling` never drops.
        let neverRestored = expectRestored(activity)
        neverRestored.isInverted = true
        wait(for: [neverRestored], timeout: Self.testDelay * 4)
        XCTAssertTrue(
            activity.isScrolling,
            "A drag that starts inside the settle window is the SAME scroll — the pill must hold."
        )
    }

    func testDragEndedWithoutBeganStaysAtRest() {
        // The recognizer cannot deliver .ended without .began, but the model must not rely on
        // that ordering: an unmatched end is a no-op, not a latch into some third state.
        let activity = CaptureDiscScrollActivity(settleDelay: Self.testDelay)
        activity.dragEnded()
        XCTAssertFalse(activity.isScrolling)
    }

    func testRepeatedDragBeganIsIdempotent() {
        let activity = CaptureDiscScrollActivity(settleDelay: Self.testDelay)
        activity.dragBegan()
        activity.dragBegan()
        XCTAssertTrue(activity.isScrolling)
    }

    func testProductionSettleDelayIsADeliberateBeat() {
        // The debounce is the feature: 0 would flap on every stop-and-go scroll, and multiple
        // seconds would park a pill over nothing long after the scroll ended.
        XCTAssertGreaterThanOrEqual(CaptureDiscScrollActivity.settleDelay, 0.3)
        XCTAssertLessThanOrEqual(CaptureDiscScrollActivity.settleDelay, 1.5)
    }

    // MARK: - Support

    /// Fulfilled when `isScrolling` next publishes `false`.
    private func expectRestored(_ activity: CaptureDiscScrollActivity) -> XCTestExpectation {
        let expectation = expectation(description: "isScrolling returned to false")
        let cancellable = activity.$isScrolling
            .dropFirst()
            .filter { !$0 }
            .sink { _ in expectation.fulfill() }
        // Keep the subscription alive until the wait resolves it.
        addTeardownBlock { cancellable.cancel() }
        return expectation
    }
}

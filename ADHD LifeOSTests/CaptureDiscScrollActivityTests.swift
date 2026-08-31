//
//  CaptureDiscScrollActivityTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// F-PillStay's state machine (superseding F-DiscPill's settle-timer version, at E's direction:
/// "stay in pill form until the page is scrolled upwards again"). The pill is DIRECTIONAL and
/// STICKY: dragging the finger up (reading down the page) collapses the disc and it stays
/// collapsed — through the lift, through momentum, indefinitely; dragging the finger down
/// (scrolling back up) restores the disc. A ±threshold latch keeps touch jitter from flapping
/// the state, and a mid-drag reversal flips it without a new touch.
///
/// There are deliberately NO timers here — the old settle-debounce restore is gone, and these
/// tests are all synchronous because the model's behaviour is.
@MainActor
final class CaptureDiscScrollActivityTests: XCTestCase {

    /// One comfortable step past the latch threshold.
    private static let step = CaptureDiscScrollActivity.directionThreshold + 1

    func testStartsAtRest() {
        XCTAssertFalse(CaptureDiscScrollActivity().prefersPill)
    }

    func testScrollingDownCollapsesToThePill() {
        let activity = CaptureDiscScrollActivity()
        activity.dragBegan()
        activity.dragMoved(translationY: -Self.step)
        XCTAssertTrue(activity.prefersPill, "Finger moving up = reading down the page = pill.")
    }

    func testThePillSticksAfterTheDragEnds() {
        // The heart of F-PillStay: no terminal event, no timer, nothing restores the disc
        // except an upward scroll. The model has no way to hear "drag ended" at all now —
        // stickiness by construction, not by a flag.
        let activity = CaptureDiscScrollActivity()
        activity.dragBegan()
        activity.dragMoved(translationY: -Self.step)
        // A second drag that goes nowhere near the threshold changes nothing either.
        activity.dragBegan()
        activity.dragMoved(translationY: -1)
        XCTAssertTrue(activity.prefersPill)
    }

    func testScrollingUpRestoresTheDisc() {
        let activity = CaptureDiscScrollActivity()
        activity.dragBegan()
        activity.dragMoved(translationY: -Self.step)
        activity.dragBegan()
        activity.dragMoved(translationY: Self.step)
        XCTAssertFalse(activity.prefersPill, "Finger moving down = scrolling back up = disc.")
    }

    func testAMidDragReversalFlipsWithoutANewTouch() {
        // Drag down the page, then pull back up in the SAME gesture: the anchor re-bases at
        // each flip, so the reversal only needs the threshold of travel from the turn, not
        // from the gesture's start.
        let activity = CaptureDiscScrollActivity()
        activity.dragBegan()
        activity.dragMoved(translationY: -Self.step)
        XCTAssertTrue(activity.prefersPill)
        // Back to 0: a full threshold-plus of travel upward from the re-based anchor.
        activity.dragMoved(translationY: 0)
        XCTAssertFalse(activity.prefersPill)
    }

    func testJitterUnderTheThresholdNeverFlaps() {
        let activity = CaptureDiscScrollActivity()
        activity.dragBegan()
        activity.dragMoved(translationY: -Self.step)
        // Wobble around the anchor by less than the threshold, both directions.
        activity.dragMoved(translationY: -Self.step + 4)
        activity.dragMoved(translationY: -Self.step - 4)
        activity.dragMoved(translationY: -Self.step + 4)
        XCTAssertTrue(activity.prefersPill, "±4pt of touch jitter must not restore the disc.")
    }

    func testResetRestoresTheDisc() {
        // The one restore that isn't a scroll: a context switch (tab change) starts fresh —
        // a sticky pill on a page the user never scrolled reads as a bug.
        let activity = CaptureDiscScrollActivity()
        activity.dragBegan()
        activity.dragMoved(translationY: -Self.step)
        activity.reset()
        XCTAssertFalse(activity.prefersPill)
    }

    func testThresholdIsADeliberateLatch() {
        // 0 would flap on every touch tremor; a huge value would make the pill feel deaf.
        XCTAssertGreaterThan(CaptureDiscScrollActivity.directionThreshold, 4)
        XCTAssertLessThanOrEqual(CaptureDiscScrollActivity.directionThreshold, 44)
    }
}

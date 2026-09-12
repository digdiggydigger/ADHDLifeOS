//
//  TaskRowSwipeTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The dense row's bonus gesture (F-V3-Tasks-rebuild): swipe RIGHT past the threshold to close.
/// There is no left action any more — delete moved to the detail screen, and closed tasks don't
/// reopen — so leftward drags don't move the row at all.
final class TaskRowSwipeTests: XCTestCase {

    func testCloses_onlyPastTheRightwardThreshold() {
        XCTAssertFalse(TaskRowSwipe.closes(forTranslation: 74))
        XCTAssertFalse(TaskRowSwipe.closes(forTranslation: TaskRowSwipe.threshold))
        XCTAssertTrue(TaskRowSwipe.closes(forTranslation: 76))
    }

    func testCloses_neverOnALeftwardDrag() {
        XCTAssertFalse(TaskRowSwipe.closes(forTranslation: -200))
    }

    func testRubberBanded_tracksOneToOneUpToTheThreshold() {
        XCTAssertEqual(TaskRowSwipe.rubberBanded(40), 40)
        XCTAssertEqual(TaskRowSwipe.rubberBanded(TaskRowSwipe.threshold), TaskRowSwipe.threshold)
    }

    func testRubberBanded_dampsPastTheThresholdAndCapsAtTheElasticLimit() {
        XCTAssertEqual(TaskRowSwipe.rubberBanded(125), 75 + 50 * 0.4)
        XCTAssertEqual(TaskRowSwipe.rubberBanded(10_000), TaskRowSwipe.elasticLimit)
    }

    func testRubberBanded_leftwardDragsDoNotMoveTheRow() {
        XCTAssertEqual(TaskRowSwipe.rubberBanded(-1), 0)
        XCTAssertEqual(TaskRowSwipe.rubberBanded(-500), 0)
    }

    // MARK: - Where a swipe's pop leaves from (E's device finding, 2026-09-12)

    /// **E swiped a task closed on their phone and the paper flew off the right-hand edge.** The
    /// swipe shared the circle's recorded origin — and the circle sits at the row's TRAILING edge,
    /// so once `F-CTACelebrations-PopScale` took the throw to 208 pt most of the confetti left the
    /// screen. E: *"make the animation origin at the tap location of the 'swipe to complete'."*
    ///
    /// The gesture reports its finger position in the ROW's own space, so the pop needs the row's
    /// global frame to place it on screen. Pure, so it can be read rather than inferred from a
    /// gesture host.
    func testASwipesPopLeavesFromTheFingerRatherThanTheCircle() {
        let row = CGRect(x: 16, y: 269, width: 361, height: 74)
        let origin = TaskRowSwipe.popOrigin(rowFrame: row, fingerInRow: CGPoint(x: 120, y: 37))
        XCTAssertEqual(origin?.x, 136)
        XCTAssertEqual(origin?.y, 306)
    }

    /// A finger near the row's leading edge pops from there — the case E actually hit, and the one
    /// the circle's origin got most wrong.
    func testASwipeStartedAtTheLeadingEdgePopsFromTheLeadingEdge() {
        let row = CGRect(x: 16, y: 269, width: 361, height: 74)
        let origin = TaskRowSwipe.popOrigin(rowFrame: row, fingerInRow: CGPoint(x: 24, y: 37))
        XCTAssertEqual(origin?.x, 40)
    }

    /// **No frame, no origin — and `nil` is the right answer rather than a guess.** The layer
    /// centres an origin-less burst, which is a sane pop; a fabricated point would be a pop from
    /// somewhere the user never touched.
    func testAnUnmeasuredRowHandsOverNoOriginAtAll() {
        XCTAssertNil(TaskRowSwipe.popOrigin(rowFrame: .zero, fingerInRow: CGPoint(x: 24, y: 37)))
    }
}

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
}

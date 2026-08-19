//
//  SwipeActionTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The swipe card's threshold logic is pure (`SwipeAction`), so the 75pt trigger and the elastic
/// rubber-banding are testable without a gesture host — the same split the web card's
/// `handleDragEnd` used.
final class SwipeActionTests: XCTestCase {
    func testBelowThreshold_resolvesToNone() {
        XCTAssertEqual(SwipeAction.resolved(forTranslation: 0), .none)
        XCTAssertEqual(SwipeAction.resolved(forTranslation: 74), .none)
        XCTAssertEqual(SwipeAction.resolved(forTranslation: -74), .none)
    }

    func testPastRightThreshold_resolvesToComplete() {
        XCTAssertEqual(SwipeAction.resolved(forTranslation: 76), .complete)
        XCTAssertEqual(SwipeAction.resolved(forTranslation: 300), .complete)
    }

    func testPastLeftThreshold_resolvesToDelete() {
        XCTAssertEqual(SwipeAction.resolved(forTranslation: -76), .delete)
        XCTAssertEqual(SwipeAction.resolved(forTranslation: -300), .delete)
    }

    func testExactlyThreshold_isNotYetTriggered() {
        XCTAssertEqual(SwipeAction.resolved(forTranslation: SwipeAction.threshold), .none)
        XCTAssertEqual(SwipeAction.resolved(forTranslation: -SwipeAction.threshold), .none)
    }

    func testRubberBanding_isOneToOneWithinThreshold() {
        XCTAssertEqual(SwipeAction.rubberBanded(50), 50, accuracy: 0.001)
        XCTAssertEqual(SwipeAction.rubberBanded(-50), -50, accuracy: 0.001)
    }

    func testRubberBanding_dampsBeyondThreshold() {
        // 75 + (175 - 75) * 0.4 = 115, still under the 140 elastic limit.
        XCTAssertEqual(SwipeAction.rubberBanded(175), 115, accuracy: 0.001)
        XCTAssertEqual(SwipeAction.rubberBanded(-175), -115, accuracy: 0.001)
    }

    func testRubberBanding_clampsToElasticLimit() {
        XCTAssertEqual(SwipeAction.rubberBanded(10_000), SwipeAction.elasticLimit, accuracy: 0.001)
        XCTAssertEqual(SwipeAction.rubberBanded(-10_000), -SwipeAction.elasticLimit, accuracy: 0.001)
    }
}

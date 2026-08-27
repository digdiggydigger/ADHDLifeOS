//
//  PlaceMonitoringCapacityTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// "12 of 20 places" — how many places exist against how many iOS will actually watch
/// (E's 2026-08-27 request).
///
/// This counter exists to make an INVISIBLE failure visible. iOS monitors at most 20 regions per
/// app and enforces it silently: define a 21st place and one of them simply stops triggering,
/// with no error, no callback, and nothing on screen to suggest anything is wrong. Without this
/// line, the only way to discover the cap is to notice a nudge that never came.
///
/// The wording matters as much as the number. Over the cap is NOT an error — `placesToMonitor`
/// keeps the nearest 20 and re-picks on every significant-change wake — so the copy has to say
/// what actually happens rather than implying the extra places are broken.
final class PlaceMonitoringCapacityTests: XCTestCase {

    func testLimit_isTheSameCapTheGeofenceSelectionUses() {
        // One source of truth: a counter that disagreed with the selection would be a lie.
        XCTAssertEqual(PlaceMonitoringCapacity.limit, PlaceGeometry.regionMonitoringLimit)
        XCTAssertEqual(PlaceMonitoringCapacity.limit, 20)
    }

    // MARK: - Under the cap

    func testSummary_underTheCap_readsAsAPlainCount() {
        XCTAssertEqual(PlaceMonitoringCapacity.summary(placeCount: 1), "1 of 20 places")
        XCTAssertEqual(PlaceMonitoringCapacity.summary(placeCount: 12), "12 of 20 places")
        XCTAssertEqual(PlaceMonitoringCapacity.summary(placeCount: 19), "19 of 20 places")
    }

    func testIsOverCapacity_isFalseUpToAndIncludingTheLimit() {
        XCTAssertFalse(PlaceMonitoringCapacity.isOverCapacity(placeCount: 0))
        XCTAssertFalse(PlaceMonitoringCapacity.isOverCapacity(placeCount: 19))
        XCTAssertFalse(PlaceMonitoringCapacity.isOverCapacity(placeCount: 20))
    }

    func testRemaining_countsDownToZeroAndNeverNegative() {
        XCTAssertEqual(PlaceMonitoringCapacity.remaining(placeCount: 0), 20)
        XCTAssertEqual(PlaceMonitoringCapacity.remaining(placeCount: 19), 1)
        XCTAssertEqual(PlaceMonitoringCapacity.remaining(placeCount: 20), 0)
        XCTAssertEqual(PlaceMonitoringCapacity.remaining(placeCount: 25), 0)
    }

    // MARK: - At the cap

    /// Exactly 20 is fine — everything is watched — but it is the last moment that is true, and
    /// saying so is cheaper than letting E discover the cliff by crossing it.
    func testSummary_exactlyAtTheCap_saysItIsFull() {
        XCTAssertEqual(PlaceMonitoringCapacity.summary(placeCount: 20), "20 of 20 places — that's the limit")
    }

    // MARK: - Over the cap

    /// The copy must describe what ACTUALLY happens: the nearest 20 are watched and the selection
    /// re-runs as you move. Wording like "8 places are not working" would be simply untrue.
    func testSummary_overTheCap_explainsThatTheNearestAreWatched() {
        XCTAssertEqual(
            PlaceMonitoringCapacity.summary(placeCount: 24),
            "24 places — iOS watches the 20 nearest you"
        )
    }

    func testIsOverCapacity_isTrueOnlyPastTheLimit() {
        XCTAssertTrue(PlaceMonitoringCapacity.isOverCapacity(placeCount: 21))
        XCTAssertTrue(PlaceMonitoringCapacity.isOverCapacity(placeCount: 100))
    }

    // MARK: - Nothing yet

    /// An empty list already says "No places yet" in its empty state; a "0 of 20" underneath it
    /// is noise at the exact moment E has nothing to reason about.
    func testSummary_withNoPlaces_isAbsent() {
        XCTAssertNil(PlaceMonitoringCapacity.summaryIfWorthShowing(placeCount: 0))
        XCTAssertNotNil(PlaceMonitoringCapacity.summaryIfWorthShowing(placeCount: 1))
    }

    // MARK: - Robustness

    /// A negative count cannot happen through the UI, but the formatter must not produce
    /// nonsense ("-3 of 20") if it ever did.
    func testSummary_withANonsenseCount_doesNotProduceNonsense() {
        XCTAssertNil(PlaceMonitoringCapacity.summaryIfWorthShowing(placeCount: -3))
        XCTAssertEqual(PlaceMonitoringCapacity.remaining(placeCount: -3), 20)
    }
}

//
//  SprintRingGeometryTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The polar placement maths behind S4's sprint ring: where a checkpoint dot sits on the ring's
/// stroke centreline. The linear track's `dotOffset` maths, made assertable before the rebuild —
/// twelve o'clock is fraction 0 and the dial runs clockwise, matching `ClosureRing`'s -90° trim.
final class SprintRingGeometryTests: XCTestCase {
    private let accuracy = 0.0001

    // MARK: - Fraction

    func testFraction_isTheCheckpointsShareOfTheSprint() {
        XCTAssertEqual(SprintRingGeometry.fraction(checkpoint: 375, durationSeconds: 1500), 0.25, accuracy: accuracy)
        XCTAssertEqual(SprintRingGeometry.fraction(checkpoint: 750, durationSeconds: 1500), 0.5, accuracy: accuracy)
    }

    /// The same guard rails the linear track had: a checkpoint past the end pins to the end, a
    /// negative one to the start, and a zero-duration sprint has no meaningful positions at all.
    func testFraction_clampsIntoTheSprint() {
        XCTAssertEqual(SprintRingGeometry.fraction(checkpoint: 2000, durationSeconds: 1500), 1, accuracy: accuracy)
        XCTAssertEqual(SprintRingGeometry.fraction(checkpoint: -30, durationSeconds: 1500), 0, accuracy: accuracy)
        XCTAssertEqual(SprintRingGeometry.fraction(checkpoint: 300, durationSeconds: 0), 0, accuracy: accuracy)
    }

    // MARK: - Dot centre

    /// The four compass points, in the ring's own size×size space: fraction 0 at twelve o'clock,
    /// then clockwise — right, bottom, left — on the stroke centreline (radius size/2).
    func testDotCenter_walksTheDialClockwiseFromTwelve() {
        let size: CGFloat = 56

        let top = SprintRingGeometry.dotCenter(checkpoint: 0, durationSeconds: 1500, size: size)
        XCTAssertEqual(top.x, 28, accuracy: accuracy)
        XCTAssertEqual(top.y, 0, accuracy: accuracy)

        let right = SprintRingGeometry.dotCenter(checkpoint: 375, durationSeconds: 1500, size: size)
        XCTAssertEqual(right.x, 56, accuracy: accuracy)
        XCTAssertEqual(right.y, 28, accuracy: accuracy)

        let bottom = SprintRingGeometry.dotCenter(checkpoint: 750, durationSeconds: 1500, size: size)
        XCTAssertEqual(bottom.x, 28, accuracy: accuracy)
        XCTAssertEqual(bottom.y, 56, accuracy: accuracy)

        let left = SprintRingGeometry.dotCenter(checkpoint: 1125, durationSeconds: 1500, size: size)
        XCTAssertEqual(left.x, 0, accuracy: accuracy)
        XCTAssertEqual(left.y, 28, accuracy: accuracy)
    }

    /// A zero-duration sprint parks every dot at twelve o'clock rather than trapping — the
    /// `dotOffset` guard, preserved.
    func testDotCenter_zeroDurationParksAtTwelve() {
        let point = SprintRingGeometry.dotCenter(checkpoint: 300, durationSeconds: 0, size: 56)
        XCTAssertEqual(point.x, 28, accuracy: accuracy)
        XCTAssertEqual(point.y, 0, accuracy: accuracy)
    }
}

//
//  ChipFlowArithmeticTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The wrap arithmetic behind `FlowingChips` (E's 2026-08-25 note: chips should hug their words
/// and flow, not sit in a sparse two-column grid). Pure geometry, extracted so the `Layout`
/// conformance is a thin caller and the wrapping rules are testable without rendering anything.
final class ChipFlowArithmeticTests: XCTestCase {
    private func sizes(_ widths: [CGFloat], height: CGFloat = 36) -> [CGSize] {
        widths.map { CGSize(width: $0, height: height) }
    }

    func testSingleRow_placesLeftToRightWithSpacing() {
        let placement = ChipFlowArithmetic.placement(
            of: sizes([50, 70]), spacing: 8, maxWidth: 200
        )

        XCTAssertEqual(placement.origins, [CGPoint(x: 0, y: 0), CGPoint(x: 58, y: 0)])
        XCTAssertEqual(placement.size, CGSize(width: 128, height: 36))
    }

    func testWrap_startsANewRowWhenTheNextChipWouldOverflow() {
        let placement = ChipFlowArithmetic.placement(
            of: sizes([90, 90, 90]), spacing: 8, maxWidth: 200
        )

        // 90 + 8 + 90 = 188 fits; the third would need 286 — it wraps.
        XCTAssertEqual(placement.origins[2], CGPoint(x: 0, y: 44))
        XCTAssertEqual(placement.size, CGSize(width: 188, height: 80))
    }

    /// A chip wider than the container gets a row to itself rather than being lost — degenerate,
    /// but a very long tag name at an accessibility size can produce it.
    func testOversizeChip_takesItsOwnRow() {
        let placement = ChipFlowArithmetic.placement(
            of: sizes([250, 50]), spacing: 8, maxWidth: 200
        )

        XCTAssertEqual(placement.origins, [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 44)])
    }

    func testRowHeight_comesFromTheTallestChipInTheRow() {
        let placement = ChipFlowArithmetic.placement(
            of: [CGSize(width: 50, height: 36), CGSize(width: 50, height: 60), CGSize(width: 50, height: 36)],
            spacing: 8, maxWidth: 200
        )

        // All three fit one row; the row is as tall as its tallest chip.
        XCTAssertEqual(placement.origins.map(\.y), [0, 0, 0])
        XCTAssertEqual(placement.size.height, 60)
    }

    func testEmpty_isZero() {
        let placement = ChipFlowArithmetic.placement(of: [], spacing: 8, maxWidth: 200)

        XCTAssertEqual(placement.origins, [])
        XCTAssertEqual(placement.size, .zero)
    }
}

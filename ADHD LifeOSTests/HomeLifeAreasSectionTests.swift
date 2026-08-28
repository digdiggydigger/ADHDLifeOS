//
//  HomeLifeAreasSectionTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// What Today's life-area list says about itself once it is collapsed.
///
/// Collapsing must not amount to hiding: the section is the largest thing on Today, and a header
/// that folds away to nothing would take the one number worth glancing at with it. The summary is
/// what stays behind.
final class HomeLifeAreasSectionTests: XCTestCase {
    private func item(open: Int) -> MomentumScoreboard.AreaMomentum {
        MomentumScoreboard.AreaMomentum(
            area: LifeArea(id: UUID(), name: "Health", colour: "🫀", sortOrder: 0),
            closedThisWeek: 0,
            open: open,
            lastClosedAt: nil
        )
    }

    func testCollapsedLine_countsAreasAndTheirOpenWork() {
        XCTAssertEqual(
            HomeLifeAreasSection.collapsedLine(items: [item(open: 2), item(open: 1)]),
            "2 areas · 3 open"
        )
    }

    func testCollapsedLine_singularAreaReadsAsOne() {
        XCTAssertEqual(HomeLifeAreasSection.collapsedLine(items: [item(open: 1)]), "1 area · 1 open")
    }

    /// Nothing open is the good state, so it is named rather than rendered as a zero — the rule
    /// "Inbox clear" and "Nothing due" already follow.
    func testCollapsedLine_nothingOpenIsNotAZero() {
        XCTAssertEqual(
            HomeLifeAreasSection.collapsedLine(items: [item(open: 0), item(open: 0)]),
            "2 areas · nothing open"
        )
    }

    func testCollapsedLine_noAreasAtAll() {
        XCTAssertEqual(HomeLifeAreasSection.collapsedLine(items: []), "No areas yet")
    }
}

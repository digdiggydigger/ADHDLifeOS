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

    // MARK: - The Arrange control's visibility

    /// **Arrange acts on the ROWS, so with the section folded it has nothing to act on** (E's
    /// screenshot note, 2026-08-28: it should hide inside the fold along with the list). Left
    /// visible it is a button whose entire effect is off-screen — and tapping it force-expands the
    /// section, so it silently undoes the fold the user just chose.
    func testShowsArrangeControl_hiddenWhileTheSectionIsFolded() {
        XCTAssertFalse(HomeLifeAreasSection.showsArrangeControl(areaCount: 8, isExpanded: false))
    }

    func testShowsArrangeControl_visibleWhenExpandedWithSomethingToReorder() {
        XCTAssertTrue(HomeLifeAreasSection.showsArrangeControl(areaCount: 2, isExpanded: true))
    }

    /// The older rule, which still holds: reordering is meaningless below two rows.
    func testShowsArrangeControl_hiddenBelowTwoAreasEvenWhenExpanded() {
        XCTAssertFalse(HomeLifeAreasSection.showsArrangeControl(areaCount: 1, isExpanded: true))
        XCTAssertFalse(HomeLifeAreasSection.showsArrangeControl(areaCount: 0, isExpanded: true))
    }

    /// Arrange mode force-expands the section, so `isExpanded` is true throughout it. That is what
    /// keeps the button — reading "Done" by then — on screen to get back OUT of the mode, rather
    /// than vanishing under the new rule and stranding the user in it.
    func testShowsArrangeControl_survivesIntoArrangeModeBecauseThatModeForcesExpansion() {
        XCTAssertTrue(HomeLifeAreasSection.showsArrangeControl(areaCount: 8, isExpanded: true))
    }
}

//
//  TabNavigationTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// E's rule, 2026-09-08: tapping the tab you are already on takes you back to that tab's
/// top-level page; at the top-level page it scrolls to the top (the iOS convention). The bar
/// only knows the selection; each tab root knows its own depth — so the two meet in a
/// coordinator that carries the re-tap DOWN and the depth UP.
@MainActor
final class TabNavigationTests: XCTestCase {

    // MARK: - The rule

    func testResponse_deepInTheTab_popsToRoot() {
        XCTAssertEqual(TabReselectionResponse.response(isAtRoot: false), .popToRoot)
    }

    func testResponse_atTheTopLevel_scrollsToTop() {
        XCTAssertEqual(TabReselectionResponse.response(isAtRoot: true), .scrollToTop)
    }

    // MARK: - The bar's tap

    func testTapOutcome_aDifferentTab_selectsIt() {
        XCTAssertEqual(
            AppTabBarPresentation.tapOutcome(current: .today, tapped: .tasks), .select(.tasks)
        )
    }

    func testTapOutcome_theCurrentTab_reselectsIt() {
        XCTAssertEqual(
            AppTabBarPresentation.tapOutcome(current: .today, tapped: .today), .reselect(.today)
        )
    }

    // MARK: - The coordinator

    func testReselect_bumpsOnlyThatTab() {
        let coordinator = TabNavigationCoordinator()

        coordinator.reselect(.today)
        coordinator.reselect(.today)
        coordinator.reselect(.tools)

        XCTAssertEqual(coordinator.reselectionCount(for: .today), 2)
        XCTAssertEqual(coordinator.reselectionCount(for: .tools), 1)
        XCTAssertEqual(coordinator.reselectionCount(for: .tasks), 0)
    }

    /// A tab that has never reported is at its top-level page — the only place an unvisited tab
    /// can be. The default must be true, or the search row (block 2) would hide on every tab
    /// until each one had been visited.
    func testIsAtRoot_defaultsToTrueForAnUnreportedTab() {
        XCTAssertTrue(TabNavigationCoordinator().isAtRoot(.journal))
    }

    func testReport_recordsDepthPerTab() {
        let coordinator = TabNavigationCoordinator()

        coordinator.report(.today, isAtRoot: false)
        coordinator.report(.tasks, isAtRoot: true)

        XCTAssertFalse(coordinator.isAtRoot(.today))
        XCTAssertTrue(coordinator.isAtRoot(.tasks))
    }

    func testReport_theLatestReportWins() {
        let coordinator = TabNavigationCoordinator()

        coordinator.report(.today, isAtRoot: false)
        coordinator.report(.today, isAtRoot: true)

        XCTAssertTrue(coordinator.isAtRoot(.today))
    }
}

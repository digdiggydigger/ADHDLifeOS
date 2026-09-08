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

    // MARK: - The capture disc (E's GIF, 2026-09-08 evening)

    /// A re-tap's scroll-to-top is "the page scrolled upwards again" — E's sticky-pill rule of
    /// 2026-08-31 — but it is a programmatic scroll, so the pan-driven pill never sees it. E's
    /// GIF: the tab bar restored (it reads the offset) and the pill stayed collapsed over a page
    /// sitting at the top until a finger nudged it.
    func testResponse_scrollToTop_restoresTheCaptureDisc() {
        XCTAssertTrue(
            TabReselectionResponse.scrollToTop.restoresCaptureDisc,
            "A scroll-to-top re-tap leaves the capture disc as a pill over a page at the top —"
                + " E's GIF, unchanged."
        )
    }

    /// A pop brings the root page back at its old offset; the pill's state there is still
    /// honest, so nothing about the disc changes.
    func testResponse_popToRoot_leavesTheCaptureDiscAlone() {
        XCTAssertFalse(
            TabReselectionResponse.popToRoot.restoresCaptureDisc,
            "A pop-to-root re-tap restores the disc over a list that is still scrolled down."
        )
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

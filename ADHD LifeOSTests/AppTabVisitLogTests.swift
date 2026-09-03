//
//  AppTabVisitLogTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The rule that makes the app's own tab container behave like the `TabView` it replaced:
/// a tab is BUILT the first time it is selected, and stays built for ever after.
///
/// Both halves matter and they pull in opposite directions. Building eagerly would have all six
/// screens fetching at launch; discarding on the way out would throw away every tab's scroll
/// position and `NavigationStack` depth, which is the exact regression the architecture note
/// warned a `switch selectedTab` would cause.
final class AppTabVisitLogTests: XCTestCase {

    func testOnlyTheStartingTabIsBuiltAtLaunch() {
        let log = AppTabVisitLog(initial: .today)
        XCTAssertTrue(log.isBuilt(.today))
        for tab in AppTab.allCases where tab != .today {
            XCTAssertFalse(log.isBuilt(tab), "\(tab) was built before it was ever selected")
        }
    }

    func testSelectingATabBuildsIt() {
        var log = AppTabVisitLog(initial: .today)
        log.select(.tools)
        XCTAssertTrue(log.isBuilt(.tools))
    }

    /// **The property the whole container exists for.** Leaving a tab must not unbuild it, or
    /// its scroll offset and pushed screens go with it.
    func testATabStaysBuiltAfterMovingAwayFromIt() {
        var log = AppTabVisitLog(initial: .today)
        log.select(.journal)
        log.select(.captures)
        log.select(.today)
        XCTAssertTrue(log.isBuilt(.journal))
        XCTAssertTrue(log.isBuilt(.captures))
        XCTAssertTrue(log.isBuilt(.today))
    }

    func testUnvisitedTabsStayUnbuiltHoweverMuchTheOthersAreUsed() {
        var log = AppTabVisitLog(initial: .today)
        for _ in 1...5 {
            log.select(.tasks)
            log.select(.today)
        }
        XCTAssertFalse(log.isBuilt(.tools))
        XCTAssertFalse(log.isBuilt(.areas))
    }

    func testSelectingTheSameTabTwiceChangesNothing() {
        var log = AppTabVisitLog(initial: .today)
        log.select(.areas)
        let after = log.builtTabs
        log.select(.areas)
        XCTAssertEqual(log.builtTabs, after)
    }

    /// Visiting everything ends with everything built — the steady state after a user has been
    /// round the app once, and the state in which the container is at its most expensive.
    func testVisitingEveryTabBuildsEveryTab() {
        var log = AppTabVisitLog(initial: .today)
        for tab in AppTab.allCases { log.select(tab) }
        XCTAssertEqual(log.builtTabs, Set(AppTab.allCases))
    }
}

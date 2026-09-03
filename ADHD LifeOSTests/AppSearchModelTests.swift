//
//  AppSearchModelTests.swift
//  ADHD LifeOSTests
//
//  The app-level search state: which scope is live, and whether the full-screen surface is open.
//
//  **The rule this file mostly exists for is the scope change.** `AppTabContent` keeps every
//  visited tab alive so that scroll position and navigation depth survive a switch — which means
//  `.onAppear` / `.onDisappear` fire once on first build and then effectively never again. Any
//  "register my search when I appear, clear it when I leave" design is silently broken. The scope
//  is therefore driven from `selectedTab`, and everything that must reset on a tab change resets
//  HERE, in a pure type, where it can be tested. `TabBarScrollActivity.reset()` exists for the
//  same reason and was settled the same way.
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class AppSearchModelTests: XCTestCase {

    func testStartsClosedWithNoScope() {
        let model = AppSearchModel()

        XCTAssertEqual(model.scope, AppSearchScope.none)
        XCTAssertFalse(model.isPresentingSurface)
        XCTAssertEqual(model.query, "")
    }

    // MARK: - Opening

    func testOpeningASearchableScopePresentsTheSurface() {
        let model = AppSearchModel()
        model.activate(.tasks)

        model.open()

        XCTAssertTrue(model.isPresentingSurface)
    }

    /// There is nothing to search on Home, Areas or Tools, so nothing can be opened there. Without
    /// this the surface could be presented over a screen with no results view behind it.
    func testOpeningWithoutAScopeIsANoOp() {
        let model = AppSearchModel()

        model.open()

        XCTAssertFalse(
            model.isPresentingSurface,
            "The search surface opened on a screen with no search scope, so it would present with"
                + " nothing to show."
        )
    }

    // MARK: - Changing tab

    /// A query typed on Tasks must not still be filtering when the user comes back from another
    /// tab. Same reasoning as the bar's and the disc's reset on tab change: state left over from
    /// a screen the user has left reads as a bug.
    func testChangingScopeClearsTheQuery() {
        let model = AppSearchModel()
        model.activate(.tasks)
        model.query = "dentist"

        model.activate(.none)

        XCTAssertEqual(
            model.query, "",
            "A query survived a tab change, so the list is still filtered by something the user"
                + " typed somewhere else."
        )
    }

    func testChangingScopeClosesTheSurface() {
        let model = AppSearchModel()
        model.activate(.tasks)
        model.open()

        model.activate(.none)

        XCTAssertFalse(
            model.isPresentingSurface,
            "The full-screen surface survived a tab change, so it is showing one screen's results"
                + " on top of another screen."
        )
    }

    /// Re-activating the SAME scope is what a redundant `onChange` does; it must not wipe a query
    /// mid-type.
    func testReactivatingTheSameScopeKeepsTheQuery() {
        let model = AppSearchModel()
        model.activate(.tasks)
        model.query = "dentist"

        model.activate(.tasks)

        XCTAssertEqual(
            model.query, "dentist",
            "Re-activating the scope already active wiped the query. A redundant state update"
                + " would then clear the field out from under the user."
        )
    }

    // MARK: - Closing

    func testCancellingClosesAndClearsTheQuery() {
        let model = AppSearchModel()
        model.activate(.tasks)
        model.query = "dentist"
        model.open()

        model.close()

        XCTAssertFalse(model.isPresentingSurface)
        XCTAssertEqual(
            model.query, "",
            "Cancel left the query behind, so the list stays filtered by a search the user just"
                + " dismissed."
        )
    }
}

//
//  TabReselectionJourneyUITests.swift
//  ADHD LifeOSUITests
//
//  E's rule (2026-09-08), driven on the simulator against the Firebase emulator: tapping the
//  tab you are already on returns you to that tab's top-level page; at the top-level page it
//  scrolls to the top. E's own example is the journey — Today → Nudges, then "there is no way
//  to get back to the Today main page".
//
//  **This is the block's acceptance test.** `TabNavigationTests` proves the rule and the
//  coordinator; `TabNavigationCallSiteTests` proves every tab root calls the modifier; only
//  this proves a tap on the bar actually pops a pushed screen, because the pop happens inside
//  SwiftUI's navigation and no unit test can see it.
//

import XCTest

final class TabReselectionJourneyUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// E's example, exactly: into Nudges from Today, then the Today tab brings Today back.
    @MainActor
    func testReTappingTodayFromNudgesReturnsToTodaysTopLevel() throws {
        try UITestEmulator.skipUnlessRunning()
        let account = try UITestSession.createAccount(label: "retap-nudges")
        let app = try UITestSession.launchSignedIn(as: account)

        let door = app.buttons["homeNudgesFirstRunDirective"]
        UITestSession.scrollUntilHittable(door, in: app)
        XCTAssertTrue(door.waitForExistence(timeout: UITestSession.timeout), "Today's Nudges door never appeared")
        door.tap()

        let nudges = app.staticTexts["nudgesEmptyState"]
        XCTAssertTrue(nudges.waitForExistence(timeout: UITestSession.timeout), "Nudges did not push")
        attach(app, "1-nudges-pushed-from-today")

        reTapToday(app)

        XCTAssertTrue(
            door.waitForExistence(timeout: UITestSession.timeout),
            "Re-tapping Today with Nudges pushed did not bring Today back — E's report, unchanged."
        )
        XCTAssertFalse(nudges.exists, "Nudges is still on screen after the Today re-tap.")
        attach(app, "2-today-back-after-retap")
    }

    /// The pushed Nudges screen has a visible way back of its own now, not only the re-tap.
    @MainActor
    func testNudgesShowsABackControl() throws {
        try UITestEmulator.skipUnlessRunning()
        let account = try UITestSession.createAccount(label: "retap-nudges-back")
        let app = try UITestSession.launchSignedIn(as: account)

        let door = app.buttons["homeNudgesFirstRunDirective"]
        UITestSession.scrollUntilHittable(door, in: app)
        XCTAssertTrue(door.waitForExistence(timeout: UITestSession.timeout))
        door.tap()
        XCTAssertTrue(app.staticTexts["nudgesEmptyState"].waitForExistence(timeout: UITestSession.timeout))

        let back = app.buttons["nudgesBackButton"]
        XCTAssertTrue(
            back.waitForExistence(timeout: UITestSession.timeout),
            "Nudges draws no back control; the edge swipe is the only way out."
        )
        back.tap()
        XCTAssertTrue(door.waitForExistence(timeout: UITestSession.timeout), "Back from Nudges did not return to Today")
    }

    /// At the top-level page, a re-tap scrolls to the top: the title's frame comes back to where
    /// it started after a scroll pushed it off. Frames, because "it scrolled" is otherwise a
    /// claim a passing test can make on a broken build.
    @MainActor
    func testReTappingTodayAtTheTopLevelScrollsToTheTop() throws {
        try UITestEmulator.skipUnlessRunning()
        let account = try UITestSession.createAccount(label: "retap-scroll")
        let app = try UITestSession.launchSignedIn(as: account)

        // The page title by identifier — `staticTexts["Today"]` also matches the tab bar's pill
        // label, which sits at the bottom of the screen and never scrolls.
        let title = app.staticTexts["homeTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: UITestSession.timeout), "Today's title never appeared")
        // Today loads its sections after the title; on a fresh account the page is too short
        // to scroll until they land. The nudges door is the last card, so its existence is the
        // "content is here" landmark.
        XCTAssertTrue(
            app.buttons["homeNudgesFirstRunDirective"].waitForExistence(timeout: UITestSession.timeout),
            "Today's content never loaded, so there is nothing to scroll."
        )
        let restingY = title.frame.minY

        app.swipeUp()
        app.swipeUp()
        let scrolledY = title.exists ? title.frame.minY : -1_000
        XCTAssertLessThan(scrolledY, restingY - 100, "The swipes did not move Today; nothing to scroll back from.")

        reTapToday(app)

        let returned = NSPredicate { _, _ in title.exists && abs(title.frame.minY - restingY) < 4 }
        let settled = XCTNSPredicateExpectation(predicate: returned, object: nil)
        XCTAssertEqual(
            XCTWaiter().wait(for: [settled], timeout: UITestSession.timeout), .completed,
            "A re-tap at Today's top level did not scroll back to the top (title at"
                + " \(title.exists ? title.frame.minY : -1_000), was \(restingY))."
        )
    }

    /// A tap on the tab that is ALREADY selected. `UITestSession.openTab` returns early when the
    /// slot reports `isSelected`, which is the right behaviour for every other journey and the
    /// exact thing this one must not do — the first run of this file passed nothing through it.
    @MainActor
    private func reTapToday(_ app: XCUIApplication) {
        let today = UITestSession.tabButton("Today", in: app)
        XCTAssertTrue(today.waitForExistence(timeout: UITestSession.timeout), "The Today slot is missing")
        XCTAssertTrue(today.isSelected, "Today is not the selected tab, so this would be a select, not a re-tap")
        today.tap()
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}

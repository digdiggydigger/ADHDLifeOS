//
//  UITestTabs.swift
//  ADHD LifeOSUITests
//
//  Tab navigation for the journeys, split out of `UITestSession.swift` (F-Routines-B) the same
//  way `SignedInJourneySupport` was split out of `SignedInJourneyUITests` — hoisting this one
//  helper put that file at 407 lines against SwiftLint's 400 bar.
//
//  It lives on `UITestSession` rather than on a test class because two journey classes now need
//  it, and the alternative was a sixth hand-rolled copy of a loop whose retry rules were each
//  paid for by a failed run.
//

import XCTest

extension UITestSession {
    /// Taps a tab until it is actually SELECTED.
    ///
    /// Hoisted here from `SignedInJourneySupport` (F-Routines-B) so a second journey class can
    /// reach it without making a copy — the same move `scrollUntilHittable` made after it had
    /// been re-implemented five times, each copy swiping without settling in its own way.
    ///
    /// The two hard-won details: a plain `.tap()` goes through hittability resolution that a
    /// just-dismissed cover can still interfere with, so retries tap the COORDINATE instead; and
    /// each attempt builds a FRESH expectation, because XCTest allows one to be waited on exactly
    /// once and a hoisted one raises an API violation instead of retrying.
    @MainActor
    static func openTab(_ name: String, in app: XCUIApplication) {
        let tab = tabButton(name, in: app)
        XCTAssertTrue(
            tab.waitForExistence(timeout: timeout),
            "The \(name) tab is missing from the tab bar"
        )
        for attempt in 1...3 {
            if tab.isSelected { return }
            if attempt == 1 {
                tab.tap()
            } else {
                tab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            }
            let selected = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "isSelected == true"), object: tab
            )
            if XCTWaiter().wait(for: [selected], timeout: 4) == .completed { return }
        }
        XCTAssertTrue(tab.isSelected, "The \(name) tab never became selected")
    }
}

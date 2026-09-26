//
//  UITestNudges.swift
//  ADHD LifeOSUITests
//
//  The one way into the Nudges screen, shared so no journey hand-rolls it.
//
//  `F-E3-OneCardToday`: Today's nudges door left with round 3's one card, and E's Step 0 answer
//  (2026-09-24) moved it to Tools, beside Routines. Due nudges still show on Today, at the top of
//  the "then" list — but the SCREEN (create, edit, pause, history) is reached only from here.
//

import XCTest

extension UITestSession {
    /// Opens Tools, brings its Nudges row into reach, and pushes the Nudges screen — retried,
    /// because a tap taken while a tab is still settling is a silent no-op. Returns whether the
    /// screen's own landmark (the header's add button) appeared.
    @MainActor
    @discardableResult
    static func openNudgesFromTools(in app: XCUIApplication) -> Bool {
        openTab("Tools", in: app)
        let row = app.buttons["toolsNudgesRow"].firstMatch
        _ = scrollUntilHittable(row, in: app)
        XCTAssertTrue(
            row.waitForExistence(timeout: timeout),
            "The Tools page draws no Nudges row, so the Nudges screen is unreachable"
        )
        return tap(row, untilExists: app.buttons["nudgeAddButton"])
    }
}

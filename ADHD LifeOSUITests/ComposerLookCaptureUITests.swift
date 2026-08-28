//
//  ComposerLookCaptureUITests.swift
//  ADHD LifeOSUITests
//
//  TEMPORARY — a camera, not a test. Captures the journal composer in both entry kinds so the
//  look can be reviewed against a real render instead of guessed at. Delete once the design is
//  settled; it asserts almost nothing and would otherwise just cost 90 seconds a run.
//

import XCTest

final class ComposerLookCaptureUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        try UITestEmulator.skipUnlessRunning()
    }

    @MainActor
    func testCaptureComposerBothKinds() throws {
        let app = try UITestSession.launchSignedIn(label: "look")

        let journalTab = app.tabBars.buttons["Journal"]
        XCTAssertTrue(journalTab.waitForExistence(timeout: UITestSession.timeout))
        journalTab.tap()

        let compose = app.buttons["journalComposeButton"]
        XCTAssertTrue(compose.waitForExistence(timeout: UITestSession.timeout), "No compose button")
        compose.tap()

        let journalChip = app.buttons["logComposerType-journal"]
        XCTAssertTrue(journalChip.waitForExistence(timeout: UITestSession.timeout), "Composer never opened")

        attach(app, named: "01-log-selected")
        journalChip.tap()
        attach(app, named: "02-journal-selected")
    }

    @MainActor
    private func attach(_ app: XCUIApplication, named name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}

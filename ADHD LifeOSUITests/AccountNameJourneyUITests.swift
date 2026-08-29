//
//  AccountNameJourneyUITests.swift
//  ADHD LifeOSUITests
//
//  F-AccountName end to end. Two of that block's acceptance criteria are about a row APPEARING
//  and DISAPPEARING, which no unit test can observe — the unit suite covers the rule underneath
//  (`AuthDisplayNameTests`), and this covers that the rule is reachable at all.
//

import XCTest

final class AccountNameJourneyUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        try UITestEmulator.skipUnlessRunning()
    }

    /// A brand-new emulator account has NO display name — which is the state E's own account has
    /// been in the whole time, and the reason the Name row could never appear for them.
    @MainActor
    func testAccountName_canBeSetThenClearedFromSettings() throws {
        let app = try UITestSession.launchSignedIn(label: "accountname")
        openSettings(app)

        let nameRow = app.descendants(matching: .any)["settingsAccountNameRow"]
        let addButton = app.buttons["settingsAddAccountNameButton"]
        // Scroll it into being, not just into view. SwiftUI materialises `Form` rows lazily, so a
        // row below the fold does not EXIST to XCUITest at all — the same reason `signOutButton`
        // needs this. `waitForExistence` alone waits for something that will never arrive.
        scrollUntilExists(addButton, in: app)
        XCTAssertTrue(addButton.waitForExistence(timeout: UITestSession.timeout), "No way in")
        XCTAssertFalse(nameRow.exists, "An account with no name must render no Name row")

        setName(to: "Ethan", in: app, from: addButton)
        XCTAssertTrue(
            nameRow.waitForExistence(timeout: UITestSession.timeout),
            "Setting a name on an account that never had one did not make the Name row appear"
                + Self.reportedError(in: app)
        )

        // And back: an empty field CLEARS rather than storing "" as a name to greet you by.
        setName(to: "", in: app, from: nameRow)
        let gone = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"), object: nameRow
        )
        XCTAssertEqual(
            XCTWaiter().wait(for: [gone], timeout: UITestSession.timeout), .completed,
            "Clearing the name left the row behind — it must disappear, not render blank"
        )
        XCTAssertTrue(addButton.waitForExistence(timeout: UITestSession.timeout))
    }

    /// The failure message should say WHY where the app knows why. `updateDisplayName` surfaces a
    /// failed write into the Account section's footer precisely so it is never silent; a journey
    /// that ignored that would report "the row did not appear" while the reason sat on screen.
    @MainActor
    private static func reportedError(in app: XCUIApplication) -> String {
        let error = app.descendants(matching: .any)["settingsAccountNameError"]
        return error.exists ? " — the app reported: \(error.label)" : " (and reported no error)"
    }

    /// Bounded, so a genuinely absent control still fails fast rather than swiping forever.
    @MainActor
    private func scrollUntilExists(_ element: XCUIElement, in app: XCUIApplication, attempts: Int = 8) {
        var remaining = attempts
        while !element.exists, remaining > 0 {
            app.swipeUp()
            remaining -= 1
        }
    }

    @MainActor
    private func openSettings(_ app: XCUIApplication) {
        let settings = app.buttons["settingsButton"]
        XCTAssertTrue(
            UITestSession.tap(settings, untilExists: app.buttons["settingsDoneButton"]),
            "Settings did not open"
        )
    }

    /// Opens the rename alert from whichever control is currently the way in, types, and saves.
    @MainActor
    private func setName(to name: String, in app: XCUIApplication, from entry: XCUIElement) {
        // Query INSIDE the alert. An alert is its own element tree, and its text field is not
        // reliably reachable from `app.textFields` — the first version of this looked there, found
        // nothing, and reported "the alert never opened" about an alert that had opened perfectly.
        let alert = app.alerts.firstMatch
        XCTAssertTrue(UITestSession.tap(entry, untilExists: alert), "The name alert never opened")
        let field = alert.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: UITestSession.timeout), "No name field")
        field.tap()
        // Typing APPENDS, so clearing "Ethan" needs deletes — an empty `name` is the clear case
        // this journey exists to prove, and it would silently do nothing without this.
        if let existing = field.value as? String, !existing.isEmpty {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count))
        }
        if !name.isEmpty {
            field.typeText(name)
            // Assert the text actually LANDED. Without this, a mis-focused field leaves the draft
            // empty, Save then clears a name that was already absent, and the whole thing fails
            // later as "the row did not appear" with no error — a true statement that explains
            // nothing.
            XCTAssertEqual(
                field.value as? String, name,
                "The name never reached the field, so Save had nothing to store"
            )
        }
        // Retried until the alert is GONE. Its Save tap gets swallowed exactly like every other
        // tap in this harness, and when it does the alert simply stays up — which then fails much
        // later as "the Name row did not appear", about a row that was never asked for.
        XCTAssertTrue(
            UITestSession.tap(alert.buttons["Save"], untilGone: alert),
            "The name alert would not dismiss, so nothing was ever saved"
        )
    }
}

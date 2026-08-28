//
//  UITestSession.swift
//  ADHD LifeOSUITests
//

import XCTest

/// One throwaway emulator account: the address a test signs in with, and the uid its documents
/// live under (`users/{uid}/...`).
struct UITestAccount {
    let email: String
    let uid: String
}

/// Launches the app against the emulator and gets it to a signed-in state, which every journey
/// below needs before it can begin.
enum UITestSession {
    /// The file's own convention. Sign-in is the slowest step in any of these tests — it is a
    /// network round trip plus first-login seeding (six life areas, five tags, three tasks and a
    /// journal entry, in one batch) — so the waits around it are generous rather than tight.
    /// The 15s timeouts on the older tests were flagged twice as too short for this machine.
    static let timeout: TimeInterval = 45

    /// A brand-new emulator account, not yet signed in to.
    ///
    /// Split from `launchSignedIn` so a test can write documents into the account's collections
    /// BEFORE the app ever launches — the nudge journey needs an already-overdue nudge in place
    /// when Home first loads, and the app has no UI that could produce one.
    static func createAccount(label: String) throws -> UITestAccount {
        let email = UITestEmulator.uniqueEmail(label)
        let uid = try UITestEmulator.createAccount(email: email)
        return UITestAccount(email: email, uid: uid)
    }

    /// A launched app, signed in to a brand-new emulator account seeded exactly as production
    /// seeds one.
    @MainActor
    static func launchSignedIn(label: String) throws -> XCUIApplication {
        try launchSignedIn(as: createAccount(label: label))
    }

    @MainActor
    static func launchSignedIn(as account: UITestAccount) throws -> XCUIApplication {
        let email = account.email
        let app = XCUIApplication()
        // This is what keeps the journey off the live project. `launchEnvironment` becomes the
        // app process's environment, and `FirebaseEmulatorSettings.resolve()` reads it at
        // `FirebaseManager` init — before any Firestore call can happen.
        app.launchEnvironment[emulatorHostKey] = UITestEmulator.host
        app.launch()

        // BEFORE anything waits on the app's own UI. A SpringBoard alert renders above the app,
        // so a permission prompt left standing makes every query miss and the test time out
        // against an app that is running perfectly well behind it. That is exactly what happened
        // to the nudge journey: the app restored a previous session whose account had an overdue
        // nudge, Home asked for notification permission on load, and the alert hid both the login
        // field and the tab bar until the harness gave up and the process was killed — surfacing
        // as "crashed in <external symbol>" rather than as anything resembling its real cause.
        dismissSystemAlertIfPresent()
        signOutIfSignedIn(app)
        try signIn(app, email: email)
        return app
    }

    /// Firebase Auth persists its session in the keychain, and the keychain outlives the app
    /// process — so a test launching after one that signed in would inherit that account and
    /// never see the login screen at all. Signing out through the real UI resets it without
    /// adding a test-only hook to production code, and exercises the sign-out path for free.
    @MainActor
    private static func signOutIfSignedIn(_ app: XCUIApplication) {
        let loginField = app.textFields["loginEmailField"]
        let tabBar = app.tabBars.firstMatch

        // Whichever appears first tells us which state the app restored into.
        let settled = XCTWaiter().wait(
            for: [
                XCTNSPredicateExpectation(predicate: .init(format: "exists == true"), object: loginField),
                XCTNSPredicateExpectation(predicate: .init(format: "exists == true"), object: tabBar)
            ],
            timeout: timeout
        )
        guard settled == .completed || tabBar.exists else { return }
        guard tabBar.exists, !loginField.exists else { return }

        // Wait for the control before tapping it. `tabBar.exists` only proves the signed-in
        // SHELL is up; Today's header arrives with its content, which is a separate load. Tapping
        // a button that is not there yet is a silent no-op, and the failure then surfaced further
        // down as "Settings did not open" — a true statement about the wrong step.
        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(
            settingsButton.waitForExistence(timeout: timeout),
            "Today never presented its Settings control, so the previous session could not be ended"
        )
        settingsButton.tap()

        // Wait for the sheet itself before hunting inside it. The scroll loop below used to start
        // after a 2s grace, so a Settings sheet that was still presenting swallowed all eight
        // swipes — which then scrolled TODAY instead, left it somewhere unexpected, and reported
        // "did not present a sign-out control" for a screen that simply had not opened yet. It
        // failed once the suite grew to five journeys and the simulator got slower under them.
        // `settingsDoneButton` is in the nav bar, so it is present without any scrolling at all.
        XCTAssertTrue(
            app.buttons["settingsDoneButton"].waitForExistence(timeout: timeout),
            "Settings did not open, so sign-out could never be reached"
        )

        let signOut = app.buttons["signOutButton"]
        // SwiftUI materialises Form rows lazily, so a row below the fold does not EXIST to
        // XCUITest until it scrolls into view — and the Momentum blocks keep adding rows above
        // this one (M2, M7, M9 each moved the fold; M9 was the one that finally pushed sign-out
        // under it and failed three journeys). Hunt for the row the way a user would instead of
        // asserting on where the fold happens to fall this release.
        _ = signOut.waitForExistence(timeout: 2)
        var scrollsRemaining = 8
        while !(signOut.exists && signOut.isHittable), scrollsRemaining > 0 {
            app.swipeUp()
            scrollsRemaining -= 1
        }
        XCTAssertTrue(signOut.exists, "Settings opened but presented no sign-out control")
        signOut.tap()
        XCTAssertTrue(
            loginField.waitForExistence(timeout: timeout),
            "Signing out did not return the app to the login screen"
        )
    }

    @MainActor
    private static func signIn(_ app: XCUIApplication, email: String) throws {
        let emailField = app.textFields["loginEmailField"]
        let passwordField = app.secureTextFields["loginPasswordField"]
        let signInButton = app.buttons["signInButton"]

        XCTAssertTrue(emailField.waitForExistence(timeout: timeout), "Login form never appeared")
        focusAndType(emailField, text: email, in: app)
        focusAndType(passwordField, text: UITestEmulator.password, in: app)
        XCTAssertTrue(signInButton.isEnabled, "Sign In stayed disabled with both fields filled")
        signInButton.tap()

        // And again after signing in: the notification prompt is triggered by loading nudges,
        // which only happens once Home appears.
        dismissSystemAlertIfPresent()

        // The tab bar is the app's signed-in shell; waiting on it also waits out first-login
        // seeding, since both land after the same auth state change.
        XCTAssertTrue(
            app.tabBars.firstMatch.waitForExistence(timeout: timeout),
            "Sign-in did not reach the signed-in shell — "
                + (app.staticTexts["loginErrorMessage"].exists
                    ? "the form showed: \(app.staticTexts["loginErrorMessage"].label)"
                    : "no inline error was shown")
        )
    }

    /// Grants (or otherwise clears) any pending iOS permission alert. Cheap when there is none:
    /// it waits only on the alert itself, not on each candidate button.
    ///
    /// "Allow" is preferred over "Don't Allow" because granting settles the prompt for the rest of
    /// the run, whereas denying leaves the app free to ask again on the next launch.
    @MainActor
    static func dismissSystemAlertIfPresent(timeout: TimeInterval = 5) {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alert = springboard.alerts.firstMatch
        guard alert.waitForExistence(timeout: timeout) else { return }

        for label in ["Allow", "OK", "Allow While Using App", "Don’t Allow"] where alert.buttons[label].exists {
            alert.buttons[label].tap()
            return
        }
        alert.buttons.firstMatch.tap()
    }

    // MARK: - Input

    /// Taps `element` and waits for the software keyboard before typing.
    ///
    /// On a headless simulator XCUITest can synthesize a tap before SwiftUI has granted the field
    /// keyboard focus, which surfaces as "Neither element nor any descendant has keyboard focus"
    /// from `typeText`. Waiting for `isHittable` and then for the keyboard confirms focus landed,
    /// instead of guessing with a fixed sleep.
    @MainActor
    static func focusAndType(_ element: XCUIElement, text: String, in app: XCUIApplication) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout))
        let hittable = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isHittable == true"), object: element)
        XCTAssertEqual(
            XCTWaiter().wait(for: [hittable], timeout: timeout), .completed,
            "\(element) never became hittable"
        )
        element.tap()
        XCTAssertTrue(
            app.keyboards.element.waitForExistence(timeout: timeout),
            "Keyboard did not appear after tapping \(element)"
        )
        element.typeText(text)
    }

    /// Mirrors `FirebaseEmulatorSettings.hostKey`. Spelled out rather than imported because the
    /// UI test target does not link the app — it drives it as a black box.
    private static let emulatorHostKey = "LIFEOS_FIREBASE_EMULATOR_HOST"
}

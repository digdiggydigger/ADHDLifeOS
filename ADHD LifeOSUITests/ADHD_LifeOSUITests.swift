//
//  ADHD_LifeOSUITests.swift
//  ADHD LifeOSUITests
//
//  Slimmed to credential-free tests on 2026-08-19: the original suite signed into a seeded
//  Supabase test account via a gitignored `TestCredentials.swift` and drove Supabase REST
//  helpers (`NudgeRestTestHelper`) — none of which survived the Firebase cutover. Those four
//  signed-in journeys (task create, settings dismiss, detail-field population, nudge backdating)
//  were deleted with their helpers, not stubbed: reviving them means a dedicated Firebase test
//  user (ideally against the Auth/Firestore emulators) and a fresh design, tracked as future
//  work. What remains runs against the login screen only — no account, no network writes — so
//  the target compiles and passes on a fresh clone with zero local setup.
//
//  That fresh-clone promise still holds, and `UITestSession.launchSignedOut()` is what keeps it
//  honest. These tests need the LOGIN screen, and a bare `app.launch()` does not guarantee one:
//  Firebase Auth persists its session in the simulator keychain, which outlives the whole test
//  RUN, so a session left by the previous run's journeys restored the app straight into the tab
//  bar. Both tests below failed on it for exactly that reason. See F-LoginTestIsolation.
//

import XCTest

final class ADHD_LifeOSUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLoginForm_rendersFieldsAndValidatesInput() throws {
        let app = UITestSession.launchSignedOut()

        let emailField = app.textFields["loginEmailField"]
        let passwordField = app.secureTextFields["loginPasswordField"]
        let signInButton = app.buttons["signInButton"]

        XCTAssertTrue(
            emailField.waitForExistence(timeout: UITestSession.timeout),
            "The login form never appeared. If the tab bar is up instead, the app restored a"
                + " previous session and `launchSignedOut` failed to end it."
        )
        XCTAssertTrue(passwordField.exists)
        XCTAssertTrue(signInButton.exists)
        // Both alternative sign-in paths are stub-and-hide flags on LoginView, defaulting off:
        // magic links since Stage C.1, and Sign in with Apple since 2026-08-19 (free developer
        // account blocks device deploys with the SIWA entitlement attached).
        XCTAssertFalse(app.buttons["magicLinkButton"].exists, "Magic link is hidden by default")
        XCTAssertFalse(
            app.buttons["signInWithAppleButton"].exists,
            "Sign in with Apple is hidden while the entitlement is off the free-account build"
        )

        XCTAssertFalse(signInButton.isEnabled, "Sign In should be disabled with empty fields")

        UITestSession.focusAndType(emailField, text: "e@example.com", in: app)
        XCTAssertFalse(signInButton.isEnabled, "Sign In should stay disabled until a password is entered too")

        UITestSession.focusAndType(passwordField, text: "correct-horse", in: app)
        XCTAssertTrue(signInButton.isEnabled, "Sign In should enable once both fields are filled")
    }

    @MainActor
    func testSignIn_invalidCredentials_showsInlineErrorAndStaysOnLoginForm() throws {
        let app = UITestSession.launchSignedOut()

        let emailField = app.textFields["loginEmailField"]
        let passwordField = app.secureTextFields["loginPasswordField"]
        let signInButton = app.buttons["signInButton"]

        XCTAssertTrue(
            emailField.waitForExistence(timeout: UITestSession.timeout),
            "The login form never appeared — see the note on the test above."
        )

        UITestSession.focusAndType(emailField, text: "nonexistent-user@example.com", in: app)
        UITestSession.focusAndType(passwordField, text: "definitely-wrong-password", in: app)
        signInButton.tap()

        let errorMessage = app.staticTexts["loginErrorMessage"]
        XCTAssertTrue(
            errorMessage.waitForExistence(timeout: UITestSession.timeout),
            "An inline error should appear on failed sign-in"
        )
        XCTAssertTrue(emailField.exists, "Login form should remain visible, not crash or silently fail")
    }

    @MainActor
    func testLaunchPerformance() throws {
        // Signed out ONCE, outside the measured block. A restored session changes what launch
        // DOES — the tab bar and its first Firestore reads instead of the login form — so a run
        // that inherited one would be timing a different app than the run before it, and the
        // metric would drift for a reason that has nothing to do with launch. The block itself
        // stays a bare launch, because that is the thing being measured.
        _ = UITestSession.launchSignedOut()

        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}

//
//  LandscapeLoginUITests.swift
//  ADHD LifeOSUITests
//
//  F-LandscapeFix's journey. The app declares landscape support on iPhone (the Xcode template
//  default, kept by E's explicit 2026-08-31 call: both orientations stay), and F-PortraitArrival
//  proved the login screen could not deliver it: ten tests, one line, one message —
//  "loginPasswordField" never became hittable — every time a test arrived in landscape.
//
//  This test is that arrival made deliberate. It reaches the login form in a known portrait
//  state, rotates, and then runs the SAME shared sign-in flow every journey uses, so on an
//  unfixed tree it fails at exactly the line the ten failures died on. It asserts the window is
//  genuinely wider than tall before signing in — without that, a rotation that silently failed
//  would make this a portrait sign-in test wearing a landscape name.
//

import XCTest

final class LandscapeLoginUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// A user holding the phone sideways can sign in: every field reachable, the primary button
    /// tappable, and the signed-in shell reached — not merely "the form renders".
    @MainActor
    func testSignIn_completesInLandscape() throws {
        try UITestEmulator.skipUnlessRunning()
        let account = try UITestSession.createAccount(label: "landscape")

        // Arrive in portrait like any journey, THEN rotate: the behaviour under test is the
        // landscape form, not whatever state the previous test left the device in.
        let app = UITestSession.launchSignedOut()

        // Orientation outlives the app process and the whole run (F-PortraitArrival). Registered
        // before the rotation so it runs even if anything below throws.
        addTeardownBlock { @MainActor in
            UITestSession.resetToPortrait()
        }

        let emailField = app.textFields["loginEmailField"]
        XCTAssertTrue(
            emailField.waitForExistence(timeout: UITestSession.timeout),
            "The login form never appeared, so there is nothing to rotate"
        )

        // The anti-vacuity guard: prove the WINDOW went landscape, don't trust the setter.
        // `rotateToLandscape` retries the set — a single one can be swallowed exactly like a
        // single tap, and was, on this test's second-ever run.
        let window = app.windows.firstMatch
        XCTAssertTrue(
            UITestSession.rotateToLandscape(app),
            "The window never went landscape — a portrait sign-in here would prove nothing"
        )

        // Frames traced on the PASS path, not only on failure, so a green run can be audited
        // for vacuity (the geometry-journey lesson).
        let passwordField = app.secureTextFields["loginPasswordField"]
        print(
            "[LANDSCAPE] window=\(window.frame)"
                + " email=\(emailField.frame)"
                + " password=\(passwordField.exists ? "\(passwordField.frame)" : "MISSING")"
        )

        try UITestSession.signIn(app, email: account.email)
    }
}

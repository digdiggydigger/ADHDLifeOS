//
//  SignedOutLaunchUITests.swift
//  ADHD LifeOSUITests
//
//  The regression guard for `UITestSession.launchSignedOut()`.
//
//  `ADHD_LifeOSUITests`' two login tests cannot be this guard themselves. They run FIRST in a
//  full run — XCTest orders classes by name and `ADHD_…` sorts ahead of every journey — so
//  within a single run nothing has signed in yet and they pass. The session that breaks them is
//  left by the PREVIOUS run, which no test in that file can arrange. This one arranges it: it
//  signs in through the harness and then asserts a relaunch still reaches the login form.
//

import XCTest

final class SignedOutLaunchUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Signs in, then relaunches and asserts the app is back at the login form.
    ///
    /// The assertion is deliberately about the login FIELD rather than about the absence of the
    /// tab bar: "signed out" is a claim about what the user can reach, and an empty tab bar with
    /// no content would satisfy the negative while failing the user.
    @MainActor
    func testRelaunchAfterSigningInStillReachesTheLoginForm() throws {
        try UITestEmulator.skipUnlessRunning()

        // Leaves a real Firebase Auth session in the simulator keychain — the exact state a
        // journey leaves behind, and the state the login tests used to inherit and fail on.
        let app = try UITestSession.launchSignedIn(label: "signedout")
        XCTAssertTrue(
            app.tabBars.firstMatch.waitForExistence(timeout: UITestSession.timeout),
            "Precondition failed: this test has to SIGN IN before it can prove sign-out works"
        )

        let relaunched = UITestSession.launchSignedOut()
        XCTAssertTrue(
            relaunched.textFields["loginEmailField"].waitForExistence(timeout: UITestSession.timeout),
            "A relaunch after signing in restored the session instead of reaching the login form."
                + " Every test that expects the login screen inherits this, and they run first."
        )
    }
}

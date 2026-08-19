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

import XCTest

final class ADHD_LifeOSUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Taps `element` and waits for the software keyboard to appear before typing.
    ///
    /// On a headless simulator, XCUITest can synthesize a tap before SwiftUI has actually
    /// granted the field keyboard focus, which surfaces as "Neither element nor any descendant
    /// has keyboard focus" from `typeText`. Waiting for `isHittable` and then for
    /// `app.keyboards` to appear confirms focus landed before we type, instead of guessing
    /// with a fixed sleep.
    @MainActor
    private func focusAndType(_ element: XCUIElement, text: String, in app: XCUIApplication) {
        XCTAssertTrue(element.waitForExistence(timeout: 10))
        let hittable = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isHittable == true"), object: element)
        XCTAssertEqual(XCTWaiter().wait(for: [hittable], timeout: 10), .completed, "\(element) never became hittable")
        element.tap()
        let keyboardAppeared = app.keyboards.element.waitForExistence(timeout: 10)
        XCTAssertTrue(keyboardAppeared, "Keyboard did not appear after tapping \(element)")
        element.typeText(text)
    }

    @MainActor
    func testLoginForm_rendersFieldsAndValidatesInput() throws {
        let app = XCUIApplication()
        app.launch()

        let emailField = app.textFields["loginEmailField"]
        let passwordField = app.secureTextFields["loginPasswordField"]
        let signInButton = app.buttons["signInButton"]

        XCTAssertTrue(emailField.waitForExistence(timeout: 15))
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

        focusAndType(emailField, text: "e@example.com", in: app)
        XCTAssertFalse(signInButton.isEnabled, "Sign In should stay disabled until a password is entered too")

        focusAndType(passwordField, text: "correct-horse", in: app)
        XCTAssertTrue(signInButton.isEnabled, "Sign In should enable once both fields are filled")
    }

    @MainActor
    func testSignIn_invalidCredentials_showsInlineErrorAndStaysOnLoginForm() throws {
        let app = XCUIApplication()
        app.launch()

        let emailField = app.textFields["loginEmailField"]
        let passwordField = app.secureTextFields["loginPasswordField"]
        let signInButton = app.buttons["signInButton"]

        XCTAssertTrue(emailField.waitForExistence(timeout: 15))

        focusAndType(emailField, text: "nonexistent-user@example.com", in: app)
        focusAndType(passwordField, text: "definitely-wrong-password", in: app)
        signInButton.tap()

        let errorMessage = app.staticTexts["loginErrorMessage"]
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 15), "An inline error should appear on failed sign-in")
        XCTAssertTrue(emailField.exists, "Login form should remain visible, not crash or silently fail")
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}

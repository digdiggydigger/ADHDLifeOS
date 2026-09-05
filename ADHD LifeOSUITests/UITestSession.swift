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
    /// One slot on the app's own tab bar.
    ///
    /// These journeys used to reach the tabs through `app.tabBars.buttons[name]`. Since
    /// F-Tools-1-Bar the bar is a SwiftUI stack rather than a `UITabBar` — the app needed a
    /// sixth station and a system `TabView` folds everything past the fifth into "More" — and
    /// XCUITest has no `tabBar` element for one, because SwiftUI exposes no `isTabBar`
    /// accessibility trait to give it. So the journeys address the identifiers
    /// `AppTabBarPresentation.accessibilityIdentifier(for:)` mints instead.
    ///
    /// `isSelected` still works: the bar adds the trait to the selected slot, which is what
    /// `openTab` waits on.
    @MainActor
    static func tabButton(_ name: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons["tabBar.\(name)"]
    }

    /// The landmark that says the signed-in shell is up, replacing `app.tabBars.firstMatch`.
    /// Today's slot exists for exactly as long as the tabs do.
    @MainActor
    static func signedInShell(_ app: XCUIApplication) -> XCUIElement {
        tabButton("Today", in: app)
    }

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
        resetToPortrait()
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
        awaitFirstRunSeeding(app, uid: account.uid)
        return app
    }

    /// A launched app sitting on the LOGIN screen, whatever the last run left in the keychain.
    ///
    /// Firebase Auth persists its session in the simulator keychain, and the keychain outlives
    /// both the app process and the whole test RUN. The two login tests in `ADHD_LifeOSUITests`
    /// only called `app.launch()`, so they inherited the account the previous run's last journey
    /// signed into, restored straight into the tab bar, and failed on a `loginEmailField` that
    /// was never going to appear. `xcrun simctl keychain booted reset` made them pass — which is
    /// what PROVED the cause, and is not a fix, because a person has to remember it every time.
    ///
    /// Two failures on every full UI run is worse than it sounds: they have to be manually
    /// discounted each time, which is exactly how a real failure eventually gets waved through.
    ///
    /// **The emulator host is set only when the emulator is actually answering.** A session in
    /// the keychain can only have come from a journey, and journeys only ever run against the
    /// emulator — so pointing at it here signs out of the same backend that signed in. With no
    /// emulator there is nothing to point at, and `ADHD_LifeOSUITests`' promise in its own header
    /// holds: those tests still need zero local setup on a fresh clone.
    @MainActor
    static func launchSignedOut(resettingOrientation: Bool = true) -> XCUIApplication {
        if resettingOrientation { resetToPortrait() }
        let app = XCUIApplication()
        if UITestEmulator.isRunning {
            app.launchEnvironment[emulatorHostKey] = UITestEmulator.host
        }
        app.launch()
        // Before anything queries the app's own UI: a SpringBoard alert renders above it, so a
        // prompt left standing makes every query miss. Same reason as `launchSignedIn`.
        dismissSystemAlertIfPresent()
        signOutIfSignedIn(app)
        return app
    }

    /// Waits for first-run seeding to actually land, and retries it the way the APP does.
    ///
    /// `seedDefaultContentIfNeeded()` is called best-effort (`try?`) on sign-in, sign-up and
    /// session restore. That is deliberate and documented: a seeding failure must not fail the
    /// sign-up, and it retries on the next entry until the `seeded_at` marker lands. The cost of
    /// that trade is that a failed seed leaves the session with an EMPTY account, and under a
    /// loaded emulator it does intermittently fail.
    ///
    /// It cost two journey failures on 2026-08-29 with two different messages — "No life-area
    /// chips" and "The decision card rendered a wordless capture as a blank" — which read like
    /// unrelated UI bugs and were the same missing seed. Note neither is a TAP problem, so
    /// `tap(_:untilExists:)` cannot help: this is a different race and wants a different fix.
    ///
    /// So: observe the DATA, not a screen, and if it never arrives relaunch — which re-enters
    /// `restoredUser()` and seeds again, i.e. exactly the retry the app promises. Nothing here
    /// papers over a product bug; it reproduces the product's own contract.
    @MainActor
    static func awaitFirstRunSeeding(_ app: XCUIApplication, uid: String, attempts: Int = 2) {
        let areas = "users/\(uid)/life_areas"
        for attempt in 1...attempts {
            if pollForDocuments(in: areas) { return }
            guard attempt < attempts else { break }
            // The app's own retry path: a relaunch restores the session and seeds again.
            app.terminate()
            app.launch()
            dismissSystemAlertIfPresent()
        }
        XCTFail(
            "First-run seeding never landed for \(uid) after \(attempts) app launches."
                + " Every journey depends on the seeded life areas, so this would surface further"
                + " down as a missing chip or an empty inbox rather than as what it is."
        )
    }

    private static func pollForDocuments(in path: String, seconds: TimeInterval = 20) -> Bool {
        let deadline = Date().addingTimeInterval(seconds)
        while Date() < deadline {
            if UITestEmulator.collectionHasDocuments(path: path) { return true }
            Thread.sleep(forTimeInterval: 0.5)
        }
        return false
    }

    /// Firebase Auth persists its session in the keychain, and the keychain outlives the app
    /// process — so a test launching after one that signed in would inherit that account and
    /// never see the login screen at all. Signing out through the real UI resets it without
    /// adding a test-only hook to production code, and exercises the sign-out path for free.
    @MainActor
    private static func signOutIfSignedIn(_ app: XCUIApplication) {
        let loginField = app.textFields["loginEmailField"]
        let tabBar = signedInShell(app)

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
        // Retried, not tapped once. See `tap(_:untilExists:)` — this exact call is the one whose
        // swallowed taps produced four false failures in a single day.
        XCTAssertTrue(
            tap(settingsButton, untilExists: app.buttons["settingsDoneButton"]),
            "Settings did not open after \(3) attempts, so sign-out could never be reached"
        )

        // Wait for the sheet itself before hunting inside it. The scroll loop below used to start
        // after a 2s grace, so a Settings sheet that was still presenting swallowed all eight
        // swipes — which then scrolled TODAY instead, left it somewhere unexpected, and reported
        // "did not present a sign-out control" for a screen that simply had not opened yet. It
        // failed once the suite grew to five journeys and the simulator got slower under them.
        // `settingsDoneButton` is in the nav bar, so it is present without any scrolling at all —
        // which is why it is the thing the retry above waits on. The assertion that used to stand
        // here is gone rather than kept as a second copy: `tap(_:untilExists:)` has already
        // established it, and a duplicate would only report the same fact twice.

        let signOut = app.buttons["signOutButton"]
        // SwiftUI materialises Form rows lazily, so a row below the fold does not EXIST to
        // XCUITest until it scrolls into view — and the Momentum blocks keep adding rows above
        // this one (M2, M7, M9 each moved the fold; M9 was the one that finally pushed sign-out
        // under it and failed three journeys). Hunt for the row the way a user would instead of
        // asserting on where the fold happens to fall this release.
        _ = signOut.waitForExistence(timeout: 2)
        // Settles between swipes; a tight loop does not scroll at all.
        scrollUntilHittable(signOut, in: app, attempts: 8)
        XCTAssertTrue(signOut.exists, "Settings opened but presented no sign-out control")
        signOut.tap()
        XCTAssertTrue(
            loginField.waitForExistence(timeout: timeout),
            "Signing out did not return the app to the login screen"
        )
    }

    /// Internal rather than private since F-LandscapeFix: `LandscapeLoginUITests` runs this exact
    /// flow after rotating, so a landscape regression fails at the same line the ten
    /// F-PortraitArrival failures died on, not in a lookalike copy.
    @MainActor
    static func signIn(_ app: XCUIApplication, email: String) throws {
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
            signedInShell(app).waitForExistence(timeout: timeout),
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

    /// Taps `element` until `expected` shows up, rather than once and hoping.
    ///
    /// **This is the single biggest source of false failures in this suite**, and it is not a
    /// feature, which is exactly why it went unfixed for so long. A tap synthesised while a screen
    /// is still settling is a silent no-op — XCUITest reports it as delivered — so the run carries
    /// on and dies at the NEXT assertion with a true statement about the wrong step. Four false
    /// journey failures in one day (2026-08-28) all read "Settings did not open"; every one passed
    /// in isolation, and none of them were about Settings.
    ///
    /// Waiting for the element before tapping is necessary and was already done — it is not
    /// sufficient, because existing is not the same as being ready to receive a hit.
    ///
    /// Returns whether `expected` ever appeared, so callers can assert with their own message.
    @MainActor
    @discardableResult
    static func tap(
        _ element: XCUIElement,
        untilExists expected: XCUIElement,
        attempts: Int = 3
    ) -> Bool {
        guard element.waitForExistence(timeout: timeout) else { return false }
        let perAttempt = max(2.0, timeout / Double(attempts))
        for attempt in 1...attempts {
            if expected.exists { return true }
            element.tap()
            if expected.waitForExistence(timeout: perAttempt) { return true }
            // Re-check the tap target: a swallowed tap can also mean the screen moved under us.
            if attempt < attempts, !element.exists { return expected.waitForExistence(timeout: perAttempt) }
        }
        return expected.exists
    }

    /// Taps `element` until `doomed` goes away — the mirror of `tap(_:untilExists:)`.
    ///
    /// Same swallowed-tap problem, from the other side. An alert's Save is the case that forced
    /// this: the tap was reported as delivered, the alert stayed up with the typed name still in
    /// it, and the journey failed several steps later claiming a row had not appeared. A
    /// screenshot was the only thing that said otherwise.
    @MainActor
    @discardableResult
    static func tap(_ element: XCUIElement, untilGone doomed: XCUIElement, attempts: Int = 3) -> Bool {
        for _ in 1...attempts {
            if !doomed.exists { return true }
            guard element.exists else { return !doomed.exists }
            element.tap()
            let gone = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "exists == false"), object: doomed
            )
            if XCTWaiter().wait(for: [gone], timeout: max(2.0, timeout / Double(attempts))) == .completed {
                return true
            }
        }
        return !doomed.exists
    }

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
        // Retried on FOCUS, not on the keyboard existing — and that distinction is the whole point.
        //
        // A swallowed tap here leaves the field unfocused, which surfaces as "Keyboard did not
        // appear" (first field) or "Neither element nor any descendant has keyboard focus"
        // (second field). Reaching for `tap(_:untilExists: app.keyboards.element)` looked right and
        // was wrong: it short-circuits when the expected element ALREADY exists, and on the
        // password field the keyboard is still up from the email field — so it never tapped at
        // all, and typing went nowhere. That regression is why this asks the field itself.
        //
        // `hasKeyboardFocus` is KVC-only, so it is read defensively: where it cannot be read the
        // keyboard's presence is the fallback, which is exactly the old behaviour.
        func isFocused() -> Bool {
            if let focused = element.value(forKey: "hasKeyboardFocus") as? Bool { return focused }
            return app.keyboards.element.exists
        }
        for _ in 1...3 {
            element.tap()
            let deadline = Date().addingTimeInterval(3)
            while Date() < deadline, !isFocused() { Thread.sleep(forTimeInterval: 0.2) }
            if isFocused() { break }
        }
        XCTAssertTrue(isFocused(), "\(element) never took keyboard focus")
        element.typeText(text)
    }

    /// Mirrors `FirebaseEmulatorSettings.hostKey`. Spelled out rather than imported because the
    /// UI test target does not link the app — it drives it as a black box.
    private static let emulatorHostKey = "LIFEOS_FIREBASE_EMULATOR_HOST"
}

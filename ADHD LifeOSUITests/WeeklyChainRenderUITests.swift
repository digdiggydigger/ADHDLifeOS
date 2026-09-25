//
//  WeeklyChainRenderUITests.swift
//  ADHD LifeOSUITests
//
//  `F-E1-WeeklyChain`'s evidence harness — the frames for `screenshots/weekly-chain-goals-off/`.
//
//  E's round 3: *"Preset goals → 'Off until you set one.' No ring and no percentage until the user
//  chooses a goal in Settings."* Round 8b: *"'Close it — makes today count'"* while today has no
//  activity yet. Unit tests prove the model; only the real screens show a fresh account meeting
//  it: Today's count with no ring, the gain line on a task's close, both goal rows off with their
//  Steppers hidden, and the ring arriving the moment a goal is set.
//
//  Run deliberately, one appearance per run: set the simulator's appearance with `xcrun simctl ui`
//  and name the frames with `CHAIN_RENDER_TAG` (L / D), passed as `TEST_RUNNER_CHAIN_RENDER_TAG`.
//  The goal it turns on is turned off again before the run ends: the preference is DEVICE-wide.
//

import XCTest

final class WeeklyChainRenderUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testRenderGoalsOffAndTheGainLine() throws {
        try UITestEmulator.skipUnlessRunning()
        let tag = ProcessInfo.processInfo.environment["CHAIN_RENDER_TAG"] ?? "X"
        let app = try UITestSession.launchSignedIn(label: "e1chain")
        XCTAssertTrue(
            app.buttons["quickCaptureButton"].waitForExistence(timeout: UITestSession.timeout),
            "The signed-in tabs never appeared"
        )

        // 1 — Today on a fresh account: a count, no ring, no "of N".
        UITestSession.openTab("Today", in: app)
        let card = app.descendants(matching: .any).matching(identifier: "homeMomentumRing").firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: UITestSession.timeout), "Today drew no scoreboard")
        XCTAssertTrue(card.label.contains("closed today"), "No-goal count reads \"\(card.label)\"")
        XCTAssertFalse(card.label.contains(" of "), "A ring's \"of N\" was drawn with no goal set")
        print("MEASURE chain-\(tag) card=\(card.frame) label=\(card.label)")
        attach(app, named: "01-today-no-goal-\(tag)")

        // 2 — the gain line on a task's close: nothing has counted today on a fresh account.
        UITestSession.openTab("Tasks", in: app)
        // The ON-SCREEN copy: Today's hero shows the same seeded task, and the hidden Today tab is
        // parked ~10,000pt away but still in the hierarchy, so `firstMatch` picked that copy.
        let seeded = try XCTUnwrap(
            onScreen(app.staticTexts.matching(NSPredicate(format: "label == %@", "Take a 10-minute walk"))),
            "The seeded task is not on the Tasks board"
        )
        // Anchored on a DETAIL-only element. Today's hero also carries a "Close it" button, and a
        // hidden tab stays in the hierarchy (parked off screen), so waiting on any "Close it" was
        // satisfied before the row was ever tapped — the first run photographed the Tasks list.
        let titleField = app.descendants(matching: .any).matching(identifier: "taskDetailTitleField").firstMatch
        XCTAssertTrue(UITestSession.tap(seeded, untilExists: titleField), "Task detail never opened")
        let gain = app.buttons["Close it — makes today count"].firstMatch
        XCTAssertTrue(gain.waitForExistence(timeout: UITestSession.timeout), "Task detail shows no gain line")
        print("MEASURE chain-\(tag) close=\(gain.frame)")
        attach(app, named: "02-task-detail-gain-line-\(tag)")
        app.navigationBars.buttons.firstMatch.tap()

        renderSettings(app, tag: tag)

        // 5 — Today again: the ring arrives around the same number, with its "of 5".
        UITestSession.openTab("Today", in: app)
        let ringed = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label CONTAINS %@", "of 5 closed"), object: card
        )
        XCTAssertEqual(
            XCTWaiter().wait(for: [ringed], timeout: UITestSession.timeout), .completed,
            "The ring never drew its goal (card reads \"\(card.label)\")"
        )
        attach(app, named: "05-today-goal-set-\(tag)")

        turnTheGoalBackOff(app)
    }

    // MARK: - Steps

    /// Frames 3–4: both goals off with their Steppers hidden, the chain's Stepper at 3, and the
    /// daily goal's Stepper appearing when it is turned on.
    @MainActor
    private func renderSettings(_ app: XCUIApplication, tag: String) {
        // 3 — Settings: both goals off, their Steppers hidden; the chain's Stepper at 3 days.
        let done = openSettings(app)
        let goalToggle = app.switches["settingsMomentumGoalToggle"].firstMatch
        UITestSession.scrollUntilHittable(goalToggle, in: app)
        XCTAssertEqual(goalToggle.value as? String, "0", "The daily goal should start OFF")
        XCTAssertFalse(app.steppers["settingsMomentumGoalStepper"].exists, "A Stepper was drawn with no goal")
        let chain = app.steppers["settingsMomentumChainStepper"].firstMatch
        XCTAssertTrue(chain.exists, "The weekly chain's Stepper is missing")
        print("MEASURE chain-\(tag) goalToggle=\(goalToggle.frame) chain=\(chain.frame) \(chain.label)")
        attach(app, named: "03-settings-goals-off-\(tag)")

        // 4 — turned on: the Stepper appears at the old seed.
        let goalStepper = app.steppers["settingsMomentumGoalStepper"].firstMatch
        XCTAssertTrue(flip(goalToggle, until: goalStepper, exists: true), "Turning the goal on showed no Stepper")
        print("MEASURE chain-\(tag) goalStepper=\(goalStepper.frame) \(goalStepper.label)")
        attach(app, named: "04-settings-goal-on-\(tag)")

        let focusToggle = app.switches["settingsFocusGoalToggle"].firstMatch
        UITestSession.scrollUntilHittable(focusToggle, in: app)
        XCTAssertEqual(focusToggle.value as? String, "0", "The focus goal should start OFF")
        // No frame of its own: at the default size frame 04 already shows the Focus section.
        XCTAssertFalse(app.steppers["settingsFocusGoalStepper"].exists)
        done.tap()
    }

    /// The goal preference is DEVICE-wide, so the run leaves it the way it found it.
    @MainActor
    private func turnTheGoalBackOff(_ app: XCUIApplication) {
        let doneAgain = openSettings(app)
        let toggleAgain = app.switches["settingsMomentumGoalToggle"].firstMatch
        UITestSession.scrollUntilHittable(toggleAgain, in: app)
        let stepper = app.steppers["settingsMomentumGoalStepper"].firstMatch
        XCTAssertTrue(flip(toggleAgain, until: stepper, exists: false), "Could not turn the goal back off")
        doneAgain.tap()
    }

    // MARK: - Plumbing

    /// The first match drawn inside the screen, not on a tab parked off it (`AppTabContent`).
    @MainActor
    private func onScreen(_ query: XCUIElementQuery) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(UITestSession.timeout)
        while Date() < deadline {
            let screen = XCUIApplication().frame
            if let hit = query.allElementsBoundByIndex.first(where: { screen.intersects($0.frame) }) { return hit }
            Thread.sleep(forTimeInterval: 0.5)
        }
        return nil
    }

    /// Taps the SWITCH end of a Form toggle row until `target` reaches `exists`. The row's centre
    /// is its label, which on iOS 26+ does not always flip the switch, so the tap goes to the
    /// trailing edge where the switch is drawn.
    @MainActor
    private func flip(_ toggle: XCUIElement, until target: XCUIElement, exists: Bool) -> Bool {
        for _ in 1...3 {
            if target.exists == exists { return true }
            toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
            let settled = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "exists == %@", NSNumber(value: exists)), object: target
            )
            if XCTWaiter().wait(for: [settled], timeout: 4) == .completed { return true }
        }
        return target.exists == exists
    }

    @MainActor
    private func openSettings(_ app: XCUIApplication) -> XCUIElement {
        UITestSession.openTab("Today", in: app)
        let gear = app.buttons["settingsButton"].firstMatch
        let done = app.buttons["settingsDoneButton"].firstMatch
        XCTAssertTrue(UITestSession.tap(gear, untilExists: done), "Settings never opened from Today's gear")
        return done
    }

    @MainActor
    private func attach(_ app: XCUIApplication, named name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}

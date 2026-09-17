//
//  LandscapeAwayCardUITests.swift
//  ADHD LifeOSUITests
//
//  F-LandscapeFabOverlap's journey — the regression camera for the bug E found on the phone on
//  2026-09-16: in LANDSCAPE, with an unacknowledged "Sprint finished while you were away" card up,
//  the capture disc rendered on top of the Settings gear and the gear could not be tapped
//  (`screenshots/ios27-device-findings/04-fab-overlap-landscape.jpeg`).
//
//  The trigger is the COMBINATION — landscape plus the away card; neither alone did it — so the
//  journey holds both and asserts the one thing E could not do: tap the gear. Portrait is
//  asserted first as the CONTROL, so a frame assertion that could never tell the two states apart
//  cannot pass by accident (the geometry-journey lesson: a frame check once passed on the broken
//  build). Frames are printed on the pass path for the same reason.
//
//  The away card is raised the way the APP raises it — from the UserDefaults key
//  `restorePersistedSprint()` reads at launch — seeded through the argument domain. See
//  `UITestUserDefaultsSeeds.swift`.
//

import XCTest

final class LandscapeAwayCardUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Landscape, away card up: the Settings gear is clear of the capture disc and can be tapped —
    /// it opens Settings. And the invariant the fix must not break: the card never covers the
    /// disc, because "an active sprint PUSHES the disc up" is the reason `RootBottomOverlay`'s
    /// stack exists at all.
    @MainActor
    func testTheGearStaysReachableInLandscapeWithTheAwayCardUp() throws {
        try UITestEmulator.skipUnlessRunning()
        let account = try UITestSession.createAccount(label: "landscapeaway")
        let app = try UITestSession.launchSignedIn(
            as: account,
            launchArguments: UITestSession.unacknowledgedCompletionLaunchArguments(
                taskTitle: "celebration sound testing"
            )
        )
        // Orientation outlives the app process and the whole run (F-PortraitArrival). Registered
        // before the rotation so it runs even if anything below throws.
        addTeardownBlock { @MainActor in
            UITestSession.resetToPortrait()
        }

        let card = app.descendants(matching: .any)["offlineSprintSummaryCard"]
        let disc = app.buttons["quickCaptureButton"]
        let gear = app.buttons["settingsButton"]
        XCTAssertTrue(
            card.waitForExistence(timeout: UITestSession.timeout),
            "The away card never appeared, so the premise of the bug is missing and nothing below"
                + " would mean anything. Check the seed against `CompletedFocusSession.CodingKeys`."
        )
        XCTAssertTrue(gear.waitForExistence(timeout: UITestSession.timeout), "No Settings gear on Today")
        XCTAssertTrue(disc.waitForExistence(timeout: UITestSession.timeout), "No capture disc")
        // iOS's own two prompts are due about now — the notification alert and the AutoFill
        // "Save Password?" sheet, which trails sign-in by a schedule of its own (the sweep's
        // first frame caught it; so did this journey's second run, on a loaded simulator). A
        // sheet standing over the header makes the gear un-hittable for a reason that has
        // nothing to do with the layout, so sweep with a real wait before the control.
        sweepSystemPrompts(app, wait: 5)
        settle()
        attach(app, "00-portrait-away-card")

        assertPortraitControl(app, disc: disc, gear: gear, card: card)

        // The anti-vacuity guard: prove the WINDOW went landscape, don't trust the setter.
        XCTAssertTrue(
            UITestSession.rotateToLandscape(app),
            "The window never went landscape — a portrait check here would prove nothing"
        )
        settle()
        attach(app, "01-landscape-away-card")
        hold()
        print("[LANDSCAPE-AWAY] landscape window=\(app.windows.firstMatch.frame)"
            + " disc=\(disc.frame) gear=\(gear.frame) card=\(card.frame)")
        XCTAssertTrue(card.exists, "The away card left the screen on rotation — the premise is gone")

        // The bug, as E met it.
        XCTAssertFalse(
            disc.frame.intersects(gear.frame),
            "Landscape: the capture disc sits on the Settings gear — the bug E photographed"
        )
        XCTAssertTrue(waitUntilHittable(gear, in: app), "Landscape: the Settings gear cannot be tapped")
        // The invariant the fix must not break: the card never covers the disc.
        XCTAssertFalse(disc.frame.intersects(card.frame), "Landscape: the away card covers the disc")

        // Not merely hittable — the user's action: the gear opens Settings.
        let done = app.buttons["settingsDoneButton"]
        XCTAssertTrue(UITestSession.tap(gear, untilExists: done), "Landscape: tapping the gear did not open Settings")
        settle()
        attach(app, "02-landscape-settings-open")
        hold()
        XCTAssertTrue(UITestSession.tap(done, untilGone: done), "Done did not close Settings")
    }

    // MARK: - The control

    /// Portrait is the state E uses daily and it has never collided; if this fails, the landscape
    /// assertions cannot tell landscape from portrait and prove nothing.
    @MainActor
    private func assertPortraitControl(
        _ app: XCUIApplication, disc: XCUIElement, gear: XCUIElement, card: XCUIElement
    ) {
        print("[LANDSCAPE-AWAY] portrait window=\(app.windows.firstMatch.frame)"
            + " disc=\(disc.frame) gear=\(gear.frame) card=\(card.frame)")
        XCTAssertFalse(disc.frame.intersects(gear.frame), "Portrait: the disc overlaps the gear — the control failed")
        XCTAssertTrue(
            waitUntilHittable(gear, in: app),
            "Portrait: the gear is not hittable — the control failed"
        )
    }

    // MARK: - Hittability

    /// `isHittable` read once is a race against whatever iOS is animating at that instant. This
    /// polls for a few seconds, sweeping the AutoFill sheet each time, and on a miss attaches the
    /// app's hierarchy so the failure says what was standing over the point.
    @MainActor
    private func waitUntilHittable(_ element: XCUIElement, in app: XCUIApplication, seconds: TimeInterval = 5) -> Bool {
        let deadline = Date().addingTimeInterval(seconds)
        repeat {
            UITestSession.dismissSystemPasswordPromptIfPresent()
            if element.isHittable { return true }
            Thread.sleep(forTimeInterval: 0.5)
        } while Date() < deadline
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "hierarchy-when-\(element.identifier)-was-not-hittable"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        return false
    }

    // MARK: - Capture

    /// A beat for springs to land before the frame is taken (`RenderHarnessUITests` records why).
    private func settle() {
        Thread.sleep(forTimeInterval: 1.0)
    }

    /// **`app.screenshot()` lies on a rotated simulator** (F-LandscapeFix): the attachment comes
    /// back letterboxed portrait with the content squeezed into a column. The ground-truth frame
    /// is `xcrun simctl io <udid> screenshot`, taken from OUTSIDE the test while it holds the
    /// pose — this is the pose being held. The attachment is still taken, as the record that the
    /// pose was reached.
    private func hold() {
        Thread.sleep(forTimeInterval: 3.0)
    }

    /// The sweep harness's prompt sweep: the SpringBoard alert, then the in-app password sheet.
    @MainActor
    private func sweepSystemPrompts(_ app: XCUIApplication, wait: TimeInterval) {
        UITestSession.dismissSystemAlertIfPresent(timeout: wait)
        let passwordSheet = app.sheets.matching(NSPredicate(format: "label CONTAINS[c] 'password'")).firstMatch
        _ = passwordSheet.waitForExistence(timeout: wait)
        UITestSession.dismissSystemPasswordPromptIfPresent()
    }

    @MainActor
    private func attach(_ app: XCUIApplication, _ name: String) {
        sweepSystemPrompts(app, wait: 0.5)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}

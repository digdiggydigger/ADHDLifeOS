//
//  FirstRunJourneyUITests.swift
//  ADHD LifeOSUITests
//
//  What a BRAND-NEW account can reach. Every other journey seeds the thing it is about before
//  launching, which is right for those journeys and is exactly why this gap survived: a fresh
//  account is the one state nothing was testing.
//

import XCTest

final class FirstRunJourneyUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// A new account must be able to create its first nudge.
    ///
    /// It could not. `loadedNudgesSection` was gated on `!due.isEmpty || scheduled > 0`, so with
    /// no nudges the whole section — door included — did not render; first-run seeding creates
    /// life areas, tags, tasks and a journal entry but never a nudge; and the only route to the
    /// Nudges screen is through that door. So the feature was unreachable until a nudge already
    /// existed, which nothing could produce.
    ///
    /// The empty-state copy for this exact screen already existed and was already unit-tested —
    /// `doorSubtitle(0, 0)`, `chipText(0, 0)`, `countLine(0, 0)` — and the gate made every line of
    /// it unreachable. Found when `RenderHarnessUITests` failed on a fresh account with "Today
    /// never rendered the nudges door", which was true.
    ///
    /// **Seeds nothing on purpose.** The moment this test arranges a nudge it stops testing the
    /// thing it exists for.
    @MainActor
    func testNewAccount_canReachTheNudgesScreenWithNoNudges() throws {
        try UITestEmulator.skipUnlessRunning()

        let app = try UITestSession.launchSignedIn(label: "firstrun")
        XCTAssertTrue(
            app.buttons["quickCaptureButton"].waitForExistence(timeout: UITestSession.timeout),
            "The signed-in tabs never appeared"
        )

        // Today is a LazyVStack: a row below the fold does not exist until it is scrolled into
        // being, so hunt for the door rather than asserting on where the fold happens to fall.
        let door = app.buttons["homeManageNudgesRow"]
        var remaining = 10
        while !door.exists, remaining > 0 {
            app.swipeUp()
            remaining -= 1
        }
        XCTAssertTrue(
            door.exists,
            "A brand-new account cannot see the nudges door, so it can never create a first nudge."
                + " The section is gated on already having one, and nothing else routes there."
        )

        remaining = 6
        while !door.isHittable, remaining > 0 {
            app.swipeUp()
            remaining -= 1
        }
        XCTAssertTrue(
            UITestSession.tap(door, untilExists: app.buttons["nudgeAddButton"]),
            "The nudges door did not open the Nudges screen"
        )

        // And the sheet behind it actually opens, because reaching a dead screen is no better.
        XCTAssertTrue(
            UITestSession.tap(app.buttons["nudgeAddButton"], untilExists: app.textFields["nudgeAddLabelField"]),
            "The New nudge sheet never opened, so a first nudge still cannot be created"
        )
    }
}

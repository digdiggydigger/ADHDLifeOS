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
    /// thing it exists for. (Since `F-E3-OneCardToday` the door is the Tools page's Nudges row.)
    @MainActor
    func testNewAccount_canReachTheNudgesScreenWithNoNudges() throws {
        try UITestEmulator.skipUnlessRunning()

        let app = try UITestSession.launchSignedIn(label: "firstrun")
        XCTAssertTrue(
            app.buttons["quickCaptureButton"].waitForExistence(timeout: UITestSession.timeout),
            "The signed-in tabs never appeared"
        )

        // **Reversed by `F-E3-OneCardToday`:** the door was Today's nudges card, which round 3's one
        // card removed; E moved it to Tools, beside Routines (2026-09-24). The guarantee is the
        // same one — a brand-new account, with nothing seeded, reaches the Nudges screen — and the
        // Tools row is drawn in every state, so there is no first-run gate left to get wrong.
        XCTAssertTrue(
            UITestSession.openNudgesFromTools(in: app),
            "A brand-new account cannot open the Nudges screen from Tools, so it can never create a"
                + " first nudge."
        )

        // And the sheet behind it actually opens, because reaching a dead screen is no better.
        XCTAssertTrue(
            UITestSession.tap(app.buttons["nudgeAddButton"], untilExists: app.textFields["nudgeAddLabelField"]),
            "The New nudge sheet never opened, so a first nudge still cannot be created"
        )
    }
}

//
//  CaptureDiscClearanceUITests.swift
//  ADHD LifeOSUITests
//
//  The capture disc's clearance, asserted as GEOMETRY. Its own class rather than another method
//  on `SignedInJourneyUITests` (already at its length ceiling), and a sibling of
//  `JournalJourneyUITests` in kind: both measure frames, because both guard defects that are
//  invisible to a test over pure types — the element is on screen the whole time, in the wrong
//  place or under something.
//

import XCTest

final class CaptureDiscClearanceUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        try UITestEmulator.skipUnlessRunning()
    }

    /// **The nudges screen's last row is reachable, not parked under the capture disc.**
    ///
    /// E's report, 2026-08-29. `NudgesView` ends in `nudgesNewNudgeRow` — a full-width 54pt
    /// button, the only way to create a nudge — and the disc is a fixed overlay ~86pt above the
    /// screen's bottom edge. With nothing below the row to scroll to, the row's trailing half sat
    /// under an opaque 60pt circle permanently.
    ///
    /// `CaptureDiscMetrics.clearance` has existed since 2026-08-25 and says in its own doc comment
    /// that ANY bottom-of-scroll content lands underneath the disc. Two screens called it. This is
    /// [[dead-shared-component-pattern]] for the fourth time, so the assertion is on the geometry
    /// rather than on the call.
    @MainActor
    func testNudges_theNewNudgeRowIsNotUnderTheCaptureDisc() throws {
        let app = try UITestSession.launchSignedIn(label: "discnudges")
        openNudges(in: app)

        let newNudge = app.buttons["nudgesNewNudgeRow"]
        XCTAssertTrue(
            newNudge.waitForExistence(timeout: UITestSession.timeout),
            "The nudges screen never rendered its New nudge row"
        )
        scrollToRest(newNudge, in: app)
        assertClearOfCaptureDisc(newNudge, "The nudges screen's New nudge row", in: app)
    }

    /// **Today's last card is reachable too** — the same defect on a tab root rather than a pushed
    /// screen, which is the other half of the class. Both live inside the `TabView` the disc
    /// overlays, so a fix that reached only one of them would not be a fix.
    @MainActor
    func testToday_theLastCardIsNotUnderTheCaptureDisc() throws {
        let app = try UITestSession.launchSignedIn(label: "disctoday")

        let weekReview = app.buttons["homeWeekReviewRow"]
        XCTAssertTrue(
            weekReview.waitForExistence(timeout: UITestSession.timeout),
            "Today never rendered its week-review row"
        )
        scrollToRest(weekReview, in: app)
        assertClearOfCaptureDisc(weekReview, "Today's week-review row", in: app)
    }

    // MARK: - Helpers

    /// Pushes the nudges screen through Today's door, retried — a tap taken while Today is still
    /// settling is a silent no-op (`UITestSession.tap(_:untilExists:)`'s whole reason to exist).
    @MainActor
    private func openNudges(in app: XCUIApplication) {
        let door = app.buttons["homeManageNudgesRow"]
        XCTAssertTrue(
            door.waitForExistence(timeout: UITestSession.timeout),
            "Today never rendered the nudges door"
        )
        // The door is below the fold on Today; existing is not reachable.
        var remaining = 8
        while !door.isHittable, remaining > 0 {
            app.swipeUp()
            remaining -= 1
        }
        XCTAssertTrue(
            UITestSession.tap(door, untilExists: app.buttons["nudgesNewNudgeRow"]),
            "The nudges door never opened the nudges screen"
        )
    }

    /// Swipes up until `element` stops moving, so it is measured where the scroll actually leaves
    /// it rather than mid-flight. A bounce settles back to the same frame, which is the signal.
    @MainActor
    private func scrollToRest(_ element: XCUIElement, in app: XCUIApplication, attempts: Int = 10) {
        var previous = CGRect.null
        for _ in 1...attempts {
            guard element.exists else { return }
            let frame = element.frame
            if frame.equalTo(previous) { return }
            previous = frame
            app.swipeUp()
            Thread.sleep(forTimeInterval: 0.4)
        }
    }

    /// The assertion itself: the element's frame and the disc's frame do not intersect.
    ///
    /// Deliberately the disc's own frame rather than `CaptureDiscMetrics.clearance` — the UI test
    /// target does not link the app, and a constant copied over here would agree with a wrong
    /// implementation. What is being claimed is about pixels on a screen, so it is measured there.
    @MainActor
    private func assertClearOfCaptureDisc(
        _ element: XCUIElement, _ what: String, in app: XCUIApplication
    ) {
        let disc = app.buttons["quickCaptureButton"]
        XCTAssertTrue(
            disc.waitForExistence(timeout: UITestSession.timeout),
            "The capture disc is not on screen, so this journey proved nothing"
        )
        XCTAssertFalse(
            element.frame.intersects(disc.frame),
            "\(what) at \(element.frame) is underneath the capture disc at \(disc.frame)"
        )
    }
}

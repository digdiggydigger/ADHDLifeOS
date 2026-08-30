//
//  RenderHarnessUITests.swift
//  ADHD LifeOSUITests
//
//  TEMPORARY — a render harness, not a test. It asserts almost nothing; it drives the app to one
//  screen and attaches screenshots so E can look at a change before it reaches the device. The
//  standing lesson is that three journal-pad colour attempts were rejected on device before a
//  render loop existed (F-PadNightRender).
//
//  Delete this file before the block commits, or commit it deliberately — do not leave it behind.
//

import XCTest

final class RenderHarnessUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Opens the rebuilt New nudge sheet and photographs it in whatever appearance the simulator
    /// is currently set to (`xcrun simctl ui booted appearance light|dark`).
    @MainActor
    func testRenderNewNudgeSheet() throws {
        try UITestEmulator.skipUnlessRunning()

        // Seed a nudge BEFORE launching. First-run seeding creates life areas, tags, tasks and a
        // journal entry but never a nudge, and `loadedNudgesSection` is gated on
        // `!due.isEmpty || scheduled > 0` — so on a fresh account the whole nudges section,
        // door included, does not render at all. The first run of this harness failed on exactly
        // that, and said so accurately: "Today never rendered the nudges door".
        let account = try UITestSession.createAccount(label: "render")
        try seedScheduledNudge(id: UUID(), label: "Drink water", uid: account.uid)
        let app = try UITestSession.launchSignedIn(as: account)

        // Today → the nudges door, using the navigation `CaptureDiscClearanceUITests` proved out:
        // Today is a LazyVStack, so a row below the fold does not merely fail to be hittable, it
        // does not EXIST — scroll it into being, then into reach, and use the header's add button
        // as the arrival landmark rather than anything below the fold.
        XCTAssertTrue(
            app.buttons["quickCaptureButton"].waitForExistence(timeout: UITestSession.timeout),
            "The signed-in tabs never appeared"
        )
        let door = app.buttons["homeManageNudgesRow"]
        var scrolls = 10
        while !door.exists, scrolls > 0 {
            app.swipeUp()
            scrolls -= 1
        }
        XCTAssertTrue(door.exists, "Today never rendered the nudges door, even scrolled to the end")
        scrolls = 6
        while !door.isHittable, scrolls > 0 {
            app.swipeUp()
            scrolls -= 1
        }
        XCTAssertTrue(
            UITestSession.tap(door, untilExists: app.buttons["nudgeAddButton"]),
            "The nudges screen never opened"
        )

        // The header + button, rather than the row at the bottom of the list: it is present
        // without scrolling, so it cannot be the source of a below-the-fold miss.
        XCTAssertTrue(
            UITestSession.tap(app.buttons["nudgeAddButton"], untilExists: app.textFields["nudgeAddLabelField"]),
            "The New nudge sheet never opened"
        )

        attach(app, named: "1-new-nudge-default")

        // Custom reveals the day row — the part that used to wrap every label mid-word.
        let custom = app.buttons["nudgeAddPreset-custom"]
        XCTAssertTrue(custom.waitForExistence(timeout: UITestSession.timeout), "No Custom chip")
        custom.tap()
        attach(app, named: "2-new-nudge-custom-days")

        // And a named preset, so the summary line is shown saying a real sentence.
        //
        // Settled on a real CONDITION before capturing, not a sleep. The first attempt shot
        // immediately after the tap and caught the spring mid-flight — the day row ghosting as it
        // collapsed, the chip half-filled, its label washed out. The state was right and the
        // picture was a lie, which is worse than no picture. Choosing Weekdays closes the day row,
        // so the row's own disappearance is the thing to wait on.
        let weekdays = app.buttons["nudgeAddPreset-weekdays"]
        XCTAssertTrue(weekdays.waitForExistence(timeout: UITestSession.timeout), "No Weekdays chip")
        XCTAssertTrue(
            UITestSession.tap(weekdays, untilGone: app.buttons["nudgeAddWeekdayToggle-0"]),
            "Choosing Weekdays did not close the Custom day row"
        )
        attach(app, named: "3-new-nudge-weekdays")
    }

    /// One ACTIVE, not-yet-due nudge — enough to make the door render in its quiet state.
    ///
    /// Deliberately not overdue: an overdue nudge puts a due card above the door and pushes it
    /// further down the scroll for no benefit here. The schedule fires daily at 23:59 and
    /// `created_at` is now, so its next fire is always ahead of the reference date.
    private func seedScheduledNudge(id: UUID, label: String, uid: String) throws {
        try UITestEmulator.writeDocument(
            path: "users/\(uid)/nudges/\(id.uuidString)",
            fields: [
                "id": UITestEmulator.string(id.uuidString),
                "label": UITestEmulator.string(label),
                "schedule": UITestEmulator.string("59 23 * * 0,1,2,3,4,5,6"),
                "active": UITestEmulator.bool(true),
                "created_at": UITestEmulator.timestamp(Date()),
                "updated_at": UITestEmulator.timestamp(Date())
            ]
        )
    }

    @MainActor
    private func attach(_ app: XCUIApplication, named name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}

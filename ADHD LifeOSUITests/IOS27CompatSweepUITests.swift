//
//  IOS27CompatSweepUITests.swift
//  ADHD LifeOSUITests
//
//  Phase D of the iOS 27 arc — a render harness, not a test. It asserts only that each surface
//  was reached; the evidence is the attachments, driven ONCE PER RUNTIME (`OS=26.5` and `OS=27.0`
//  on the same build) and once per appearance, so the two runtimes' frames can be laid side by
//  side. The `RenderHarnessUITests` shape, kept deliberately: it photographs the app on a REAL
//  runtime, which a `#Preview` render cannot claim.
//
//  The surfaces are the audit's list, in its order of risk: the custom tab bar (in every frame),
//  the search row, the three sheets with detents, the Settings sheet and a confirmation dialog
//  over it, and the nudges screen's inline toolbar.
//

import XCTest

final class IOS27CompatSweepUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testSweepTheDesignSensitiveSurfaces() throws {
        try UITestEmulator.skipUnlessRunning()

        // Seeded BEFORE launch so every surface has real content in it: an empty list, an empty
        // inbox and a nudges section that does not render (see `RenderHarnessUITests`) would
        // photograph the empty states, not the surfaces the sweep is about.
        let account = try UITestSession.createAccount(label: "ios27sweep")
        let taskID = UUID()
        try UITestSession.seedTask(id: taskID, title: "Renew the passport", uid: account.uid)
        try seedWaitingCapture(id: UUID(), content: "Book the dentist", uid: account.uid)
        try seedScheduledNudge(id: UUID(), label: "Drink water", uid: account.uid)

        let app = try UITestSession.launchSignedIn(as: account)
        XCTAssertTrue(
            UITestSession.signedInShell(app).waitForExistence(timeout: UITestSession.timeout),
            "The signed-in tabs never appeared"
        )
        // A longer first sweep: both of iOS's own prompts are due about now (see
        // `sweepSystemPrompts`), and the first frame is the one they landed on in the first runs.
        sweepSystemPrompts(app, wait: 5)
        settle()
        attach(app, "00-today")

        try sweepTasksAndSearch(app, taskID: taskID)
        sweepPlainTabs(app)
        try sweepCapturesAndPromoteSheet(app)
        try sweepSettingsSheetAndDialog(app)
        try sweepNudgesAndDetents(app)
    }

    // MARK: - Surfaces

    /// Tasks: the list with its bottom search row, then the row opened — the `.searchable`
    /// precedent that created the bottom-search arc when iOS 26 moved the capsule.
    @MainActor
    private func sweepTasksAndSearch(_ app: XCUIApplication, taskID: UUID) throws {
        UITestSession.openTab("Tasks", in: app)
        let taskRow = app.descendants(matching: .any)["taskRow-\(taskID.uuidString)"]
        XCTAssertTrue(taskRow.waitForExistence(timeout: UITestSession.timeout), "The seeded task never listed")
        settle()
        attach(app, "01-tasks")

        let row = app.descendants(matching: .any)["appSearchRow"]
        let field = app.descendants(matching: .any)["taskSearchField"]
        XCTAssertTrue(row.waitForExistence(timeout: UITestSession.timeout), "No search row on Tasks")
        XCTAssertTrue(UITestSession.tap(row, untilExists: field), "The search row did not open the field")
        settle()
        attach(app, "02-tasks-search-open")
        XCTAssertTrue(
            UITestSession.tap(app.buttons["taskSearchCancelButton"], untilGone: field),
            "Cancel did not close the search field"
        )
    }

    /// The three tabs with nothing to open: each is a frame of the bar with a different content
    /// layer scrolling beneath it, which is exactly what the HIG's 2026-09-09 Layout revision is
    /// about.
    @MainActor
    private func sweepPlainTabs(_ app: XCUIApplication) {
        for (index, tab) in ["Areas", "Journal", "Tools"].enumerated() {
            UITestSession.openTab(tab, in: app)
            settle()
            attach(app, "0\(index + 3)-\(tab.lowercased())")
        }
    }

    /// Captures with the seeded note on the decision card, then Task It → the promote sheet
    /// (`CapturePromoteSheet:92`, `[.medium, .large]`, an inline-title toolbar, and the surface
    /// that mounts its own `CelebrationLayer`).
    @MainActor
    private func sweepCapturesAndPromoteSheet(_ app: XCUIApplication) throws {
        UITestSession.openTab("Captures", in: app)
        let topCard = app.descendants(matching: .any)["captureInboxTopCard"]
        XCTAssertTrue(topCard.waitForExistence(timeout: UITestSession.timeout), "The seeded capture never surfaced")
        settle()
        attach(app, "06-captures")

        let cancel = app.buttons["capturePromoteCancelButton"]
        XCTAssertTrue(
            UITestSession.tap(app.buttons["captureInboxTaskItButton"], untilExists: cancel),
            "Task It did not open the promote sheet"
        )
        settle()
        attach(app, "07-promote-sheet")
        XCTAssertTrue(UITestSession.tap(cancel, untilGone: cancel), "The promote sheet did not dismiss")
    }

    /// The Settings sheet (a plain `.sheet` over Today), then Delete Account… — a
    /// `confirmationDialog` presented OVER a sheet, the composition
    /// `CelebrationProbeSwiftUISheetTests` covers and the one iOS 27's trait-inheritance change
    /// (release note 170005251) would reach first. Cancelled, never confirmed.
    @MainActor
    private func sweepSettingsSheetAndDialog(_ app: XCUIApplication) throws {
        UITestSession.openTab("Today", in: app)
        let done = app.buttons["settingsDoneButton"]
        XCTAssertTrue(
            UITestSession.tap(app.buttons["settingsButton"], untilExists: done),
            "Settings never opened"
        )
        settle()
        attach(app, "08-settings-sheet")

        let delete = app.buttons["deleteAccountButton"]
        XCTAssertTrue(UITestSession.scrollUntilHittable(delete, in: app), "Delete Account… never came into reach")
        let confirm = app.buttons["confirmDeleteAccountButton"]
        XCTAssertTrue(UITestSession.tap(delete, untilExists: confirm), "The delete confirmation never appeared")
        settle()
        attach(app, "09-delete-account-dialog")

        dismissConfirmationDialog(app, confirm: confirm)
        XCTAssertTrue(UITestSession.tap(done, untilGone: done), "Done did not close Settings")
    }

    /// A `confirmationDialog` has two costumes and only one of them has a Cancel: on iOS 26.5 the
    /// delete dialog rendered as a POPOVER anchored to its row (first run's frame 09), with no
    /// Cancel button in the tree, dismissed by a tap outside. The action-sheet costume has one.
    /// Both are handled so the 27.0 run can take either shape without failing the sweep.
    @MainActor
    private func dismissConfirmationDialog(_ app: XCUIApplication, confirm: XCUIElement) {
        let cancel = app.buttons["Cancel"].firstMatch
        if cancel.waitForExistence(timeout: 2) {
            XCTAssertTrue(UITestSession.tap(cancel, untilGone: confirm), "Cancel did not close the dialog")
            return
        }
        for _ in 1...3 where confirm.exists {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.12)).tap()
            settle()
        }
        XCTAssertFalse(confirm.exists, "Tapping outside did not close the popover dialog")
    }

    /// The nudges screen (an inline-title navigation bar with a leading back button), then the
    /// New nudge sheet at `.medium`, then the Custom preset that grows it to `.large`
    /// (`NudgesView:300`, the one detent site with a SELECTION binding).
    @MainActor
    private func sweepNudgesAndDetents(_ app: XCUIApplication) throws {
        // Through Tools since `F-E3-OneCardToday` moved the door there (E, 2026-09-24).
        let add = app.buttons["nudgeAddButton"]
        XCTAssertTrue(UITestSession.openNudgesFromTools(in: app), "The nudges screen never opened")
        settle()
        attach(app, "10-nudges")

        let label = app.textFields["nudgeAddLabelField"]
        XCTAssertTrue(UITestSession.tap(add, untilExists: label), "The New nudge sheet never opened")
        settle()
        attach(app, "11-new-nudge-medium")

        let toggle = app.buttons["nudgeAddWeekdayToggle-0"]
        XCTAssertTrue(
            UITestSession.tap(app.buttons["nudgeAddPreset-custom"], untilExists: toggle),
            "Custom did not reveal the day row"
        )
        settle()
        attach(app, "12-new-nudge-large")
    }

    // MARK: - Seeds

    /// One capture in the inbox — the `SignedInJourneySupport` shape, camelCase except
    /// `created_at`, which is the convention split `FirestoreFieldPayloads` documents.
    private func seedWaitingCapture(id: UUID, content: String, uid: String) throws {
        try UITestEmulator.writeDocument(
            path: "users/\(uid)/captures/\(id.uuidString)",
            fields: [
                "id": UITestEmulator.string(id.uuidString),
                "content": UITestEmulator.string(content),
                "kind": UITestEmulator.string("note"),
                "processed": UITestEmulator.bool(false),
                "created_at": UITestEmulator.timestamp(Date().addingTimeInterval(-3600))
            ]
        )
    }

    /// One active, not-yet-due nudge — enough to make Today's nudges door render at all.
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

    // MARK: - Capture

    /// A beat for springs to land before the frame is taken. `RenderHarnessUITests` records why:
    /// a shot taken straight after a tap caught a sheet mid-flight, and the picture lied.
    private func settle() {
        Thread.sleep(forTimeInterval: 1.0)
    }

    /// iOS puts two prompts of its own over a fresh sign-in, and neither arrives on a schedule:
    /// the notification-permission alert (Home asks when it loads an active nudge) and the
    /// AutoFill "Save Password?" sheet, which can trail sign-in by ten seconds or more. The first
    /// runs caught the alert on 26.5's Today frame and the sheet on 27.0's Tasks frame — different
    /// frames per runtime, which made the composites measure the prompts instead of the app. So
    /// every capture sweeps both first. The wait is short when nothing is there.
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

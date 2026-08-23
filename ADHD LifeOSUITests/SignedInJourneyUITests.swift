//
//  SignedInJourneyUITests.swift
//  ADHD LifeOSUITests
//

import XCTest

/// The four signed-in journeys deleted in the 2026-08-19 slimming, rebuilt against the Firebase
/// Emulator Suite. `ADHD_LifeOSUITests`'s header named the prerequisite for reviving them — "a
/// dedicated Firebase test user (ideally against the Auth/Firestore emulators)" — and that now
/// exists, so they no longer need a gitignored credentials file or a real account.
///
/// These skip when the emulator is not running, so a fresh clone still passes with zero setup.
/// They are also the only tests in the project that exercise SwiftUI view bodies, which unit
/// tests cannot reach.
final class SignedInJourneyUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        try UITestEmulator.skipUnlessRunning()
    }

    // MARK: - Task create

    /// Creating a task from the Tasks tab puts it in the list. The end-to-end path: the create
    /// sheet writes through `FirebaseTaskCreateClientAdapter` to the emulator's Firestore, and
    /// the list re-reads it — so a break anywhere from the form to the wire fails this.
    @MainActor
    func testCreateTask_fromTasksTab_appearsInList() throws {
        let app = try UITestSession.launchSignedIn(label: "create")
        openTasksTab(app)

        let createButton = app.buttons["taskCreateButton"]
        XCTAssertTrue(createButton.waitForExistence(timeout: UITestSession.timeout))
        createButton.tap()

        // Unique per run: the account is new every time, but a fixed title would still collide
        // with the seeded starter tasks if one were ever renamed to match.
        let title = "Buy oat milk \(UUID().uuidString.prefix(6))"
        let titleField = app.textFields["taskCreateTitleField"]
        UITestSession.focusAndType(titleField, text: title, in: app)

        let submit = app.buttons["taskCreateSubmitButton"]
        XCTAssertTrue(submit.isEnabled, "Create stayed disabled with a title entered")
        submit.tap()

        XCTAssertTrue(
            app.staticTexts[title].waitForExistence(timeout: UITestSession.timeout),
            "The created task never appeared in the list"
        )
    }

    // MARK: - Settings dismiss

    /// Settings opens from Home and closes again. Trivial-sounding, and it is exactly the kind of
    /// modal-presentation wiring that breaks silently: a sheet that will not dismiss strands the
    /// user with no way back to their tasks.
    @MainActor
    func testSettings_opensFromHomeAndDismissesBackToIt() throws {
        let app = try UITestSession.launchSignedIn(label: "settings")

        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: UITestSession.timeout))
        settingsButton.tap()

        let done = app.buttons["settingsDoneButton"]
        XCTAssertTrue(done.waitForExistence(timeout: UITestSession.timeout), "Settings never presented")
        done.tap()

        XCTAssertTrue(
            settingsButton.waitForExistence(timeout: UITestSession.timeout),
            "Dismissing Settings did not return to Home"
        )
        XCTAssertFalse(done.exists, "The Settings sheet was still present after Done")
    }

    // MARK: - Task detail field population

    /// The regression this exists for: `TaskDetailView` opening with a BLANK title field instead
    /// of the task's own title. Its original test was one of the intermittently-failing four
    /// logged in the flaky-UI-test KNOWN ISSUE, which means it had never once cleanly exercised
    /// the code it was written to verify.
    ///
    /// The task is written straight into Firestore with a known id, so the test can address
    /// `taskDetails-<uuid>` exactly rather than guessing which row it is opening.
    @MainActor
    func testTaskDetail_opensWithTitleFieldPopulated_notBlank() throws {
        let account = try UITestSession.createAccount(label: "detail")
        let taskID = UUID()
        let title = "Renew the passport"
        try seedTask(id: taskID, title: title, uid: account.uid)

        let app = try UITestSession.launchSignedIn(as: account)
        openTasksTab(app)

        let detailsButton = app.buttons["taskDetails-\(taskID.uuidString)"]
        XCTAssertTrue(
            detailsButton.waitForExistence(timeout: UITestSession.timeout),
            "The seeded task never appeared in the list"
        )
        detailsButton.tap()

        let titleField = app.textFields["taskDetailTitleField"]
        XCTAssertTrue(titleField.waitForExistence(timeout: UITestSession.timeout), "Task detail never opened")
        XCTAssertEqual(
            titleField.value as? String,
            title,
            "Task detail opened with a title field that does not match the task"
        )
    }

    // MARK: - Due nudge dismissal

    /// Home surfaces overdue nudges in a strip, and dismissing one removes it.
    ///
    /// The nudge is backdated rather than created through the UI because dueness is computed, not
    /// stored: `NudgeDueness` asks whether the next fire time after `last_fired_at` has elapsed.
    /// A nudge made through the app is by definition not yet due, so there is no UI path to this
    /// state — hence the direct Firestore write, a month in the past against an every-day
    /// schedule, which is overdue regardless of when the test runs.
    @MainActor
    func testDueNudge_appearsOnHomeAndCanBeDismissed() throws {
        let account = try UITestSession.createAccount(label: "nudge")
        let nudgeID = UUID()
        let nudgeLabel = "Stretch your back"
        try seedOverdueNudge(id: nudgeID, label: nudgeLabel, uid: account.uid)

        let app = try UITestSession.launchSignedIn(as: account)

        // Addressed by LABEL, not identifier. The enclosing stack's own identifier is pushed
        // down over the subtree, so every dismiss button answers to "homeDueNudgesStrip" and
        // none can be told apart by id — confirmed from the accessibility tree. The label is
        // per-nudge and survives, so it is what identifies this one.
        let dismiss = app.buttons["Dismiss \(nudgeLabel)"]
        XCTAssertTrue(
            dismiss.waitForExistence(timeout: UITestSession.timeout),
            "An overdue nudge did not appear in Home's due strip"
                + (app.staticTexts[nudgeLabel].exists
                    ? " (its label rendered, so the identifier is the problem)"
                    : " (nothing from the nudge rendered at all)")
        )

        dismiss.tap()

        let gone = XCTNSPredicateExpectation(predicate: .init(format: "exists == false"), object: dismiss)
        XCTAssertEqual(
            XCTWaiter().wait(for: [gone], timeout: UITestSession.timeout),
            .completed,
            "The nudge was still listed as due after being dismissed"
        )
    }

    // MARK: - Navigation

    @MainActor
    private func openTasksTab(_ app: XCUIApplication) {
        let tab = app.tabBars.buttons["Tasks"]
        XCTAssertTrue(tab.waitForExistence(timeout: UITestSession.timeout), "Tab bar never appeared")
        tab.tap()
    }

    // MARK: - Firestore fixtures

    /// Task documents are fully snake_cased (`life_area_id`, `created_at`) — see CLAUDE.md, where
    /// the tasks/captures casing split is spelled out. Document IDs are UPPERCASE `uuidString`.
    private func seedTask(id: UUID, title: String, uid: String) throws {
        try UITestEmulator.writeDocument(
            path: "users/\(uid)/tasks/\(id.uuidString)",
            fields: [
                "id": UITestEmulator.string(id.uuidString),
                "title": UITestEmulator.string(title),
                "status": UITestEmulator.string("open"),
                "priority": UITestEmulator.string("p3"),
                "created_at": UITestEmulator.timestamp(Date())
            ]
        )
    }

    private func seedOverdueNudge(id: UUID, label: String, uid: String) throws {
        let aMonthAgo = Date().addingTimeInterval(-30 * 24 * 3600)
        try UITestEmulator.writeDocument(
            path: "users/\(uid)/nudges/\(id.uuidString)",
            fields: [
                "id": UITestEmulator.string(id.uuidString),
                "label": UITestEmulator.string(label),
                // "MIN HOUR * * DOW" — midnight, every day, so the next fire after the reference
                // date below is a month in the past no matter what time the suite runs.
                "schedule": UITestEmulator.string("0 0 * * 0,1,2,3,4,5,6"),
                "active": UITestEmulator.bool(true),
                "last_fired_at": UITestEmulator.timestamp(aMonthAgo),
                "created_at": UITestEmulator.timestamp(aMonthAgo),
                "updated_at": UITestEmulator.timestamp(aMonthAgo)
            ]
        )
    }
}

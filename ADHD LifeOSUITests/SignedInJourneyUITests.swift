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

        // The composer creates the task undated, and the default Momentum board deliberately
        // excludes undated tasks since F-V3-Tasks-rebuild — they live under the Open filter,
        // so that is where a freshly created task must appear.
        let openChip = app.buttons["Open"]
        XCTAssertTrue(openChip.waitForExistence(timeout: UITestSession.timeout), "The Open filter chip is missing")
        openChip.tap()

        XCTAssertTrue(
            app.staticTexts[title].waitForExistence(timeout: UITestSession.timeout),
            "The created task never appeared under the Open filter"
        )
    }

    // MARK: - Settings dismiss

    /// Settings opens from Home and closes again. Trivial-sounding, and it is exactly the kind of
    /// modal-presentation wiring that breaks silently: a sheet that will not dismiss strands the
    /// user with no way back to their tasks.
    @MainActor
    func testSettings_opensFromHomeAndDismissesBackToIt() throws {
        let account = try UITestSession.createAccount(label: "settings")
        let app = try UITestSession.launchSignedIn(as: account)

        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: UITestSession.timeout))
        settingsButton.tap()

        let done = app.buttons["settingsDoneButton"]
        XCTAssertTrue(done.waitForExistence(timeout: UITestSession.timeout), "Settings never presented")

        // Settings is the only place that says WHICH account this device is on. Until now it said
        // nothing at all — you had to sign out and read the address back to find out.
        //
        // TWO traps here, both confirmed by dumping the hierarchy rather than reasoning about it:
        //
        // 1. The Account section starts BELOW the fold, and SwiftUI materialises Form rows lazily
        //    — un-scrolled, the section does not merely sit off-screen, it is absent from the
        //    accessibility tree entirely. `signOutIfSignedIn` hunts the same section for the same
        //    reason. So: scroll first, and `waitForExistence` cannot substitute for scrolling.
        // 2. `LabeledContent` merges its title and value into ONE element reading
        //    "Email, someone@example.test", so nothing carries the bare address. Match the row by
        //    identifier and assert its LABEL contains the address — which still catches the
        //    failure that matters, a row naming the wrong account.
        let emailRow = app.staticTexts["settingsAccountEmailRow"]
        scrollUntilHittable(emailRow, in: app)
        XCTAssertTrue(
            emailRow.exists,
            "Settings showed no account email row, even after scrolling to the Account section"
        )
        XCTAssertTrue(
            emailRow.label.contains(account.email),
            "Settings named the wrong account: '\(emailRow.label)' does not contain '\(account.email)'"
        )

        // No name row: these accounts are created straight through the Auth REST API, which never
        // sees the sign-up form's optional name field. Absent means absent — the row is omitted
        // rather than rendered blank or as "Not set". Checked HERE, with the section on screen, so
        // "not found" cannot just mean "not scrolled to".
        XCTAssertFalse(
            app.descendants(matching: .any)["settingsAccountNameRow"].exists,
            "A nameless account must not render an empty Name row"
        )

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
    /// `taskRow-<uuid>` exactly rather than guessing which row it is opening (F-V3-Tasks-rebuild
    /// replaced the swipe cards with dense rows — the row's text area opens the detail).
    ///
    /// The seeded task is due TODAY: the Momentum board (the default filter) now shows only
    /// due-today/tomorrow/closed-today, so an undated task would never render on it.
    @MainActor
    func testTaskDetail_opensWithTitleFieldPopulated_notBlank() throws {
        let account = try UITestSession.createAccount(label: "detail")
        let taskID = UUID()
        let title = "Renew the passport"
        try seedTask(id: taskID, title: title, uid: account.uid)

        let app = try UITestSession.launchSignedIn(as: account)
        openTasksTab(app)

        let detailsButton = app.descendants(matching: .any)["taskRow-\(taskID.uuidString)"]
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

    /// Today surfaces an overdue nudge as its own dismissable card, and dismissal happens right
    /// there — no tab hop, because there is no Nudges tab. Captures took that slot back on
    /// 2026-08-28 and nudges became a section on Today, which restores the inline dismissal
    /// F-V3-Today had traded away for a row that only crossed to the tab.
    ///
    /// The journey got SHORTER as a result, and that is the point: the thing being tested is
    /// "an overdue nudge can be dealt with", and it is now one tap from launch.
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

        // The tab bar arrives with the signed-in shell, but Today's CONTENT arrives later — its
        // whole scroll view is absent until `HomeService` reaches `.loaded`. Waiting on a
        // load-bearing Today element first separates "Home never loaded" from "the nudge did not
        // render", which the same 45s timeout on the card alone cannot tell apart.
        XCTAssertTrue(
            app.staticTexts["homeMomentumRing"].waitForExistence(timeout: UITestSession.timeout),
            "Today never finished loading, so the nudge had nowhere to appear"
        )

        // The overdue nudge's own card. Asserted on the dismiss control directly: it is what the
        // user came for, and it carries the nudge's id, so a card rendered for the WRONG nudge
        // fails here rather than passing on a label match.
        let dismiss = app.buttons["nudgeDismissButton-\(nudgeID.uuidString)"]
        XCTAssertTrue(
            dismiss.waitForExistence(timeout: UITestSession.timeout),
            "An overdue nudge did not surface a dismissable card on Today"
                + (app.otherElements["homeNudgesFailureCard"].exists
                    ? " (the nudge list failed to LOAD — this is the emulator or the fetch, not"
                        + " the section)"
                    : app.otherElements["homeNudgesSection"].exists
                        ? " (the section rendered, so the card's identifier is the problem —"
                            + " check nothing above it swallowed the children's identifiers)"
                        : app.staticTexts[nudgeLabel].exists
                            ? " (its label rendered without the section)"
                            : " (nothing from the nudge rendered at all)")
        )

        // Existing is not reachable. Today is a long scroll and the nudges section sits below the
        // fold on this device, so the card is in the hierarchy while being untappable — the same
        // trap `UITestSession.signOutIfSignedIn` hits on the sign-out row. Hunt for it the way a
        // user would rather than pinning where the fold happens to fall this release.
        var scrollsRemaining = 8
        while !dismiss.isHittable, scrollsRemaining > 0 {
            app.swipeUp()
            scrollsRemaining -= 1
        }
        XCTAssertTrue(
            dismiss.isHittable, "The nudge's dismiss control never scrolled into reach on Today"
        )
        dismiss.tap()

        // The card goes because the nudge is no longer DUE — `dismiss` stamps `last_fired_at`,
        // which moves the next fire time into the future. Today's section shows no error line of
        // its own (that lives on the pushed manager), so a stuck card here means the write failed
        // or the section did not recompute.
        let gone = XCTNSPredicateExpectation(predicate: .init(format: "exists == false"), object: dismiss)
        XCTAssertEqual(
            XCTWaiter().wait(for: [gone], timeout: UITestSession.timeout),
            .completed,
            "The nudge was still shown as due on Today after being dismissed"
        )
    }

    // MARK: - Capture triage, on the tab captures finally have

    /// The Captures tab end to end: a waiting capture reaches the decision card, **Sorted** stays
    /// unavailable until a life area is picked, sorting files it and clears it, and Undo puts it
    /// back.
    ///
    /// This screen was rebuilt across three blocks — the audit rewrote its rules, the IA
    /// restructure made it a tab and folded the archive into it, and the undo work changed what
    /// its bottom bar does — with no end-to-end coverage at all. The unit suite cannot see any of
    /// what this asserts: that the tab exists, that the disabled button is genuinely disabled,
    /// that a write lands, and that a bar built from `lastTriageAction` can actually be tapped.
    @MainActor
    func testCapturesTab_sortsACaptureIntoAnAreaAndTakesItBack() throws {
        let account = try UITestSession.createAccount(label: "capture")
        let content = "Book the dentist"
        try seedWaitingCapture(id: UUID(), content: content, uid: account.uid)

        let app = try UITestSession.launchSignedIn(as: account)
        openCapturesTab(app)

        XCTAssertTrue(
            app.staticTexts[content].waitForExistence(timeout: UITestSession.timeout),
            "A waiting capture did not reach the Captures tab's decision card"
                + (app.staticTexts["captureInboxEmptyState"].exists
                    ? " (the inbox rendered as empty — check the seeded document decodes,"
                        + " especially `created_at`)"
                    : " (the inbox did not render at all)")
        )

        // The requirement, seen from outside: Sorted is present but refuses to fire until an area
        // is chosen. Round 1's whole design rests on this being visibly true.
        let sorted = app.buttons["captureInboxSortedButton"]
        XCTAssertTrue(sorted.waitForExistence(timeout: UITestSession.timeout), "No Sorted button")
        XCTAssertFalse(
            sorted.isEnabled, "Sorted was live with no life area chosen — the rule is not enforced"
        )

        // Any area will do; they are seeded server-side with UUIDs a test cannot know.
        let chip = app.buttons.matching(identifier: "composerAreaChip").firstMatch
        XCTAssertTrue(chip.waitForExistence(timeout: UITestSession.timeout), "No life-area chips")
        scrollUntilHittable(chip, in: app)
        chip.tap()

        XCTAssertTrue(sorted.isEnabled, "Sorted stayed unavailable after an area was chosen")
        scrollUntilHittable(sorted, in: app)
        sorted.tap()

        // Sorted files AND clears in one write, so the capture leaves the queue...
        let gone = XCTNSPredicateExpectation(
            predicate: .init(format: "exists == false"), object: app.staticTexts[content]
        )
        XCTAssertEqual(
            XCTWaiter().wait(for: [gone], timeout: UITestSession.timeout), .completed,
            "The capture was still in the inbox after being sorted"
        )

        // ...and the bar offers it back. Tapping the bar's own button is the point: it was fused
        // into the bar by `.combine` until this journey existed to press it.
        let undo = app.buttons["Undo"]
        XCTAssertTrue(
            undo.waitForExistence(timeout: UITestSession.timeout),
            "Sorting offered no undo bar"
                + (app.otherElements["captureInboxUndoBar"].exists
                    ? " (the bar is there but its button is not addressable)"
                    : " (no bar at all)")
        )
        scrollUntilHittable(undo, in: app)
        undo.tap()

        XCTAssertTrue(
            app.staticTexts[content].waitForExistence(timeout: UITestSession.timeout),
            "Undo did not bring the sorted capture back to the inbox"
        )
    }

}

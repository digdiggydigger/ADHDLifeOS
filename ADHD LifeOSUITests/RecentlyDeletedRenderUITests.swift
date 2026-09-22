//
//  RecentlyDeletedRenderUITests.swift
//  ADHD LifeOSUITests
//
//  A render harness for `F-C3-RecentlyDeleted`, not a test — the block's acceptance criteria ask
//  for `screenshots/recently-deleted/`, and this is what produces it. It asserts only enough to
//  fail loudly when it photographs the wrong thing. `DraftsToInboxRenderUITests` is the model.
//
//  **Why the real app rather than previews.** Every claim here is a TRANSITION across three
//  screens — a task leaves Tasks, appears on a screen in Tools, and comes back. `RecentlyDeletedView`
//  has previews and they draw the rows perfectly; what they cannot show is that deleting from task
//  detail is what fills them, or that Restore puts the task back in the list it left. That round
//  trip is the whole block.
//
//  **The seeded task has a known id**, the `SearchRowDepthJourneyUITests` arrangement, so every
//  frame is of THAT row — "a task is in the list" and "the task I deleted is back in the list" are
//  different claims and only an id tells them apart.
//
//  **One ordering constraint, and it comes from E's own call.** The delete no longer raises a
//  confirmation (E, 2026-09-22, after the `apple-design` review), so `taskDetailDeleteButton` is a
//  single tap that pops the screen. A harness written against the old flow would sit waiting for
//  a dialog that is deliberately gone.
//
//  **Two vacuous assertions, both paid for on the first run, and both the same mistake.** The
//  delete was first written as `tap(deleteButton, untilGone: titleField)` — and `tap(_:untilGone:)`
//  returns `true` on its FIRST LINE when the doomed element is already absent, without tapping at
//  all. Scrolling down a `Form` to reach the Delete button takes the title field out of the
//  hierarchy, so the condition was satisfied by the SCROLL. The follow-up,
//  `row.waitForNonExistence`, then passed for the same reason in reverse: the run was still on
//  task detail, where no task row exists. Two green assertions, no delete, and a frame of a tab
//  transition labelled as a deleted list. The emulator settled it — `deleted_at` appeared on no
//  document in the project.
//
//  **So every step here waits on something POSITIVE.** The capsule appearing is proof the write
//  landed; the create button proves the list is actually rendered before its emptiness means
//  anything. An absence is only ever asserted next to a presence.
//

import XCTest

final class RecentlyDeletedRenderUITests: XCTestCase {

    private enum Fixture {
        static let title = "Ring the dentist about the referral"
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// One account, one task, one round trip: delete it, find it, restore it, then delete it again
    /// and destroy it for good.
    ///
    /// Appearance is whatever the simulator is set to (`xcrun simctl ui booted appearance
    /// light|dark`) and the text size is whatever `content_size` was before the run, so the same
    /// journey produces the light, dark and AX3 sets without three copies of it.
    @MainActor
    func testRenderTheRoundTripFromDeleteToRestore() throws {
        try UITestEmulator.skipUnlessRunning()
        let account = try UITestSession.createAccount(label: "recentlydeleted")
        let taskID = UUID()
        try UITestSession.seedTask(id: taskID, title: Fixture.title, uid: account.uid)
        let app = try UITestSession.launchSignedIn(as: account)
        XCTAssertTrue(
            app.buttons["quickCaptureButton"].waitForExistence(timeout: UITestSession.timeout),
            "The signed-in tabs never appeared"
        )

        // **Tasks FIRST, and the empty Tools row gets its own run below.** Opening Tools before
        // this used to put a five-slot tab slide immediately in front of the delete, and
        // `scrollUntilHittable` would report the button hittable on a frame still in transit —
        // the tap then landed on a page at x≈10016 and the run failed intermittently. Nothing
        // about the empty row needs to be photographed in the same session as the delete.
        deleteTheSeededTask(app, id: taskID)
        renderTheFilledToolsRow(app)
        restoreFromTheScreen(app, id: taskID)
    }

    /// The row before anything has been deleted. **Its own run, with a fresh account**, because
    /// it is the only frame in this folder that needs an account nothing has happened to.
    @MainActor
    func testRenderTheEmptyToolsRow() throws {
        try UITestEmulator.skipUnlessRunning()
        let account = try UITestSession.createAccount(label: "recentlydeletedempty")
        let app = try UITestSession.launchSignedIn(as: account)
        XCTAssertTrue(
            app.buttons["quickCaptureButton"].waitForExistence(timeout: UITestSession.timeout),
            "The signed-in tabs never appeared"
        )
        renderTheEmptyToolsRow(app)
    }

    /// **Delete forever gets its own run, and a task seeded ALREADY STAMPED.**
    /// Reaching it inside the journey above meant deleting a second time, which put the run back
    /// through task detail with a capsule already pending — and every signal that a delete had
    /// landed was then satisfiable by the FIRST one. Seeding the stamp removes the whole
    /// interaction: this run only has to open the screen and press the one button that cannot be
    /// undone.
    @MainActor
    func testRenderDeleteForever() throws {
        try UITestEmulator.skipUnlessRunning()
        let account = try UITestSession.createAccount(label: "deleteforever")
        let taskID = UUID()
        try Self.seedDeletedTask(id: taskID, title: Fixture.title, uid: account.uid)
        let app = try UITestSession.launchSignedIn(as: account)
        XCTAssertTrue(
            app.buttons["quickCaptureButton"].waitForExistence(timeout: UITestSession.timeout),
            "The signed-in tabs never appeared"
        )

        openTheScreen(app)
        let forever = app.buttons["recentlyDeletedDeleteForever-task-\(taskID.uuidString)"]
        XCTAssertTrue(
            forever.waitForExistence(timeout: UITestSession.timeout),
            "The pre-stamped task is not listed, so `fetchDeletedTasks` did not find it"
        )
        // `.firstMatch`: a `confirmationDialog` puts its button in the sheet AND leaves a second
        // match in the presenting hierarchy, so the bare subscript is ambiguous and the tap fails
        // with "Multiple matching elements found" rather than with anything about the app.
        let confirm = app.buttons["recentlyDeletedConfirmDeleteForever"].firstMatch
        guard UITestSession.tap(forever, untilExists: confirm) else {
            return XCTFail("Delete forever raised no confirm — it is the one delete that must")
        }
        attach(app, named: "08-delete-forever-is-the-one-confirm-that-stays")

        let empty = app.staticTexts["recentlyDeletedEmpty"].firstMatch
        guard UITestSession.tap(confirm, untilExists: empty) else {
            attach(app, named: "09-DELETE-FOREVER-NEVER-LANDED")
            return XCTFail("Delete forever left the row standing")
        }
        attach(app, named: "09-deleted-for-good-and-the-list-is-empty")
    }

    /// A task that is already in the 30-day window. Same field spelling as `UITestSession.seedTask`
    /// plus the stamp — snake_cased, like every other task field.
    private static func seedDeletedTask(id: UUID, title: String, uid: String) throws {
        try UITestEmulator.writeDocument(
            path: "users/\(uid)/tasks/\(id.uuidString)",
            fields: [
                "id": UITestEmulator.string(id.uuidString),
                "title": UITestEmulator.string(title),
                "status": UITestEmulator.string("open"),
                "priority": UITestEmulator.string("p3"),
                "due_date": UITestEmulator.timestamp(Date()),
                "created_at": UITestEmulator.timestamp(Date()),
                "deleted_at": UITestEmulator.timestamp(Date())
            ]
        )
    }

    // MARK: - Before: the row exists with nothing waiting

    /// **The row is drawn in every state, including empty**, which is the claim this frame
    /// settles. A section that hid itself when the list was empty would be missing at exactly the
    /// moment someone goes looking for it — just after a delete they regret — and no test can see
    /// a view that was never built.
    @MainActor
    private func renderTheEmptyToolsRow(_ app: XCUIApplication) {
        UITestSession.openTab("Tools", in: app)
        settle(app.buttons["toolsCard.places"].firstMatch, "The Tools page")
        let row = app.buttons["toolsRecentlyDeletedRow"].firstMatch
        _ = UITestSession.scrollUntilHittable(row, in: app)
        XCTAssertTrue(
            row.waitForExistence(timeout: UITestSession.timeout),
            "The Tools page draws no Recently Deleted row, so the 30-day list is unreachable"
        )
        attach(app, named: "00-tools-row-nothing-waiting")
    }

    // MARK: - The delete, and the capsule that offers it back

    @MainActor
    private func deleteTheSeededTask(_ app: XCUIApplication, id: UUID) {
        UITestSession.openTab("Tasks", in: app)
        settle(app.buttons["taskCreateButton"], "The Tasks list")
        let row = app.descendants(matching: .any).matching(identifier: "taskRow-\(id.uuidString)").firstMatch
        XCTAssertTrue(
            row.waitForExistence(timeout: UITestSession.timeout), "The seeded task never listed"
        )
        attach(app, named: "01-tasks-list-holds-the-task")

        let deleteButton = app.buttons["taskDetailDeleteButton"]
        let titleField = app.textFields["taskDetailTitleField"]
        XCTAssertTrue(UITestSession.tap(row, untilExists: titleField), "Task detail never opened")
        // **The PUSH has to settle too, not just the tab switch.** Without this the run scrolled
        // and tapped while the detail was still sliding in, and XCUITest reported the Delete
        // button at x≈10016 — a whole screen-width times the tab index. A coordinate tap on that
        // bogus frame landed on the tab bar and selected another tab; a plain tap failed with
        // "Failed to not hittable". Both symptoms, one cause.
        settle(app.navigationBars["Task"], "Task detail")
        XCTAssertTrue(
            UITestSession.scrollUntilHittable(deleteButton, in: app),
            "The Delete button never became hittable — it is the last row of a Form under a tab bar"
        )
        attach(app, named: "02-task-detail-delete-button")
        // Re-checked AFTER the screenshot: `scrollUntilHittable` can catch a frame mid-slide, and
        // taking a screenshot is long enough for the page to move on.
        settle(deleteButton, "The Delete button")

        // **One tap, no dialog** (E's 2026-09-22 call), and the signal is the NAV BAR going away.
        //
        // Two earlier shapes of this line were wrong in opposite directions, and both are worth
        // the ink. `untilGone: titleField` never tapped at all — `tap(_:untilGone:)` returns on
        // its first line when the doomed element is already absent, and the scroll above had
        // taken the title field out of the hierarchy. `untilExists: undoCapsuleButton` then
        // failed the same way on the SECOND delete, because a capsule from the first was still
        // pending and `tap(_:untilExists:)` returns immediately when the expectation already
        // holds. The nav bar is immune to both: it is pinned, so scrolling cannot remove it, and
        // it belongs to THIS screen, so nothing left over from earlier can satisfy it.
        guard tapDelete(deleteButton, in: app) else {
            attach(app, named: "03-DELETE-NEVER-LANDED")
            return XCTFail("Task detail did not pop, so the soft delete did not land")
        }
        XCTAssertTrue(
            app.buttons["undoCapsuleButton"].waitForExistence(timeout: UITestSession.timeout),
            "No capsule was offered for the delete — E's Step 0 answer 2 is unmet"
        )
        XCTAssertFalse(
            app.alerts.firstMatch.exists,
            "A dialog was raised on delete. E dropped both confirms because the delete is undoable."
        )

        // The list, and only once it is demonstrably RENDERED — an absent row on a screen that
        // has not drawn yet is not evidence of anything.
        XCTAssertTrue(
            app.buttons["taskCreateButton"].waitForExistence(timeout: UITestSession.timeout),
            "The Tasks list never came back after the delete popped its detail"
        )
        XCTAssertTrue(
            row.waitForNonExistence(timeout: UITestSession.timeout),
            "The task is still in the Tasks list, so the live-ness filter is not reaching it"
        )
        attach(app, named: "03-tasks-list-without-it-and-the-capsule-offers-undo")
    }

    // MARK: - After: the row counts it, and the screen holds it

    @MainActor
    private func renderTheFilledToolsRow(_ app: XCUIApplication) {
        UITestSession.openTab("Tools", in: app)
        settle(app.buttons["toolsCard.places"].firstMatch, "The Tools page")
        let row = app.buttons["toolsRecentlyDeletedRow"].firstMatch
        _ = UITestSession.scrollUntilHittable(row, in: app)
        XCTAssertTrue(row.waitForExistence(timeout: UITestSession.timeout), "The Tools row vanished")
        attach(app, named: "04-tools-row-one-item-thirty-days-left")
    }

    // MARK: - Restore, and the task coming back where it left

    @MainActor
    private func restoreFromTheScreen(_ app: XCUIApplication, id: UUID) {
        openTheScreen(app)
        let restore = app.buttons["recentlyDeletedRestore-task-\(id.uuidString)"]
        XCTAssertTrue(
            restore.waitForExistence(timeout: UITestSession.timeout),
            "The deleted task is not listed in Recently Deleted"
        )
        attach(app, named: "05-recently-deleted-holds-the-task")

        let empty = app.staticTexts["recentlyDeletedEmpty"].firstMatch
        guard UITestSession.tap(restore, untilExists: empty) else {
            attach(app, named: "06-RESTORE-NEVER-EMPTIED")
            return XCTFail("Restore did not clear the row, so the stamp was not erased")
        }
        attach(app, named: "06-restored-and-the-screen-is-empty-again")

        UITestSession.openTab("Tasks", in: app)
        settle(app.buttons["taskCreateButton"], "The Tasks list")
        let taskRow = app.descendants(matching: .any).matching(identifier: "taskRow-\(id.uuidString)").firstMatch
        XCTAssertTrue(
            taskRow.waitForExistence(timeout: UITestSession.timeout),
            "The restored task did not come back to the Tasks list — `DataChangeSignal` is the"
                + " thing to look at, since the write plumbing is what posts it"
        )
        attach(app, named: "07-the-task-is-back-in-the-tasks-list")
    }

    // MARK: - Getting to the screen

    /// **The screen may ALREADY be open, and the fourth run of this harness is why.** Nothing pops
    /// it: after Restore the run switches to the Tasks tab to photograph the task coming back, and
    /// the Tools tab keeps its pushed screen. Coming back therefore lands on Recently Deleted, not
    /// on the cards — and the settle below failed with *"The Tools page never appeared"* while the
    /// app was behaving perfectly. It stays open deliberately rather than being popped: the screen
    /// observes `DataChangeSignal`, so the second delete reaches it, and that is worth exercising.
    @MainActor
    private func openTheScreen(_ app: XCUIApplication) {
        UITestSession.openTab("Tools", in: app)
        let screen = app.descendants(matching: .any).matching(identifier: "recentlyDeletedView").firstMatch
        if screen.waitForExistence(timeout: 3) {
            // **POPPED and re-pushed rather than reused**, so the next visit re-runs the screen's
            // `.task` and the frame is of a deterministic fetch. Left open, it depends on
            // `DataChangeSignal`'s 600ms debounce having delivered while the run was on another
            // tab — which it does, but a harness that waits on a debounce is a harness that
            // fails on a loaded machine and reads like a broken refresh. The re-tap IS the pop
            // (`.tabRoot(.tools, isAtRoot:onPopToRoot:)`), the same mechanism
            // `SearchRowDepthJourneyUITests` uses.
            _ = UITestSession.tap(UITestSession.tabButton("Tools", in: app), untilGone: screen)
        }

        settle(app.buttons["toolsCard.places"].firstMatch, "The Tools page")
        let row = app.buttons["toolsRecentlyDeletedRow"].firstMatch
        _ = UITestSession.scrollUntilHittable(row, in: app)
        guard UITestSession.tap(row, untilExists: screen) else {
            return XCTFail("The Tools row did not push the Recently Deleted screen")
        }
    }

    /// **Tapped by COORDINATE, re-settling between attempts.** `scrollUntilHittable` can report
    /// the button hittable on a frame that is still sliding, and the tap then lands on a page at
    /// x≈10016 — a whole screen-width times the tab index — failing with *"Failed to not
    /// hittable"*. It is intermittent, which is worse than reproducible. `openTab` solved the
    /// same problem the same way: *"a plain `.tap()` goes through hittability resolution that a
    /// just-dismissed cover can still interfere with, so retries tap the COORDINATE instead."*
    ///
    /// The nav bar is the signal, not the title field and not the capsule — see the call site.
    @MainActor
    private func tapDelete(_ button: XCUIElement, in app: XCUIApplication) -> Bool {
        let bar = app.navigationBars["Task"]
        for _ in 1...3 {
            guard !bar.exists else {
                // A PLAIN tap, deliberately. The coordinate form was tried and is worse here: it
                // bypasses hittability, so on a frame that is still sliding it taps real screen
                // coordinates that belong to something else — one run ended on the Areas tab.
                // Failing loudly on "not hittable" is the better outcome, and `settle` above is
                // what stops it happening.
                button.tap()
                let gone = XCTNSPredicateExpectation(
                    predicate: NSPredicate(format: "exists == false"), object: bar
                )
                if XCTWaiter().wait(for: [gone], timeout: 6) == .completed { return true }
                _ = UITestSession.scrollUntilHittable(button, in: app)
                continue
            }
            return true
        }
        return !bar.exists
    }

    /// **`openTab` returns as soon as the tab reports `isSelected`, and the CONTENT is still
    /// sliding.** The second run of this harness failed on
    /// *"Failed to not hittable: Button, {{10016.0, 563.3}…, 'taskDetailDeleteButton'"* — x≈10016
    /// is a whole screen-width times the tab index, i.e. the element was found on a page that had
    /// not arrived yet. `scrollUntilHittable` had reported it hittable a moment earlier, mid-slide.
    ///
    /// So every tab change here is followed by waiting for that tab's own root control to come to
    /// REST, not merely to exist.
    ///
    /// **And every anchor is a TYPED query with `.firstMatch`.** The third run failed on *"The
    /// Tools page never appeared"* while the page was plainly on screen: an accessibility
    /// identifier is inherited by a container's children (this repo's oldest UI-test trap), so
    /// `descendants(matching: .any)["toolsCard.places"]` resolves to several elements and an
    /// ambiguous query reports that it does not exist.
    @MainActor
    private func settle(_ anchor: XCUIElement, _ label: String) {
        XCTAssertTrue(
            anchor.waitForExistence(timeout: UITestSession.timeout), "\(label) never appeared"
        )
        let atRest = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isHittable == true"), object: anchor
        )
        XCTAssertEqual(
            XCTWaiter().wait(for: [atRest], timeout: UITestSession.timeout), .completed,
            "\(label) never came to rest on screen — the tab transition had not finished"
        )
    }

    private func attach(_ app: XCUIApplication, named name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}

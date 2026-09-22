//
//  TagsRecentlyDeletedRenderUITests.swift
//  ADHD LifeOSUITests
//
//  A render harness for `F-C4-TagsRecentlyDeleted`, not a test — the block's acceptance criteria
//  ask for `screenshots/recently-deleted-tags/`, and this is what produces it.
//  `RecentlyDeletedRenderUITests` is the model, and its §4 traps apply here verbatim: every step
//  waits on something POSITIVE, because `tap(_:untilGone:)` returns true WITHOUT TAPPING when the
//  doomed element is already absent, and `tap(_:untilExists:)` fails the same way from the other
//  side when a capsule left pending from an earlier action already satisfies it.
//
//  **Why the real app rather than previews.** The claim this folder exists to settle cannot be
//  drawn by any single view: deleting a tag in SETTINGS makes a chip vanish from a task on the
//  TASKS tab, and restoring it from a third screen in TOOLS puts that chip back — with no write to
//  the task at any point. Three screens, one document, and the interesting part is what does NOT
//  happen in between.
//
//  **The seeded ids are known** so every frame is of THAT tag and THAT task. "A chip is missing"
//  and "the chip I deleted is missing" are different claims, and only an id tells them apart.
//

import XCTest

final class TagsRecentlyDeletedRenderUITests: XCTestCase {

    private enum Fixture {
        static let taskTitle = "Ring the dentist about the referral"
        static let tagName = "errand"
        /// Differs from `tagName` by CASE alone — which is the whole point of the merge frames.
        /// The collision folds case and the app renders the stored case, so these two cannot both
        /// be live, and the survivor decides which spelling the user is left reading.
        static let rivalName = "Errand"
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// One account, one task, one tag: see the chip, delete the tag in Settings, watch the chip
    /// go, find the tag in Tools, restore it, watch the chip come back.
    ///
    /// Appearance is whatever the simulator is set to (`xcrun simctl ui booted appearance
    /// light|dark`), so the same journey produces both sets without two copies of it.
    @MainActor
    func testRenderTheRoundTripFromTagDeleteToRestore() throws {
        try UITestEmulator.skipUnlessRunning()
        let account = try UITestSession.createAccount(label: "tagsdeleted")
        let tagID = UUID()
        let taskID = UUID()
        try UITestSession.seedTag(id: tagID, name: Fixture.tagName, uid: account.uid)
        try UITestSession.seedTask(
            id: taskID, title: Fixture.taskTitle, uid: account.uid, tagIds: [tagID]
        )
        let app = try UITestSession.launchSignedIn(as: account)
        settle(app.buttons["quickCaptureButton"], "The signed-in tabs")

        renderTheChip(app, taskID: taskID, tagID: tagID, present: true, named: "00-the-task-wears-the-tag")
        deleteTheTag(app, tagID: tagID)
        renderTheChip(app, taskID: taskID, tagID: tagID, present: false, named: "03-the-chip-is-gone")
        restoreFromTheScreen(app, tagID: tagID)
        renderTheChip(app, taskID: taskID, tagID: tagID, present: true, named: "06-the-chip-is-back")
    }

    /// **The survivor alert gets its own run, and BOTH tags are seeded.** Driving the collision
    /// live would mean deleting a tag and then creating another with the same name, which puts the
    /// run back through two screens with a capsule already pending — and every signal that the
    /// delete landed would then be satisfiable by the first one. Seeding the state removes the
    /// interaction entirely: this run only has to open the screen and press Restore.
    @MainActor
    func testRenderTheSurvivorChoice() throws {
        try UITestEmulator.skipUnlessRunning()
        let account = try UITestSession.createAccount(label: "tagsurvivor")
        let deletedID = UUID()
        try UITestSession.seedTag(
            id: deletedID, name: Fixture.tagName, uid: account.uid, deletedAt: Date()
        )
        try UITestSession.seedTag(id: UUID(), name: Fixture.rivalName, uid: account.uid)
        let app = try UITestSession.launchSignedIn(as: account)
        settle(app.buttons["quickCaptureButton"], "The signed-in tabs")

        openTheScreen(app)
        let restore = app.buttons["recentlyDeletedRestore-tag-\(deletedID.uuidString)"]
        XCTAssertTrue(
            restore.waitForExistence(timeout: UITestSession.timeout),
            "The pre-stamped tag is not listed, so `fetchDeletedTags` did not find it"
        )
        // `.firstMatch`: an alert leaves a second match in the presenting hierarchy, so the bare
        // subscript is ambiguous and the tap fails with "Multiple matching elements found".
        let keepRestored = app.buttons["recentlyDeletedKeepRestored"].firstMatch
        guard UITestSession.tap(restore, untilExists: keepRestored) else {
            attach(app, named: "07-THE-SURVIVOR-ALERT-NEVER-OPENED")
            return XCTFail(
                "Restore did not raise the survivor alert, so a colliding restore either merged"
                    + " silently or left two live tags wearing one name"
            )
        }
        attach(app, named: "07-restoring-onto-a-taken-name-asks-which-spelling-survives")

        let empty = app.staticTexts["recentlyDeletedEmpty"].firstMatch
        guard UITestSession.tap(keepRestored, untilExists: empty) else {
            attach(app, named: "08-THE-MERGE-NEVER-LANDED")
            return XCTFail("Choosing a survivor left the row standing")
        }
        attach(app, named: "08-merged-and-the-list-is-empty")
    }

    // MARK: - The chip, on the task that never changed

    /// **The claim the whole block turns on.** The task document is written ONCE, at seed time,
    /// and never again — so a chip that appears, disappears and reappears is proof that hiding a
    /// tag is a property of the TAG's own stamp and nothing else. If the delete had stripped
    /// `tag_ids`, the restore could not put this chip back at all.
    @MainActor
    private func renderTheChip(
        _ app: XCUIApplication, taskID: UUID, tagID: UUID, present: Bool, named name: String
    ) {
        UITestSession.openTab("Tasks", in: app)
        settle(app.buttons["taskCreateButton"], "The Tasks list")
        // Not `app.buttons[...]`: the identifier sits on a CONTAINER and is inherited by its
        // children, so a typed subscript is ambiguous and reports "does not exist".
        // `RecentlyDeletedRenderUITests` reaches the same row the same way.
        let row = app.descendants(matching: .any)
            .matching(identifier: "taskRow-\(taskID.uuidString)").firstMatch
        _ = UITestSession.scrollUntilHittable(row, in: app)
        let nameField = app.textFields["taskDetailTitleField"].firstMatch
        guard UITestSession.tap(row, untilExists: nameField) else {
            attach(app, named: "\(name)-TASK-DETAIL-NEVER-OPENED")
            return XCTFail("Task detail never opened, so there is no chip row to photograph")
        }

        let chip = app.buttons["taskDetailTagChip-\(tagID.uuidString)"].firstMatch
        if present {
            XCTAssertTrue(
                chip.waitForExistence(timeout: UITestSession.timeout),
                "The task's tag chip is missing when it should be drawn"
            )
        } else {
            // **Asserted next to a PRESENCE**, the harness rule one file over: the add-tag chip
            // proves the tag row itself is rendered, so the absence of this one means something.
            XCTAssertTrue(
                app.buttons["taskDetailAddTagChip"].firstMatch.waitForExistence(
                    timeout: UITestSession.timeout
                ),
                "The tag row is not drawn at all, so a missing chip proves nothing"
            )
            XCTAssertFalse(chip.exists, "A deleted tag is still drawn as a chip on its task")
        }
        attach(app, named: name)
        UITestSession.openTab("Tasks", in: app)
    }

    // MARK: - The delete, in Settings, with no confirmation

    /// **One tap, and that is E's call of 2026-09-22 rather than an oversight.** The delete raises
    /// no alert now, so a harness written against the old flow would sit waiting for a dialog that
    /// is deliberately gone. The capsule appearing is what proves the write landed.
    @MainActor
    private func deleteTheTag(_ app: XCUIApplication, tagID: UUID) {
        UITestSession.openTab("Settings", in: app)
        let tagEditorRow = app.buttons["settingsTagEditorRow"].firstMatch
        _ = UITestSession.scrollUntilHittable(tagEditorRow, in: app)
        let list = app.otherElements["tagEditorList"].firstMatch
        guard UITestSession.tap(tagEditorRow, untilExists: list) else {
            attach(app, named: "01-TAG-EDITOR-NEVER-OPENED")
            return XCTFail("The Tag Editor never opened")
        }
        attach(app, named: "01-the-tag-editor-lists-it")

        let row = app.buttons["tagRow_\(tagID.uuidString.lowercased())"].firstMatch
        _ = UITestSession.scrollUntilHittable(row, in: app)
        let deleteButton = app.buttons["tagDeleteButton"].firstMatch
        guard UITestSession.tap(row, untilExists: deleteButton) else {
            attach(app, named: "02-TAG-DETAIL-NEVER-OPENED")
            return XCTFail("Tag detail never opened")
        }

        let capsule = app.otherElements["undoCapsule"].firstMatch
        guard UITestSession.tap(deleteButton, untilExists: capsule) else {
            attach(app, named: "02-THE-DELETE-NEVER-LANDED")
            return XCTFail(
                "Deleting the tag raised no capsule. Either the write failed, or a confirmation"
                    + " alert is back — E removed it on 2026-09-22 and it must not return."
            )
        }
        attach(app, named: "02-deleted-and-the-capsule-offers-undo")
    }

    // MARK: - Recently Deleted, and the way back

    @MainActor
    private func restoreFromTheScreen(_ app: XCUIApplication, tagID: UUID) {
        openTheScreen(app)
        let row = app.buttons["recentlyDeletedRow-tag-\(tagID.uuidString)"].firstMatch
        XCTAssertTrue(
            row.waitForExistence(timeout: UITestSession.timeout),
            "The deleted tag is not listed, so `fetchDeletedTags` did not reach it"
        )
        attach(app, named: "04-recently-deleted-holds-the-tag")

        let restore = app.buttons["recentlyDeletedRestore-tag-\(tagID.uuidString)"].firstMatch
        let empty = app.staticTexts["recentlyDeletedEmpty"].firstMatch
        guard UITestSession.tap(restore, untilExists: empty) else {
            attach(app, named: "05-THE-RESTORE-NEVER-LANDED")
            return XCTFail("Restore left the row standing")
        }
        attach(app, named: "05-restored-and-the-screen-is-empty-again")
    }

    /// Popped and re-pushed rather than reused, so the next visit re-runs the screen's `.task` and
    /// the frame is of a deterministic fetch — `RecentlyDeletedRenderUITests`' reasoning, and the
    /// re-tap IS the pop.
    @MainActor
    private func openTheScreen(_ app: XCUIApplication) {
        UITestSession.openTab("Tools", in: app)
        let screen = app.descendants(matching: .any).matching(identifier: "recentlyDeletedView").firstMatch
        if screen.waitForExistence(timeout: 3) {
            _ = UITestSession.tap(UITestSession.tabButton("Tools", in: app), untilGone: screen)
        }
        settle(app.buttons["toolsCard.places"].firstMatch, "The Tools page")
        let row = app.buttons["toolsRecentlyDeletedRow"].firstMatch
        _ = UITestSession.scrollUntilHittable(row, in: app)
        guard UITestSession.tap(row, untilExists: screen) else {
            attach(app, named: "RECENTLY-DELETED-NEVER-OPENED")
            return XCTFail("The Recently Deleted screen never opened from Tools")
        }
    }

    // MARK: - Attaching

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

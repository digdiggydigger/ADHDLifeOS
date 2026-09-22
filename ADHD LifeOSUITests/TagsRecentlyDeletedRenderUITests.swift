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

    /// **The block's central claim, driven end to end: a hidden tag's LINKS survive.** The task
    /// document is written ONCE, at seed time, and never again. Its tag arrives already stamped,
    /// so the chip is absent at first sight; restoring the tag from Tools — which writes one field
    /// on the TAG and nothing on the task — brings the chip back. Had the delete stripped
    /// `tag_ids`, that could not happen at all.
    ///
    /// **Seeded rather than deleted through the Tag Editor**, and that is a strength rather than a
    /// shortcut: driving the delete would prove the button works, whereas this isolates the one
    /// thing the block actually changed. The Tag Editor's own delete has its own run below.
    ///
    /// Appearance is whatever the simulator is set to (`xcrun simctl ui booted appearance
    /// light|dark`), so the same journey produces both sets without two copies of it.
    @MainActor
    func testRenderTheRestoreThatPutsTheChipBack() throws {
        try UITestEmulator.skipUnlessRunning()
        let account = try UITestSession.createAccount(label: "tagsrestore")
        let tagID = UUID()
        let taskID = UUID()
        try UITestSession.seedTag(
            id: tagID, name: Fixture.tagName, uid: account.uid, deletedAt: Date()
        )
        try UITestSession.seedTask(
            id: taskID, title: Fixture.taskTitle, uid: account.uid, tagIds: [tagID]
        )
        let app = try UITestSession.launchSignedIn(as: account)
        XCTAssertTrue(
            app.buttons["quickCaptureButton"].waitForExistence(timeout: UITestSession.timeout),
            "The signed-in tabs never appeared"
        )

        renderTheChip(
            app, taskID: taskID, tagID: tagID, present: false,
            named: "00-the-tag-is-hidden-so-the-task-shows-no-chip"
        )
        restoreFromTheScreen(app, tagID: tagID)
        renderTheChip(
            app, taskID: taskID, tagID: tagID, present: true,
            named: "03-restored-and-the-chip-is-back-with-no-write-to-the-task"
        )
    }

    /// **The Tag Editor's own delete, and the capsule E chose in place of the confirmation.**
    /// Its own run because it is the only journey that goes through Settings — a SHEET from
    /// Today, with the Tag Editor pushed inside it, two levels below a modal.
    @MainActor
    func testRenderTheTagEditorDelete() throws {
        try UITestEmulator.skipUnlessRunning()
        let account = try UITestSession.createAccount(label: "tagsdelete")
        let tagID = UUID()
        let taskID = UUID()
        try UITestSession.seedTag(id: tagID, name: Fixture.tagName, uid: account.uid)
        try UITestSession.seedTask(
            id: taskID, title: Fixture.taskTitle, uid: account.uid, tagIds: [tagID]
        )
        let app = try UITestSession.launchSignedIn(as: account)
        XCTAssertTrue(
            app.buttons["quickCaptureButton"].waitForExistence(timeout: UITestSession.timeout),
            "The signed-in tabs never appeared"
        )

        deleteTheTag(app, tagID: tagID)
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
        // **`waitForExistence`, NOT `settle`.** The capture disc EXISTS from the first frame and
        // is never reported hittable by XCUITest — it is a floating overlay outside the tab
        // content — so waiting on `isHittable` here times out against an app that is running
        // perfectly. `RecentlyDeletedRenderUITests` waits on existence alone for the same anchor;
        // this harness used `settle` on its first run and both journeys died at 144s and 166s
        // having photographed nothing.
        XCTAssertTrue(
            app.buttons["quickCaptureButton"].waitForExistence(timeout: UITestSession.timeout),
            "The signed-in tabs never appeared"
        )

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

        // **Scroll to the tags SECTION first, and anchor on the add-tag chip rather than on the
        // tag's own.** A `Form` builds its rows lazily, so a chip below the fold is genuinely
        // absent from the accessibility hierarchy — the first run of this harness read that as
        // "the tag was never attached" and failed on a build where everything was correct.
        // Anchoring on `taskDetailAddTagChip` also gives the absent case its PRESENCE to be
        // asserted against, which is `RecentlyDeletedRenderUITests`' rule.
        let addChip = app.buttons["taskDetailAddTagChip"].firstMatch
        _ = UITestSession.scrollUntilHittable(addChip, in: app)
        XCTAssertTrue(
            addChip.waitForExistence(timeout: UITestSession.timeout),
            "The task's tag row is not drawn at all, so nothing about a chip proves anything"
        )

        let chip = app.buttons["taskDetailTagChip-\(tagID.uuidString)"].firstMatch
        if present {
            XCTAssertTrue(
                chip.waitForExistence(timeout: UITestSession.timeout),
                "The task's tag chip is missing when it should be drawn"
            )
        } else {
            XCTAssertFalse(chip.exists, "A deleted tag is still drawn as a chip on its task")
        }
        attach(app, named: name)
        // **Pop to the Tasks root by tapping the TAB BUTTON, not via `openTab`.** `openTab`
        // returns early when the tab is already selected, so from a pushed task detail it never
        // taps and never pops — the run then carried task detail into the next step and the Today
        // gear reported not hittable at a perfectly sensible frame. The re-tap IS the pop
        // (`.tabRoot(.tasks, isAtRoot:onPopToRoot:)`), which is how `RecentlyDeletedRenderUITests`
        // re-enters its own screen.
        //
        // **And `untilExists:`, NEVER `untilGone: nameField`.** This harness wrote that first and
        // it is trap #1 from `RecentlyDeletedRenderUITests`' own header, walked into again:
        // scrolling the Form to the tags section takes `taskDetailTitleField` OUT of the
        // hierarchy, so `untilGone:` was already satisfied, `tap` returned true on its first line
        // WITHOUT TAPPING, and the run carried task detail into the next step. An absence that
        // the previous step caused is not a signal.
        let createButton = app.buttons["taskCreateButton"].firstMatch
        _ = UITestSession.tap(UITestSession.tabButton("Tasks", in: app), untilExists: createButton)
        settle(createButton, "The Tasks list after popping back")
    }

    // MARK: - The delete, in Settings, with no confirmation

    /// **Settings is a SHEET from Today, not a tab**, and the Tag Editor is pushed inside it — so
    /// this is two navigation levels below a modal. The first version of this harness called
    /// `openTab("Settings")` and failed with "The Settings tab is missing from the tab bar", which
    /// is the tab bar telling the truth.
    ///
    /// **One tap deletes, and that is E's call of 2026-09-22 rather than an oversight.** The
    /// delete raises no alert now, so a harness written against the old flow would sit waiting for
    /// a dialog that is deliberately gone. The capsule appearing is what proves the write landed —
    /// and asserting it HERE, inside the sheet, is deliberate: if an app-level overlay cannot draw
    /// above a sheet then E's chosen replacement for the confirmation shows nothing at the moment
    /// of the delete, and that is a finding rather than something for a harness to work around.
    @MainActor
    private func deleteTheTag(_ app: XCUIApplication, tagID: UUID) {
        UITestSession.openTab("Today", in: app)
        let settingsButton = app.buttons["settingsButton"].firstMatch
        XCTAssertTrue(
            settingsButton.waitForExistence(timeout: UITestSession.timeout),
            "Today's gear never appeared, so Settings is unreachable"
        )
        // **Wait on the SHEET, not on the row inside it.** The first version waited for
        // `settingsTagEditorRow`, which is section 5 of Settings and therefore below the fold and
        // absent from the hierarchy — so the gear was tapped, the sheet opened correctly, and the
        // harness went on retrying against a row it could not have seen yet. The diagnostic frame
        // it filed shows Settings open, which is what settled it.
        //
        // The retry is still needed for the gear itself: Today's board loads asynchronously and
        // re-lays out under it, so hittable at time T says nothing about time T+ε, and
        // `UITestSession.tap` surfaces XCUITest's own "Failed to not hittable".
        let done = app.buttons["settingsDoneButton"].firstMatch
        guard tapWhenHittable(settingsButton, untilExists: done, in: app) else {
            attach(app, named: "01-SETTINGS-NEVER-OPENED")
            return XCTFail("The Settings sheet never opened from Today's gear")
        }
        let tagEditorRow = app.descendants(matching: .any)
            .matching(identifier: "settingsTagEditorRow").firstMatch
        _ = UITestSession.scrollUntilHittable(tagEditorRow, in: app)

        let list = app.descendants(matching: .any).matching(identifier: "tagEditorList").firstMatch
        guard UITestSession.tap(tagEditorRow, untilExists: list) else {
            attach(app, named: "01-TAG-EDITOR-NEVER-OPENED")
            return XCTFail("The Tag Editor never opened")
        }
        attach(app, named: "01-the-tag-editor-lists-it")

        let row = app.descendants(matching: .any)
            .matching(identifier: "tagRow_\(tagID.uuidString.lowercased())").firstMatch
        _ = UITestSession.scrollUntilHittable(row, in: app)
        let deleteButton = app.buttons["tagDeleteButton"].firstMatch
        guard UITestSession.tap(row, untilExists: deleteButton) else {
            attach(app, named: "02-TAG-DETAIL-NEVER-OPENED")
            return XCTFail("Tag detail never opened")
        }
        _ = UITestSession.scrollUntilHittable(deleteButton, in: app)

        let capsule = app.descendants(matching: .any).matching(identifier: "undoCapsule").firstMatch
        guard UITestSession.tap(deleteButton, untilExists: capsule) else {
            attach(app, named: "02-THE-DELETE-LANDED-BUT-NO-CAPSULE")
            return XCTFail(
                "Deleting the tag showed no capsule. Either the write failed, or a confirmation"
                    + " alert is back (E removed it on 2026-09-22 and it must not return), or the"
                    + " app-level capsule cannot draw above the Settings SHEET — which would mean"
                    + " E's chosen replacement for the confirmation shows nothing at the moment of"
                    + " the delete."
            )
        }
        attach(app, named: "02-deleted-and-the-capsule-offers-undo")

        // Back out of the sheet so the rest of the journey can reach the tabs: the Tag Editor is
        // PUSHED inside it, so Settings' own Done button is not on screen until we pop.
        let back = app.navigationBars.buttons.element(boundBy: 0)
        _ = UITestSession.tap(back, untilExists: done)
        _ = UITestSession.tap(done, untilGone: done)
    }

    // MARK: - Recently Deleted, and the way back

    @MainActor
    private func restoreFromTheScreen(_ app: XCUIApplication, tagID: UUID) {
        openTheScreen(app)
        // **Anchored on the RESTORE button, not on the row.** The row's identifier sits on a
        // container and is inherited by its children, and a `buttons[...]` subscript for it found
        // nothing while the button inside it was there all along — which the survivor journey
        // proves, since it has always addressed this screen by the same button.
        let restore = app.buttons["recentlyDeletedRestore-tag-\(tagID.uuidString)"].firstMatch
        _ = UITestSession.scrollUntilHittable(restore, in: app)
        XCTAssertTrue(
            restore.waitForExistence(timeout: UITestSession.timeout),
            "The deleted tag is not listed, so `fetchDeletedTags` did not reach it"
        )
        attach(app, named: "01-recently-deleted-holds-the-tag")

        let empty = app.staticTexts["recentlyDeletedEmpty"].firstMatch
        guard UITestSession.tap(restore, untilExists: empty) else {
            attach(app, named: "02-THE-RESTORE-NEVER-LANDED")
            return XCTFail("Restore left the row standing")
        }
        attach(app, named: "02-restored-and-the-screen-is-empty-again")
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

    /// Taps only in the instant the element reports itself hittable, and re-checks rather than
    /// waiting once. See the Today gear's note above for why a single wait is not enough.
    @MainActor
    private func tapWhenHittable(
        _ element: XCUIElement, untilExists expected: XCUIElement, in app: XCUIApplication,
        attempts: Int = 12
    ) -> Bool {
        guard element.waitForExistence(timeout: UITestSession.timeout) else { return false }
        // Bring Today's header into view first: the gear sits in it, and a board scrolled down
        // moves it. Cheap, and it removes one of the two reasons a tap can be refused.
        _ = UITestSession.scrollUntilHittable(element, in: app)
        for _ in 1...attempts {
            if expected.exists { return true }
            if element.isHittable {
                element.tap()
                if expected.waitForExistence(timeout: 3) { return true }
            } else {
                _ = XCTWaiter().wait(
                    for: [XCTNSPredicateExpectation(
                        predicate: NSPredicate(format: "isHittable == true"), object: element
                    )],
                    timeout: 3
                )
            }
        }
        if !expected.exists { attach(app, named: "01-TODAY-GEAR-NEVER-TAPPABLE") }
        return expected.exists
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

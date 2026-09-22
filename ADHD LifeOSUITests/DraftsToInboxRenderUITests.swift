//
//  DraftsToInboxRenderUITests.swift
//  ADHD LifeOSUITests
//
//  A render harness for `F-C2-DraftsToInbox`, not a test — the block's one unmet acceptance
//  criterion was `screenshots/drafts-to-inbox/`, and this is what produces it. It asserts only
//  enough to fail loudly when it photographs the wrong thing; its job is to drive the REAL app
//  through each composer and attach a frame, on the model of `UndoCapsuleRenderUITests`.
//
//  **Why the real app rather than a preview.** Every frame here is about a TRANSITION between two
//  screens — text typed in a composer turning up as a capture in the inbox, a left-edge swipe
//  popping a detail that used to raise a "Discard changes?" alert. A preview can draw the composer
//  and the inbox; it cannot show that closing one fills the other, which is the whole claim.
//
//  **Four ordering constraints, all learned from `F-C2`'s own shape:**
//  1. **The capsule is ONE slot, and filing a draft spends whatever was pending** (the block's
//     named accepted cost). So each composer's capsule is photographed BEFORE the next composer
//     is opened, never in a batch at the end — a second pass would photograph the third draft's
//     capsule three times.
//  1b. **Which means the JOURNAL composer has to go FIRST**, because on the Journal the capsule
//     stands in for the pencil disc rather than sitting beside it — so with any capsule pending
//     there is no compose control to tap at all. See the journey below.
//  2. **`QuickCaptureView` is presented twice** — a `.fullScreenCover` from the capture disc and a
//     `.sheet` from the Capture Inbox. The disc route is the one photographed, because it is the
//     one a user meets first; `.onDisappear` is what makes both work and neither frame would show
//     the difference.
//  3. **Reopen is addressed by IDENTIFIER, never by its word.** `undoCapsuleButton` is stable
//     across every `RecentActionKind`; the LABEL is "Undo" for five kinds and "Reopen" for the
//     sixth. `SignedInJourneyUITests` finds the control by the word "Undo" deliberately, which is
//     precisely why a harness that wants the Reopen case must not copy that.
//
//  Committed deliberately rather than deleted: arc C's later blocks file drafts through the same
//  seam (F-C3 puts a soft-deleted item behind the same capsule), so the next block re-renders
//  these frames rather than rebuilding the drive.
//

import XCTest

final class DraftsToInboxRenderUITests: XCTestCase {

    /// Distinct text per composer, so `08-` is legible as three separate drafts rather than three
    /// identical rows — a frame whose whole point is "all three arrived" has to show which is which.
    private enum Draft {
        static let note = "Draft from the note composer"
        static let task = "Draft from the task composer"
        static let journal = "Draft from the journal composer"
        /// Typed into the seeded task's title. Asserted by CONTAINS rather than by composing an
        /// expected string — see the wait in the swipe-back journey for why the caret's landing
        /// place is not something a render harness gets to depend on.
        static let titleEdit = " — and the visa"
        /// The seeded title's opening words, so "the edit survived" and "this is still the task
        /// that was seeded" are two separate assertions rather than one hopeful one.
        static let titleStem = "Renew the"
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - The three composers, in one run

    /// One account, three composers, one inbox. Appearance is whatever the simulator is set to
    /// (`xcrun simctl ui booted appearance light|dark`) and the text size is whatever
    /// `content_size` was set to before the run, so the same journey produces the light, dark and
    /// AX3 sets without three copies of it — `UndoCapsuleRenderUITests`' arrangement, and the
    /// reason that file's header warns against the launch-argument route.
    @MainActor
    func testRenderEachComposerFilingItsDraft() throws {
        try UITestEmulator.skipUnlessRunning()
        let account = try UITestSession.createAccount(label: "draftstoinbox")
        let app = try UITestSession.launchSignedIn(as: account)
        XCTAssertTrue(
            app.buttons["quickCaptureButton"].waitForExistence(timeout: UITestSession.timeout),
            "The signed-in tabs never appeared"
        )

        // **The JOURNAL goes first, and the first run of this harness is why.** On the Journal
        // the capsule does not sit beside the pencil disc — it STANDS IN for it (E's `F-C1`
        // Step 0 answer 4, the claim `screenshots/undo-capsule/03-` was rendered to confirm). So
        // with any capsule pending there is no `journalComposeButton` to tap, and a run that
        // filed a draft from another composer first sat waiting for a control the app had
        // deliberately replaced. The capture disc is unaffected — it never moves for the capsule
        // — so the note and task composers are reachable with one pending and follow in any order.
        renderJournalComposer(app)
        renderNoteComposer(app)
        renderTaskComposer(app)
        renderReopen(app)
        renderInbox(app)
    }

    // MARK: - The note composer, through the capture disc

    @MainActor
    private func renderNoteComposer(_ app: XCUIApplication) {
        let noteTile = app.buttons["captureFan-note"]
        guard UITestSession.tap(app.buttons["quickCaptureButton"], untilExists: noteTile) else {
            return XCTFail("The capture fan never opened, so the note composer cannot be reached")
        }
        let field = app.textFields["quickCaptureContentField"]
        guard UITestSession.tap(noteTile, untilExists: field) else {
            return XCTFail("The note tile never opened the quick-capture composer")
        }
        UITestSession.focusAndType(field, text: Draft.note, in: app)
        attach(app, named: "03-note-composer-typed")

        closeAndPhotographTheCapsule(
            app,
            close: app.buttons["quickCaptureCloseButton"],
            field: field,
            named: "04-note-closed-capsule-kept-in-your-inbox"
        )
    }

    // MARK: - Reopen — E's Step 0 answer 1, "open it in the inbox"

    /// The door, photographed where it lands. Tapping Reopen must switch to the Captures tab AND
    /// present that capture's detail; a frame of the inbox alone would not distinguish "opened the
    /// capture" from "opened the tab", which is the half of E's answer that could silently not work.
    @MainActor
    private func renderReopen(_ app: XCUIApplication) {
        let reopen = app.buttons["undoCapsuleButton"]
        guard reopen.waitForExistence(timeout: UITestSession.timeout) else {
            return XCTFail("No capsule was pending, so Reopen cannot be photographed")
        }
        let detail = app.descendants(matching: .any)["captureDetailView"]
        guard UITestSession.tap(reopen, untilExists: detail) else {
            attach(app, named: "07-reopen-NEVER-LANDED")
            return XCTFail("Reopen did not open the filed capture's detail in the inbox")
        }
        attach(app, named: "07-reopen-lands-on-the-filed-capture")

        // **A PUSHED destination, not a sheet, and the first run of this harness proved it the
        // expensive way** — `app.swipeDown()` sat waiting 45 seconds for a sheet to dismiss that
        // was never a sheet. `CaptureInboxView.swift:47-49` says so in its own words: the
        // inspected capture is optional state plus a `navigationDestination`, the `TaskListView`
        // precedent. So the way back is the Captures tab RE-TAP, which
        // `.tabRoot(.captures, isAtRoot:onPopToRoot:)` turns into a pop — the same mechanism
        // `SearchRowDepthJourneyUITests` uses to pop a task's detail.
        //
        // The slot is tapped DIRECTLY rather than through `openTab`, which returns early when its
        // tab is already selected — and after Reopen, Captures is exactly that.
        let capturesTab = UITestSession.tabButton("Captures", in: app)
        _ = UITestSession.tap(capturesTab, untilGone: detail)
    }

    // MARK: - The task composer

    @MainActor
    private func renderTaskComposer(_ app: XCUIApplication) {
        UITestSession.openTab("Tasks", in: app)
        let field = app.textFields["taskCreateTitleField"]
        guard UITestSession.tap(app.buttons["taskCreateButton"], untilExists: field) else {
            return XCTFail("The task composer never opened from Tasks")
        }
        UITestSession.focusAndType(field, text: Draft.task, in: app)
        attach(app, named: "05-task-composer-typed")

        closeAndPhotographTheCapsule(
            app,
            close: app.buttons["taskCreateCloseButton"],
            field: field,
            named: "06-task-closed-capsule-kept-in-your-inbox"
        )
    }

    // MARK: - The journal composer

    @MainActor
    private func renderJournalComposer(_ app: XCUIApplication) {
        UITestSession.openTab("Journal", in: app)
        let field = app.textFields["logComposerBodyField"]
        guard UITestSession.tap(app.buttons["journalComposeButton"], untilExists: field) else {
            return XCTFail("The journal composer never opened")
        }
        UITestSession.focusAndType(field, text: Draft.journal, in: app)
        attach(app, named: "01-journal-composer-typed")

        closeAndPhotographTheCapsule(
            app,
            close: app.buttons["logComposerCloseButton"],
            field: field,
            named: "02-journal-closed-capsule-kept-in-your-inbox"
        )
    }

    // MARK: - The inbox afterwards

    /// All three drafts, as ordinary `.note` captures. **Counted, not eyeballed**: the frame is
    /// evidence of "three arrived", and a run where one composer silently filed nothing would
    /// produce a perfectly plausible-looking photograph of two rows.
    @MainActor
    private func renderInbox(_ app: XCUIApplication) {
        UITestSession.openTab("Captures", in: app)
        let rows = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'captureRow-'")
        )
        XCTAssertTrue(
            rows.firstMatch.waitForExistence(timeout: UITestSession.timeout),
            "The inbox listed no captures at all, so no draft was filed by any composer"
        )
        // Polled rather than read once: the inbox refreshes on appear and the third write may
        // still be in flight when the tab settles.
        let three = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "count >= 3"), object: rows
        )
        let arrived = XCTWaiter().wait(for: [three], timeout: UITestSession.timeout) == .completed
        attach(app, named: "08-inbox-holds-all-three-drafts")
        XCTAssertTrue(
            arrived,
            "The inbox holds \(rows.count) capture rows, not the three drafts this run filed"
        )
    }

    // MARK: - Task detail: the edit that saves itself, and the gesture that was blocked

    /// The other half of `F-C2`: the blocking *"Discard changes?"* alert is gone, the left-edge
    /// swipe-back it disabled is restored, and leaving commits the edit.
    ///
    /// **A seeded task with a known id**, the `SearchRowDepthJourneyUITests` arrangement, so the
    /// run edits THAT row and can re-open it afterwards to prove the write landed rather than
    /// trusting a list label that a stale render could also produce.
    @MainActor
    func testRenderTaskDetailSwipeBackSavingTheEdit() throws {
        try UITestEmulator.skipUnlessRunning()
        let account = try UITestSession.createAccount(label: "draftsswipeback")
        let taskID = UUID()
        try UITestSession.seedTask(id: taskID, title: "Renew the passport", uid: account.uid)
        let app = try UITestSession.launchSignedIn(as: account)

        UITestSession.openTab("Tasks", in: app)
        let row = app.descendants(matching: .any)["taskRow-\(taskID.uuidString)"]
        XCTAssertTrue(
            row.waitForExistence(timeout: UITestSession.timeout), "The seeded task never listed"
        )
        let titleField = app.textFields["taskDetailTitleField"]
        XCTAssertTrue(UITestSession.tap(row, untilExists: titleField), "Task detail never opened")

        // **`focusAndType` APPENDS** (`ui-journey-harness`), which is what is wanted here: the
        // edit has to be visibly an edit of the seeded title rather than a new title that could
        // have come from anywhere.
        UITestSession.focusAndType(titleField, text: Draft.titleEdit, in: app)
        attach(app, named: "09-task-detail-edited-and-save-never-tapped")

        swipeBackFromTheLeftEdge(app)
        XCTAssertTrue(
            titleField.waitForNonExistence(timeout: UITestSession.timeout),
            "The left-edge swipe did not pop task detail — the gesture is still blocked"
        )
        // The assertion the whole block turns on: before `F-C2` this gesture raised
        // "Discard changes?" and the swipe went nowhere.
        XCTAssertFalse(
            app.alerts.firstMatch.exists, "A dialog was raised on the way out of task detail"
        )
        attach(app, named: "10-swipe-back-popped-with-no-discard-dialog")

        XCTAssertTrue(UITestSession.tap(row, untilExists: titleField), "Task detail never reopened")
        // **Waited, not read once.** The autosave fires from `.onDisappear` and the reopened
        // screen re-fetches the document, so on a fast tap-back the read can beat the write. A
        // bare equality here would flake with a message reading like a broken autosave — and the
        // wait also means the FRAME below shows the saved title rather than a half-loaded field.
        //
        // **CONTAINS, not equality, and the AX3 pass is why.** `focusAndType` taps the field to
        // focus it, and at accessibility text sizes that tap lands BETWEEN words rather than past
        // the end of a longer-drawn string — the AX3 run saved "Renew the — and the visa
        // passport" and the equality assertion reported "the edit did not autosave", which was
        // false in the one way a harness must never be wrong. Where the caret went is the
        // harness's business; that the edit SURVIVED is the claim. Both halves are asserted, so a
        // field that had been cleared and replaced could not pass as an edit.
        let saved = XCTNSPredicateExpectation(
            predicate: NSPredicate(
                format: "value CONTAINS %@ AND value CONTAINS %@", Draft.titleEdit, Draft.titleStem
            ),
            object: titleField
        )
        let landed = XCTWaiter().wait(for: [saved], timeout: UITestSession.timeout) == .completed
        attach(app, named: "11-reopened-the-edit-saved-itself")
        XCTAssertTrue(
            landed,
            "The title reads \(String(describing: titleField.value)) — the edit did not autosave"
        )
    }

    // MARK: - Driving

    /// Closes a composer that has text in it and photographs the capsule that catches it.
    ///
    /// `untilGone` rather than a bare tap: a Close tap taken while the keyboard is still animating
    /// is a silent no-op, and the frame after it would be of the composer rather than the capsule.
    @MainActor
    private func closeAndPhotographTheCapsule(
        _ app: XCUIApplication, close: XCUIElement, field: XCUIElement, named name: String
    ) {
        guard UITestSession.tap(close, untilGone: field) else {
            attach(app, named: "\(name)-CLOSE-NEVER-LANDED")
            return XCTFail("Close did not dismiss the composer, so no draft was filed")
        }
        let capsule = app.otherElements["undoCapsule"]
        XCTAssertTrue(
            capsule.waitForExistence(timeout: UITestSession.timeout),
            "Closing a composer with typed text showed no capsule, so the draft was discarded"
        )
        attach(app, named: name)
    }

    /// The interactive pop gesture, from the very edge of the screen.
    ///
    /// **0.01 rather than 0.0**: the system's pop gesture recogniser owns a narrow strip at the
    /// leading edge, and a drag begun at exactly 0 lands outside the window on some runs. The
    /// press is held briefly before the drag so the gesture is recognised as a drag rather than
    /// swallowed as a tap.
    @MainActor
    private func swipeBackFromTheLeftEdge(_ app: XCUIApplication) {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        let finish = app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: finish)
    }

    @MainActor
    private func attach(_ app: XCUIApplication, named name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}

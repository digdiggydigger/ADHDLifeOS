//
//  TodayOneCardRenderUITests.swift
//  ADHD LifeOSUITests
//
//  `F-E3-OneCardToday`'s evidence harness — the frames for `screenshots/today-one-card/`.
//
//  E's round 3, *"C · One next thing. Today shows ONE card, then a short 'then' list, and nothing
//  else"*, and round 5a's H1 card. Unit tests pin the slot order, the stores and every string; only
//  the real screen shows the card where it sits, the pin and "Not this one" answering a tap, the
//  next step saved from the card, the capsule after a close, the Resume card, and the two doors
//  that moved (Nudges to Tools, a second Week review door on Areas).
//
//  Run deliberately, one appearance per run: set `xcrun simctl ui … appearance` / `content_size`
//  before the run and name the frames with `TODAY_RENDER_TAG` (L / D / A), passed as
//  `TEST_RUNNER_TODAY_RENDER_TAG`. At the accessibility tag the harness ASSERTS round 5a's
//  "Start above the fold" rather than photographing it.
//

import XCTest

final class TodayOneCardRenderUITests: XCTestCase {

    private var tag: String { ProcessInfo.processInfo.environment["TODAY_RENDER_TAG"] ?? "X" }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - The one card, walked through its states

    @MainActor
    func testRenderTheOneCard() throws {
        try UITestEmulator.skipUnlessRunning()
        let account = try UITestSession.createAccount(label: "e3onecard")
        let ids = try seedToday(uid: account.uid)
        let app = try UITestSession.launchSignedIn(as: account)

        try renderSuggested(app)
        if tag == "A" { return }
        renderPinned(app)
        renderNotThisOne(app, skipped: ids.reply)
        renderNextStep(app)
        renderClosed(app)
        renderTheDoorsThatMoved(app)
    }

    /// 1 — Suggested: the shortest due task (15 min), "Not this one", the gain line on Close.
    @MainActor
    private func renderSuggested(_ app: XCUIApplication) throws {
        let card = element("homeTodayCard", in: app)
        XCTAssertTrue(card.waitForExistence(timeout: UITestSession.timeout), "Today drew no one card")
        UITestSession.dismissSystemPasswordPromptIfPresent()
        let skip = app.buttons["homeNotThisOneButton"].firstMatch
        XCTAssertTrue(skip.waitForExistence(timeout: UITestSession.timeout), "No \"Not this one\" when suggested")
        let close = app.buttons["homeCloseTaskButton"].firstMatch
        let start = app.buttons["homeStartSessionButton"].firstMatch
        XCTAssertEqual(start.label, "Start 15 min", "Start does not name the sprint it launches")
        XCTAssertEqual(close.frame.height, skip.frame.height, accuracy: 0.5, "The quiet pair is ragged")
        print("MEASURE today-\(tag) card=\(card.frame) start=\(start.frame) close=\(close.frame) skip=\(skip.frame)")
        if tag == "A" { try assertStartAboveTheFold(start, in: app) }
        attach(app, named: "01-suggested-\(tag)")
    }

    /// 2 — Pinned: the corner pin, then the eyebrow says so; then unpinned again.
    @MainActor
    private func renderPinned(_ app: XCUIApplication) {
        let pin = app.buttons["homeTodayPinButton"].firstMatch
        XCTAssertTrue(UITestSession.tap(pin, untilExists: app.buttons["Unpin"].firstMatch), "The pin did not pin")
        XCTAssertFalse(app.buttons["homeNotThisOneButton"].firstMatch.exists, "A pinned card offers \"Not this one\"")
        attach(app, named: "02-pinned-\(tag)")
        XCTAssertTrue(
            UITestSession.tap(app.buttons["Unpin"].firstMatch, untilExists: app.buttons["Pin to Today"].firstMatch),
            "Unpinning did not unpin"
        )
    }

    /// 3 — "Not this one": the next due task takes the card and the skipped one is back in the list.
    @MainActor
    private func renderNotThisOne(_ app: XCUIApplication, skipped: UUID) {
        let skippedRow = app.buttons["homeThenRow-\(skipped.uuidString)"].firstMatch
        XCTAssertTrue(
            UITestSession.tap(app.buttons["homeNotThisOneButton"].firstMatch, untilExists: skippedRow),
            "The skipped task did not come back in the \"then\" list"
        )
        XCTAssertEqual(app.buttons["homeStartSessionButton"].firstMatch.label, "Start 30 min")
        attach(app, named: "03-not-this-one-\(tag)")
    }

    /// 4 — The next step, typed on the card and saved by Return.
    @MainActor
    private func renderNextStep(_ app: XCUIApplication) {
        let field = element("homeTodayNextStepField", in: app)
        UITestSession.focusAndType(field, text: "Book the photo booth\n", in: app)
        let saved = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", "Book the photo booth"), object: field
        )
        XCTAssertEqual(XCTWaiter().wait(for: [saved], timeout: UITestSession.timeout), .completed,
                       "The next step typed on the card did not survive (reads \"\(field.value ?? "nil")\")")
        attach(app, named: "04-next-step-on-the-card-\(tag)")
    }

    /// 5 — Close from the card: the undo capsule, and the done line counts it.
    @MainActor
    private func renderClosed(_ app: XCUIApplication) {
        let doneLine = app.buttons["homeWeekReviewRow"].firstMatch
        let capsule = app.buttons["undoCapsuleButton"].firstMatch
        XCTAssertTrue(
            UITestSession.tap(app.buttons["homeCloseTaskButton"].firstMatch, untilExists: capsule),
            "Closing from the card raised no undo capsule"
        )
        let counted = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label BEGINSWITH %@", "1 done today"), object: doneLine
        )
        XCTAssertEqual(XCTWaiter().wait(for: [counted], timeout: UITestSession.timeout), .completed,
                       "The done line did not count the close (reads \"\(doneLine.label)\")")
        print("MEASURE today-\(tag) doneLine=\(doneLine.frame) label=\(doneLine.label)")
        attach(app, named: "05-closed-from-the-card-\(tag)")
    }

    /// 6–8 — The Nudges door beside Routines on Tools; the second Week review door at the top of
    /// Areas, and the review it opens.
    @MainActor
    private func renderTheDoorsThatMoved(_ app: XCUIApplication) {
        UITestSession.openTab("Tools", in: app)
        let nudges = app.buttons["toolsNudgesRow"].firstMatch
        UITestSession.scrollUntilHittable(nudges, in: app)
        XCTAssertTrue(nudges.exists, "Tools draws no Nudges row")
        print("MEASURE today-\(tag) toolsNudgesRow=\(nudges.frame) label=\(nudges.label)")
        attach(app, named: "06-tools-nudges-row-\(tag)")

        UITestSession.openTab("Areas", in: app)
        let areasDoor = app.buttons["areasWeekReviewRow"].firstMatch
        XCTAssertTrue(areasDoor.waitForExistence(timeout: UITestSession.timeout), "Areas draws no Week review row")
        print("MEASURE today-\(tag) areasWeekReviewRow=\(areasDoor.frame)")
        attach(app, named: "07-areas-week-review-row-\(tag)")
        let review = app.descendants(matching: .any).matching(identifier: "weekReviewHeader").firstMatch
        XCTAssertTrue(UITestSession.tap(areasDoor, untilExists: review), "The Areas door opened no week review")
        attach(app, named: "08-week-review-from-areas-\(tag)")
    }

    // MARK: - The Resume card

    /// A PAUSED sprint takes the card (round 4a, idea 4). Seeded at launch, paused, because a
    /// running countdown would finish mid-journey and move what is being photographed.
    @MainActor
    func testRenderTheResumeCard() throws {
        try UITestEmulator.skipUnlessRunning()
        let account = try UITestSession.createAccount(label: "e3resume")
        _ = try seedToday(uid: account.uid)
        let app = try UITestSession.launchSignedIn(
            as: account,
            launchArguments: UITestSession.pausedSprintLaunchArguments(taskTitle: "Draft the brief", collapsed: true)
        )
        let resume = app.buttons["homeResumeSprintButton"].firstMatch
        XCTAssertTrue(resume.waitForExistence(timeout: UITestSession.timeout), "A paused sprint did not take the card")
        UITestSession.dismissSystemPasswordPromptIfPresent()
        XCTAssertFalse(
            app.buttons["homeNotThisOneButton"].firstMatch.exists, "The Resume card offers \"Not this one\""
        )
        print("MEASURE today-\(tag) resume=\(resume.frame)")
        attach(app, named: "09-resume-card-\(tag)")
    }

    // MARK: - Plumbing

    private struct Seeded {
        let reply: UUID
        let passport: UUID
    }

    /// One Work and one Home area — which also stands the first-run seed down, so Today shows
    /// exactly this — and four tasks: two due today (15 and 30 min), one overdue, one undated.
    private func seedToday(uid: String) throws -> Seeded {
        let work = UUID()
        let home = UUID()
        try seedArea(id: work, name: "Work", colour: "💼", order: 0, uid: uid)
        try seedArea(id: home, name: "Home", colour: "🏠", order: 1, uid: uid)
        let reply = UUID()
        let passport = UUID()
        let now = Date()
        try seedTask(id: reply, title: "Reply to Priya about the Q4 roadmap", due: now, minutes: 15, area: work,
                     nextStep: "Say yes to the date, ask who owns the spec", uid: uid)
        try seedTask(id: passport, title: "Renew passport", due: now, minutes: 30, area: home, nextStep: nil, uid: uid)
        try seedTask(id: UUID(), title: "Pay the council tax instalment", due: now.addingTimeInterval(-86_400),
                     minutes: nil, area: home, nextStep: nil, uid: uid)
        try seedTask(id: UUID(), title: "Call Mum back", due: nil, minutes: nil, area: nil, nextStep: nil, uid: uid)
        return Seeded(reply: reply, passport: passport)
    }

    private func seedArea(id: UUID, name: String, colour: String, order: Int, uid: String) throws {
        try UITestEmulator.writeDocument(
            path: "users/\(uid)/life_areas/\(id.uuidString)",
            fields: [
                "id": UITestEmulator.string(id.uuidString),
                "name": UITestEmulator.string(name),
                "colour": UITestEmulator.string(colour),
                "sort_order": ["integerValue": String(order)]
            ]
        )
    }

    // swiftlint:disable:next function_parameter_count
    private func seedTask(
        id: UUID, title: String, due: Date?, minutes: Int?, area: UUID?, nextStep: String?, uid: String
    ) throws {
        var fields: [String: Any] = [
            "id": UITestEmulator.string(id.uuidString),
            "title": UITestEmulator.string(title),
            "status": UITestEmulator.string("open"),
            "priority": UITestEmulator.string("p3"),
            "created_at": UITestEmulator.timestamp(Date())
        ]
        if let due { fields["due_date"] = UITestEmulator.timestamp(due) }
        if let minutes { fields["focus_duration_seconds"] = ["integerValue": String(minutes * 60)] }
        if let area { fields["life_area_id"] = UITestEmulator.string(area.uuidString) }
        if let nextStep { fields["next_step"] = UITestEmulator.string(nextStep) }
        try UITestEmulator.writeDocument(path: "users/\(uid)/tasks/\(id.uuidString)", fields: fields)
    }

    /// Round 5a: *"At AX3 the card is taller than the screen, so the build needs a COMPACT AX3
    /// card with Start above the fold."* The fold is the top of the tab bar.
    @MainActor
    private func assertStartAboveTheFold(_ start: XCUIElement, in app: XCUIApplication) throws {
        let tabBarTop = UITestSession.tabButton("Today", in: app).frame.minY
        print("MEASURE today-\(tag) startMaxY=\(start.frame.maxY) tabBarTop=\(tabBarTop)")
        XCTAssertLessThan(start.frame.maxY, tabBarTop, "Start is below the fold at an accessibility size")
    }

    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func attach(_ app: XCUIApplication, named name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}

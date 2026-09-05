//
//  ToolsRoutinesJourneyUITests.swift
//  ADHD LifeOSUITests
//
//  The Routines section on Tools, driven on the simulator against the Firebase emulator
//  (F-Routines-B-ToolsSection).
//
//  **This is the block's acceptance test, not a nice-to-have.** The whole feature is a
//  REACHABILITY feature, and reachability is the one claim a unit test cannot make: this repo
//  has shipped six defects where a helper was written, documented, unit-tested and then either
//  called by nothing or gated behind a state no user could reach. `ToolsRoutinesCatalogTests`
//  proves the catalog returns the right rows; only this proves anyone can see them.
//
//  All three states are walked, and the FIRST-RUN one is walked first on purpose — an account
//  with no places is the state every other journey seeds its way out of before launching, which
//  is exactly why it is the state that keeps shipping broken.
//

import XCTest

final class ToolsRoutinesJourneyUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Seeding

    private func action(_ id: UUID, _ fields: [String: Any]) -> [String: Any] {
        var all: [String: Any] = [
            "id": UITestEmulator.string(id.uuidString),
            "direction": UITestEmulator.string("arrival")
        ]
        fields.forEach { all[$0.key] = $0.value }
        return UITestEmulator.map(all)
    }

    private func openApp(_ name: String) -> [String: Any] {
        action(UUID(), [
            "kind": UITestEmulator.string("open_app"),
            "scheme": UITestEmulator.string(name.lowercased()),
            "display_name": UITestEmulator.string(name)
        ])
    }

    private func journalLine(_ body: String) -> [String: Any] {
        action(UUID(), [
            "kind": UITestEmulator.string("journal_line"),
            "journal_body": UITestEmulator.string(body)
        ])
    }

    private func seedPlace(
        id: UUID, name: String, emoji: String, actions: [[String: Any]], uid: String
    ) throws {
        try UITestEmulator.writeDocument(
            path: "users/\(uid)/places/\(id.uuidString)",
            fields: [
                "id": UITestEmulator.string(id.uuidString),
                "name": UITestEmulator.string(name),
                "latitude": UITestEmulator.double(51.5152),
                "longitude": UITestEmulator.double(-0.1418),
                "radius_metres": UITestEmulator.double(150),
                "emoji": UITestEmulator.string(emoji),
                "created_at": UITestEmulator.timestamp(Date()),
                "nudge_on_arrival": UITestEmulator.bool(false),
                "nudge_on_departure": UITestEmulator.bool(false),
                "actions": UITestEmulator.array(actions)
            ]
        )
    }

    // MARK: - 1. The state nothing else tests: a brand-new account

    @MainActor
    func testAFreshAccountIsToldHowToMakeItsFirstRoutine() throws {
        try UITestEmulator.skipUnlessRunning()

        let account = try UITestSession.createAccount(label: "routines-empty")
        let app = try UITestSession.launchSignedIn(as: account)
        openTools(app)

        let empty = app.staticTexts["toolsRoutinesEmpty.noPlaces"]
        UITestSession.scrollUntilHittable(empty, in: app)
        XCTAssertTrue(
            empty.waitForExistence(timeout: UITestSession.timeout),
            "A new account's Tools tab shows no Routines empty state. This is the state every"
                + " new install starts in, and a section that says nothing here teaches nothing"
                + " — the nudges-door defect, exactly."
        )
        XCTAssertTrue(
            app.buttons["toolsRoutinesEmptyAction"].exists,
            "The empty state offers no way out. Its whole job is to hand over the next action."
        )
        attach(app, "1-fresh-account-no-places")
    }

    // MARK: - 2. Places, but nothing that qualifies — the OTHER empty state

    /// The discriminator. Both empty states pass `waitForExistence` on a section that renders a
    /// single generic message, so this is what proves the two flavours are really distinguished
    /// at runtime and not merely in the enum.
    @MainActor
    func testAPlaceWithOneStepGetsTheOtherEmptyStateAndNotTheFirstRunOne() throws {
        try UITestEmulator.skipUnlessRunning()

        let account = try UITestSession.createAccount(label: "routines-nonqualifying")
        try seedPlace(
            id: UUID(), name: "Corner shop", emoji: "🏪",
            actions: [openApp("Spotify")], uid: account.uid
        )
        let app = try UITestSession.launchSignedIn(as: account)
        openTools(app)

        let notQualifying = app.staticTexts["toolsRoutinesEmpty.noQualifyingPlaces"]
        UITestSession.scrollUntilHittable(notQualifying, in: app)
        XCTAssertTrue(
            notQualifying.waitForExistence(timeout: UITestSession.timeout),
            "A place with one tap-step got the wrong empty state. Telling someone who already has"
                + " places to add a place is advice they cannot follow."
        )
        XCTAssertFalse(
            app.staticTexts["toolsRoutinesEmpty.noPlaces"].exists,
            "Both empty states are on screen at once, so one of them is lying."
        )
        attach(app, "2-places-but-no-routines")
    }

    // MARK: - 3. A real routine, on screen, opening the real editor

    @MainActor
    func testAQualifyingPlaceAppearsAsARoutineAndOpensItsEditor() throws {
        try UITestEmulator.skipUnlessRunning()

        let account = try UITestSession.createAccount(label: "routines-listed")
        let placeId = UUID()
        // One AUTO step and two TAP steps. The auto step is the trap: it must be counted
        // nowhere, so the row has to read "2 steps" and not "3 steps".
        try seedPlace(
            id: placeId, name: "Gym", emoji: "🏋️",
            actions: [journalLine("Leg day"), openApp("Spotify"), openApp("Maps")],
            uid: account.uid
        )
        let app = try UITestSession.launchSignedIn(as: account)
        openTools(app)

        let row = app.buttons["toolsRoutineRow-\(placeId.uuidString)-arrival"]
        UITestSession.scrollUntilHittable(row, in: app)
        XCTAssertTrue(
            row.waitForExistence(timeout: UITestSession.timeout),
            "A qualifying place produced no routine row on Tools. The catalog can be perfectly"
                + " correct and perfectly tested while nothing renders it — that is this repo's"
                + " most repeated defect and the reason this journey exists."
        )
        XCTAssertTrue(
            row.label.contains("When you arrive"),
            "The row is not direction-worded. Its label was: \(row.label)"
        )
        XCTAssertTrue(
            row.label.contains("Gym · 2 steps"),
            "The row's count disagrees with the notification's. The auto-run journal line must be"
                + " counted nowhere — the banner says \"2 steps ready\" for this same place."
                + " Its label was: \(row.label)"
        )
        XCTAssertFalse(
            app.buttons["toolsRoutineRow-\(placeId.uuidString)-departure"].exists,
            "A departure routine was listed for a place with no departure actions at all."
        )
        attach(app, "3-routine-listed")

        // The row opens the PLACE editor, because a routine's editor is the place's Actions
        // section (E's settled Option A). There is no separate routine object to edit.
        row.tap()
        XCTAssertTrue(
            app.buttons["placeEditorSaveButton"].waitForExistence(timeout: UITestSession.timeout),
            "Tapping a routine opened no editor. A row that does nothing is worse than no row —"
                + " it promises an edit the app never delivers."
        )
        attach(app, "4-routine-opens-place-editor")
    }

    // MARK: - Helpers

    @MainActor
    private func openTools(_ app: XCUIApplication) {
        XCTAssertTrue(
            app.buttons["quickCaptureButton"].waitForExistence(timeout: UITestSession.timeout),
            "The signed-in tabs never appeared"
        )
        UITestSession.openTab("Tools", in: app)
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}

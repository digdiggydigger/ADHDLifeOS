//
//  SignedInJourneySupport.swift
//  ADHD LifeOSUITests
//
//  The journeys' shared machinery — tab navigation, the scroll-into-reach helper, and the
//  Firestore seeding that puts a document in place before the app ever launches. Split out of
//  `SignedInJourneyUITests.swift` when the fifth journey pushed that file over its 400-line
//  budget; the members are internal rather than private for exactly that reason.
//

import XCTest

extension SignedInJourneyUITests {
    // MARK: - Navigation

    /// Existing is not reachable — these screens scroll, and an element below the fold is in the
    /// hierarchy while being untappable. Bounded, so a genuinely absent control still fails fast.
    @MainActor
    func scrollUntilHittable(
        _ element: XCUIElement, in app: XCUIApplication, attempts: Int = 8
    ) {
        var remaining = attempts
        while !element.isHittable, remaining > 0 {
            app.swipeUp()
            remaining -= 1
        }
    }

    @MainActor
    func openCapturesTab(_ app: XCUIApplication) {
        let tab = app.tabBars.buttons["Captures"]
        XCTAssertTrue(
            tab.waitForExistence(timeout: UITestSession.timeout),
            "The Captures tab is missing from the tab bar"
        )
        tab.tap()
    }

    @MainActor
    func openTasksTab(_ app: XCUIApplication) {
        let tab = app.tabBars.buttons["Tasks"]
        XCTAssertTrue(tab.waitForExistence(timeout: UITestSession.timeout), "Tab bar never appeared")
        tab.tap()
    }

    // MARK: - Firestore fixtures

    /// Task documents are fully snake_cased (`life_area_id`, `created_at`) — see CLAUDE.md, where
    /// the tasks/captures casing split is spelled out. Document IDs are UPPERCASE `uuidString`.
    /// Due now, so the row renders on the Momentum board (F-V3-Tasks-rebuild: undated tasks
    /// appear only under the Open filter).
    func seedTask(id: UUID, title: String, uid: String) throws {
        try UITestEmulator.writeDocument(
            path: "users/\(uid)/tasks/\(id.uuidString)",
            fields: [
                "id": UITestEmulator.string(id.uuidString),
                "title": UITestEmulator.string(title),
                "status": UITestEmulator.string("open"),
                "priority": UITestEmulator.string("p3"),
                "due_date": UITestEmulator.timestamp(Date()),
                "created_at": UITestEmulator.timestamp(Date())
            ]
        )
    }

    /// One capture sitting in the inbox, written straight to Firestore.
    ///
    /// Seeded rather than captured through the UI for the same reason the nudge is: the composer
    /// is a separate flow with its own failure modes, and this journey is about what happens to a
    /// capture AFTER it exists. Only the five fields a `Capture` cannot decode without.
    ///
    /// Captures are camelCase on the wire EXCEPT `created_at` — the convention split
    /// `FirestoreFieldPayloads` documents. Spelling `createdAt` here would leave the document
    /// undecodable and the inbox empty, which is why this is written out rather than derived.
    func seedWaitingCapture(id: UUID, content: String, uid: String) throws {
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

    func seedOverdueNudge(id: UUID, label: String, uid: String) throws {
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

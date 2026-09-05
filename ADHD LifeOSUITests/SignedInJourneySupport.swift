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
    /// hierarchy while being untappable.
    ///
    /// Delegates rather than re-implementing. This was the FIFTH copy of the same loop, and like
    /// the other four it swiped without settling, so it read `isHittable` mid-flight. It passed
    /// where the others failed only by luck of timing — which is exactly the kind of divergence
    /// two helpers with the same name are guaranteed to produce.
    @MainActor
    func scrollUntilHittable(
        _ element: XCUIElement, in app: XCUIApplication, attempts: Int = 8
    ) {
        UITestSession.scrollUntilHittable(element, in: app, attempts: attempts)
    }

    /// Taps a tab until it is actually SELECTED.
    ///
    /// These tapped once. A tab tap taken while Today is still settling is a silent no-op, and the
    /// run then dies at whatever the tab was supposed to reveal — `testCreateTask` failed on
    /// `taskCreateButton` for exactly this, one commit AFTER `tap(_:untilExists:)` was added and
    /// wired into `signOutIfSignedIn`. The lesson is that a fix for a class of bug has to be
    /// applied to every member of the class, not to the one that happened to be failing.
    ///
    /// `isSelected` rather than a per-tab landmark, so one helper serves every tab and no caller
    /// has to know what its destination renders first.
    @MainActor
    func openTab(_ name: String, in app: XCUIApplication) {
        let tab = UITestSession.tabButton(name, in: app)
        XCTAssertTrue(
            tab.waitForExistence(timeout: UITestSession.timeout),
            "The \(name) tab is missing from the tab bar"
        )
        for attempt in 1...3 {
            if tab.isSelected { return }
            // A plain `.tap()` goes through hittability resolution, which a just-dismissed cover
            // can still interfere with. From the second attempt, tap the COORDINATE, which
            // bypasses that resolution entirely — `RoutineJourneyUITests.openTab`'s lesson.
            if attempt == 1 {
                tab.tap()
            } else {
                tab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            }
            // A FRESH expectation per attempt. XCTest allows an expectation to be waited on
            // exactly ONCE, so the hoisted one this replaces raised "API violation - expectations
            // can only be waited on once" on the second lap instead of retrying — which failed
            // three journeys the first time the retry path was ever actually taken.
            let selected = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "isSelected == true"), object: tab
            )
            if XCTWaiter().wait(for: [selected], timeout: 4) == .completed { return }
        }
        XCTAssertTrue(tab.isSelected, "The \(name) tab never became selected")
    }

    @MainActor
    func openCapturesTab(_ app: XCUIApplication) {
        openTab("Captures", in: app)
    }

    @MainActor
    func openTasksTab(_ app: XCUIApplication) {
        openTab("Tasks", in: app)
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
    /// The decision card must NAME a capture that has no words of its own, then get out of the way.
    ///
    /// Lives here rather than inline because the journey it belongs to is at its 50-line function
    /// budget. A photo capture carries neither title nor content, and the card used to coalesce
    /// the two and render the empty string — chips above a blank (E's device screenshot,
    /// 2026-08-28). `CaptureRowPresentation.primaryText` is the shared resolver that ends in
    /// "Photo capture" for exactly this input, and a SwiftUI body is not something the unit suite
    /// can see, so this assertion is the only guard that exists.
    ///
    /// Skip is in-memory and writes nothing, which makes it the cheapest way to move the wordless
    /// capture aside and leave the seeded note on the decision card for the rest of the journey.
    @MainActor
    func assertWordlessCaptureIsNamedThenSkipItAside(in app: XCUIApplication) {
        XCTAssertTrue(
            app.staticTexts["Photo capture"].waitForExistence(timeout: UITestSession.timeout),
            "The decision card rendered a wordless capture as a blank instead of naming its kind"
                + (app.staticTexts["captureInboxEmptyState"].exists
                    ? " (the inbox rendered as empty — check the seeded document decodes,"
                        + " especially `created_at`)"
                    : "")
        )
        let skip = app.buttons["captureInboxSkipButton"]
        XCTAssertTrue(skip.waitForExistence(timeout: UITestSession.timeout), "No Skip button")
        scrollUntilHittable(skip, in: app)
        skip.tap()
    }

    /// `kind` and `age` are parameters because a photo capture with EMPTY content is a real and
    /// awkward case — it is the one shape whose card has no words of its own to fall back on, and
    /// the decision card rendered it as a blank until 2026-08-28. `age` decides which capture wins
    /// the top slot, since the inbox sorts newest-first by default.
    func seedWaitingCapture(
        id: UUID,
        content: String,
        uid: String,
        kind: String = "note",
        age: TimeInterval = -3600
    ) throws {
        try UITestEmulator.writeDocument(
            path: "users/\(uid)/captures/\(id.uuidString)",
            fields: [
                "id": UITestEmulator.string(id.uuidString),
                "content": UITestEmulator.string(content),
                "kind": UITestEmulator.string(kind),
                "processed": UITestEmulator.bool(false),
                "created_at": UITestEmulator.timestamp(Date().addingTimeInterval(age))
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

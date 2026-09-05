//
//  PlaceRoutineNotificationContentTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The routine notification's words and wire (F-Routines-2-Notify). Every phrasing pinned —
/// the canvas After board is the spec: title stays the place moment, body = custom message ·
/// auto-run report · "N steps ready — <first names>. Tap to run."
final class PlaceRoutineNotificationContentTests: XCTestCase {

    private let noon = Date(timeIntervalSince1970: 1_756_296_000)
    private let gymId = UUID()

    private func spotify() -> PlaceAction {
        PlaceAction(
            id: UUID(), direction: .arrival,
            kind: .openApp(scheme: "spotify", displayName: "Spotify")
        )
    }

    private func text() -> PlaceAction {
        PlaceAction(
            id: UUID(), direction: .arrival,
            kind: .textContact(contactName: "Ben", phoneNumber: "+44111", messageBody: "Here!")
        )
    }

    private func journal() -> PlaceAction {
        PlaceAction(id: UUID(), direction: .arrival, kind: .journalLine(body: "Leg day"))
    }

    private func makeRun(
        kind: PlaceTriggerEvent.Kind = .arrival,
        message: String? = nil,
        actions: [PlaceAction]
    ) -> RoutineRun {
        RoutineRun.make(
            event: PlaceTriggerEvent(placeId: gymId, kind: kind, occurredAt: noon),
            entry: AtPlaceSnapshot.PlaceEntry(
                placeId: gymId, displayName: "Gym 🏋️", openTaskTitles: [],
                arrivalMessage: kind == .arrival ? message : nil,
                departureMessage: kind == .departure ? message : nil,
                actions: actions, latitude: nil, longitude: nil
            ),
            plan: PlaceRoutinePlan.make(actions, for: kind)
        )
    }

    // MARK: - The wire

    func testIdentifier_isStablePerPlaceAndDirection_underItsOwnPrefix() {
        let identifier = PlaceRoutineNotificationContent.identifier(placeId: gymId, kind: .arrival)

        XCTAssertEqual(identifier, "placeRoutine-\(gymId.uuidString)-arrival")
        XCTAssertFalse(
            identifier.hasPrefix(PlaceActionNotificationContent.identifierPrefix),
            "the placeAction- prefix is GREEDY (its router claims anything under it, by pinned"
                + " design) — a routine identifier must never start with it"
        )
        XCTAssertNotEqual(
            identifier,
            PlaceRoutineNotificationContent.identifier(placeId: gymId, kind: .departure),
            "each direction replaces its OWN predecessor, never the other's"
        )
    }

    /// It used to carry the UUID and nothing else, because the crossing had already written
    /// the run. Deferred logging (Block A) removed the thing a bare key resolved against, so
    /// the whole frozen run rides along — and the key STAYS, because the door's stale rule
    /// reads it and a banner delivered by an older build carries nothing but.
    func testUserInfo_carriesTheRunKeyAndTheWholeRun() throws {
        let run = makeRun(message: "Time to train", actions: [journal(), spotify(), text()])

        let userInfo = PlaceRoutineNotificationContent.userInfo(for: run)

        XCTAssertEqual(
            userInfo[PlaceRoutineNotificationContent.runIdUserInfoKey], run.id.uuidString
        )
        XCTAssertEqual(
            PlaceRoutineNotificationContent.runKey(fromUserInfo: userInfo), run.id
        )
        // A round-trip rather than a string comparison: JSON key order is nondeterministic per
        // encode, and what is claimed is that the tap can rebuild THIS run.
        XCTAssertEqual(
            PlaceRoutineNotificationContent.run(fromUserInfo: userInfo), run,
            "the tap has to be able to CREATE the routine — everything it needs rides here"
        )
    }

    func testRunPayload_fromABrokenUserInfo_isNil() {
        XCTAssertNil(PlaceRoutineNotificationContent.run(fromUserInfo: [:]))
        XCTAssertNil(PlaceRoutineNotificationContent.run(
            fromUserInfo: [PlaceRoutineNotificationContent.runPayloadUserInfoKey: "{not json"]
        ))
        XCTAssertNil(PlaceRoutineNotificationContent.runKey(
            fromUserInfo: [PlaceRoutineNotificationContent.runIdUserInfoKey: "not-a-uuid"]
        ))
    }

    // MARK: - The words

    /// The middle part is FORWARD-looking now (Block A). "Journaled" was past tense reporting a
    /// completed write; under deferral nothing has run when this posts, so the same sentence
    /// would be a straight lie.
    func testNotification_absorbsTheMessage_namesWhatWillRun_thenOffersTheSteps() {
        let run = makeRun(message: "Time to train", actions: [journal(), spotify(), text()])

        let content = PlaceRoutineNotificationContent.notification(for: run)

        XCTAssertEqual(content.title, "You're at Gym 🏋️")
        XCTAssertEqual(
            content.body,
            "Time to train · Will journal \u{201C}Leg day\u{201D}"
                + " · 2 steps ready — Open Spotify · Text Ben. Tap to run."
        )
        XCTAssertFalse(
            content.body.contains("Journaled"),
            "past tense here is the report of a write that has not happened"
        )
    }

    func testNotification_withoutMessageOrAutoStep_isJustTheSteps() {
        let run = makeRun(actions: [spotify(), text()])

        let content = PlaceRoutineNotificationContent.notification(for: run)

        XCTAssertEqual(content.body, "2 steps ready — Open Spotify · Text Ben. Tap to run.")
    }

    func testNotification_quotesAtMostTwoStepNames() {
        let run = makeRun(actions: [
            spotify(), text(),
            PlaceAction(id: UUID(), direction: .arrival, kind: .startSprint(minutes: 25)),
            PlaceAction(id: UUID(), direction: .arrival, kind: .openScreen(screen: "tasks_today"))
        ])

        let content = PlaceRoutineNotificationContent.notification(for: run)

        XCTAssertEqual(
            content.body,
            "4 steps ready — Open Spotify · Text Ben · +2 more. Tap to run.",
            "a notification is a glance — the ArrivalNudgeContent.maximumQuotedTitles convention"
        )
    }

    func testNotification_departureMoment() {
        let actions = [
            PlaceAction(id: UUID(), direction: .departure, kind: .openURL(urlString: "https://a.example")),
            PlaceAction(id: UUID(), direction: .departure, kind: .startSprint(minutes: 10))
        ]
        let run = makeRun(kind: .departure, message: "Grab your towel", actions: actions)

        let content = PlaceRoutineNotificationContent.notification(for: run)

        XCTAssertEqual(content.title, "Leaving Gym 🏋️")
        XCTAssertTrue(content.body.hasPrefix("Grab your towel · "))
    }

    // MARK: - The species split's registration (call-site read, the clearance-tests mould)

    func testTheRoutineCategory_isRegisteredAtLaunch() throws {
        XCTAssertEqual(PlaceRoutineNotificationContent.categoryIdentifier, "PLACE_ROUTINE")

        let appSource = try Self.appSource("ADHD_LifeOSApp.swift")
        XCTAssertTrue(
            appSource.contains("setNotificationCategories"),
            "the routine category must be registered at launch — an unregistered category is"
                + " the dead-shared-component shape at the notification layer"
        )
        XCTAssertTrue(
            appSource.contains("PlaceRoutineNotificationContent.categoryIdentifier"),
            "registration must spell the shared constant, not a string copy that can drift"
        )
        XCTAssertEqual(
            appSource.components(separatedBy: "setNotificationCategories").count - 1, 1,
            "setNotificationCategories REPLACES the whole set — a second call site would"
                + " silently erase the first. One registry, one call."
        )
    }

    private static func appSource(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ADHD LifeOS")
            .appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw NSError(domain: "PlaceRoutineNotificationContentTests", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Could not read \(url.path) — this test reads the"
                    + " tree it was compiled from (#filePath)."
            ])
        }
        return text
    }
}

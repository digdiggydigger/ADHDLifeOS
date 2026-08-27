//
//  DepartureMessageTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The per-place custom DEPARTURE message (E's 2026-08-28 request) — the counterpart to
/// `ArrivalMessageTests`' arrival words, and it carries the same rule change: a set message is the
/// content, so leaving here always says it, and the empty-never-fires gate applies only to places
/// without one. Before this, departure was task-gated always.
///
/// The two messages are separate fields on purpose: "remember your keys" on the way out is not the
/// same sentence as "locker code is 4821" on the way in, and a place commonly wants one without
/// the other. Tests pin that neither leaks into the other's crossing.
@MainActor
final class DepartureMessageTests: XCTestCase {

    private let noon = Date(timeIntervalSince1970: 1_756_296_000)
    private let tescoId = UUID()

    private func entry(
        titles: [String] = [], arrival: String? = nil, departure: String? = nil
    ) -> AtPlaceSnapshot {
        AtPlaceSnapshot(entries: [
            AtPlaceSnapshot.PlaceEntry(
                placeId: tescoId, displayName: "Tesco 🛒",
                openTaskTitles: titles, arrivalMessage: arrival, departureMessage: departure
            )
        ])
    }

    private func arrivalEvent() -> PlaceTriggerEvent {
        PlaceTriggerEvent(placeId: tescoId, kind: .arrival, occurredAt: noon)
    }

    private func departureEvent() -> PlaceTriggerEvent {
        PlaceTriggerEvent(placeId: tescoId, kind: .departure, occurredAt: noon)
    }

    // MARK: - Firing

    /// The message alone is enough — E wrote it, so leaving with zero open tasks still says it.
    func testContent_customMessageFiresWithoutTasks() {
        let content = ArrivalNudgeContent.notification(
            for: departureEvent(), snapshot: entry(departure: "Got your keys?")
        )

        XCTAssertEqual(content?.title, "Leaving Tesco 🛒")
        XCTAssertEqual(content?.body, "Got your keys?")
    }

    func testContent_customMessageAndTasksCompose() {
        let content = ArrivalNudgeContent.notification(
            for: departureEvent(),
            snapshot: entry(titles: ["Return the parcel"], departure: "Got your keys?")
        )

        XCTAssertEqual(
            content?.body, "Got your keys? — \u{201C}Return the parcel\u{201D} is still open here."
        )
    }

    /// No message, no tasks — the original restraint rule is untouched.
    func testContent_withoutAMessageTheEmptyCaseStillNeverFires() {
        XCTAssertNil(ArrivalNudgeContent.notification(for: departureEvent(), snapshot: entry()))
    }

    /// Unchanged from block 4b: with tasks and no message, leaving still reports what is open.
    func testContent_withoutAMessageTasksStillSpeak() {
        let content = ArrivalNudgeContent.notification(
            for: departureEvent(), snapshot: entry(titles: ["Return the parcel", "Buy milk"])
        )

        XCTAssertEqual(content?.body, "2 things are still open here.")
    }

    // MARK: - The two messages never cross

    func testContent_departureMessageIsSilentOnArrival() {
        XCTAssertNil(ArrivalNudgeContent.notification(
            for: arrivalEvent(), snapshot: entry(departure: "Got your keys?")
        ))
    }

    func testContent_arrivalMessageIsSilentOnDeparture() {
        XCTAssertNil(ArrivalNudgeContent.notification(
            for: departureEvent(), snapshot: entry(arrival: "Locker code is 4821")
        ))
    }

    func testContent_eachCrossingSpeaksItsOwnWords() {
        let snapshot = entry(arrival: "Locker code is 4821", departure: "Got your keys?")

        XCTAssertEqual(
            ArrivalNudgeContent.notification(for: arrivalEvent(), snapshot: snapshot)?.body,
            "Locker code is 4821"
        )
        XCTAssertEqual(
            ArrivalNudgeContent.notification(for: departureEvent(), snapshot: snapshot)?.body,
            "Got your keys?"
        )
    }

    // MARK: - The model and the editor carry it

    func testPlace_encodesTheDepartureMessageSnakeCased() throws {
        let place = Place(
            id: UUID(), name: "Tesco",
            coordinate: PlaceCoordinate(latitude: 51.5152, longitude: -0.1418),
            radiusMetres: 150, emoji: "🛒",
            nudgeOnDeparture: true, departureMessage: "Got your keys?"
        )

        let data = try JSONEncoder().encode(place)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["departure_message"] as? String, "Got your keys?")
        XCTAssertNil(json["departureMessage"], "places are snake_cased throughout")
    }

    func testPlace_legacyDocumentDecodesWithNoMessage() throws {
        let legacy = Data("""
        {"id":"5B1E4C1E-0000-0000-0000-00000000000A","name":"Tesco","latitude":51.5152,\
        "longitude":-0.1418,"radius_metres":150,"created_at":0}
        """.utf8)

        XCTAssertNil(try JSONDecoder().decode(Place.self, from: legacy).departureMessage)
    }

    /// A whitespace-only message stores nil, not "" — an empty string would count as "has a
    /// message" and turn every departure into a blank nudge.
    func testMakePlace_trimsTheMessageToNil() {
        let made = PlaceEditorValidation.makePlace(
            id: UUID(), name: "Tesco",
            coordinate: PlaceCoordinate(latitude: 51.5152, longitude: -0.1418),
            radiusMetres: 150, emoji: "🛒",
            nudgeOnDeparture: true, departureMessage: "   "
        )

        XCTAssertEqual(made?.nudgeOnDeparture, true)
        XCTAssertNil(made?.departureMessage)
    }

    func testMakePlace_keepsBothMessagesApart() {
        let made = PlaceEditorValidation.makePlace(
            id: UUID(), name: "Tesco",
            coordinate: PlaceCoordinate(latitude: 51.5152, longitude: -0.1418),
            radiusMetres: 150, emoji: "🛒",
            nudgeOnArrival: true, nudgeOnDeparture: true,
            arrivalMessage: "Locker code is 4821", departureMessage: "Got your keys?"
        )

        XCTAssertEqual(made?.arrivalMessage, "Locker code is 4821")
        XCTAssertEqual(made?.departureMessage, "Got your keys?")
    }

    func testSnapshotBuild_carriesTheMessage() {
        let tesco = Place(
            id: tescoId, name: "Tesco",
            coordinate: PlaceCoordinate(latitude: 51.5152, longitude: -0.1418),
            radiusMetres: 150, emoji: "🛒",
            nudgeOnDeparture: true, departureMessage: "Got your keys?"
        )

        let built = AtPlaceSnapshot.build(places: [tesco], tasks: [])

        XCTAssertEqual(built.entries.first?.departureMessage, "Got your keys?")
        XCTAssertNil(built.entries.first?.arrivalMessage)
        XCTAssertEqual(built.entries.first?.openTaskTitles, [])
    }

    /// Snapshots written before this field existed must decode as "no departure words", not fail
    /// — a background wake reading a stale snapshot is the normal case, not the edge case.
    func testSnapshot_preMessageSnapshotDecodesWithNoDepartureMessage() throws {
        let legacy = Data("""
        {"entries":[{"placeId":"5B1E4C1E-0000-0000-0000-00000000000B",\
        "displayName":"Tesco 🛒","openTaskTitles":[]}]}
        """.utf8)

        let decoded = try JSONDecoder().decode(AtPlaceSnapshot.self, from: legacy)

        XCTAssertNil(decoded.entries.first?.departureMessage)
    }
}

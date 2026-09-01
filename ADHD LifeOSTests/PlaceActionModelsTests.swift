//
//  PlaceActionModelsTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The `PlaceAction` wire contract (F-PlaceActions-1-Model, E's 2026-08-31 spec).
///
/// The kind list is an OPEN catalogue — E: "all of the above and likely more" — so the contract
/// under test is not just "every kind round-trips" but the forward-compatibility half: a kind
/// this build has never heard of must decode as `.unsupported` WITH its payload preserved for
/// verbatim re-encode, and must never fail the place carrying it. E's device routinely lags
/// main; an old build editing a place must not strip a newer build's action.
final class PlaceActionModelsTests: XCTestCase {

    private let coordinate = PlaceCoordinate(latitude: 51.5152, longitude: -0.1418)

    private func everyKind() -> [PlaceAction.Kind] {
        [
            .openApp(scheme: "spotify", displayName: "Spotify"),
            .openURL(urlString: "https://example.com/timesheet"),
            .textContact(contactName: "Ben", phoneNumber: "+441234567890", messageBody: "Here!"),
            .startSprint(minutes: 25),
            .startSprint(minutes: nil),
            .createCapture(text: "Check the mail"),
            .journalLine(body: "Arrived at the gym 💪"),
            .openScreen(screen: "tasks_today")
        ]
    }

    // MARK: - Round trips

    func testEveryKind_survivesAJSONRoundTrip() throws {
        for (index, kind) in everyKind().enumerated() {
            let action = PlaceAction(id: UUID(), direction: .arrival, kind: kind)
            let decoded = try JSONDecoder().decode(
                PlaceAction.self, from: JSONEncoder().encode(action)
            )
            XCTAssertEqual(decoded, action, "kind #\(index) did not survive the round trip")
        }
    }

    func testDirection_survivesTheRoundTrip() throws {
        let leaving = PlaceAction(
            id: UUID(), direction: .departure,
            kind: .textContact(contactName: "Home", phoneNumber: "+44111", messageBody: "On my way")
        )
        let decoded = try JSONDecoder().decode(
            PlaceAction.self, from: JSONEncoder().encode(leaving)
        )
        XCTAssertEqual(decoded.direction, .departure)
    }

    // MARK: - Field spelling (the CLAUDE.md standing rule: right spelling present, wrong absent)

    func testOpenApp_encodesSnakeCasedFlatFields() throws {
        let action = PlaceAction(
            id: UUID(), direction: .arrival,
            kind: .openApp(scheme: "spotify", displayName: "Spotify")
        )

        let data = try JSONEncoder().encode(action)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["kind"] as? String, "open_app")
        XCTAssertEqual(json["scheme"] as? String, "spotify")
        XCTAssertEqual(json["display_name"] as? String, "Spotify")
        XCTAssertNil(json["displayName"], "the camelCase spelling must NOT be written")
        XCTAssertNil(json["payload"], "payload fields are FLAT on the object, never nested")
    }

    func testTextContact_encodesSnakeCasedFlatFields() throws {
        let action = PlaceAction(
            id: UUID(), direction: .departure,
            kind: .textContact(contactName: "Ben", phoneNumber: "+44123", messageBody: "Leaving")
        )

        let data = try JSONEncoder().encode(action)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["kind"] as? String, "text_contact")
        XCTAssertEqual(json["contact_name"] as? String, "Ben")
        XCTAssertEqual(json["phone_number"] as? String, "+44123")
        XCTAssertEqual(json["message_body"] as? String, "Leaving")
        XCTAssertNil(json["contactName"], "the camelCase spelling must NOT be written")
    }

    /// Absent minutes IS the payload — it means "use E's default sprint setting at execution
    /// time", so it must encode as no field at all rather than 0 or null.
    func testStartSprint_defaultMinutesEncodesNoField() throws {
        let action = PlaceAction(id: UUID(), direction: .arrival, kind: .startSprint(minutes: nil))

        let data = try JSONEncoder().encode(action)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["kind"] as? String, "start_sprint")
        XCTAssertFalse(json.keys.contains("minutes"))
    }

    // MARK: - The open catalogue (forward compatibility)

    func testUnknownKind_decodesAsUnsupported_withItsPayloadCaptured() throws {
        let id = UUID()
        let document: [String: Any] = [
            "id": id.uuidString,
            "direction": "arrival",
            "kind": "play_soundscape",
            "soundscape_name": "Rainforest",
            "volume": 0.8,
            "fade_in": true
        ]
        let data = try JSONSerialization.data(withJSONObject: document)

        let decoded = try JSONDecoder().decode(PlaceAction.self, from: data)

        guard case .unsupported(let rawKind, let payload) = decoded.kind else {
            return XCTFail("an unknown kind must decode as .unsupported, got \(decoded.kind)")
        }
        XCTAssertEqual(rawKind, "play_soundscape")
        XCTAssertEqual(payload["soundscape_name"], .string("Rainforest"))
        XCTAssertEqual(payload["volume"], .number(0.8))
        XCTAssertEqual(payload["fade_in"], .bool(true))
        XCTAssertEqual(decoded.direction, .arrival, "direction is reserved, never payload")
    }

    /// The device-lag guarantee itself: decode on a build that doesn't know the kind, re-encode
    /// (as an old build saving the place would), and the action comes back byte-equivalent.
    func testUnsupportedAction_reencodesItsPayloadVerbatim() throws {
        let document: [String: Any] = [
            "id": UUID().uuidString,
            "direction": "departure",
            "kind": "play_soundscape",
            "soundscape_name": "Rainforest",
            "volume": 0.8
        ]
        let decoded = try JSONDecoder().decode(
            PlaceAction.self, from: JSONSerialization.data(withJSONObject: document)
        )

        let reencoded = try JSONEncoder().encode(decoded)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: reencoded) as? [String: Any])

        XCTAssertEqual(json["kind"] as? String, "play_soundscape")
        XCTAssertEqual(json["soundscape_name"] as? String, "Rainforest")
        XCTAssertEqual(json["volume"] as? Double, 0.8)
        XCTAssertEqual(json["direction"] as? String, "departure")
    }

    /// A KNOWN kind whose required payload is missing is corrupt — but it degrades to
    /// `.unsupported`, never throws: throwing would fail the whole place over one broken action.
    func testKnownKind_withMissingPayload_degradesToUnsupportedNotAFailure() throws {
        let document: [String: Any] = [
            "id": UUID().uuidString,
            "direction": "arrival",
            "kind": "open_app"
        ]
        let decoded = try JSONDecoder().decode(
            PlaceAction.self, from: JSONSerialization.data(withJSONObject: document)
        )

        guard case .unsupported(let rawKind, _) = decoded.kind else {
            return XCTFail("a payload-broken known kind must degrade, got \(decoded.kind)")
        }
        XCTAssertEqual(rawKind, "open_app")
    }

    // MARK: - The place carries them

    func testPlace_carriesActionsThroughARoundTrip() throws {
        let place = Place(
            id: UUID(), name: "Gym", coordinate: coordinate, radiusMetres: 150,
            actions: [
                PlaceAction(
                    id: UUID(), direction: .arrival,
                    kind: .openApp(scheme: "spotify", displayName: "Spotify")
                ),
                PlaceAction(
                    id: UUID(), direction: .departure,
                    kind: .textContact(
                        contactName: "Home", phoneNumber: "+44111", messageBody: "On my way"
                    )
                )
            ]
        )

        let decoded = try JSONDecoder().decode(Place.self, from: JSONEncoder().encode(place))

        XCTAssertEqual(decoded, place)
        XCTAssertEqual(decoded.actions.count, 2)
    }

    /// Every place saved before the arc has no `actions` field — a place with nothing to do,
    /// never a failed document (the nudge-toggle precedent).
    func testPlace_withoutActionsField_decodesWithAnEmptyList() throws {
        let document: [String: Any] = [
            "id": UUID().uuidString,
            "name": "Tesco",
            "latitude": 51.5152,
            "longitude": -0.1418,
            "radius_metres": 150.0,
            "created_at": 1_700_000_000.0
        ]
        let decoded = try JSONDecoder().decode(
            Place.self, from: JSONSerialization.data(withJSONObject: document)
        )

        XCTAssertEqual(decoded.actions, [])
    }

    /// One broken action must not take the place down with it — the degradation contract at the
    /// PLACE level, which is where it actually protects E's data.
    func testPlace_withOneUnknownAction_stillDecodesWholly() throws {
        let document: [String: Any] = [
            "id": UUID().uuidString,
            "name": "Gym",
            "latitude": 51.5152,
            "longitude": -0.1418,
            "radius_metres": 150.0,
            "created_at": 1_700_000_000.0,
            "actions": [
                [
                    "id": UUID().uuidString,
                    "direction": "arrival",
                    "kind": "from_the_future",
                    "mystery": "payload"
                ]
            ]
        ]
        let decoded = try JSONDecoder().decode(
            Place.self, from: JSONSerialization.data(withJSONObject: document)
        )

        XCTAssertEqual(decoded.name, "Gym")
        XCTAssertEqual(decoded.actions.count, 1)
        guard case .unsupported = decoded.actions[0].kind else {
            return XCTFail("the future action must ride along as unsupported")
        }
    }

    // MARK: - Wanting a crossing (the fence opt-in)

    private func gym(
        arrivalToggle: Bool = false, departureToggle: Bool = false,
        actions: [PlaceAction] = []
    ) -> Place {
        Place(
            id: UUID(), name: "Gym", coordinate: coordinate, radiusMetres: 150,
            nudgeOnArrival: arrivalToggle, nudgeOnDeparture: departureToggle, actions: actions
        )
    }

    private func action(_ direction: PlaceActionDirection) -> PlaceAction {
        PlaceAction(
            id: UUID(), direction: direction,
            kind: .openApp(scheme: "spotify", displayName: "Spotify")
        )
    }

    func testWantsCrossing_aToggleAloneCounts() {
        let place = gym(departureToggle: true)
        XCTAssertFalse(place.wantsArrivalCrossing)
        XCTAssertTrue(place.wantsDepartureCrossing)
        XCTAssertTrue(place.wantsAnyCrossing)
    }

    /// Configuring an action IS the opt-in gesture — "arrive → Spotify" is E saying interrupt
    /// me here — so an action earns its direction's fence with both toggles off.
    func testWantsCrossing_anActionAloneCountsForItsDirectionOnly() {
        let place = gym(actions: [action(.arrival)])
        XCTAssertTrue(place.wantsArrivalCrossing)
        XCTAssertFalse(place.wantsDepartureCrossing)
    }

    func testWantsCrossing_aQuietPlaceWantsNothing() {
        let place = gym()
        XCTAssertFalse(place.wantsAnyCrossing)
    }

    /// An unsupported action still holds its fence: the intent came from a newer build, and
    /// dropping the fence here would silently disarm it until the device catches up.
    func testWantsCrossing_anUnsupportedActionStillCounts() {
        let future = PlaceAction(
            id: UUID(), direction: .departure,
            kind: .unsupported(rawKind: "from_the_future", payload: [:])
        )
        XCTAssertTrue(gym(actions: [future]).wantsDepartureCrossing)
    }

    // MARK: - The snapshot carries them

    func testSnapshotBuild_carriesThePlaceActions() {
        let spotify = action(.arrival)
        let snapshot = AtPlaceSnapshot.build(places: [gym(actions: [spotify])], tasks: [])

        XCTAssertEqual(snapshot.entries.first?.actions, [spotify])
    }

    /// Snapshots written before the arc have no actions field — they must decode quietly, not
    /// fail the wake that reads them.
    func testSnapshot_preActionsJSON_decodesQuietly() throws {
        let legacy: [String: Any] = [
            "entries": [
                [
                    "placeId": UUID().uuidString,
                    "displayName": "Gym 💪",
                    "openTaskTitles": ["Stretch"]
                ]
            ]
        ]
        let decoded = try JSONDecoder().decode(
            AtPlaceSnapshot.self, from: JSONSerialization.data(withJSONObject: legacy)
        )

        XCTAssertNil(decoded.entries.first?.actions)
    }
}

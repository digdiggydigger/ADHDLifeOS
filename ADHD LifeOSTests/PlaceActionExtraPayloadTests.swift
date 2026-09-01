//
//  PlaceActionExtraPayloadTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The forward encoder fix (F-AppDirectory-1): known kinds keep a stranger's fields.
///
/// `.unsupported` protects unknown KINDS; `extraPayload` protects a KNOWN kind that grew an
/// optional field in a newer build — without the capture, an older build re-saving the place
/// would strip the field silently. Split from `PlaceActionModelsTests` for file length; the
/// contract is the same wire format's.
final class PlaceActionExtraPayloadTests: XCTestCase {

    private func everyKind() -> [PlaceAction.Kind] {
        [
            .openApp(scheme: "spotify", displayName: "Spotify"),
            .openLink(
                displayName: "Spotify — A playlist",
                link: "https://open.spotify.com/playlist/abc123",
                scheme: "spotify"
            ),
            .openURL(urlString: "https://example.com/timesheet"),
            .textContact(contactName: "Ben", phoneNumber: "+441234567890", messageBody: "Here!"),
            .startSprint(minutes: 25),
            .startSprint(minutes: nil),
            .createCapture(text: "Check the mail"),
            .journalLine(body: "Arrived at the gym 💪"),
            .openScreen(screen: "tasks_today")
        ]
    }

    /// The other half of the device-lag guarantee, for every typed kind at once.
    func testEveryKnownKind_reencodesAStrangerFieldIntact() throws {
        for (index, kind) in everyKind().enumerated() {
            let action = PlaceAction(id: UUID(), direction: .arrival, kind: kind)
            var json = try XCTUnwrap(
                JSONSerialization.jsonObject(with: JSONEncoder().encode(action)) as? [String: Any]
            )
            json["from_the_future"] = "keep me"

            let decoded = try JSONDecoder().decode(
                PlaceAction.self, from: JSONSerialization.data(withJSONObject: json)
            )
            if case .unsupported = decoded.kind {
                XCTFail("kind #\(index) must still decode typed, not degrade over a stranger")
            }
            let reencoded = try XCTUnwrap(
                JSONSerialization.jsonObject(with: JSONEncoder().encode(decoded)) as? [String: Any]
            )
            XCTAssertEqual(
                reencoded["from_the_future"] as? String, "keep me",
                "kind #\(index) stripped the stranger field on re-encode"
            )
            XCTAssertEqual(
                try JSONDecoder().decode(PlaceAction.self, from: JSONEncoder().encode(decoded)),
                decoded,
                "kind #\(index): the stranger must be part of the action's value, not a side channel"
            )
        }
    }

    /// Another kind's payload key on this kind is still a stranger — capture must exclude only
    /// the keys THIS kind owns, not every key any kind has ever used.
    func testKnownKind_keepsAnotherKindsPayloadKeyAsAStranger() throws {
        let document: [String: Any] = [
            "id": UUID().uuidString,
            "direction": "arrival",
            "kind": "open_app",
            "scheme": "spotify",
            "display_name": "Spotify",
            "minutes": 5
        ]
        let decoded = try JSONDecoder().decode(
            PlaceAction.self, from: JSONSerialization.data(withJSONObject: document)
        )

        guard case .openApp = decoded.kind else {
            return XCTFail("open_app with its payload intact must decode typed")
        }
        let reencoded = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(decoded)) as? [String: Any]
        )
        XCTAssertEqual(reencoded["minutes"] as? Double, 5)
    }

    /// A hand-built collision must lose to the typed payload — extras fill gaps, never
    /// overwrite what the kind itself wrote.
    func testExtraPayload_canNeverOverrideTypedOrReservedFields() throws {
        let action = PlaceAction(
            id: UUID(), direction: .arrival,
            kind: .openApp(scheme: "spotify", displayName: "Spotify"),
            extraPayload: [
                "scheme": .string("corrupted"),
                "kind": .string("corrupted"),
                "note": .string("kept")
            ]
        )

        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(action)) as? [String: Any]
        )

        XCTAssertEqual(json["scheme"] as? String, "spotify")
        XCTAssertEqual(json["kind"] as? String, "open_app")
        XCTAssertEqual(json["note"] as? String, "kept")
    }

    /// The broken-payload degradation is untouched by the capture: everything already rides in
    /// the `.unsupported` payload, so `extraPayload` must stay empty — one field, one home.
    func testBrokenKnownKind_carriesEverythingInItsPayloadNotExtras() throws {
        let document: [String: Any] = [
            "id": UUID().uuidString,
            "direction": "arrival",
            "kind": "open_app",
            "display_name": "Spotify"
        ]
        let decoded = try JSONDecoder().decode(
            PlaceAction.self, from: JSONSerialization.data(withJSONObject: document)
        )

        guard case .unsupported(let rawKind, let payload) = decoded.kind else {
            return XCTFail("a payload-broken known kind must still degrade")
        }
        XCTAssertEqual(rawKind, "open_app")
        XCTAssertEqual(payload["display_name"], .string("Spotify"))
        XCTAssertTrue(decoded.extraPayload.isEmpty)
    }
}

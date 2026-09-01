//
//  PlaceOpenLinkModelTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The `open_link` wire kind (F-AppDirectory-2-Links): pasted share-links and deep
/// destinations. A NEW kind rather than a field on `open_app` — the encoder re-encodes known
/// kinds from their typed payload, so an already-shipped build editing the place would strip an
/// extra field, whereas an unknown KIND degrades to `.unsupported` with its payload preserved
/// verbatim and the honest "added by a newer version" row. That degradation is this kind's
/// designed-for path on old builds, so it is pinned here through JSON AND the Firestore codec.
final class PlaceOpenLinkModelTests: XCTestCase {

    private func linkAction(scheme: String? = "spotify") -> PlaceAction {
        PlaceAction(
            id: UUID(), direction: .arrival,
            kind: .openLink(
                displayName: "Spotify — A playlist",
                link: "https://open.spotify.com/playlist/abc123",
                scheme: scheme
            )
        )
    }

    // MARK: - Round trips

    func testOpenLink_survivesAJSONRoundTrip_withAndWithoutScheme() throws {
        for action in [linkAction(), linkAction(scheme: nil)] {
            let decoded = try JSONDecoder().decode(
                PlaceAction.self, from: JSONEncoder().encode(action)
            )
            XCTAssertEqual(decoded, action)
        }
    }

    func testOpenLink_survivesTheFirestoreCodecRoundTrip() throws {
        let action = linkAction()
        let fields = try FirestoreDocumentCoder.encode(action)
        let decoded = try FirestoreDocumentCoder.decode(PlaceAction.self, from: fields)
        XCTAssertEqual(decoded, action)
    }

    // MARK: - Field spelling (right spelling present, wrong absent — the standing rule)

    func testOpenLink_encodesSnakeCasedFlatFields() throws {
        let data = try JSONEncoder().encode(linkAction())
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["kind"] as? String, "open_link")
        XCTAssertEqual(json["display_name"] as? String, "Spotify — A playlist")
        XCTAssertEqual(json["link"] as? String, "https://open.spotify.com/playlist/abc123")
        XCTAssertEqual(json["scheme"] as? String, "spotify")
        XCTAssertNil(json["displayName"], "the camelCase spelling must NOT be written")
        XCTAssertNil(json["url"], "open_url's key must not leak onto open_link")
    }

    /// Absent scheme IS a valid payload (an unrecognised pasted link has no scheme to verify
    /// against) — it must encode as no field at all, the `start_sprint` minutes precedent.
    func testOpenLink_absentSchemeEncodesNoField() throws {
        let data = try JSONEncoder().encode(linkAction(scheme: nil))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertFalse(json.keys.contains("scheme"))
    }

    // MARK: - Degradation

    /// Missing `link` is a broken payload: degrade to `.unsupported`, never throw — throwing
    /// would fail the whole place over one action.
    func testOpenLink_missingLink_degradesToUnsupported() throws {
        let document: [String: Any] = [
            "id": UUID().uuidString,
            "direction": "arrival",
            "kind": "open_link",
            "display_name": "Spotify"
        ]
        let decoded = try JSONDecoder().decode(
            PlaceAction.self, from: JSONSerialization.data(withJSONObject: document)
        )

        guard case .unsupported(let rawKind, let payload) = decoded.kind else {
            return XCTFail("a link-less open_link must degrade, got \(decoded.kind)")
        }
        XCTAssertEqual(rawKind, "open_link")
        XCTAssertEqual(payload["display_name"], .string("Spotify"))
    }

    /// A scheme that is PRESENT but undecodable is corruption, not absence — degrade rather
    /// than silently reading nil (the SE-0230 `try?`-flattening trap, pinned).
    func testOpenLink_presentButBrokenScheme_degradesToUnsupported() throws {
        let document: [String: Any] = [
            "id": UUID().uuidString,
            "direction": "arrival",
            "kind": "open_link",
            "display_name": "Spotify",
            "link": "https://open.spotify.com/playlist/abc123",
            "scheme": 42
        ]
        let decoded = try JSONDecoder().decode(
            PlaceAction.self, from: JSONSerialization.data(withJSONObject: document)
        )

        guard case .unsupported = decoded.kind else {
            return XCTFail("a corrupt scheme must degrade, got \(decoded.kind)")
        }
    }

    /// The old-build path itself, through the FIRESTORE codec: a build without this kind sees
    /// `.unsupported` and must hand the document back byte-for-byte. JSON already pins this
    /// generally; the coder is the wire that actually carries E's data.
    func testUnknownKind_reencodesVerbatimThroughTheFirestoreCodec() throws {
        let fields: [String: Any] = [
            "id": UUID().uuidString,
            "direction": "departure",
            "kind": "open_link_v2",
            "display_name": "Future thing",
            "link": "https://example.com",
            "hologram": true
        ]
        let decoded = try FirestoreDocumentCoder.decode(PlaceAction.self, from: fields)

        guard case .unsupported(let rawKind, _) = decoded.kind else {
            return XCTFail("an unknown kind must degrade, got \(decoded.kind)")
        }
        XCTAssertEqual(rawKind, "open_link_v2")

        let reencoded = try FirestoreDocumentCoder.encode(decoded)
        XCTAssertEqual(reencoded["kind"] as? String, "open_link_v2")
        XCTAssertEqual(reencoded["display_name"] as? String, "Future thing")
        XCTAssertEqual(reencoded["link"] as? String, "https://example.com")
        XCTAssertEqual(reencoded["hologram"] as? Bool, true)
        XCTAssertEqual(reencoded["direction"] as? String, "departure")
    }

    // MARK: - The place carries it

    func testPlace_carriesAnOpenLinkActionThroughTheCodec() throws {
        let place = Place(
            id: UUID(), name: "Gym",
            coordinate: PlaceCoordinate(latitude: 51.5152, longitude: -0.1418),
            radiusMetres: 150,
            // Whole seconds: `Date.now`'s sub-second tail doesn't survive the Timestamp
            // round trip bit-exactly, and this test is about the ACTION.
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            actions: [linkAction()]
        )

        let decoded = try FirestoreDocumentCoder.decode(
            Place.self, from: FirestoreDocumentCoder.encode(place)
        )

        XCTAssertEqual(decoded, place)
    }
}

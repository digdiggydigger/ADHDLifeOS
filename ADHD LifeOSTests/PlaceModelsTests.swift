//
//  PlaceModelsTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The `places` collection's wire contract (F-Location-Foundation).
///
/// `CLAUDE.md`'s standing warning applies with full force here: hand-written Firestore field
/// dictionaries are not derived from `Codable`, so a wrong key raises nothing — it writes a field
/// nothing reads. These assert the RIGHT spelling is present AND the wrong one is absent.
///
/// Convention for this new collection: **snake_case throughout**, matching `tasks` rather than
/// `captures` (which is camelCase apart from `created_at` for historical reasons). A new
/// collection has no history to preserve, so it takes the dominant convention.
final class PlaceModelsTests: XCTestCase {

    private let coordinate = PlaceCoordinate(latitude: 51.5152, longitude: -0.1418)

    // MARK: - Codable round-trip

    func testPlace_survivesARoundTrip() throws {
        let place = Place(
            id: UUID(),
            name: "The office",
            coordinate: coordinate,
            radiusMetres: 200,
            emoji: "🏢",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let data = try JSONEncoder().encode(place)
        let decoded = try JSONDecoder().decode(Place.self, from: data)

        XCTAssertEqual(decoded, place)
    }

    // MARK: - Field spelling

    func testPlace_encodesSnakeCasedKeys() throws {
        let place = Place(id: UUID(), name: "Gym", coordinate: coordinate, radiusMetres: 150)

        let data = try JSONEncoder().encode(place)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertNotNil(json["radius_metres"], "radius_metres must be present")
        XCTAssertNotNil(json["created_at"], "created_at must be present")
        XCTAssertNil(json["radiusMetres"], "the camelCase spelling must NOT be written")
        XCTAssertNil(json["createdAt"], "the camelCase spelling must NOT be written")
    }

    func testPlace_encodesCoordinateAsFlatLatLong_notANestedObject() throws {
        let place = Place(id: UUID(), name: "Gym", coordinate: coordinate, radiusMetres: 150)

        let data = try JSONEncoder().encode(place)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        // Flat, so a Firestore query can range over latitude/longitude directly and so the
        // document stays legible in the console.
        XCTAssertEqual(json["latitude"] as? Double, 51.5152)
        XCTAssertEqual(json["longitude"] as? Double, -0.1418)
        XCTAssertNil(json["coordinate"], "the coordinate must be flattened, not nested")
    }

    // MARK: - Decoding what is already out there

    /// A document written before `emoji` existed must decode with its name and coordinate intact —
    /// dropping someone's place because a later block added a field would be data loss.
    func testPlace_decodesADocumentWithoutTheOptionalFields() throws {
        let legacy = Data("""
        {"id":"5B1E4C1E-0000-0000-0000-000000000001","name":"Home",\
        "latitude":51.5,"longitude":-0.14,"radius_metres":150,"created_at":0}
        """.utf8)

        let decoded = try JSONDecoder().decode(Place.self, from: legacy)

        XCTAssertEqual(decoded.name, "Home")
        XCTAssertEqual(decoded.radiusMetres, 150)
        XCTAssertNil(decoded.emoji)
    }

    /// A radius that arrives out of range from anywhere — a hand-edited document, a future
    /// writer — is clamped on the way IN, not just on the way out.
    func testPlace_decodingClampsAnOutOfRangeRadius() throws {
        let absurd = Data("""
        {"id":"5B1E4C1E-0000-0000-0000-000000000002","name":"Everywhere",\
        "latitude":51.5,"longitude":-0.14,"radius_metres":9999999,"created_at":0}
        """.utf8)

        let decoded = try JSONDecoder().decode(Place.self, from: absurd)

        XCTAssertEqual(decoded.radiusMetres, Place.maximumRadiusMetres)
    }
}

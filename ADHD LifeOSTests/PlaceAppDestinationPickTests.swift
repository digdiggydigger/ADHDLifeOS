//
//  PlaceAppDestinationPickTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The destination step's pure layer (F-AppDirectory-2-Links): the `placeCoordinatePrefill`
/// flag, the coordinate value it fills, and the display-name convention for destination picks.
final class PlaceAppDestinationPickTests: XCTestCase {

    private let spotify = PlaceAppDirectoryEntry(
        scheme: "spotify", name: "Spotify",
        destinations: [
            PlaceAppDestinationTemplate(
                name: "A playlist", template: "https://open.spotify.com/playlist/{value}"
            )
        ]
    )

    // MARK: - The prefill flag

    /// Curated, never name-matched: a template that can take the place's own coordinate says
    /// so with a flag the remote decode can carry.
    func testTemplate_prefillFlagDefaultsFalse() {
        XCTAssertFalse(spotify.destinations[0].placeCoordinatePrefill)
    }

    func testRemoteDecode_readsThePrefillFlag() throws {
        let data = try JSONSerialization.data(withJSONObject: [[
            "scheme": "comgooglemaps",
            "name": "Google Maps",
            "destinations": [[
                "name": "Directions to an address",
                "template": "comgooglemaps://?daddr={value}",
                "place_coordinate_prefill": true
            ]]
        ]])

        let decoded = PlaceAppDirectory.entries(fromJSONArray: data)

        XCTAssertEqual(decoded.first?.destinations.first?.placeCoordinatePrefill, true)
    }

    /// Both bundled Maps entries offer directions, and directions are exactly what the
    /// place's own coordinate can prefill.
    func testBundled_mapsDirectionsTemplatesArePrefillable() throws {
        for scheme in ["maps", "comgooglemaps"] {
            let entry = try XCTUnwrap(
                PlaceAppDirectoryBundled.entries.first(where: { $0.scheme == scheme })
            )
            XCTAssertTrue(
                entry.destinations.contains(where: \.placeCoordinatePrefill),
                "\(scheme) should offer a coordinate-prefillable directions destination"
            )
        }
    }

    /// A prefill flag on a slotless template would have nowhere to land — swept whole.
    func testBundled_everyPrefillTemplateHasAValueSlot() {
        for entry in PlaceAppDirectoryBundled.entries {
            for destination in entry.destinations where destination.placeCoordinatePrefill {
                XCTAssertTrue(
                    destination.template.contains(PlaceAppDestinationTemplate.slot),
                    "\(entry.name)/\(destination.name) is prefillable but has no {value} slot"
                )
            }
        }
    }

    // MARK: - The pick's parts

    func testDisplayName_joinsEntryAndDestination() {
        XCTAssertEqual(
            PlaceAppDestinationPick.displayName(entry: spotify, destination: spotify.destinations[0]),
            "Spotify — A playlist"
        )
    }

    func testDirectionsDisplayName_namesThePlace() {
        XCTAssertEqual(
            PlaceAppDestinationPick.directionsDisplayName(entry: spotify, placeName: "Gym"),
            "Spotify — Directions to Gym"
        )
    }

    func testCoordinateValue_isLatCommaLong() {
        let value = PlaceAppDestinationPick.coordinateValue(
            PlaceCoordinate(latitude: 51.5152, longitude: -0.1418)
        )
        XCTAssertEqual(value, "51.51520,-0.14180")
    }

    /// End to end: the directions template resolved with the place's own coordinate is a
    /// well-formed URL (the comma percent-encodes inside the query value — pinned so the sim
    /// drive checks the REAL link, not a lookalike).
    func testDirectionsLink_resolvesToAWellFormedURL() throws {
        let directions = PlaceAppDestinationTemplate(
            name: "Directions to an address",
            template: "maps://?daddr={value}",
            placeCoordinatePrefill: true
        )
        let value = PlaceAppDestinationPick.coordinateValue(
            PlaceCoordinate(latitude: 51.5152, longitude: -0.1418)
        )

        let link = try XCTUnwrap(directions.resolved(with: value))

        XCTAssertEqual(link, "maps://?daddr=51.51520%2C-0.14180")
        XCTAssertNotNil(URL(string: link))
    }
}

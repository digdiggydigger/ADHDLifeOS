//
//  PlaceEditorValidationTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// What the place editor will and won't let E save (F-Location-PlacesUI).
///
/// A place with no name is unusable in a picker; a place with no coordinate cannot be geofenced
/// at all. Both are cheap to prevent here and expensive to discover later, when a nudge silently
/// never fires because the region was never valid.
final class PlaceEditorValidationTests: XCTestCase {

    private let coordinate = PlaceCoordinate(latitude: 51.5152, longitude: -0.1418)

    // MARK: - Name

    func testName_isTrimmed() {
        XCTAssertEqual(PlaceEditorValidation.normalizedName("  The office \n"), "The office")
    }

    func testName_thatIsEmptyOrWhitespaceOnly_isRejected() {
        XCTAssertNil(PlaceEditorValidation.normalizedName(""))
        XCTAssertNil(PlaceEditorValidation.normalizedName("   "))
        XCTAssertNil(PlaceEditorValidation.normalizedName("\n\t "))
    }

    func testName_keepsInternalPunctuationAndSpacing() {
        XCTAssertEqual(PlaceEditorValidation.normalizedName("Mum & Dad's"), "Mum & Dad's")
    }

    /// A runaway name breaks the row layout and the geofence's notification text. Truncated
    /// rather than rejected — silently losing what E typed is worse than shortening it.
    func testName_longerThanTheLimit_isTruncatedNotRejected() {
        let long = String(repeating: "a", count: PlaceEditorValidation.maximumNameLength + 40)

        let normalized = PlaceEditorValidation.normalizedName(long)

        XCTAssertEqual(normalized?.count, PlaceEditorValidation.maximumNameLength)
    }

    // MARK: - Saveability

    func testCanSave_needsBothANameAndACoordinate() {
        XCTAssertTrue(PlaceEditorValidation.canSave(name: "Gym", coordinate: coordinate))
        XCTAssertFalse(PlaceEditorValidation.canSave(name: "  ", coordinate: coordinate))
        XCTAssertFalse(PlaceEditorValidation.canSave(name: "Gym", coordinate: nil))
        XCTAssertFalse(PlaceEditorValidation.canSave(name: "", coordinate: nil))
    }

    // MARK: - Building the place

    func testMakePlace_appliesTheNormalizedNameAndClampedRadius() throws {
        let place = try XCTUnwrap(
            PlaceEditorValidation.makePlace(
                id: UUID(),
                name: "  Gym  ",
                coordinate: coordinate,
                radiusMetres: 10,
                emoji: "🏋️"
            )
        )

        XCTAssertEqual(place.name, "Gym")
        XCTAssertEqual(place.radiusMetres, Place.minimumRadiusMetres)
        XCTAssertEqual(place.emoji, "🏋️")
    }

    func testMakePlace_returnsNilWhenItCannotBeSaved() {
        XCTAssertNil(
            PlaceEditorValidation.makePlace(
                id: UUID(), name: "   ", coordinate: coordinate, radiusMetres: 200, emoji: nil
            )
        )
        XCTAssertNil(
            PlaceEditorValidation.makePlace(
                id: UUID(), name: "Gym", coordinate: nil, radiusMetres: 200, emoji: nil
            )
        )
    }

    /// An emoji field left empty must store `nil`, not `""` — an empty string would render as a
    /// blank glyph slot everywhere the identity emoji is shown.
    func testMakePlace_treatsABlankEmojiAsAbsent() throws {
        let place = try XCTUnwrap(
            PlaceEditorValidation.makePlace(
                id: UUID(), name: "Gym", coordinate: coordinate, radiusMetres: 200, emoji: "  "
            )
        )

        XCTAssertNil(place.emoji)
    }

    /// Editing must preserve the id and the original creation date — a save that mints a new id
    /// would orphan every record already tagged with this place.
    func testMakePlace_preservesAnExistingIdAndCreationDate() throws {
        let id = UUID()
        let created = Date(timeIntervalSince1970: 1_700_000_000)

        let place = try XCTUnwrap(
            PlaceEditorValidation.makePlace(
                id: id, name: "Gym", coordinate: coordinate, radiusMetres: 200,
                emoji: nil, createdAt: created
            )
        )

        XCTAssertEqual(place.id, id)
        XCTAssertEqual(place.createdAt, created)
    }
}

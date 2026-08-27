//
//  CaptureLocationChoiceTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The per-capture location switch, and what a capture row says about where it happened
/// (E's 2026-08-27 request).
///
/// E's rules, settled by question: the switch lives in the COMPOSER (decided before saving, so the
/// coordinate recorded is always the true one — flipping it on afterwards would stamp where you
/// are now, not where you were); it DEFAULTS to the global Settings toggle and overrides it for
/// that capture only; and a capture taken outside every named place shows NOTHING on its row.
final class CaptureLocationChoiceTests: XCTestCase {

    // MARK: - The default the composer opens with

    func testDefault_followsTheGlobalSettingWhenAuthorized() {
        XCTAssertTrue(
            CaptureLocationChoice.defaultValue(globalEnabled: true, authorization: .whenInUse)
        )
        XCTAssertFalse(
            CaptureLocationChoice.defaultValue(globalEnabled: false, authorization: .whenInUse)
        )
    }

    /// Without permission the switch cannot mean anything — defaulting it on would show a control
    /// promising something the app cannot deliver.
    func testDefault_isOffWithoutPermissionEvenWhenTheGlobalSettingIsOn() {
        XCTAssertFalse(
            CaptureLocationChoice.defaultValue(globalEnabled: true, authorization: .denied)
        )
        XCTAssertFalse(
            CaptureLocationChoice.defaultValue(globalEnabled: true, authorization: .notDetermined)
        )
    }

    func testDefault_worksOnWhenInUse_notJustAlways() {
        XCTAssertTrue(
            CaptureLocationChoice.defaultValue(globalEnabled: true, authorization: .always)
        )
        XCTAssertTrue(
            CaptureLocationChoice.defaultValue(globalEnabled: true, authorization: .whenInUse)
        )
    }

    // MARK: - Whether to show the switch at all

    /// A switch that cannot do anything is worse than no switch — it invites a tap that silently
    /// achieves nothing.
    func testAvailability_needsPermission() {
        XCTAssertTrue(CaptureLocationChoice.isAvailable(authorization: .whenInUse))
        XCTAssertTrue(CaptureLocationChoice.isAvailable(authorization: .always))
        XCTAssertFalse(CaptureLocationChoice.isAvailable(authorization: .denied))
        XCTAssertFalse(CaptureLocationChoice.isAvailable(authorization: .restricted))
        XCTAssertFalse(CaptureLocationChoice.isAvailable(authorization: .notDetermined))
    }

    /// The switch stays available when the GLOBAL setting is off, so E can opt a single capture
    /// in — that is what "override" means, and it has to work in both directions.
    func testAvailability_doesNotDependOnTheGlobalSetting() {
        XCTAssertTrue(CaptureLocationChoice.isAvailable(authorization: .whenInUse))
    }

    // MARK: - What the row says

    private func place(_ name: String, emoji: String?) -> Place {
        Place(
            id: UUID(),
            name: name,
            coordinate: PlaceCoordinate(latitude: 51.5, longitude: -0.14),
            radiusMetres: 200,
            emoji: emoji
        )
    }

    private func capture(placeId: UUID?, latitude: Double? = 51.5) -> Capture {
        Capture(
            id: UUID(), content: "Buy milk", kind: .note, processed: false, createdAt: Date(),
            placeId: placeId, latitude: latitude, longitude: -0.14
        )
    }

    func testLabel_insideANamedPlace_showsItsEmojiAndName() {
        let office = place("The office", emoji: "🏢")

        XCTAssertEqual(
            CapturePlaceLabel.label(for: capture(placeId: office.id), places: [office]),
            "🏢 The office"
        )
    }

    /// A place with no emoji still reads cleanly — no leading space, no orphan glyph slot.
    func testLabel_forAPlaceWithNoEmoji_isJustTheName() {
        let office = place("The office", emoji: nil)

        XCTAssertEqual(
            CapturePlaceLabel.label(for: capture(placeId: office.id), places: [office]),
            "The office"
        )
    }

    /// E's call: a coordinate outside every named place shows NOTHING. A bare coordinate means
    /// little at a glance, and most captures happen away from a saved place — a line on every row
    /// would be noise in a list that exists to be scanned.
    func testLabel_withACoordinateButNoNamedPlace_isAbsent() {
        XCTAssertNil(CapturePlaceLabel.label(for: capture(placeId: nil), places: []))
    }

    func testLabel_withNoLocationAtAll_isAbsent() {
        XCTAssertNil(
            CapturePlaceLabel.label(for: capture(placeId: nil, latitude: nil), places: [])
        )
    }

    /// A place deleted after the capture was made leaves a dangling id. That must read as no
    /// label rather than crashing or showing a raw UUID.
    func testLabel_whenThePlaceHasSinceBeenDeleted_isAbsent() {
        XCTAssertNil(
            CapturePlaceLabel.label(for: capture(placeId: UUID()), places: [place("Other", emoji: "🏠")])
        )
    }

    /// The label follows the place's CURRENT name — renaming a place updates every row that
    /// references it, which is the whole reason the id is stored rather than the name.
    func testLabel_reflectsThePlacesCurrentName() {
        let id = UUID()
        let renamed = Place(
            id: id, name: "HQ",
            coordinate: PlaceCoordinate(latitude: 51.5, longitude: -0.14),
            radiusMetres: 200, emoji: "🏢"
        )

        XCTAssertEqual(
            CapturePlaceLabel.label(for: capture(placeId: id), places: [renamed]),
            "🏢 HQ"
        )
    }
}

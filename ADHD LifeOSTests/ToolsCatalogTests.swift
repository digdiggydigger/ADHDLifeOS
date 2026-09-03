//
//  ToolsCatalogTests.swift
//  ADHD LifeOSTests
//
//  The Tools tab's contents, as a pure list. The page itself is a SwiftUI body and therefore
//  ~0% covered by design, so every rule that can be answered without a renderer lives here —
//  the `PlaceAppPickerPresentation` house pattern.
//
//  The load-bearing test is `testPlacesAbsentWhereItIsUnsupported`. `PlacesListView` is
//  `@available(iOS 17.0, *)` and this app's floor is **16.0**, so the page has to survive Places
//  simply not existing. That never shows up on the 26.5 simulator every build here runs on — it
//  would ship broken to a 16.x phone and nothing in the suite would have said a word.
//

import XCTest
@testable import ADHD_LifeOS

final class ToolsCatalogTests: XCTestCase {

    // MARK: - What the page holds

    func testPlacesSupportedGivesBothDoorsWithPlacesFirst() {
        let entries = ToolsCatalog.available(placesSupported: true)

        XCTAssertEqual(
            entries.map(\.destination), [.places, .lifeAreas],
            "The Tools page's order changed. Places leads: it is the door that MOVED here and has"
                + " nowhere else to be reached from, while Life Areas keeps its Settings door too."
        )
    }

    /// **The iOS 16 test.** With Places gated away the page must still be a page.
    func testPlacesAbsentWhereItIsUnsupported() {
        let entries = ToolsCatalog.available(placesSupported: false)

        XCTAssertEqual(
            entries.map(\.destination), [.lifeAreas],
            "On a build without Places the catalog still offers it. `PlacesListView` is iOS 17+"
                + " and the app floor is 16.0 — this is the one case the simulator never shows."
        )
    }

    /// Life Areas is the floor's whole page, so it can never be the entry that gets gated.
    func testLifeAreasSurvivesBothModes() {
        for supported in [true, false] {
            XCTAssertTrue(
                ToolsCatalog.available(placesSupported: supported)
                    .contains(where: { $0.destination == .lifeAreas }),
                "Life Areas vanished with placesSupported: \(supported). On iOS 16 that leaves the"
                    + " Tools tab empty — a station on the bar with nothing behind it."
            )
        }
    }

    // MARK: - Every entry is a finished card

    func testEveryEntryCarriesCopyAndAGlyph() {
        for entry in ToolsCatalog.available(placesSupported: true) {
            XCTAssertFalse(entry.title.isEmpty, "\(entry.destination) has no title.")
            XCTAssertFalse(
                entry.caption.isEmpty,
                "\(entry.destination) has no caption. A bento card with a bare title is the"
                    + " Settings row this page was chosen INSTEAD of."
            )
            XCTAssertFalse(entry.systemImage.isEmpty, "\(entry.destination) has no glyph.")
        }
    }

    func testIdentifiersAreNamespacedAndUnique() {
        let identifiers = ToolsCatalog.available(placesSupported: true)
            .map(\.accessibilityIdentifier)

        XCTAssertEqual(
            Set(identifiers).count, identifiers.count,
            "Two Tools cards share an accessibility identifier, so a journey addressing one gets"
                + " an ambiguous match rather than a card."
        )
        for identifier in identifiers {
            XCTAssertTrue(
                identifier.hasPrefix("toolsCard."),
                "\(identifier) is not namespaced to this page."
            )
        }
    }

    // MARK: - Sparseness is a decision, not an accident

    /// E's instruction for this page was *sparse* — Places, Life Areas, and room left over so
    /// Routines has an obvious home when it lands. A third card arriving without that decision
    /// being made again is what this pins.
    func testThePageStaysSparse() {
        XCTAssertEqual(
            ToolsCatalog.available(placesSupported: true).count, 2,
            "The Tools page grew a third card. E asked for it left sparse so Routines has"
                + " somewhere obvious to land — if that is what arrived, update this number and"
                + " the doc comment together."
        )
    }

    /// `Destination` is what the page switches on to build its push, so a case added here without
    /// a card is a door with nothing behind it.
    func testEveryDestinationHasAnEntry() {
        let offered = Set(ToolsCatalog.available(placesSupported: true).map(\.destination))

        XCTAssertEqual(
            offered, Set(ToolsCatalog.Destination.allCases),
            "A `ToolsCatalog.Destination` exists that no entry offers, so nothing on the page can"
                + " reach it."
        )
    }
}

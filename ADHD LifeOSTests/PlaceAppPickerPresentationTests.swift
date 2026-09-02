//
//  PlaceAppPickerPresentationTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The pure presentation helpers behind the app-directory design pass (E's 2026-09-02 device
/// verdict: "ugly and plain"): the monogram initial each row's avatar disc shows, the
/// Popular / All-apps browse split, and the kind glyphs the editor's Action picker carries.
final class PlaceAppPickerPresentationTests: XCTestCase {

    private func entry(_ name: String, scheme: String, rank: Int) -> PlaceAppDirectoryEntry {
        PlaceAppDirectoryEntry(
            scheme: scheme, name: name, keywords: [], universalLinkHosts: [],
            destinations: [], rank: rank, hidden: false
        )
    }

    // MARK: - Monogram

    func testMonogram_isTheFirstCharacterUppercased() {
        XCTAssertEqual(PlaceAppPickerPresentation.monogram(for: "spotify"), "S")
        XCTAssertEqual(PlaceAppPickerPresentation.monogram(for: "WhatsApp"), "W")
    }

    func testMonogram_survivesLeadingWhitespaceAndEmpty() {
        XCTAssertEqual(PlaceAppPickerPresentation.monogram(for: "  uber"), "U")
        XCTAssertEqual(PlaceAppPickerPresentation.monogram(for: ""), "")
    }

    // MARK: - Browse split

    func testBrowseSplit_popularKeepsRankOrder_restIsAlphabetical() {
        let ranked = [
            entry("Spotify", scheme: "spotify", rank: 1),
            entry("WhatsApp", scheme: "whatsapp", rank: 2),
            entry("Zoom", scheme: "zoomus", rank: 3),
            entry("Deliveroo", scheme: "deliveroo", rank: 4)
        ]

        let split = PlaceAppPickerPresentation.browseSplit(ranked, popularCount: 2)

        XCTAssertEqual(split.popular.map(\.name), ["Spotify", "WhatsApp"])
        XCTAssertEqual(
            split.rest.map(\.name), ["Deliveroo", "Zoom"],
            "The long tail reads alphabetically — rank stops meaning anything down there"
        )
    }

    func testBrowseSplit_shortListIsAllPopular() {
        let ranked = [entry("Spotify", scheme: "spotify", rank: 1)]

        let split = PlaceAppPickerPresentation.browseSplit(ranked, popularCount: 8)

        XCTAssertEqual(split.popular.map(\.name), ["Spotify"])
        XCTAssertTrue(split.rest.isEmpty)
    }

    // MARK: - Kind glyphs

    func testEveryKindChoice_carriesAGlyph() {
        for choice in PlaceActionDraft.KindChoice.allCases {
            XCTAssertFalse(
                PlaceAppPickerPresentation.kindGlyph(for: choice).isEmpty,
                "\(choice) has no glyph"
            )
        }
    }
}

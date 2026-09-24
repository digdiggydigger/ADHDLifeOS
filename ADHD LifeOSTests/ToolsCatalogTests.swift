//
//  ToolsCatalogTests.swift
//  ADHD LifeOSTests
//
//  The Tools tab's contents, as a pure list. The page itself is a SwiftUI body and therefore
//  ~0% covered by design, so every rule that can be answered without a renderer lives here —
//  the `PlaceAppPickerPresentation` house pattern.
//
//  **The `placesSupported` half of this file was REVERSED by `F-Floor18`** (E, 2026-09-23). Until
//  then `available(placesSupported:)` took a `Bool` and the load-bearing test was the one that
//  proved the page survived Places not existing on the old 16.0 floor. At the 18 floor Places is
//  universal, the catalog is a constant list, and what is pinned instead is that Places is ALWAYS
//  offered — a flag creeping back would look like caution and ship a card that vanishes for no one.
//

import XCTest
@testable import ADHD_LifeOS

final class ToolsCatalogTests: XCTestCase {

    // MARK: - What the page holds

    func testBothDoorsAreOfferedWithPlacesFirst() {
        XCTAssertEqual(
            ToolsCatalog.entries.map(\.destination), [.places, .lifeAreas],
            "The Tools page's order changed. Places leads: it is the door that MOVED here and has"
                + " nowhere else to be reached from, while Life Areas keeps its Settings door too."
        )
    }

    /// **REVERSED by `F-Floor18`.** This was `testPlacesAbsentWhereItIsUnsupported`: with
    /// `placesSupported: false` the catalog had to answer `[.lifeAreas]` so the page survived the
    /// old 16.0 floor, where Places did not exist. Nothing is absent at 18, so the pin is now that
    /// Places is offered unconditionally — there is no flag left to pass, and the source read
    /// below is what stops one coming back.
    func testPlacesIsAlwaysOffered_thereIsNoSupportFlag() throws {
        XCTAssertTrue(
            ToolsCatalog.entries.contains(where: { $0.destination == .places }),
            "Places is missing from the catalog. Since F-Floor18 it is universal: the only door"
                + " into Places is this card."
        )
        let source = try Self.code("Tools/ToolsCatalog.swift")
        XCTAssertFalse(
            source.contains("placesSupported"),
            "`placesSupported` is back in `ToolsCatalog`. The iOS 18 floor made Places universal;"
                + " a flag here would ship a card that vanishes for nobody and reopen the one"
                + " case no simulator on this machine can show."
        )
    }

    /// Life Areas has two doors (Settings and here); this one must never go missing.
    func testLifeAreasIsOffered() {
        XCTAssertTrue(
            ToolsCatalog.entries.contains(where: { $0.destination == .lifeAreas }),
            "Life Areas vanished from the Tools page."
        )
    }

    // MARK: - Every entry is a finished card

    func testEveryEntryCarriesCopyAndAGlyph() {
        for entry in ToolsCatalog.entries {
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
        let identifiers = ToolsCatalog.entries
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
            ToolsCatalog.entries.count, 2,
            "The Tools page grew a third card. E asked for it left sparse so Routines has"
                + " somewhere obvious to land — if that is what arrived, update this number and"
                + " the doc comment together."
        )
    }

    /// `Destination` is what the page switches on to build its push, so a case added here without
    /// a card is a door with nothing behind it.
    func testEveryDestinationHasAnEntry() {
        let offered = Set(ToolsCatalog.entries.map(\.destination))

        XCTAssertEqual(
            offered, Set(ToolsCatalog.Destination.allCases),
            "A `ToolsCatalog.Destination` exists that no entry offers, so nothing on the page can"
                + " reach it."
        )
    }

    // MARK: - Reading the tree

    /// Comment lines stripped, because this file's own history names the flag it asserts absent.
    private static func code(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // ADHD LifeOSTests
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("ADHD LifeOS")
            .appendingPathComponent(relativePath)
        let text = try String(contentsOf: url, encoding: .utf8)
        return text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }
}

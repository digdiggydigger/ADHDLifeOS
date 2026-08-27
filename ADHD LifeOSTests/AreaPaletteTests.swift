//
//  AreaPaletteTests.swift
//  ADHD LifeOSTests
//

import UIKit
import XCTest
@testable import ADHD_LifeOS

/// The Momentum v3 identity palette gives every life area one of five hue families (work blue,
/// health teal, admin gold, growth purple, hobby pink), each a four-token set: base (label-safe),
/// vivid (fills/bars), tint (washes) and on (text over a solid fill). `LifeArea.colour` stores an
/// EMOJI by app-wide convention, so the resolver maps emoji → family, with a fallback that must be
/// stable across launches (UUID-derived, never `hashValue` — that's salted per process).
final class AreaPaletteTests: XCTestCase {
    private func area(_ emoji: String, id: UUID = UUID()) -> LifeArea {
        LifeArea(id: id, name: "Area", colour: emoji, sortOrder: 0)
    }

    // The six seeded areas plus the four emoji the v3 file itself draws. Money shares admin's
    // gold (six areas, five families — one repeat is forced; gold suits 💰 best).
    func testSeededAndV3EmojiMapToTheirFamilies() {
        XCTAssertEqual(AreaPalette.family(for: area("🫀")), .health)
        XCTAssertEqual(AreaPalette.family(for: area("💼")), .work)
        XCTAssertEqual(AreaPalette.family(for: area("🏠")), .admin)
        XCTAssertEqual(AreaPalette.family(for: area("💰")), .admin)
        XCTAssertEqual(AreaPalette.family(for: area("💬")), .hobby)
        XCTAssertEqual(AreaPalette.family(for: area("🌱")), .growth)
        XCTAssertEqual(AreaPalette.family(for: area("🏋️")), .health)
        XCTAssertEqual(AreaPalette.family(for: area("📝")), .admin)
        XCTAssertEqual(AreaPalette.family(for: area("🧘")), .growth)
        XCTAssertEqual(AreaPalette.family(for: area("🎨")), .hobby)
    }

    // U+FE0F (variation selector) must not split an emoji into two identities — the seed writes
    // bare emoji while pickers can produce the FE0F form.
    func testVariationSelectorFormsResolveIdentically() {
        XCTAssertEqual(AreaPalette.family(for: area("🏋\u{FE0F}")), AreaPalette.family(for: area("🏋")))
    }

    // Unknown emoji: the first UUID byte picks the family, so the assignment survives relaunches,
    // renames and reorders. allCases order is part of the contract.
    func testUnknownEmojiFallbackIsUUIDStable() {
        let first = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        let second = UUID(uuidString: "03000000-0000-0000-0000-000000000000")!
        XCTAssertEqual(AreaPalette.family(for: area("🦖", id: first)), .work)
        XCTAssertEqual(AreaPalette.family(for: area("🦖", id: second)), .growth)
        XCTAssertEqual(
            AreaPalette.family(for: area("🦖", id: first)),
            AreaPalette.family(for: area("🦖", id: first))
        )
    }

    func testFamilyAssetNamesFollowTheTokenConvention() {
        XCTAssertEqual(AreaPalette.work.assetName, "AreaWork")
        XCTAssertEqual(AreaPalette.work.vividAssetName, "AreaWorkVivid")
        XCTAssertEqual(AreaPalette.work.tintAssetName, "AreaWorkTint")
        XCTAssertEqual(AreaPalette.work.onAssetName, "OnAreaWork")
    }

    func testEveryFamilyTokenExistsInTheAssetCatalog() {
        let bundle = Bundle(for: ADHD_LifeOS.FirebaseManager.self)
        for family in AreaPalette.allCases {
            for name in [family.assetName, family.vividAssetName, family.tintAssetName, family.onAssetName] {
                XCTAssertNotNil(
                    UIColor(named: name, in: bundle, compatibleWith: nil),
                    "Colorset '\(name)' is missing from the asset catalog"
                )
            }
        }
    }

    // MARK: - Stored override (E's 2026-08-25 note: assignable area colours)

    func testStoredPaletteKeyBeatsTheEmojiMapping() {
        let overridden = LifeArea(
            id: UUID(), name: "Work", colour: "💼", sortOrder: 0, palette: "growth"
        )
        XCTAssertEqual(AreaPalette.family(for: overridden), .growth)
    }

    /// A key this build doesn't recognise resolves to AUTOMATIC, not to a crash or an arbitrary
    /// pin — the same resolve-to-safe posture as `FirebaseEmulatorSettings`.
    func testMalformedStoredKeyFallsBackToAutomatic() {
        let broken = LifeArea(
            id: UUID(), name: "Work", colour: "💼", sortOrder: 0, palette: "sparkle"
        )
        XCTAssertEqual(AreaPalette.family(for: broken), .work)
    }

    func testWireKeysRoundTripAndAreNotAssetNames() {
        for family in AreaPalette.allCases {
            XCTAssertEqual(AreaPalette(key: family.key), family, "\(family) must round-trip")
        }
        XCTAssertEqual(AreaPalette.work.key, "work")
        XCTAssertNil(AreaPalette(key: "AreaWork"), "asset catalog names are not wire keys")
    }

    func testEveryFamilyHasAColourDisplayName() {
        XCTAssertEqual(AreaPalette.work.displayName, "Blue")
        XCTAssertEqual(AreaPalette.health.displayName, "Teal")
        XCTAssertEqual(AreaPalette.admin.displayName, "Gold")
        XCTAssertEqual(AreaPalette.growth.displayName, "Purple")
        XCTAssertEqual(AreaPalette.hobby.displayName, "Pink")
    }

    // MARK: - The four explicit-only colours (SUGG-b3, E's picks: Green, Orange, Red, Slate)

    func testExplicitOnlyFamilies_roundTripTheirKeys() {
        XCTAssertEqual(AreaPalette(key: "green"), .green)
        XCTAssertEqual(AreaPalette(key: "orange"), .orange)
        XCTAssertEqual(AreaPalette(key: "red"), .red)
        XCTAssertEqual(AreaPalette(key: "slate"), .slate)
    }

    /// Adding colours must not repaint anyone's areas uninvited: the automatic fallback for an
    /// unmapped emoji keeps choosing from the ORIGINAL five families, whatever `allCases` grows
    /// to. The new colours are reachable only by explicit choice in the editor.
    func testAutomaticFallback_staysWithinTheOriginalFive() {
        let original: Set<AreaPalette> = [.work, .health, .admin, .growth, .hobby]
        for _ in 0..<64 {
            let area = LifeArea(id: UUID(), name: "Any", colour: "🦖", sortOrder: 0)
            XCTAssertTrue(
                original.contains(AreaPalette.family(for: area)),
                "an automatic hue must never be one of the explicit-only colours"
            )
        }
    }
}

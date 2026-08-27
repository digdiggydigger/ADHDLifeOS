//
//  EmojiPaletteTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The curated emoji palettes' invariants.
///
/// These are worth testing precisely because the palettes are hand-typed literals. The picker's
/// whole safety story is "tapping the grid can only ever produce a valid selection" — which is
/// true only if every entry really is ONE grapheme cluster. Paste in a glyph that is secretly two
/// (a base emoji plus a stray variation selector, say) and the grid silently starts writing values
/// the free-type field would have rejected.
final class EmojiPaletteTests: XCTestCase {

    private func assertSingleGlyphs(
        _ palette: [String],
        name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for emoji in palette {
            XCTAssertEqual(
                EmojiValidation.validate(emoji),
                .valid(emoji),
                "\(name) entry \(emoji) is not a single grapheme cluster",
                file: file,
                line: line
            )
        }
    }

    func testLifeAreaPalette_isAllSingleGlyphs() {
        assertSingleGlyphs(EmojiPalette.lifeArea, name: "lifeArea")
    }

    func testPlacePalette_isAllSingleGlyphs() {
        assertSingleGlyphs(EmojiPalette.place, name: "place")
    }

    /// A duplicate would render two identical cells that both look selected at once.
    func testPalettes_haveNoDuplicates() {
        XCTAssertEqual(Set(EmojiPalette.lifeArea).count, EmojiPalette.lifeArea.count)
        XCTAssertEqual(Set(EmojiPalette.place).count, EmojiPalette.place.count)
    }

    func testPalettes_areNotEmpty() {
        XCTAssertFalse(EmojiPalette.lifeArea.isEmpty)
        XCTAssertFalse(EmojiPalette.place.isEmpty)
    }

    /// The place palette exists because the life-area one is the wrong vocabulary for somewhere
    /// you GO — "🧠 ❤️ 🎯" name themes, not destinations. If they ever converge, the split has
    /// stopped earning its keep.
    func testPlacePalette_isMeaningfullyDifferentFromLifeAreas() {
        let shared = Set(EmojiPalette.place).intersection(Set(EmojiPalette.lifeArea))

        XCTAssertLessThan(
            shared.count,
            EmojiPalette.place.count / 2,
            "the place palette has drifted back toward the life-area one"
        )
    }

    // MARK: - The validation the picker leans on

    func testValidation_rejectsMultipleGlyphsAndPlainText() {
        XCTAssertEqual(EmojiValidation.validate("🏠🏢"), .invalidNotSingleGlyph)
        XCTAssertEqual(EmojiValidation.validate("ab"), .invalidNotSingleGlyph)
        XCTAssertEqual(EmojiValidation.validate("   "), .invalidEmpty)
    }

    /// A multi-scalar emoji (skin tone, ZWJ family) is still ONE glyph and must be accepted —
    /// counting scalars rather than characters would wrongly reject these.
    func testValidation_acceptsMultiScalarEmoji() {
        XCTAssertEqual(EmojiValidation.validate("👨‍👩‍👧‍👦"), .valid("👨‍👩‍👧‍👦"))
        XCTAssertEqual(EmojiValidation.validate("🏋️"), .valid("🏋️"))
    }
}

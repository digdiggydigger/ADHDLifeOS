//
//  LifeAreaEditorValidationTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class LifeAreaEditorValidationTests: XCTestCase {

    // MARK: renameChange

    func test_renameChange_emptyAfterTrim_isInvalidEmpty() {
        XCTAssertEqual(LifeAreaEditorValidation.renameChange(current: "Work", proposed: "   "), .invalidEmpty)
    }

    func test_renameChange_unchangedAfterTrim_isUnchanged() {
        XCTAssertEqual(LifeAreaEditorValidation.renameChange(current: "Work", proposed: "  Work  "), .unchanged)
    }

    func test_renameChange_trimmedDifferent_isValidTrimmed() {
        XCTAssertEqual(
            LifeAreaEditorValidation.renameChange(current: "Work", proposed: "  Health  "),
            .valid("Health")
        )
    }

    // MARK: normalizeNewName

    func test_normalizeNewName_trimsAndKeeps() {
        XCTAssertEqual(LifeAreaEditorValidation.normalizeNewName("  Garden  "), "Garden")
    }

    func test_normalizeNewName_emptyIsNil() {
        XCTAssertNil(LifeAreaEditorValidation.normalizeNewName("   "))
    }

    // MARK: validateEmoji — the one-grapheme rule

    func test_validateEmoji_empty_isInvalidEmpty() {
        XCTAssertEqual(LifeAreaEditorValidation.validateEmoji("   "), .invalidEmpty)
    }

    func test_validateEmoji_twoCharacters_isInvalidNotSingleGlyph() {
        XCTAssertEqual(LifeAreaEditorValidation.validateEmoji("ab"), .invalidNotSingleGlyph)
    }

    func test_validateEmoji_twoEmoji_isInvalidNotSingleGlyph() {
        XCTAssertEqual(LifeAreaEditorValidation.validateEmoji("🏠💼"), .invalidNotSingleGlyph)
    }

    func test_validateEmoji_singleSimpleEmoji_isValid() {
        XCTAssertEqual(LifeAreaEditorValidation.validateEmoji("🏠"), .valid("🏠"))
    }

    func test_validateEmoji_multiScalarFamilyEmoji_isValid() {
        // "👨‍👩‍👧‍👦" is several Unicode scalars joined by ZWJ but ONE grapheme cluster → count == 1 → valid.
        let family = "👨‍👩‍👧‍👦"
        XCTAssertEqual(family.count, 1, "precondition: family emoji is a single Character")
        XCTAssertEqual(LifeAreaEditorValidation.validateEmoji("  \(family)  "), .valid(family))
    }

    func test_validateEmoji_singleLetter_isValidSingleGlyph() {
        // The rule is one grapheme cluster, not "must be an emoji" — a single letter passes here and
        // the backend accepts any non-empty string. Documents the deliberate scope of the client rule.
        XCTAssertEqual(LifeAreaEditorValidation.validateEmoji("A"), .valid("A"))
    }
}

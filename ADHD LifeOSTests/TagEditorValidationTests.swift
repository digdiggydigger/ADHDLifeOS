//
//  TagEditorValidationTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class TagEditorValidationTests: XCTestCase {

    // MARK: renameChange

    func test_renameChange_whitespaceOnly_isInvalidEmpty() {
        XCTAssertEqual(TagEditorValidation.renameChange(current: "work", proposed: "   "), .invalidEmpty)
        XCTAssertEqual(TagEditorValidation.renameChange(current: "work", proposed: ""), .invalidEmpty)
    }

    func test_renameChange_sameNameAfterTrim_isUnchanged() {
        XCTAssertEqual(TagEditorValidation.renameChange(current: "work", proposed: "work"), .unchanged)
        XCTAssertEqual(TagEditorValidation.renameChange(current: "work", proposed: "  work  "), .unchanged)
    }

    func test_renameChange_differentName_isValidAndTrimmed() {
        XCTAssertEqual(
            TagEditorValidation.renameChange(current: "work", proposed: "  errands  "),
            .valid("errands")
        )
    }

    // MARK: normalizeNewName

    func test_normalizeNewName_trimsAndRejectsEmpty() {
        XCTAssertNil(TagEditorValidation.normalizeNewName(""))
        XCTAssertNil(TagEditorValidation.normalizeNewName("   \n"))
        XCTAssertEqual(TagEditorValidation.normalizeNewName("  errands  "), "errands")
    }
}

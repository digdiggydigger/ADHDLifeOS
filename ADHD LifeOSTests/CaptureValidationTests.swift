//
//  CaptureValidationTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class CaptureValidationTests: XCTestCase {

    func testNormalizeCreateCaptureInput_trimsContent() {
        let result = CaptureValidation.normalizeCreateCaptureInput(content: "  Buy milk  ", kind: .note)

        switch result {
        case .success(let normalized):
            XCTAssertEqual(normalized.content, "Buy milk")
            XCTAssertEqual(normalized.kind, .note)
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testNormalizeCreateCaptureInput_emptyContent_fails() {
        let result = CaptureValidation.normalizeCreateCaptureInput(content: "   ", kind: .note)

        XCTAssertEqual(result, .failure(.emptyContent))
    }

    func testNormalizeCreateCaptureInput_whitespaceOnlyContent_fails() {
        let result = CaptureValidation.normalizeCreateCaptureInput(content: "\n\t ", kind: .task)

        XCTAssertEqual(result, .failure(.emptyContent))
    }

    func testNormalizeCreateCaptureInput_passesThroughEachKind() {
        for kind in CaptureKind.allCases {
            let result = CaptureValidation.normalizeCreateCaptureInput(content: "Something", kind: kind)

            switch result {
            case .success(let normalized):
                XCTAssertEqual(normalized.kind, kind)
            case .failure:
                XCTFail("Expected success for kind \(kind)")
            }
        }
    }

    func testDefaultKind_isNote() {
        XCTAssertEqual(CaptureValidation.defaultKind, .note)
    }

    // MARK: - Link normalization

    func testNormalizeCreateCaptureInput_linkKind_addsHTTPSSchemeWhenMissing() {
        let result = CaptureValidation.normalizeCreateCaptureInput(content: "example.com/article", kind: .link)

        switch result {
        case .success(let normalized):
            XCTAssertEqual(normalized.content, "https://example.com/article")
            XCTAssertEqual(normalized.kind, .link)
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testNormalizeCreateCaptureInput_linkKind_preservesExistingScheme() {
        let result = CaptureValidation.normalizeCreateCaptureInput(content: "http://example.com", kind: .link)

        switch result {
        case .success(let normalized):
            XCTAssertEqual(normalized.content, "http://example.com")
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testNormalizeCreateCaptureInput_linkKind_trimsSurroundingWhitespace() {
        let result = CaptureValidation.normalizeCreateCaptureInput(content: "  example.com  ", kind: .link)

        switch result {
        case .success(let normalized):
            XCTAssertEqual(normalized.content, "https://example.com")
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testNormalizeCreateCaptureInput_linkKind_emptyInput_failsWithInvalidURL() {
        let result = CaptureValidation.normalizeCreateCaptureInput(content: "   ", kind: .link)

        XCTAssertEqual(result, .failure(.invalidURL))
    }

    func testNormalizeCreateCaptureInput_linkKind_unsupportedScheme_failsWithInvalidURL() {
        let result = CaptureValidation.normalizeCreateCaptureInput(content: "ftp://example.com", kind: .link)

        XCTAssertEqual(result, .failure(.invalidURL))
    }

    func testNormalizeCreateCaptureInput_linkKind_textWithSpaces_failsWithInvalidURL() {
        let result = CaptureValidation.normalizeCreateCaptureInput(content: "not a url", kind: .link)

        XCTAssertEqual(result, .failure(.invalidURL))
    }

    func testNormalizedLinkURLString_validURLWithQueryAndPath_isPreserved() {
        let result = CaptureValidation.normalizedLinkURLString(from: "https://example.com/path?query=1")

        XCTAssertEqual(result, .success("https://example.com/path?query=1"))
    }
}

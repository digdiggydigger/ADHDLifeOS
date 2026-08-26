//
//  LinkPasteNormalizationTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// BUG-b6 (E's checklist, 2026-08-26): the link composer's paste button drops the clipboard into
/// the URL field. Clipboards are messy — a URL copied out of a note arrives with the newline that
/// followed it, a share-sheet copy with a trailing space — and a URL field must never hold
/// invisible whitespace the user can't see but validation trips over.
final class LinkPasteNormalizationTests: XCTestCase {
    func testCleanURLString_passesThrough() {
        XCTAssertEqual(
            LinkPasteNormalization.normalize("https://example.com/a?b=c"),
            "https://example.com/a?b=c"
        )
    }

    func testSurroundingWhitespaceAndNewlines_areTrimmed() {
        XCTAssertEqual(
            LinkPasteNormalization.normalize("  https://example.com \n"),
            "https://example.com"
        )
    }

    func testWhitespaceOnlyClipboard_normalizesToEmpty() {
        XCTAssertEqual(LinkPasteNormalization.normalize(" \n "), "")
    }
}

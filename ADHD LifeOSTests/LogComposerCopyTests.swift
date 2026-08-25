//
//  LogComposerCopyTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The v3 entry composer says what each type MEANS instead of assuming the split is obvious —
/// the S1 voice ("one question at a time, optional-ness said out loud"), applied to the journal.
final class LogComposerCopyTests: XCTestCase {
    func testExplainers_sayWhatEachTypeCarries() {
        XCTAssertEqual(
            LogComposerCopy.explainer(for: .log),
            "A quick line, saved as-is — no questions asked."
        )
        XCTAssertEqual(
            LogComposerCopy.explainer(for: .journal),
            "A fuller entry — energy and mood ride along."
        )
    }

    func testGuidanceAndFooter() {
        XCTAssertEqual(LogComposerCopy.guidance, "One honest line about now is enough.")
        XCTAssertEqual(
            LogComposerCopy.footer,
            "Entries are append-only — saved means saved."
        )
    }
}

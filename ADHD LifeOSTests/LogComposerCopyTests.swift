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

    /// The location switch says what THIS entry will do, and names the place when one resolves
    /// (E, 2026-08-31: "show the place while composing") — the capture composer's subtitle,
    /// upgraded with `JournalTimeline.placeLine`'s spelling ("at The Office 💼").
    func testLocationSubtitle_offSaysWontRecord() {
        XCTAssertEqual(
            LogComposerCopy.locationSubtitle(attach: false, placeLine: nil),
            "This entry won't record where you made it."
        )
        XCTAssertEqual(
            LogComposerCopy.locationSubtitle(attach: false, placeLine: "at The Office 💼"),
            "This entry won't record where you made it.",
            "off wins even when a stale place line is still around"
        )
    }

    func testLocationSubtitle_onWithoutANamedPlace_saysWillRecord() {
        XCTAssertEqual(
            LogComposerCopy.locationSubtitle(attach: true, placeLine: nil),
            "This entry will record where you made it."
        )
    }

    func testLocationSubtitle_onInsideANamedPlace_namesIt() {
        XCTAssertEqual(
            LogComposerCopy.locationSubtitle(attach: true, placeLine: "at The Office 💼"),
            "This entry will record you're at The Office 💼."
        )
    }
}

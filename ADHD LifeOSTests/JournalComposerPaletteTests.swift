//
//  JournalComposerPaletteTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The composer's surface, which now depends on WHICH kind of entry is being written (E,
/// 2026-08-28: "when the kind of entry selected equals journal, please turn this into a yellow
/// backgrounded view… just to spice it up a bit").
///
/// A pure decision rather than a ternary buried in the view body, for two reasons: the "leave Log
/// exactly as it is" half of that instruction is a real requirement that deserves a test of its
/// own, and the asset name is the token layer's business (§4 — no colour is spelled in Swift).
final class JournalComposerPaletteTests: XCTestCase {

    /// The half that is easy to break by accident while doing the half that was asked for.
    func testLogKeepsTheOrdinaryPageBackground() {
        XCTAssertEqual(JournalComposerPalette.backgroundAsset(for: .log), "PageBackground")
    }

    func testJournalGetsItsOwnPaperSurface() {
        XCTAssertEqual(JournalComposerPalette.backgroundAsset(for: .journal), "JournalPaper")
    }

    /// Exhaustive, so a third `LogType` has to decide what it looks like here rather than
    /// silently inheriting whichever branch the `switch` fell into.
    func testEveryEntryKindHasASurface() {
        for type in LogType.allCases {
            XCTAssertFalse(
                JournalComposerPalette.backgroundAsset(for: type).isEmpty,
                "\(type) has no composer surface"
            )
        }
    }

    /// The two surfaces must actually differ, or "spice it up" quietly became a no-op.
    func testTheTwoKindsDoNotLookTheSame() {
        XCTAssertNotEqual(
            JournalComposerPalette.backgroundAsset(for: .log),
            JournalComposerPalette.backgroundAsset(for: .journal)
        )
    }

    // MARK: - The legal-pad rule

    /// Only a journal entry gets the paper treatment — the page, the ink, the ruling. The pad has
    /// a day face and a night face now rather than one light face forced on both; the tokens carry
    /// that, so this only has to say WHO is paper.
    func testJournalIsPaper() {
        XCTAssertTrue(JournalComposerPalette.isPaper(for: .journal))
    }

    /// Log is untouched — the ordinary page, following the device exactly as every other screen
    /// does. This is the half of E's instruction that is easiest to break while chasing the other
    /// half, so it gets its own test rather than riding on the one above.
    func testLogIsNotPaper() {
        XCTAssertFalse(JournalComposerPalette.isPaper(for: .log))
    }

    /// The writing surface is the one card that must not stay grey: a grey-blue box on gold was
    /// the single worst thing in the first attempt on device.
    func testJournalGivesTheWritingBoxAWhiteSurface() {
        XCTAssertEqual(JournalComposerPalette.writingSurfaceAsset(for: .journal), "CardSurface")
        XCTAssertEqual(
            JournalComposerPalette.writingSurfaceAsset(for: .log), "CardSurfaceSecondary"
        )
    }
}

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
    /// the single worst thing in the first attempt on device — and `CardSurface` was only ever
    /// half a fix, because it is white by day but a COOL near-black by night. On a warm page that
    /// is the same mistake in the other appearance, so the pad now has its own warm sheet.
    func testJournalGivesTheWritingBoxItsOwnWarmSheet() {
        XCTAssertEqual(
            JournalComposerPalette.writingSurfaceAsset(for: .journal), "JournalPaperSurface"
        )
        XCTAssertEqual(
            JournalComposerPalette.writingSurfaceAsset(for: .log), "CardSurfaceSecondary"
        )
    }

    // MARK: - The balanced wardrobe (E, 2026-08-28)

    /// E's reframing: rather than keep hunting for a yellow that survives, redesign what SURROUNDS
    /// the yellow so a stronger one becomes possible. The clash was never one wrong gold — it was
    /// a warm page wearing a cool wardrobe: a blue accent at goldenrod's near-exact complement,
    /// cool-grey quiet chips, and a cool near-black writing box at night.
    func testJournalChipsAreMonochromeInkOnGold() {
        let pad = JournalComposerPalette.chipPalette(for: .journal)
        XCTAssertEqual(pad.quietSurface, "JournalPaperSurface")
        XCTAssertEqual(pad.quietLabel, "JournalPaperInk")
        // Selection is the pad's own ink, with the page colour as the label — no new hue at all.
        XCTAssertEqual(pad.selectedFill, "JournalPaperInk")
        XCTAssertEqual(pad.selectedLabel, "JournalPaper")
    }

    /// Every other composer keeps the app's accent. This is the half easiest to break while
    /// chasing the other, exactly like `testLogIsNotPaper`.
    func testOrdinaryComposersKeepTheAppAccent() {
        let ordinary = JournalComposerPalette.chipPalette(for: .log)
        XCTAssertEqual(ordinary.quietSurface, "CardSurfaceSecondary")
        XCTAssertEqual(ordinary.quietLabel, "LabelSecondary")
        XCTAssertEqual(ordinary.selectedFill, "AccentColor")
    }

    /// The desk the pad sits on. In LIGHT it is the pad's own gold, so the page still reads
    /// full-bleed and the day face E already approved is untouched; at night it goes dark and the
    /// pad becomes a lit object on it. One structure, two appearances, decided purely by tokens —
    /// no `colorScheme` branch anywhere.
    func testJournalSitsOnItsOwnChrome() {
        XCTAssertEqual(JournalComposerPalette.chromeAsset(for: .journal), "JournalPaperChrome")
        XCTAssertEqual(JournalComposerPalette.chromeAsset(for: .log), "PageBackground")
    }

    /// **There is no dimmed ink on this page, and that is arithmetic rather than preference.**
    /// The primary ink only clears AA at about 5.2:1 against the gold, so anything dimmed from it
    /// lands under 4.5:1 — measured at #6B4E12 on #DAA520 = 3.45:1. Hierarchy on the pad comes
    /// from type weight and size (§1), never from a lighter ink or an opacity (§4).
    func testJournalHasNoSecondaryInk() {
        XCTAssertEqual(
            JournalComposerPalette.inkAsset(for: .journal),
            JournalComposerPalette.softInkAsset(for: .journal),
            "the pad deliberately has ONE ink — a dimmed one cannot clear AA on gold"
        )
        XCTAssertEqual(JournalComposerPalette.softInkAsset(for: .log), "LabelSecondary")
    }
}

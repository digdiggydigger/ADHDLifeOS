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
    }

    /// **`nil` is the whole point, and it is what makes this reachable.**
    ///
    /// The previous shape returned `"LabelSecondary"` for a log, which is a perfectly good answer
    /// that no view could act on: an opaque `LabelSecondary` is NOT what `.foregroundStyle(.secondary)`
    /// paints today, so wiring it up would have quietly restyled the ordinary composer as a side
    /// effect of fixing the pad. Returning `nil` means "keep exactly what you already do", so the
    /// ordinary page is unchanged BY CONSTRUCTION and only the pad opts in — the containment
    /// pattern F-PadBalance established across ~20 call sites.
    func testTheOrdinaryPageOptsOutOfTheInkOverrideEntirely() {
        XCTAssertNil(
            JournalComposerPalette.softInkAsset(for: .log),
            "a log must keep its own `.secondary`, not be repainted while fixing the pad"
        )
    }

    /// **The footer and the desk are ONE surface, deliberately** (E, 2026-08-29: "do the header
    /// and gutters too").
    ///
    /// A day earlier the footer alone was lifted off a jet-black desk, because E had marked up only
    /// that band. Lifting the whole surround makes that split pointless: two tokens that can never
    /// differ are drift-bait, and the bar is already told apart by its hairline and by the cream
    /// Save button sitting on it. So `JournalPaperChrome` carries the warm desk in one place and
    /// the footer wears it.
    ///
    /// The value moved rather than the structure: chrome dark went `#1A1610` -> `#332C20`, a
    /// 1.31:1 lift, warm at hue 38°, and at 23% saturation against the ink's 85% it stays a surface
    /// rather than reading as ink. The step down from the gold page softens from 6.97:1 to 5.47:1,
    /// and the parchment chrome ink still clears 10.51:1 on it.
    ///
    /// This assertion is what a future re-split has to come through: it fails the moment the footer
    /// stops wearing the desk, which forces the reasoning to be written down again rather than
    /// rediscovered from a screenshot.
    func testThePadsFooterWearsTheDesk() {
        XCTAssertEqual(
            JournalComposerPalette.footerSurfaceAsset(for: .journal),
            JournalComposerPalette.chromeAsset(for: .journal),
            "the pad's footer and its desk are one surface — see E, 2026-08-29"
        )
    }

    /// Same containment as every other override here: the ordinary composer keeps `.bar`.
    func testTheOrdinaryFooterKeepsItsBarMaterial() {
        XCTAssertNil(JournalComposerPalette.footerSurfaceAsset(for: .log))
    }

    /// **The footer's ink is NOT the page's ink, and that is the whole reason it has its own
    /// token.** The chrome tracks the appearance while the page does not: in light the desk IS the
    /// pad's gold, at night it goes near-black while the page stays gold. Painting the footer with
    /// the page ink was tried and measured before it shipped — `#3D2B05` on the night chrome
    /// `#1A1610` is 1.33:1, an invisible line, against 5.20:1 for the same ink on the day chrome.
    func testTheFooterInkIsNotThePageInk() {
        XCTAssertNotEqual(
            JournalComposerPalette.chromeInkAsset(for: .journal),
            JournalComposerPalette.softInkAsset(for: .journal),
            "the footer sits on the desk, not the page — one ink cannot serve both at night"
        )
        XCTAssertEqual(
            JournalComposerPalette.chromeInkAsset(for: .journal),
            "JournalPaperChromeInk"
        )
    }

    /// Same containment as every other override on this screen: the ordinary composer opts out.
    func testTheOrdinaryFooterKeepsItsOwnInk() {
        XCTAssertNil(JournalComposerPalette.chromeInkAsset(for: .log))
    }

    /// The pad's soft ink and its chip wardrobe have to name the SAME ink, or the section labels
    /// and the chips inside them drift apart — two vehicles, one colour.
    func testTheWardrobeAndTheSoftInkAgree() {
        XCTAssertEqual(
            ComposerChipPalette.pad.softInk,
            JournalComposerPalette.softInkAsset(for: .journal),
            "the wardrobe and the label ink must be the same ink"
        )
        XCTAssertNil(
            ComposerChipPalette.ordinary.softInk,
            "the ordinary wardrobe overrides nothing — that is what keeps task-create unchanged"
        )
    }

    /// **The regression this block exists to close, stated as arithmetic.**
    ///
    /// `.foregroundStyle(.secondary)` under a container that sets a plain `Color` does NOT inherit
    /// that colour — it inherits it at roughly half alpha. Measured off E's device (2026-08-28):
    /// ink `#4A3506` at 50% over the day page `#DAA520` renders `#916D12` = **2.13:1**, and at
    /// night `#3D2B05` over `#C99A1E` renders `#836212` = **2.18:1**. Both fail AA outright, on a
    /// page where the same ink at full strength clears it at 5.20:1 / 5.25:1.
    ///
    /// So the pad may never express hierarchy through alpha, and the only way a view can obey that
    /// is to be HANDED an ink rather than left to derive one.
    func testThePadHandsOutARealInkRatherThanSomethingToDim() {
        for type in LogType.allCases where JournalComposerPalette.isPaper(for: type) {
            XCTAssertEqual(
                JournalComposerPalette.softInkAsset(for: type),
                JournalComposerPalette.inkAsset(for: type),
                "\(type) is paper, so its quiet labels must be the page's one ink at full strength"
            )
        }
    }
}

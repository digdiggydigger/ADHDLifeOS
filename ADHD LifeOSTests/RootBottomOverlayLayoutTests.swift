//
//  RootBottomOverlayLayoutTests.swift
//  ADHD LifeOSTests
//
//  F-LandscapeFabOverlap's pure rule and geometry. The bug E found on the phone on 2026-09-16:
//  in LANDSCAPE with an unacknowledged "Sprint finished while you were away" card up, the capture
//  disc sat on the Settings gear and the gear could not be tapped. The cause is arithmetic, and
//  the first test below IS that arithmetic — built from the production constants the overlay
//  reads and E's own measurements — so the rule the other tests pin is explained, not asserted.
//
//  The geometry lives in pure functions rather than in the `Layout`'s `placeSubviews` so it can
//  be held here: a `Layout` needs real subviews to run, and every number in it would otherwise
//  be a number nothing checks.
//

import XCTest
@testable import ADHD_LifeOS

final class RootBottomOverlayLayoutTests: XCTestCase {

    /// Today's disc row: the 24pt trailing margin, the 60pt disc and the row's 16pt leading
    /// padding, with no search field. The row's HEIGHT is the disc's in both states, which is
    /// what `AppSearchRowMetrics.fieldHeight`'s doc comment guarantees.
    private let discRow = CGSize(
        width: 16 + CaptureDiscMetrics.discDiameter + CaptureDiscMetrics.edgeMargin,
        height: CaptureDiscMetrics.discDiameter
    )

    // MARK: - The bug, as arithmetic

    /// `RootBottomOverlay` is bottom-aligned, and in the STACKED arrangement the disc sits on top
    /// of everything: lift, cards, spacing, then the disc. E's landscape iPhone 15 Pro has 393pt
    /// of height less the 21pt home-indicator inset — 372pt — and the away card measured 186pt
    /// on E's frame (`screenshots/ios27-device-findings/04-fab-overlap-landscape.jpeg`, where the
    /// disc was read at y 16–75pt). The gear's 40pt well starts 8pt under the top edge, so
    /// anything above y 48 is in the header. The journey reproduced the same sum on the 17 Pro
    /// simulator to the point: 381 − 100 − 196.7 − 8 − 60 = 17.3, and it printed 17.3.
    ///
    /// The middle assertion is why "neither alone did it": the expanded sprint card is 148pt,
    /// and 148 leaves the disc 8pt clear of the well. That is the margin it was all living on.
    ///
    /// The last block is the fix in the same numbers: side by side, the disc is back at its
    /// resting position and the card's top is under the header.
    func testTheAwayCardInLandscapeLiftsTheStackedDiscIntoTheHeaderAndTheSideBySideOneDoesNot() {
        let landscapeSafeHeight: CGFloat = 393 - 21
        let width: CGFloat = 852 - 59 - 59
        let gearWellBottom: CGFloat = 8 + 40
        // What is left above the lift for the stack to stand in.
        let room = landscapeSafeHeight - AppSearchRowMetrics.bottomFurnitureLift
        let awayCard = CGSize(width: width, height: 186)

        let stacked = RootBottomOverlayLayout.size(.stacked, width: width, discRow: discRow, cards: awayCard)
        let stackedDiscTop = room - stacked.height
        XCTAssertLessThan(
            stackedDiscTop, gearWellBottom,
            "With the away card up the stacked disc's top is at \(stackedDiscTop), which should be"
                + " INSIDE the header band — that is the bug. If this fails the metrics have moved;"
                + " re-measure before deciding the rule below is no longer needed."
        )
        XCTAssertEqual(stackedDiscTop, 18, accuracy: 4, "E measured the disc at y 16 on the device frame.")

        let sprintOnly = RootBottomOverlayLayout.size(
            .stacked, width: width, discRow: discRow, cards: CGSize(width: width, height: 148)
        )
        XCTAssertGreaterThanOrEqual(
            room - sprintOnly.height, gearWellBottom,
            "An expanded sprint card ALONE should just clear the gear — that is why the bug needed"
                + " the away card to show itself."
        )

        let beside = RootBottomOverlayLayout.size(.besideTheDisc, width: width, discRow: discRow, cards: awayCard)
        // Bottom-aligned inside the room, as the overlay places it.
        let bounds = CGRect(x: 0, y: room - beside.height, width: width, height: beside.height)
        let frames = RootBottomOverlayLayout.frames(.besideTheDisc, in: bounds, discRow: discRow, cards: awayCard)
        XCTAssertEqual(
            frames.discRow.minY, room - CaptureDiscMetrics.discDiameter,
            "Side by side, the disc is not at its resting position — something is still pushing it."
        )
        XCTAssertGreaterThanOrEqual(frames.cards.minY, gearWellBottom, "The card itself reaches into the header.")
    }

    // MARK: - The rule

    func testRegularHeightStacksTheDiscAboveTheCardsWhateverIsUp() {
        XCTAssertEqual(
            RootBottomOverlayLayout.arrangement(isCompactHeight: false, hasCards: true), .stacked,
            "Portrait with a card up must stay the stack E reviewed: an active sprint PUSHES the"
                + " disc up rather than covering it (2026-08-19, 2026-08-25)."
        )
        XCTAssertEqual(
            RootBottomOverlayLayout.arrangement(isCompactHeight: false, hasCards: false), .stacked
        )
    }

    /// The search row shares the disc's row and fills the leading width. With nothing up there is
    /// no column to put beside the disc, and a side-by-side arrangement would hand half the width
    /// to an empty column — so compact height with nothing up is the ordinary row, untouched.
    func testCompactHeightWithNothingUpKeepsTheStackedRowSoTheSearchRowIsUntouched() {
        XCTAssertEqual(
            RootBottomOverlayLayout.arrangement(isCompactHeight: true, hasCards: false), .stacked
        )
    }

    /// The fix. Compact height is the landscape iPhone (the `CaptureFanOverlay` / `LoginView`
    /// reading of `verticalSizeClass`), where 372pt cannot hold the lift, a card and the disc in
    /// one column without the disc reaching the header. The disc keeps its resting corner and
    /// the cards take the column beside it — nothing pushes, nothing covers.
    func testCompactHeightWithAnyCardUpPutsTheCardsBesideTheDisc() {
        XCTAssertEqual(
            RootBottomOverlayLayout.arrangement(isCompactHeight: true, hasCards: true), .besideTheDisc
        )
    }

    // MARK: - The geometry

    /// The stacked arrangement is the `VStack(alignment: .trailing, spacing: 8)` E's position
    /// review settled, expressed as frames: the disc row on top, trailing-aligned, the cards
    /// below it, the grid gap between. **`discRow.maxY <= cards.minY` is the invariant** — the
    /// disc above the cards, never under them.
    func testStackedPutsTheDiscRowAboveTheCardsTrailingAlignedWithTheGridGapBetween() {
        let cards = CGSize(width: 393, height: 186)
        let size = RootBottomOverlayLayout.size(.stacked, width: 393, discRow: discRow, cards: cards)
        XCTAssertEqual(size, CGSize(width: 393, height: 60 + RootBottomOverlayLayout.spacing + 186))

        let frames = RootBottomOverlayLayout.frames(
            .stacked, in: CGRect(origin: .zero, size: size), discRow: discRow, cards: cards
        )
        XCTAssertEqual(frames.discRow, CGRect(x: 393 - 100, y: 0, width: 100, height: 60))
        XCTAssertEqual(frames.cards, CGRect(x: 0, y: 60 + RootBottomOverlayLayout.spacing, width: 393, height: 186))
        XCTAssertLessThanOrEqual(
            frames.discRow.maxY, frames.cards.minY,
            "The cards are not below the disc row, so a running sprint no longer pushes the disc"
                + " up — it sits under it."
        )
    }

    /// The `if` around the cards in the old body was not decoration: an empty column must not
    /// spend the stack's spacing on nothing, or the disc rises 8pt on every screen for no reason.
    func testStackedWithNothingUpIsTheDiscRowAloneAndSpendsNoGapOnNothing() {
        let none = CGSize(width: 393, height: 0)
        let size = RootBottomOverlayLayout.size(.stacked, width: 393, discRow: discRow, cards: none)
        XCTAssertEqual(size.height, CaptureDiscMetrics.discDiameter)

        let frames = RootBottomOverlayLayout.frames(
            .stacked, in: CGRect(origin: .zero, size: size), discRow: discRow, cards: none
        )
        XCTAssertEqual(frames.discRow, CGRect(x: 393 - 100, y: 0, width: 100, height: 60))
    }

    /// Side by side: the disc row keeps the bottom-trailing corner it rests in, the cards take
    /// the column to its leading side, both bottom-aligned, and the column ends where the disc
    /// row begins — so the two can never overlap whatever the cards' height.
    func testBesideKeepsTheDiscRowInItsRestingCornerAndTheCardsToItsLeading() {
        let width: CGFloat = 734
        XCTAssertEqual(
            RootBottomOverlayLayout.cardsWidth(.besideTheDisc, width: width, discRow: discRow), width - 100,
            "The cards column is not the width the disc row leaves, so the two are proposed"
                + " overlapping widths."
        )
        XCTAssertEqual(RootBottomOverlayLayout.cardsWidth(.stacked, width: width, discRow: discRow), width)

        let cards = CGSize(width: width - 100, height: 186)
        let size = RootBottomOverlayLayout.size(.besideTheDisc, width: width, discRow: discRow, cards: cards)
        XCTAssertEqual(size, CGSize(width: width, height: 186), "Side by side, the height is the taller piece.")

        let frames = RootBottomOverlayLayout.frames(
            .besideTheDisc, in: CGRect(origin: .zero, size: size), discRow: discRow, cards: cards
        )
        XCTAssertEqual(frames.discRow, CGRect(x: width - 100, y: 186 - 60, width: 100, height: 60))
        XCTAssertEqual(frames.cards, CGRect(x: 0, y: 0, width: width - 100, height: 186))
        XCTAssertLessThanOrEqual(frames.cards.maxX, frames.discRow.minX, "The cards column runs under the disc.")
    }

    /// A column shorter than the disc — a collapsed sprint card is 60pt — sits on the same
    /// bottom line rather than floating at the top of the row.
    func testBesideWithAColumnShorterThanTheDiscSitsBothOnTheBottomLine() {
        let cards = CGSize(width: 634, height: 40)
        let size = RootBottomOverlayLayout.size(.besideTheDisc, width: 734, discRow: discRow, cards: cards)
        XCTAssertEqual(size.height, CaptureDiscMetrics.discDiameter)

        let frames = RootBottomOverlayLayout.frames(
            .besideTheDisc, in: CGRect(origin: .zero, size: size), discRow: discRow, cards: cards
        )
        XCTAssertEqual(frames.cards.maxY, frames.discRow.maxY, "The two pieces do not share a bottom line.")
        XCTAssertEqual(frames.cards.minY, 20)
    }

    /// The stack's spacing was a literal in the view body; it is named now because the
    /// arithmetic above has to read it. §2's grid: 8 is inter-element spacing.
    func testTheStackSpacingIsOnTheGrid() {
        XCTAssertEqual(RootBottomOverlayLayout.spacing, 8)
    }
}

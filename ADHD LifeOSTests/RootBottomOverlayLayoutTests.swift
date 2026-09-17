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
        let frames = RootBottomOverlayLayout.frames(
            .besideTheDisc, in: bounds, discRow: discRow, cards: awayCard, fanIsOpen: false
        )
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
    /// disc above the cards, never under them — **while the fan is closed.** With it open the ×
    /// drops into the invisible cards' space on purpose (`F-FanXAtRest`, tested below).
    func testStackedPutsTheDiscRowAboveTheCardsTrailingAlignedWithTheGridGapBetween() {
        let cards = CGSize(width: 393, height: 186)
        let size = RootBottomOverlayLayout.size(.stacked, width: 393, discRow: discRow, cards: cards)
        XCTAssertEqual(size, CGSize(width: 393, height: 60 + RootBottomOverlayLayout.spacing + 186))

        let frames = RootBottomOverlayLayout.frames(
            .stacked, in: CGRect(origin: .zero, size: size), discRow: discRow, cards: cards, fanIsOpen: false
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
            .stacked, in: CGRect(origin: .zero, size: size), discRow: discRow, cards: none, fanIsOpen: false
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
            .besideTheDisc, in: CGRect(origin: .zero, size: size), discRow: discRow, cards: cards, fanIsOpen: false
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
            .besideTheDisc, in: CGRect(origin: .zero, size: size), discRow: discRow, cards: cards, fanIsOpen: false
        )
        XCTAssertEqual(frames.cards.maxY, frames.discRow.maxY, "The two pieces do not share a bottom line.")
        XCTAssertEqual(frames.cards.minY, 20)
    }

    // MARK: - The fan (F-FanCardsFade)

    /// E's call, 2026-09-17, on the finding in `screenshots/landscape-fab-overlap/09–12`: with a
    /// card up, opening the capture fan drew the card crisp above the fan's scrim and, in
    /// portrait, hid the LINK and TASK tiles behind it. *"Fade the cards out while the fan's
    /// open."* Invisible AND out of the hit-test — an invisible card that still took the tap
    /// would be the same bug with better lighting.
    func testWhileTheFanIsOpenTheCardsAreInvisibleAndTakeNoTouches() {
        let presence = RootBottomOverlayLayout.cardsPresence(fanIsOpen: true)
        XCTAssertEqual(presence.opacity, 0, "The cards are still visible over the fan.")
        XCTAssertFalse(presence.acceptsTouches, "The faded cards still take the taps meant for the tiles under them.")
    }

    func testWithTheFanClosedTheCardsArePresentAndTappable() {
        let presence = RootBottomOverlayLayout.cardsPresence(fanIsOpen: false)
        XCTAssertEqual(presence.opacity, 1)
        XCTAssertTrue(presence.acceptsTouches)
    }

    // MARK: - The × while the fan is open (F-FanXAtRest)

    /// The resting ×'s centre, from the safe area's bottom-trailing corner — the corner both the
    /// fan's `GeometryReader` and this overlay measure from. 54 across (the 24pt margin and half
    /// the disc), 130 up (the 100pt lift and half the disc); E's phone put it at y 688 on an
    /// 818pt safe bottom, which is 130.
    private static let restingX = CGPoint(
        x: CaptureDiscMetrics.edgeMargin + CaptureDiscMetrics.discDiameter / 2,
        y: AppSearchRowMetrics.bottomFurnitureLift + CaptureDiscMetrics.discDiameter / 2
    )

    /// A tile and the disc overlap when their centres are nearer than their two radii.
    private static let clearance = CaptureFan.tileDiameter / 2 + CaptureDiscMetrics.discDiameter / 2

    /// Where the × actually is, in the fan's corner-offset convention, for a stacked column of
    /// `cardsHeight` — laid out the way the overlay lays it out: bottom-aligned, lifted by
    /// `bottomFurnitureLift`.
    private func xCentre(cardsHeight: CGFloat, fanIsOpen: Bool) -> CGPoint {
        let cards = CGSize(width: 393, height: cardsHeight)
        let size = RootBottomOverlayLayout.size(.stacked, width: 393, discRow: discRow, cards: cards)
        let bounds = CGRect(origin: .zero, size: size)
        let frames = RootBottomOverlayLayout.frames(
            .stacked, in: bounds, discRow: discRow, cards: cards, fanIsOpen: fanIsOpen
        )
        return CGPoint(
            x: bounds.maxX - frames.discRow.maxX + CaptureDiscMetrics.edgeMargin + CaptureDiscMetrics.discDiameter / 2,
            y: AppSearchRowMetrics.bottomFurnitureLift + bounds.maxY - frames.discRow.midY
        )
    }

    private static func nearestTile(to point: CGPoint) -> (kind: CaptureKind, distance: CGFloat) {
        CaptureFan.slots
            .map { ($0.kind, hypot($0.fromTrailing - point.x, $0.fromBottom - point.y)) }
            .min { $0.1 < $1.1 }!
    }

    /// **The bug, as arithmetic, and the fix in the same numbers.** E's frame 19 and GIF
    /// (`screenshots/landscape-fab-overlap/19`, `21`): in portrait any card pushes the disc up by
    /// its height plus the stack's gap, the tiles are placed from the RESTING corner, and the
    /// tiles are 78pt apart — so wherever the push lands the ×, some tile is under it. The heights
    /// are the ones the pushes were measured or derived from: the collapsed bar (60, pushing 68 —
    /// TASK, 9pt, measured), a Confirm card (76, pushing 84 — TASK, 7pt, measured), the expanded
    /// card (148) and the away card (186).
    ///
    /// E's call, shape B — *"× drops to its corner"*: with the fan open every one of them puts the
    /// × back where it rests, clear of every tile.
    func testWithAnyCardUpTheClosedStackPutsTheXOnATileAndTheOpenFanDoesNot() {
        for height: CGFloat in [60, 76, 148, 186] {
            let closed = Self.nearestTile(to: xCentre(cardsHeight: height, fanIsOpen: false))
            XCTAssertLessThan(
                closed.distance, Self.clearance,
                "A \(height)pt card no longer pushes the × onto a tile. If the arc or the lift moved,"
                    + " re-measure before deciding the rule below is still needed."
            )
            let open = xCentre(cardsHeight: height, fanIsOpen: true)
            XCTAssertEqual(open, Self.restingX, "Fan open over a \(height)pt card: the × is not at its resting corner.")
            XCTAssertGreaterThanOrEqual(
                Self.nearestTile(to: open).distance, Self.clearance,
                "Fan open over a \(height)pt card: the × still sits on \(Self.nearestTile(to: open).kind)."
            )
        }
        XCTAssertEqual(
            Self.nearestTile(to: xCentre(cardsHeight: 60, fanIsOpen: false)).kind, .task,
            "E's frame 19: the collapsed sprint bar put the × on TASK."
        )
    }

    /// The pure rule: fan open, stacked, with cards up — the disc row moves to the bottom line and
    /// the cards stay exactly where they were. They are invisible then, but they keep their space,
    /// so nothing else on screen reflows.
    func testStackedWithCardsAndTheFanOpenMovesOnlyTheDiscRowToTheBottomLine() {
        let cards = CGSize(width: 393, height: 186)
        let size = RootBottomOverlayLayout.size(.stacked, width: 393, discRow: discRow, cards: cards)
        let bounds = CGRect(origin: .zero, size: size)
        let closed = RootBottomOverlayLayout.frames(
            .stacked, in: bounds, discRow: discRow, cards: cards, fanIsOpen: false
        )
        let open = RootBottomOverlayLayout.frames(
            .stacked, in: bounds, discRow: discRow, cards: cards, fanIsOpen: true
        )

        XCTAssertEqual(open.discRow, CGRect(x: 393 - 100, y: bounds.maxY - 60, width: 100, height: 60))
        XCTAssertEqual(open.discRow.maxY, closed.cards.maxY, "The × is not on the column's bottom line.")
        XCTAssertEqual(open.cards, closed.cards, "Opening the fan moved the cards, so the column reflows.")
    }

    /// With nothing up the disc already rests on the bottom line, so opening the fan changes
    /// nothing — the ordinary row must not jump on every screen.
    func testStackedWithNothingUpIsTheSameWhetherTheFanIsOpenOrNot() {
        let none = CGSize(width: 393, height: 0)
        let size = RootBottomOverlayLayout.size(.stacked, width: 393, discRow: discRow, cards: none)
        let bounds = CGRect(origin: .zero, size: size)
        XCTAssertEqual(
            RootBottomOverlayLayout.frames(.stacked, in: bounds, discRow: discRow, cards: none, fanIsOpen: true),
            RootBottomOverlayLayout.frames(.stacked, in: bounds, discRow: discRow, cards: none, fanIsOpen: false)
        )
    }

    /// Landscape already keeps the disc in its corner beside the cards (`F-LandscapeFabOverlap`),
    /// which is why E's landscape frames never showed the collision. The fan changes nothing there.
    func testBesideTheDiscIsTheSameWhetherTheFanIsOpenOrNot() {
        let cards = CGSize(width: 634, height: 186)
        let size = RootBottomOverlayLayout.size(.besideTheDisc, width: 734, discRow: discRow, cards: cards)
        let bounds = CGRect(origin: .zero, size: size)
        XCTAssertEqual(
            RootBottomOverlayLayout.frames(.besideTheDisc, in: bounds, discRow: discRow, cards: cards, fanIsOpen: true),
            RootBottomOverlayLayout.frames(.besideTheDisc, in: bounds, discRow: discRow, cards: cards, fanIsOpen: false)
        )
    }

    /// **A PIN, and it passes on the tree it was written against.** Every tile, in BOTH fans, is
    /// clear of the RESTING ×. Shape B is only a fix while that holds — so a later change to the
    /// arc, the tile size, the lift or the disc cannot quietly put a tile back under the ×.
    /// Portrait's nearest is TASK at 77pt; landscape's is TASK at ~170pt.
    func testEveryTileInBothFansClearsTheRestingX() {
        for (name, slots) in [("portrait", CaptureFan.slots), ("landscape", CaptureFan.horizontalSlots)] {
            for slot in slots {
                let distance = hypot(slot.fromTrailing - Self.restingX.x, slot.fromBottom - Self.restingX.y)
                XCTAssertGreaterThanOrEqual(
                    distance, Self.clearance,
                    "The \(name) fan's \(slot.label) tile is \(distance)pt from the resting × — they overlap."
                )
            }
        }
    }

    /// The stack's spacing was a literal in the view body; it is named now because the
    /// arithmetic above has to read it. §2's grid: 8 is inter-element spacing.
    func testTheStackSpacingIsOnTheGrid() {
        XCTAssertEqual(RootBottomOverlayLayout.spacing, 8)
    }
}

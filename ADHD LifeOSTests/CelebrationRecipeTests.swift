//
//  CelebrationRecipeTests.swift
//  ADHD LifeOSTests
//
//  `F-CTACelebrations-3`: WHAT the two new families launch. E's F6 chose the mini confetti pop over
//  a halo and tick — "12 to 20 pieces from the tap point, the Confirm engine at a tenth of the
//  size" — and E's #7 chose a still scatter that fades wherever Reduce Motion is on.
//
//  **Nothing requests these yet.** The nine pop sites are `F-CTACelebrations-4` and the four
//  milestones are `-5`; E picks the pop's look by LOOKING at a render on a real `TaskRow` before
//  either is wired. What is settled now is the maths, so that render has something to show.
//
//  The still model is where §7.2's opening-pose rule lives: under Reduce Motion the FIRST frame
//  already has its final geometry and only opacity travels. A reduced path that opens on the
//  pre-animation pose and then snaps is the bug, not the fix.
//

import CoreGraphics
import XCTest
@testable import ADHD_LifeOS

final class CelebrationRecipeTests: XCTestCase {

    private let tap = CGPoint(x: 120, y: 300)
    private let canvas = CGSize(width: 390, height: 844)

    // MARK: - The pop (E's F6)

    /// **E's call, 2026-09-12, made by LOOKING at four variants rendered in situ on a real
    /// `TaskRow`** — the same way E chose the pop's family in `F-CTACelebrations-4`.
    ///
    /// E saw the shipped pop on their own phone and said the scaling "needs to be increased
    /// slightly", then asked for a wider spread and more pieces in turn. Variant C carried all
    /// three at 1.6× and E picked it from A (shipped) / B (1.3×) / C / D (2.0×).
    ///
    /// **Do not "tune" this back down.** It is not a guess at what reads well — it is the value E
    /// approved by sight, and the evidence is `screenshots/cta-celebrations-pop-scale/`. The
    /// `FocusCompletionStackLayout.peekStep` precedent exactly.
    func testThePopScaleIsTheValueEChoseByLooking() {
        XCTAssertEqual(CelebrationRecipes.popScale, 1.6)
    }

    /// Was 12 to 20 — E's F6 — until E asked for more paper on the device. The range is the
    /// original scaled by `popScale`, so one number governs all three dimensions.
    func testAPopIsBetweenNineteenAndThirtyTwoPieces() {
        XCTAssertEqual(CelebrationRecipes.popCount, 19...32)
        for ordinal in 1...40 {
            let pieces = CelebrationRecipes.pop(at: tap, ordinal: ordinal)
            XCTAssertTrue(
                CelebrationRecipes.popCount.contains(pieces.count),
                "Ordinal \(ordinal) threw \(pieces.count) pieces; E's scaled pop is 19 to 32."
            )
        }
    }

    /// The throw scales with the paper (E: "bigger spread too, not just bigger pieces"), so the
    /// speeds are the original 250–450 scaled. Asserted as a band across the whole pop rather than
    /// per piece, so a regression reports one clear failure instead of thirty.
    func testAPopLeavesFromTheTapPointAndIsGoneWithinASecond() {
        let pieces = CelebrationRecipes.pop(at: tap, ordinal: 1)
        let speeds = pieces.map {
            ($0.velocity.dx * $0.velocity.dx + $0.velocity.dy * $0.velocity.dy).squareRoot()
        }
        for piece in pieces {
            XCTAssertEqual(piece.origin.x, tap.x, accuracy: 0.0001)
            XCTAssertEqual(piece.origin.y, tap.y, accuracy: 0.0001)
        }
        XCTAssertTrue(
            pieces.allSatisfy { (0.7...1.0).contains($0.lifetime) },
            "A pop piece must still live 0.7 to 1.0 s — E scaled the paper, not the timing."
        )
        XCTAssertGreaterThanOrEqual(
            speeds.min() ?? 0, 250 * CelebrationRecipes.popScale - 0.001,
            "The slowest piece leaves at \(speeds.min() ?? 0) pt/s; E's scaled pop throws from 400."
        )
        XCTAssertLessThanOrEqual(
            speeds.max() ?? .greatestFiniteMagnitude, 450 * CelebrationRecipes.popScale + 0.001,
            "The fastest piece leaves at \(speeds.max() ?? 0) pt/s; E's scaled pop tops out at 720."
        )
    }

    /// The pieces themselves are the Confirm's paper, scaled — same shapes and proportions, just
    /// bigger. 7–10 × 4–6 and a 6 pt circle become 11.2–16 × 6.4–9.6 and a 9.6 pt circle.
    func testAPopsPiecesAreTheConfirmsPaperScaledUp() {
        let scale = CelebrationRecipes.popScale
        for piece in CelebrationRecipes.pop(at: tap, ordinal: 3) {
            switch piece.shape {
            case .rectangle:
                XCTAssertTrue(
                    (7 * scale - 0.001...10 * scale + 0.001).contains(piece.size.width),
                    "A pop rectangle is \(piece.size.width) pt wide; scaled it must be 11.2 to 16."
                )
                XCTAssertTrue((4 * scale - 0.001...6 * scale + 0.001).contains(piece.size.height))
            case .circle:
                XCTAssertEqual(piece.size.width, 6 * scale, accuracy: 0.001)
            }
        }
    }

    /// **The milestone's still field is NOT scaled**, and that is the point of asserting it. E
    /// asked for a bigger POP; the 120-piece field behind a full-screen milestone is a different
    /// moment at a different size, and the shared `piece(...)` builder would have carried the
    /// scale into it silently.
    func testTheMilestonesStillFieldKeepsTheConfirmsOwnPaperSize() {
        for piece in CelebrationRecipes.stillField(canvas: canvas, ordinal: 3) {
            switch piece.shape {
            case .rectangle:
                XCTAssertTrue(
                    (7.0...10.0).contains(piece.size.width),
                    "A still-field rectangle is \(piece.size.width) pt wide; the field is unscaled."
                )
            case .circle:
                XCTAssertEqual(piece.size.width, 6, accuracy: 0.001)
            }
        }
    }

    /// CLAUDE.md §4: the seven confetti TOKENS, never a hue. `AreaSlateVivid` is left out as grey
    /// and `StateRisk` because it means risk — the Confirm palette, unchanged.
    func testEveryNewRecipeUsesTheSameSevenTokensAsTheConfirmCelebration() {
        let palette = Set(ConfettiRecipe.palette)
        let everything = CelebrationRecipes.pop(at: tap, ordinal: 3)
            + CelebrationRecipes.stillPop(at: tap, ordinal: 3)
            + CelebrationRecipes.stillField(canvas: canvas, ordinal: 3)
        for piece in everything {
            XCTAssertTrue(palette.contains(piece.colorName), "\(piece.colorName) is not one of the seven tokens.")
        }
    }

    /// Seeded from the ordinal, like every Confirm: the same burst replays identically and the next
    /// one is different paper.
    func testTheSameOrdinalDrawsTheSamePopAndTheNextOrdinalDrawsAnother() {
        XCTAssertEqual(CelebrationRecipes.pop(at: tap, ordinal: 7), CelebrationRecipes.pop(at: tap, ordinal: 7))
        XCTAssertNotEqual(CelebrationRecipes.pop(at: tap, ordinal: 7), CelebrationRecipes.pop(at: tap, ordinal: 8))
    }

    // MARK: - The still pop and the still field (E's #7)

    /// The reduced pop is the SAME pop at rest, so its scatter has to follow the pop's throw —
    /// otherwise E's bigger pop and its Reduce Motion counterpart drift apart in size.
    func testTheStillPopsSpreadScalesWithThePop() {
        XCTAssertEqual(CelebrationRecipes.stillPopSpread, 48 * CelebrationRecipes.popScale)
    }

    func testTheStillPopIsTheSameCountAtRestNearTheTapPoint() {
        for ordinal in 1...20 {
            let still = CelebrationRecipes.stillPop(at: tap, ordinal: ordinal)
            XCTAssertEqual(
                still.count, CelebrationRecipes.pop(at: tap, ordinal: ordinal).count,
                "The reduced pop is a different SIZE of moment, not the same one held still."
            )
            for piece in still {
                XCTAssertEqual(piece.velocity.dx, 0, accuracy: 0.0001)
                XCTAssertEqual(piece.velocity.dy, 0, accuracy: 0.0001)
                let across = piece.origin.x - tap.x
                let down = piece.origin.y - tap.y
                XCTAssertLessThanOrEqual(
                    (across * across + down * down).squareRoot(), CelebrationRecipes.stillPopSpread,
                    "A still pop piece landed further than E's 48 pt from the tap point."
                )
            }
        }
    }

    func testTheStillFieldIsOneHundredAndTwentyPiecesAtRestAcrossTheWholeCanvas() {
        let field = CelebrationRecipes.stillField(canvas: canvas, ordinal: 1)
        XCTAssertEqual(field.count, CelebrationRecipes.stillFieldCount)
        XCTAssertEqual(CelebrationRecipes.stillFieldCount, 120)
        for piece in field {
            XCTAssertEqual(piece.velocity.dx, 0, accuracy: 0.0001)
            XCTAssertEqual(piece.velocity.dy, 0, accuracy: 0.0001)
            XCTAssertTrue((0...canvas.width).contains(piece.origin.x))
            XCTAssertTrue((0...canvas.height).contains(piece.origin.y))
        }
    }

    // MARK: - The still envelope (§7.2's opening-pose rule)

    /// The FIRST frame already has its final geometry. A still piece is in the same place, at the
    /// same angle, at 0.01 s and at the very end — only its opacity has moved.
    func testAStillPieceNeverMovesFromTheOpeningPoseItArrivesIn() throws {
        let piece = try XCTUnwrap(CelebrationRecipes.stillField(canvas: canvas, ordinal: 1).first)
        let length: TimeInterval = 5.4
        let first = try XCTUnwrap(CelebrationStillField.state(of: piece, at: 0.01, length: length))
        let last = try XCTUnwrap(CelebrationStillField.state(of: piece, at: length - 0.01, length: length))
        XCTAssertEqual(first.position.x, piece.origin.x, accuracy: 0.0001)
        XCTAssertEqual(first.position.y, piece.origin.y, accuracy: 0.0001)
        XCTAssertEqual(first.position.x, last.position.x, accuracy: 0.0001)
        XCTAssertEqual(first.position.y, last.position.y, accuracy: 0.0001)
        XCTAssertEqual(first.rotation, last.rotation, accuracy: 0.0001)
        XCTAssertEqual(first.tumbleScale, last.tumbleScale, accuracy: 0.0001)
    }

    func testAStillPieceFadesInOverThreeTenthsAndOutOverTheLastSevenTenths() throws {
        let piece = try XCTUnwrap(CelebrationRecipes.stillField(canvas: canvas, ordinal: 1).first)
        let length: TimeInterval = 5.4
        XCTAssertNil(CelebrationStillField.state(of: piece, at: -0.01, length: length))
        XCTAssertNil(CelebrationStillField.state(of: piece, at: length + 0.01, length: length))
        let arriving = try XCTUnwrap(CelebrationStillField.state(of: piece, at: 0.15, length: length))
        XCTAssertEqual(arriving.opacity, 0.5, accuracy: 0.01)
        let settled = try XCTUnwrap(
            CelebrationStillField.state(of: piece, at: CelebrationStillField.fadeIn, length: length)
        )
        XCTAssertEqual(settled.opacity, 1, accuracy: 0.0001)
        let holding = try XCTUnwrap(CelebrationStillField.state(of: piece, at: 2.0, length: length))
        XCTAssertEqual(holding.opacity, 1, accuracy: 0.0001)
        let leaving = try XCTUnwrap(
            CelebrationStillField.state(of: piece, at: length - CelebrationStillField.fadeOut / 2, length: length)
        )
        XCTAssertEqual(leaving.opacity, 0.5, accuracy: 0.01)
    }
}

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

    func testAPopIsBetweenTwelveAndTwentyPieces() {
        for ordinal in 1...40 {
            let pieces = CelebrationRecipes.pop(at: tap, ordinal: ordinal)
            XCTAssertTrue(
                CelebrationRecipes.popCount.contains(pieces.count),
                "Ordinal \(ordinal) threw \(pieces.count) pieces; E chose 12 to 20."
            )
        }
    }

    func testAPopLeavesFromTheTapPointAndIsGoneWithinASecond() {
        for piece in CelebrationRecipes.pop(at: tap, ordinal: 1) {
            XCTAssertEqual(piece.origin.x, tap.x, accuracy: 0.0001)
            XCTAssertEqual(piece.origin.y, tap.y, accuracy: 0.0001)
            XCTAssertTrue(
                (0.7...1.0).contains(piece.lifetime),
                "A pop piece lives \(piece.lifetime) s; E's pop lives 0.7 to 1.0 s."
            )
            let speed = (piece.velocity.dx * piece.velocity.dx + piece.velocity.dy * piece.velocity.dy).squareRoot()
            XCTAssertTrue(
                (250.0...450.0).contains(speed),
                "A pop piece leaves at \(speed) pt/s; E's pop is 250 to 450."
            )
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

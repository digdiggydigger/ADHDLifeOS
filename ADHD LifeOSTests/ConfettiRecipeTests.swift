//
//  ConfettiRecipeTests.swift
//  ADHD LifeOSTests
//
//  F-ConfirmCelebration-1: what every Confirm launches. E chose "B but also C" — rain from the top
//  AND both corner cannons, together — by video, and these hold the recipe that video was made with
//  (`handoff/SESSION-OPENER-confirm-celebration-design.md`, "Every Confirm's recipe").
//

import UIKit
import XCTest
@testable import ADHD_LifeOS

@MainActor
final class ConfettiRecipeTests: XCTestCase {

    /// The prototype's window: an iPhone 17 Pro in points.
    private let canvas = CGSize(width: 393, height: 852)

    // MARK: - The recipe

    func testEveryConfirmIsRainAndCannonsInTheRecordsCounts() {
        let pieces = ConfettiRecipe.everyConfirm(canvas: canvas, ordinal: 1)
        XCTAssertEqual(pieces.count, 220, "Every Confirm is 120 rain + 100 cannon pieces.")
        XCTAssertEqual(
            pieces.filter { $0.origin.y < 0 }.count, 120,
            "The rain is missing. E's \"B but also C\" is both sources on every Confirm."
        )
        XCTAssertEqual(
            pieces.filter { abs($0.origin.y - canvas.height * 0.86) < 1e-9 }.count, 100,
            "The cannons are missing. E's \"B but also C\" is both sources on every Confirm."
        )
    }

    func testRainStartsAboveTheScreenAndFallsAcrossItsWholeWidth() {
        let rain = ConfettiRecipe.rain(count: 120, canvas: canvas, seed: 7)
        XCTAssertEqual(rain.count, 120)
        XCTAssertTrue(rain.allSatisfy { piece in
            (-10...canvas.width + 10).contains(piece.origin.x)
                && (-80 ... -10).contains(piece.origin.y)
                && (-60...60).contains(piece.velocity.dx)
                && (420...720).contains(piece.velocity.dy)
                && (0...0.6).contains(piece.delay)
                && (3.0...3.6).contains(piece.lifetime)
        }, "A rain piece is launched outside the record's ranges.")
        let launchXs = rain.map(\.origin.x)
        XCTAssertGreaterThan(
            (launchXs.max() ?? 0) - (launchXs.min() ?? 0), canvas.width * 0.8,
            "The rain does not span the screen, so it reads as a column rather than rain."
        )
    }

    func testCannonsFireInwardAndUpFromBothBottomCorners() {
        let cannons = ConfettiRecipe.cannons(count: 100, canvas: canvas, seed: 7)
        XCTAssertEqual(cannons.count, 100)
        let left = cannons.filter { $0.origin.x < 0 }
        let right = cannons.filter { $0.origin.x > canvas.width }
        XCTAssertEqual(left.count, 50, "The corners do not alternate evenly.")
        XCTAssertEqual(right.count, 50, "The corners do not alternate evenly.")
        XCTAssertTrue(cannons.allSatisfy { piece in
            let degrees = atan2(-Double(piece.velocity.dy), abs(Double(piece.velocity.dx))) * 180 / .pi
            let speed = hypot(Double(piece.velocity.dx), Double(piece.velocity.dy))
            return abs(piece.origin.y - canvas.height * 0.86) < 1e-9
                && (52...78).contains(degrees)
                && (1100...1900).contains(speed)
                && (0...0.12).contains(piece.delay)
                && (2.8...3.5).contains(piece.lifetime)
        }, "A cannon piece is launched outside the record's ranges.")
        XCTAssertTrue(left.allSatisfy { $0.velocity.dx > 0 }, "The left cannon fires off-screen.")
        XCTAssertTrue(right.allSatisfy { $0.velocity.dx < 0 }, "The right cannon fires off-screen.")
    }

    func testTheShapeMixAndSizesAreTheRecords() {
        let pieces = ConfettiRecipe.everyConfirm(canvas: canvas, ordinal: 3)
        XCTAssertEqual(pieces.count, 220)
        let rectangles = pieces.filter { $0.shape == .rectangle }
        XCTAssertTrue(rectangles.allSatisfy {
            (7...10).contains($0.size.width) && (4...6).contains($0.size.height)
        })
        XCTAssertTrue(pieces.filter { $0.shape == .circle }.allSatisfy {
            $0.size == CGSize(width: 6, height: 6)
        })
        XCTAssertEqual(
            Double(rectangles.count) / Double(max(pieces.count, 1)), 0.75, accuracy: 0.1,
            "The mix is not the record's three rectangles to every circle."
        )
    }

    // MARK: - Colour

    func testColoursCycleThroughTheSevenRecordTokens() {
        XCTAssertEqual(ConfettiRecipe.palette, [
            "AreaWorkVivid", "AreaHealthVivid", "AreaGrowthVivid", "AreaHobbyVivid",
            "AreaOrangeVivid", "StateGoVivid", "StateWarnVivid"
        ])
        XCTAssertEqual(
            ConfettiRecipe.rain(count: 14, canvas: canvas, seed: 1).map(\.colorName),
            ConfettiRecipe.palette + ConfettiRecipe.palette,
            "Pieces do not cycle through the palette, so some colours cluster and some vanish."
        )
    }

    /// `Color("Name")` draws nothing for a missing asset and raises no error, so a typo here would
    /// ship invisible confetti. `UIColor(named:)` returns nil instead, and the test host is the app.
    func testEveryColourIsARealAssetCatalogToken() {
        for name in ConfettiRecipe.palette + [ConfirmCelebrationGlow.colorName] {
            XCTAssertNotNil(
                UIColor(named: name, in: .main, compatibleWith: nil),
                "`\(name)` is not a colour in the asset catalog, so it draws nothing."
            )
        }
    }

    // MARK: - Every Confirm is its own

    /// E's approved R5: seeded from the confirmation ordinal, so a celebration is reproducible
    /// (the same frame renders the same way) and no two Confirms look identical.
    func testTheSameConfirmationReplaysAndTheNextOneDiffers() {
        let first = ConfettiRecipe.everyConfirm(canvas: canvas, ordinal: 5)
        XCTAssertEqual(first.count, 220)
        XCTAssertEqual(first, ConfettiRecipe.everyConfirm(canvas: canvas, ordinal: 5))
        XCTAssertNotEqual(
            first, ConfettiRecipe.everyConfirm(canvas: canvas, ordinal: 6),
            "Two Confirms launch identical confetti."
        )
    }
}

//
//  JournalComposeDiscTests.swift
//  ADHD LifeOSTests
//
//  `F-JournalPencilDisc` (E, 2026-09-18). The Journal's pencil left the header and became a 42pt
//  disc beside the capture disc — *"move the filled pencil icon disc down to the left-hand side of
//  the FAB Icon. make the filled pencil disc inline with the FAB icon"* — wearing the + disc's two
//  colours with the gradient REVERSED and the + disc's glow: *"So the pair are twins with halos, But
//  with the pencil disc's Background colour gradient direction different."*
//
//  **The twins are the risk this file exists for.** Two views that must agree on colours, a glow
//  and a pill curve will drift the first time someone tunes one of them, and a later "tidy" that
//  makes the two gradients match would undo the one difference E asked for. So the shared values
//  live in ONE place (`CaptureDiscFace`), are asserted here by VALUE, and both faces are read from
//  source to prove they use them — the value half alone is a correct number nothing reads.
//

import SwiftUI
import XCTest
@testable import ADHD_LifeOS

final class JournalComposeDiscTests: XCTestCase {

    // MARK: - The twins: same colours, opposite directions

    func testThePairShareTheirColoursAndRunInOppositeDirections() {
        XCTAssertEqual(
            CaptureDiscFace.colors, [Color("CaptureDeep"), Color.accentColor],
            "The + disc's \"Deep field\" colours (E's 2026-08-30 pick) are not the pair's."
        )
        XCTAssertEqual(CaptureDiscFace.plus.start, .top, "The + disc runs CaptureDeep at the TOP.")
        XCTAssertEqual(CaptureDiscFace.plus.end, .bottom)
        XCTAssertEqual(
            CaptureDiscFace.pencil.start, .bottom,
            "E: *\"reverse the DIRECTION that the gradient on the pencil disc currently points in\"* —"
                + " CaptureDeep at the BOTTOM, accent at the top."
        )
        XCTAssertEqual(CaptureDiscFace.pencil.end, .top)
        XCTAssertNotEqual(
            CaptureDiscFace.plus, CaptureDiscFace.pencil,
            "The two faces point the same way — the one difference E asked for is gone."
        )
    }

    func testBothFacesDrawTheirGradientFromTheSharedFace() throws {
        let plus = try Self.flattened("Theme/CaptureDiscLabel.swift")
        XCTAssertTrue(plus.contains("CaptureDiscFace.plus.gradient"), "The + disc no longer draws the shared face.")
        let pencil = try Self.flattened("Journal/JournalComposeDisc.swift")
        XCTAssertTrue(
            pencil.contains("CaptureDiscFace.pencil.gradient"), "The pencil disc no longer draws the shared face."
        )
        for (file, source) in [("CaptureDiscLabel", plus), ("JournalComposeDisc", pencil)] {
            XCTAssertFalse(
                source.contains("Color(\"CaptureDeep\")"),
                "\(file) spells the colour itself again, so the twins can drift apart."
            )
        }
    }

    // MARK: - The twins: the same halo, shrinking the same way

    /// The + disc's glow, unchanged — 0.5 / 12 / 8 at rest, 0.3 / 6 / 4 as a pill. E's call over
    /// §5's soft-shadow default for the pencil for the same reason the + has it: *"use the same
    /// glow as the +"*.
    func testTheGlowIsTheCaptureDiscsAtRestAndAsAPill() {
        XCTAssertEqual(
            CaptureDiscFace.glow(showsPill: false), CaptureDiscFace.Glow(opacity: 0.5, radius: 12, offsetY: 8)
        )
        XCTAssertEqual(
            CaptureDiscFace.glow(showsPill: true), CaptureDiscFace.Glow(opacity: 0.3, radius: 6, offsetY: 4)
        )
    }

    /// E's **"Follows the pill"**: 68% with the +, on the + disc's own curves — the spring on the
    /// shrink, the 0.9s `easeOut` regrow, and nothing under Reduce Motion (the + disc's shipped
    /// reading; the translucency is a continuous change, not an appearance).
    func testThePillCurvesAreTheCaptureDiscsAsymmetricPair() {
        XCTAssertEqual(
            CaptureDiscFace.pillAnimation(showsPill: true, reduceMotion: false),
            .spring(response: 0.35, dampingFraction: 0.8)
        )
        XCTAssertEqual(CaptureDiscFace.pillAnimation(showsPill: false, reduceMotion: false), .easeOut(duration: 0.9))
        XCTAssertNil(CaptureDiscFace.pillAnimation(showsPill: true, reduceMotion: true))
        XCTAssertNil(CaptureDiscFace.pillAnimation(showsPill: false, reduceMotion: true))
    }

    func testBothFacesReadTheSharedGlowPillOpacityAndCurves() throws {
        for file in ["Theme/CaptureDiscLabel.swift", "Journal/JournalComposeDisc.swift"] {
            let source = try Self.flattened(file)
            for anchor in [
                "CaptureDiscFace.glow(showsPill: showsPill)",
                "CaptureDiscMetrics.pillOpacity",
                "CaptureDiscFace.pillAnimation(showsPill: showsPill, reduceMotion: reduceMotion)"
            ] {
                XCTAssertTrue(
                    source.contains(anchor), "\(file) does not read `\(anchor)`, so the twins can fall out of step."
                )
            }
        }
    }

    // MARK: - The disc itself

    func testTheDiscIsAWhitePencilOnE42ptCircleWithTheHitOverflow() throws {
        let source = try Self.flattened("Journal/JournalComposeDisc.swift")
        for anchor in [
            "Image(systemName: \"square.and.pencil\")",
            ".font(.title3.weight(.semibold))",
            ".foregroundStyle(AreaPalette.work.onColor)",
            "width: JournalComposeDiscMetrics.diameter, height: JournalComposeDiscMetrics.diameter",
            ".padding(JournalComposeDiscMetrics.hitOverflow)",
            ".contentShape(Circle())",
            ".padding(-JournalComposeDiscMetrics.hitOverflow)",
            ".buttonStyle(PressScaleButtonStyle())"
        ] {
            XCTAssertTrue(source.contains(anchor), "JournalComposeDisc does not carry `\(anchor)`.")
        }
        XCTAssertFalse(source.contains("width: 42"), "A literal 42 is back beside E's named metric.")
    }

    // MARK: - Where it shows

    /// The Journal, at its top level, and nowhere else — the search row's rule (a pushed door has
    /// its own screen). Loaded or not: E's answer, 2026-09-18, *"Always on the Journal"*.
    func testTheDiscShowsOnTheJournalAtItsTopLevelOnly() {
        XCTAssertTrue(JournalComposeDoor.isShown(selectedTab: .journal, isAtRoot: true))
        XCTAssertFalse(
            JournalComposeDoor.isShown(selectedTab: .journal, isAtRoot: false),
            "A pushed task or capture door is under the Journal's pencil."
        )
        for tab in AppTab.allCases where tab != .journal {
            XCTAssertFalse(JournalComposeDoor.isShown(selectedTab: tab, isAtRoot: true), "The pencil shows on \(tab).")
        }
    }

    /// Appearing and leaving is a REDUCED SITE (§7.2): with motion, the search row's spring; under
    /// Reduce Motion a plain fade — never `nil`, which is a hard cut. The type is non-optional so a
    /// `nil` cannot even be written; the values are asserted so the two paths stay distinct.
    func testAppearingAndLeavingFadesOnBothPaths() {
        XCTAssertEqual(
            JournalComposeDoor.appearAnimation(reduceMotion: false),
            .spring(response: 0.35, dampingFraction: 0.8)
        )
        XCTAssertEqual(JournalComposeDoor.appearAnimation(reduceMotion: true), .default)
    }

    // MARK: - Reading the tree

    private static var appRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ADHD LifeOS")
    }

    /// Comment lines stripped, then flattened to one line so an anchor need not know the wrapping.
    private static func flattened(_ relativePath: String) throws -> String {
        let url = appRoot.appendingPathComponent(relativePath)
        return try String(contentsOf: url, encoding: .utf8)
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.hasPrefix("//") }
            .joined(separator: " ")
    }
}

//
//  UndoCapsulePresentationTests.swift
//  ADHD LifeOSTests
//
//  `F-C1-UndoCapsule`: the words, the glyphs and the geometry E chose in round 2b (board `54`,
//  option **A · Capsule in the disc row**).
//
//  These are pure functions rather than view-body reads for the reason every presentation type in
//  this app is pure: a SwiftUI body is ~0% covered by design, so a rule left inside one is a rule
//  nothing checks.
//

import SwiftUI
import XCTest
@testable import ADHD_LifeOS

final class UndoCapsulePresentationTests: XCTestCase {

    // MARK: - The words (E: "a glyph plus words naming what happened")

    func testEachKindNamesWhatHappenedInOneVerb() {
        XCTAssertEqual(RecentActionKind.taskClosed.verb, "Closed")
        XCTAssertEqual(RecentActionKind.nudgeDismissed.verb, "Done for now")
        XCTAssertEqual(RecentActionKind.captureSkipped.verb, "Skipped")
        XCTAssertEqual(RecentActionKind.captureJournalled.verb, "Journalled")
    }

    /// The area travels in the verb, exactly as the retired inbox bar said it — "Sorted to 💼 Work".
    func testSortingNamesTheAreaItFiledInto() {
        XCTAssertEqual(RecentActionKind.captureSorted(areaLabel: "💼 Work").verb, "Sorted to 💼 Work")
    }

    /// A deleted area degrades to the bare verb rather than quoting a raw id — the rule the inbox
    /// bar already held, carried over rather than re-decided.
    func testSortingIntoAnAreaThatIsGoneSaysJustSorted() {
        XCTAssertEqual(RecentActionKind.captureSorted(areaLabel: nil).verb, "Sorted")
    }

    // MARK: - The glyph

    func testACloseAndANudgeCarryTheCompletionGlyphInTheGoTint() {
        for kind in [RecentActionKind.taskClosed, .nudgeDismissed] {
            XCTAssertEqual(kind.systemImage, "checkmark.circle.fill", "\(kind) lost the completion glyph.")
            XCTAssertEqual(kind.glyphTint, .completion, "\(kind) is a completion, so its glyph is the go tint.")
        }
    }

    func testTheThreeTriageVerbsEachCarryTheirOwnGlyph() {
        XCTAssertEqual(RecentActionKind.captureSorted(areaLabel: nil).systemImage, "tray.full.fill")
        XCTAssertEqual(RecentActionKind.captureJournalled.systemImage, "book.closed.fill")
        XCTAssertEqual(RecentActionKind.captureSkipped.systemImage, "arrow.triangle.2.circlepath")
    }

    /// A skip is not a completion and must not read as one — it is the one kind whose glyph is
    /// quiet. Both others are accented, matching the tab their subject lives on.
    func testASkipIsTheOneQuietGlyph() {
        XCTAssertEqual(RecentActionKind.captureSkipped.glyphTint, .secondary)
        XCTAssertEqual(RecentActionKind.captureSorted(areaLabel: nil).glyphTint, .accent)
        XCTAssertEqual(RecentActionKind.captureJournalled.glyphTint, .accent)
    }

    // MARK: - The geometry

    /// Round 7: "48pt for anything that starts, closes, adds, undoes, ends or saves". Deliberately
    /// NOT `AppSearchRowMetrics.fieldHeight` (44) — a taller metric for this one control, which is
    /// why it is spelled separately rather than borrowed.
    func testTheCapsuleIsFortyEightPointsTallAndNotTheSearchFieldsFortyFour() {
        XCTAssertEqual(UndoCapsuleMetrics.minHeight, 48)
        XCTAssertNotEqual(UndoCapsuleMetrics.minHeight, AppSearchRowMetrics.fieldHeight)
    }

    /// It stands in for the search row, so it wears the row's corner rather than inventing one —
    /// §2's grid governs spacing, and a second radius beside the row it replaces would read as a
    /// different control in the same slot.
    func testItWearsTheSearchRowsCornerRatherThanANewNumber() {
        XCTAssertEqual(UndoCapsuleMetrics.cornerRadius, AppSearchRowMetrics.fieldCornerRadius)
    }

    /// The Undo control itself is a 48pt target too — it is the reason the capsule exists, and
    /// §3's floor is 44 with round 7 raising an action to 48.
    func testTheUndoControlIsItselfAFortyEightPointTarget() {
        XCTAssertEqual(UndoCapsuleMetrics.undoMinHeight, 48)
    }

    /// Every padding the capsule spends is on §2's 4/8/16/24 grid. The two sanctioned off-grid
    /// values in this app (`peekStep`, `floatingPaddingHorizontal`) are named waivers for other
    /// controls and do not reach here.
    func testEveryCapsuleSpacingIsOnTheGrid() {
        let grid: Set<CGFloat> = [4, 8, 16, 24]
        for (name, value) in UndoCapsuleMetrics.spacings {
            XCTAssertTrue(grid.contains(value), "`\(name)` is \(value), which is off §2's 4/8/16/24 grid.")
        }
    }

    // MARK: - The stacked layout at accessibility sizes (E, round 2b)

    func testTheCapsuleStacksAtAccessibilitySizesAndOnlyThere() {
        for size in DynamicTypeSize.allCases {
            XCTAssertEqual(
                UndoCapsuleLayout.isStacked(size), size.isAccessibilitySize,
                "\(size) resolves the wrong layout — E asked for a stacked one at accessibility sizes."
            )
        }
    }
}

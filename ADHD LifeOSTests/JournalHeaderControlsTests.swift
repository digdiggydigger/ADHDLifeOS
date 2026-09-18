//
//  JournalHeaderControlsTests.swift
//  ADHD LifeOSTests
//
//  `F-JournalDoorUnpinned` (E's option 04, 2026-09-18): the pinned "One line about today…" bar is
//  gone, so the header pencil is the Journal's ONLY door to a new entry — and it was a 40pt circle,
//  under §3's 44pt floor. A SwiftUI body cannot be measured from XCTest, so the geometry is held
//  the house way: the size is a named metric whose VALUE is asserted here, and the two header
//  circles are read from SOURCE to prove they are sized by it (the `FocusBarCollapseCallSiteTests`
//  shape). Either half alone is the repo's most repeated defect: a correct metric nothing reads.
//

import XCTest
@testable import ADHD_LifeOS

final class JournalHeaderControlsTests: XCTestCase {

    /// §3: every touch target is at least 44 × 44. A real frame, not the negative-padding overflow
    /// `AppTabBarMetrics.slotHitOverflow` uses — that trick exists so a target does not grow a
    /// CONSTRAINED container (the tab card, the collapsed sprint card). The header row's height is
    /// already set by the caption and the `.largeTitle`, so a 44pt circle costs no layout, and E's
    /// word was "grow".
    func testTheHeaderControlsMeetTheTouchFloor() {
        XCTAssertGreaterThanOrEqual(
            JournalHeaderMetrics.controlSize, AppTabBarPresentation.minimumTouchTarget,
            "The Journal's header circles are under §3's 44pt floor — and since the pinned composer"
                + " bar went (F-JournalDoorUnpinned) the pencil is the ONLY way to write an entry."
        )
    }

    /// Both circles, because they are one family (`JournalAllActivityButton`'s own header says the
    /// eye "is the compose button's circle"). Growing one alone would put a 40 beside a 44 and
    /// leave a real toggle under the floor.
    func testBothHeaderCirclesAreSizedByTheSharedMetric() throws {
        for file in ["Journal/JournalView.swift", "Journal/JournalAllActivityButton.swift"] {
            let code = try Self.code(file)
            XCTAssertTrue(
                code.contains("JournalHeaderMetrics.controlSize"),
                "\(file) no longer sizes its header circle with `JournalHeaderMetrics.controlSize`,"
                    + " so the metric this file's first test holds is not what reaches the screen."
            )
            XCTAssertFalse(
                code.contains("frame(width: 40, height: 40)"),
                "\(file) still hand-sizes a 40pt circle — under §3's floor."
            )
        }
    }

    /// The pencil IS the door now. This passed before the block by design — it pins what the block
    /// must keep, not what it adds — so it was mutation-checked instead: deleting either the
    /// identifier or the composer flag fails it.
    func testThePencilStillOpensTheComposer() throws {
        let code = try Self.code("Journal/JournalView.swift")
        let pencil = try XCTUnwrap(
            code.range(of: "Image(systemName: \"square.and.pencil\")"),
            "The header pencil is gone, and with the pinned bar deleted the Journal has no door."
        )
        let before = code[..<pencil.lowerBound]
        let buttonStart = try XCTUnwrap(before.range(of: "Button {", options: .backwards))
        XCTAssertTrue(
            code[buttonStart.upperBound..<pencil.lowerBound].contains("isPresentingComposer = true"),
            "The header pencil no longer opens the composer."
        )
        XCTAssertTrue(code.contains(".accessibilityIdentifier(\"journalComposeButton\")"))
        XCTAssertTrue(code.contains(".accessibilityLabel(\"Write an entry\")"))
    }

    // MARK: - Reading the tree

    private static var appRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // ADHD LifeOSTests
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("ADHD LifeOS")
    }

    /// The source with `//` comments stripped, so a doc comment that NAMES a pattern — the history
    /// these files keep on purpose — can never satisfy or trip an assertion about code.
    private static func code(_ relativePath: String) throws -> String {
        let url = appRoot.appendingPathComponent(relativePath)
        let source = try String(contentsOf: url, encoding: .utf8)
        var output = ""
        var index = source.startIndex
        while index < source.endIndex {
            if source[index...].hasPrefix("//") {
                while index < source.endIndex, source[index] != "\n" {
                    index = source.index(after: index)
                }
            } else {
                output.append(source[index])
                index = source.index(after: index)
            }
        }
        return output
    }
}

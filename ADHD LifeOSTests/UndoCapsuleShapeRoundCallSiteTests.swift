//
//  UndoCapsuleShapeRoundCallSiteTests.swift
//  ADHD LifeOSTests
//
//  `F-C1-UndoCapsule`'s SHAPE ROUND (E, 2026-09-20) — the three things E changed by LOOKING at the
//  capsule on their own phone, asserted by reading the tree.
//
//  **Its own file rather than three more methods in `UndoCapsuleCallSiteTests`**, which is already
//  at SwiftLint's 250-line type-body ceiling. Every call-site suite in this project carries its own
//  private source reader (twenty of them do), so the duplicated ~20 lines below are the house
//  pattern rather than a shortcut.
//
//  **Why a call-site read at all.** Two of the three are geometry a metrics test cannot see: a
//  `cardShape` that is a perfectly good `Capsule` proves nothing if the view hand-writes a
//  `RoundedRectangle` beside it, and a deleted constant proves nothing if the padding comes back
//  inline. The third is worse — with the chip gone, §3's 44pt tap target has no witness on screen
//  at all, so the lines that produce it are pinned here in the order that produces it.
//

import XCTest
@testable import ADHD_LifeOS

final class UndoCapsuleShapeRoundCallSiteTests: XCTestCase {

    /// **The card is DRAWN as a `Capsule`, and `UndoCapsuleMetrics.cardShape` being one is not
    /// enough.** A metrics test stays green on a build that hand-writes a `RoundedRectangle` back
    /// into the view and never reads the shared shape at all — the `dead-shared-component-pattern`
    /// failure exactly, a correct component sitting beside a call site that ignores it.
    ///
    /// **Both the fill and the border have to read it**, because `strokeBorder` needs an
    /// `InsettableShape` and the two temptations when that fails are to erase the type (`AnyShape`
    /// is NOT insettable — this bit the redesign round's render build) or to stroke a radius
    /// instead, either of which lets the fill and the outline drift apart.
    func testTheCardIsDrawnAsACapsuleAtBothItsFillAndItsBorder() throws {
        let capsule = try Self.appCode("Undo/UndoCapsule.swift")
        XCTAssertEqual(
            capsule.components(separatedBy: "UndoCapsuleMetrics.cardShape").count - 1, 2,
            "The card does not read the shared shape at BOTH its background and its border."
        )
        XCTAssertFalse(
            capsule.contains("RoundedRectangle"),
            "A `RoundedRectangle` is back in the capsule's tree. E chose \"Option C, 'Fully"
                + " rounded'\" by looking at eight shapes rendered on the real screen."
        )
    }

    /// **E removed the chip, and the padding that went with it must stay gone.** The Undo control's
    /// 16pt of horizontal padding was padding the INSIDE of that chip; with nothing drawn behind
    /// it, it is 32pt of invisible dead space taken from the task title beside it. Reclaiming it is
    /// what bought the wider single line E chose 44pt for, so reinstating either — while tidying,
    /// or by copying the tab bar's selected pill again — silently undoes the decision. Read across
    /// BOTH files, since a padding can come back as a constant or inline.
    func testNeitherTheChipNorTheUndoControlsPaddingCameBack() throws {
        for file in ["Undo/UndoCapsule.swift", "Undo/UndoCapsuleMetrics.swift"] {
            let source = try Self.appCode(file)
            XCTAssertFalse(
                source.contains("undoHorizontalPadding"),
                "\(file) has the Undo control's horizontal padding back — the 32pt E reclaimed."
            )
            XCTAssertFalse(
                source.contains("chipTint"),
                "\(file) tints a chip behind the Undo control again. E: \"remove the blue chip"
                    + " background colour behind the \"Undo\" Button\"."
            )
        }
    }

    /// **With the chip gone, these three lines ARE §3's 44pt on this control.** It lays out at 32
    /// so the card can be the 44pt E measured, and the hit area is grown back with the tab bar's
    /// own negative-padding trick around the `contentShape`. `UndoCapsulePresentationTests` proves
    /// the NUMBERS come to 44; only a call-site read proves they are still spent, and there is no
    /// longer a tinted pill on screen to show anyone that they are not.
    ///
    /// **Order is the mechanism**: grow, shape, shrink back. Any other arrangement either moves the
    /// layout or leaves the target at the laid-out height, which is why this walks a cursor forward
    /// rather than asking three times whether a line exists somewhere.
    func testTheUndoControlsTapTargetIsStillGrownBackToFortyFour() throws {
        let capsule = try Self.appCode("Undo/UndoCapsule.swift")
        let sequence = [
            ".padding(.vertical, UndoCapsuleMetrics.undoHitOverflow)",
            ".contentShape(Capsule(style: .continuous))",
            ".padding(.vertical, -UndoCapsuleMetrics.undoHitOverflow)"
        ]
        var cursor = capsule.startIndex
        for line in sequence {
            guard let found = capsule.range(of: line, range: cursor..<capsule.endIndex) else {
                return XCTFail(
                    "`\(line)` is missing or out of order, so the Undo control's tap target is"
                        + " whatever it lays out at and §3's 44pt floor is broken with nothing on"
                        + " screen to show it."
                )
            }
            cursor = found.upperBound
        }
    }

    // MARK: - Reading the tree

    /// The same source with every comment line removed, because these files document the very
    /// names the assertions look for — `UndoCapsuleMetrics` explains at length why
    /// `undoHorizontalPadding` was deleted, and a whole-file read would fail on that explanation.
    private static func appCode(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // ADHD LifeOSTests
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("ADHD LifeOS")
            .appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw ShapeRoundSourceError.unreadable(url.path)
        }
        return text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    private enum ShapeRoundSourceError: Error, CustomStringConvertible {
        case unreadable(String)

        var description: String {
            switch self {
            case .unreadable(let path):
                return "Could not read \(path). This test reads the tree it was compiled from (`#filePath`)."
            }
        }
    }
}

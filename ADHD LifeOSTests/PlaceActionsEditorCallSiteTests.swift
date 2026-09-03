//
//  PlaceActionsEditorCallSiteTests.swift
//  ADHD LifeOSTests
//
//  Source-reading pins for F-Routines-1-Order, in the CaptureDiscClearanceCallSiteTests mould:
//  the claims below live in SwiftUI bodies, which XCTest cannot reach, and this repo's most
//  repeated defect is exactly a view drifting away from what the pure layer promises. So the
//  test reads the SOURCE — the layer the claim actually lives in.
//
//  Two claims:
//  1. The actions ForEach reorders (`.onMove`), and ONLY it — the automation-guide rows answer
//     to their own ForEach precisely so row gestures cannot land on the wrong index, and a
//     second `.onMove` would be that bug arriving by another door.
//  2. The editor's footers tell the truth about who taps. `startSprint` claimed "runs by
//     itself" for four days while `PlaceActionPlan.split` made it tap-only (ActivityKit
//     refuses background starts) — the pre-existing copy bug the Routines scoping session
//     found. Only the two genuinely-auto kinds may make that claim.
//

import XCTest

final class PlaceActionsEditorCallSiteTests: XCTestCase {

    func testTheActionsForEach_andOnlyIt_reorders() throws {
        let source = try Self.appSource("Places/PlaceActionsSection.swift")

        XCTAssertEqual(
            source.components(separatedBy: ".onMove").count - 1, 1,
            "PlaceActionsSection needs exactly ONE .onMove — on the actions ForEach. Zero means"
                + " reordering is gone; two means the automation-guide rows grew one."
        )
    }

    func testTheActionsFooter_saysStepsRunInOrder() throws {
        let source = try Self.appSource("Places/PlaceActionsSection.swift")

        XCTAssertTrue(
            source.contains("Steps run top to bottom on the crossing. Drag to reorder."),
            "The footer is where a user DISCOVERS that order matters (the public-launch lens:"
                + " first-run discovery lives here in v1)."
        )
    }

    func testOnlyTheGenuinelyAutoKinds_claimToRunByThemselves() throws {
        let source = try Self.appSource("Places/PlaceActionsEditorView.swift")

        XCTAssertEqual(
            source.components(separatedBy: "Runs by itself when the crossing fires").count - 1, 2,
            "Exactly two footers may say an action runs itself: createCapture and journalLine —"
                + " the kinds PlaceActionPlan.split actually auto-runs. startSprint made this"
                + " claim falsely (ActivityKit refuses background starts; the tap starts it)."
        )
        XCTAssertTrue(
            source.contains("tapping it starts the sprint"),
            "The sprint footer must say the tap starts it — the honest copy for a tap-only kind."
        )
    }

    // MARK: - Reading the tree (the #filePath trick, shared shape with the clearance tests)

    private static var appRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // ADHD LifeOSTests
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("ADHD LifeOS")
    }

    private static func appSource(_ relativePath: String) throws -> String {
        let url = appRoot.appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw SourceError.unreadable(url.path)
        }
        return text
    }

    /// Loud rather than skipped — a guard that quietly disables itself is the failure mode
    /// these tests exist to prevent.
    private enum SourceError: Error, CustomStringConvertible {
        case unreadable(String)

        var description: String {
            switch self {
            case .unreadable(let path):
                return "Could not read the app sources at \(path)."
                    + " This test reads the tree it was compiled from (`#filePath`)."
            }
        }
    }
}

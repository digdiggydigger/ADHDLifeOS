//
//  ToolsRecentlyDeletedCallSiteTests.swift
//  ADHD LifeOSTests
//
//  `F-C3-RecentlyDeleted`: the Tools row and the launch purge, asserted by reading the tree.
//
//  Its own file because `ToolsPageCallSiteTests` had reached SwiftLint's 250-line type-body
//  ceiling — a LOCATION split. Everything that file's header says about why these are read rather
//  than exercised applies verbatim: a section that is never mounted draws nothing and fails no
//  behaviour test, because nothing builds `ToolsView`'s body in the standard run.
//

import XCTest
@testable import ADHD_LifeOS

final class ToolsRecentlyDeletedCallSiteTests: XCTestCase {

    /// **A SECTION, not a third bento card, and therefore `ToolsCatalog` is untouched.** E's round
    /// 2 word was "row"; `ToolsRoutinesSection` is the precedent. `ToolsCatalogTests` still pins
    /// exactly two `Entry` values, so a third CARD stays a decision rather than a drift — this
    /// test is the other half of that, asserting the row exists at all.
    func testTheRecentlyDeletedRowIsASectionAndOpensTheRealScreen() throws {
        let tools = Self.collapsed(try Self.appSource("Tools/ToolsView.swift"))
        XCTAssertTrue(
            tools.contains("ToolsRecentlyDeletedSection(client: recentlyDeletedClient)"),
            "The Tools page draws no Recently Deleted row, so the 30-day list is unreachable —"
                + " the only way back from a mistaken delete is the capsule, which is spent on"
                + " the user's next action."
        )
        XCTAssertTrue(
            tools.contains("RecentlyDeletedView(client: recentlyDeletedClient) .captureDiscClearance()"),
            "The row's push does not open `RecentlyDeletedView` with the disc clearance."
        )
        XCTAssertFalse(
            try Self.appSource("Tools/ToolsCatalog.swift").contains("recentlyDeleted"),
            "Recently Deleted became a third CARD. E said row, and `ToolsCatalog` pins the card"
                + " count so that a third door has to be a decision."
        )
    }

    /// **The one `#available` this section must NOT copy.** `ToolsRoutinesSection` is gated to
    /// iOS 17 because the Places editor a routine row opens is; Recently Deleted has no such
    /// dependency, and gating it would make a 16.0 user's only route back from a mistaken delete
    /// disappear (§7.1 — a feature whose absence is not announced is the shape that rule forbids).
    func testTheRecentlyDeletedSectionIsNotGatedToTheModernOS() throws {
        let section = try Self.appSource("RecentlyDeleted/ToolsRecentlyDeletedSection.swift")
        XCTAssertFalse(
            section.contains("@available(iOS"),
            "The Recently Deleted section copied Routines' availability gate along with its"
                + " shape. Routines is gated because the editor it opens is 17+; this screen has"
                + " no such dependency and is a 16.0 user's only route back from a delete."
        )
        let tools = Self.collapsed(try Self.appSource("Tools/ToolsView.swift"))
        XCTAssertFalse(
            tools.contains("if #available(iOS 17.0, *) { ToolsRecentlyDeletedSection"),
            "`ToolsView` wrapped the Recently Deleted section in an availability gate."
        )
    }

    /// The launch purge, E's Step 0 answer 1 (*"The app, when you open it"*), on the SIGNED-IN
    /// branch — it needs a uid, so it cannot sit on the app struct.
    func testTheLaunchPurgeRunsOnTheSignedInBranch() throws {
        let root = Self.collapsed(try Self.appSource("RootView.swift"))
        XCTAssertTrue(
            root.contains(".task { await RecentlyDeletedPurge.run() }"),
            "Nothing purges the 30-day window, so a deleted item waits forever and E's"
                + " *\"The app, when you open it\"* is unmet."
        )
        let signedIn = try XCTUnwrap(root.range(of: "case .signedIn:"))
        let purge = try XCTUnwrap(root.range(of: "RecentlyDeletedPurge.run()"))
        XCTAssertTrue(
            signedIn.lowerBound < purge.lowerBound,
            "The purge runs outside the signed-in branch, where there is no uid to purge."
        )
    }

    // MARK: - Reading the tree

    private static func collapsed(_ source: String) -> String {
        source.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    private static func appSource(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // ADHD LifeOSTests
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("ADHD LifeOS")
            .appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw ToolsRecentlyDeletedSourceError.unreadable(url.path)
        }
        return text
    }

    private enum ToolsRecentlyDeletedSourceError: Error, CustomStringConvertible {
        case unreadable(String)

        var description: String {
            switch self {
            case .unreadable(let path):
                return "Could not read \(path). This test reads the tree it was compiled from."
            }
        }
    }
}

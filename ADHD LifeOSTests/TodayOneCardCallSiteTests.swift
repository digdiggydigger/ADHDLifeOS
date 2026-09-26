//
//  TodayOneCardCallSiteTests.swift
//  ADHD LifeOSTests
//
//  `F-E3-OneCardToday`'s reachability and retirement guards — what the pure `TodayPlan` tests
//  cannot see, because it lives in a SwiftUI body or in which file a line sits.
//
//  Source is read with comment lines stripped and flattened to one line — the `*CallSiteTests`
//  house shape — so re-flowing a call never breaks a guard.
//

import XCTest
@testable import ADHD_LifeOS

final class TodayOneCardCallSiteTests: XCTestCase {

    // MARK: - The focus history outlives the charts that used to fetch it

    /// `FocusAnalyticsSection` was the ONLY writer of `publishedHistory`, through its load
    /// callback. Round 3 takes both charts off Today — and that history also feeds the weekly
    /// chain's "finished a sprint" signal, the gain line on Close, the week review and the Home
    /// Screen widget. Deleting the section alone breaks none of their tests and blanks all four.
    func testHomeReadsItsOwnFocusHistory() throws {
        let loader = try flattened("Home/HomeView+FocusHistory.swift")
        XCTAssertTrue(loader.contains("try? await focusHistoryReader.fetchHistory()"),
                      "Home no longer fetches the focus history itself.")
        XCTAssertTrue(loader.contains("publishedHistory = sessions"),
                      "The fetch never reaches `publishedHistory`, so the chain and the widget read [].")
        XCTAssertTrue(loader.contains("publishWidgetSnapshot(sprint: widgetSprint)"),
                      "A landed history must republish the widget, as the section's callback did.")
    }

    /// The same three triggers the charts reloaded on: first load, pull-to-refresh, and every
    /// finished sprint (`focusReloadToken` is RootView's `completedSprintCount`).
    func testTheHistoryReloadsOnTheChartsThreeTriggers() throws {
        let home = try flattened("Home/HomeView.swift")
        XCTAssertTrue(home.contains(".task(id: focusReloadToken + pullRefreshCount) { await loadFocusHistory() }"),
                      "The history must refetch on appear, on a pull and on every finished sprint.")
    }

    func testTheFocusChartsAreOffToday() throws {
        XCTAssertEqual(try occurrences(of: "FocusAnalyticsSection(", under: "Home"), [],
                       "Round 3: *\"Both charts come off Today.\"* (`F-E4` moves one into Week review.)")
    }

    // MARK: - Nudges stays reachable: its door moved to Tools (E, 2026-09-24)

    /// `NudgesView(` had exactly one production door, Today's nudges card, and Structure C removes
    /// it. E's Step 0 answer: *"the Nudges manager door moves to Tools, beside Routines."* A feature
    /// with no door is `F-FirstNudgeReachable`'s defect exactly.
    func testToolsHasTheNudgesDoorBesideRoutines() throws {
        let tools = try flattened("Tools/ToolsView.swift")
        let routines = try XCTUnwrap(tools.range(of: "ToolsRoutinesSection(")?.lowerBound)
        let nudges = try XCTUnwrap(tools.range(of: "ToolsNudgesSection(")?.lowerBound,
                                   "Tools draws no Nudges door, so the Nudges screen is unreachable.")
        XCTAssertLessThan(routines, nudges, "Beside Routines — directly after it.")
        XCTAssertTrue(tools.contains("case .nudges: NudgesView(service: nudgesService) .captureDiscClearance()"),
                      "The Nudges push must reach `NudgesView` with Tools' service, under the disc's clearance.")
    }

    /// Tools builds its `NudgesService` in `init`, where no `@Environment` value can be read — so,
    /// like Home, it hands the service the centre (the seven-day streak) and the undo slot in
    /// `.task`. Without them a dismissal on the Tools-pushed screen celebrates and records nothing.
    func testToolsHandsItsNudgesServiceTheCentreAndTheUndoSlot() throws {
        let tools = try flattened("Tools/ToolsView.swift")
        XCTAssertTrue(tools.contains("nudgesService.celebrate = celebrate"))
        XCTAssertTrue(tools.contains("nudgesService.recordAction = recordAction"))
    }

    // MARK: - Two week-review doors, one review (round 5b: "Both")

    /// Today's done line and the Areas row must open the SAME review — so both build it through
    /// `WeekReviewView(inputs:)`, and nothing else constructs one from loose parts.
    func testBothWeekReviewDoorsBuildTheReviewTheSameWay() throws {
        let doors = try occurrences(of: "WeekReviewView(", under: "").filter { $0 != "WeekReviewView.swift" }
        XCTAssertEqual(doors, ["AreasWeekReviewDoor.swift", "HomeWeekReviewRow.swift"])
        for door in doors {
            let path = door == "HomeWeekReviewRow.swift" ? "Home/\(door)" : "Areas/\(door)"
            XCTAssertTrue(try flattened(path).contains("WeekReviewView(inputs:"),
                          "\(door) builds the review from loose parts, so the two doors can drift.")
        }
    }

    /// *"...AND a row sits at the top of the Areas tab."*
    func testTheAreasRowSitsAtTheTopOfTheTab() throws {
        let areas = try flattened("Areas/AreasView.swift")
        let row = try XCTUnwrap(areas.range(of: "identifier: \"areasWeekReviewRow\"")?.lowerBound,
                                "The Areas tab has no Week review row.")
        let grid = try XCTUnwrap(areas.range(of: "grid(items: items)")?.lowerBound)
        XCTAssertLessThan(row, grid, "The row sits at the TOP — above the area grid.")
    }

    // MARK: - Reading the tree

    private func occurrences(of needle: String, under folder: String) throws -> [String] {
        let root = Self.appRoot.appendingPathComponent(folder)
        guard let walker = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else {
            throw SiteError.unreadable(root.path)
        }
        var found: [String] = []
        for case let url as URL in walker where url.pathExtension == "swift" {
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
            if stripped(text).contains(needle) { found.append(url.lastPathComponent) }
        }
        return found.sorted()
    }

    private func flattened(_ path: String) throws -> String {
        let url = Self.appRoot.appendingPathComponent(path)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw SiteError.unreadable(url.path)
        }
        return stripped(text)
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: " ")
    }

    private func stripped(_ text: String) -> String {
        text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    private static let appRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("ADHD LifeOS")

    private enum SiteError: Error, CustomStringConvertible {
        case unreadable(String)

        var description: String {
            switch self {
            case .unreadable(let path): return "could not read \(path)"
            }
        }
    }
}

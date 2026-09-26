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

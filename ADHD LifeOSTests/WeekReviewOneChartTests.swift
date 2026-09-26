//
//  WeekReviewOneChartTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// `F-E4-WeekReviewConsolidation`. Round 3, *"Charts → 'One bar chart in Week review.' Keep the
/// Mon–Sun bars and drop the 7-day trend line (its smoothing drew values below zero). Both charts
/// come off Today."* E's Step 0 (2026-09-24): the Mon–Sun focus widget REPLACES the review's
/// closures bars, shedding its streak stat and its minutes/hours toggle, its goal bar drawn only
/// once a goal is set.
///
/// Reverses `MomentumWeekReviewTests.testBuild_dayBarsCoverSevenDays`: the review still charts seven
/// days, but they are the CALENDAR week, Monday first, of measured focus — not a rolling window of
/// closures. Closures stay in the review as words (the headline, the wins, the quiet line).
@MainActor
final class WeekReviewOneChartTests: XCTestCase {

    /// 2026-08-19 12:00 UTC — a Wednesday, so the week has days on both sides of it.
    private let now = Date(timeIntervalSince1970: 1_787_140_800)

    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func inputs(sessions: [CompletedFocusSession], goal: Int?) -> WeekReviewInputs {
        WeekReviewInputs(
            tasks: [], lifeAreas: [], sessions: sessions, inboxCount: 0, openTaskCount: 0,
            areaCount: 0, dueNudgeCount: 0, focusDailyGoalMinutes: goal
        )
    }

    private func sprint(daysAgo: Int, minutes: Int) -> CompletedFocusSession {
        let ended = utc.date(byAdding: .day, value: -daysAgo, to: now)!
        return CompletedFocusSession(
            id: UUID(), taskId: nil, taskTitle: "Draft", lifeAreaEmoji: "💼",
            plannedSeconds: minutes * 60, focusedSeconds: minutes * 60, checkpointsReached: 0,
            completedNaturally: true, startedAt: ended.addingTimeInterval(TimeInterval(-minutes * 60)),
            endedAt: ended
        )
    }

    // MARK: - The chart's data

    func testTheReviewChartsTheCalendarWeekMondayFirst() {
        // Monday (2 days ago) and Tuesday count; LAST Sunday (3 days ago) is the previous week's.
        let view = WeekReviewView(
            inputs: inputs(sessions: [sprint(daysAgo: 2, minutes: 25), sprint(daysAgo: 3, minutes: 40),
                                      sprint(daysAgo: 1, minutes: 15)], goal: nil),
            asOf: now, calendar: utc
        )

        XCTAssertEqual(view.focusWeek.count, 7)
        XCTAssertEqual(utc.component(.weekday, from: view.focusWeek[0].date), 2, "Monday first")
        XCTAssertEqual(utc.component(.weekday, from: view.focusWeek[6].date), 1, "…through Sunday")
        XCTAssertEqual(view.focusWeek.map(\.focusedMinutes), [25, 15, 0, 0, 0, 0, 0])
    }

    func testNoGoalSetMeansNoGoalBar() {
        XCTAssertEqual(WeekReviewView(inputs: inputs(sessions: [], goal: nil), asOf: now, calendar: utc)
            .focusDailyGoalMinutes, 0, "`F-E1`: no goal, no bar — the widget draws its bar only above 0")
        XCTAssertEqual(WeekReviewView(inputs: inputs(sessions: [], goal: 30), asOf: now, calendar: utc)
            .focusDailyGoalMinutes, 30)
    }

    // MARK: - The one chart, and what it sheds

    func testWeekReviewDrawsTheOneFocusChartInPlaceOfTheClosureBars() throws {
        let review = try flattened("Home/WeekReviewView.swift")
        XCTAssertTrue(review.contains("WeeklyFocusSummaryWidget(buckets: focusWeek, dailyGoalMinutes: focusDailyGoalMinutes)"))
        XCTAssertFalse(review.contains("barsCard"), "Two bar charts would contradict \"one\"")
        XCTAssertFalse(review.contains("weekReviewBars"))
    }

    func testTheChartShedsItsStreakAndItsUnitToggle() throws {
        let widget = try flattened("Focus/WeeklyFocusSummaryWidget.swift")
        XCTAssertFalse(widget.contains("currentStreak"), "HOME-04: a fourth streak reading")
        XCTAssertFalse(widget.contains("Day Streak"))
        XCTAssertFalse(widget.contains("Picker("), "HOME-09: one of the three toggles")
        XCTAssertFalse(widget.contains("DisplayUnit"))
        XCTAssertTrue(widget.contains("if dailyGoalMinutes > 0 {"), "The goal bar stays gated on a set goal")
        XCTAssertFalse(widget.contains(".padding(12)"), "§2: 12 is off the grid")
    }

    /// Both doors carry the goal (the non-defaulted field makes the compiler hold that too), and the
    /// review turns "no goal" into the widget's 0 — `WeeklyChainCallSiteTests` pins the same line.
    func testBothDoorsCarryTheFocusGoal() throws {
        XCTAssertTrue(try flattened("Home/HomeWeekReviewRow.swift")
            .contains("focusDailyGoalMinutes: momentumPreferences.focusDailyGoalMinutes"))
        XCTAssertTrue(try flattened("Areas/AreasService.swift")
            .contains("focusDailyGoalMinutes: preferencesStore.read().focusDailyGoalMinutes"))
    }

    func testTheTrendLineAndItsOnlyHostAreGone() throws {
        for file in ["Focus/ProductivityTrendChart.swift", "Focus/FocusAnalyticsSection.swift"] {
            XCTAssertFalse(FileManager.default.fileExists(atPath: Self.appRoot.appendingPathComponent(file).path),
                           "\(file) outlived the chart it existed for")
        }
        for needle in ["ProductivityTrendChart", "FocusAnalyticsSection(", "rollingDays(", "peakDay(",
                       "dayCounts", "dayLabels"] {
            XCTAssertEqual(try filesContaining(needle), [], "\(needle) is dead once the trend line goes")
        }
    }

    // MARK: - Plumbing

    private static let appRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("ADHD LifeOS")

    private func flattened(_ path: String) throws -> String {
        let text = try String(contentsOf: Self.appRoot.appendingPathComponent(path), encoding: .utf8)
        return codeLines(text).joined(separator: " ")
    }

    private func codeLines(_ text: String) -> [String] {
        text.split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.hasPrefix("//") && !$0.hasPrefix("///") }
    }

    private func filesContaining(_ needle: String) throws -> [String] {
        let walker = FileManager.default.enumerator(at: Self.appRoot, includingPropertiesForKeys: nil)
        var hits: [String] = []
        while let url = walker?.nextObject() as? URL {
            guard url.pathExtension == "swift" else { continue }
            let text = try String(contentsOf: url, encoding: .utf8)
            if codeLines(text).contains(where: { $0.contains(needle) }) { hits.append(url.lastPathComponent) }
        }
        return hits.sorted()
    }
}

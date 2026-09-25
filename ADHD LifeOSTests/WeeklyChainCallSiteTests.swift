//
//  WeeklyChainCallSiteTests.swift
//  ADHD LifeOSTests
//
//  `F-E1-WeeklyChain`'s reachability and retirement guards. Two halves, and each is what a pure
//  test cannot see:
//
//  - **Retirement.** E's round 3: *"The other two streaks go: the closing streak '6 days · Best is
//    6' and the focus '2 Day Streak'. The nudge 'best 2' goes too."* The seven tests that pinned
//    `bestStreak`/`streakLine` were REVERSED into the absence assertions below rather than deleted,
//    so a later block cannot quietly bring a missed-day tally back.
//  - **Reachability.** The chain's inputs are four fetches on three screens, and a screen that
//    forgets one still compiles, still passes every `WeeklyActiveChainTests` case, and shows
//    "makes today count" on a day that already counts. Tests prove correctness, never
//    reachability (`dead-shared-component-pattern`).
//
//  Source is read with comment lines stripped and flattened to one line — the `*CallSiteTests`
//  house shape — so re-flowing a call never breaks a guard.
//

import XCTest
@testable import ADHD_LifeOS

final class WeeklyChainCallSiteTests: XCTestCase {

    // MARK: - Retired: the daily streaks and their best-ever tallies

    func testNoDailyStreakOrBestEverTallySurvivesInTheApp() throws {
        let retired = [
            "func streak(tasks:", "func bestStreak(", "func streakLine(", "trailingWeekClosureFlags",
            // The button's old copy, not "-day streak": Settings rightly names E's seven-day
            // nudge MILESTONE, a celebration of what was done, which round 3 left in place.
            "Close it — keeps", "Best is", "· best ", "start a streak", "days closed in a row"
        ]
        for needle in retired {
            let sites = try occurrences(of: needle, under: Self.appRoot)
            XCTAssertTrue(sites.isEmpty, "\"\(needle)\" is retired (E, round 3) but appears in \(sites)")
        }
    }

    /// The Home Screen widget's focus streak is the "2 Day Streak" E named. The stat and the goal
    /// bar's "· N streak" both go; the wire field stays, so an old widget binary still decodes.
    func testTheHomeScreenWidgetShowsNoFocusStreak() throws {
        let widget = try flattened(Self.widgetRoot.appendingPathComponent("FocusStatsWidget.swift"))
        XCTAssertFalse(widget.contains("week.streak"), "the widget must not render the focus streak")
        XCTAssertFalse(widget.contains("caption: \"streak\""))
    }

    // MARK: - Goals off until set

    /// Round 3 reaches the Home Screen widget: its goal bar draws only once a goal is set, and Home
    /// publishes "no goal" as the wire's 0 rather than falling back to a goal nobody chose.
    func testTheWidgetGoalBarIsGatedAndHomePublishesNoGoalAsZero() throws {
        let widget = try flattened(Self.widgetRoot.appendingPathComponent("FocusStatsWidget.swift"))
        XCTAssertTrue(widget.contains("hasDailyGoal"), "the goal bar must be gated on a set goal")
        let refresh = try flattened(Self.appRoot.appendingPathComponent("Home/HomeView+Refresh.swift"))
        XCTAssertTrue(refresh.contains("dailyGoalMinutes: momentumPreferences.focusDailyGoalMinutes ?? 0"))
        let analytics = try flattened(Self.appRoot.appendingPathComponent("Focus/FocusAnalyticsSection.swift"))
        XCTAssertTrue(analytics.contains(".focusDailyGoalMinutes ?? 0"))
    }

    /// The two "Set a … goal" toggles and the chain's Stepper are the only writers of the three new
    /// preferences — the helpers are unit-tested, and this is the proof something calls them.
    func testSettingsWiresBothGoalTogglesAndTheChainStepper() throws {
        let settings = try flattened(
            Self.appRoot.appendingPathComponent("Settings/SettingsPreferenceSections.swift")
        )
        XCTAssertTrue(settings.contains("setDailyGoalEnabled("))
        XCTAssertTrue(settings.contains("setFocusGoalEnabled("))
        XCTAssertTrue(settings.contains("momentumPreferences.weeklyActiveDayGoal = newValue"))
        XCTAssertTrue(settings.contains("in: WeeklyActiveChain.goalRange"))
        // The apple-design review's in-scope fix: the chain's N is revealed with the chain, the
        // same way each goal's Stepper is revealed with its toggle.
        XCTAssertTrue(settings.contains("if momentumPreferences.showStreaks { Stepper("))
    }

    // MARK: - "Makes today count": every door into Task Detail answers it

    /// Three screens push Task Detail with a Momentum context — the spec named two; the third is
    /// Journal's. `hasCountedToday:` is a required parameter, so the compiler guards its presence;
    /// this pins that there are exactly three, so a fourth door is a deliberate addition.
    func testThreeDoorsBuildTheMomentumContext() throws {
        let sites = try occurrences(of: "MomentumTaskContext.build(", under: Self.appRoot)
        XCTAssertEqual(sites.sorted(), ["HomeMomentumSections.swift", "JournalView.swift", "TaskListView.swift"])
    }

    /// Home is the one screen that holds all four signals, and the journal plumb is new in this
    /// block — so each of the four is pinned by name at the one place Home assembles them.
    func testHomeFeedsTheChainAllFourSignals() throws {
        let home = try flattened(Self.appRoot.appendingPathComponent("Home/HomeView+WeeklyChain.swift"))
        let signals = try XCTUnwrap(
            home.range(of: "WeeklyActiveChain.Signals(").map { String(home[$0.lowerBound...].prefix(260)) }
        )
        for argument in ["tasks: homeService.allTasks", "sessions: publishedHistory",
                         "capturesCleared: clearedCaptureStamps", "journalLines: journalLineStamps"] {
            XCTAssertTrue(signals.contains(argument), "Home's chain signals are missing `\(argument)`")
        }
        XCTAssertTrue(home.contains("journalClient?.fetchLogs()"), "the journal signal must be fetched")
        let sections = try flattened(Self.appRoot.appendingPathComponent("Home/HomeMomentumSections.swift"))
        XCTAssertTrue(sections.contains("hasCountedToday: hasCountedToday"))
    }

    /// Journal holds its own lines, so its door must count them — the case a tasks-only answer
    /// would get wrong on the very screen the line was written on.
    func testJournalsDoorCountsItsOwnLines() throws {
        let journal = try flattened(Self.appRoot.appendingPathComponent("Journal/JournalView.swift"))
        XCTAssertTrue(journal.contains("journalLines: allLogs.map(\\.createdAt)"))
        XCTAssertTrue(journal.contains("sessions: journalService.focusSessions"))
    }

    // MARK: - Helpers

    private func occurrences(of needle: String, under root: URL) throws -> [String] {
        guard let walker = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else {
            throw ChainSiteError.unreadable(root.path)
        }
        var found: [String] = []
        for case let url as URL in walker where url.pathExtension == "swift" {
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
            if stripped(text).contains(needle) { found.append(url.lastPathComponent) }
        }
        return found
    }

    private func flattened(_ url: URL) throws -> String {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw ChainSiteError.unreadable(url.path)
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

    private static let repoRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    private static let appRoot = repoRoot.appendingPathComponent("ADHD LifeOS")
    private static let widgetRoot = repoRoot.appendingPathComponent("FocusTimerWidget")

    private enum ChainSiteError: Error, CustomStringConvertible {
        case unreadable(String)

        var description: String {
            switch self {
            case .unreadable(let path): return "could not read \(path)"
            }
        }
    }
}

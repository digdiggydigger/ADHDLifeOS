//
//  FocusWidgetSnapshotBuilderTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Projects Home's live state (active goal + focus history) onto the widget payload. Pure, so the
/// numbers the Home Screen shows are locked to the same `FocusAnalytics` maths the in-app weekly
/// widget uses — the two can never quietly disagree.
final class FocusWidgetSnapshotBuilderTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// Wednesday 19 August 2026, 22:00 UTC.
    private let now = Date(timeIntervalSince1970: 1_787_176_800)

    private func session(daysAgo: Int, seconds: Int, completed: Bool = true) -> CompletedFocusSession {
        let endedAt = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
        return CompletedFocusSession(
            id: UUID(), taskId: UUID(), taskTitle: "Sprint", lifeAreaEmoji: "🫀",
            plannedSeconds: seconds, focusedSeconds: seconds, checkpointsReached: 1,
            completedNaturally: completed,
            startedAt: endedAt.addingTimeInterval(TimeInterval(-seconds)), endedAt: endedAt
        )
    }

    private func lifeArea(name: String, emoji: String) -> LifeArea {
        LifeArea(id: UUID(), name: name, colour: emoji, sortOrder: 0, archived: false)
    }

    private func build(
        activeGoal: TaskSummary?,
        lifeAreas: [LifeArea] = [],
        sessions: [CompletedFocusSession] = []
    ) -> FocusWidgetSnapshot {
        FocusWidgetSnapshotBuilder.snapshot(
            activeGoal: activeGoal, lifeAreas: lifeAreas, sessions: sessions,
            now: now, calendar: calendar
        )
    }

    // MARK: - Active goal

    func testActiveGoal_carriesTitleAreaNameAndEmoji() {
        let area = lifeArea(name: "Health", emoji: "🫀")
        let goal = TaskSummary(
            lifeAreaId: area.id, status: .open, title: "Take a 10-minute walk",
            focusDurationSeconds: 900, nudgesCount: 10
        )

        let snapshot = build(activeGoal: goal, lifeAreas: [area])

        XCTAssertEqual(snapshot.activeGoal?.title, "Take a 10-minute walk")
        XCTAssertEqual(snapshot.activeGoal?.lifeAreaName, "Health")
        XCTAssertEqual(snapshot.activeGoal?.emoji, "🫀")
        XCTAssertEqual(snapshot.activeGoal?.focusDurationSeconds, 900)
        XCTAssertEqual(snapshot.activeGoal?.nudgeCount, 10)
    }

    func testActiveGoal_withNoLifeArea_fallsBackToTheTargetGlyph() {
        let goal = TaskSummary(lifeAreaId: nil, status: .open, title: "Unfiled task")

        let snapshot = build(activeGoal: goal)

        XCTAssertNil(snapshot.activeGoal?.lifeAreaName)
        XCTAssertEqual(snapshot.activeGoal?.emoji, "🎯", "the same unassigned glyph every start path uses")
    }

    func testActiveGoal_resolvesAnUnsetFocusConfigThroughTheStandardDefaults() {
        let goal = TaskSummary(lifeAreaId: nil, status: .open, title: "No sprint configured")

        let snapshot = build(activeGoal: goal)

        XCTAssertEqual(snapshot.activeGoal?.focusDurationSeconds, FocusNudgeCadence.standardDurationSeconds)
        XCTAssertEqual(
            snapshot.activeGoal?.nudgeCount,
            FocusNudgeCadence.standardCount(forDurationSeconds: FocusNudgeCadence.standardDurationSeconds)
        )
    }

    func testNoActiveGoal_leavesTheFieldNilRatherThanFabricatingOne() {
        let snapshot = build(activeGoal: nil)

        XCTAssertNil(snapshot.activeGoal, "the hero is hidden on Home in this state; the widget matches")
    }

    // MARK: - Week stats

    func testWeekStats_mirrorTheInAppWeeklyWidgetMaths() {
        // Wednesday `now`: today plus Monday, i.e. two active days this calendar week.
        let sessions = [
            session(daysAgo: 0, seconds: 900),
            session(daysAgo: 0, seconds: 360),
            session(daysAgo: 2, seconds: 600)
        ]
        let buckets = FocusAnalytics.currentWeek(sessions: sessions, now: now, calendar: calendar)

        let week = build(activeGoal: nil, sessions: sessions).week

        XCTAssertEqual(week.focusedSeconds, FocusAnalytics.totalFocusedSeconds(buckets))
        XCTAssertEqual(week.sessionCount, FocusAnalytics.totalSessions(buckets))
        XCTAssertEqual(week.activeDayCount, FocusAnalytics.activeDayCount(buckets))
        XCTAssertEqual(week.dailyAverageSeconds, FocusAnalytics.dailyAverageSeconds(buckets))
        XCTAssertEqual(week.streak, FocusAnalytics.currentStreak(buckets))
        XCTAssertEqual(week.focusedSeconds, 1860)
        XCTAssertEqual(week.activeDayCount, 2)
    }

    func testWeekStats_alwaysCarrySevenMondayFirstDays() {
        let sessions = [session(daysAgo: 0, seconds: 600)]

        let week = build(activeGoal: nil, sessions: sessions).week

        XCTAssertEqual(week.dailyFocusedSeconds.count, 7)
        XCTAssertEqual(week.dailyFocusedSeconds[2], 600, "Wednesday is index 2 in a Monday-first week")
        XCTAssertEqual(week.dailyFocusedSeconds.filter { $0 > 0 }.count, 1)
    }

    func testWeekStats_withNoHistory_areAllZeroNotAbsent() {
        let week = build(activeGoal: nil).week

        XCTAssertEqual(week.focusedSeconds, 0)
        XCTAssertEqual(week.sessionCount, 0)
        XCTAssertEqual(week.streak, 0)
        XCTAssertEqual(week.dailyFocusedSeconds, Array(repeating: 0, count: 7))
    }

    func testWeekStats_ignoreSessionsOutsideTheCurrentWeek() {
        let sessions = [session(daysAgo: 0, seconds: 600), session(daysAgo: 20, seconds: 3600)]

        let week = build(activeGoal: nil, sessions: sessions).week

        XCTAssertEqual(week.focusedSeconds, 600, "last month's focus is not this week's")
    }

    func testWeekStats_carryTheSameDailyGoalTheInAppWidgetUses() {
        XCTAssertEqual(build(activeGoal: nil).week.dailyGoalMinutes, 30)
    }

    // MARK: - Envelope

    func testSnapshot_stampsGenerationTimeAndVersion() {
        let snapshot = build(activeGoal: nil)

        XCTAssertEqual(snapshot.generatedAt, now)
        XCTAssertEqual(snapshot.version, FocusWidgetSnapshot.currentVersion)
    }
}

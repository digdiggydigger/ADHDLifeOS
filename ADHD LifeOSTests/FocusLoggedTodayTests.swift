//
//  FocusLoggedTodayTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// BUG-b10 (E's on-device checklist, 2026-08-26): a focus session that completes — including one
/// that ran out while the app was dead — must be VISIBLE on the Today hero for its task, not just
/// silently logged. The hero's chip and button both hang off this one label; nil means "nothing
/// logged against this task today" and the card stays exactly as it was.
final class FocusLoggedTodayTests: XCTestCase {
    private let taskId = UUID()
    private let calendar = Calendar.current
    private let now = Date()

    private func session(
        taskId: UUID?,
        focusedSeconds: Int,
        endedAt: Date
    ) -> CompletedFocusSession {
        CompletedFocusSession(
            id: UUID(),
            taskId: taskId,
            taskTitle: "Any",
            lifeAreaEmoji: "🎯",
            plannedSeconds: focusedSeconds,
            focusedSeconds: focusedSeconds,
            checkpointsReached: 0,
            completedNaturally: true,
            startedAt: endedAt.addingTimeInterval(TimeInterval(-focusedSeconds)),
            endedAt: endedAt
        )
    }

    func testNoSessions_givesNoLabel() {
        XCTAssertNil(MomentumScoreboard.focusLoggedTodayLabel(
            sessions: [], taskId: taskId, asOf: now, calendar: calendar
        ))
    }

    /// E's own repro used a 30-second sprint — a sub-minute session must still show, or the fix
    /// looks broken in the exact test that found the bug. (The Journal hides sub-minute sprints;
    /// this label deliberately does NOT share that rule.)
    func testSingleSubMinuteSessionToday_countsWithoutAMinuteFigure() {
        let label = MomentumScoreboard.focusLoggedTodayLabel(
            sessions: [session(taskId: taskId, focusedSeconds: 30, endedAt: now)],
            taskId: taskId, asOf: now, calendar: calendar
        )
        XCTAssertEqual(label, "1 session today")
    }

    func testMultipleSessions_sumTheirMinutes() {
        let label = MomentumScoreboard.focusLoggedTodayLabel(
            sessions: [
                session(taskId: taskId, focusedSeconds: 20 * 60, endedAt: now),
                session(taskId: taskId, focusedSeconds: 15 * 60, endedAt: now)
            ],
            taskId: taskId, asOf: now, calendar: calendar
        )
        XCTAssertEqual(label, "2 sessions · 35 min today")
    }

    func testYesterdaysSession_doesNotCount() {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        XCTAssertNil(MomentumScoreboard.focusLoggedTodayLabel(
            sessions: [session(taskId: taskId, focusedSeconds: 600, endedAt: yesterday)],
            taskId: taskId, asOf: now, calendar: calendar
        ))
    }

    func testOtherTasksAndTasklessSessions_doNotCount() {
        XCTAssertNil(MomentumScoreboard.focusLoggedTodayLabel(
            sessions: [
                session(taskId: UUID(), focusedSeconds: 600, endedAt: now),
                session(taskId: nil, focusedSeconds: 600, endedAt: now)
            ],
            taskId: taskId, asOf: now, calendar: calendar
        ))
    }

    /// Whole minutes floor: 90 seconds is "1 min", not a rounded-up "2 min" — the label must
    /// never claim more focus than happened.
    func testMinutesFloor_neverOverstates() {
        let label = MomentumScoreboard.focusLoggedTodayLabel(
            sessions: [session(taskId: taskId, focusedSeconds: 90, endedAt: now)],
            taskId: taskId, asOf: now, calendar: calendar
        )
        XCTAssertEqual(label, "1 session · 1 min today")
    }
}

//
//  FocusSprintConfigurationTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Locks down the web prototype's per-task focus defaults (`TaskDetailModal.tsx` /
/// `SwipeableTaskCard.tsx`): a task with no stored duration runs the standard 15-minute sprint,
/// stored values are clamped to the web's 30s–120m input bounds, and an unset nudge count falls
/// back to 1 for a ≤60s sprint and 2 otherwise.
final class FocusSprintConfigurationTests: XCTestCase {
    // MARK: - Duration resolution

    func testResolvedDuration_nilFallsBackToStandardFifteenMinutes() {
        XCTAssertEqual(FocusSprintConfiguration.resolvedDuration(explicit: nil), 900)
    }

    func testResolvedDuration_storedValueIsUsed() {
        XCTAssertEqual(FocusSprintConfiguration.resolvedDuration(explicit: 600), 600)
        XCTAssertEqual(FocusSprintConfiguration.resolvedDuration(explicit: 30), 30)
    }

    func testResolvedDuration_clampsBelowThirtySeconds() {
        XCTAssertEqual(FocusSprintConfiguration.resolvedDuration(explicit: 5), 30)
        XCTAssertEqual(FocusSprintConfiguration.resolvedDuration(explicit: 0), 30)
        XCTAssertEqual(FocusSprintConfiguration.resolvedDuration(explicit: -10), 30)
    }

    func testResolvedDuration_clampsAboveTwoHours() {
        XCTAssertEqual(FocusSprintConfiguration.resolvedDuration(explicit: 100_000), 7200)
    }

    func testClampDuration_matchesResolutionBounds() {
        XCTAssertEqual(FocusSprintConfiguration.clampDuration(29), 30)
        XCTAssertEqual(FocusSprintConfiguration.clampDuration(30), 30)
        XCTAssertEqual(FocusSprintConfiguration.clampDuration(7200), 7200)
        XCTAssertEqual(FocusSprintConfiguration.clampDuration(7201), 7200)
    }

    // MARK: - Nudge-count resolution

    func testResolvedNudgeCount_nilUsesStandardCadenceRule() {
        XCTAssertEqual(FocusSprintConfiguration.resolvedNudgeCount(explicit: nil, durationSeconds: 30), 1)
        XCTAssertEqual(FocusSprintConfiguration.resolvedNudgeCount(explicit: nil, durationSeconds: 60), 1)
        XCTAssertEqual(FocusSprintConfiguration.resolvedNudgeCount(explicit: nil, durationSeconds: 61), 2)
        XCTAssertEqual(FocusSprintConfiguration.resolvedNudgeCount(explicit: nil, durationSeconds: 900), 2)
    }

    func testResolvedNudgeCount_explicitValueIsUsedIncludingZero() {
        XCTAssertEqual(FocusSprintConfiguration.resolvedNudgeCount(explicit: 0, durationSeconds: 900), 0)
        XCTAssertEqual(FocusSprintConfiguration.resolvedNudgeCount(explicit: 5, durationSeconds: 900), 5)
    }

    func testResolvedNudgeCount_clampsToZeroThroughTen() {
        XCTAssertEqual(FocusSprintConfiguration.resolvedNudgeCount(explicit: -1, durationSeconds: 900), 0)
        XCTAssertEqual(FocusSprintConfiguration.resolvedNudgeCount(explicit: 99, durationSeconds: 900), 10)
    }

    // MARK: - Presets

    func testPresetDurations_matchTheWebModalChips() {
        XCTAssertEqual(
            FocusSprintConfiguration.presetDurationsSeconds,
            [30, 60, 120, 300, 600, 900, 1500]
        )
    }

    // MARK: - Human sprint-length formatting (web `formatFocusDuration`)

    func testHumanFormatting_matchesTheWebFormatter() {
        XCTAssertEqual(FocusTimeFormatting.human(seconds: 30), "30s")
        XCTAssertEqual(FocusTimeFormatting.human(seconds: 59), "59s")
        XCTAssertEqual(FocusTimeFormatting.human(seconds: 60), "1m")
        XCTAssertEqual(FocusTimeFormatting.human(seconds: 450), "7m 30s")
        XCTAssertEqual(FocusTimeFormatting.human(seconds: 900), "15m")
        XCTAssertEqual(FocusTimeFormatting.human(seconds: -5), "0s")
    }

    // MARK: - Plan from a task card

    func testPlanFromTaskItem_resolvesStoredConfigAndAreaEmoji() {
        let taskId = UUID()
        let task = TaskItem(
            id: taskId, lifeAreaId: UUID(), title: "Write the report",
            status: .open, priority: .p2, dueDate: nil,
            focusDurationSeconds: 300, nudgesCount: 3
        )
        let area = LifeArea(id: task.lifeAreaId ?? UUID(), name: "Work", colour: "💼", sortOrder: 0)

        let plan = FocusSprintPlan(task: task, lifeArea: area)

        XCTAssertEqual(plan.taskId, taskId)
        XCTAssertEqual(plan.taskTitle, "Write the report")
        XCTAssertEqual(plan.lifeAreaEmoji, "💼")
        XCTAssertEqual(plan.durationSeconds, 300)
        XCTAssertEqual(plan.nudgeCount, 3)
    }

    func testPlanFromTaskItem_defaultsWhenTaskCarriesNoConfig() {
        let task = TaskItem(
            id: UUID(), lifeAreaId: nil, title: "Untuned task",
            status: .open, priority: .p4, dueDate: nil
        )

        let plan = FocusSprintPlan(task: task, lifeArea: nil)

        XCTAssertEqual(plan.durationSeconds, 900)
        XCTAssertEqual(plan.nudgeCount, 2)
        XCTAssertEqual(plan.lifeAreaEmoji, "🎯")
    }
}

//
//  FocusSprintConfiguration.swift
//  ADHD LifeOS
//

import Foundation

/// Per-task focus-sprint defaults and bounds, ported from the web prototype's
/// `TaskDetailModal.tsx` / `SwipeableTaskCard.tsx`: a task with no stored duration runs the
/// standard 15-minute sprint, stored values are clamped to the modal's 30s–120m input bounds,
/// and an unset nudge count falls back to the standard cadence rule (1 for ≤60s, else 2).
/// Pure and total, so every card, detail screen and start action resolves a task's config the
/// same way — and the rules are unit-testable without a view host.
enum FocusSprintConfiguration {
    static let minimumDurationSeconds = FocusCheckpoints.minimumIntervalSeconds
    /// The web modal's numeric input caps at 7200s / 120m.
    static let maximumDurationSeconds = 7200
    static let defaultDurationSeconds = FocusNudgeCadence.standardDurationSeconds
    static let maximumNudgeCount = 10
    /// The web modal's quick preset chips: 30s, 1m, 2m, 5m, 10m, 15m, 25m.
    static let presetDurationsSeconds = [30, 60, 120, 300, 600, 900, 1500]

    static func clampDuration(_ seconds: Int) -> Int {
        min(max(seconds, minimumDurationSeconds), maximumDurationSeconds)
    }

    static func resolvedDuration(explicit: Int?) -> Int {
        guard let explicit else { return defaultDurationSeconds }
        return clampDuration(explicit)
    }

    static func clampNudgeCount(_ count: Int) -> Int {
        min(max(count, 0), maximumNudgeCount)
    }

    static func resolvedNudgeCount(explicit: Int?, durationSeconds: Int) -> Int {
        guard let explicit else { return FocusNudgeCadence.standardCount(forDurationSeconds: durationSeconds) }
        return clampNudgeCount(explicit)
    }
}

/// Everything `FocusSessionService.start` needs to launch a sprint, resolved from a task's stored
/// config (or the staged edits on the detail screen). Built at the interaction site and handed up
/// to `RootView`, which owns the app-wide `FocusSessionService`.
struct FocusSprintPlan: Equatable, Sendable {
    let taskId: UUID?
    let taskTitle: String
    let lifeAreaEmoji: String
    let durationSeconds: Int
    let nudgeCount: Int

    init(taskId: UUID?, taskTitle: String, lifeAreaEmoji: String, durationSeconds: Int, nudgeCount: Int) {
        self.taskId = taskId
        self.taskTitle = taskTitle
        self.lifeAreaEmoji = lifeAreaEmoji
        self.durationSeconds = FocusSprintConfiguration.clampDuration(durationSeconds)
        self.nudgeCount = FocusSprintConfiguration.clampNudgeCount(nudgeCount)
    }

    /// The card's one-tap start: the task's stored config resolved through the standard defaults,
    /// with the life area's emoji (stored in `colour`) or the unassigned target glyph.
    init(task: TaskItem, lifeArea: LifeArea?) {
        let duration = FocusSprintConfiguration.resolvedDuration(explicit: task.focusDurationSeconds)
        self.init(
            taskId: task.id,
            taskTitle: task.title,
            lifeAreaEmoji: lifeArea?.colour ?? "🎯",
            durationSeconds: duration,
            nudgeCount: FocusSprintConfiguration.resolvedNudgeCount(
                explicit: task.nudgesCount, durationSeconds: duration
            )
        )
    }
}

//
//  FocusNudgeCadence.swift
//  ADHD LifeOS
//
//  The sprint-planning vocabulary and the history-logging seam, split from
//  `FocusSessionService.swift` for that file's length budget (F-SprintPersistence made the
//  service grow its restore path).
//

import Foundation

/// Thin seam over the focus-history backend so `FocusSessionService` is testable without a
/// network — same `*Adapting` convention as every other feature.
protocol FocusSessionLogging: Sendable {
    func logCompletedSession(_ session: CompletedFocusSession) async throws
}

/// How a sprint's checkpoint nudges are spaced.
enum FocusNudgeCadence: Equatable, Sendable {
    /// N evenly-spaced checkpoints between start and finish.
    case count(Int)
    /// One checkpoint every N seconds (floored at 30s, per the web).
    case interval(seconds: Int)

    /// The web's implicit default when a task carries no explicit nudge count: one checkpoint for
    /// a very short sprint, two for anything longer (`secs <= 60 ? 1 : 2`).
    static func standard(forDurationSeconds duration: Int) -> FocusNudgeCadence {
        .count(standardCount(forDurationSeconds: duration))
    }

    /// The bare count behind `standard(forDurationSeconds:)`, exposed so
    /// `FocusSprintConfiguration` resolves an unset per-task nudge count from the same rule.
    static func standardCount(forDurationSeconds duration: Int) -> Int {
        duration <= 60 ? 1 : 2
    }

    /// The default sprint length when a task has no target of its own — the web's `15 * 60`.
    static let standardDurationSeconds = 15 * 60

    func checkpoints(forDurationSeconds duration: Int) -> [Int] {
        switch self {
        case .count(let count):
            return FocusCheckpoints.evenlySpaced(durationSeconds: duration, count: count)
        case .interval(let seconds):
            return FocusCheckpoints.interval(durationSeconds: duration, intervalSeconds: seconds)
        }
    }
}

extension FocusSessionService {
    /// Starts a sprint from a resolved per-task plan (card tap, detail-screen launch).
    func start(plan: FocusSprintPlan) {
        start(
            taskId: plan.taskId,
            taskTitle: plan.taskTitle,
            lifeAreaEmoji: plan.lifeAreaEmoji,
            durationSeconds: plan.durationSeconds,
            cadence: .count(plan.nudgeCount)
        )
    }
}

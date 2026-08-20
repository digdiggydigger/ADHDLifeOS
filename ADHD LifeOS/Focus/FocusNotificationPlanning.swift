//
//  FocusNotificationPlanning.swift
//  ADHD LifeOS
//

import Foundation

/// One local notification a running sprint needs the system to post on its behalf.
struct ScheduledFocusNotification: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case checkpoint(index: Int)
        case sprintComplete
    }

    let kind: Kind
    let fireDate: Date
    let title: String
    let body: String

    /// Keeps these clear of the per-task (`taskCountdownNudge.`) and per-nudge
    /// (`nudgeNotification.`) namespaces, so none of the three features can cancel another's — and
    /// so a delegate handling a TAP can tell whose notification it is (`FocusNotificationResponse`).
    /// Named here rather than spelled inline at each site, which is how the withdraw filter and the
    /// tap router could otherwise drift apart from the identifiers they are meant to match.
    static let identifierPrefix = "focusSprint."

    /// Stable per kind, so re-handing a plan replaces the previous requests rather than stacking
    /// duplicates. Only one sprint runs at a time, so no per-sprint namespace is needed.
    var identifier: String {
        switch kind {
        case .checkpoint(let index): return "\(Self.identifierPrefix)checkpoint.\(index)"
        case .sprintComplete: return "\(Self.identifierPrefix)complete"
        }
    }
}

/// Turns a running sprint into the notifications the OS must hold for it.
///
/// Why this exists at all: checkpoints used to raise only an in-app banner and bump the Live
/// Activity's count. Both need the app alive — so on a locked phone, which is exactly when an ADHD
/// nudge matters, a sprint configured for ten nudges delivered none. The app cannot post a
/// notification at the moment it is due (it is suspended); it must hand the whole schedule over up
/// front, and withdraw it whenever the schedule stops being true.
///
/// Pure and total: every rule below is unit-tested without a notification centre.
enum FocusNotificationPlanning {
    static func plan(session: FocusSession?, deadline: Date?, now: Date) -> [ScheduledFocusNotification] {
        // No sprint, paused (no live deadline), or already finished → nothing may be pending.
        guard let session, let deadline, !session.isPaused, !session.isComplete else { return [] }

        let total = session.nudgeCheckpoints.count
        var notifications: [ScheduledFocusNotification] = session.nudgeCheckpoints.enumerated()
            .filter { index, mark in
                // Already heard, or already behind the playhead: scheduling either would fire a
                // nudge for a moment that has gone. The engine's own wall-clock resync reports a
                // missed crossing instead.
                !session.triggeredCheckpointIndices.contains(index) && mark > session.elapsedSeconds
            }
            .map { index, mark in
                ScheduledFocusNotification(
                    kind: .checkpoint(index: index),
                    fireDate: now.addingTimeInterval(TimeInterval(mark - session.elapsedSeconds)),
                    title: "Checkpoint \(index + 1) of \(total) · \(session.taskTitle)",
                    body: FocusSession.checkpointPrompt(index: index, total: total)
                )
            }

        notifications.append(
            ScheduledFocusNotification(
                kind: .sprintComplete,
                fireDate: deadline,
                title: "\(session.lifeAreaEmoji) Sprint complete",
                // The copy names the tap deliberately. This notification is not decoration — it is
                // the only route that clears a Live Activity iOS won't let a suspended app dismiss
                // on time, so the user has to know the tap does something (see
                // `FocusNotificationResponse`).
                body: "\(FocusTimeFormatting.human(seconds: session.durationSeconds)) on "
                    + "\(session.taskTitle). Tap to log it and clear the Lock Screen."
            )
        )
        return notifications
    }
}

/// Seam over the notification centre for focus sprints — the same `*Adapting` convention as
/// `TaskCountdownNudgeSchedulingAdapting` and `NudgeNotificationSchedulingAdapting`, so the engine
/// is testable with a fake and the three features stay in separate identifier namespaces.
protocol FocusNotificationScheduling: Sendable {
    /// Asked once per sprint start. A sprint IS the moment an ADHD user meets nudges, so it is the
    /// honest place to request permission — the app previously only ever asked if the user happened
    /// to open a task's countdown-nudge control, which most never do.
    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool
    /// Replaces every pending focus-sprint notification with exactly `notifications` (an empty
    /// array withdraws them all).
    func replaceScheduled(with notifications: [ScheduledFocusNotification]) async
}

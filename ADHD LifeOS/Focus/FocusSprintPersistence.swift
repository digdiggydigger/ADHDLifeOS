//
//  FocusSprintPersistence.swift
//  ADHD LifeOS
//

import Foundation

/// A running sprint, flattened for storage (F-SprintPersistence, E's on-device report
/// 2026-08-24: killing the app lost the in-app sprint while the Live Activity kept counting).
/// The engine is deadline-derived, so this is everything a relaunch needs: identity, plan, and
/// the clock anchors — either a live `deadline` or the frozen `pausedRemainingSeconds`, never
/// both. Cadence rides along as its two raw shapes rather than a custom-Codable enum.
struct PersistedFocusSprint: Codable, Equatable {
    var taskId: UUID?
    var taskTitle: String
    var lifeAreaEmoji: String
    var durationSeconds: Int
    var nudgeCheckpoints: [Int]
    var triggeredCheckpointIndices: [Int]
    var startedAt: Date
    /// The countdown's wall-clock end; `nil` while paused.
    var deadline: Date?
    /// The frozen remainder while paused; `nil` while running.
    var pausedRemainingSeconds: Int?
    var cadenceCount: Int?
    var cadenceIntervalSeconds: Int?

    var cadence: FocusNudgeCadence {
        if let cadenceIntervalSeconds { return .interval(seconds: cadenceIntervalSeconds) }
        return .count(cadenceCount ?? 1)
    }

    init(
        taskId: UUID?,
        taskTitle: String,
        lifeAreaEmoji: String,
        durationSeconds: Int,
        nudgeCheckpoints: [Int],
        triggeredCheckpointIndices: [Int],
        startedAt: Date,
        deadline: Date?,
        pausedRemainingSeconds: Int?,
        cadenceCount: Int?,
        cadenceIntervalSeconds: Int?
    ) {
        self.taskId = taskId
        self.taskTitle = taskTitle
        self.lifeAreaEmoji = lifeAreaEmoji
        self.durationSeconds = durationSeconds
        self.nudgeCheckpoints = nudgeCheckpoints
        self.triggeredCheckpointIndices = triggeredCheckpointIndices
        self.startedAt = startedAt
        self.deadline = deadline
        self.pausedRemainingSeconds = pausedRemainingSeconds
        self.cadenceCount = cadenceCount
        self.cadenceIntervalSeconds = cadenceIntervalSeconds
    }

    init(session: FocusSession, startedAt: Date, deadline: Date?, cadence: FocusNudgeCadence) {
        let (count, interval): (Int?, Int?)
        switch cadence {
        case .count(let value): (count, interval) = (value, nil)
        case .interval(let seconds): (count, interval) = (nil, seconds)
        }
        self.init(
            taskId: session.taskId,
            taskTitle: session.taskTitle,
            lifeAreaEmoji: session.lifeAreaEmoji,
            durationSeconds: session.durationSeconds,
            nudgeCheckpoints: session.nudgeCheckpoints,
            triggeredCheckpointIndices: session.triggeredCheckpointIndices.sorted(),
            startedAt: startedAt,
            deadline: session.isPaused ? nil : deadline,
            pausedRemainingSeconds: session.isPaused ? session.remainingSeconds : nil,
            cadenceCount: count,
            cadenceIntervalSeconds: interval
        )
    }
}

/// Seam over the sprint's local persistence — same convention as `FocusSessionLogging`, so the
/// service is testable with a recording fake and the storage medium stays swappable.
protocol FocusSprintPersisting: AnyObject {
    func read() -> PersistedFocusSprint?
    func write(_ state: PersistedFocusSprint)
    func clear()
}

/// The live store: one JSON blob in UserDefaults. Local-only device state — a sprint is not
/// backend data until it completes and logs to history, so Firestore is deliberately not
/// involved (the redesign's "views and local state only" line holds).
final class UserDefaultsFocusSprintStore: FocusSprintPersisting {
    static let key = "focus.sprint.running"

    private let defaults: UserDefaults?

    init(defaults: UserDefaults? = .standard) {
        self.defaults = defaults
    }

    func read() -> PersistedFocusSprint? {
        guard
            let data = defaults?.data(forKey: Self.key),
            let state = try? JSONDecoder().decode(PersistedFocusSprint.self, from: data)
        else { return nil }
        return state
    }

    func write(_ state: PersistedFocusSprint) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults?.set(data, forKey: Self.key)
    }

    func clear() {
        defaults?.removeObject(forKey: Self.key)
    }
}

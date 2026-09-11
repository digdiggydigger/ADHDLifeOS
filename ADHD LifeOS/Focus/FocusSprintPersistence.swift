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

/// Seam over the sprint's local, per-device persistence — same convention as
/// `FocusSessionLogging`, so the service is testable with a recording fake and the storage medium
/// stays swappable.
///
/// **Four concerns under four keys, widened three times since it was one.** The RUNNING sprint
/// (F-SprintPersistence); the app-was-dead completion held until acknowledged (E, 2026-08-25);
/// the running card's collapse posture (F-FocusCard-1); and the stack of naturally-finished
/// sprints waiting on Confirm (F-FocusCard-2). Every widening broke both recording fakes' compile
/// on purpose — that break is the red step, and a protocol-extension default would silence it.
///
/// **What is deliberately NOT here:** F-FocusCard-4's in-memory cue for which card just finished.
/// It must not survive a relaunch, or a sprint that ended hours ago would burst again on every
/// launch; `testTheStampIsNeverPersisted` holds that.
protocol FocusSprintPersisting: AnyObject {
    func read() -> PersistedFocusSprint?
    func write(_ state: PersistedFocusSprint)
    func clear()
    /// A sprint that finished while the process was dead, held until the user has SEEN it —
    /// the confirmation card survives further relaunches until acknowledged (E's review note,
    /// 2026-08-25: progress must never complete invisibly).
    func readUnacknowledgedCompletion() -> CompletedFocusSession?
    func writeUnacknowledgedCompletion(_ record: CompletedFocusSession)
    func clearUnacknowledgedCompletion()
    /// Whether the running sprint's card is collapsed (F-FocusCard-1).
    func readCardCollapsed() -> Bool
    func writeCardCollapsed(_ isCollapsed: Bool)
    /// Sprints that finished naturally and are waiting on the user's Confirm (F-FocusCard-2),
    /// newest first. **A separate key from `readUnacknowledgedCompletion` above, never a
    /// migration between the two**: that one belongs to the app-was-dead flow, which has its own
    /// card in its own visual language. Two keys, two published properties, two cards, zero
    /// interaction — `testTheNewKeyNeverTouchesTheOldOne` asserts both directions.
    func readUnconfirmedCompletions() -> [CompletedFocusSession]
    func writeUnconfirmedCompletions(_ records: [CompletedFocusSession])
}

/// The live store: one JSON blob in UserDefaults. Local-only device state — a sprint is not
/// backend data until it completes and logs to history, so Firestore is deliberately not
/// involved (the redesign's "views and local state only" line holds).
final class UserDefaultsFocusSprintStore: FocusSprintPersisting {
    static let key = "focus.sprint.running"
    static let completionKey = "focus.sprint.unacknowledgedCompletion"
    static let cardCollapsedKey = "focus.card.collapsed"
    static let unconfirmedCompletionsKey = "focus.sprint.unconfirmedCompletions"

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

    func readUnacknowledgedCompletion() -> CompletedFocusSession? {
        guard
            let data = defaults?.data(forKey: Self.completionKey),
            let record = try? JSONDecoder().decode(CompletedFocusSession.self, from: data)
        else { return nil }
        return record
    }

    func writeUnacknowledgedCompletion(_ record: CompletedFocusSession) {
        guard let data = try? JSONEncoder().encode(record) else { return }
        defaults?.set(data, forKey: Self.completionKey)
    }

    func clearUnacknowledgedCompletion() {
        defaults?.removeObject(forKey: Self.completionKey)
    }

    func readCardCollapsed() -> Bool {
        defaults?.bool(forKey: Self.cardCollapsedKey) ?? false
    }

    func writeCardCollapsed(_ isCollapsed: Bool) {
        defaults?.set(isCollapsed, forKey: Self.cardCollapsedKey)
    }

    /// An empty stack rather than `nil` on a decode failure, deliberately: the caller renders a
    /// list, and "nothing waiting" is the honest reading of a blob that cannot be read back.
    func readUnconfirmedCompletions() -> [CompletedFocusSession] {
        guard
            let data = defaults?.data(forKey: Self.unconfirmedCompletionsKey),
            let records = try? JSONDecoder().decode([CompletedFocusSession].self, from: data)
        else { return [] }
        return records
    }

    /// The whole stack is rewritten on every push and every confirm — it is at most a handful of
    /// small records, and one blob keeps the persisted order identical to the published one
    /// rather than reconstructing it from a set of keys.
    func writeUnconfirmedCompletions(_ records: [CompletedFocusSession]) {
        guard let data = try? JSONEncoder().encode(records) else { return }
        defaults?.set(data, forKey: Self.unconfirmedCompletionsKey)
    }
}

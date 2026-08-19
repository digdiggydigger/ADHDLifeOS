//
//  FocusSessionService.swift
//  ADHD LifeOS
//

import Combine
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

/// Owns the running focus sprint for the whole app — one instance, held by `RootView`, so the
/// bar survives tab switches (the web kept it in `useLifeOSState` for the same reason).
///
/// The countdown is **wall-clock derived, not tick-accumulated**: while running, the service
/// stores a `deadline` and every tick recomputes `remainingSeconds` from `now`. A late, coalesced
/// or suspended timer therefore can't drift — the same guarantee the web's high-accuracy tick
/// engine claimed, but without accumulating error.
@MainActor
final class FocusSessionService: ObservableObject {
    @Published private(set) var session: FocusSession?
    /// Coaching copy for the checkpoint just crossed; the bar shows it briefly.
    @Published private(set) var checkpointBanner: String?
    /// Set when persisting a finished sprint fails — the sprint itself still ended cleanly.
    @Published var logErrorMessage: String?
    /// Bumped once per ENDED sprint (manual stop or natural completion, regardless of whether
    /// the history write landed). Home threads it into `FocusAnalyticsSection` as a reload
    /// token, so the analytics refresh right after a sprint instead of on the next cold launch.
    @Published private(set) var completedSprintCount = 0

    private let logger: FocusSessionLogging?
    /// Mirrors sprint lifecycle events into the Lock Screen / Dynamic Island Live Activity.
    /// Optional because ActivityKit is iOS 16.1+ against the 16.0 floor (§7) — and so tests can
    /// substitute a fake.
    private let activityMirror: FocusActivityMirroring?
    private let now: () -> Date
    private var deadline: Date?
    private var startedAt: Date?
    private var ticker: Task<Void, Never>?

    var isActive: Bool { session != nil }

    init(
        logger: FocusSessionLogging? = nil,
        activityMirror: FocusActivityMirroring? = nil,
        now: @escaping () -> Date = Date.init
    ) {
        self.logger = logger
        self.activityMirror = activityMirror
        self.now = now
    }

    // No `deinit` cancelling `ticker`: the module compiles with default-MainActor isolation, so a
    // nonisolated `deinit` can't touch actor-isolated state. The ticker is cancelled on every
    // pause/stop path, and the service lives for the app's lifetime (owned by `RootView`).

    // MARK: - Controls

    /// Starts a sprint, replacing any in flight (the replaced one is logged as stopped-early, so
    /// history never silently loses a session).
    func start(
        taskId: UUID?,
        taskTitle: String,
        lifeAreaEmoji: String,
        durationSeconds: Int,
        cadence: FocusNudgeCadence = .count(1)
    ) {
        // Retire any sprint in flight SYNCHRONOUSLY, before the new session is installed. The
        // previous deferred `Task { await stop() }` ran after this method body, so it tore down
        // the replacement and logged IT (at ~0s) instead of the sprint being displaced.
        if let replaced = finishCurrentSprint(completedNaturally: false) {
            Task { await log(replaced) }
        }
        let duration = max(FocusCheckpoints.minimumIntervalSeconds, durationSeconds)
        let started = FocusSession(
            taskId: taskId,
            taskTitle: taskTitle,
            lifeAreaEmoji: lifeAreaEmoji.isEmpty ? "🎯" : lifeAreaEmoji,
            durationSeconds: duration,
            nudgeCheckpoints: cadence.checkpoints(forDurationSeconds: duration)
        )
        session = started
        startedAt = now()
        deadline = now().addingTimeInterval(TimeInterval(duration))
        checkpointBanner = nil
        startTicking()
        activityMirror?.sprintStarted(activitySnapshot(for: started))
    }

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

    func togglePause() {
        guard var current = session else { return }
        if current.isPaused {
            current.isPaused = false
            deadline = now().addingTimeInterval(TimeInterval(current.remainingSeconds))
            session = current
            startTicking()
        } else {
            current.isPaused = true
            session = current
            deadline = nil
            ticker?.cancel()
            ticker = nil
        }
        activityMirror?.sprintUpdated(activitySnapshot(for: current))
    }

    /// Extends a running sprint (+30s / +5m in the bar). Adds to both the remaining time and the
    /// total, so the progress fill stays truthful rather than jumping backwards.
    func addSeconds(_ seconds: Int) {
        guard var current = session, seconds > 0 else { return }
        current.durationSeconds += seconds
        current.remainingSeconds += seconds
        session = current
        if !current.isPaused {
            deadline = now().addingTimeInterval(TimeInterval(current.remainingSeconds))
        }
        activityMirror?.sprintUpdated(activitySnapshot(for: current))
    }

    /// Ends the sprint and persists it. `completedNaturally` distinguishes a countdown that ran
    /// out from a manual stop, which the analytics views report separately.
    func stop(completedNaturally: Bool = false) async {
        guard let record = finishCurrentSprint(completedNaturally: completedNaturally) else { return }
        await log(record)
    }

    /// The synchronous teardown shared by `stop` and the replacement path in `start`: cancels the
    /// ticker, clears all sprint state, ends the Live Activity, and returns the history record
    /// for the caller to persist (awaited in `stop`, fire-and-forget on replacement).
    private func finishCurrentSprint(completedNaturally: Bool) -> CompletedFocusSession? {
        ticker?.cancel()
        ticker = nil
        deadline = nil
        guard let finished = session, let began = startedAt else { return nil }
        session = nil
        startedAt = nil
        checkpointBanner = nil

        completedSprintCount += 1
        activityMirror?.sprintEnded(completedNaturally: completedNaturally)

        return CompletedFocusSession(
            id: UUID(),
            taskId: finished.taskId,
            taskTitle: finished.taskTitle,
            lifeAreaEmoji: finished.lifeAreaEmoji,
            plannedSeconds: finished.durationSeconds,
            focusedSeconds: finished.elapsedSeconds,
            checkpointsReached: finished.triggeredCheckpointIndices.count,
            completedNaturally: completedNaturally,
            startedAt: began,
            endedAt: now()
        )
    }

    private func log(_ record: CompletedFocusSession) async {
        do {
            try await logger?.logCompletedSession(record)
        } catch {
            logErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func activitySnapshot(for session: FocusSession) -> FocusActivitySnapshot {
        FocusActivitySnapshot(
            taskTitle: session.taskTitle,
            lifeAreaEmoji: session.lifeAreaEmoji,
            durationSeconds: session.durationSeconds,
            deadline: session.isPaused ? nil : deadline,
            pausedRemainingSeconds: session.isPaused ? session.remainingSeconds : nil,
            checkpointCount: session.nudgeCheckpoints.count,
            checkpointsReached: session.triggeredCheckpointIndices.count
        )
    }

    // MARK: - Ticking

    private func startTicking() {
        ticker?.cancel()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000)
                guard let self else { return }
                if Task.isCancelled { return }
                await self.tick()
            }
        }
    }

    /// One countdown step. Internal rather than private so tests can drive it directly with an
    /// injected clock instead of waiting on real time.
    func tick() async {
        guard var current = session, !current.isPaused, let deadline else { return }
        let remaining = Int(deadline.timeIntervalSince(now()).rounded(.up))
        let crossed = current.advance(toRemaining: remaining)
        session = current
        if let last = crossed.last {
            checkpointBanner = FocusSession.checkpointPrompt(
                index: last, total: current.nudgeCheckpoints.count
            )
        }
        if current.isComplete {
            await stop(completedNaturally: true)
        } else if !crossed.isEmpty {
            // A checkpoint crossing is the one mid-sprint event the Activity shows (the reached
            // count); plain ticks never touch it — the OS renders the countdown itself.
            activityMirror?.sprintUpdated(activitySnapshot(for: current))
        }
    }
}

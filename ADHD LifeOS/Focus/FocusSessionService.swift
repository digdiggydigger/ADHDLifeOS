//
//  FocusSessionService.swift
//  ADHD LifeOS
//

import Combine
import Foundation

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
    /// The cadence the running sprint was last planned with — `start`'s argument until the modal's
    /// live editor replaces it. Published so the editor seeds from what is actually scheduled
    /// rather than from a guess reverse-engineered out of the checkpoint marks.
    @Published private(set) var cadence: FocusNudgeCadence = .count(1)

    private let logger: FocusSessionLogging?
    /// Local persistence for the RUNNING sprint (F-SprintPersistence) — written on every
    /// plan/clock mutation and on checkpoint crossings, cleared when the sprint ends, read back
    /// once by `restorePersistedSprint()` after a process death.
    private let sprintStore: FocusSprintPersisting?
    /// Mirrors sprint lifecycle events into the Lock Screen / Dynamic Island Live Activity.
    /// Optional because ActivityKit is iOS 16.1+ against the 16.0 floor (§7) — and so tests can
    /// substitute a fake.
    private let activityMirror: FocusActivityMirroring?
    /// Hands the sprint's checkpoint + completion notifications to the OS. Distinct from the
    /// Activity mirror: the OS re-renders an Activity from a deadline on its own, but a
    /// notification must be scheduled ahead of time — the app is suspended when one comes due.
    private let notificationScheduler: FocusNotificationScheduling?
    private let now: () -> Date
    private var deadline: Date?
    private var startedAt: Date?
    private var ticker: Task<Void, Never>?
    /// The in-flight notification write. Retained so successive mutations serialise (a pause
    /// landing before the resume that followed it would leave the OS holding a stale schedule)
    /// and so tests can await it.
    private var notificationTask: Task<Void, Never>?

    var isActive: Bool { session != nil }

    init(
        logger: FocusSessionLogging? = nil,
        activityMirror: FocusActivityMirroring? = nil,
        notificationScheduler: FocusNotificationScheduling? = nil,
        sprintStore: FocusSprintPersisting? = nil,
        now: @escaping () -> Date = Date.init
    ) {
        self.logger = logger
        self.activityMirror = activityMirror
        self.notificationScheduler = notificationScheduler
        self.sprintStore = sprintStore
        self.now = now
    }

    /// Awaits any in-flight notification write. Used by tests, and by the Lock Screen intents so a
    /// pause/resume's schedule change lands before the OS re-suspends the app.
    func pendingNotificationWork() async {
        await notificationTask?.value
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
        syncToWallClock()
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
        self.cadence = cadence
        startedAt = now()
        deadline = now().addingTimeInterval(TimeInterval(duration))
        checkpointBanner = nil
        startTicking()
        activityMirror?.sprintStarted(activitySnapshot(for: started))
        rescheduleNotifications(requestingAuthorization: true)
        persistCurrentSprint()
    }

    func togglePause() {
        syncToWallClock()
        guard var current = session else { return }
        if !current.isPaused, current.isComplete {
            // The countdown ran out while the app was suspended (a Lock Screen pause arriving
            // late): complete the sprint rather than freezing a finished one at 00:00.
            Task { await stop(completedNaturally: true) }
            return
        }
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
        rescheduleNotifications()
        persistCurrentSprint()
    }

    /// Extends a running sprint (+30s / +5m in the bar). Adds to both the remaining time and the
    /// total, so the progress fill stays truthful rather than jumping backwards.
    func addSeconds(_ seconds: Int) {
        syncToWallClock()
        guard var current = session, seconds > 0 else { return }
        current.durationSeconds += seconds
        current.remainingSeconds += seconds
        session = current
        if !current.isPaused {
            deadline = now().addingTimeInterval(TimeInterval(current.remainingSeconds))
        }
        activityMirror?.sprintUpdated(activitySnapshot(for: current))
        rescheduleNotifications()
        persistCurrentSprint()
    }

    /// Re-plans the running sprint's nudge cadence mid-flight — the modal's live cadence editor.
    ///
    /// Checkpoints are computed once at `start` and deliberately never re-spaced by `addSeconds`,
    /// because moving a mark the user already passed would re-fire it. This is the one sanctioned
    /// way to change the plan: `FocusSession.replanCheckpoints(to:)` preserves every fired mark and
    /// only re-spaces what is still ahead. The countdown, the deadline and the paused state are all
    /// untouched — only the nudge schedule moves.
    ///
    /// A cadence change moves `checkpointCount`, which the Live Activity displays, so it is a
    /// legitimate `sprintUpdated` event (plain ticks still never are — the OS renders the countdown
    /// itself).
    func updateCadence(_ cadence: FocusNudgeCadence) {
        syncToWallClock()
        guard var current = session else { return }
        self.cadence = cadence
        current.replanCheckpoints(to: cadence)
        session = current
        activityMirror?.sprintUpdated(activitySnapshot(for: current))
        rescheduleNotifications()
        persistCurrentSprint()
    }

    /// Ends the sprint and persists it. `completedNaturally` distinguishes a countdown that ran
    /// out from a manual stop, which the analytics views report separately.
    func stop(completedNaturally: Bool = false) async {
        syncToWallClock()
        // A manual stop that arrives after the deadline already passed (Lock Screen button on a
        // suspended app) is a countdown that genuinely ran out — record it as such.
        let ranOut = session.map { !$0.isPaused && $0.isComplete } ?? false
        guard let record = finishCurrentSprint(completedNaturally: completedNaturally || ranOut) else { return }
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
        // `session` is already nil, so the plan comes out empty: every pending checkpoint and the
        // completion notice are withdrawn. A finished sprint must never nudge.
        rescheduleNotifications()
        sprintStore?.clear()

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

    /// Re-derives the sprint's whole notification schedule and hands it to the OS, replacing
    /// whatever was pending. Called from every mutation that can change WHEN a nudge is due —
    /// start, pause, resume, extend, re-plan, end — and deliberately NOT from plain ticks: the OS
    /// already holds the schedule, so re-handing it twice a second would be pure churn.
    ///
    /// Fire-and-forget, because the engine's mutations are synchronous and must stay that way; the
    /// writes are chained so they can never land out of order.
    private func rescheduleNotifications(requestingAuthorization: Bool = false) {
        guard let notificationScheduler else { return }
        let plan = FocusNotificationPlanning.plan(session: session, deadline: deadline, now: now())
        let previous = notificationTask
        notificationTask = Task {
            await previous?.value
            if requestingAuthorization {
                await notificationScheduler.requestAuthorizationIfNeeded()
            }
            await notificationScheduler.replaceScheduled(with: plan)
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
            checkpointsReached: session.triggeredCheckpointIndices.count,
            checkpointSeconds: session.nudgeCheckpoints
        )
    }

    /// The running sprint's countdown deadline; `nil` while paused or idle.
    ///
    /// Exposed read-only so the Home Screen widget's projection (`widgetSprint`) can be built
    /// outside the engine without the engine growing a second presentation concern. The deadline is
    /// deliberately what leaves this type rather than `remainingSeconds`: it is stable while a
    /// sprint merely counts down, which is what lets Home republish on change without churn.
    var sprintDeadline: Date? { deadline }

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

    /// Settles the sprint against the wall clock right now — completing it if its countdown ran out
    /// while the app was suspended.
    ///
    /// Called when the app returns to the foreground. Without it, a sprint that finished behind a
    /// locked screen stayed "running" until the ticker's next beat, which is what left a finished
    /// sprint's Live Activity on the Lock Screen showing 0:00, a stale checkpoint count and live
    /// Pause/Stop buttons (E, 2026-08-20). The ticker would eventually do this; waiting for it is
    /// the difference between the Activity vanishing as you unlock and lingering visibly.
    func syncNow() {
        let crossed = syncToWallClock()
        guard let current = session, !current.isPaused else { return }
        if let last = crossed.last {
            checkpointBanner = FocusSession.checkpointPrompt(
                index: last, total: current.nudgeCheckpoints.count
            )
        }
        if current.isComplete {
            Task { await stop(completedNaturally: true) }
        } else if !crossed.isEmpty {
            activityMirror?.sprintUpdated(activitySnapshot(for: current))
            persistCurrentSprint()
        }
    }

    /// One countdown step. Internal rather than private so tests can drive it directly with an
    /// injected clock instead of waiting on real time.
    func tick() async {
        let crossed = syncToWallClock()
        guard let current = session, !current.isPaused else { return }
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
            persistCurrentSprint()
        }
    }

    /// Re-derives the countdown from the deadline, returning any checkpoints the move crossed.
    /// The ticker does this every 500ms while the app is live, but Lock Screen intents run in an
    /// app process that may have been suspended for minutes — every mutation resyncs first so it
    /// never acts on a stale `remainingSeconds`.
    @discardableResult
    private func syncToWallClock() -> [Int] {
        guard var current = session, !current.isPaused, let deadline else { return [] }
        let remaining = Int(deadline.timeIntervalSince(now()).rounded(.up))
        let crossed = current.advance(toRemaining: remaining)
        session = current
        return crossed
    }
}

// MARK: - Sprint persistence (F-SprintPersistence)

extension FocusSessionService {
    /// Reinstates a sprint the process died holding, if the store has one. Running sprints
    /// recompute their countdown from the saved deadline — checkpoints crossed while dead are
    /// marked fired WITHOUT nudging — a paused sprint comes back frozen, and one whose deadline
    /// passed completes properly: logged whole, Activity ended, store cleared. Called once by
    /// `RootView` when the signed-in UI appears.
    func restorePersistedSprint() async {
        guard let sprintStore, session == nil, let saved = sprintStore.read() else { return }
        cadence = saved.cadence
        startedAt = saved.startedAt
        var restored = FocusSession(
            taskId: saved.taskId,
            taskTitle: saved.taskTitle,
            lifeAreaEmoji: saved.lifeAreaEmoji,
            durationSeconds: saved.durationSeconds,
            remainingSeconds: saved.pausedRemainingSeconds ?? saved.durationSeconds,
            isPaused: saved.deadline == nil,
            nudgeCheckpoints: saved.nudgeCheckpoints,
            triggeredCheckpointIndices: Set(saved.triggeredCheckpointIndices)
        )
        if let savedDeadline = saved.deadline {
            let remaining = Int(savedDeadline.timeIntervalSince(now()).rounded(.up))
            _ = restored.advance(toRemaining: remaining)
            session = restored
            deadline = savedDeadline
            if restored.isComplete {
                await stop(completedNaturally: true)
                return
            }
            startTicking()
        } else {
            session = restored
        }
        activityMirror?.sprintRestored(activitySnapshot(for: restored))
        rescheduleNotifications()
        persistCurrentSprint()
    }

    /// Snapshots the running sprint into the store — or clears it if none is running.
    private func persistCurrentSprint() {
        guard let sprintStore else { return }
        guard let session, let startedAt else {
            sprintStore.clear()
            return
        }
        sprintStore.write(
            PersistedFocusSprint(session: session, startedAt: startedAt, deadline: deadline, cadence: cadence)
        )
    }
}

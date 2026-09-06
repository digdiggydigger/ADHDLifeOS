//
//  RoutineActivation.swift
//  ADHD LifeOS
//
//  What a tap on a routine notification DOES (Block A — E's deferred-logging spec, 2026-09-04).
//
//  Before this, a crossing wrote the run and the notification merely REPORTED what had already
//  happened; the tap only had to resolve a UUID against the store. E's rule inverts that: the
//  crossing writes nothing, so the tap is where the routine comes into existence — and with
//  nothing written there is nothing for a bare UUID to resolve against. The notification
//  therefore carries the whole frozen run, and this file is the decision about what to do with
//  it, kept pure and separated from the doing.
//

import Foundation

/// The pure half: given what the tap carries and what the store holds, what should happen?
enum RoutineActivation {
    enum Decision: Equatable {
        /// The routine does not exist yet — create it, run its auto steps, open it.
        case start(RoutineRun)
        /// It already exists (a second tap, or a banner from before deferred logging shipped).
        /// Open it; creating it again would write the journal line twice.
        case open(UUID)
        /// Nothing worth opening — the door resolves this to Today, never a blank screen.
        case stale
    }

    /// `carriedKey` is the bare run UUID that has ridden the tap since F-Routines-2. It is the
    /// back-compat path and it earns its keep: a banner delivered by the PREVIOUS build carries
    /// only that key, and its run IS in the store, so an app update must not strand it.
    static func decide(
        payload: RoutineRun?,
        carriedKey: UUID?,
        stored: RoutineRun?,
        now: Date,
        calendar: Calendar = .current
    ) -> Decision {
        guard let payload else {
            guard let carriedKey else { return .stale }
            return .open(carriedKey)
        }
        // Newest-wins is the store's rule, not this one: if THIS run is already the stored run,
        // the routine is underway and the tap is a way back in.
        if stored?.id == payload.id { return .open(payload.id) }
        // The lifetime rules the store applies on read, applied here to a run that was never
        // stored: yesterday's banner, or a departure banner past its window, opens Today.
        guard RoutineRunLifecycle.isLive(payload, now: now, calendar: calendar) else {
            return .stale
        }
        return .start(payload)
    }
}

/// The seam the router talks to, so the routing rules (pending, replay-once, prefix greed) stay
/// testable without a tap creating anything.
@MainActor
protocol RoutineActivating {
    /// Returns the run key the door should open, or `nil` for Today.
    func activate(userInfo: [AnyHashable: Any], now: Date) -> UUID?
}

/// The doing half.
///
/// Deliberately part-synchronous. The run is written to the store BEFORE this returns, because
/// the router hands the key straight to the door and the door resolves it against the store —
/// an async write would race a blank routine screen. The Firestore auto-step writes are slow
/// and nothing on screen waits for them, so they ride a `Task` and announce themselves through
/// the write plumbing's own `DataChangeSignal` when they land.
///
/// A class rather than a struct for one reason, and it is a test-quality reason worth stating:
/// that `Task` is held, so a test can AWAIT it. The first version left it detached and the
/// tests counted `Task.yield()`s to drain it — three passed in one test and failed in another,
/// which is the definition of a flaky harness rather than a passing one.
@MainActor
final class PlaceRoutineActivator: RoutineActivating {
    private let runStore: RoutineRunStoring
    private let snapshotStore: ArrivalNudgeStateStoring
    private let executor: PlaceAutoRunExecutor
    private let calendar: Calendar
    /// The routine RECORD's seam (F-RoutineRecord-1): the tap is where a run STARTS, and where
    /// a run it replaces is ENDED — recorded in that order.
    private let recorder: RoutineRunRecording

    /// The in-flight auto-step writes. Nothing in the app waits on this — the screen is already
    /// up and the writes announce themselves — but a test can, and must.
    private(set) var autoRunTask: Task<Void, Never>?
    /// The in-flight record writes, held for the same reason.
    private(set) var recordTask: Task<Void, Never>?

    init(
        runStore: RoutineRunStoring = UserDefaultsRoutineRunStore(),
        snapshotStore: ArrivalNudgeStateStoring = UserDefaultsArrivalNudgeStateStore(),
        executor: PlaceAutoRunExecutor = .live(),
        calendar: Calendar = .current,
        recorder: RoutineRunRecording? = nil
    ) {
        self.runStore = runStore
        self.snapshotStore = snapshotStore
        self.executor = executor
        self.calendar = calendar
        self.recorder = recorder ?? FirebaseRoutineRunRecorder()
    }

    func activate(userInfo: [AnyHashable: Any], now: Date) -> UUID? {
        let stored = runStore.readLiveRun(now: now)
        let decision = RoutineActivation.decide(
            payload: PlaceRoutineNotificationContent.run(fromUserInfo: userInfo),
            carriedKey: PlaceRoutineNotificationContent.runKey(fromUserInfo: userInfo),
            stored: stored,
            now: now,
            calendar: calendar
        )
        switch decision {
        case .open(let runKey):
            return runKey
        case .stale:
            return nil
        case .start(var run):
            // The TAP's moment, distinct from `startedAt` (the crossing's): the screen measures
            // time spent from here, and the record stamps `started_at` with it.
            run.activatedAt = now
            start(run, replacing: stored?.id, now: now)
            return run.id
        }
    }

    private func start(_ run: RoutineRun, replacing replaced: UUID?, now: Date) {
        runStore.write(run)
        // Today's card is a PULL surface and this is the only push it gets — a routine of
        // tap-steps writes nothing to Firestore, so without this the card would not appear
        // until the user navigated away and back.
        DataChangeSignal.post()
        recordStart(of: run.id, replacing: replaced, now: now)

        let entry = snapshotStore.readSnapshot()?.entries.first { $0.placeId == run.placeId }
        let stamp = PlaceAutoRunStamp.make(entry: entry, placeId: run.placeId)
        let autoActions = run.steps.filter { $0.state == .autoDone }.map(\.action)
        guard !autoActions.isEmpty else { return }
        let executor = self.executor
        autoRunTask = Task {
            for action in autoActions {
                _ = await executor.run(action, stamp: stamp)
            }
        }
    }

    /// Site 2 (and the `replaced` half of site 5) of the routine record. Newest-wins is the
    /// store's rule; the record says what it cost: the run this tap wrote over is ended as
    /// `replaced` BEFORE the new one is started. Best-effort — the routine is already real in
    /// the store, and a lost write must never take the screen with it.
    private func recordStart(of runId: UUID, replacing replaced: UUID?, now: Date) {
        let recorder = self.recorder
        recordTask = Task {
            if let replaced, replaced != runId {
                try? await recorder.ended(runId: replaced, reason: .replaced, at: now)
            }
            try? await recorder.started(runId: runId, at: now)
        }
    }
}

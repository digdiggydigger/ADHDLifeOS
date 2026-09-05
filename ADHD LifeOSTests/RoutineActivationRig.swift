//
//  RoutineActivationRig.swift
//  ADHD LifeOSTests
//
//  The shared rig for the TAP half of deferred logging (Block A) — the mirror of
//  `RoutineHandlerHarness`, which rigs the CROSSING half. Split out for the same reason: two
//  test classes drive this, and both would otherwise carry the fakes.
//
//  `settle()` exists because activation is deliberately part-synchronous: the run must be in
//  the store before `activate` returns (the door resolves the key the moment it is delivered,
//  so an async write would race a blank screen), while the auto-step writes ride a `Task`.
//  It AWAITS that task rather than counting `Task.yield()`s — the yield-counting version passed
//  in a test that called it twice and failed in one that called it once, which is a flaky
//  harness, not a passing one. `PlaceRoutineActivator` holds the task for exactly this.
//

import Foundation
@testable import ADHD_LifeOS

@MainActor
final class ActivationRig {
    let noon = Date(timeIntervalSince1970: 1_756_296_000)
    let gymId = UUID()
    let log = RoutineSequenceLog()
    let runStore: RoutineFakeRunStore
    let snapshotStore = RoutineFakeArrivalStore()
    let writers = RoutineWriterLog()
    let sut: PlaceRoutineActivator

    init() {
        let writers = self.writers
        runStore = RoutineFakeRunStore(log: log)
        snapshotStore.snapshot = AtPlaceSnapshot(entries: [
            AtPlaceSnapshot.PlaceEntry(
                placeId: gymId, displayName: "Gym 🏋️", openTaskTitles: [],
                arrivalMessage: "Time to train", departureMessage: nil,
                actions: [], latitude: 51.5152, longitude: -0.1418
            )
        ])
        sut = PlaceRoutineActivator(
            runStore: runStore,
            snapshotStore: snapshotStore,
            executor: PlaceAutoRunExecutor(
                journalWriter: { input in await Task.yield(); return writers.journal(input) },
                captureWriter: { input in await Task.yield(); return writers.capture(input) }
            )
        )
    }

    // MARK: - Fixtures

    var journalAction: PlaceAction {
        PlaceAction(id: UUID(), direction: .arrival, kind: .journalLine(body: "Leg day"))
    }

    var spotifyAction: PlaceAction {
        PlaceAction(
            id: UUID(), direction: .arrival,
            kind: .openApp(scheme: "spotify", displayName: "Spotify")
        )
    }

    func run(steps: [(PlaceAction, RoutineStepState)]) -> RoutineRun {
        RoutineRun(
            id: UUID(), placeId: gymId, direction: .arrival, startedAt: noon,
            displayName: "Gym 🏋️", customMessage: "Time to train",
            steps: steps.map { RoutineRun.Step(action: $0.0, state: $0.1) }
        )
    }

    func userInfo(for run: RoutineRun) -> [AnyHashable: Any] {
        PlaceRoutineNotificationContent.userInfo(for: run)
    }

    /// Waits for the auto-step writes the tap kicked off. Deterministic: there is nothing to
    /// wait for unless a run was started, and if one was, this returns when its writes are done.
    func settle() async {
        await sut.autoRunTask?.value
    }
}

/// A router activator that records rather than acting, so the routing tests stay hermetic —
/// they are about the pending/replay rules, not about what a tap creates.
@MainActor
final class RecordingRoutineActivator: RoutineActivating {
    var opens: UUID?
    private(set) var activations: [[AnyHashable: Any]] = []

    init(opens: UUID? = nil) { self.opens = opens }

    func activate(userInfo: [AnyHashable: Any], now: Date) -> UUID? {
        activations.append(userInfo)
        // The one rule this fake honours, because every routing test depends on it: a payload
        // carrying a readable run key resolves to that key.
        if let opens { return opens }
        return PlaceRoutineNotificationContent.runKey(fromUserInfo: userInfo)
    }
}

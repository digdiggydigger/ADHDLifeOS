//
//  RoutineRun.swift
//  ADHD LifeOS
//
//  The ONE live routine run (F-Routines-2-Notify). A qualifying crossing mints a run; the
//  routine screen (block 3) reads and mutates it; the Today card (block 4) is its pull
//  surface. UserDefaults-persisted like the snapshot and cooldowns — a routine must survive
//  a background relaunch, and Firestore is deliberately not involved: zero wire changes all
//  arc.
//
//  This record is also the future SENSING SEAM: smart-skip's per-run tapped/skipped data
//  (E's queued direction 3) is exactly what `Step.state` accumulates, so the shape here is
//  the contract that feature will read.
//

import Foundation

/// Where one step of a live run stands. `autoDone` is minted at creation for the kinds the
/// crossing runs itself (the screen shows them pre-ticked, E's settled call #4); `done` and
/// `skipped` are the screen's verbs (block 3); everything else starts `pending`.
enum RoutineStepState: String, Codable, Equatable, Sendable {
    case autoDone
    case pending
    case done
    case skipped
}

/// One crossing's routine, frozen at creation. The step embeds the whole `PlaceAction` — the
/// tap must be runnable on a cold launch from this record alone, and a mid-run edit of the
/// place must not mutate a run already underway: the record tells the truth about what THIS
/// crossing offered.
struct RoutineRun: Codable, Equatable, Sendable, Identifiable {
    struct Step: Codable, Equatable, Sendable {
        let action: PlaceAction
        var state: RoutineStepState
    }

    /// The minted run key. It rides the notification's userInfo AND this record — a tap whose
    /// UUID no longer matches the live run is STALE and opens Today, never a blank screen.
    let id: UUID
    let placeId: UUID
    let direction: PlaceTriggerEvent.Kind
    let startedAt: Date
    /// Frozen from the snapshot entry so the screen renders on a cold launch with no network
    /// and no second store: the place moment ("Gym 🏋️") and E's own words for this crossing.
    let displayName: String
    let customMessage: String?
    var steps: [Step]

    static func make(
        event: PlaceTriggerEvent, entry: AtPlaceSnapshot.PlaceEntry?, plan: PlaceRoutinePlan
    ) -> RoutineRun {
        RoutineRun(
            id: UUID(),
            placeId: event.placeId,
            direction: event.kind,
            startedAt: event.occurredAt,
            displayName: entry?.displayName ?? "",
            customMessage: event.kind == .arrival
                ? entry?.arrivalMessage : entry?.departureMessage,
            steps: plan.steps.map {
                Step(action: $0.action, state: $0.runsAutomatically ? .autoDone : .pending)
            }
        )
    }
}

/// The pure lifecycle rules (E's settled call #3): an ARRIVAL run lives until the same
/// place's departure crossing; a DEPARTURE run lives `RoutineDefaults.departureRunWindow`;
/// every run dies with its own day — the lazy end-of-day sweep, evaluated on READ, so no
/// timer and no background wake exists anywhere in the arc.
enum RoutineRunLifecycle {
    /// Does this crossing END the run? Only the run's own place departing closes an arrival
    /// run. Everything else that removes a run is either expiry (`isLive`) or newest-wins
    /// replacement (a qualifying crossing writing over it).
    static func ends(_ run: RoutineRun, on event: PlaceTriggerEvent) -> Bool {
        run.direction == .arrival && event.kind == .departure && run.placeId == event.placeId
    }

    static func isLive(_ run: RoutineRun, now: Date, calendar: Calendar = .current) -> Bool {
        guard calendar.isDate(now, inSameDayAs: run.startedAt) else { return false }
        if run.direction == .departure {
            return now.timeIntervalSince(run.startedAt) < RoutineDefaults.departureRunWindow
        }
        return true
    }
}

/// One live run, newest wins — `write` replaces whatever was there. Reads apply the lifetime
/// rules lazily and sweep a dead run out, which is the whole end-of-day mechanism.
protocol RoutineRunStoring {
    func readLiveRun(now: Date) -> RoutineRun?
    func write(_ run: RoutineRun)
    func endLiveRun()
    /// Named widening (F-Routines-3): persist the screen's step changes ONLY while this run
    /// is still the stored one. A run can end underneath an open screen (its departure
    /// crossing, the window, the sweep, newest-wins) — a blind write would resurrect it.
    /// Returns whether the update landed.
    func updateMatching(_ run: RoutineRun) -> Bool
    /// Named widening (F-Routines-3): end THIS run, and only this run — the screen's
    /// completion path must never end a newer run that replaced it mid-view.
    func end(runId: UUID)
}

/// App-local UserDefaults, the `UserDefaultsArrivalNudgeStateStore` arrangement: every
/// failure path — unavailable defaults, corrupt data — degrades to "no live run".
struct UserDefaultsRoutineRunStore: RoutineRunStoring {
    static let runKey = "places.routine.liveRun"

    private let defaults: UserDefaults?
    private let calendar: Calendar

    init(defaults: UserDefaults? = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar
    }

    func readLiveRun(now: Date) -> RoutineRun? {
        guard let data = defaults?.data(forKey: Self.runKey),
              let run = try? JSONDecoder().decode(RoutineRun.self, from: data) else { return nil }
        guard RoutineRunLifecycle.isLive(run, now: now, calendar: calendar) else {
            // The lazy end-of-day sweep IS this line — a dead run is cleared by the first
            // read that notices, and nothing in the arc ever needs a timer for it.
            defaults?.removeObject(forKey: Self.runKey)
            return nil
        }
        return run
    }

    func write(_ run: RoutineRun) {
        guard let data = try? JSONEncoder().encode(run) else { return }
        defaults?.set(data, forKey: Self.runKey)
    }

    func endLiveRun() {
        defaults?.removeObject(forKey: Self.runKey)
    }

    func updateMatching(_ run: RoutineRun) -> Bool {
        guard let data = defaults?.data(forKey: Self.runKey),
              let stored = try? JSONDecoder().decode(RoutineRun.self, from: data),
              stored.id == run.id else { return false }
        write(run)
        return true
    }

    func end(runId: UUID) {
        guard let data = defaults?.data(forKey: Self.runKey),
              let stored = try? JSONDecoder().decode(RoutineRun.self, from: data),
              stored.id == runId else { return }
        defaults?.removeObject(forKey: Self.runKey)
    }
}

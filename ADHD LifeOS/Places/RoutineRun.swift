//
//  RoutineRun.swift
//  ADHD LifeOS
//
//  The ONE live routine run (F-Routines-2-Notify). A qualifying crossing mints a run; the
//  routine screen (block 3) reads and mutates it; the Today card (block 4) is its pull
//  surface. UserDefaults-persisted like the snapshot and cooldowns — a routine must survive
//  a background relaunch. Firestore was deliberately not involved all arc; since
//  F-RoutineRecord-1 the durable twin is `RoutineRunRecord` in `routine_runs`, derived from
//  this record at every moment that matters and never the other way round.
//
//  `Step.state` (and now `Step.resolvedAt`) is the SENSING SEAM smart-skip will read — the
//  record carries it to Firestore, so it is no longer thrown away on completion.
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
        /// When the screen last marked this step done or skipped; `nil` while pending, and
        /// cleared again by Undo (F-RoutineRecord-1). Optional so a banner minted by an older
        /// build still decodes.
        var resolvedAt: Date?

        init(action: PlaceAction, state: RoutineStepState, resolvedAt: Date? = nil) {
            self.action = action
            self.state = state
            self.resolvedAt = resolvedAt
        }
    }

    /// The minted run key. It rides the notification's userInfo AND this record — a tap whose
    /// UUID no longer matches the live run is STALE and opens Today, never a blank screen.
    let id: UUID
    let placeId: UUID
    let direction: PlaceTriggerEvent.Kind
    /// The CROSSING's moment — the run is minted at the crossing and rides the banner. The tap
    /// that makes it real is `activatedAt`.
    let startedAt: Date
    /// The TAP (F-RoutineRecord-1): set by the activator when the routine starts existing, so
    /// the screen can say how long the routine has been worked without asking Firestore.
    /// `nil` on the banner and on a run written by an older build.
    var activatedAt: Date?
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

    /// The instant the same rules stop calling a run — or an unopened OFFER — live: the end
    /// of its day, or for a departure its window if that comes first. The routine record's
    /// reconciler stamps a passive ending with THIS moment rather than with whenever somebody
    /// next opened the Journal (F-RoutineRecord-1).
    static func expiry(
        direction: PlaceTriggerEvent.Kind, startedAt: Date, calendar: Calendar = .current
    ) -> Date {
        let dayStart = calendar.startOfDay(for: startedAt)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? startedAt
        guard direction == .departure else { return dayEnd }
        return min(startedAt.addingTimeInterval(RoutineDefaults.departureRunWindow), dayEnd)
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
///
/// Keyed PER USER since F-RoutineRecord-1 (register item B2): app-local defaults outlive a
/// sign-out, and under one shared key one account's place name could surface on another
/// account's Today. The scope is read at CALL time, so the stores built at launch follow the
/// session; signed out, the store reads nothing and drops writes.
struct UserDefaultsRoutineRunStore: RoutineRunStoring {
    /// The one unscoped key every build before F-RoutineRecord-1 wrote — the leak itself. Kept
    /// as the scoped keys' prefix, and so that `clearEveryUser` removes what those builds left.
    static let legacyRunKey = "places.routine.liveRun"

    private let defaults: UserDefaults?
    private let calendar: Calendar
    private let userScope: () -> String?

    init(
        defaults: UserDefaults? = .standard,
        calendar: Calendar = .current,
        userScope: @escaping () -> String? = { FirebaseManager.shared.currentUser?.uid }
    ) {
        self.defaults = defaults
        self.calendar = calendar
        self.userScope = userScope
    }

    /// The scoped key for one user — internal so a test can look at the raw defaults.
    static func runKey(forUser uid: String) -> String {
        "\(legacyRunKey).\(uid)"
    }

    private var runKey: String? {
        userScope().map(Self.runKey(forUser:))
    }

    func readLiveRun(now: Date) -> RoutineRun? {
        guard let key = runKey,
              let data = defaults?.data(forKey: key),
              let run = try? JSONDecoder().decode(RoutineRun.self, from: data) else { return nil }
        guard RoutineRunLifecycle.isLive(run, now: now, calendar: calendar) else {
            // The lazy end-of-day sweep IS this line — a dead run is cleared by the first
            // read that notices, and nothing in the arc ever needs a timer for it.
            defaults?.removeObject(forKey: key)
            return nil
        }
        return run
    }

    func write(_ run: RoutineRun) {
        guard let key = runKey, let data = try? JSONEncoder().encode(run) else { return }
        defaults?.set(data, forKey: key)
    }

    func endLiveRun() {
        guard let key = runKey else { return }
        defaults?.removeObject(forKey: key)
    }

    func updateMatching(_ run: RoutineRun) -> Bool {
        guard let key = runKey,
              let data = defaults?.data(forKey: key),
              let stored = try? JSONDecoder().decode(RoutineRun.self, from: data),
              stored.id == run.id else { return false }
        write(run)
        return true
    }

    func end(runId: UUID) {
        guard let key = runKey,
              let data = defaults?.data(forKey: key),
              let stored = try? JSONDecoder().decode(RoutineRun.self, from: data),
              stored.id == runId else { return }
        defaults?.removeObject(forKey: key)
    }

    /// A session ending: every user's live run goes, and so does the legacy unscoped key an
    /// older build may have left. Needs no scope, which is the point — after an account
    /// deletion there is no user left to name.
    func clearEveryUser() {
        guard let defaults else { return }
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(Self.legacyRunKey) {
            defaults.removeObject(forKey: key)
        }
    }
}

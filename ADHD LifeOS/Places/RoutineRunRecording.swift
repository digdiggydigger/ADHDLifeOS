//
//  RoutineRunRecording.swift
//  ADHD LifeOS
//
//  The write seam for the routine record (F-RoutineRecord-1): six moments, one protocol, and
//  the production adapter over the manager's narrow `RoutineRunsBackingStore`. The
//  `LocationEventRecording` arrangement, widened to a lifecycle.
//
//  The OFFER is a whole-document create through the codec. Every later moment is a PARTIAL
//  update carrying only its own stamps, which is what keeps the moments from clobbering each
//  other: a swipe response that lands after a tap cannot write the tap away, because it never
//  writes `started_at` at all.
//

import Foundation

/// The moments a routine run passes through, as the sites tell them.
protocol RoutineRunRecording: Sendable {
    func offered(_ record: RoutineRunRecord) async throws
    func started(runId: UUID, at now: Date) async throws
    func dismissed(runId: UUID, at now: Date) async throws
    func expired(runId: UUID, at now: Date) async throws
    /// The screen's step changes — steps, counts and time spent all derived from THIS run.
    func progressed(_ run: RoutineRun, at now: Date) async throws
    func ended(runId: UUID, reason: RoutineRunEndReason, at now: Date) async throws
}

/// The Firestore surface behind `FirebaseRoutineRunRecorder` and the history readers.
/// `updateRoutineRun` is the named partial-write wrapper the house rule asks for, so this
/// store cannot address another collection.
protocol RoutineRunsBackingStore {
    func createRoutineRun(_ record: RoutineRunRecord) async throws
    func updateRoutineRun(id: UUID, fields: [String: Any]) async throws
    func fetchRoutineRuns() async throws -> [RoutineRunRecord]
}

/// Previews and the sim-only rigs: records nothing, throws nothing.
struct InertRoutineRunRecorder: RoutineRunRecording {
    func offered(_ record: RoutineRunRecord) async throws {}
    func started(runId: UUID, at now: Date) async throws {}
    func dismissed(runId: UUID, at now: Date) async throws {}
    func expired(runId: UUID, at now: Date) async throws {}
    func progressed(_ run: RoutineRun, at now: Date) async throws {}
    func ended(runId: UUID, reason: RoutineRunEndReason, at now: Date) async throws {}
}

struct FirebaseRoutineRunRecorder: RoutineRunRecording {
    private let store: RoutineRunsBackingStore

    init(store: RoutineRunsBackingStore = FirebaseManager.shared) {
        self.store = store
    }

    func offered(_ record: RoutineRunRecord) async throws {
        try await store.createRoutineRun(record)
    }

    func started(runId: UUID, at now: Date) async throws {
        try await store.updateRoutineRun(id: runId, fields: FirestoreFieldPayloads.routineRunStarted(at: now))
    }

    func dismissed(runId: UUID, at now: Date) async throws {
        try await store.updateRoutineRun(id: runId, fields: FirestoreFieldPayloads.routineRunDismissed(at: now))
    }

    func expired(runId: UUID, at now: Date) async throws {
        try await store.updateRoutineRun(id: runId, fields: FirestoreFieldPayloads.routineRunExpired(at: now))
    }

    func progressed(_ run: RoutineRun, at now: Date) async throws {
        try await store.updateRoutineRun(
            id: run.id, fields: try FirestoreFieldPayloads.routineRunProgressed(run, at: now)
        )
    }

    func ended(runId: UUID, reason: RoutineRunEndReason, at now: Date) async throws {
        try await store.updateRoutineRun(
            id: runId, fields: FirestoreFieldPayloads.routineRunEnded(reason: reason, at: now)
        )
    }
}

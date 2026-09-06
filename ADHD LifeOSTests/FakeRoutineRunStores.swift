//
//  FakeRoutineRunStores.swift
//  ADHD LifeOSTests
//
//  The two recording stand-ins for the routine record (F-RoutineRecord-1): the Firestore
//  surface behind `FirebaseRoutineRunRecorder`, and the recorder seam itself for the six
//  write sites. One ordered `events` log on the recorder fake, because ORDER is a claim the
//  sites make (a replaced run is ended BEFORE its successor starts).
//

import Foundation
@testable import ADHD_LifeOS

final class FakeRoutineRunsBackingStore: RoutineRunsBackingStore {
    var records: [RoutineRunRecord] = []
    var createError: Error?
    var updateError: Error?
    var fetchError: Error?

    private(set) var created: [RoutineRunRecord] = []
    private(set) var updates: [(id: UUID, fields: [String: Any])] = []

    func createRoutineRun(_ record: RoutineRunRecord) async throws {
        created.append(record)
        if let createError { throw createError }
    }

    func updateRoutineRun(id: UUID, fields: [String: Any]) async throws {
        updates.append((id: id, fields: fields))
        if let updateError { throw updateError }
    }

    func fetchRoutineRuns() async throws -> [RoutineRunRecord] {
        if let fetchError { throw fetchError }
        return records
    }
}

/// The seam fake. Every call is appended to `events` as a short word so a test can assert
/// what was recorded AND in what order; the typed captures below carry the detail.
final class FakeRoutineRunRecorder: RoutineRunRecording, @unchecked Sendable {
    private(set) var events: [String] = []
    private(set) var offered: [RoutineRunRecord] = []
    private(set) var started: [(runId: UUID, at: Date)] = []
    private(set) var dismissed: [(runId: UUID, at: Date)] = []
    private(set) var expired: [(runId: UUID, at: Date)] = []
    private(set) var progressed: [(run: RoutineRun, at: Date)] = []
    struct Ended: Equatable {
        let runId: UUID
        let reason: RoutineRunEndReason
        let endedAt: Date
    }

    private(set) var ended: [Ended] = []
    var error: Error?

    func offered(_ record: RoutineRunRecord) async throws {
        events.append("offered")
        offered.append(record)
        if let error { throw error }
    }

    func started(runId: UUID, at now: Date) async throws {
        events.append("started")
        started.append((runId: runId, at: now))
        if let error { throw error }
    }

    func dismissed(runId: UUID, at now: Date) async throws {
        events.append("dismissed")
        dismissed.append((runId: runId, at: now))
        if let error { throw error }
    }

    func expired(runId: UUID, at now: Date) async throws {
        events.append("expired")
        expired.append((runId: runId, at: now))
        if let error { throw error }
    }

    func progressed(_ run: RoutineRun, at now: Date) async throws {
        events.append("progressed")
        progressed.append((run: run, at: now))
        if let error { throw error }
    }

    func ended(runId: UUID, reason: RoutineRunEndReason, at now: Date) async throws {
        events.append("ended:\(reason.rawValue)")
        ended.append(Ended(runId: runId, reason: reason, endedAt: now))
        if let error { throw error }
    }
}

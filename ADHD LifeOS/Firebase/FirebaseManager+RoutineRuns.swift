//
//  FirebaseManager+RoutineRuns.swift
//  ADHD LifeOS
//

import FirebaseFirestore
import Foundation

/// Routine run documents (F-RoutineRecord-1). Unlike `logs` and `location_events` these are
/// UPDATED — a run moves through offered → started → ended in place — so the collection sits in
/// the generic owner-CRUD rule rather than the append-only ones.
extension FirebaseManager {
    func createRoutineRun(_ record: RoutineRunRecord) async throws {
        try await save(record, id: record.id, in: .routineRuns)
    }

    /// Partial update of one run. Named rather than exposing the generic `update(id:fields:in:)`
    /// so `RoutineRunsBackingStore` cannot address another collection.
    func updateRoutineRun(id: UUID, fields: [String: Any]) async throws {
        try await update(id: id, fields: fields, in: .routineRuns)
    }

    /// Newest offer first, matching the journal's ordering.
    func fetchRoutineRuns() async throws -> [RoutineRunRecord] {
        try await fetchAll(
            RoutineRunRecord.self, from: .routineRuns, orderedBy: "offered_at", descending: true
        )
    }
}

extension FirebaseManager: RoutineRunsBackingStore {}

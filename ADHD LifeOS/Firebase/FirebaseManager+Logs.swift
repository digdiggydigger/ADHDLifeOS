//
//  FirebaseManager+Logs.swift
//  ADHD LifeOS
//

import FirebaseFirestore
import Foundation

/// Journal entries. Append-only for EDITS: there is no update path here by design (see
/// `LogModels.swift`). Delete exists — `firestore.rules` has allowed owner delete on `logs` since
/// 2026-08-19 for account deletion's cascade, and "no rewriting history" never meant "no taking
/// back the last thing you did".
extension FirebaseManager {
    /// Newest entry first, matching the Journal feed sort.
    func fetchLogs() async throws -> [Log] {
        try await fetchAll(Log.self, from: .logs, orderedBy: "entry_date", descending: true)
    }

    /// The only write for logs — no update or delete exists on purpose (see `LogModels.swift`).
    func appendLog(_ log: Log) async throws {
        try await save(log, id: log.id, in: .logs)
    }

    /// Removes one entry. The narrow use is undoing capture triage's "Journal it", which has to
    /// take back the entry it just wrote; there is still no path that EDITS one.
    func deleteLog(id: UUID) async throws {
        try await delete(id: id, from: .logs)
    }

    /// Server-side scoped to one life area. Unsorted (see `fetchWhere`) — callers order for display.
    func fetchLogs(lifeAreaId: UUID) async throws -> [Log] {
        try await fetchWhere(Log.self, from: .logs, field: "life_area_id", equals: lifeAreaId.uuidString)
    }
}

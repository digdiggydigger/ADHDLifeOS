//
//  FirebaseManager+Logs.swift
//  ADHD LifeOS
//

import FirebaseFirestore
import Foundation

/// Journal entries. Append-only for edits: there is no update path here by design (see
/// `LogModels.swift`), and the only delete is account deletion's cascade.
extension FirebaseManager {
    /// Newest entry first, matching the Journal feed sort.
    func fetchLogs() async throws -> [Log] {
        try await fetchAll(Log.self, from: .logs, orderedBy: "entry_date", descending: true)
    }

    /// The only write for logs — no update or delete exists on purpose (see `LogModels.swift`).
    func appendLog(_ log: Log) async throws {
        try await save(log, id: log.id, in: .logs)
    }

    /// Server-side scoped to one life area. Unsorted (see `fetchWhere`) — callers order for display.
    func fetchLogs(lifeAreaId: UUID) async throws -> [Log] {
        try await fetchWhere(Log.self, from: .logs, field: "life_area_id", equals: lifeAreaId.uuidString)
    }
}

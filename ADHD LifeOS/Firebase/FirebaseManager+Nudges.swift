//
//  FirebaseManager+Nudges.swift
//  ADHD LifeOS
//

import FirebaseFirestore
import Foundation

/// Nudge documents. `schedule` stays the `MIN HOUR * * DOW` cron string end to end; it is parsed
/// for display and dueness by `NudgeSchedule`/`NudgeDueness`, never by this layer.
///
/// The four write methods below lived under the "Focus sessions" MARK in `FirebaseManager.swift`
/// until this file existed — appended to the end of the file rather than to their own section.
extension FirebaseManager {
    func fetchNudges() async throws -> [Nudge] {
        try await fetchAll(Nudge.self, from: .nudges, orderedBy: "created_at")
    }

    func fetchNudge(id: UUID) async throws -> Nudge {
        try await collection(.nudges).document(id.uuidString).getDocument(as: Nudge.self)
    }

    func createNudge(_ nudge: Nudge) async throws {
        try await save(nudge, id: nudge.id, in: .nudges)
    }

    func updateNudge(id: UUID, payload: NudgeUpdatePayload) async throws {
        try await update(id: id, fields: FirestoreFieldPayloads.nudgeUpdate(payload), in: .nudges)
    }

    /// Partial update of one nudge. Named rather than exposing the generic `update(id:fields:in:)`
    /// so `NudgesBackingStore` cannot address another collection.
    func updateNudge(id: UUID, fields: [String: Any]) async throws {
        try await update(id: id, fields: fields, in: .nudges)
    }

    func deleteNudge(id: UUID) async throws {
        try await delete(id: id, from: .nudges)
    }
}

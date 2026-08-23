//
//  FirebaseManager+Captures.swift
//  ADHD LifeOS
//

import FirebaseFirestore
import Foundation

/// Capture (inbox) documents. Unlike tasks these keep mixed-case keys — camelCase apart from
/// `created_at` — which is deliberate and load-bearing; see `FirestoreFieldPayloads`.
extension FirebaseManager {
    func fetchCaptures() async throws -> [Capture] {
        try await fetchAll(Capture.self, from: .captures, orderedBy: "created_at", descending: true)
    }

    func fetchCapture(id: UUID) async throws -> Capture {
        try await collection(.captures).document(id.uuidString).getDocument(as: Capture.self)
    }

    /// The inbox query. Unsorted (see `fetchWhere`) — the adapter orders newest-first client-side.
    func fetchUnprocessedCaptures() async throws -> [Capture] {
        try await fetchWhere(Capture.self, from: .captures, field: "processed", equals: false)
    }

    func fetchProcessedCaptures() async throws -> [Capture] {
        try await fetchWhere(Capture.self, from: .captures, field: "processed", equals: true)
    }

    /// The Captures tab's archive query. Equality on `seen == true` also excludes every document
    /// that has no `seen` field at all — exactly right, those were never archived. Unsorted and
    /// unrefined for the same single-field reason as the queries above; the adapter drops
    /// already-promoted captures and orders newest-first client-side.
    func fetchSeenCaptures() async throws -> [Capture] {
        try await fetchWhere(Capture.self, from: .captures, field: "seen", equals: true)
    }

    /// Triage's partial update — never a whole-document overwrite, so the `tag_ids` membership
    /// array (managed in `FirebaseManager+Tags.swift`, not part of `Capture`'s `Codable`) survives.
    func updateCapture(id: UUID, changes: CaptureUpdate) async throws {
        try await update(id: id, fields: FirestoreFieldPayloads.captureUpdate(changes), in: .captures)
    }

    func markCaptureProcessed(id: UUID) async throws {
        try await update(
            id: id,
            fields: ["processed": true, "status": CaptureStatus.processed.rawValue],
            in: .captures
        )
    }

    /// Creates or fully overwrites one capture — covers content edits, triage (`status`/
    /// `processed`), and life-area assignment.
    func saveCapture(_ capture: Capture) async throws {
        try await save(capture, id: capture.id, in: .captures)
    }

    func deleteCapture(id: UUID) async throws {
        try await delete(id: id, from: .captures)
    }
}

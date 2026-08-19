//
//  FirebaseNudgesClientAdapter.swift
//  ADHD LifeOS
//

import FirebaseFirestore
import Foundation

/// Production `NudgesClientAdapting` backed by Firestore via `FirebaseManager`. Mutations write
/// the delta then re-read the document so the returned `Nudge` is the stored truth. A Firestore
/// `notFound` on the write maps to `NudgesServiceError.notFound`, preserving the "this nudge no
/// longer exists" UX the Supabase adapter's 404 handling provided.
struct FirebaseNudgesClientAdapter: NudgesClientAdapting {
    private let manager: FirebaseManager

    init(manager: FirebaseManager = .shared) {
        self.manager = manager
    }

    func fetchNudges() async throws -> [Nudge] {
        do {
            return try await manager.fetchNudges()
        } catch {
            throw NudgesServiceError.fetchFailed(Self.message(for: error))
        }
    }

    func createNudge(label: String, schedule: NudgeSchedule) async throws -> Nudge {
        let now = Date()
        let nudge = Nudge(
            id: UUID(),
            label: label,
            schedule: schedule.encode(),
            active: true,
            lastFiredAt: nil,
            createdAt: now,
            updatedAt: now
        )
        try await manager.createNudge(nudge)
        return nudge
    }

    func updateNudge(id: UUID, payload: NudgeUpdatePayload) async throws -> Nudge {
        do {
            try await manager.updateNudge(id: id, payload: payload)
            return try await manager.fetchNudge(id: id)
        } catch {
            throw Self.mapped(error)
        }
    }

    func markFired(id: UUID) async throws -> Nudge {
        do {
            let now = Timestamp(date: Date())
            try await manager.update(
                id: id,
                fields: ["last_fired_at": now, "updated_at": now],
                in: .nudges
            )
            return try await manager.fetchNudge(id: id)
        } catch {
            throw Self.mapped(error)
        }
    }

    private static func mapped(_ error: Error) -> Error {
        let nsError = error as NSError
        if nsError.domain == FirestoreErrorDomain, nsError.code == FirestoreErrorCode.notFound.rawValue {
            return NudgesServiceError.notFound
        }
        return NudgesServiceError.fetchFailed(message(for: error))
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}

//
//  FirebaseNudgesClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `NudgesClientAdapting` backed by Firestore through `NudgesBackingStore`
/// (`FirebaseManager` in the app, a recording fake in tests). Mutations write
/// the delta then re-read the document so the returned `Nudge` is the stored truth. A Firestore
/// `notFound` on the write maps to `NudgesServiceError.notFound`, preserving the "this nudge no
/// longer exists" UX the Supabase adapter's 404 handling provided.
struct FirebaseNudgesClientAdapter: NudgesClientAdapting {
    private let store: NudgesBackingStore

    init(store: NudgesBackingStore = FirebaseManager.shared) {
        self.store = store
    }

    func fetchNudges() async throws -> [Nudge] {
        do {
            return try await store.fetchNudges()
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
        try await store.createNudge(nudge)
        return nudge
    }

    func updateNudge(id: UUID, payload: NudgeUpdatePayload) async throws -> Nudge {
        do {
            try await store.updateNudge(id: id, payload: payload)
            return try await store.fetchNudge(id: id)
        } catch {
            throw Self.mapped(error)
        }
    }

    func markFired(id: UUID) async throws -> Nudge {
        do {
            try await store.updateNudge(id: id, fields: FirestoreFieldPayloads.nudgeFired(now: .now))
            return try await store.fetchNudge(id: id)
        } catch {
            throw Self.mapped(error)
        }
    }

    private static func mapped(_ error: Error) -> Error {
        if FirestoreErrorMapping.isNotFound(error) {
            return NudgesServiceError.notFound
        }
        return NudgesServiceError.fetchFailed(message(for: error))
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}

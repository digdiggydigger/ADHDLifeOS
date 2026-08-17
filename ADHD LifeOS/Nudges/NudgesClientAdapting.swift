//
//  NudgesClientAdapting.swift
//  ADHD LifeOS
//

import Foundation

enum NudgesServiceError: LocalizedError, Equatable {
    case fetchFailed(String)
    case notFound

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return message
        case .notFound:
            return "This nudge no longer exists."
        }
    }
}

/// Thin seam over the Supabase Postgrest client so `NudgesService` is testable without a network.
/// Mirrors web's `nudgeService`/`supabaseNudgeService`: create, list, mark-fired (dismiss), and
/// partial update (label/schedule/active).
protocol NudgesClientAdapting: Sendable {
    func fetchNudges() async throws -> [Nudge]
    func createNudge(label: String, schedule: NudgeSchedule) async throws -> Nudge
    func updateNudge(id: UUID, payload: NudgeUpdatePayload) async throws -> Nudge
    func markFired(id: UUID) async throws -> Nudge
}

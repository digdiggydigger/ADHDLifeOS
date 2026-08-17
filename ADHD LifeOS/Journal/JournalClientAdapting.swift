//
//  JournalClientAdapting.swift
//  ADHD LifeOS
//

import Foundation

enum JournalServiceError: LocalizedError, Equatable {
    case fetchFailed(String)

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return message
        }
    }
}

/// Thin seam over the Supabase Postgrest client so `JournalService` is testable without a
/// network. Mirrors web's `logService`/`supabaseLogService`: fetch life areas (for the filter/
/// composer pickers), list all logs, and create — no update/delete, `public.logs` has no such
/// RLS policy.
protocol JournalClientAdapting: Sendable {
    func fetchLifeAreas() async throws -> [LifeArea]
    func fetchLogs() async throws -> [Log]
    func createLog(_ input: NormalizedCreateLogInput) async throws -> Log
}

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
    /// The finished-sprint history the timeline interleaves beside the written entries
    /// (E's 2026-08-25 note). Read-only, like everything else on this seam except `createLog`.
    func fetchFocusSessions() async throws -> [CompletedFocusSession]
    /// The capture log — every thought dumped, stamped at `createdAt`. Read-only.
    func fetchCaptures() async throws -> [Capture]
    /// The recorded fence crossings the timeline interleaves as quiet event rows (block 4c),
    /// and the places that give them names. Read-only garnish, like the streams above.
    func fetchLocationEvents() async throws -> [LocationEvent]
    func fetchPlaces() async throws -> [Place]
    /// The shared tag registry, for the composer's chips and the rows' resolution — the same
    /// list tasks and captures use.
    func fetchAllTags() async throws -> [Tag]
    /// Creates (or dedups by name, server-side semantics) a tag for the composer.
    func createTag(name: String) async throws -> Tag
    func createLog(_ input: NormalizedCreateLogInput) async throws -> Log
}

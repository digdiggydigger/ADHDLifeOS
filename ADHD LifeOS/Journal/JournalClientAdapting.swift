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

/// Thin seam over the journal backend so `JournalService` is testable without a network.
/// `FirebaseJournalClientAdapter` is the production conformance. Mirrors the web prototype's
/// `logService`: fetch life areas (for the filter/composer pickers), list all logs, and create.
///
/// There is no UPDATE — an entry is never rewritten, which is the design the old Supabase RLS
/// enforced and `firestore.rules` still does (`allow update: if false` on `logs`). Delete arrived
/// with capture triage's undo (see `deleteLog`); the rules have permitted it since 2026-08-19.
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
    /// The routine record (F-RoutineRecord-1): offered, started and finished runs, for the
    /// timeline's routine rows and for the passive-ending reconciliation the load performs.
    func fetchRoutineRuns() async throws -> [RoutineRunRecord]
    func fetchPlaces() async throws -> [Place]
    /// The shared tag registry, for the composer's chips and the rows' resolution — the same
    /// list tasks and captures use.
    func fetchAllTags() async throws -> [Tag]
    /// Creates (or dedups by name, server-side semantics) a tag for the composer.
    func createTag(name: String) async throws -> Tag
    func createLog(_ input: NormalizedCreateLogInput) async throws -> Log
    /// Removes one entry. Written for undoing capture triage's "Journal it", which must be able
    /// to take back the entry it wrote a moment ago. Not an edit path: an entry that survives is
    /// still never rewritten.
    func deleteLog(id: UUID) async throws
}

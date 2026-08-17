//
//  LifeAreaEditorClientAdapting.swift
//  ADHD LifeOS
//

import Foundation

/// Editor-scoped life-area model. Deliberately **separate** from `LifeArea` (`HomeModels.swift`),
/// which is decoded by the Home, Tasks, Journal and LifeAreaDetail adapters — adding `archived` (or
/// anything else) to that shared type would force every one of those decode sites to account for it,
/// the exact trap `EditableTag` avoided for `Tag`. `GET /life-areas` returns `archived` on every row
/// (missing = false, applied server-side), so it is a plain non-optional `Bool` here.
struct EditableLifeArea: Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    var name: String
    var colour: String   // stores the emoji, not a colour — §8 says leave the name as-is.
    var sortOrder: Int
    var archived: Bool
}

/// The conflicting area surfaced when a create or rename collides with an existing name. Built from
/// the `409` body's `conflict` object, which is why the adapter must decode `409` into this typed
/// value rather than collapsing it into a generic failure string (trap d). `archived` is the field
/// the two conflict *flows* branch on: create-onto-archived offers "Unarchive it instead?", every
/// other collision is Cancel-only.
struct LifeAreaNameConflict: Equatable, Sendable {
    let id: UUID
    let name: String
    let archived: Bool
}

/// Typed outcome of a `PATCH /life-areas/{id}` that may carry a new name. `200` → `.updated`;
/// `409` → `.nameConflict`. A real failure (`400`/`404`/network) is thrown, not represented here.
enum LifeAreaUpdateOutcome: Equatable, Sendable {
    case updated
    case nameConflict(LifeAreaNameConflict)
}

/// Typed outcome of a `POST /life-areas`. Unlike `POST /tags`, life areas do **not** dedup-and-
/// return-existing — a name clash is an honest `409` (§8), so this is `.created` or `.nameConflict`,
/// never a silent "already existed" hand-back.
enum LifeAreaCreateOutcome: Equatable, Sendable {
    case created(EditableLifeArea)
    case nameConflict(LifeAreaNameConflict)
}

enum LifeAreaEditorServiceError: LocalizedError, Equatable {
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .failed(let message):
            return message
        }
    }
}

/// Thin seam over `life-os-api-gw`'s life-area routes so `LifeAreaEditorService` is testable without
/// a network. `update` and `create` map the backend's `409` semantics into typed Swift — see
/// `AWSLifeAreaEditorClientAdapter` for why the fetch-only `AWSHomeClientAdapter` could not be
/// reused as-is (it collapses every non-2xx into one string, discarding the conflict body).
protocol LifeAreaEditorClientAdapting: Sendable {
    /// `GET /life-areas` — every area, active and archived, with its `archived` flag.
    func fetchLifeAreas() async throws -> [EditableLifeArea]
    /// `PATCH /life-areas/{id}` with any subset of `name`/`colour` — `.updated` on `200`,
    /// `.nameConflict` on `409`. Send only the fields that actually changed.
    func update(id: UUID, name: String?, colour: String?) async throws -> LifeAreaUpdateOutcome
    /// `PATCH /life-areas/{id}` `{"archived": ...}` — archive or unarchive. Cannot name-conflict,
    /// so it throws on failure or succeeds.
    func setArchived(id: UUID, archived: Bool) async throws
    /// `POST /life-areas` `{"name": ..., "colour": ...}` — `.created` on `201`, `.nameConflict` on
    /// `409`.
    func create(name: String, colour: String) async throws -> LifeAreaCreateOutcome
}

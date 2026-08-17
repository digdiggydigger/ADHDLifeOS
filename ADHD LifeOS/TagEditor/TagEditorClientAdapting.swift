//
//  TagEditorClientAdapting.swift
//  ADHD LifeOS
//

import Foundation

/// Editor-scoped tag model carrying the usage count. Deliberately **separate** from `Tag`
/// (`{ id, name }`, used by `TagDedup`, task detail and capture tagging): adding a required count
/// to `Tag` would force every other decode site to supply it. `GET /tags` returns `taskCount`,
/// `captureCount` and `usageCount` (their sum) per tag; only the sum is shown on this screen, so
/// only `usageCount` is modelled here.
struct EditableTag: Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    let name: String
    let usageCount: Int
}

/// The conflicting tag surfaced when a rename collides with a *different* existing tag. Built from
/// the `409` body's `conflict` object — this is the data the merge alert is rendered from, which is
/// why the adapter must decode the `409` into this typed case rather than collapsing it into a
/// generic failure string.
struct TagRenameConflict: Equatable, Sendable {
    let id: UUID
    let name: String
    let usageCount: Int
}

/// The typed outcome of a `PATCH /tags/{id}` rename attempt, so the alert-triggering logic is
/// testable without a network. A real failure (`400`/`404`/network) is thrown, not represented
/// here — this enum only distinguishes the two *successful-request* branches.
enum TagRenameOutcome: Equatable, Sendable {
    case renamed
    case needsMerge(TagRenameConflict)
}

/// The typed outcome of a `POST /tags` create. `POST /tags` dedups server-side and never fails on a
/// duplicate name: `201` with a new tag, or `200` with the *existing* tag. Distinguishing the two
/// lets the UI avoid a phantom duplicate row and tell E honestly that the tag already existed.
enum TagCreateOutcome: Equatable, Sendable {
    case created(EditableTag)
    case alreadyExisted(EditableTag)
}

enum TagEditorServiceError: LocalizedError, Equatable {
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .failed(let message):
            return message
        }
    }
}

/// Thin seam over `life-os-api-gw`'s tag routes so `TagEditorService` is testable without a
/// network. Rename and delete map the backend's `409`/`204` semantics into typed Swift — see
/// `AWSTagEditorClientAdapter` for why the existing fetch-only adapters could not be reused as-is.
protocol TagEditorClientAdapting: Sendable {
    /// `GET /tags` — every tag with its usage count.
    func fetchTags() async throws -> [EditableTag]
    /// `PATCH /tags/{id}` `{"name": ...}` — `.renamed` on `200`, `.needsMerge` on `409`.
    func renameTag(id: UUID, to name: String) async throws -> TagRenameOutcome
    /// `PATCH /tags/{id}` `{"name": ..., "onConflict": "merge"}` — throws on failure, else succeeds.
    func mergeTag(id: UUID, into name: String) async throws
    /// `DELETE /tags/{id}` — `204`, cascade handled server-side.
    func deleteTag(id: UUID) async throws
    /// `POST /tags` `{"name": ...}` — `.created` on `201`, `.alreadyExisted` on `200` (dedup).
    func createTag(name: String) async throws -> TagCreateOutcome
}

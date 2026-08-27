//
//  CaptureClientAdapting.swift
//  ADHD LifeOS
//

import Foundation

struct NormalizedPromoteToTaskInput: Equatable, Sendable {
    let title: String
    /// The capture's annotation, becoming the new task's starting notes.
    let notes: String?
    let lifeAreaId: UUID?
    let priority: TaskPriority
    let dueDate: Date?
    /// S2's effort chip, landing on the task's own sprint config (`focus_duration_seconds`) —
    /// the field every task already carries. `nil` = the user skipped the chip.
    var focusDurationSeconds: Int?
}

struct CaptureUploadTarget: Equatable, Sendable {
    let uploadURL: URL
    let mediaKey: String
    let thumbnailKey: String?
}

/// A partial update payload for `updateCapture` — mirrors `TaskUpdatePayload`'s per-field
/// omit-if-nil/explicit-null discipline. `title` is set-or-omit (outer `nil` = don't touch);
/// `lifeAreaId` is a nested optional since triage's Life Area picker can explicitly clear a
/// capture back to "None" — outer `nil` = don't touch, `.some(nil)` = clear to null.
///
/// There was a `status` field here too, carrying a `CaptureStatus` enum. No caller ever set it
/// (the audit's A4); `processed` and `seen` are the state.
struct CaptureUpdate: Equatable, Sendable {
    var lifeAreaId: UUID??
    var title: String?
    /// Nested optional like `lifeAreaId`: outer `nil` = untouched, `.some(nil)` = the user erased
    /// their annotation, which deletes the field rather than storing an empty string.
    var notes: String??
    /// Set-or-omit like `status` — a plain `Bool?`, never a delete: undo writes an explicit
    /// `false` back onto the document.
    var seen: Bool?
    /// The inbox-exit stamp. Nested optional: `.some(nil)` deletes it when an archive is undone
    /// and the capture re-enters the inbox.
    var clearedAt: Date??
}

enum CaptureServiceError: LocalizedError, Equatable {
    case fetchFailed(String)
    case alreadyProcessed

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return message
        case .alreadyProcessed:
            return "This capture has already been processed."
        }
    }
}

/// Thin seam over the capture backend so `CaptureInboxService` is testable without a network.
/// `FirebaseCaptureClientAdapter` is the production conformance; tests use a recording fake.
/// Mirrors the web prototype's `captureService`/`capturePromotion` flow: create, list unprocessed,
/// and promote (re-check current state, create task, mark processed).
protocol CaptureClientAdapting: Sendable {
    func createCapture(_ input: NormalizedCreateCaptureInput) async throws -> Capture
    func fetchUnprocessedCaptures() async throws -> [Capture]
    /// Captures already triaged — the Promoted tab. Separate call rather than a filter argument so
    /// the tab the user isn't looking at is never fetched.
    func fetchProcessedCaptures() async throws -> [Capture]
    /// Captures sorted and not since promoted — the Captures tab's Sorted slice. `seen` is the
    /// field's name on the wire; **Sorted** is the only word the user ever sees for it.
    func fetchSeenCaptures() async throws -> [Capture]
    /// Every capture regardless of state — the input to S1's weekly capture-vs-clear
    /// counterweight (M10). Newest first, straight off the server ordering.
    func fetchCaptures() async throws -> [Capture]
    func fetchCapture(id: UUID) async throws -> Capture
    func createTask(_ input: NormalizedPromoteToTaskInput) async throws -> TaskItem
    func markProcessed(captureId: UUID) async throws
    /// Returns a processed capture to the inbox — the inverse of `markProcessed`, and the reason
    /// "Journal it" can finally be taken back. Its absence is why round 1 shipped undo for Sorted
    /// and Skip only.
    func markUnprocessed(captureId: UUID) async throws
    /// Discards a capture outright — the triage exit for something that is neither a task nor worth
    /// keeping. `captures` already grants owner delete in `firestore.rules`, so no rules change.
    func deleteCapture(id: UUID) async throws

    /// Partial update (status/lifeAreaId/title) — the triage screen's Life Area picker path.
    func updateCapture(id: UUID, changes: CaptureUpdate) async throws -> Capture
    func fetchAllTags() async throws -> [Tag]
    /// Server dedups by name — creating a tag with a name that already exists returns the
    /// existing `Tag` rather than a new duplicate row.
    func createTag(name: String) async throws -> Tag
    func fetchTags(captureId: UUID) async throws -> [Tag]
    func addTag(captureId: UUID, tagId: UUID) async throws
    func removeTag(captureId: UUID, tagId: UUID) async throws

    /// Mints an upload target — a Firebase Storage object path (`mediaKey`) and the URL to write
    /// it at. Call before `uploadMedia`, then pass the returned `mediaKey` into `createCapture`.
    /// `thumbnailKey` is vestigial: nothing generates thumbnails on Firebase.
    func requestUploadURL(kind: CaptureKind, contentType: String) async throws -> CaptureUploadTarget

    /// Uploads raw media bytes to the `uploadURL` from `requestUploadURL`, through the Firebase
    /// Storage SDK — which carries the signed-in user's credentials itself.
    func uploadMedia(to uploadURL: URL, data: Data, contentType: String) async throws
}

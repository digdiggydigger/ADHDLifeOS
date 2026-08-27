//
//  CaptureModels.swift
//  ADHD LifeOS
//

import Foundation

enum CaptureKind: String, Codable, Equatable, Sendable, CaseIterable {
    case note
    case task
    case link
    case voice
    case photo
}

enum CaptureStatus: String, Codable, Equatable, Sendable, CaseIterable {
    case inbox
    case needsReview = "needs-review"
    case processed
}

struct CaptureLinkPreview: Codable, Equatable, Sendable {
    let url: String
    let title: String?
    let description: String?
    let thumbnailURL: URL?
}

struct Capture: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var content: String
    var kind: CaptureKind
    var processed: Bool
    let createdAt: Date
    var title: String?
    var status: CaptureStatus?
    var lifeAreaId: UUID?
    var mediaURL: URL?
    var mediaContentType: String?
    var thumbnailURL: URL?
    var linkPreview: CaptureLinkPreview?
    var aiAssessment: String?
    /// The user's own annotation, editable from the detail screen — the words that accompany a
    /// capture whose `content` slot is already spoken for (a link's URL, a voice memo's
    /// transcript, a photo's caption). Carried into the task on promotion.
    var notes: String?
    /// When the capture left the inbox — stamped by archive-as-seen, promotion and
    /// log-to-journal, deleted again when an archive is undone (M7). `nil` on documents cleared
    /// before the stamp existed; those belong to no particular day.
    var clearedAt: Date?
    /// The Captures-tab archive flag — "noted, nothing to do". Orthogonal to `processed` on
    /// purpose: a seen capture stays unprocessed so it can still be promoted later. `nil` on every
    /// document written before the flag existed, and it means the same as `false`.
    var seen: Bool?
    /// Tag membership, read straight off the document so the inbox can chip it without per-row
    /// fetches. Read-only from this model's point of view: writes stay `arrayUnion`/`arrayRemove`
    /// in `FirebaseManager+Tags`, and the full-document encode only ever runs at create, where
    /// this is `nil` and the key is omitted. `tag_ids` is one of the snake_case exceptions in the
    /// captures convention, because that is what the membership writes have always spelled.
    var tagIds: [UUID]?

    enum CodingKeys: String, CodingKey {
        case id, content, kind, processed, title, status, lifeAreaId
        case mediaURL, mediaContentType, thumbnailURL, linkPreview, aiAssessment, seen, notes, clearedAt
        case createdAt = "created_at"
        case tagIds = "tag_ids"
    }

    /// The URL a photo capture's thumbnail should render from: the server-generated thumbnail when
    /// present, falling back to the original image (e.g. before the thumbnailer Lambda has run, or
    /// if the thumbnail 404s). `nil` for non-photo captures with no media.
    var photoDisplayURL: URL? {
        thumbnailURL ?? mediaURL
    }
}

//
//  TagModels.swift
//  ADHD LifeOS
//

import Foundation

struct Tag: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    /// When this tag was soft-deleted (`F-C4-TagsRecentlyDeleted`). **`nil` means LIVE**, the same
    /// load-bearing absence `TaskItem` and `Capture` carry.
    ///
    /// **A tag's stamp hides the tag and NOTHING else.** Every `tag_ids` array on every task and
    /// capture keeps this id while the stamp is set — E's *"Back on every item"* is a property of
    /// never having unlinked, not of re-attaching at restore. The links are stripped only by the
    /// 30-day purge, which is where today's immediate `removeTagEverywhere` batch finally runs.
    ///
    /// Read through `SoftDelete.isLive(deletedAt:)`, never compared inline.
    var deletedAt: Date?

    /// **The first `CodingKeys` this model has ever had**, and it exists for one field. `id` and
    /// `name` are single words, so Swift's default synthesis happened to match the wire — which is
    /// why nothing here declared a convention until now. `deletedAt` is the first multi-word field
    /// on the collection, and the default spelling would have disagreed with `tasks` silently:
    /// a stamp written under a key nothing reads leaves the tag on every chip.
    enum CodingKeys: String, CodingKey {
        case id, name
        case deletedAt = "deleted_at"
    }
}

extension Tag: SoftDeletable {}

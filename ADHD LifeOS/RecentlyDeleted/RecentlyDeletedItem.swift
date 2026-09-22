//
//  RecentlyDeletedItem.swift
//  ADHD LifeOS
//
//  `F-C3-RecentlyDeleted`: one row of the 30-day list, whichever collection it came from.
//
//  **A projection, not a third model.** A deleted task is still a `TaskItem` and a deleted capture
//  is still a `Capture`; this is the four fields the screen needs, so the screen can hold one
//  sorted list instead of two interleaved ones and so the presentation can be tested without
//  either of the real models' dozen-odd fields. The adapter builds these; nothing else does.
//

import Foundation

struct RecentlyDeletedItem: Identifiable, Equatable, Sendable {
    /// Which collection the document lives in — the only thing that tells `restore` and
    /// `deleteForever` where to write, and the only thing that tells the two rows apart when
    /// their titles do not.
    enum Kind: String, Equatable, Sendable, CaseIterable {
        case task
        case capture
        /// **`F-C4-TagsRecentlyDeleted`, and the one kind whose row is not a document waiting to
        /// come back.** A deleted task is hidden and nothing else changed; a deleted TAG is hidden
        /// while every `tag_ids` array that names it stays exactly as it was. So this row stands
        /// for a link set held open, and its "Delete Forever" is the only one in the screen that
        /// rewrites other documents.
        case tag
    }

    /// The DOCUMENT's id, not the row's. Named apart from `id` because the row's identity has to
    /// carry the collection as well — see below.
    let itemId: UUID
    let kind: Kind
    let title: String
    let deletedAt: Date
    /// A LIVE tag already wearing this one's name. **Only ever non-nil on a `.tag` row** — only
    /// tags have a name that has to be unique.
    ///
    /// **Carried on the row rather than discovered at the write**, because the alert is what the
    /// Restore TAP opens: the screen has to know before the user commits. A write that failed with
    /// a typed error would hand the same alert to every caller of `restore`, including the undo
    /// capsule in the Tag Editor, which cannot reach this collision at all.
    let collision: NameCollision?

    /// The live tag a restore would have to be reconciled with.
    struct NameCollision: Equatable, Sendable {
        let liveId: UUID
        /// Its spelling, which is one of the two the user picks between — the collision folds
        /// case, so this can differ from the restored tag's name by case and nothing else.
        let liveName: String
    }

    init(itemId: UUID, kind: Kind, title: String, deletedAt: Date, collision: NameCollision? = nil) {
        self.itemId = itemId
        self.kind = kind
        self.title = title
        self.deletedAt = deletedAt
        self.collision = collision
    }

    /// **Composite, and it is not paranoia.** Firestore ids are unique per collection, not across
    /// them, so nothing prevents a task and a capture sharing one — and a `ForEach` over a
    /// colliding id drops a row without a word.
    var id: String { "\(kind.rawValue)-\(itemId.uuidString)" }
}

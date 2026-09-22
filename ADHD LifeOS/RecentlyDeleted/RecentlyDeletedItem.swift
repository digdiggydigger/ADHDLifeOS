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
    }

    /// The DOCUMENT's id, not the row's. Named apart from `id` because the row's identity has to
    /// carry the collection as well — see below.
    let itemId: UUID
    let kind: Kind
    let title: String
    let deletedAt: Date

    /// **Composite, and it is not paranoia.** Firestore ids are unique per collection, not across
    /// them, so nothing prevents a task and a capture sharing one — and a `ForEach` over a
    /// colliding id drops a row without a word.
    var id: String { "\(kind.rawValue)-\(itemId.uuidString)" }
}

//
//  FirebaseManager+SoftDelete.swift
//  ADHD LifeOS
//
//  `F-C3-RecentlyDeleted`: the one place a fetch drops deleted rows.
//
//  **Why the filter is here and not in the queries.** A soft-delete filter written as
//  `whereField("deleted_at", isEqualTo: NSNull())` matches only documents where the field is
//  explicitly PRESENT and null — every task and capture written before this block has no such key,
//  so a server-side filter would empty the app. The fetches therefore stay exactly as they were
//  and the client decides, which is why this file exists: the decision is taken in nine places and
//  must be one function. `SoftDeleteCallSiteTests` pins the nine and their COUNT, so a tenth
//  cannot be added without tripping a test.
//
//  **Why a protocol rather than four copies.** `.filter { $0.deletedAt == nil }` written in four
//  files is right until the rule changes once — and the rule already has a subtlety (a FUTURE
//  stamp is still a delete) that a hand-rolled copy would get wrong.
//

import Foundation

/// A model that can be soft-deleted. Conformance is the model's declaration that its documents
/// carry the stamp; the filter below is the only thing that reads it.
protocol SoftDeletable {
    var deletedAt: Date? { get }
}

extension FirebaseManager {
    /// The rows a list should show.
    func live<T: SoftDeletable>(_ items: [T]) -> [T] {
        items.filter { SoftDelete.isLive(deletedAt: $0.deletedAt) }
    }

    /// The single-document read's guard.
    ///
    /// **It throws rather than returning `nil`.** These reads are reachable from routes that
    /// outlive the list they came from — a widget link, a nudge, a notification, a capsule held
    /// across a tab switch — and a screen that opens a deleted item as though it were live and
    /// editable is the one outcome worse than an error. The error says where the thing went.
    func requireLive<T: SoftDeletable>(_ item: T) throws -> T {
        guard SoftDelete.isLive(deletedAt: item.deletedAt) else { throw SoftDeleteError.itemIsDeleted }
        return item
    }
}

//
//  SoftDelete.swift
//  ADHD LifeOS
//
//  `F-C3-RecentlyDeleted`: the two questions a soft delete asks.
//
//  E, round 2: *"Where Recently Deleted lives → 'One row in Tools'"*, *"Kept 30 days"*,
//  *"Tasks + Captures + Tags"* (tags are C4). Step 0 answer 1: *"The app, when you open it"* —
//  the purge runs on launch, with an injectable clock.
//
//  **Why this is a type and not two `if`s at the read sites.** A soft-delete filter written as
//  `whereField("deleted_at", isEqualTo: NSNull())` matches ONLY documents where the field is
//  explicitly present and null — so every task and capture written before this block would vanish
//  from every list. The app therefore fetches as it always did and decides live-ness in the
//  client, which means the decision is taken in a dozen places and has to be ONE function.
//  `SoftDeleteCallSiteTests` pins the places; these two functions are the decision.
//
//  **A deviation from the spec's own signature, named.** The spec proposed
//  `isLive(deletedAt:asOf:)`. `asOf` cannot change that answer — an item with a stamp is not live
//  whether or not its 30 days have run — and a parameter no test can make matter is a parameter
//  that hides which question is being asked. The clock belongs to the second function only.
//

import Foundation

enum SoftDelete {
    /// E's *"Kept 30 days"*.
    static let retention: TimeInterval = 30 * 24 * 60 * 60

    /// Whether a document belongs in the app's ordinary lists.
    ///
    /// **`nil` means LIVE, and that is the case most likely to be got backwards.** Every task and
    /// capture written before this block has no `deleted_at` key at all, so it decodes as `nil`;
    /// an implementation that treated absence as anything but live would empty the app.
    static func isLive(deletedAt: Date?) -> Bool {
        deletedAt == nil
    }

    /// Whether the launch purge should delete this document for good.
    ///
    /// **A live item is never purgeable, whatever the clock says.** The purge iterates documents
    /// it fetched *as deleted*, so this guard is redundant by construction — and it is here anyway,
    /// because this is the only irreversible operation in the block and it does not get to assume
    /// its caller filtered correctly.
    ///
    /// A stamp in the FUTURE is a delete that has not yet aged, so it is kept: a second device
    /// with a fast clock must not cause an immediate purge.
    static func isPurgeable(deletedAt: Date?, asOf now: Date) -> Bool {
        guard let deletedAt else { return false }
        return now.timeIntervalSince(deletedAt) > retention
    }
}

/// Why a single-document fetch refused.
///
/// **A dedicated error rather than a not-found.** Single-document reads (`fetchTaskDetail(id:)`,
/// `fetchCapture(id:)`) are reachable from routes that outlive the list they came from — a widget
/// deep link, a nudge, a notification, a capsule held across a tab switch. Opening a deleted item
/// as though it were live and editable is the one outcome worse than an error, and "not found" is
/// a lie the user can do nothing with. This says where the thing went.
enum SoftDeleteError: LocalizedError, Equatable {
    case itemIsDeleted

    var errorDescription: String? {
        switch self {
        case .itemIsDeleted: return "That's in Recently Deleted. Restore it from Tools to open it."
        }
    }
}

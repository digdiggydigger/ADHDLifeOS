//
//  RecentlyDeletedClientAdapting.swift
//  ADHD LifeOS
//
//  `F-C3-RecentlyDeleted`: the 30-day list's seam.
//
//  **The only place in the app that can destroy a document**, and that is the point of collecting
//  these three methods behind one protocol: `deleteTask`/`deleteCapture` left every other seam in
//  this block, so an irreversible write now requires reaching a type whose name says what it is
//  for. `SoftDeleteCallSiteTests` walks the tree to keep it that way.
//

import Foundation

protocol RecentlyDeletedClientAdapting: Sendable {
    /// Everything waiting, both collections, unsorted — `RecentlyDeletedPresentation` orders them.
    func fetchDeleted() async throws -> [RecentlyDeletedItem]
    /// Erases the stamp. The item reappears everywhere it used to be, with its tags, notes and
    /// history intact, because it never left.
    func restore(_ item: RecentlyDeletedItem) async throws
    /// Restore a tag whose name has been taken again, merging the two into whichever the user
    /// kept (E's Step 0: *"Ask which one survives"*). `keepingRestored` false means the LIVE tag
    /// wins and the one in this list is absorbed and destroyed — so this is the only method here
    /// that can end with the row's own document gone on a RESTORE.
    func restore(_ item: RecentlyDeletedItem, keepingRestored: Bool) async throws
    /// The real document delete — "Delete forever", and the launch purge. The item's `kind` is
    /// what says which collection, which is why these take the whole value rather than an id.
    func deleteForever(_ item: RecentlyDeletedItem) async throws
}

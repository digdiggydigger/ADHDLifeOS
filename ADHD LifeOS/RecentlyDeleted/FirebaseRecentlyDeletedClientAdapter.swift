//
//  FirebaseRecentlyDeletedClientAdapter.swift
//  ADHD LifeOS
//
//  `F-C3-RecentlyDeleted`: the fifteenth `Firebase*ClientAdapter`, beside the feature it serves
//  rather than in `ADHD LifeOS/Firebase/` — the house arrangement (CLAUDE.md, Architecture notes).
//

import Foundation

struct FirebaseRecentlyDeletedClientAdapter: RecentlyDeletedClientAdapting {
    private let store: RecentlyDeletedBackingStore

    init(store: RecentlyDeletedBackingStore = FirebaseManager.shared) {
        self.store = store
    }

    /// **Both collections, concurrently, and a failure in either fails the whole read.**
    /// A screen that quietly showed only the tasks because the capture fetch threw would tell the
    /// user their capture is already gone — the one thing this screen exists to disprove. So no
    /// `try?` here, unlike the garnish loads elsewhere in the app.
    func fetchDeleted() async throws -> [RecentlyDeletedItem] {
        async let tasks = store.fetchDeletedTasks()
        async let captures = store.fetchDeletedCaptures()
        async let tags = store.fetchDeletedTags()
        // The live list is read for ONE reason: a deleted tag's name can be taken again in the
        // thirty days it waits, and the row has to say so before the user taps Restore.
        async let liveTags = store.fetchTags()
        return try await Self.items(from: tasks) + Self.items(from: captures)
            + Self.items(from: tags, collidingWith: liveTags)
    }

    func restore(_ item: RecentlyDeletedItem) async throws {
        switch item.kind {
        case .task: try await store.restoreTask(id: item.itemId)
        case .capture: try await store.restoreCapture(id: item.itemId)
        case .tag: try await store.restoreTag(id: item.itemId)
        }
    }

    /// **Both directions end with ONE live tag, and neither leaves a dangling id.** Keeping the
    /// restored tag is the atomic merge-and-restore; keeping the live one is the Tag Editor's
    /// existing merge, after which there is nothing left to restore.
    func restore(_ item: RecentlyDeletedItem, keepingRestored: Bool) async throws {
        guard let collision = item.collision else {
            // No collision: the choice was never offered, so this is an ordinary restore. Reached
            // only if a caller asks for the resolving form on a row that does not need it.
            try await restore(item)
            return
        }
        if keepingRestored {
            try await store.mergeTagsRestoring(survivor: item.itemId, absorbed: collision.liveId)
        } else {
            try await store.mergeTagInto(item.itemId, replacement: collision.liveId)
        }
    }

    func deleteForever(_ item: RecentlyDeletedItem) async throws {
        switch item.kind {
        case .task: try await store.deleteTask(id: item.itemId)
        case .capture: try await store.deleteCapture(id: item.itemId)
        // **Not a document delete.** A tag's purge strips its id from every task and capture that
        // still carries it, THEN destroys it — the batch a tag delete used to run at the tap.
        case .tag: try await store.purgeTag(id: item.itemId)
        }
    }

    /// **A row with no stamp is dropped rather than shown with a guessed date.** The fetches
    /// already filter to stamped documents, so this is unreachable by construction — and the
    /// alternative, defaulting to `.now`, would put an item at the TOP of the list with a full
    /// 30 days it does not have.
    private static func items(from tasks: [TaskItem]) -> [RecentlyDeletedItem] {
        tasks.compactMap { task in
            task.deletedAt.map {
                RecentlyDeletedItem(itemId: task.id, kind: .task, title: task.title, deletedAt: $0)
            }
        }
    }

    /// A tag's title is its name, which is the whole of a tag.
    ///
    /// **The name match folds case, because `fetchTag(named:)` does.** Two tags differing only in
    /// case cannot both be live — dedup would never have made the second — so a restore that
    /// compared exactly would create precisely the state the app treats as impossible.
    private static func items(from tags: [Tag], collidingWith liveTags: [Tag]) -> [RecentlyDeletedItem] {
        tags.compactMap { tag in
            tag.deletedAt.map { stamp in
                let live = liveTags.first {
                    $0.name.compare(tag.name, options: [.caseInsensitive]) == .orderedSame
                }
                return RecentlyDeletedItem(
                    itemId: tag.id, kind: .tag, title: tag.name, deletedAt: stamp,
                    collision: live.map { .init(liveId: $0.id, liveName: $0.name) }
                )
            }
        }
    }

    /// A capture's headline is resolved by the same type the inbox and the capsule use, so one
    /// capture never reads differently on two screens.
    private static func items(from captures: [Capture]) -> [RecentlyDeletedItem] {
        captures.compactMap { capture in
            capture.deletedAt.map {
                RecentlyDeletedItem(
                    itemId: capture.id, kind: .capture,
                    title: CaptureDetailPresentation.headline(for: capture), deletedAt: $0
                )
            }
        }
    }
}

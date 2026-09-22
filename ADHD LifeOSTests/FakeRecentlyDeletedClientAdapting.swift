//
//  FakeRecentlyDeletedClientAdapting.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

final class FakeRecentlyDeletedClientAdapting: RecentlyDeletedClientAdapting, @unchecked Sendable {
    var fetchResult: Result<[RecentlyDeletedItem], Error> = .success([])
    var restoreResult: Result<Void, Error> = .success(())
    var deleteForeverResult: Result<Void, Error> = .success(())

    private(set) var fetchCallCount = 0
    private(set) var restored: [RecentlyDeletedItem] = []
    private(set) var deletedForever: [RecentlyDeletedItem] = []

    private(set) var resolvedRestores: [ResolvedRestore] = []

    struct ResolvedRestore: Equatable {
        let item: RecentlyDeletedItem
        let keptRestored: Bool
    }

    func fetchDeleted() async throws -> [RecentlyDeletedItem] {
        fetchCallCount += 1
        return try fetchResult.get()
    }

    func restore(_ item: RecentlyDeletedItem) async throws {
        restored.append(item)
        try restoreResult.get()
    }

    /// Recorded apart from `restored`, because the whole point of the survivor choice is that a
    /// resolving restore is a DIFFERENT write — and in one direction it does not restore at all.
    func restore(_ item: RecentlyDeletedItem, keepingRestored: Bool) async throws {
        resolvedRestores.append(ResolvedRestore(item: item, keptRestored: keepingRestored))
        try restoreResult.get()
    }

    func deleteForever(_ item: RecentlyDeletedItem) async throws {
        deletedForever.append(item)
        try deleteForeverResult.get()
    }
}

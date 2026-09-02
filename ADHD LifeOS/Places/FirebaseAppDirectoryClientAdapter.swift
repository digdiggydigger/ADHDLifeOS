//
//  FirebaseAppDirectoryClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// The Firestore surface the app-directory provider uses — one method, per the house rule:
/// a narrow protocol `FirebaseManager` satisfies in one line, with a recording fake in tests.
protocol AppDirectoryBackingStore {
    func fetchAppDirectoryEntryObjects() async throws -> [[String: Any]]
}

extension FirebaseManager: AppDirectoryBackingStore {}

struct FirebaseAppDirectoryClientAdapter: AppDirectoryClientAdapting {
    let store: AppDirectoryBackingStore

    init(store: AppDirectoryBackingStore = FirebaseManager.shared) {
        self.store = store
    }

    func fetchRemoteEntryObjects() async throws -> [[String: Any]] {
        try await store.fetchAppDirectoryEntryObjects()
    }
}

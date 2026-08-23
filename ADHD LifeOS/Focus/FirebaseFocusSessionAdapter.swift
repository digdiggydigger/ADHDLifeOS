//
//  FirebaseFocusSessionAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `FocusSessionLogging` + history reader backed by Firestore through
/// `FocusSessionBackingStore` (`FirebaseManager` in the app, a recording fake in tests).
/// Writes land in `users/{uid}/focus_sessions`.
struct FirebaseFocusSessionAdapter: FocusSessionLogging, FocusHistoryReading {
    private let store: FocusSessionBackingStore

    init(store: FocusSessionBackingStore = FirebaseManager.shared) {
        self.store = store
    }

    func logCompletedSession(_ session: CompletedFocusSession) async throws {
        try await store.saveFocusSession(session)
    }

    func fetchHistory() async throws -> [CompletedFocusSession] {
        try await store.fetchFocusSessions()
    }
}

/// Read seam for the focus analytics views, mirroring `FocusSessionLogging` on the write side.
protocol FocusHistoryReading: Sendable {
    func fetchHistory() async throws -> [CompletedFocusSession]
}

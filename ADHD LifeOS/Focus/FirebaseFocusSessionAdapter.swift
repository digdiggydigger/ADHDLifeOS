//
//  FirebaseFocusSessionAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `FocusSessionLogging` + history reader backed by Firestore via `FirebaseManager`.
/// Writes land in `users/{uid}/focus_sessions`.
struct FirebaseFocusSessionAdapter: FocusSessionLogging, FocusHistoryReading {
    private let manager: FirebaseManager

    init(manager: FirebaseManager = .shared) {
        self.manager = manager
    }

    func logCompletedSession(_ session: CompletedFocusSession) async throws {
        try await manager.saveFocusSession(session)
    }

    func fetchHistory() async throws -> [CompletedFocusSession] {
        try await manager.fetchFocusSessions()
    }
}

/// Read seam for the focus analytics views, mirroring `FocusSessionLogging` on the write side.
protocol FocusHistoryReading: Sendable {
    func fetchHistory() async throws -> [CompletedFocusSession]
}

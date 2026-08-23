//
//  FirebaseManager+FocusSessions.swift
//  ADHD LifeOS
//

import FirebaseFirestore
import Foundation

extension FirebaseManager {
    /// Append-only in practice: a finished sprint is a historical fact, so nothing updates or
    /// deletes these — the weekly and trend analytics read them straight back.
    func saveFocusSession(_ session: CompletedFocusSession) async throws {
        try await save(session, id: session.id, in: .focusSessions)
    }

    /// Newest-first history, used by the focus analytics views.
    func fetchFocusSessions() async throws -> [CompletedFocusSession] {
        try await fetchAll(
            CompletedFocusSession.self, from: .focusSessions, orderedBy: "ended_at", descending: true
        )
    }
}

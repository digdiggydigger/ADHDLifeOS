//
//  FirebaseManager+Reminders.swift
//  ADHD LifeOS
//

import FirebaseFirestore
import Foundation

/// Reminders are DORMANT. The collection's Poke/DynamoDB source did not survive the Firebase
/// cutover, so `users/{uid}/reminders` starts empty and stays empty — the feature's files remain
/// compiled but unreachable from the UI (the tab was removed 2026-08-19). An empty result is the
/// expected state, not a failure.
extension FirebaseManager {
    /// `users/{uid}/reminders` starts empty and stays empty until something writes to it — an
    /// empty collection is the expected state, not an error.
    func fetchReminders() async throws -> [Reminder] {
        try await fetchAll(Reminder.self, from: .reminders)
    }
}

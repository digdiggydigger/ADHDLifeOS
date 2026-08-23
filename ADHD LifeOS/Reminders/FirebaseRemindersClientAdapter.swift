//
//  FirebaseRemindersClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `RemindersClientAdapting` backed by Firestore through `RemindersBackingStore`
/// (`FirebaseManager` in the app, a recording fake in tests). The old
/// implementation read Poke's external DynamoDB bridge; on the clean Firebase slate reminders
/// live in `users/{uid}/reminders`, which starts (and, until something writes to it, stays)
/// empty — the Reminders screen renders its empty state rather than 404ing. `Reminder`'s lenient
/// decoder is unchanged, so any future writer only needs `task_id`, `created`, and `type`.
struct FirebaseRemindersClientAdapter: RemindersClientAdapting {
    private let store: RemindersBackingStore

    init(store: RemindersBackingStore = FirebaseManager.shared) {
        self.store = store
    }

    func fetchReminders() async throws -> [Reminder] {
        do {
            return try await store.fetchReminders()
        } catch {
            throw RemindersServiceError.fetchFailed(Self.message(for: error))
        }
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}

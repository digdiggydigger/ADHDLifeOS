//
//  FirebaseRemindersClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `RemindersClientAdapting` backed by Firestore via `FirebaseManager`. The old
/// implementation read Poke's external DynamoDB bridge; on the clean Firebase slate reminders
/// live in `users/{uid}/reminders`, which starts (and, until something writes to it, stays)
/// empty — the Reminders screen renders its empty state rather than 404ing. `Reminder`'s lenient
/// decoder is unchanged, so any future writer only needs `task_id`, `created`, and `type`.
struct FirebaseRemindersClientAdapter: RemindersClientAdapting {
    private let manager: FirebaseManager

    init(manager: FirebaseManager = .shared) {
        self.manager = manager
    }

    func fetchReminders() async throws -> [Reminder] {
        do {
            return try await manager.fetchAll(Reminder.self, from: .reminders)
        } catch {
            throw RemindersServiceError.fetchFailed(Self.message(for: error))
        }
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}

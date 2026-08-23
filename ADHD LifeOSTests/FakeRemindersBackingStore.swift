//
//  FakeRemindersBackingStore.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

/// Recording stand-in for the Firestore surface behind `FirebaseRemindersClientAdapter`.
final class FakeRemindersBackingStore: RemindersBackingStore {
    var reminders: [Reminder] = []
    var fetchError: Error?

    private(set) var fetchCallCount = 0

    func fetchReminders() async throws -> [Reminder] {
        fetchCallCount += 1
        if let fetchError { throw fetchError }
        return reminders
    }
}

//
//  RemindersBackingStore.swift
//  ADHD LifeOS
//

import Foundation

/// The Firestore surface `FirebaseRemindersClientAdapter` uses. See `LifeAreaEditorBackingStore`
/// for why the seam exists and why it is one narrow protocol per adapter.
///
/// `fetchReminders` is a named wrapper over the manager's generic `fetchAll` so the store cannot
/// address another collection — and so the adapter no longer has to know that `Reminder` lives in
/// `.reminders`.
protocol RemindersBackingStore {
    func fetchReminders() async throws -> [Reminder]
}

extension FirebaseManager: RemindersBackingStore {}

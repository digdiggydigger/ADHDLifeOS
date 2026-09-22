//
//  RecentlyDeletedBackingStore.swift
//  ADHD LifeOS
//
//  The Firestore surface `FirebaseRecentlyDeletedClientAdapter` uses. See
//  `LifeAreaEditorBackingStore` for why the seam exists and why it is one narrow protocol per
//  adapter — `FirebaseManager` is a `final class` with a `private init`, so an adapter holding it
//  concretely could not be tested at any price.
//
//  **This is the one store that declares the hard delete**, and it declares it under a name that
//  cannot be reached by accident: nothing conforms to this protocol but `FirebaseManager`, and
//  nothing holds it but the adapter next door.
//

import Foundation

protocol RecentlyDeletedBackingStore {
    func fetchDeletedTasks() async throws -> [TaskItem]
    func fetchDeletedCaptures() async throws -> [Capture]
    func restoreTask(id: UUID) async throws
    func restoreCapture(id: UUID) async throws
    func deleteTask(id: UUID) async throws
    func deleteCapture(id: UUID) async throws
}

extension FirebaseManager: RecentlyDeletedBackingStore {}

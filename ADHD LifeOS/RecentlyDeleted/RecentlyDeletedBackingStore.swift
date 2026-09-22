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
    func fetchDeletedTags() async throws -> [Tag]
    func restoreTag(id: UUID) async throws
    /// **A tag's "delete forever" is the only one here that is not a document delete.** It is the
    /// batch today's tag delete used to run at the tap: strip this id from every referencing task
    /// and capture, then destroy the tag. A NAMED wrapper rather than exposing
    /// `removeTagEverywhere(_:replacingWith:)` on this seam — CLAUDE.md's rule — so a store that
    /// can purge cannot also silently MERGE one tag into another.
    func purgeTag(id: UUID) async throws
}

extension FirebaseManager: RecentlyDeletedBackingStore {}

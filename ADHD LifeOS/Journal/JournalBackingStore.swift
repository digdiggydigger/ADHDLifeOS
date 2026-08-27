//
//  JournalBackingStore.swift
//  ADHD LifeOS
//

import Foundation

/// The Firestore surface `FirebaseJournalClientAdapter` uses. See `LifeAreaEditorBackingStore` for
/// why the seam exists and why it is one narrow protocol per adapter.
///
/// Append-only stays structural for EDITS: there is deliberately no update path here, matching
/// `JournalClientAdapting` and the `logs` rule in `firestore.rules` (`allow update: if false`).
/// Delete is a different question and the rules already permit it — see `deleteLog`.
protocol JournalBackingStore {
    func fetchLifeAreas(includeArchived: Bool) async throws -> [LifeArea]
    func fetchLogs() async throws -> [Log]
    func fetchFocusSessions() async throws -> [CompletedFocusSession]
    func fetchCaptures() async throws -> [Capture]
    func fetchLocationEvents() async throws -> [LocationEvent]
    func fetchPlaces() async throws -> [Place]
    func fetchTags() async throws -> [Tag]
    func createTagDeduplicating(name: String) async throws -> Tag
    func appendLog(_ log: Log) async throws
    func deleteLog(id: UUID) async throws
}

extension FirebaseManager: JournalBackingStore {}

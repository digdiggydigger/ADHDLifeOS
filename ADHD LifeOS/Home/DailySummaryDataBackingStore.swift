//
//  DailySummaryDataBackingStore.swift
//  ADHD LifeOS
//

import Foundation

/// The five Firestore reads `FirebaseDailySummaryDataAdapter` folds into one summary request. See
/// `LifeAreaEditorBackingStore` for why the seam exists and why it is one narrow protocol per
/// adapter.
///
/// They are independent and run concurrently — in sequence the Generate button feels broken on a
/// slow connection. None of them may fail quietly: the on-device fallback rewords the day, it
/// cannot invent one, so a failed read has to fail the whole request rather than yield an empty day.
protocol DailySummaryDataBackingStore {
    func fetchTasks() async throws -> [TaskItem]
    func fetchLogs() async throws -> [Log]
    func fetchFocusSessions() async throws -> [CompletedFocusSession]
    func fetchCaptures() async throws -> [Capture]
    func fetchLifeAreas(includeArchived: Bool) async throws -> [LifeArea]
}

extension FirebaseManager: DailySummaryDataBackingStore {}

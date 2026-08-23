//
//  FocusSessionBackingStore.swift
//  ADHD LifeOS
//

import Foundation

/// The Firestore surface `FirebaseFocusSessionAdapter` uses. See `LifeAreaEditorBackingStore` for
/// why the seam exists and why it is one narrow protocol per adapter.
///
/// Append-only in practice: a finished sprint is a historical fact, so there is no update or delete
/// here — the weekly and trend analytics only ever read it back.
protocol FocusSessionBackingStore {
    func saveFocusSession(_ session: CompletedFocusSession) async throws
    func fetchFocusSessions() async throws -> [CompletedFocusSession]
}

extension FirebaseManager: FocusSessionBackingStore {}

//
//  FocusSessionBackingStore.swift
//  ADHD LifeOS
//

import Foundation

/// The Firestore surface `FirebaseFocusSessionAdapter` uses. See `LifeAreaEditorBackingStore` for
/// why the seam exists and why it is one narrow protocol per adapter.
///
/// **Not append-only since F-FocusCard-2, and the comment that stood here said it was.** A sprint
/// that finishes naturally is written once as it ends (provisional, `confirmed_at` nil) and then
/// RE-SAVED by Confirm with `confirmed_at` set — the same `id`, through this same `save`, which is
/// `setData` with no merge, i.e. a full upsert. That is why there is still no `update` method: the
/// re-save is deliberately not a partial write, because if the provisional write failed offline a
/// partial update against a document that was never created would throw, whereas the upsert
/// creates it. There is still no delete: history is never removed by the app, only finalised.
/// The weekly and trend analytics read every record back regardless of `confirmed_at` — banked
/// time is banked; the confirmation is a UI acknowledgement, not a data gate.
protocol FocusSessionBackingStore {
    func saveFocusSession(_ session: CompletedFocusSession) async throws
    func fetchFocusSessions() async throws -> [CompletedFocusSession]
}

extension FirebaseManager: FocusSessionBackingStore {}

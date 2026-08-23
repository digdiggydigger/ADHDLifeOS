//
//  NudgesBackingStore.swift
//  ADHD LifeOS
//

import Foundation

/// The Firestore surface `FirebaseNudgesClientAdapter` uses. See `LifeAreaEditorBackingStore` for
/// why the seam exists and why it is one narrow protocol per adapter.
///
/// Two update shapes, and both are needed: `payload` is the user's edit (server-stamped), `fields`
/// is `markFired`'s pinned client instant. See `FirestoreFieldPayloads.nudgeUpdate`/`nudgeFired`
/// for why the two clocks differ.
protocol NudgesBackingStore {
    func fetchNudges() async throws -> [Nudge]
    func fetchNudge(id: UUID) async throws -> Nudge
    func createNudge(_ nudge: Nudge) async throws
    func updateNudge(id: UUID, payload: NudgeUpdatePayload) async throws
    func updateNudge(id: UUID, fields: [String: Any]) async throws
}

extension FirebaseManager: NudgesBackingStore {}

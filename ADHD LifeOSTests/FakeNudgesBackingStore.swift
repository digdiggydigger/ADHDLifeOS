//
//  FakeNudgesBackingStore.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

/// Recording stand-in for the Firestore surface behind `FirebaseNudgesClientAdapter`.
///
/// `storedNudge` is what a re-read returns, and tests set it to something distinguishable from the
/// local edit so an echoed-back payload fails.
final class FakeNudgesBackingStore: NudgesBackingStore {
    var nudges: [Nudge] = []
    var storedNudge: Nudge?

    var fetchNudgesError: Error?
    var createError: Error?
    var updateError: Error?
    var fetchNudgeError: Error?

    private(set) var createdNudges: [Nudge] = []
    private(set) var payloadUpdates: [PayloadUpdate] = []
    private(set) var fieldUpdates: [FieldUpdate] = []
    private(set) var fetchedIds: [UUID] = []

    /// Named records rather than tuples — SwiftLint caps tuples at two members.
    struct PayloadUpdate {
        let id: UUID
        let payload: NudgeUpdatePayload
    }

    struct FieldUpdate {
        let id: UUID
        let fields: [String: Any]
    }

    func fetchNudges() async throws -> [Nudge] {
        if let fetchNudgesError { throw fetchNudgesError }
        return nudges
    }

    func createNudge(_ nudge: Nudge) async throws {
        createdNudges.append(nudge)
        if let createError { throw createError }
    }

    func updateNudge(id: UUID, payload: NudgeUpdatePayload) async throws {
        payloadUpdates.append(PayloadUpdate(id: id, payload: payload))
        if let updateError { throw updateError }
    }

    func updateNudge(id: UUID, fields: [String: Any]) async throws {
        fieldUpdates.append(FieldUpdate(id: id, fields: fields))
        if let updateError { throw updateError }
    }

    func fetchNudge(id: UUID) async throws -> Nudge {
        fetchedIds.append(id)
        if let fetchNudgeError { throw fetchNudgeError }
        guard let storedNudge else { throw FirebaseManagerError.notSignedIn }
        return storedNudge
    }
}

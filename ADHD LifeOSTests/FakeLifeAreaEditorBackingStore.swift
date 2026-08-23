//
//  FakeLifeAreaEditorBackingStore.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

/// Recording stand-in for the Firestore surface behind `FirebaseLifeAreaEditorClientAdapter`.
///
/// Sits one layer below `FakeLifeAreaEditorClientAdapting`, which fakes the adapter *for the
/// service*; this fakes Firestore *for the adapter*, so the adapter's own translation work — name
/// conflicts, sort-order assignment, error mapping, and the literal field keys it writes — is
/// finally reachable from a test.
///
/// Every call is recorded **before** any configured error is thrown, so a test can tell "was called
/// and failed" apart from "was never called". Assertions that no write happened depend on that
/// distinction.
final class FakeLifeAreaEditorBackingStore: LifeAreaEditorBackingStore {
    /// What `fetchLifeAreas` hands back when no error is configured.
    var areas: [LifeArea] = []

    var fetchError: Error?
    var saveError: Error?
    var updateError: Error?

    private(set) var includeArchivedArguments: [Bool] = []
    private(set) var savedAreas: [LifeArea] = []
    private(set) var updates: [(id: UUID, fields: [String: Any])] = []

    func fetchLifeAreas(includeArchived: Bool) async throws -> [LifeArea] {
        includeArchivedArguments.append(includeArchived)
        if let fetchError { throw fetchError }
        return areas
    }

    func saveLifeArea(_ area: LifeArea) async throws {
        savedAreas.append(area)
        if let saveError { throw saveError }
    }

    func updateLifeArea(id: UUID, fields: [String: Any]) async throws {
        updates.append((id: id, fields: fields))
        if let updateError { throw updateError }
    }
}

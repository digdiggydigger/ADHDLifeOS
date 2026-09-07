//
//  FakeAppDirectoryBackingStore.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

/// Recording stand-in for the Firestore surface behind `FirebaseAppDirectoryClientAdapter`.
///
/// The adapter it serves had **0% coverage** until 2026-09-07 — nothing anywhere instantiated it,
/// so the one hop it exists to perform was never exercised. That is why this fake records the
/// call COUNT as well as returning a value: the adapter's whole job is to delegate exactly once.
final class FakeAppDirectoryBackingStore: AppDirectoryBackingStore {
    var entryObjects: [[String: Any]] = []
    var fetchError: Error?

    private(set) var fetchCallCount = 0

    func fetchAppDirectoryEntryObjects() async throws -> [[String: Any]] {
        fetchCallCount += 1
        if let fetchError { throw fetchError }
        return entryObjects
    }
}

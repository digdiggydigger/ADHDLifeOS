//
//  FakeJournalBackingStore.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

/// Recording stand-in for the Firestore surface behind `FirebaseJournalClientAdapter`.
final class FakeJournalBackingStore: JournalBackingStore {
    var lifeAreas: [LifeArea] = []
    var logs: [Log] = []
    var focusSessions: [CompletedFocusSession] = []
    var captures: [Capture] = []

    var fetchLifeAreasError: Error?
    var fetchLogsError: Error?
    var fetchFocusSessionsError: Error?
    var fetchCapturesError: Error?
    var appendError: Error?

    private(set) var includeArchivedArguments: [Bool] = []
    private(set) var appendedLogs: [Log] = []

    func fetchLifeAreas(includeArchived: Bool) async throws -> [LifeArea] {
        includeArchivedArguments.append(includeArchived)
        if let fetchLifeAreasError { throw fetchLifeAreasError }
        return lifeAreas
    }

    func fetchLogs() async throws -> [Log] {
        if let fetchLogsError { throw fetchLogsError }
        return logs
    }

    func fetchFocusSessions() async throws -> [CompletedFocusSession] {
        if let fetchFocusSessionsError { throw fetchFocusSessionsError }
        return focusSessions
    }

    func fetchCaptures() async throws -> [Capture] {
        if let fetchCapturesError { throw fetchCapturesError }
        return captures
    }

    func appendLog(_ log: Log) async throws {
        appendedLogs.append(log)
        if let appendError { throw appendError }
    }
}

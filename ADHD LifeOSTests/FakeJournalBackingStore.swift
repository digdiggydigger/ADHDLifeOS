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
    var allTags: [Tag] = []
    var createTagResult = Tag(id: UUID(), name: "made-up")

    var fetchLifeAreasError: Error?
    var fetchLogsError: Error?
    var fetchFocusSessionsError: Error?
    var fetchCapturesError: Error?
    var fetchAllTagsError: Error?
    var createTagError: Error?
    var appendError: Error?

    private(set) var createdTagNames: [String] = []

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

    func fetchTags() async throws -> [Tag] {
        if let fetchAllTagsError { throw fetchAllTagsError }
        return allTags
    }

    func createTagDeduplicating(name: String) async throws -> Tag {
        createdTagNames.append(name)
        if let createTagError { throw createTagError }
        return createTagResult
    }

    func appendLog(_ log: Log) async throws {
        appendedLogs.append(log)
        if let appendError { throw appendError }
    }
}

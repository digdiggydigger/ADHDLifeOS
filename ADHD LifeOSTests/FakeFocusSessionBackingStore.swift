//
//  FakeFocusSessionBackingStore.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

/// Recording stand-in for the Firestore surface behind `FirebaseFocusSessionAdapter`.
final class FakeFocusSessionBackingStore: FocusSessionBackingStore {
    var history: [CompletedFocusSession] = []

    var saveError: Error?
    var fetchError: Error?

    private(set) var savedSessions: [CompletedFocusSession] = []
    private(set) var fetchCallCount = 0

    func saveFocusSession(_ session: CompletedFocusSession) async throws {
        savedSessions.append(session)
        if let saveError { throw saveError }
    }

    func fetchFocusSessions() async throws -> [CompletedFocusSession] {
        fetchCallCount += 1
        if let fetchError { throw fetchError }
        return history
    }
}

/// Recording stand-in for the five Firestore reads behind `FirebaseDailySummaryDataAdapter`.
final class FakeDailySummaryDataBackingStore: DailySummaryDataBackingStore {
    var tasks: [TaskItem] = []
    var logs: [Log] = []
    var focusSessions: [CompletedFocusSession] = []
    var captures: [Capture] = []
    var lifeAreas: [LifeArea] = []

    var tasksError: Error?
    var logsError: Error?
    var focusSessionsError: Error?
    var capturesError: Error?
    var lifeAreasError: Error?

    private(set) var tasksCallCount = 0
    private(set) var logsCallCount = 0
    private(set) var focusSessionsCallCount = 0
    private(set) var capturesCallCount = 0
    private(set) var includeArchivedArguments: [Bool] = []

    func fetchTasks() async throws -> [TaskItem] {
        tasksCallCount += 1
        if let tasksError { throw tasksError }
        return tasks
    }

    func fetchLogs() async throws -> [Log] {
        logsCallCount += 1
        if let logsError { throw logsError }
        return logs
    }

    func fetchFocusSessions() async throws -> [CompletedFocusSession] {
        focusSessionsCallCount += 1
        if let focusSessionsError { throw focusSessionsError }
        return focusSessions
    }

    func fetchCaptures() async throws -> [Capture] {
        capturesCallCount += 1
        if let capturesError { throw capturesError }
        return captures
    }

    func fetchLifeAreas(includeArchived: Bool) async throws -> [LifeArea] {
        includeArchivedArguments.append(includeArchived)
        if let lifeAreasError { throw lifeAreasError }
        return lifeAreas
    }
}

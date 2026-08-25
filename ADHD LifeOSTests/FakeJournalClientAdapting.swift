//
//  FakeJournalClientAdapting.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

final class FakeJournalClientAdapting: JournalClientAdapting, @unchecked Sendable {
    var lifeAreasResult: Result<[LifeArea], Error> = .success([])
    var logsResult: Result<[Log], Error> = .success([])
    var focusSessionsResult: Result<[CompletedFocusSession], Error> = .success([])
    var capturesResult: Result<[Capture], Error> = .success([])
    var createLogResult: Result<Log, Error>?

    private(set) var fetchLifeAreasCallCount = 0
    private(set) var fetchLogsCallCount = 0
    private(set) var fetchFocusSessionsCallCount = 0
    private(set) var fetchCapturesCallCount = 0
    private(set) var createLogCallCount = 0
    private(set) var lastCreateLogInput: NormalizedCreateLogInput?

    func fetchLifeAreas() async throws -> [LifeArea] {
        fetchLifeAreasCallCount += 1
        return try lifeAreasResult.get()
    }

    func fetchLogs() async throws -> [Log] {
        fetchLogsCallCount += 1
        return try logsResult.get()
    }

    func fetchFocusSessions() async throws -> [CompletedFocusSession] {
        fetchFocusSessionsCallCount += 1
        return try focusSessionsResult.get()
    }

    func fetchCaptures() async throws -> [Capture] {
        fetchCapturesCallCount += 1
        return try capturesResult.get()
    }

    func createLog(_ input: NormalizedCreateLogInput) async throws -> Log {
        createLogCallCount += 1
        lastCreateLogInput = input
        guard let result = createLogResult else {
            let now = Date()
            return Log(
                id: UUID(), lifeAreaId: input.lifeAreaId, type: input.type, body: input.body,
                entryDate: now, createdAt: now
            )
        }
        return try result.get()
    }
}

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
    var locationEventsResult: Result<[LocationEvent], Error> = .success([])
    var routineRunsResult: Result<[RoutineRunRecord], Error> = .success([])
    var placesResult: Result<[Place], Error> = .success([])
    var allTagsResult: Result<[Tag], Error> = .success([])
    var createTagResult: Result<Tag, Error> = .success(Tag(id: UUID(), name: "made-up"))
    var createLogResult: Result<Log, Error>?
    var deleteLogResult: Result<Void, Error> = .success(())
    /// Set alongside the capture fake's, so cross-seam call order is assertable.
    var callSequence: TriageCallSequence?

    private(set) var fetchLifeAreasCallCount = 0
    private(set) var fetchLogsCallCount = 0
    private(set) var fetchFocusSessionsCallCount = 0
    private(set) var fetchCapturesCallCount = 0
    private(set) var createLogCallCount = 0
    private(set) var lastCreateLogInput: NormalizedCreateLogInput?
    private(set) var lastDeleteLogId: UUID?
    private(set) var deleteLogCallOrder: Int?

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

    func fetchLocationEvents() async throws -> [LocationEvent] {
        try locationEventsResult.get()
    }

    func fetchRoutineRuns() async throws -> [RoutineRunRecord] {
        try routineRunsResult.get()
    }

    func fetchPlaces() async throws -> [Place] {
        try placesResult.get()
    }

    func fetchCaptures() async throws -> [Capture] {
        fetchCapturesCallCount += 1
        return try capturesResult.get()
    }

    func fetchAllTags() async throws -> [Tag] {
        try allTagsResult.get()
    }

    func createTag(name: String) async throws -> Tag {
        try createTagResult.get()
    }

    func deleteLog(id: UUID) async throws {
        lastDeleteLogId = id
        deleteLogCallOrder = callSequence?.next()
        try deleteLogResult.get()
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

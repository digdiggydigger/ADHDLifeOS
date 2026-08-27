//
//  FakeNudgesClientAdapting.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

final class FakeNudgesClientAdapting: NudgesClientAdapting, @unchecked Sendable {
    var fetchNudgesResult: Result<[Nudge], Error> = .success([])
    var createNudgeResult: Result<Nudge, Error>?
    var updateNudgeResult: Result<Nudge, Error>?
    var markFiredResult: Result<Nudge, Error>?

    private(set) var fetchNudgesCallCount = 0
    private(set) var createNudgeCallCount = 0
    private(set) var updateNudgeCallCount = 0
    private(set) var markFiredCallCount = 0
    private(set) var lastCreateNudgeArguments: (label: String, schedule: NudgeSchedule)?
    private(set) var lastUpdateNudgePayload: NudgeUpdatePayload?

    func fetchNudges() async throws -> [Nudge] {
        fetchNudgesCallCount += 1
        return try fetchNudgesResult.get()
    }

    func createNudge(label: String, schedule: NudgeSchedule) async throws -> Nudge {
        createNudgeCallCount += 1
        lastCreateNudgeArguments = (label, schedule)
        guard let result = createNudgeResult else {
            let now = Date()
            return Nudge(
                id: UUID(), label: label, schedule: schedule.encode(), active: true,
                lastFiredAt: nil, createdAt: now, updatedAt: now
            )
        }
        return try result.get()
    }

    func updateNudge(id: UUID, payload: NudgeUpdatePayload) async throws -> Nudge {
        updateNudgeCallCount += 1
        lastUpdateNudgePayload = payload
        guard let result = updateNudgeResult else {
            guard case .success(let existing) = fetchNudgesResult,
                  var updated = existing.first(where: { $0.id == id }) else {
                throw NudgesServiceError.notFound
            }
            if let label = payload.label { updated.label = label }
            if let schedule = payload.schedule { updated.schedule = schedule.encode() }
            if let active = payload.active { updated.active = active }
            return updated
        }
        return try result.get()
    }

    private(set) var lastMarkFiredExistingCompletionDates: [Date]?

    func markFired(id: UUID, existingCompletionDates: [Date]) async throws -> Nudge {
        markFiredCallCount += 1
        lastMarkFiredExistingCompletionDates = existingCompletionDates
        guard let result = markFiredResult else {
            guard case .success(let existing) = fetchNudgesResult,
                  var updated = existing.first(where: { $0.id == id }) else {
                throw NudgesServiceError.notFound
            }
            updated.lastFiredAt = Date()
            updated.completionDates = existingCompletionDates + [Date()]
            return updated
        }
        return try result.get()
    }
}

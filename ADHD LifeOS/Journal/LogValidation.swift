//
//  LogValidation.swift
//  ADHD LifeOS
//

import Foundation

enum LogValidationError: LocalizedError, Equatable {
    case emptyBody

    var errorDescription: String? {
        switch self {
        case .emptyBody:
            return "Log body must not be empty."
        }
    }
}

struct NormalizedCreateLogInput: Equatable, Sendable {
    let body: String
    let type: LogType
    let lifeAreaId: UUID?
    /// Journal entries only — see `normalizeCreateLogInput`.
    let energyLevel: EnergyLevel?
    let moodEmoji: String?
    /// Both types (E's 2026-08-25 note: "journal and logs") — unlike energy/mood.
    let tagIds: [UUID]
    /// Set by the service AFTER validation — location is not something to validate, and a missing
    /// stamp is never a reason to refuse an entry. Both types stamp: energy/mood are journal-only
    /// for web parity, but location has no web precedent to preserve. A `var` outside the init so
    /// every existing call site stays as it was.
    var locationStamp: LocationStamp?

    init(
        body: String,
        type: LogType,
        lifeAreaId: UUID?,
        energyLevel: EnergyLevel? = nil,
        moodEmoji: String? = nil,
        tagIds: [UUID] = []
    ) {
        self.body = body
        self.type = type
        self.lifeAreaId = lifeAreaId
        self.energyLevel = energyLevel
        self.moodEmoji = moodEmoji
        self.tagIds = tagIds
    }
}

/// Body trim/empty check only — mirrors web's `logService` validation, minus a `LogType` check.
/// Web validates `type` at runtime because JS has no enums (`isValidLogType` checks a string
/// array); Swift's `LogType` is a genuine 2-case `enum`, so an "invalid type" runtime check is
/// structurally impossible here. This is a simplification, not a scope cut.
enum LogValidation {
    /// Energy and mood are kept for a `.journal` entry and DROPPED for a quick `.log`.
    ///
    /// The web splits these into two types and puts both fields on `JournalEntry` alone; Swift
    /// unifies them behind `LogType`, so the rule has to live here instead of being enforced by the
    /// type system. A blank mood normalises to unset for the same reason an empty body is rejected:
    /// whitespace is not a reading.
    static func normalizeCreateLogInput(
        body: String,
        type: LogType,
        lifeAreaId: UUID?,
        energyLevel: EnergyLevel? = nil,
        moodEmoji: String? = nil,
        tagIds: [UUID] = []
    ) -> Result<NormalizedCreateLogInput, LogValidationError> {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failure(.emptyBody) }
        let trimmedMood = moodEmoji?.trimmingCharacters(in: .whitespacesAndNewlines)
        let isJournal = type == .journal
        return .success(
            NormalizedCreateLogInput(
                body: trimmed,
                type: type,
                lifeAreaId: lifeAreaId,
                energyLevel: isJournal ? energyLevel : nil,
                moodEmoji: isJournal ? trimmedMood.flatMap { $0.isEmpty ? nil : $0 } : nil,
                tagIds: tagIds
            )
        )
    }
}

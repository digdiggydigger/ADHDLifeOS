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
}

/// Body trim/empty check only — mirrors web's `logService` validation, minus a `LogType` check.
/// Web validates `type` at runtime because JS has no enums (`isValidLogType` checks a string
/// array); Swift's `LogType` is a genuine 2-case `enum`, so an "invalid type" runtime check is
/// structurally impossible here. This is a simplification, not a scope cut.
enum LogValidation {
    static func normalizeCreateLogInput(
        body: String,
        type: LogType,
        lifeAreaId: UUID?
    ) -> Result<NormalizedCreateLogInput, LogValidationError> {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failure(.emptyBody) }
        return .success(NormalizedCreateLogInput(body: trimmed, type: type, lifeAreaId: lifeAreaId))
    }
}

//
//  NudgeValidation.swift
//  ADHD LifeOS
//

import Foundation

enum NudgeValidationError: LocalizedError, Equatable {
    case emptyLabel
    case invalidSchedule

    var errorDescription: String? {
        switch self {
        case .emptyLabel:
            return "Nudge label must not be empty."
        case .invalidSchedule:
            return "Please select at least one day."
        }
    }
}

struct NormalizedCreateNudgeInput: Equatable, Sendable {
    let label: String
    let schedule: NudgeSchedule
}

/// Mirrors web's `normalizeCreateNudgeInput`/`normalizeUpdateNudgeInput` (trim, reject empty
/// label, reject an invalid schedule) — schedule validity here is "has at least one weekday
/// selected," since the time/weekday picker UI can only ever produce a valid hour/minute.
enum NudgeValidation {
    static func normalizeCreateNudgeInput(
        label: String,
        schedule: NudgeSchedule
    ) -> Result<NormalizedCreateNudgeInput, NudgeValidationError> {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failure(.emptyLabel) }
        guard !schedule.weekdays.isEmpty else { return .failure(.invalidSchedule) }
        return .success(NormalizedCreateNudgeInput(label: trimmed, schedule: schedule))
    }

    /// Diffs the edited label/schedule against the originally-fetched `Nudge` (parsing its raw
    /// `schedule` string for comparison) and only carries forward fields that actually changed,
    /// matching `normalizeUpdateNudgeInput`'s partial-update semantics. `active` isn't part of
    /// this form — it's toggled immediately, its own action.
    static func normalizeUpdateNudgeInput(
        original: Nudge,
        editedLabel: String,
        editedSchedule: NudgeSchedule
    ) -> Result<NudgeUpdatePayload, NudgeValidationError> {
        let trimmed = editedLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failure(.emptyLabel) }
        guard !editedSchedule.weekdays.isEmpty else { return .failure(.invalidSchedule) }

        var payload = NudgeUpdatePayload()
        if trimmed != original.label {
            payload.label = trimmed
        }
        if NudgeSchedule.parse(cronString: original.schedule) != editedSchedule {
            payload.schedule = editedSchedule
        }
        return .success(payload)
    }
}

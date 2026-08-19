//
//  TaskUpdateValidation.swift
//  ADHD LifeOS
//

import Foundation

/// Mirrors web's `normalizeUpdateTaskInput`: diffs the edited field values against the
/// originally-fetched `TaskDetail` and only carries forward the fields that actually changed,
/// so `TaskDetailService.save` sends a genuine partial update rather than the whole form.
enum TaskUpdateValidation {
    static func normalizeUpdateTaskInput(
        original: TaskDetail,
        edited: TaskEditedFields
    ) -> Result<TaskUpdatePayload, TaskCreateValidationError> {
        let trimmedTitle = edited.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return .failure(.emptyTitle) }

        let trimmedNotes = edited.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedNotes: String? = trimmedNotes.isEmpty ? nil : trimmedNotes

        var payload = TaskUpdatePayload()

        if trimmedTitle != original.title {
            payload.title = trimmedTitle
        }
        if normalizedNotes != original.notes {
            payload.notes = .some(normalizedNotes)
        }
        if edited.lifeAreaId != original.lifeAreaId {
            payload.lifeAreaId = .some(edited.lifeAreaId)
        }
        if edited.priority != original.priority {
            payload.priority = edited.priority
        }
        if edited.dueDate != original.dueDate {
            payload.dueDate = .some(edited.dueDate)
        }

        // Focus config diffs against the RESOLVED original, not the raw stored value: a legacy
        // task with no stored config resolves to the standard defaults, so staging exactly those
        // defaults is not an edit and must not manufacture a write.
        if let stagedDuration = edited.focusDurationSeconds {
            let clamped = FocusSprintConfiguration.clampDuration(stagedDuration)
            if clamped != FocusSprintConfiguration.resolvedDuration(explicit: original.focusDurationSeconds) {
                payload.focusDurationSeconds = clamped
            }
        }
        if let stagedNudges = edited.nudgesCount {
            let clamped = FocusSprintConfiguration.clampNudgeCount(stagedNudges)
            let originalResolved = FocusSprintConfiguration.resolvedNudgeCount(
                explicit: original.nudgesCount,
                durationSeconds: FocusSprintConfiguration.resolvedDuration(explicit: original.focusDurationSeconds)
            )
            if clamped != originalResolved {
                payload.nudgesCount = clamped
            }
        }

        return .success(payload)
    }
}

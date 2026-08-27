//
//  TaskUpdateValidation.swift
//  ADHD LifeOS
//

import Foundation

/// Mirrors web's `normalizeUpdateTaskInput`: diffs the edited field values against the
/// originally-fetched `TaskDetail` and only carries forward the fields that actually changed,
/// so `TaskDetailService.save` sends a genuine partial update rather than the whole form.
enum TaskUpdateValidation {
    /// `defaultSprintSeconds` is the Settings-chosen fallback the detail screen's planner seeded
    /// from (E's 2026-08-28 fix). It has to reach the focus diff below or the two disagree, and
    /// merely OPENING an untuned task reads as an edit.
    static func normalizeUpdateTaskInput(
        original: TaskDetail,
        edited: TaskEditedFields,
        defaultSprintSeconds: Int = FocusSprintConfiguration.defaultDurationSeconds
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
        if edited.atPlaceId != original.atPlaceId {
            payload.atPlaceId = .some(edited.atPlaceId)
        }

        applyFocusConfigDiff(
            from: edited, against: original, defaultSprintSeconds: defaultSprintSeconds, to: &payload
        )

        return .success(payload)
    }

    /// Focus config diffs against the RESOLVED original, not the raw stored value: a task with no
    /// stored config resolves to the fallback the planner opened at, so staging exactly that is
    /// not an edit and must not manufacture a write. Split out when the at-place diff pushed the
    /// main function over SwiftLint's complexity budget.
    private static func applyFocusConfigDiff(
        from edited: TaskEditedFields, against original: TaskDetail,
        defaultSprintSeconds: Int, to payload: inout TaskUpdatePayload
    ) {
        let originalDuration = FocusSprintConfiguration.resolvedDuration(
            explicit: original.focusDurationSeconds, defaultSeconds: defaultSprintSeconds
        )
        if let stagedDuration = edited.focusDurationSeconds {
            let clamped = FocusSprintConfiguration.clampDuration(stagedDuration)
            if clamped != originalDuration {
                payload.focusDurationSeconds = clamped
            }
        }
        if let stagedNudges = edited.nudgesCount {
            let clamped = FocusSprintConfiguration.clampNudgeCount(stagedNudges)
            let originalResolved = FocusSprintConfiguration.resolvedNudgeCount(
                explicit: original.nudgesCount, durationSeconds: originalDuration
            )
            if clamped != originalResolved {
                payload.nudgesCount = clamped
            }
        }
    }
}

//
//  TaskDetailDirtyState.swift
//  ADHD LifeOS
//

import Foundation

/// Answers the one fact `TaskDetailView` never used to know: has anything actually been edited?
///
/// It is a **pure** value type — no view, no service, no `UIKit` — so the whole staged-vs-saved
/// clarity behaviour (Save enablement, the discard-confirmation gate, the due-date notification
/// gate) is unit-testable without a simulator, matching the repo's established pattern for pure
/// decision types (`TaskGrouping`, `NudgeDueness`, `TaskCreateValidation`, `TaskUpdateValidation`).
///
/// Both questions it answers are needed and deliberately kept separate:
/// - `hasUnsavedChanges` — *any* of the five staged fields (title, notes, life area, priority,
///   due date) differs from the loaded task. Drives Save and the discard confirmation.
/// - `isDueDateDirty` — the due date *specifically* differs. Drives the Part 5 gate that disables
///   the immediate-apply notification controls while an unsaved due date would arm them against a
///   time the stored task does not have.
///
/// The comparison is delegated to `TaskUpdateValidation.normalizeUpdateTaskInput` rather than
/// re-derived, so the two can never drift: a field the engine calls "unsaved" is exactly a field
/// that Save would put in its payload. That is what makes trimmed-whitespace title churn and
/// `""`-vs-`nil` notes compare equal here for free — Save treats them as equal too.
struct TaskDetailDirtyState: Equatable {
    let hasUnsavedChanges: Bool
    let isDueDateDirty: Bool

    /// `defaultSprintSeconds` must be the same fallback the planner seeded from — see
    /// `TaskUpdateValidation.normalizeUpdateTaskInput`. Passing the wrong one makes an untouched
    /// screen read as edited.
    init(
        original: TaskDetail, edited: TaskEditedFields,
        defaultSprintSeconds: Int = FocusSprintConfiguration.defaultDurationSeconds
    ) {
        // Mirrors the payload's own due-date test (`edited.dueDate != original.dueDate`) — the
        // same equality Save uses to decide whether to send a new due date.
        isDueDateDirty = edited.dueDate != original.dueDate

        switch TaskUpdateValidation.normalizeUpdateTaskInput(
            original: original, edited: edited, defaultSprintSeconds: defaultSprintSeconds
        ) {
        case .success(let payload):
            hasUnsavedChanges = !payload.isEmpty
        case .failure:
            // The only failure is an empty/whitespace title. A loaded task always has a non-empty
            // title, so a title that trims to empty is itself an edit away from the stored value —
            // i.e. genuinely unsaved (and Save stays disabled on it via the empty-title guard).
            hasUnsavedChanges = true
        }
    }
}

//
//  TaskDetailAutosave.swift
//  ADHD LifeOS
//
//  `F-C2-DraftsToInbox`: when leaving task detail commits, and when it must not.
//
//  E, round 2: *"Task detail's blocking 'Discard changes?' becomes autosave with swipe-back
//  restored."* Q4: *"never block with a modal and never lose user input."*
//
//  Pure, and out of the view for the reason every rule in this app is: a SwiftUI body is ~0%
//  covered by design, so a rule left inside one is a rule nothing checks.
//

import Foundation

enum TaskDetailAutosave {
    /// Whether leaving the screen should commit the staged edits.
    ///
    /// **This is the Save button's own `disabled` clause, read in the positive** (see
    /// `TaskDetailFormSections.saveSection`), and the equivalence is the safety argument for
    /// deleting the discard gate rather than a tidy coincidence: backing out now performs exactly
    /// the write the user could already have made deliberately, so nothing NEW can reach the server
    /// by leaving. `testTheRuleIsTheSaveButtonsOwnEnabledConditionForEveryCombination` sweeps every
    /// combination of the three so the two cannot drift apart.
    ///
    /// **The empty title is the case that earns the guard.** Save has always been disabled on one,
    /// so before this block a user who cleared the title and backed out kept their task. If
    /// autosave committed it they would lose the task's name with no dialog, no confirmation and
    /// no undo — the one way deleting a blocking gate could have made something worse instead of
    /// better.
    static func shouldSave(hasUnsavedChanges: Bool, trimmedTitle: String, isSaving: Bool) -> Bool {
        guard hasUnsavedChanges, !isSaving else { return false }
        return !trimmedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

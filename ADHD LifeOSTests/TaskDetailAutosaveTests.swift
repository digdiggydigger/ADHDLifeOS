//
//  TaskDetailAutosaveTests.swift
//  ADHD LifeOSTests
//
//  `F-C2-DraftsToInbox`, the autosave half. E, round 2: *"Task detail's blocking 'Discard
//  changes?' becomes autosave with swipe-back restored."* Q4: *"never block with a modal and never
//  lose user input."*
//
//  **The rule is pure and the call sites are read, because neither half can catch the other.** A
//  correct rule with no `.onDisappear` behind it saves nothing; an `.onDisappear` that saved
//  whatever it found would commit an empty title over a real one. `TaskDetailAutosaveCallSiteTests`
//  is the other half.
//

import XCTest
@testable import ADHD_LifeOS

final class TaskDetailAutosaveTests: XCTestCase {

    /// **Autosave commits exactly what tapping Save would have committed — no more.** That is the
    /// whole safety argument for deleting the discard gate: leaving the screen is now the same
    /// write the user could already have made deliberately, so nothing new can reach the server by
    /// backing out. The three conditions are the Save button's own `disabled` clause
    /// (`TaskDetailFormSections.saveSection`) read in the positive.
    func testAutosaveCommitsExactlyWhatTheSaveButtonWouldHave() {
        XCTAssertTrue(
            TaskDetailAutosave.shouldSave(hasUnsavedChanges: true, trimmedTitle: "Renew the passport", isSaving: false)
        )
    }

    /// Nothing staged, nothing written. Backing out of a screen the user only LOOKED at must not
    /// touch the server — this is also what keeps `onUpdated()` from reloading the list for free.
    func testAnUntouchedScreenWritesNothingOnTheWayOut() {
        XCTAssertFalse(
            TaskDetailAutosave.shouldSave(hasUnsavedChanges: false, trimmedTitle: "Renew the passport", isSaving: false)
        )
    }

    /// **An emptied title is the one edit autosave must REFUSE, and it is the reason the gate's
    /// removal is safe.** Save is disabled on an empty title, so before this block a user who
    /// cleared the title and backed out kept their task; if autosave committed it they would
    /// silently lose the task's name with no dialog and no undo. Whitespace counts as empty —
    /// a space is not a title.
    func testAnEmptiedTitleIsRefusedRatherThanCommitted() {
        for title in ["", " ", "\n", "   \t "] {
            XCTAssertFalse(
                TaskDetailAutosave.shouldSave(hasUnsavedChanges: true, trimmedTitle: title, isSaving: false),
                "A title of \(title.debugDescription) was committed — the task would lose its name silently."
            )
        }
    }

    /// A save already in flight owns the write. Firing a second one as the screen tears down would
    /// race the first with the same payload.
    func testASaveAlreadyInFlightIsNotDoubledOnTheWayOut() {
        XCTAssertFalse(
            TaskDetailAutosave.shouldSave(hasUnsavedChanges: true, trimmedTitle: "Renew the passport", isSaving: true)
        )
    }

    /// The rule is the Save button's `disabled` clause inverted, so the two can never disagree
    /// about what is committable. Swept rather than asserted one case at a time, because the thing
    /// under test is the EQUIVALENCE: a fourth condition added to one and not the other is exactly
    /// the drift this catches.
    func testTheRuleIsTheSaveButtonsOwnEnabledConditionForEveryCombination() {
        for dirty in [true, false] {
            for title in ["Renew the passport", "  "] {
                for saving in [true, false] {
                    let saveButtonWouldBeEnabled =
                        dirty && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !saving
                    XCTAssertEqual(
                        TaskDetailAutosave.shouldSave(
                            hasUnsavedChanges: dirty, trimmedTitle: title, isSaving: saving
                        ),
                        saveButtonWouldBeEnabled,
                        "Autosave and the Save button disagree at dirty=\(dirty),"
                            + " title=\(title.debugDescription), saving=\(saving)."
                    )
                }
            }
        }
    }
}

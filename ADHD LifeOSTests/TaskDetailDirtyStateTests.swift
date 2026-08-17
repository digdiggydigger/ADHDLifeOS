//
//  TaskDetailDirtyStateTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Unit coverage for the pure dirty-state engine that drives Save enablement (Part 2), the
/// discard-confirmation gate (Part 4) and the due-date notification gate (Part 5). It must mirror
/// `TaskUpdateValidation.normalizeUpdateTaskInput`'s comparison semantics exactly, so a change the
/// engine reports as "unsaved" is precisely a change `TaskDetailService.save` would actually send.
final class TaskDetailDirtyStateTests: XCTestCase {

    private func makeOriginal(
        title: String = "Original title",
        notes: String? = "Original notes",
        lifeAreaId: UUID? = nil,
        priority: TaskPriority = .p3,
        dueDate: Date? = nil
    ) -> TaskDetail {
        TaskDetail(
            id: UUID(),
            lifeAreaId: lifeAreaId,
            title: title,
            notes: notes,
            status: .open,
            priority: priority,
            dueDate: dueDate,
            createdAt: Date()
        )
    }

    private func editedFields(matching original: TaskDetail) -> TaskEditedFields {
        TaskEditedFields(
            title: original.title,
            notes: original.notes ?? "",
            lifeAreaId: original.lifeAreaId,
            priority: original.priority,
            dueDate: original.dueDate
        )
    }

    // MARK: - Clean

    func testNoEdits_isNotDirty() {
        let original = makeOriginal()

        let state = TaskDetailDirtyState(original: original, edited: editedFields(matching: original))

        XCTAssertFalse(state.hasUnsavedChanges)
        XCTAssertFalse(state.isDueDateDirty)
    }

    // MARK: - Each of the five staged fields, edited individually

    func testTitleEdited_isDirty_butNotDueDateDirty() {
        let original = makeOriginal()
        var edited = editedFields(matching: original)
        edited.title = "A different title"

        let state = TaskDetailDirtyState(original: original, edited: edited)

        XCTAssertTrue(state.hasUnsavedChanges)
        XCTAssertFalse(state.isDueDateDirty)
    }

    func testNotesEdited_isDirty_butNotDueDateDirty() {
        let original = makeOriginal(notes: "Original notes")
        var edited = editedFields(matching: original)
        edited.notes = "Rewritten notes"

        let state = TaskDetailDirtyState(original: original, edited: edited)

        XCTAssertTrue(state.hasUnsavedChanges)
        XCTAssertFalse(state.isDueDateDirty)
    }

    func testLifeAreaEdited_isDirty_butNotDueDateDirty() {
        let original = makeOriginal(lifeAreaId: nil)
        var edited = editedFields(matching: original)
        edited.lifeAreaId = UUID()

        let state = TaskDetailDirtyState(original: original, edited: edited)

        XCTAssertTrue(state.hasUnsavedChanges)
        XCTAssertFalse(state.isDueDateDirty)
    }

    func testPriorityEdited_isDirty_butNotDueDateDirty() {
        let original = makeOriginal(priority: .p3)
        var edited = editedFields(matching: original)
        edited.priority = .p1

        let state = TaskDetailDirtyState(original: original, edited: edited)

        XCTAssertTrue(state.hasUnsavedChanges)
        XCTAssertFalse(state.isDueDateDirty)
    }

    func testDueDateEdited_isDirty_andDueDateDirty() {
        let original = makeOriginal(dueDate: nil)
        var edited = editedFields(matching: original)
        edited.dueDate = Date(timeIntervalSince1970: 1_700_000_000)

        let state = TaskDetailDirtyState(original: original, edited: edited)

        XCTAssertTrue(state.hasUnsavedChanges)
        XCTAssertTrue(state.isDueDateDirty)
    }

    // MARK: - Edit then manually revert → clean again

    func testFieldEditedThenRevertedToOriginal_isNotDirty() {
        let original = makeOriginal(title: "Original title")
        var edited = editedFields(matching: original)
        edited.title = "Changed"
        XCTAssertTrue(TaskDetailDirtyState(original: original, edited: edited).hasUnsavedChanges)

        edited.title = "Original title" // reverted by hand

        let state = TaskDetailDirtyState(original: original, edited: edited)
        XCTAssertFalse(state.hasUnsavedChanges)
        XCTAssertFalse(state.isDueDateDirty)
    }

    // MARK: - Whitespace-only churn on the title must not register as an edit

    func testWhitespaceOnlyTitleChurn_isNotDirty() {
        let original = makeOriginal(title: "Buy milk")
        var edited = editedFields(matching: original)
        edited.title = "  Buy milk  " // typed a space, will be trimmed on save — not a real change

        let state = TaskDetailDirtyState(original: original, edited: edited)

        XCTAssertFalse(state.hasUnsavedChanges)
        XCTAssertFalse(state.isDueDateDirty)
    }

    // MARK: - notes "" vs nil equivalence

    func testEmptyStringNotesAgainstNilNotes_isNotDirty() {
        let original = makeOriginal(notes: nil)
        var edited = editedFields(matching: original)
        edited.notes = "" // an empty field is equivalent to nil notes, so not a change

        let state = TaskDetailDirtyState(original: original, edited: edited)

        XCTAssertFalse(state.hasUnsavedChanges)
    }

    func testWhitespaceOnlyNotesAgainstNilNotes_isNotDirty() {
        let original = makeOriginal(notes: nil)
        var edited = editedFields(matching: original)
        edited.notes = "   " // trims to empty → nil → equal to original nil notes

        let state = TaskDetailDirtyState(original: original, edited: edited)

        XCTAssertFalse(state.hasUnsavedChanges)
    }

    // MARK: - due date set then cleared

    func testDueDateSetThenClearedBackToOriginalNil_isNotDirty() {
        let original = makeOriginal(dueDate: nil)
        var edited = editedFields(matching: original)
        edited.dueDate = Date(timeIntervalSince1970: 1_700_000_000)
        XCTAssertTrue(TaskDetailDirtyState(original: original, edited: edited).isDueDateDirty)

        edited.dueDate = nil // cleared back to the stored value

        let state = TaskDetailDirtyState(original: original, edited: edited)
        XCTAssertFalse(state.hasUnsavedChanges)
        XCTAssertFalse(state.isDueDateDirty)
    }

    func testDueDateClearedFromStoredValue_isDueDateDirty() {
        let original = makeOriginal(dueDate: Date(timeIntervalSince1970: 1_700_000_000))
        var edited = editedFields(matching: original)
        edited.dueDate = nil

        let state = TaskDetailDirtyState(original: original, edited: edited)

        XCTAssertTrue(state.hasUnsavedChanges)
        XCTAssertTrue(state.isDueDateDirty)
    }

    // MARK: - Title cleared to empty (the normalize failure branch) still reads as unsaved

    func testTitleClearedToWhitespace_isDirty() {
        let original = makeOriginal(title: "Buy milk")
        var edited = editedFields(matching: original)
        edited.title = "   " // cleared — normalizeUpdateTaskInput fails on empty title

        let state = TaskDetailDirtyState(original: original, edited: edited)

        XCTAssertTrue(state.hasUnsavedChanges, "Clearing the title away from its stored value is an unsaved change")
    }

    // MARK: - isDueDateDirty is true ONLY for a due-date change

    func testNonDueDateEdit_leavesDueDateDirtyFalse_evenWhenOtherFieldsChange() {
        let original = makeOriginal(dueDate: Date(timeIntervalSince1970: 1_700_000_000))
        var edited = editedFields(matching: original)
        edited.title = "New title"
        edited.priority = .p1
        edited.notes = "New notes"
        // dueDate deliberately left equal to the stored value

        let state = TaskDetailDirtyState(original: original, edited: edited)

        XCTAssertTrue(state.hasUnsavedChanges)
        XCTAssertFalse(state.isDueDateDirty)
    }
}

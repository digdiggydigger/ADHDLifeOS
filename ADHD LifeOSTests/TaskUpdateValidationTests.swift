//
//  TaskUpdateValidationTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class TaskUpdateValidationTests: XCTestCase {

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

    func testNormalizeUpdateTaskInput_emptyTitle_fails() {
        let original = makeOriginal()
        var edited = editedFields(matching: original)
        edited.title = "   "

        let result = TaskUpdateValidation.normalizeUpdateTaskInput(original: original, edited: edited)

        XCTAssertEqual(result, .failure(.emptyTitle))
    }

    func testNormalizeUpdateTaskInput_noFieldsChanged_returnsEmptyPayload() {
        let original = makeOriginal()

        let result = TaskUpdateValidation.normalizeUpdateTaskInput(
            original: original, edited: editedFields(matching: original)
        )

        switch result {
        case .success(let payload):
            XCTAssertTrue(payload.isEmpty)
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testNormalizeUpdateTaskInput_onlyTitleChanged_payloadContainsOnlyTitle() {
        let original = makeOriginal()
        var edited = editedFields(matching: original)
        edited.title = "  Updated title  "

        let result = TaskUpdateValidation.normalizeUpdateTaskInput(original: original, edited: edited)

        switch result {
        case .success(let payload):
            XCTAssertEqual(payload.title, "Updated title")
            XCTAssertNil(payload.notes)
            XCTAssertNil(payload.lifeAreaId)
            XCTAssertNil(payload.priority)
            XCTAssertNil(payload.dueDate)
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testNormalizeUpdateTaskInput_notesClearedToEmpty_payloadHasExplicitNil() {
        let original = makeOriginal(notes: "Something")
        var edited = editedFields(matching: original)
        edited.notes = "   "

        let result = TaskUpdateValidation.normalizeUpdateTaskInput(original: original, edited: edited)

        switch result {
        case .success(let payload):
            XCTAssertEqual(payload.notes, .some(nil))
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testNormalizeUpdateTaskInput_lifeAreaIdChanged_payloadContainsNewValue() {
        let original = makeOriginal(lifeAreaId: nil)
        let newLifeAreaId = UUID()
        var edited = editedFields(matching: original)
        edited.lifeAreaId = newLifeAreaId

        let result = TaskUpdateValidation.normalizeUpdateTaskInput(original: original, edited: edited)

        switch result {
        case .success(let payload):
            XCTAssertEqual(payload.lifeAreaId, .some(newLifeAreaId))
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testNormalizeUpdateTaskInput_priorityChanged_payloadContainsNewPriority() {
        let original = makeOriginal(priority: .p3)
        var edited = editedFields(matching: original)
        edited.priority = .p1

        let result = TaskUpdateValidation.normalizeUpdateTaskInput(original: original, edited: edited)

        switch result {
        case .success(let payload):
            XCTAssertEqual(payload.priority, .p1)
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testNormalizeUpdateTaskInput_dueDateCleared_payloadHasExplicitNil() {
        let original = makeOriginal(dueDate: Date())
        var edited = editedFields(matching: original)
        edited.dueDate = nil

        let result = TaskUpdateValidation.normalizeUpdateTaskInput(original: original, edited: edited)

        switch result {
        case .success(let payload):
            XCTAssertEqual(payload.dueDate, .some(nil))
        case .failure:
            XCTFail("Expected success")
        }
    }

    // MARK: - Focus sprint config (duration + nudge count)

    func testNormalizeUpdateTaskInput_focusFieldsUntouched_payloadStaysEmpty() {
        let original = makeOriginal()

        let result = TaskUpdateValidation.normalizeUpdateTaskInput(
            original: original, edited: editedFields(matching: original)
        )

        switch result {
        case .success(let payload):
            XCTAssertNil(payload.focusDurationSeconds)
            XCTAssertNil(payload.nudgesCount)
            XCTAssertTrue(payload.isEmpty)
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testNormalizeUpdateTaskInput_stagedDefaultsOverNilOriginal_writeNothing() {
        // A task with no stored config resolves to 15m / 2 nudges; staging exactly those
        // resolved defaults is not an edit, so Save must not manufacture a write.
        let original = makeOriginal()
        var edited = editedFields(matching: original)
        edited.focusDurationSeconds = 900
        edited.nudgesCount = 2

        let result = TaskUpdateValidation.normalizeUpdateTaskInput(original: original, edited: edited)

        switch result {
        case .success(let payload):
            XCTAssertTrue(payload.isEmpty)
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testNormalizeUpdateTaskInput_focusDurationChanged_payloadCarriesClampedValue() {
        let original = makeOriginal()
        var edited = editedFields(matching: original)
        edited.focusDurationSeconds = 300

        let result = TaskUpdateValidation.normalizeUpdateTaskInput(original: original, edited: edited)

        switch result {
        case .success(let payload):
            XCTAssertEqual(payload.focusDurationSeconds, 300)
            XCTAssertNil(payload.nudgesCount)
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testNormalizeUpdateTaskInput_focusDurationBelowFloor_clampsToThirtySeconds() {
        let original = makeOriginal()
        var edited = editedFields(matching: original)
        edited.focusDurationSeconds = 4

        let result = TaskUpdateValidation.normalizeUpdateTaskInput(original: original, edited: edited)

        switch result {
        case .success(let payload):
            XCTAssertEqual(payload.focusDurationSeconds, 30)
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testNormalizeUpdateTaskInput_nudgesCountChanged_payloadCarriesClampedValue() {
        let original = makeOriginal()
        var edited = editedFields(matching: original)
        edited.nudgesCount = 99

        let result = TaskUpdateValidation.normalizeUpdateTaskInput(original: original, edited: edited)

        switch result {
        case .success(let payload):
            XCTAssertEqual(payload.nudgesCount, 10)
            XCTAssertNil(payload.focusDurationSeconds)
        case .failure:
            XCTFail("Expected success")
        }
    }
}

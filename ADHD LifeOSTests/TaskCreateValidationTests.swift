//
//  TaskCreateValidationTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class TaskCreateValidationTests: XCTestCase {

    func testNormalizeCreateTaskInput_trimsTitleAndDefaultsPriorityToP4() {
        let result = TaskCreateValidation.normalizeCreateTaskInput(
            title: "  Buy milk  ", notes: nil, lifeAreaId: nil, dueDate: nil
        )

        switch result {
        case .success(let normalized):
            XCTAssertEqual(normalized.title, "Buy milk")
            XCTAssertEqual(normalized.priority, .p4)
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testNormalizeCreateTaskInput_emptyTitle_fails() {
        let result = TaskCreateValidation.normalizeCreateTaskInput(
            title: "   ", notes: nil, lifeAreaId: nil, dueDate: nil
        )

        XCTAssertEqual(result, .failure(.emptyTitle))
    }

    func testNormalizeCreateTaskInput_emptyNotes_normalizesToNil() {
        let result = TaskCreateValidation.normalizeCreateTaskInput(
            title: "Task", notes: "   ", lifeAreaId: nil, dueDate: nil
        )

        switch result {
        case .success(let normalized):
            XCTAssertNil(normalized.notes)
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testNormalizeCreateTaskInput_trimsNotes_whenNonEmpty() {
        let result = TaskCreateValidation.normalizeCreateTaskInput(
            title: "Task", notes: "  Some notes  ", lifeAreaId: nil, dueDate: nil
        )

        switch result {
        case .success(let normalized):
            XCTAssertEqual(normalized.notes, "Some notes")
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testNormalizeCreateTaskInput_lifeAreaIdAndDueDate_passThroughWhenProvided() {
        let lifeAreaId = UUID()
        let dueDate = Date()

        let result = TaskCreateValidation.normalizeCreateTaskInput(
            title: "Task", notes: nil, lifeAreaId: lifeAreaId, dueDate: dueDate
        )

        switch result {
        case .success(let normalized):
            XCTAssertEqual(normalized.lifeAreaId, lifeAreaId)
            XCTAssertEqual(normalized.dueDate, dueDate)
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testNormalizeCreateTaskInput_lifeAreaIdAndDueDate_areNilWhenOmitted() {
        let result = TaskCreateValidation.normalizeCreateTaskInput(
            title: "Task", notes: nil, lifeAreaId: nil, dueDate: nil
        )

        switch result {
        case .success(let normalized):
            XCTAssertNil(normalized.lifeAreaId)
            XCTAssertNil(normalized.dueDate)
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testNormalizeCreateTagInput_trimsName() {
        let result = TaskCreateValidation.normalizeCreateTagInput(name: "  urgent  ")

        XCTAssertEqual(result, .success("urgent"))
    }

    func testNormalizeCreateTagInput_emptyName_fails() {
        let result = TaskCreateValidation.normalizeCreateTagInput(name: "   ")

        XCTAssertEqual(result, .failure(.emptyTagName))
    }
}

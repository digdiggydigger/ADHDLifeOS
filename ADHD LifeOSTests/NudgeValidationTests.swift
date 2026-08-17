//
//  NudgeValidationTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class NudgeValidationTests: XCTestCase {

    private let dailyAt9 = NudgeSchedule(hour: 9, minute: 0, weekdays: Set(0...6))

    private func makeNudge(
        label: String = "Morning check-in",
        schedule: String = "0 9 * * *"
    ) -> Nudge {
        let now = Date()
        return Nudge(
            id: UUID(), label: label, schedule: schedule, active: true,
            lastFiredAt: nil, createdAt: now, updatedAt: now
        )
    }

    // MARK: normalizeCreateNudgeInput

    func testCreate_trimsLabel() {
        let result = NudgeValidation.normalizeCreateNudgeInput(label: "  Drink water  ", schedule: dailyAt9)

        guard case .success(let normalized) = result else {
            return XCTFail("Expected success")
        }
        XCTAssertEqual(normalized.label, "Drink water")
    }

    func testCreate_emptyLabel_isRejected() {
        let result = NudgeValidation.normalizeCreateNudgeInput(label: "   ", schedule: dailyAt9)

        XCTAssertEqual(result, .failure(.emptyLabel))
    }

    func testCreate_zeroWeekdaysSelected_isRejected() {
        let result = NudgeValidation.normalizeCreateNudgeInput(
            label: "Drink water", schedule: NudgeSchedule(hour: 9, minute: 0, weekdays: [])
        )

        XCTAssertEqual(result, .failure(.invalidSchedule))
    }

    func testCreate_arbitrarySchedule_isAccepted() {
        let schedule = NudgeSchedule(hour: 8, minute: 0, weekdays: [2, 4])
        let result = NudgeValidation.normalizeCreateNudgeInput(label: "Drink water", schedule: schedule)

        guard case .success(let normalized) = result else {
            return XCTFail("Expected success")
        }
        XCTAssertEqual(normalized.schedule, schedule)
    }

    // MARK: normalizeUpdateNudgeInput

    func testUpdate_onlyChangedFields_arePopulated() {
        let original = makeNudge(label: "Original", schedule: "0 9 * * *")

        let result = NudgeValidation.normalizeUpdateNudgeInput(
            original: original, editedLabel: "Updated", editedSchedule: dailyAt9
        )

        guard case .success(let payload) = result else {
            return XCTFail("Expected success")
        }
        XCTAssertEqual(payload.label, "Updated")
        XCTAssertNil(payload.schedule, "Schedule did not change, should be omitted")
    }

    func testUpdate_noChangedFields_returnsEmptyPayload() {
        let original = makeNudge(label: "Same", schedule: "0 9 * * *")

        let result = NudgeValidation.normalizeUpdateNudgeInput(
            original: original, editedLabel: "Same", editedSchedule: dailyAt9
        )

        guard case .success(let payload) = result else {
            return XCTFail("Expected success")
        }
        XCTAssertTrue(payload.isEmpty)
    }

    func testUpdate_scheduleNormalizesButIsSemanticallyUnchanged_omitsSchedule() {
        // Original was written as a range ("1-5"); editing without changing anything produces the
        // same weekday set, just re-encoded as a sorted list on save — should still be a no-op.
        let original = makeNudge(label: "Same", schedule: "0 9 * * 1-5")

        let result = NudgeValidation.normalizeUpdateNudgeInput(
            original: original,
            editedLabel: "Same",
            editedSchedule: NudgeSchedule(hour: 9, minute: 0, weekdays: [1, 2, 3, 4, 5])
        )

        guard case .success(let payload) = result else {
            return XCTFail("Expected success")
        }
        XCTAssertNil(payload.schedule, "Semantically identical schedule should be omitted")
    }

    func testUpdate_emptyLabel_isRejected() {
        let original = makeNudge()

        let result = NudgeValidation.normalizeUpdateNudgeInput(
            original: original, editedLabel: "   ", editedSchedule: dailyAt9
        )

        XCTAssertEqual(result, .failure(.emptyLabel))
    }

    func testUpdate_zeroWeekdaysSelected_isRejected() {
        let original = makeNudge()

        let result = NudgeValidation.normalizeUpdateNudgeInput(
            original: original,
            editedLabel: original.label,
            editedSchedule: NudgeSchedule(hour: 9, minute: 0, weekdays: [])
        )

        XCTAssertEqual(result, .failure(.invalidSchedule))
    }

    func testUpdate_bothFieldsChanged_bothPopulated() {
        let original = makeNudge(label: "Original", schedule: "0 9 * * *")
        let newSchedule = NudgeSchedule(hour: 9, minute: 0, weekdays: [1])

        let result = NudgeValidation.normalizeUpdateNudgeInput(
            original: original, editedLabel: "Updated", editedSchedule: newSchedule
        )

        guard case .success(let payload) = result else {
            return XCTFail("Expected success")
        }
        XCTAssertEqual(payload.label, "Updated")
        XCTAssertEqual(payload.schedule, newSchedule)
    }

    func testUpdate_unparsableOriginalSchedule_treatsAnyValidEditAsAChange() {
        // A schedule created by another client outside the supported subset (e.g. day-of-month)
        // doesn't parse; any structured edit from the picker should still be treated as a change.
        let original = makeNudge(label: "Original", schedule: "0 9 1 * *")

        let result = NudgeValidation.normalizeUpdateNudgeInput(
            original: original, editedLabel: "Original", editedSchedule: dailyAt9
        )

        guard case .success(let payload) = result else {
            return XCTFail("Expected success")
        }
        XCTAssertEqual(payload.schedule, dailyAt9)
    }
}

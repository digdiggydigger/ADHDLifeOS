//
//  FocusCadenceDraftTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The live cadence editor's pure state, ported from the web modal's in-session nudge config
/// (`showConfig` block in `src/components/FocusTimerBar.tsx`): mode toggle, seconds/minutes unit,
/// the 30-second interval floor, and the 1–5 nudge-count choices.
final class FocusCadenceDraftTests: XCTestCase {
    // MARK: - Seeding from the running sprint

    func testSeed_fromCountCadence() {
        let sut = FocusCadenceDraft(cadence: .count(3))

        XCTAssertEqual(sut.mode, .count)
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.resolvedCadence, .count(3))
    }

    func testSeed_fromSecondsIntervalCadence() {
        let sut = FocusCadenceDraft(cadence: .interval(seconds: 45))

        XCTAssertEqual(sut.mode, .interval)
        XCTAssertEqual(sut.intervalUnit, .seconds)
        XCTAssertEqual(sut.intervalValue, 45)
        XCTAssertEqual(sut.resolvedCadence, .interval(seconds: 45))
    }

    func testSeed_fromWholeMinuteIntervalCadence_prefersMinutes() {
        let sut = FocusCadenceDraft(cadence: .interval(seconds: 300))

        XCTAssertEqual(sut.intervalUnit, .minutes)
        XCTAssertEqual(sut.intervalValue, 5)
        XCTAssertEqual(sut.resolvedCadence, .interval(seconds: 300))
    }

    func testSeed_carriesUsableDefaultsForTheUnselectedMode() {
        // Switching modes in the sheet must never land on a nonsense value, so the seed fills both
        // sides — the web keeps two independent `useState`s for exactly this reason.
        var fromCount = FocusCadenceDraft(cadence: .count(4))
        fromCount.mode = .interval
        XCTAssertEqual(fromCount.resolvedCadence, .interval(seconds: FocusCheckpoints.minimumIntervalSeconds))

        var fromInterval = FocusCadenceDraft(cadence: .interval(seconds: 60))
        fromInterval.mode = .count
        XCTAssertEqual(fromInterval.resolvedCadence, .count(1))
    }

    // MARK: - Resolution rules

    func testResolve_convertsMinutesToSeconds() {
        var sut = FocusCadenceDraft(cadence: .interval(seconds: 30))
        sut.intervalUnit = .minutes
        sut.intervalValue = 2

        XCTAssertEqual(sut.resolvedCadence, .interval(seconds: 120))
    }

    func testResolve_floorsTheIntervalAtThirtySeconds() {
        var sut = FocusCadenceDraft(cadence: .interval(seconds: 30))
        sut.intervalValue = 5

        XCTAssertEqual(sut.resolvedCadence, .interval(seconds: 30), "the web's Math.max(30, …) floor")
    }

    func testResolve_clampsANegativeCountToZero() {
        var sut = FocusCadenceDraft(cadence: .count(2))
        sut.count = -3

        XCTAssertEqual(sut.resolvedCadence, .count(0), "the web's Math.max(0, countVal)")
    }

    func testResolve_clampsCountToThePerTaskMaximum() {
        var sut = FocusCadenceDraft(cadence: .count(2))
        sut.count = 25

        XCTAssertEqual(
            sut.resolvedCadence, .count(FocusSprintConfiguration.maximumNudgeCount),
            "the editor can't schedule more nudges than the per-task planner allows"
        )
    }

    func testSeed_keepsACountAboveTheChipChoices() {
        // E's own task runs 10 nudges — more than the 1–5 quick chips can express, so the draft
        // must carry it verbatim rather than snapping down to a chip value.
        let sut = FocusCadenceDraft(cadence: .count(10))

        XCTAssertEqual(sut.count, 10)
        XCTAssertEqual(sut.resolvedCadence, .count(10))
    }

    // MARK: - Unit switching

    func testSelectSecondsUnit_liftsASubFloorValueToThirty() {
        var sut = FocusCadenceDraft(cadence: .interval(seconds: 120))  // seeds as 2 minutes
        sut.selectIntervalUnit(.seconds)

        XCTAssertEqual(sut.intervalUnit, .seconds)
        XCTAssertEqual(sut.intervalValue, 30, "2 would be a nonsense number of seconds")
    }

    func testSelectSecondsUnit_leavesAValidValueAlone() {
        var sut = FocusCadenceDraft(cadence: .interval(seconds: 45))
        sut.selectIntervalUnit(.seconds)

        XCTAssertEqual(sut.intervalValue, 45)
    }

    func testSelectMinutesUnit_keepsTheTypedNumber() {
        var sut = FocusCadenceDraft(cadence: .interval(seconds: 45))
        sut.selectIntervalUnit(.minutes)

        XCTAssertEqual(sut.intervalUnit, .minutes)
        XCTAssertEqual(sut.intervalValue, 45)
        XCTAssertEqual(sut.resolvedCadence, .interval(seconds: 2700))
    }

    // MARK: - Preview copy

    func testSummary_describesWhatApplyingWouldSchedule() {
        var sut = FocusCadenceDraft(cadence: .count(3))
        XCTAssertEqual(sut.summary(forDurationSeconds: 900), "3 nudges")

        sut = FocusCadenceDraft(cadence: .count(1))
        XCTAssertEqual(sut.summary(forDurationSeconds: 900), "1 nudge")

        sut = FocusCadenceDraft(cadence: .interval(seconds: 300))
        XCTAssertEqual(sut.summary(forDurationSeconds: 900), "2 nudges — every 5m")

        sut = FocusCadenceDraft(cadence: .count(0))
        XCTAssertEqual(sut.summary(forDurationSeconds: 900), "No nudges")
    }
}

//
//  FocusActivityContentStateTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Locks the snapshot → ActivityKit content-state mapping and the presentation maths the widget
/// renders from — the pure half of `FocusActivityKitMirror` (the `Activity` calls themselves
/// need an entitled process and are covered by the seam's sequence tests instead).
@available(iOS 16.1, *)
@MainActor
final class FocusActivityContentStateTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func snapshot(
        durationSeconds: Int = 900,
        deadline: Date? = nil,
        pausedRemainingSeconds: Int? = nil
    ) -> FocusActivitySnapshot {
        FocusActivitySnapshot(
            taskTitle: "Draft the review",
            lifeAreaEmoji: "💼",
            durationSeconds: durationSeconds,
            deadline: deadline,
            pausedRemainingSeconds: pausedRemainingSeconds,
            checkpointCount: 2,
            checkpointsReached: 1
        )
    }

    func testRunningSnapshot_keepsTheLiveDeadlineAndIsNotPaused() {
        let state = FocusActivityAttributes.ContentState(
            snapshot: snapshot(deadline: now.addingTimeInterval(600)), now: now
        )

        XCTAssertEqual(state.deadline, now.addingTimeInterval(600))
        XCTAssertNil(state.pausedAt)
        XCTAssertFalse(state.isPaused)
        XCTAssertFalse(state.isCompleted)
        XCTAssertEqual(state.taskTitle, "Draft the review")
        XCTAssertEqual(state.checkpointCount, 2)
        XCTAssertEqual(state.checkpointsReached, 1)
    }

    func testPausedSnapshot_synthesizesADeadlineAndPinsTheDisplayToNow() {
        let state = FocusActivityAttributes.ContentState(
            snapshot: snapshot(pausedRemainingSeconds: 300), now: now
        )

        XCTAssertEqual(state.deadline, now.addingTimeInterval(300))
        XCTAssertEqual(state.pausedAt, now, "Text(timerInterval:pauseTime:) freezes the clock here")
        XCTAssertTrue(state.isPaused)
    }

    func testTimerInterval_spansThePlannedDurationEndingAtTheDeadline() {
        let state = FocusActivityAttributes.ContentState(
            snapshot: snapshot(durationSeconds: 900, deadline: now.addingTimeInterval(600)), now: now
        )

        XCTAssertEqual(
            state.timerInterval,
            now.addingTimeInterval(-300)...now.addingTimeInterval(600),
            "the visual start derives from the deadline so pauses/extensions keep the fill truthful"
        )
    }

    func testFrozenProgress_whilePaused_isTheElapsedFraction() {
        let state = FocusActivityAttributes.ContentState(
            snapshot: snapshot(durationSeconds: 900, pausedRemainingSeconds: 300), now: now
        )

        XCTAssertEqual(state.frozenProgress, 600.0 / 900.0, accuracy: 0.0001)
    }

    func testFrozenProgress_onTheCompletedFrame_isFull() {
        var state = FocusActivityAttributes.ContentState(
            snapshot: snapshot(durationSeconds: 900, pausedRemainingSeconds: 300), now: now
        )
        state.isCompleted = true

        XCTAssertEqual(state.frozenProgress, 1)
    }

    // MARK: - frozenRemainingText (the paused frame's static readout)

    // `Text(timerInterval:pauseTime:)` does not actually freeze inside Live Activity
    // presentations (observed live on E's iPhone, 2026-08-19), so the paused frame renders this
    // static string instead — formatted like the OS timer's `showsHours: false` style (unpadded
    // minutes, padded seconds) so pausing doesn't visibly shift the format.

    func testFrozenRemainingText_whilePaused_isTheFrozenRemainder() {
        let state = FocusActivityAttributes.ContentState(
            snapshot: snapshot(durationSeconds: 900, pausedRemainingSeconds: 300), now: now
        )

        XCTAssertEqual(state.frozenRemainingText, "5:00")
    }

    func testFrozenRemainingText_padsSecondsButNotMinutes() {
        let state = FocusActivityAttributes.ContentState(
            snapshot: snapshot(durationSeconds: 900, pausedRemainingSeconds: 65), now: now
        )

        XCTAssertEqual(state.frozenRemainingText, "1:05")
    }

    func testFrozenRemainingText_rollsHoursIntoMinutes() {
        let state = FocusActivityAttributes.ContentState(
            snapshot: snapshot(durationSeconds: 7200, pausedRemainingSeconds: 3900), now: now
        )

        XCTAssertEqual(state.frozenRemainingText, "65:00")
    }

    func testFrozenRemainingText_neverGoesNegative() {
        var state = FocusActivityAttributes.ContentState(
            snapshot: snapshot(durationSeconds: 900, pausedRemainingSeconds: 0), now: now
        )
        state.deadline = now.addingTimeInterval(-30)

        XCTAssertEqual(state.frozenRemainingText, "0:00")
    }

    func testFrozenProgress_withZeroDuration_isZeroNotNaN() {
        let state = FocusActivityAttributes.ContentState(
            snapshot: snapshot(durationSeconds: 0, pausedRemainingSeconds: 0), now: now
        )

        XCTAssertEqual(state.frozenProgress, 0)
    }
}

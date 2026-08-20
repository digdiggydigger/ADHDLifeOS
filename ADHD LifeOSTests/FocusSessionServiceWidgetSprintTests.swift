//
//  FocusSessionServiceWidgetSprintTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Projects the app-wide sprint engine onto the Home Screen widget's payload.
///
/// The projection has to be **deadline-derived, not countdown-derived**: the widget renders in
/// another process long after this value was written, so anything that would go stale (a remaining
/// second count) has to be absent. It also has to be STABLE while a sprint simply runs — Home
/// republishes whenever this value changes, and a value that moved twice a second would hand
/// WidgetKit a reload storm.
@MainActor
final class FocusSessionServiceWidgetSprintTests: XCTestCase {
    private final class TestClock: @unchecked Sendable {
        var now = Date(timeIntervalSince1970: 1_800_000_000)
        func advance(_ seconds: TimeInterval) { now.addTimeInterval(seconds) }
    }

    private struct SUT {
        let service: FocusSessionService
        let clock: TestClock
    }

    private func makeSUT() -> SUT {
        let clock = TestClock()
        return SUT(service: FocusSessionService(now: { clock.now }), clock: clock)
    }

    private func startSprint(_ service: FocusSessionService, duration: Int = 900, nudges: Int = 2) {
        service.start(
            taskId: UUID(), taskTitle: "Draft the review", lifeAreaEmoji: "💼",
            durationSeconds: duration, cadence: .count(nudges)
        )
    }

    func testNoSprint_projectsNothing() {
        XCTAssertNil(makeSUT().service.widgetSprint)
    }

    func testRunningSprint_projectsTheDeadlineAndTheCheckpointPlan() {
        let env = makeSUT()

        startSprint(env.service, duration: 900, nudges: 2)

        let sprint = env.service.widgetSprint
        XCTAssertEqual(sprint?.taskTitle, "Draft the review")
        XCTAssertEqual(sprint?.emoji, "💼")
        XCTAssertEqual(sprint?.durationSeconds, 900)
        XCTAssertEqual(sprint?.deadline, env.clock.now.addingTimeInterval(900))
        XCTAssertNil(sprint?.pausedRemainingSeconds)
        // Positions, not a count: two evenly-spaced checkpoints across 900s land at 300s and 600s.
        XCTAssertEqual(sprint?.checkpointSeconds, [300, 600])
        XCTAssertEqual(sprint?.checkpointCount, 2)
        XCTAssertEqual(sprint?.checkpointsReached(asOf: env.clock.now), 0)
    }

    /// The whole reason Home can republish on every change without churning WidgetKit: a sprint
    /// that is merely counting down produces the SAME value minute after minute.
    func testRunningSprint_isUnchangedByThePassageOfTimeAlone() async {
        let env = makeSUT()
        startSprint(env.service, duration: 900, nudges: 0)
        let atStart = env.service.widgetSprint

        env.clock.advance(120)
        await env.service.tick()

        XCTAssertEqual(env.service.widgetSprint, atStart, "nothing about the plan moved")
    }

    /// Crossing a checkpoint no longer moves the PUBLISHED value — which is the point. The count is
    /// derived from the positions against the deadline, so the widget works it out for itself and
    /// WidgetKit is never asked to reload for something it could compute.
    func testCrossingACheckpoint_leavesThePublishedProjectionUntouched() async {
        let env = makeSUT()
        startSprint(env.service, duration: 900, nudges: 2)
        let atStart = env.service.widgetSprint

        env.clock.advance(310)
        await env.service.tick()

        XCTAssertEqual(env.service.widgetSprint, atStart, "no republish is owed for a crossing")
    }

    func testCrossingACheckpoint_isVisibleInTheDerivedCountWithoutARepublish() async {
        let env = makeSUT()
        startSprint(env.service, duration: 900, nudges: 2)
        // The projection as published at the very start of the sprint — never republished.
        let published = env.service.widgetSprint

        env.clock.advance(310)
        await env.service.tick()

        XCTAssertEqual(published?.checkpointsReached(asOf: env.clock.now), 1)
        XCTAssertEqual(
            published?.checkpointsReached(asOf: env.clock.now), env.service.session?.triggeredCheckpointIndices.count,
            "the derived count agrees with what the engine actually fired"
        )
    }

    /// A cadence re-plan DOES move it: the plan itself changed, so the widget has to be told.
    func testCadenceReplan_republishesTheNewPositions() {
        let env = makeSUT()
        startSprint(env.service, duration: 900, nudges: 2)

        env.service.updateCadence(.count(4))

        XCTAssertEqual(
            env.service.widgetSprint?.checkpointSeconds,
            FocusCheckpoints.evenlySpaced(durationSeconds: 900, count: 4)
        )
    }

    func testPausedSprint_dropsTheDeadlineAndCarriesTheFrozenRemainder() {
        let env = makeSUT()
        startSprint(env.service, duration: 900, nudges: 2)
        env.clock.advance(120)

        env.service.togglePause()

        let sprint = env.service.widgetSprint
        XCTAssertNil(sprint?.deadline, "a paused sprint has no instant to count down to")
        XCTAssertEqual(sprint?.pausedRemainingSeconds, 780)
        XCTAssertEqual(sprint?.isPaused, true)
    }

    func testResumingSprint_reAnchorsTheDeadline() {
        let env = makeSUT()
        startSprint(env.service, duration: 900, nudges: 2)
        env.clock.advance(120)
        env.service.togglePause()
        env.clock.advance(600)

        env.service.togglePause()

        XCTAssertEqual(env.service.widgetSprint?.deadline, env.clock.now.addingTimeInterval(780))
    }

    func testExtendingSprint_growsBothTheDurationAndTheDeadline() {
        let env = makeSUT()
        startSprint(env.service, duration: 900, nudges: 2)

        env.service.addSeconds(300)

        XCTAssertEqual(env.service.widgetSprint?.durationSeconds, 1200)
        XCTAssertEqual(env.service.widgetSprint?.deadline, env.clock.now.addingTimeInterval(1200))
    }

    func testStoppedSprint_projectsNothingAgain() async {
        let env = makeSUT()
        startSprint(env.service)

        await env.service.stop()

        XCTAssertNil(env.service.widgetSprint)
    }
}

//
//  FocusSessionServiceTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Drives `FocusSessionService` through an injected clock, so the countdown, pause/resume and
/// completion paths are verified without ever waiting on real time.
@MainActor
final class FocusSessionServiceTests: XCTestCase {
    /// Mutable clock the service reads through its `now` closure.
    private final class TestClock: @unchecked Sendable {
        var now = Date(timeIntervalSince1970: 1_800_000_000)
        func advance(_ seconds: TimeInterval) { now.addTimeInterval(seconds) }
    }

    private final class FakeFocusLogger: FocusSessionLogging, @unchecked Sendable {
        var logged: [CompletedFocusSession] = []
        var error: Error?

        func logCompletedSession(_ session: CompletedFocusSession) async throws {
            logged.append(session)
            if let error { throw error }
        }
    }

    /// Bundles the system under test with its controllable collaborators (SwiftLint caps tuples
    /// at two members).
    private struct SUT {
        let service: FocusSessionService
        let clock: TestClock
        let logger: FakeFocusLogger
    }

    private func makeSUT() -> SUT {
        let clock = TestClock()
        let logger = FakeFocusLogger()
        return SUT(
            service: FocusSessionService(logger: logger, now: { clock.now }),
            clock: clock,
            logger: logger
        )
    }

    private func startSprint(
        _ sut: FocusSessionService, duration: Int = 100, cadence: FocusNudgeCadence = .count(1)
    ) {
        sut.start(
            taskId: UUID(), taskTitle: "Draft the review", lifeAreaEmoji: "💼",
            durationSeconds: duration, cadence: cadence
        )
    }

    func testStart_populatesSessionAndCheckpoints() {
        let sut = makeSUT().service

        startSprint(sut, duration: 100, cadence: .count(1))

        XCTAssertTrue(sut.isActive)
        XCTAssertEqual(sut.session?.durationSeconds, 100)
        XCTAssertEqual(sut.session?.remainingSeconds, 100)
        XCTAssertEqual(sut.session?.nudgeCheckpoints, [50])
        XCTAssertFalse(sut.session?.isPaused ?? true)
    }

    func testStart_clampsDurationToThirtySecondFloor() {
        let sut = makeSUT().service

        startSprint(sut, duration: 5)

        XCTAssertEqual(sut.session?.durationSeconds, 30)
    }

    func testStart_usesFallbackEmojiWhenAreaHasNone() {
        let sut = makeSUT().service

        sut.start(taskId: nil, taskTitle: "Unassigned work", lifeAreaEmoji: "", durationSeconds: 60)

        XCTAssertEqual(sut.session?.lifeAreaEmoji, "🎯")
    }

    func testTick_countsDownFromWallClock() async {
        let env = makeSUT()
        let sut = env.service
        let clock = env.clock
        startSprint(sut, duration: 100)

        clock.advance(30)
        await sut.tick()

        XCTAssertEqual(sut.session?.remainingSeconds, 70)
        XCTAssertEqual(sut.session?.elapsedSeconds, 30)
    }

    func testTick_isDriftFreeAcrossAMissedInterval() async {
        let env = makeSUT()
        let sut = env.service
        let clock = env.clock
        startSprint(sut, duration: 100)

        // Simulate the app being suspended: one tick covers 40 real seconds.
        clock.advance(40)
        await sut.tick()

        XCTAssertEqual(sut.session?.remainingSeconds, 60, "remaining derives from the clock, not tick count")
    }

    func testTick_firesCheckpointBannerExactlyOnce() async {
        let env = makeSUT()
        let sut = env.service
        let clock = env.clock
        startSprint(sut, duration: 100, cadence: .count(1))  // checkpoint at 50s elapsed

        clock.advance(49)
        await sut.tick()
        XCTAssertNil(sut.checkpointBanner)

        clock.advance(2)
        await sut.tick()
        XCTAssertNotNil(sut.checkpointBanner)
        XCTAssertEqual(sut.session?.triggeredCheckpointIndices, [0])

        clock.advance(5)
        await sut.tick()
        XCTAssertEqual(sut.session?.triggeredCheckpointIndices, [0], "checkpoint never re-fires")
    }

    func testPause_freezesTheCountdown() async {
        let env = makeSUT()
        let sut = env.service
        let clock = env.clock
        startSprint(sut, duration: 100)
        clock.advance(20)
        await sut.tick()

        sut.togglePause()
        clock.advance(60)
        await sut.tick()

        XCTAssertTrue(sut.session?.isPaused ?? false)
        XCTAssertEqual(sut.session?.remainingSeconds, 80, "time spent paused is not deducted")
    }

    func testResume_reanchorsWithoutLosingTime() async {
        let env = makeSUT()
        let sut = env.service
        let clock = env.clock
        startSprint(sut, duration: 100)
        clock.advance(20)
        await sut.tick()
        sut.togglePause()
        clock.advance(60)

        sut.togglePause()
        clock.advance(10)
        await sut.tick()

        XCTAssertFalse(sut.session?.isPaused ?? true)
        XCTAssertEqual(sut.session?.remainingSeconds, 70, "only the 10s after resuming counts")
    }

    func testAddSeconds_extendsRemainingAndTotal() async {
        let env = makeSUT()
        let sut = env.service
        let clock = env.clock
        startSprint(sut, duration: 100)
        clock.advance(40)
        await sut.tick()

        sut.addSeconds(30)

        XCTAssertEqual(sut.session?.remainingSeconds, 90)
        XCTAssertEqual(sut.session?.durationSeconds, 130)
        XCTAssertEqual(sut.session?.elapsedSeconds, 40, "extending doesn't rewrite work already done")
    }

    func testAddSeconds_withNoSession_isNoOp() {
        let sut = makeSUT().service

        sut.addSeconds(30)

        XCTAssertFalse(sut.isActive)
    }

    func testStop_clearsSessionAndLogsPartialSprint() async {
        let env = makeSUT()
        let sut = env.service
        let clock = env.clock
        let logger = env.logger
        startSprint(sut, duration: 100)
        clock.advance(35)
        await sut.tick()

        await sut.stop()

        XCTAssertFalse(sut.isActive)
        XCTAssertEqual(logger.logged.count, 1)
        let record = try? XCTUnwrap(logger.logged.first)
        XCTAssertEqual(record?.focusedSeconds, 35)
        XCTAssertEqual(record?.plannedSeconds, 100)
        XCTAssertEqual(record?.completedNaturally, false)
        XCTAssertEqual(record?.taskTitle, "Draft the review")
    }

    func testCountdownReachingZero_completesNaturallyAndLogs() async {
        let env = makeSUT()
        let sut = env.service
        let clock = env.clock
        let logger = env.logger
        startSprint(sut, duration: 100, cadence: .count(1))

        clock.advance(100)
        await sut.tick()

        XCTAssertFalse(sut.isActive, "a finished sprint clears itself")
        XCTAssertEqual(logger.logged.count, 1)
        XCTAssertEqual(logger.logged.first?.completedNaturally, true)
        XCTAssertEqual(logger.logged.first?.focusedSeconds, 100)
        XCTAssertEqual(logger.logged.first?.checkpointsReached, 1)
    }

    func testStop_loggingFailure_surfacesErrorButStillEndsSession() async {
        let env = makeSUT()
        let sut = env.service
        let logger = env.logger
        logger.error = TasksServiceError.fetchFailed("offline")
        startSprint(sut, duration: 100)

        await sut.stop()

        XCTAssertFalse(sut.isActive, "the sprint ends regardless of persistence failure")
        XCTAssertEqual(sut.logErrorMessage, "offline")
    }

    func testStop_withNoSession_logsNothing() async {
        let env = makeSUT()
        let sut = env.service
        let logger = env.logger

        await sut.stop()

        XCTAssertTrue(logger.logged.isEmpty)
    }

    // MARK: - completedSprintCount (the analytics post-sprint reload signal)

    func testCompletedSprintCount_incrementsPerFinishedSprint() async {
        let sut = makeSUT().service
        XCTAssertEqual(sut.completedSprintCount, 0)

        startSprint(sut, duration: 100)
        await sut.stop()
        XCTAssertEqual(sut.completedSprintCount, 1)

        startSprint(sut, duration: 100)
        await sut.stop(completedNaturally: true)
        XCTAssertEqual(sut.completedSprintCount, 2)
    }

    func testCompletedSprintCount_incrementsEvenWhenLoggingFails() async {
        // The reload signal tracks "a sprint ended", not "the write landed" — a failed write
        // already has its own surface (the RootView alert), and reloading on it is harmless.
        let env = makeSUT()
        env.logger.error = TasksServiceError.fetchFailed("offline")
        startSprint(env.service, duration: 100)

        await env.service.stop()

        XCTAssertEqual(env.service.completedSprintCount, 1)
    }

    func testCompletedSprintCount_unchangedByNoOpStop() async {
        let sut = makeSUT().service

        await sut.stop()

        XCTAssertEqual(sut.completedSprintCount, 0)
    }
}

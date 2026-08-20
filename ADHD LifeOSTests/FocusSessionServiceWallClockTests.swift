//
//  FocusSessionServiceWallClockTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Wall-clock resync: the ticker normally refreshes `remainingSeconds` every 500ms, but a Live
/// Activity button runs its intent in an app process that may have been suspended for minutes —
/// the last tick is stale. Every mutation must re-derive the countdown from the deadline first,
/// or a Lock Screen pause freezes the wrong time and a Lock Screen stop under-logs history.
@MainActor
final class FocusSessionServiceWallClockTests: XCTestCase {
    private final class TestClock: @unchecked Sendable {
        var now = Date(timeIntervalSince1970: 1_800_000_000)
        func advance(_ seconds: TimeInterval) { now.addTimeInterval(seconds) }
    }

    private final class FakeFocusLogger: FocusSessionLogging, @unchecked Sendable {
        var logged: [CompletedFocusSession] = []
        func logCompletedSession(_ session: CompletedFocusSession) async throws {
            logged.append(session)
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

    private func startSprint(_ service: FocusSessionService, duration: Int = 100) {
        service.start(
            taskId: UUID(), taskTitle: "Draft the review", lifeAreaEmoji: "💼",
            durationSeconds: duration, cadence: .count(1)
        )
    }

    /// Lets fire-and-forget completion Tasks run before asserting.
    private func drainDeferredTasks() async {
        for _ in 0..<10 { await Task.yield() }
    }

    func testTogglePause_afterSuspendedGap_freezesAtWallClockRemaining() {
        let env = makeSUT()
        startSprint(env.service, duration: 100)

        env.clock.advance(40)  // suspended: no tick ran
        env.service.togglePause()

        XCTAssertEqual(env.service.session?.remainingSeconds, 60, "pause must not freeze the stale remainder")
    }

    func testTogglePause_pastDeadlineWhileSuspended_completesInsteadOfPausing() async {
        let env = makeSUT()
        startSprint(env.service, duration: 100)

        env.clock.advance(120)  // the countdown ran out while suspended
        env.service.togglePause()
        await drainDeferredTasks()

        XCTAssertFalse(env.service.isActive, "a finished sprint completes; it doesn't pause at 00:00")
        XCTAssertEqual(env.logger.logged.first?.completedNaturally, true)
        XCTAssertEqual(env.logger.logged.first?.focusedSeconds, 100)
    }

    func testStop_afterSuspendedGap_logsWallClockElapsed() async {
        let env = makeSUT()
        startSprint(env.service, duration: 100)

        env.clock.advance(40)
        await env.service.stop()

        XCTAssertEqual(env.logger.logged.first?.focusedSeconds, 40, "history must not under-report suspended time")
    }

    func testStop_afterDeadlinePassedWhileSuspended_logsAsNaturalCompletion() async {
        let env = makeSUT()
        startSprint(env.service, duration: 100)

        env.clock.advance(120)
        await env.service.stop()

        XCTAssertEqual(env.logger.logged.first?.completedNaturally, true, "the countdown genuinely ran out")
        XCTAssertEqual(env.logger.logged.first?.focusedSeconds, 100)
    }

    func testAddSeconds_afterSuspendedGap_extendsFromWallClockRemaining() {
        let env = makeSUT()
        startSprint(env.service, duration: 100)

        env.clock.advance(40)
        env.service.addSeconds(30)

        XCTAssertEqual(env.service.session?.remainingSeconds, 90, "+30s must not refund suspended time")
        XCTAssertEqual(env.service.session?.durationSeconds, 130)
    }

    // MARK: - Foreground catch-up

    /// E's bug, 2026-08-20: a sprint that runs out while the phone is locked leaves the Live
    /// Activity on screen — countdown at 0:00, a stale checkpoint count, and live Pause/Stop
    /// buttons — because NOTHING completes the sprint until the app is alive again. Returning to
    /// the app must settle it at once rather than waiting on the next 500ms ticker beat.
    func testSyncNow_pastDeadlineWhileSuspended_completesTheSprint() async {
        let env = makeSUT()
        startSprint(env.service, duration: 100)

        env.clock.advance(180)  // locked phone: the ticker never ran
        env.service.syncNow()
        await drainDeferredTasks()

        XCTAssertFalse(env.service.isActive)
        XCTAssertEqual(env.logger.logged.first?.completedNaturally, true)
        XCTAssertEqual(env.logger.logged.first?.focusedSeconds, 100, "credit stops at the deadline, not at wake-up")
    }

    func testSyncNow_midSprint_justCatchesTheCountdownUp() {
        let env = makeSUT()
        startSprint(env.service, duration: 100)

        env.clock.advance(40)
        env.service.syncNow()

        XCTAssertTrue(env.service.isActive)
        XCTAssertEqual(env.service.session?.remainingSeconds, 60)
    }

    func testSyncNow_whilePaused_changesNothing() {
        let env = makeSUT()
        startSprint(env.service, duration: 100)
        env.clock.advance(30)
        env.service.togglePause()

        env.clock.advance(600)  // ten minutes paused
        env.service.syncNow()

        XCTAssertEqual(env.service.session?.isPaused, true)
        XCTAssertEqual(env.service.session?.remainingSeconds, 70, "paused time is not spent")
    }

    func testSyncNow_withNoSprint_isANoOp() {
        let env = makeSUT()

        env.service.syncNow()

        XCTAssertFalse(env.service.isActive)
        XCTAssertTrue(env.logger.logged.isEmpty)
    }
}

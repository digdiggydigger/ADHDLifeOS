//
//  FocusSessionServiceNotificationTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The sprint engine's contract with the notification centre. Unlike the Live Activity — which the
/// OS re-renders from a deadline — local notifications must be handed over BEFORE the app is
/// suspended, and withdrawn the moment the schedule they were built from stops being true.
@MainActor
final class FocusSessionServiceNotificationTests: XCTestCase {
    private final class TestClock: @unchecked Sendable {
        var now = Date(timeIntervalSince1970: 1_800_000_000)
        func advance(_ seconds: TimeInterval) { now.addTimeInterval(seconds) }
    }

    private struct SUT {
        let service: FocusSessionService
        let clock: TestClock
        let notifications: FakeFocusNotificationScheduling

        /// Awaits the engine's fire-and-forget scheduling task, so assertions never race it.
        func settle() async { await service.pendingNotificationWork() }
    }

    private func makeSUT() -> SUT {
        let clock = TestClock()
        let notifications = FakeFocusNotificationScheduling()
        return SUT(
            service: FocusSessionService(notificationScheduler: notifications, now: { clock.now }),
            clock: clock,
            notifications: notifications
        )
    }

    private func startSprint(
        _ service: FocusSessionService, duration: Int = 900, cadence: FocusNudgeCadence = .count(3)
    ) {
        service.start(
            taskId: UUID(), taskTitle: "Take a 10-minute walk", lifeAreaEmoji: "🫀",
            durationSeconds: duration, cadence: cadence
        )
    }

    // MARK: - Start

    func testStart_requestsAuthorizationAndSchedulesTheWholeSprint() async {
        let env = makeSUT()

        startSprint(env.service)
        await env.settle()

        XCTAssertEqual(env.notifications.authorizationRequests, 1, "the sprint is where an ADHD user meets nudges")
        XCTAssertEqual(env.notifications.scheduled.last?.count, 4, "3 checkpoints + the completion")
    }

    func testStart_replacingASprint_replacesItsNotifications() async {
        let env = makeSUT()
        startSprint(env.service)
        await env.settle()

        startSprint(env.service, duration: 600, cadence: .count(1))
        await env.settle()

        XCTAssertEqual(env.notifications.scheduled.last?.count, 2, "the displaced sprint's nudges must not survive")
    }

    // MARK: - Pause / resume / extend

    func testPause_withdrawsEveryPendingNotification() async {
        let env = makeSUT()
        startSprint(env.service)
        await env.settle()

        env.service.togglePause()
        await env.settle()

        XCTAssertEqual(env.notifications.scheduled.last, [], "a nudge firing during a pause would be a lie")
    }

    func testResume_reschedulesAgainstTheNewDeadline() async {
        let env = makeSUT()
        startSprint(env.service)
        env.clock.advance(100)
        await env.service.tick()
        env.service.togglePause()
        env.clock.advance(600)  // ten minutes of pause

        env.service.togglePause()
        await env.settle()

        let fireDates = env.notifications.scheduled.last?.map(\.fireDate)
        XCTAssertEqual(
            fireDates?.first, env.clock.now.addingTimeInterval(125),
            "the 225s mark is 125s away from a playhead paused at 100s elapsed"
        )
    }

    func testAddSeconds_reschedulesSoCompletionMovesWithTheDeadline() async {
        let env = makeSUT()
        startSprint(env.service)
        await env.settle()

        env.service.addSeconds(300)
        await env.settle()

        let completion = env.notifications.scheduled.last?.first { $0.kind == .sprintComplete }
        XCTAssertEqual(completion?.fireDate, env.clock.now.addingTimeInterval(1_200))
    }

    // MARK: - Cadence re-planning

    func testUpdateCadence_reschedulesToTheNewPlan() async {
        let env = makeSUT()
        startSprint(env.service)
        env.clock.advance(300)
        await env.service.tick()
        await env.settle()

        env.service.updateCadence(.interval(seconds: 120))
        await env.settle()

        // 6 marks in the new plan, 1 of them behind the playhead and already fired → 5 ahead,
        // plus the completion.
        XCTAssertEqual(env.notifications.scheduled.last?.count, 6)
    }

    // MARK: - Ending

    func testStop_withdrawsEveryPendingNotification() async {
        let env = makeSUT()
        startSprint(env.service)
        await env.settle()

        await env.service.stop()
        await env.settle()

        XCTAssertEqual(env.notifications.scheduled.last, [])
    }

    func testNaturalCompletion_withdrawsPendingNotifications() async {
        let env = makeSUT()
        startSprint(env.service)
        env.clock.advance(900)

        await env.service.tick()
        await env.settle()

        XCTAssertEqual(env.notifications.scheduled.last, [])
    }

    // MARK: - Ticks

    func testPlainTicks_doNotRescheduleAnything() async {
        let env = makeSUT()
        startSprint(env.service)
        await env.settle()
        let scheduleCount = env.notifications.scheduled.count

        env.clock.advance(10)
        await env.service.tick()
        env.clock.advance(10)
        await env.service.tick()
        await env.settle()

        XCTAssertEqual(
            env.notifications.scheduled.count, scheduleCount,
            "the OS already holds the schedule; re-handing it every half-second is pure churn"
        )
    }
}

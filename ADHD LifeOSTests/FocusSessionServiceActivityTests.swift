//
//  FocusSessionServiceActivityTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Asserts the Live Activity mirroring contract: the service reports start / pause / resume /
/// extend / checkpoint / end — and NEVER a per-second tick, because the OS renders the countdown
/// itself from the snapshot's deadline.
@MainActor
final class FocusSessionServiceActivityTests: XCTestCase {
    private final class TestClock: @unchecked Sendable {
        var now = Date(timeIntervalSince1970: 1_800_000_000)
        func advance(_ seconds: TimeInterval) { now.addTimeInterval(seconds) }
    }

    /// Bundles the system under test with its controllable collaborators (SwiftLint caps tuples
    /// at two members).
    private struct SUT {
        let service: FocusSessionService
        let clock: TestClock
        let mirror: FakeFocusActivityMirroring
    }

    private func makeSUT() -> SUT {
        let clock = TestClock()
        let mirror = FakeFocusActivityMirroring()
        return SUT(
            service: FocusSessionService(activityMirror: mirror, now: { clock.now }),
            clock: clock,
            mirror: mirror
        )
    }

    private func startSprint(
        _ service: FocusSessionService, duration: Int = 100, title: String = "Draft the review"
    ) {
        service.start(
            taskId: UUID(), taskTitle: title, lifeAreaEmoji: "💼",
            durationSeconds: duration, cadence: .count(1)
        )
    }

    // MARK: - Start

    func testStart_startsActivityWithADeadlineDerivedSnapshot() {
        let env = makeSUT()

        startSprint(env.service, duration: 100)

        XCTAssertEqual(env.mirror.startedSnapshots.count, 1)
        let snapshot = env.mirror.startedSnapshots.first
        XCTAssertEqual(snapshot?.taskTitle, "Draft the review")
        XCTAssertEqual(snapshot?.lifeAreaEmoji, "💼")
        XCTAssertEqual(snapshot?.durationSeconds, 100)
        XCTAssertEqual(snapshot?.deadline, env.clock.now.addingTimeInterval(100))
        XCTAssertNil(snapshot?.pausedRemainingSeconds)
        XCTAssertEqual(snapshot?.checkpointCount, 1)
        XCTAssertEqual(snapshot?.checkpointsReached, 0)
    }

    func testReplacementStart_endsTheOldActivityBeforeStartingTheNewOne() {
        let env = makeSUT()
        startSprint(env.service, duration: 100)

        startSprint(env.service, duration: 200, title: "The replacement")

        XCTAssertEqual(env.mirror.events.count, 3)
        XCTAssertEqual(env.mirror.events[1], .ended(completedNaturally: false))
        XCTAssertEqual(env.mirror.startedSnapshots.last?.taskTitle, "The replacement")
    }

    // MARK: - Pause / resume / extend

    func testPause_updatesActivityWithTheFrozenRemainder() async {
        let env = makeSUT()
        startSprint(env.service, duration: 100)
        env.clock.advance(20)
        await env.service.tick()

        env.service.togglePause()

        let snapshot = env.mirror.updatedSnapshots.last
        XCTAssertNil(snapshot?.deadline, "a paused sprint has no live deadline")
        XCTAssertEqual(snapshot?.pausedRemainingSeconds, 80)
    }

    func testResume_updatesActivityWithTheReanchoredDeadline() async {
        let env = makeSUT()
        startSprint(env.service, duration: 100)
        env.clock.advance(20)
        await env.service.tick()
        env.service.togglePause()
        env.clock.advance(60)

        env.service.togglePause()

        let snapshot = env.mirror.updatedSnapshots.last
        XCTAssertEqual(snapshot?.deadline, env.clock.now.addingTimeInterval(80))
        XCTAssertNil(snapshot?.pausedRemainingSeconds)
    }

    func testAddSeconds_updatesActivityWithTheExtendedDeadlineAndTotal() async {
        let env = makeSUT()
        startSprint(env.service, duration: 100)
        env.clock.advance(40)
        await env.service.tick()

        env.service.addSeconds(30)

        let snapshot = env.mirror.updatedSnapshots.last
        XCTAssertEqual(snapshot?.deadline, env.clock.now.addingTimeInterval(90))
        XCTAssertEqual(snapshot?.durationSeconds, 130)
    }

    // MARK: - Ticks and checkpoints

    func testPlainTicks_neverUpdateTheActivity() async {
        let env = makeSUT()
        startSprint(env.service, duration: 100)  // checkpoint at 50s elapsed

        env.clock.advance(10)
        await env.service.tick()
        env.clock.advance(10)
        await env.service.tick()

        XCTAssertTrue(env.mirror.updatedSnapshots.isEmpty, "the OS renders the countdown itself")
    }

    func testCheckpointCrossing_updatesTheActivityExactlyOnce() async {
        let env = makeSUT()
        startSprint(env.service, duration: 100)

        env.clock.advance(51)
        await env.service.tick()
        env.clock.advance(5)
        await env.service.tick()

        XCTAssertEqual(env.mirror.updatedSnapshots.count, 1)
        XCTAssertEqual(env.mirror.updatedSnapshots.first?.checkpointsReached, 1)
    }

    // MARK: - Ending

    func testStop_endsTheActivityAsStoppedEarly() async {
        let env = makeSUT()
        startSprint(env.service, duration: 100)

        await env.service.stop()

        XCTAssertEqual(env.mirror.events.last, .ended(completedNaturally: false))
    }

    func testNaturalCompletion_endsTheActivityAsCompleted() async {
        let env = makeSUT()
        startSprint(env.service, duration: 100)

        env.clock.advance(100)
        await env.service.tick()

        XCTAssertEqual(env.mirror.events.count, 2, "the completing tick must not also send an update")
        XCTAssertEqual(env.mirror.events.last, .ended(completedNaturally: true))
    }

    func testStop_withNoSession_sendsNoActivityEvents() async {
        let env = makeSUT()

        await env.service.stop()

        XCTAssertTrue(env.mirror.events.isEmpty)
    }
}

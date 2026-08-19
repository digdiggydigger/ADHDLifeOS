//
//  FocusSessionServiceCadenceTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The live cadence editor's service API: re-planning a running sprint's checkpoints without
/// disturbing the ones it already crossed, and mirroring the new plan onto the Live Activity
/// (a cadence change moves `checkpointCount`, which the Activity shows).
@MainActor
final class FocusSessionServiceCadenceTests: XCTestCase {
    private final class TestClock: @unchecked Sendable {
        var now = Date(timeIntervalSince1970: 1_800_000_000)
        func advance(_ seconds: TimeInterval) { now.addTimeInterval(seconds) }
    }

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

    private func startSprint(_ service: FocusSessionService, duration: Int, cadence: FocusNudgeCadence) {
        service.start(
            taskId: UUID(), taskTitle: "Draft the review", lifeAreaEmoji: "💼",
            durationSeconds: duration, cadence: cadence
        )
    }

    // MARK: - Current cadence

    func testStart_recordsTheCadenceSoTheEditorCanSeedFromIt() {
        let env = makeSUT()

        startSprint(env.service, duration: 900, cadence: .count(3))

        XCTAssertEqual(env.service.cadence, .count(3))
    }

    func testUpdateCadence_becomesTheCurrentCadence() {
        let env = makeSUT()
        startSprint(env.service, duration: 900, cadence: .count(3))

        env.service.updateCadence(.interval(seconds: 120))

        XCTAssertEqual(env.service.cadence, .interval(seconds: 120))
    }

    // MARK: - Re-planning

    func testUpdateCadence_respacesUpcomingCheckpointsOnly() async {
        let env = makeSUT()
        startSprint(env.service, duration: 900, cadence: .count(3))  // 225 / 450 / 675
        env.clock.advance(300)
        await env.service.tick()  // checkpoint 0 (225s) has fired

        env.service.updateCadence(.interval(seconds: 120))

        XCTAssertEqual(env.service.session?.nudgeCheckpoints, [225, 360, 480, 600, 720, 840])
        XCTAssertEqual(env.service.session?.triggeredCheckpointIndices, [0])
    }

    func testUpdateCadence_leavesTheCountdownUntouched() async {
        let env = makeSUT()
        startSprint(env.service, duration: 900, cadence: .count(3))
        env.clock.advance(300)
        await env.service.tick()

        env.service.updateCadence(.count(5))

        XCTAssertEqual(env.service.session?.remainingSeconds, 600, "re-planning nudges never moves the deadline")
        XCTAssertEqual(env.service.session?.durationSeconds, 900)
    }

    func testUpdateCadence_whilePausedKeepsTheSprintPaused() async {
        let env = makeSUT()
        startSprint(env.service, duration: 900, cadence: .count(3))
        env.clock.advance(300)
        await env.service.tick()
        env.service.togglePause()
        env.clock.advance(120)

        env.service.updateCadence(.count(1))

        XCTAssertEqual(env.service.session?.isPaused, true)
        XCTAssertEqual(env.service.session?.remainingSeconds, 600, "paused time is not spent")
        XCTAssertEqual(env.service.session?.nudgeCheckpoints, [225, 450])
    }

    func testUpdateCadence_resyncsToWallClockBeforeReplanning() {
        let env = makeSUT()
        startSprint(env.service, duration: 900, cadence: .count(3))
        // No tick: the app was suspended. The playhead is stale until the mutation resyncs it.
        env.clock.advance(500)

        env.service.updateCadence(.interval(seconds: 300))

        XCTAssertEqual(env.service.session?.remainingSeconds, 400)
        XCTAssertEqual(
            env.service.session?.nudgeCheckpoints, [225, 450, 600],
            "225 and 450 are kept because the resync fired them; only 600 is still ahead"
        )
        XCTAssertEqual(env.service.session?.triggeredCheckpointIndices, [0, 1])
    }

    // MARK: - Live Activity mirroring

    func testUpdateCadence_mirrorsTheNewCheckpointCount() async {
        let env = makeSUT()
        startSprint(env.service, duration: 900, cadence: .count(3))
        env.clock.advance(300)
        await env.service.tick()
        let updatesBefore = env.mirror.updatedSnapshots.count

        env.service.updateCadence(.interval(seconds: 120))

        XCTAssertEqual(env.mirror.updatedSnapshots.count, updatesBefore + 1)
        XCTAssertEqual(env.mirror.updatedSnapshots.last?.checkpointCount, 6)
        XCTAssertEqual(env.mirror.updatedSnapshots.last?.checkpointsReached, 1)
    }

    func testUpdateCadence_withNoSession_isANoOp() {
        let env = makeSUT()

        env.service.updateCadence(.count(4))

        XCTAssertNil(env.service.session)
        XCTAssertTrue(env.mirror.events.isEmpty)
    }
}

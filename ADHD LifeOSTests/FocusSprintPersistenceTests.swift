//
//  FocusSprintPersistenceTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// F-SprintPersistence (E's on-device report, 2026-08-24): a running sprint must survive the app
/// being killed. The engine is deadline-derived, so persistence is just the sprint's identity,
/// plan and clock anchors — relaunch recomputes the countdown, marks checkpoints crossed while
/// dead WITHOUT re-firing them, and settles a sprint whose deadline passed by logging it whole.
@MainActor
final class FocusSprintPersistenceTests: XCTestCase {
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

    private final class FakeFocusSprintStore: FocusSprintPersisting {
        var stored: PersistedFocusSprint?
        private(set) var writeCount = 0
        private(set) var clearCount = 0

        func read() -> PersistedFocusSprint? { stored }
        func write(_ state: PersistedFocusSprint) {
            stored = state
            writeCount += 1
        }
        func clear() {
            stored = nil
            clearCount += 1
        }
    }

    private struct SUT {
        let service: FocusSessionService
        let clock: TestClock
        let logger: FakeFocusLogger
        let store: FakeFocusSprintStore
        let mirror: FakeFocusActivityMirroring
    }

    private func makeSUT(seeded: PersistedFocusSprint? = nil) -> SUT {
        let clock = TestClock()
        let logger = FakeFocusLogger()
        let store = FakeFocusSprintStore()
        let mirror = FakeFocusActivityMirroring()
        store.stored = seeded
        let service = FocusSessionService(
            logger: logger, activityMirror: mirror, sprintStore: store, now: { clock.now }
        )
        return SUT(service: service, clock: clock, logger: logger, store: store, mirror: mirror)
    }

    private func persisted(
        clock: TestClock,
        duration: Int = 600,
        startedSecondsAgo: TimeInterval = 100,
        deadlineIn: TimeInterval? = 500,
        pausedRemaining: Int? = nil,
        checkpoints: [Int] = [60, 300],
        triggered: [Int] = []
    ) -> PersistedFocusSprint {
        PersistedFocusSprint(
            taskId: UUID(),
            taskTitle: "Draft the review",
            lifeAreaEmoji: "💼",
            durationSeconds: duration,
            nudgeCheckpoints: checkpoints,
            triggeredCheckpointIndices: triggered,
            startedAt: clock.now.addingTimeInterval(-startedSecondsAgo),
            deadline: deadlineIn.map { clock.now.addingTimeInterval($0) },
            pausedRemainingSeconds: pausedRemaining,
            cadenceCount: 2,
            cadenceIntervalSeconds: nil
        )
    }

    // MARK: - Persist points

    func testStart_persistsTheRunningSprint() {
        let sut = makeSUT()
        sut.service.start(
            taskId: UUID(), taskTitle: "Draft", lifeAreaEmoji: "💼",
            durationSeconds: 600, cadence: .count(2)
        )
        let saved = sut.store.stored
        XCTAssertEqual(saved?.taskTitle, "Draft")
        XCTAssertEqual(saved?.durationSeconds, 600)
        XCTAssertEqual(saved?.deadline, sut.clock.now.addingTimeInterval(600))
        XCTAssertNil(saved?.pausedRemainingSeconds)
        XCTAssertEqual(saved?.cadenceCount, 2)
    }

    func testPause_persistsFrozenRemaining_andResumeRestoresTheDeadline() {
        let sut = makeSUT()
        sut.service.start(
            taskId: nil, taskTitle: "Draft", lifeAreaEmoji: "💼", durationSeconds: 600
        )
        sut.clock.advance(100)
        sut.service.togglePause()
        XCTAssertNil(sut.store.stored?.deadline)
        XCTAssertEqual(sut.store.stored?.pausedRemainingSeconds, 500)

        sut.clock.advance(1_000)
        sut.service.togglePause()
        XCTAssertEqual(sut.store.stored?.deadline, sut.clock.now.addingTimeInterval(500))
        XCTAssertNil(sut.store.stored?.pausedRemainingSeconds)
    }

    func testStop_clearsThePersistedSprint() async {
        let sut = makeSUT()
        sut.service.start(
            taskId: nil, taskTitle: "Draft", lifeAreaEmoji: "💼", durationSeconds: 600
        )
        await sut.service.stop()
        XCTAssertNil(sut.store.stored)
        XCTAssertGreaterThan(sut.store.clearCount, 0)
    }

    func testCheckpointCrossing_persistsTheTriggeredIndices() async {
        let sut = makeSUT()
        sut.service.start(
            taskId: nil, taskTitle: "Draft", lifeAreaEmoji: "💼",
            durationSeconds: 600, cadence: .count(2)
        )
        sut.clock.advance(250)
        await sut.service.tick()
        XCTAssertEqual(sut.store.stored?.triggeredCheckpointIndices, [0])
    }

    // MARK: - Restore

    func testRestore_runningSprint_recomputesFromTheDeadline() async {
        let sut = makeSUT()
        sut.store.stored = persisted(clock: sut.clock)
        await sut.service.restorePersistedSprint()

        XCTAssertEqual(sut.service.session?.taskTitle, "Draft the review")
        XCTAssertEqual(sut.service.session?.remainingSeconds, 500)
        XCTAssertEqual(sut.service.session?.isPaused, false)
        // The 60s checkpoint passed while the app was dead: marked as fired, never re-nudged.
        XCTAssertEqual(sut.service.session?.triggeredCheckpointIndices, [0])
        XCTAssertNil(sut.service.checkpointBanner)
        XCTAssertEqual(sut.service.sprintDeadline, sut.clock.now.addingTimeInterval(500))
    }

    func testRestore_reportsRestoredToTheMirror_notStarted() async {
        let sut = makeSUT()
        sut.store.stored = persisted(clock: sut.clock)
        await sut.service.restorePersistedSprint()

        guard case .restored(let snapshot)? = sut.mirror.events.first else {
            return XCTFail("Expected a restored event, got \(sut.mirror.events)")
        }
        XCTAssertEqual(snapshot.taskTitle, "Draft the review")
        XCTAssertEqual(sut.mirror.startedSnapshots, [])
    }

    func testRestore_pausedSprint_staysFrozen() async {
        let sut = makeSUT()
        sut.store.stored = persisted(clock: sut.clock, deadlineIn: nil, pausedRemaining: 240)
        await sut.service.restorePersistedSprint()

        XCTAssertEqual(sut.service.session?.isPaused, true)
        XCTAssertEqual(sut.service.session?.remainingSeconds, 240)
        XCTAssertNil(sut.service.sprintDeadline)
    }

    func testRestore_expiredSprint_completesLogsAndClears() async {
        let sut = makeSUT()
        sut.store.stored = persisted(clock: sut.clock, deadlineIn: -30)
        await sut.service.restorePersistedSprint()

        XCTAssertNil(sut.service.session)
        XCTAssertEqual(sut.logger.logged.count, 1)
        XCTAssertEqual(sut.logger.logged.first?.completedNaturally, true)
        XCTAssertEqual(sut.logger.logged.first?.focusedSeconds, 600)
        XCTAssertNil(sut.store.stored)
    }

    func testRestore_withNothingStored_doesNothing() async {
        let sut = makeSUT()
        await sut.service.restorePersistedSprint()
        XCTAssertNil(sut.service.session)
        XCTAssertEqual(sut.mirror.events, [])
    }

    // MARK: - Store round-trip

    func testUserDefaultsStore_roundTripsAndClears() {
        let suite = "focus-sprint-store-tests"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let store = UserDefaultsFocusSprintStore(defaults: defaults)
        let clock = TestClock()
        let state = persisted(clock: clock, triggered: [0])

        XCTAssertNil(store.read())
        store.write(state)
        XCTAssertEqual(store.read(), state)
        store.clear()
        XCTAssertNil(store.read())
        defaults.removePersistentDomain(forName: suite)
    }
}

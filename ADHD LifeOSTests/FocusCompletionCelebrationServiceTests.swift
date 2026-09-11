//
//  FocusCompletionCelebrationServiceTests.swift
//  ADHD LifeOSTests
//
//  F-FocusCard-4's service half: WHICH card celebrates, and what the haptic keys on. Split from
//  `FocusCompletionStackServiceTests` because one more test tipped that file over both SwiftLint
//  ceilings in block 3; the doubles are this file's own, `private`, for the same reason.
//
//  Three of these are discriminators. An implementation stamping every ended sprint passes the
//  natural-completion test and fails `testAManualStopStampsNothing`; one keyed on the stack's
//  depth passes everything but `testConfirmingLeavesTheCountAlone`; one that restores the stamp
//  with the stack passes everything but `testARestoredStackCelebratesNothing`.
//

import XCTest
@testable import ADHD_LifeOS

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
    var unacknowledged: CompletedFocusSession?
    var cardCollapsed = false
    var unconfirmed: [CompletedFocusSession] = []

    func read() -> PersistedFocusSprint? { stored }
    func write(_ state: PersistedFocusSprint) { stored = state }
    func clear() { stored = nil }
    func readUnacknowledgedCompletion() -> CompletedFocusSession? { unacknowledged }
    func writeUnacknowledgedCompletion(_ record: CompletedFocusSession) { unacknowledged = record }
    func clearUnacknowledgedCompletion() { unacknowledged = nil }
    func readCardCollapsed() -> Bool { cardCollapsed }
    func writeCardCollapsed(_ isCollapsed: Bool) { cardCollapsed = isCollapsed }
    func readUnconfirmedCompletions() -> [CompletedFocusSession] { unconfirmed }
    func writeUnconfirmedCompletions(_ records: [CompletedFocusSession]) { unconfirmed = records }
}

@MainActor
final class FocusCompletionCelebrationServiceTests: XCTestCase {

    private struct SUT {
        let service: FocusSessionService
        let clock: TestClock
        let logger: FakeFocusLogger
        let store: FakeFocusSprintStore
    }

    private func makeSUT() -> SUT {
        let clock = TestClock()
        let logger = FakeFocusLogger()
        let store = FakeFocusSprintStore()
        let service = FocusSessionService(
            logger: logger, sprintStore: store, locationStamp: { nil }, now: { clock.now }
        )
        return SUT(service: service, clock: clock, logger: logger, store: store)
    }

    private func startSprint(_ service: FocusSessionService, title: String = "Draft the review") {
        service.start(
            taskId: UUID(), taskTitle: title, lifeAreaEmoji: "💼",
            durationSeconds: 100, cadence: .count(1)
        )
    }

    // MARK: - Which endings celebrate

    func testANaturalCompletionStampsItsOwnRecord() async throws {
        let sut = makeSUT()
        XCTAssertEqual(sut.service.confirmableCompletionCount, 0)
        XCTAssertNil(sut.service.celebratingCompletionID)
        startSprint(sut.service)

        await sut.service.stop(completedNaturally: true)

        let front = try XCTUnwrap(sut.service.unconfirmedCompletions.first)
        XCTAssertEqual(
            sut.service.celebratingCompletionID, front.id,
            "The record that just finished is not the one named for celebration, so the burst"
                + " plays on the wrong card or on none."
        )
        XCTAssertEqual(sut.service.confirmableCompletionCount, 1)
    }

    /// **The discriminator against `completedSprintCount`.** That counter is bumped by
    /// `finishCurrentSprint`, which a manual Stop also runs — so keyed on it, stopping a sprint
    /// early would buzz and nothing on screen would explain why.
    func testAManualStopStampsNothing() async {
        let sut = makeSUT()
        startSprint(sut.service)
        sut.clock.advance(30)

        await sut.service.stop()

        XCTAssertEqual(sut.service.completedSprintCount, 1, "The premise: the analytics token moved.")
        XCTAssertEqual(
            sut.service.confirmableCompletionCount, 0,
            "A manual Stop advanced the celebration count. There is no card for it, so the haptic"
                + " would fire for nothing the user can see."
        )
        XCTAssertNil(sut.service.celebratingCompletionID)
    }

    /// The haptic's trigger must CHANGE on every completion, not merely become non-zero — a
    /// second sprint finishing while the first card still waits is E's own routine scenario.
    func testEachCompletionAdvancesTheCount() async {
        let sut = makeSUT()
        startSprint(sut.service, title: "First")
        await sut.service.stop(completedNaturally: true)
        startSprint(sut.service, title: "Second")
        await sut.service.stop(completedNaturally: true)

        XCTAssertEqual(
            sut.service.confirmableCompletionCount, 2,
            "The second completion did not move the trigger, so the second card arrives silently."
        )
        XCTAssertEqual(sut.service.celebratingCompletionID, sut.service.unconfirmedCompletions.first?.id)
    }

    // MARK: - Confirm reveals, and revealing is not finishing

    /// Push A, push B, confirm B: A is revealed, and A did not just finish. The stamp stays on B —
    /// which no longer matches any card — rather than moving to A.
    func testConfirmingTheFrontDoesNotMoveTheStampToTheRevealedCard() async throws {
        let sut = makeSUT()
        startSprint(sut.service, title: "A")
        await sut.service.stop(completedNaturally: true)
        startSprint(sut.service, title: "B")
        await sut.service.stop(completedNaturally: true)
        let cardB = try XCTUnwrap(sut.service.unconfirmedCompletions.first)
        let cardA = try XCTUnwrap(sut.service.unconfirmedCompletions.last)
        XCTAssertEqual(cardB.taskTitle, "B", "The premise: newest first.")

        await sut.service.confirmCompletion(cardB)

        XCTAssertEqual(sut.service.unconfirmedCompletions.first?.id, cardA.id, "A is now in front.")
        XCTAssertNotEqual(
            sut.service.celebratingCompletionID, cardA.id,
            "Confirming B moved the celebration onto A. A card revealed by a Confirm did not just"
                + " finish and must not burst."
        )
    }

    /// **The discriminator against `unconfirmedCompletions.count`.** The stack's depth falls on
    /// every Confirm, so a haptic keyed on it would buzz on dismissal.
    func testConfirmingLeavesTheCountAlone() async throws {
        let sut = makeSUT()
        startSprint(sut.service)
        await sut.service.stop(completedNaturally: true)
        let card = try XCTUnwrap(sut.service.unconfirmedCompletions.first)

        await sut.service.confirmCompletion(card)

        XCTAssertTrue(sut.service.unconfirmedCompletions.isEmpty, "The premise: the card is gone.")
        XCTAssertEqual(
            sut.service.confirmableCompletionCount, 1,
            "Confirm changed the celebration count, so dismissing a card fires the success"
                + " haptic — the buzz-on-dismissal the design record rules out."
        )
    }

    // MARK: - Nothing replays

    /// A relaunch restores the stack — cards from hours ago — and must celebrate none of them.
    /// The stamp is in-memory only, so a fresh service over a populated store starts at zero.
    func testARestoredStackCelebratesNothing() async {
        let sut = makeSUT()
        startSprint(sut.service)
        await sut.service.stop(completedNaturally: true)
        XCTAssertEqual(sut.store.unconfirmed.count, 1, "The premise: the stack was persisted.")

        let relaunched = FocusSessionService(
            logger: sut.logger, sprintStore: sut.store, locationStamp: { nil }, now: { sut.clock.now }
        )
        await relaunched.restorePersistedSprint()

        XCTAssertEqual(relaunched.unconfirmedCompletions.count, 1, "The premise: the card came back.")
        XCTAssertEqual(
            relaunched.confirmableCompletionCount, 0,
            "A relaunch advanced the celebration count, so every launch buzzes for a sprint that"
                + " finished long ago."
        )
        XCTAssertNil(
            relaunched.celebratingCompletionID,
            "A restored card is named for celebration, so it bursts again on every launch."
        )
    }

    /// The app-was-dead settle raises the OFFLINE card, not a stack card, and must not stamp.
    func testTheOfflineSettleStampsNothing() async {
        let sut = makeSUT()
        sut.store.stored = PersistedFocusSprint(
            taskId: UUID(), taskTitle: "Died mid-sprint", lifeAreaEmoji: "💼",
            durationSeconds: 600, nudgeCheckpoints: [300], triggeredCheckpointIndices: [],
            startedAt: sut.clock.now.addingTimeInterval(-900),
            deadline: sut.clock.now.addingTimeInterval(-300),
            pausedRemainingSeconds: nil, cadenceCount: 1, cadenceIntervalSeconds: nil
        )

        await sut.service.restorePersistedSprint()

        XCTAssertNotNil(sut.service.offlineCompletionSummary, "The premise: the offline flow ran.")
        XCTAssertEqual(sut.service.confirmableCompletionCount, 0)
        XCTAssertNil(sut.service.celebratingCompletionID)
    }

    /// Starting a replacement sprint logs the replaced one as stopped early. No card, no burst.
    func testAReplacementStampsNothing() async {
        let sut = makeSUT()
        startSprint(sut.service, title: "First")
        sut.clock.advance(10)

        startSprint(sut.service, title: "Second")

        XCTAssertEqual(sut.service.confirmableCompletionCount, 0)
        XCTAssertNil(sut.service.celebratingCompletionID)
    }
}

//
//  FocusConfirmationStampTests.swift
//  ADHD LifeOSTests
//
//  F-ConfirmCelebration-1's service half, E's approved R2: the stamp a Confirm leaves, which the
//  full-screen celebration and the Confirm haptic key on. Its own doubles, `private`, for the reason
//  `FocusCompletionCelebrationServiceTests` records.
//
//  The discriminators: an implementation that stamps whether or not the card was waiting fails
//  `testConfirmingACardThatIsNotWaitingCelebratesNothing`; one that writes after the history write
//  fails `testTheConfirmationStampLandsBeforeTheLogAwait`; one that reuses the completion stamp
//  fails `testConfirmLeavesTheCompletionStampWhereItWas`.
//

import XCTest
@testable import ADHD_LifeOS

private final class TestClock: @unchecked Sendable {
    var now = Date(timeIntervalSince1970: 1_800_000_000)
}

private final class FakeFocusLogger: FocusSessionLogging, @unchecked Sendable {
    var logged: [CompletedFocusSession] = []
    func logCompletedSession(_ session: CompletedFocusSession) async throws {
        logged.append(session)
    }
}

/// A logger that ENTERS and then waits — the Firestore write that hangs. Released at the end of the
/// test so no continuation leaks into later runs (see `FocusCompletionStackServiceTests`).
private final class GatedFocusLogger: FocusSessionLogging, @unchecked Sendable {
    var entered = false
    private var gate: CheckedContinuation<Void, Never>?

    func logCompletedSession(_ session: CompletedFocusSession) async throws {
        entered = true
        await withCheckedContinuation { self.gate = $0 }
    }

    func release() {
        gate?.resume()
        gate = nil
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
final class FocusConfirmationStampTests: XCTestCase {

    private func makeService(
        logger: FocusSessionLogging = FakeFocusLogger(), store: FakeFocusSprintStore = FakeFocusSprintStore()
    ) -> FocusSessionService {
        let clock = TestClock()
        return FocusSessionService(logger: logger, sprintStore: store, locationStamp: { nil }, now: { clock.now })
    }

    /// Finishes a sprint naturally, which raises one card.
    private func finishSprint(_ service: FocusSessionService, title: String) async {
        service.start(taskId: UUID(), taskTitle: title, lifeAreaEmoji: "💼", durationSeconds: 100, cadence: .count(1))
        await service.stop(completedNaturally: true)
    }

    // MARK: - What a Confirm stamps

    func testConfirmingTheLastCardClearsTheStack() async throws {
        let service = makeService()
        await finishSprint(service, title: "Only")
        let card = try XCTUnwrap(service.unconfirmedCompletions.first)

        await service.confirmCompletion(card)

        XCTAssertEqual(
            service.latestConfirmation, FocusConfirmation(ordinal: 1, clearedStack: true),
            "Confirming the only card did not stamp a cleared stack, so nothing celebrates it."
        )
        XCTAssertEqual(service.confirmationCount, 1, "The Confirm haptic's trigger did not move.")
    }

    func testConfirmingACardWithOneBehindItDoesNotClearTheStack() async throws {
        let service = makeService()
        await finishSprint(service, title: "Older")
        await finishSprint(service, title: "Newer")
        let front = try XCTUnwrap(service.unconfirmedCompletions.first)

        await service.confirmCompletion(front)

        XCTAssertEqual(service.unconfirmedCompletions.count, 1, "The premise: one card is left.")
        XCTAssertEqual(
            service.latestConfirmation, FocusConfirmation(ordinal: 1, clearedStack: false),
            "A Confirm that revealed another card was stamped as clearing the stack."
        )
    }

    /// Every Confirm must CHANGE the trigger — two in a row is E's routine scenario — and the one
    /// that empties the stack is the one marked cleared.
    func testEachConfirmAdvancesTheOrdinalAndTheLastOneClears() async throws {
        let service = makeService()
        await finishSprint(service, title: "Older")
        await finishSprint(service, title: "Newer")
        await service.confirmCompletion(try XCTUnwrap(service.unconfirmedCompletions.first))

        await service.confirmCompletion(try XCTUnwrap(service.unconfirmedCompletions.first))

        XCTAssertEqual(
            service.latestConfirmation, FocusConfirmation(ordinal: 2, clearedStack: true),
            "The second Confirm did not advance the ordinal, or emptying the stack was not marked."
        )
    }

    /// A card that is no longer waiting — a second call for the same card — must not celebrate
    /// again, and a record that never had a card must not celebrate at all.
    func testConfirmingACardThatIsNotWaitingCelebratesNothing() async throws {
        let service = makeService()
        await finishSprint(service, title: "Only")
        let card = try XCTUnwrap(service.unconfirmedCompletions.first)
        await service.confirmCompletion(card)

        await service.confirmCompletion(card)

        XCTAssertEqual(
            service.confirmationCount, 1,
            "Confirming a card that had already gone celebrated a second time."
        )
        let untouched = makeService()
        await untouched.confirmCompletion(card)
        XCTAssertNil(untouched.latestConfirmation, "A record with no card celebrated.")
    }

    // MARK: - What does not stamp

    /// Finishing a sprint, stopping one early and relaunching over a waiting card are not Confirms.
    func testNothingButConfirmWritesTheConfirmationStamp() async {
        let store = FakeFocusSprintStore()
        let service = makeService(store: store)
        await finishSprint(service, title: "Finished")
        XCTAssertNil(service.latestConfirmation, "A natural completion stamped a Confirm.")

        service.start(
            taskId: UUID(), taskTitle: "Stopped", lifeAreaEmoji: "💼", durationSeconds: 100, cadence: .count(1)
        )
        await service.stop()
        XCTAssertNil(service.latestConfirmation, "A manual Stop stamped a Confirm.")

        let relaunched = makeService(store: store)
        await relaunched.restorePersistedSprint()
        XCTAssertEqual(relaunched.unconfirmedCompletions.count, 1, "The premise: the card came back.")
        XCTAssertNil(relaunched.latestConfirmation, "A relaunch replays a Confirm celebration.")
    }

    /// The completion stamp keys the in-ring burst and the completion haptic; a Confirm writing it
    /// would re-celebrate the card it reveals. The new stamp is asserted too, so leaving both alone
    /// cannot pass.
    func testConfirmLeavesTheCompletionStampWhereItWas() async throws {
        let service = makeService()
        await finishSprint(service, title: "Only")
        let before = service.latestConfirmableCompletion
        let card = try XCTUnwrap(service.unconfirmedCompletions.first)

        await service.confirmCompletion(card)

        XCTAssertNotNil(service.latestConfirmation, "Confirm stamped nothing.")
        XCTAssertEqual(
            service.latestConfirmableCompletion, before,
            "Confirm moved the completion stamp, which re-celebrates whatever card it reveals."
        )
    }

    // MARK: - Order

    /// **The stamp is synchronous and lands before `await log(...)`**, like the dismissal: a
    /// Firestore write that hangs must not hold the celebration back.
    func testTheConfirmationStampLandsBeforeTheLogAwait() async {
        let logger = GatedFocusLogger()
        let store = FakeFocusSprintStore()
        let record = CompletedFocusSession(
            id: UUID(), taskId: nil, taskTitle: "Waiting", lifeAreaEmoji: "💼",
            plannedSeconds: 1500, focusedSeconds: 1500, checkpointsReached: 1, completedNaturally: true,
            startedAt: Date(timeIntervalSince1970: 1_799_998_500), endedAt: Date(timeIntervalSince1970: 1_800_000_000)
        )
        store.unconfirmed = [record]
        let service = makeService(logger: logger, store: store)
        service.restoreUnconfirmedCompletions()

        let confirming = Task { await service.confirmCompletion(record) }
        for _ in 0..<20 { await Task.yield() }

        XCTAssertTrue(
            logger.entered,
            "The logger was never reached, so the assertion below proves nothing."
        )
        XCTAssertEqual(
            service.latestConfirmation?.ordinal, 1,
            "The celebration waits on the history write. The stamp must land before `await log`."
        )
        logger.release()
        await confirming.value
    }
}

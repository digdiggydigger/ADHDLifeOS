//
//  FocusCompletionConfirmTests.swift
//  ADHD LifeOSTests
//
//  What the Confirm button does, split out of `FocusCompletionStackServiceTests` when
//  F-FocusCard-3 tipped that file over SwiftLint's 400-line and 250-line ceilings — the trap the
//  block-3 handoff names by name, hit here by adding a TEST rather than by widening a protocol.
//
//  The split is thematic rather than arbitrary: the other file answers *which sprint endings
//  raise a card and what survives a relaunch*, and this one answers *what happens when the user
//  taps Confirm*. F-FocusCard-3 added two of these — the conditional collapse reset E chose on
//  2026-09-09, and the reveal that proves the RIGHT card was removed.
//
//  The doubles are duplicated from that file rather than shared, which is this repo's established
//  arrangement for the Focus tests: they are `private`, so every Focus test file carries its own
//  twins under the same names and none of them can collide.
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

    // F-FocusCard-2 widened `FocusSprintPersisting` again. Recorded rather than defaulted in a
    // protocol extension, for the reason `FocusSprintPersistenceTests` already records: a
    // default silences the compile break that is this block's red step, and would let a
    // service that never persists the stack pass `testUnconfirmedStackSurvivesRelaunch`.
    func readUnconfirmedCompletions() -> [CompletedFocusSession] { unconfirmed }
    func writeUnconfirmedCompletions(_ records: [CompletedFocusSession]) { unconfirmed = records }
}

@MainActor
final class FocusCompletionConfirmTests: XCTestCase {

    private struct SUT {
        let service: FocusSessionService
        let clock: TestClock
        let logger: FakeFocusLogger
        let store: FakeFocusSprintStore
    }

    private static let stampedCoordinate = PlaceCoordinate(latitude: 51.5, longitude: -0.12)

    private func makeSUT(placeId: UUID? = nil) -> SUT {
        let clock = TestClock()
        let logger = FakeFocusLogger()
        let store = FakeFocusSprintStore()
        let stamp: LocationStamp? = placeId.map {
            LocationStamp(coordinate: Self.stampedCoordinate, placeId: $0)
        }
        let service = FocusSessionService(
            logger: logger, sprintStore: store, locationStamp: { stamp }, now: { clock.now }
        )
        return SUT(service: service, clock: clock, logger: logger, store: store)
    }

    private func startSprint(
        _ service: FocusSessionService, title: String = "Draft the review", duration: Int = 100
    ) {
        service.start(
            taskId: UUID(), taskTitle: title, lifeAreaEmoji: "💼",
            durationSeconds: duration, cadence: .count(1)
        )
    }
    // MARK: - Confirm

    func testConfirmRemovesRePersistsAndLogsAConfirmedCopy() async throws {
        let placeId = UUID()
        let sut = makeSUT(placeId: placeId)
        startSprint(sut.service)
        await sut.service.stop(completedNaturally: true)
        let provisional = try XCTUnwrap(sut.service.unconfirmedCompletions.first)

        await sut.service.confirmCompletion(provisional)

        XCTAssertTrue(sut.service.unconfirmedCompletions.isEmpty, "Confirm left the card on screen.")
        XCTAssertTrue(sut.store.unconfirmed.isEmpty, "Confirm did not re-persist the empty stack.")
        XCTAssertEqual(sut.logger.logged.count, 2, "Confirm must write a second time — the finalise.")
        let confirmed = try XCTUnwrap(sut.logger.logged.last)
        XCTAssertEqual(
            confirmed.id, provisional.id,
            "The confirmed copy carries a DIFFERENT id, so `save` writes a second history row"
                + " instead of upserting the provisional one — the sprint would count twice."
        )
        XCTAssertNotNil(confirmed.confirmedAt, "The re-saved record is still provisional.")
        XCTAssertEqual(
            confirmed.placeId, placeId,
            "The location stamp was lost on confirm. `save` is `setData` with no merge, so a"
                + " re-save that drops a field ERASES it from the document."
        )
        XCTAssertEqual(confirmed.latitude, Self.stampedCoordinate.latitude)
        XCTAssertEqual(confirmed.longitude, Self.stampedCoordinate.longitude)
    }

    /// **Block 1 shipped collapse deliberately sticky, and this is the reset.** E: the card stays
    /// collapsed *"until the user has tapped the final, and new, 'Confirmed' button"*.
    func testConfirmResetsCollapse() async throws {
        let sut = makeSUT()
        startSprint(sut.service)
        sut.service.setCardCollapsed(true)
        await sut.service.stop(completedNaturally: true)
        let record = try XCTUnwrap(sut.service.unconfirmedCompletions.first)

        XCTAssertTrue(
            sut.service.isCardCollapsed,
            "Something other than Confirm already reset collapse — the assertion below would then"
                + " pass on an implementation that never touches it."
        )
        // **The premise, stated rather than assumed.** Since F-FocusCard-3 the reset is
        // CONDITIONAL — it fires only when no sprint is running (E, 2026-09-09). This test still
        // passes because a natural completion clears `session` before it pushes the card, so
        // there is nothing running by the time Confirm is tapped. Without this line the test
        // reads as proof of the old unconditional rule, which it is no longer.
        XCTAssertFalse(
            sut.service.isActive,
            "A sprint is still running here, so this test is now asserting the CONDITIONAL"
                + " branch's opposite — `testConfirmLeavesARunningSprintsCardCollapsed` owns that"
                + " case."
        )

        await sut.service.confirmCompletion(record)

        XCTAssertFalse(
            sut.service.isCardCollapsed,
            "Confirm is the ONLY thing that clears collapse, and it did not. The next sprint"
                + " starts collapsed."
        )
        XCTAssertFalse(sut.store.cardCollapsed, "The reset was not persisted, so it comes back.")
    }

    /// **E's call, 2026-09-09, answering the register's item A2 before this block was built.**
    ///
    /// The rule Confirm shipped with in block 2 was unconditional, and stacking is what made the
    /// consequence visible: in E's own scenario a routine auto-starts sprint B while card A is
    /// still waiting, and confirming the OLD card A blew the NEW sprint B's card open — undoing a
    /// collapse the user had just made by hand. E was shown the three candidate rules and chose
    /// *"reset only if no sprint is running"*: the letter of the original rule still holds for
    /// the case it was written about, and nothing yanks open a card the user just collapsed.
    ///
    /// **The discriminator against the shipped implementation**, which called
    /// `setCardCollapsed(false)` unconditionally and passes `testConfirmResetsCollapse` above.
    /// **The reveal, and it discriminates "removed the RIGHT one" from "removed one".**
    ///
    /// A `confirmCompletion` that dropped `.first` regardless of its argument passes every other
    /// assertion in this file — the card count falls, the stack re-persists, a confirmed copy is
    /// logged. The only thing that catches it is asserting WHICH record was finalised, which is
    /// why the logged copy is checked by title here rather than by count.
    func testConfirmingTheFrontRevealsTheNext() async throws {
        let sut = makeSUT()
        startSprint(sut.service, title: "A, the older")
        await sut.service.stop(completedNaturally: true)
        startSprint(sut.service, title: "B, the newer")
        await sut.service.stop(completedNaturally: true)

        let front = try XCTUnwrap(sut.service.unconfirmedCompletions.first)
        XCTAssertEqual(front.taskTitle, "B, the newer", "The premise — newest in front — is gone.")

        await sut.service.confirmCompletion(front)

        XCTAssertEqual(
            sut.logger.logged.last?.taskTitle, "B, the newer",
            "Confirm finalised the WRONG record. It writes `confirmed_at` on whatever it removed,"
                + " so the card the user actually looked at stays provisional forever while one"
                + " they never saw is banked as confirmed."
        )
        XCTAssertNotNil(sut.logger.logged.last?.confirmedAt)
        XCTAssertEqual(
            sut.service.unconfirmedCompletions.map(\.taskTitle), ["A, the older"],
            "Confirming the front card did not reveal the next one — E's presentation is one at a"
                + " time, and the card behind is what makes that legible."
        )
    }

    func testConfirmLeavesARunningSprintsCardCollapsed() async throws {
        let sut = makeSUT()
        startSprint(sut.service, title: "Finished")
        await sut.service.stop(completedNaturally: true)
        let waiting = try XCTUnwrap(sut.service.unconfirmedCompletions.first)

        // The routine's replacement sprint, and the user collapses its card by hand.
        startSprint(sut.service, title: "Started by a routine", duration: 600)
        sut.service.setCardCollapsed(true)
        XCTAssertTrue(
            sut.service.isActive,
            "No sprint is running, so this test cannot tell the conditional rule from the"
                + " unconditional one — it would pass on both."
        )

        await sut.service.confirmCompletion(waiting)

        XCTAssertTrue(
            sut.service.isCardCollapsed,
            "Confirming an OLD completion expanded the card of a sprint that is still running,"
                + " undoing a collapse the user had just made by hand. Since 2026-09-09 the reset"
                + " fires only when nothing is running."
        )
        XCTAssertTrue(
            sut.store.cardCollapsed,
            "The collapse was left in memory but overwritten in the store, so the card expands on"
                + " the next launch instead."
        )
        XCTAssertTrue(
            sut.service.unconfirmedCompletions.isEmpty,
            "The confirmed card must still be dismissed — only the collapse reset is conditional."
        )
    }
}

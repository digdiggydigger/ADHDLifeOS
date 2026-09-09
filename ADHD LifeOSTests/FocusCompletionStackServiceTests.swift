//
//  FocusCompletionStackServiceTests.swift
//  ADHD LifeOSTests
//
//  F-FocusCard-2's service half: which sprint endings produce a card, what Confirm does, and what
//  survives a relaunch.
//
//  Written before the implementation (`claudecode.md`). Four of these are discriminators rather
//  than coverage — they fail an implementation that passes every other test in the file, and each
//  says so in its failure message.
//

import XCTest
@testable import ADHD_LifeOS

// The doubles sit at FILE scope, not nested in the test class: SwiftLint's `type_body_length`
// counts a nested type's body against its enclosing one. `private` keeps them visible to
// exactly this file, so the twin fakes in the other Focus test files are untouched.

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

/// A logger that ENTERS and then never returns — the Firestore write that hangs.
///
/// The continuation is stored rather than abandoned so `release()` can resume it at the end of
/// the test: a `withCheckedContinuation` deallocated un-resumed prints a runtime "leaked its
/// continuation" misuse warning into every later run of the suite.
private final class GatedFocusLogger: FocusSessionLogging, @unchecked Sendable {
    var entered = false
    var logged: [CompletedFocusSession] = []
    private var gate: CheckedContinuation<Void, Never>?

    func logCompletedSession(_ session: CompletedFocusSession) async throws {
        logged.append(session)
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

    // F-FocusCard-2 widened `FocusSprintPersisting` again. Recorded rather than defaulted in a
    // protocol extension, for the reason `FocusSprintPersistenceTests` already records: a
    // default silences the compile break that is this block's red step, and would let a
    // service that never persists the stack pass `testUnconfirmedStackSurvivesRelaunch`.
    func readUnconfirmedCompletions() -> [CompletedFocusSession] { unconfirmed }
    func writeUnconfirmedCompletions(_ records: [CompletedFocusSession]) { unconfirmed = records }
}

@MainActor
final class FocusCompletionStackServiceTests: XCTestCase {

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

    // MARK: - Which endings produce a card

    func testANaturalCompletionPushesAnUnconfirmedCard() async throws {
        let sut = makeSUT()
        startSprint(sut.service)

        await sut.service.stop(completedNaturally: true)

        XCTAssertEqual(
            sut.service.unconfirmedCompletions.count, 1,
            "A sprint that ran its countdown out produced no confirmation card, so the completion"
                + " is banked silently — the thing E's Confirm button exists to prevent."
        )
        let card = try XCTUnwrap(sut.service.unconfirmedCompletions.first)
        XCTAssertTrue(card.isProvisional)
        XCTAssertEqual(card.taskTitle, "Draft the review")
    }

    /// **The discriminator for the whole feature.** An implementation that pushes on every
    /// `finishCurrentSprint` — the obvious place to put it — passes the natural-completion test
    /// above and fails only here. E chose this knowing the consequence: after a manual Stop
    /// nothing resets collapse, so the card stays collapsed into the next sprint.
    func testManualStopPushesNothing() async {
        let sut = makeSUT()
        startSprint(sut.service, duration: 600)
        sut.clock.advance(60)

        await sut.service.stop()

        XCTAssertEqual(sut.logger.logged.count, 1, "The sprint must still be logged.")
        XCTAssertTrue(
            sut.service.unconfirmedCompletions.isEmpty,
            "A manual Stop raised a confirmation card. E chose \"only a NATURAL completion"
                + " produces a card\" — the user who just pressed Stop has already acknowledged it."
        )
    }

    /// A late manual Stop — the Lock Screen button on an app suspended past its deadline — is a
    /// countdown that genuinely ran out, and `stop()` already records it as such. The card must
    /// follow that same reading rather than the caller's argument.
    func testAStopThatArrivesAfterTheDeadlinePushesACard() async {
        let sut = makeSUT()
        startSprint(sut.service, duration: 100)
        sut.clock.advance(200)

        await sut.service.stop()

        XCTAssertEqual(
            sut.service.unconfirmedCompletions.count, 1,
            "The sprint's countdown had already run out, so this is a natural completion wearing"
                + " a manual Stop's clothes — `ranOut` decides, not the argument."
        )
    }

    func testStartingAReplacementSprintPushesNothing() async {
        let sut = makeSUT()
        startSprint(sut.service, title: "First", duration: 600)
        sut.clock.advance(60)

        startSprint(sut.service, title: "Second", duration: 600)
        for _ in 0..<10 { await Task.yield() }

        XCTAssertTrue(
            sut.service.unconfirmedCompletions.isEmpty,
            "Displacing a sprint by starting another raised a confirmation card for the one that"
                + " was cut short. It was stopped early, not completed."
        )
        XCTAssertEqual(sut.service.session?.taskTitle, "Second")
    }

    /// **The third caller of `finishCurrentSprint`, and the one no other test in this file
    /// reaches.** A sprint that expired while the app was dead has its own card
    /// (`OfflineSprintSummaryCard`) and its own persistence key. Pushing it into the new stack too
    /// would put two cards on screen for one sprint in two different visual languages — the
    /// "two keys, two published properties, two cards, zero interaction" rule.
    func testTheOfflineRestorePathPushesNothingToTheNewStack() async {
        let sut = makeSUT()
        sut.store.stored = PersistedFocusSprint(
            taskId: UUID(), taskTitle: "Died mid-sprint", lifeAreaEmoji: "💼",
            durationSeconds: 600, nudgeCheckpoints: [300], triggeredCheckpointIndices: [],
            startedAt: sut.clock.now.addingTimeInterval(-900),
            deadline: sut.clock.now.addingTimeInterval(-300),
            pausedRemainingSeconds: nil, cadenceCount: 1, cadenceIntervalSeconds: nil
        )

        await sut.service.restorePersistedSprint()

        XCTAssertNotNil(
            sut.service.offlineCompletionSummary,
            "The offline flow itself is broken — this test's premise no longer holds."
        )
        XCTAssertTrue(
            sut.service.unconfirmedCompletions.isEmpty,
            "The offline completion was ALSO pushed into the new stack, so one sprint raises two"
                + " cards. The push belongs in `stop()`, not in `finishCurrentSprint`."
        )
    }

    // MARK: - Ordering against the history write

    /// **An ordering bug invisible to every other test here.** With the push after the write, a
    /// Firestore call that hangs — offline, or a slow cold connection — leaves the user's finished
    /// sprint with nothing on screen at all until it returns or fails.
    func testThePushLandsBeforeTheLogAwait() async {
        let clock = TestClock()
        let logger = GatedFocusLogger()
        let store = FakeFocusSprintStore()
        let service = FocusSessionService(
            logger: logger, sprintStore: store, locationStamp: { nil }, now: { clock.now }
        )
        startSprint(service)

        let stopping = Task { await service.stop(completedNaturally: true) }
        for _ in 0..<20 { await Task.yield() }

        XCTAssertTrue(
            logger.entered,
            "The logger was never reached, so the assertion below proves nothing — this test is"
                + " vacuous unless the write is genuinely in flight and suspended."
        )
        XCTAssertEqual(
            service.unconfirmedCompletions.count, 1,
            "The confirmation card does not exist while the history write is still in flight."
                + " The push must be SYNCHRONOUS and come before `await log(...)`."
        )
        XCTAssertEqual(
            store.unconfirmed.count, 1,
            "The card is on screen but not persisted, so killing the app here loses it."
        )

        logger.release()
        await stopping.value
    }

    // MARK: - The stack

    /// E raised the stack themselves: *"If the user already has an unconfirmed AND completed
    /// sprint then possibly a stack could be used here."* Newest in front, so the card that shows
    /// is `.first` and the stack's depth is the array index — which is what F-FocusCard-3's
    /// layout will read.
    func testTheNewestCompletionIsInFront() async {
        let sut = makeSUT()
        startSprint(sut.service, title: "First")
        await sut.service.stop(completedNaturally: true)
        startSprint(sut.service, title: "Second")
        await sut.service.stop(completedNaturally: true)

        XCTAssertEqual(sut.service.unconfirmedCompletions.count, 2, "Nothing may be auto-confirmed.")
        XCTAssertEqual(
            sut.service.unconfirmedCompletions.first?.taskTitle, "Second",
            "The stack is appending, so the OLDEST card is in front — E's presentation is"
                + " iOS-notification style, newest in front."
        )
    }

    func testUnconfirmedStackSurvivesRelaunch() async {
        let sut = makeSUT()
        startSprint(sut.service, title: "Survivor")
        await sut.service.stop(completedNaturally: true)

        // A second service over the SAME store: the relaunch. Fails if the stack is held only in
        // memory, or restored below the `guard session == nil` in `restorePersistedSprint` — with
        // the sprint itself cleared on completion, that guard returns early on exactly this path.
        let relaunched = FocusSessionService(sprintStore: sut.store, now: { sut.clock.now })
        await relaunched.restorePersistedSprint()

        XCTAssertEqual(
            relaunched.unconfirmedCompletions.map(\.taskTitle), ["Survivor"],
            "The unconfirmed stack did not survive a relaunch. It is held only in memory, or it is"
                + " restored below the early-return guard — the same ordering trap as the collapse"
                + " read in F-FocusCard-1."
        )
    }

    // MARK: - Two keys, and they never meet

    /// **Both directions, and one alone is not enough** — a merged implementation that drove both
    /// published properties from one key passes whichever direction is tested first.
    func testTheNewKeyNeverTouchesTheOldOne() throws {
        let suite = "focus.completion.keys.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = UserDefaultsFocusSprintStore(defaults: defaults)
        let record = CompletedFocusSession(
            id: UUID(), taskId: nil, taskTitle: "Only in the new key", lifeAreaEmoji: "💼",
            plannedSeconds: 600, focusedSeconds: 600, checkpointsReached: 1,
            completedNaturally: true, startedAt: Date(), endedAt: Date()
        )

        store.writeUnconfirmedCompletions([record])

        XCTAssertNil(
            store.readUnacknowledgedCompletion(),
            "Writing the F-FocusCard-2 stack populated the OFFLINE key too, so a completion the"
                + " user is about to confirm also raises the app-was-dead card."
        )

        store.writeUnconfirmedCompletions([])
        store.writeUnacknowledgedCompletion(record)

        XCTAssertTrue(
            store.readUnconfirmedCompletions().isEmpty,
            "Writing the OFFLINE key populated the new stack. Two keys, two cards, zero"
                + " interaction — a migration between them is the refactor E ruled out."
        )
    }
}

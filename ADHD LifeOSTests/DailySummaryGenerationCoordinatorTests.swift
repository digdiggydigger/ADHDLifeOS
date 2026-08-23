//
//  DailySummaryGenerationCoordinatorTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The in-flight generation the card can be rebuilt around.
///
/// Home's `.task` re-runs `HomeService.load()` on every appearance, which flips its load state back
/// through `.loading` and destroys the summary card's whole subtree. The summary itself already
/// survives that (it is persisted). What did not survive was the *generation in progress*: the
/// rebuilt card showed "Generate" again, and tapping it cost a second model call.
@MainActor
final class DailySummaryGenerationCoordinatorTests: XCTestCase {
    private let uid = "uid-e"

    func testNothingIsGeneratingInitially() {
        let coordinator = DailySummaryGenerationCoordinator()

        XCTAssertFalse(coordinator.isGenerating(for: uid))
        XCTAssertNil(coordinator.inFlight(for: uid))
    }

    func testAGenerationIsInFlightUntilItFinishes() async throws {
        let coordinator = DailySummaryGenerationCoordinator()
        let gate = Gate()

        let task = coordinator.generation(for: uid) {
            await gate.wait()
            return Self.summary(headline: "done")
        }
        XCTAssertTrue(coordinator.isGenerating(for: uid), "in flight the moment it starts, not one hop later")

        await gate.open()
        _ = try await task.value

        XCTAssertFalse(coordinator.isGenerating(for: uid))
        XCTAssertNil(coordinator.inFlight(for: uid), "a finished generation must not look in flight")
    }

    /// The point of the whole type: a rebuilt card asking to generate again joins the model call
    /// already running instead of paying for a second one.
    func testASecondRequestJoinsTheRunningGenerationRatherThanStartingAnother() async throws {
        let coordinator = DailySummaryGenerationCoordinator()
        let gate = Gate()
        let counter = CallCounter()

        let first = coordinator.generation(for: uid) {
            await counter.increment()
            await gate.wait()
            return Self.summary(headline: "first")
        }
        let second = coordinator.generation(for: uid) {
            await counter.increment()
            return Self.summary(headline: "second")
        }

        await gate.open()
        let firstResult = try await first.value
        let secondResult = try await second.value

        let calls = await counter.count
        XCTAssertEqual(calls, 1, "the second request must not run its own work")
        XCTAssertEqual(firstResult.content.headline, "first")
        XCTAssertEqual(secondResult.content.headline, "first", "both callers see the same generation")
    }

    /// A card rebuilt mid-flight reattaches through this, without ever starting work itself.
    func testInFlightHandsBackTheRunningGenerationWithoutStartingOne() async throws {
        let coordinator = DailySummaryGenerationCoordinator()
        let gate = Gate()
        let counter = CallCounter()

        let started = coordinator.generation(for: uid) {
            await counter.increment()
            await gate.wait()
            return Self.summary(headline: "done")
        }
        let joined = try XCTUnwrap(coordinator.inFlight(for: uid))

        await gate.open()
        _ = try await started.value
        let joinedResult = try await joined.value

        let calls = await counter.count
        XCTAssertEqual(calls, 1)
        XCTAssertEqual(joinedResult.content.headline, "done")
    }

    func testAFailedGenerationReachesEveryCaller() async {
        let coordinator = DailySummaryGenerationCoordinator()

        let first = coordinator.generation(for: uid) { throw SummaryCoordinatorTestError() }
        let second = coordinator.generation(for: uid) { Self.summary(headline: "unused") }

        await XCTAssertThrowsErrorAsync(try await first.value) { _ in }
        await XCTAssertThrowsErrorAsync(try await second.value) { _ in }
    }

    func testAFailedGenerationClearsTheInFlightSlot() async {
        let coordinator = DailySummaryGenerationCoordinator()

        let task = coordinator.generation(for: uid) { throw SummaryCoordinatorTestError() }
        _ = try? await task.value

        XCTAssertFalse(coordinator.isGenerating(for: uid), "a failure must not wedge the card on a spinner")
    }

    func testAFreshGenerationCanStartOnceTheLastOneFinished() async throws {
        let coordinator = DailySummaryGenerationCoordinator()

        _ = try await coordinator.generation(for: uid) { Self.summary(headline: "first") }.value
        let second = try await coordinator.generation(for: uid) { Self.summary(headline: "second") }.value

        XCTAssertEqual(second.content.headline, "second")
    }

    // MARK: - Account scoping

    /// The same guard `DailySummarySnapshot` applies to the stored record: a summary quotes task
    /// titles and journal reflections, so it is only ever handed to the account that asked for it.
    func testAnotherAccountsGenerationIsNotVisible() async throws {
        let coordinator = DailySummaryGenerationCoordinator()
        let gate = Gate()

        let task = coordinator.generation(for: "uid-someone-else") {
            await gate.wait()
            return Self.summary(headline: "theirs")
        }

        XCTAssertFalse(coordinator.isGenerating(for: uid))
        XCTAssertNil(coordinator.inFlight(for: uid))

        await gate.open()
        _ = try await task.value
    }

    /// Signing into another account mid-flight starts that account's own generation rather than
    /// joining the previous one.
    func testAnotherAccountStartsItsOwnGeneration() async throws {
        let coordinator = DailySummaryGenerationCoordinator()
        let gate = Gate()

        let theirs = coordinator.generation(for: "uid-someone-else") {
            await gate.wait()
            return Self.summary(headline: "theirs")
        }
        let mine = coordinator.generation(for: uid) { Self.summary(headline: "mine") }

        let mineResult = try await mine.value
        XCTAssertEqual(mineResult.content.headline, "mine")

        await gate.open()
        _ = try await theirs.value
    }

    /// A signed-out service has `userId == nil`, and nil is its own scope rather than a wildcard —
    /// the same reasoning as `DailySummarySnapshot.belongs(to:)`, where an unattributed record is
    /// unclaimable rather than universally claimable.
    func testASignedOutScopeDoesNotSeeASignedInGeneration() async throws {
        let coordinator = DailySummaryGenerationCoordinator()
        let gate = Gate()

        let task = coordinator.generation(for: uid) {
            await gate.wait()
            return Self.summary(headline: "mine")
        }

        XCTAssertFalse(coordinator.isGenerating(for: nil))

        await gate.open()
        _ = try await task.value
    }

    private static func summary(headline: String) -> GeneratedDailySummary {
        GeneratedDailySummary(
            content: DailySummaryContent(
                headline: headline, dopamineWins: [], journalReflections: "r",
                focusStaminaInsight: "f", gentleTomorrowKickstart: ["k"]
            ),
            tone: .energizing,
            generatedAt: Date(timeIntervalSince1970: 1_787_000_000),
            source: .localSynthesis
        )
    }
}

private struct SummaryCoordinatorTestError: LocalizedError {
    var errorDescription: String? { "generation failed" }
}

/// Holds work open until a test lets it finish, so "in flight" is observable rather than a race.
actor Gate {
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private var isOpen = false

    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { waiters.append($0) }
    }

    func open() {
        isOpen = true
        let resuming = waiters
        waiters.removeAll()
        resuming.forEach { $0.resume() }
    }
}

/// Counts how many times the work closure actually ran — the difference between joining a
/// generation and paying for a second one.
actor CallCounter {
    private(set) var count = 0

    func increment() {
        count += 1
    }
}

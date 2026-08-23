//
//  DailySummaryRebuildTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// What happens to a generation in progress when the card that started it is destroyed.
///
/// Home's `.task` re-runs `HomeService.load()` on every appearance, which flips its load state
/// back through `.loading` and destroys the summary card's whole subtree. The summary itself
/// already survived that — it is persisted. The generation running at the time did not: the
/// rebuilt card showed "Generate" again, and tapping it cost a second model call.
///
/// Split from `DailySummaryServiceTests` when that file crossed SwiftLint's length limits.
@MainActor
final class DailySummaryRebuildTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_787_000_000)

    /// The bug this section exists for: Home's `.task` re-runs on every appearance and destroys the
    /// card's subtree, so leaving Home mid-generation and coming back rebuilt the service. The
    /// summary survived (it is persisted) but the *generation in progress* did not — the card showed
    /// "Generate" again, and tapping it cost a second model call.
    func testARebuiltServiceShowsTheGenerationAlreadyRunning() async throws {
        let coordinator = DailySummaryGenerationCoordinator()
        let gate = Gate()
        let generator = GatedDailySummaryGenerator(gate: gate)
        let service = makeService(generator: generator, userId: "uid-e", coordinator: coordinator)

        let generating = Task { await service.generate(now: now) }
        await waitUntilGenerating(coordinator, for: "uid-e")
        XCTAssertEqual(service.state, .loading)

        // The card is destroyed and rebuilt — a brand-new service over the same coordinator.
        let rebuilt = makeService(generator: generator, userId: "uid-e", coordinator: coordinator)

        XCTAssertEqual(rebuilt.state, .loading, "the spinner must be there on the first frame, not one frame late")
        XCTAssertTrue(rebuilt.isGenerating)

        await gate.open()
        await generating.value
    }

    /// Showing a spinner is only half the fix. The rebuilt card has to actually receive the result —
    /// otherwise it spins until the user navigates again, which is worse than the original bug.
    func testARebuiltServiceReceivesTheResultOfTheGenerationItJoined() async throws {
        let coordinator = DailySummaryGenerationCoordinator()
        let gate = Gate()
        let generator = GatedDailySummaryGenerator(gate: gate)
        let service = makeService(generator: generator, userId: "uid-e", coordinator: coordinator)

        let generating = Task { await service.generate(now: now) }
        await waitUntilGenerating(coordinator, for: "uid-e")
        let rebuilt = makeService(generator: generator, userId: "uid-e", coordinator: coordinator)
        let reattaching = Task { await rebuilt.reattachIfGenerating() }

        await gate.open()
        await generating.value
        await reattaching.value

        guard case .loaded(let generated) = rebuilt.state else {
            return XCTFail("expected the rebuilt card to load, got \(rebuilt.state)")
        }
        XCTAssertEqual(generated.content.headline, "gated headline")
    }

    /// A rebuilt card must not pay for a second model call — the whole cost argument for this change.
    func testARebuiltServiceDoesNotStartASecondModelCall() async throws {
        let coordinator = DailySummaryGenerationCoordinator()
        let gate = Gate()
        let generator = GatedDailySummaryGenerator(gate: gate)
        let service = makeService(generator: generator, userId: "uid-e", coordinator: coordinator)

        let generating = Task { await service.generate(now: now) }
        await waitUntilGenerating(coordinator, for: "uid-e")
        let rebuilt = makeService(generator: generator, userId: "uid-e", coordinator: coordinator)
        let reattaching = Task { await rebuilt.reattachIfGenerating() }

        await gate.open()
        await generating.value
        await reattaching.value

        let calls = await generator.callCount
        XCTAssertEqual(calls, 1)
    }

    /// A failure has to reach the rebuilt card too, or it spins forever on a dead generation.
    func testARebuiltServiceSeesTheFailureOfTheGenerationItJoined() async throws {
        let coordinator = DailySummaryGenerationCoordinator()
        let service = makeService(generator: FailingDailySummaryGenerator(), userId: "uid-e", coordinator: coordinator)
        let rebuilt = makeService(generator: FailingDailySummaryGenerator(), userId: "uid-e", coordinator: coordinator)

        let generating = Task { await service.generate(now: now) }
        await waitUntilGenerating(coordinator, for: "uid-e")
        let reattaching = Task { await rebuilt.reattachIfGenerating() }
        await generating.value
        await reattaching.value

        XCTAssertEqual(service.state, .failed("generator unavailable"))
        XCTAssertNotEqual(rebuilt.state, .loading, "a dead generation must not leave the card spinning")
    }

    /// The common case — nothing running — must stay a no-op, since the view calls this on every
    /// single appearance.
    func testReattachingWithNothingInFlightChangesNothing() async {
        let service = makeService()

        await service.reattachIfGenerating()

        XCTAssertEqual(service.state, .idle)
    }

    func testReattachingDoesNotDisturbARestoredSummary() async {
        let store = FakeDailySummaryStore()
        let seeded = makeService(store: store, userId: "uid-e")
        await seeded.generate(now: now)

        let restored = makeService(store: store, userId: "uid-e", restoringAsOf: now)
        await restored.reattachIfGenerating()

        guard case .loaded = restored.state else {
            return XCTFail("expected the restored summary to survive, got \(restored.state)")
        }
    }

    /// Another account's in-flight generation is not this card's to show — the same guard
    /// `DailySummarySnapshot.belongs(to:)` applies to the stored record.
    func testARebuiltServiceIgnoresAnotherAccountsGeneration() async throws {
        let coordinator = DailySummaryGenerationCoordinator()
        let gate = Gate()
        let generator = GatedDailySummaryGenerator(gate: gate)
        let theirs = makeService(generator: generator, userId: "uid-someone-else", coordinator: coordinator)

        let generating = Task { await theirs.generate(now: now) }
        await waitUntilGenerating(coordinator, for: "uid-someone-else")
        let mine = makeService(generator: generator, userId: "uid-e", coordinator: coordinator)

        XCTAssertEqual(mine.state, .idle, "not their spinner, and not their summary")

        await gate.open()
        await generating.value
    }

    /// The generation writes the record itself, before it stops looking in flight — so a card
    /// rebuilt in that window restores the finished summary rather than finding neither.
    func testTheStoreIsWrittenBeforeTheGenerationStopsLookingInFlight() async {
        let coordinator = DailySummaryGenerationCoordinator()
        let store = FakeDailySummaryStore()
        let service = makeService(store: store, userId: "uid-e", coordinator: coordinator)

        await service.generate(now: now)

        XCTAssertFalse(coordinator.isGenerating(for: "uid-e"))
        XCTAssertNotNil(store.snapshot?.summary, "the record must already be written by this point")

    // MARK: - Helpers

    }

    /// Yields until the generation has actually begun. `Task { }` only schedules work — asserting
    /// on "is it generating" without waiting races the Task's first execution, which is exactly the
    /// kind of flake that makes a suite untrustworthy. Yield-based rather than sleep-based so it is
    /// deterministic and costs nothing.
    private func waitUntilGenerating(
        _ coordinator: DailySummaryGenerationCoordinator,
        for userId: String?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        for _ in 0..<1_000 {
            if coordinator.isGenerating(for: userId) { return }
            await Task.yield()
        }
        XCTFail("generation never started", file: file, line: line)
    }

    private func makeService(
        tone: DailySummaryTone = .energizing,
        provider: FakeDailySummaryDataProvider = FakeDailySummaryDataProvider(),
        generator: any DailySummaryGenerating = StubbedDailySummaryGenerator(),
        fallbackGenerator: (any DailySummaryGenerating)? = nil,
        store: (any DailySummaryStoring)? = nil,
        userId: String? = nil,
        coordinator: DailySummaryGenerationCoordinator = DailySummaryGenerationCoordinator(),
        restoringAsOf restoreDate: Date? = nil
    ) -> DailySummaryService {
        let service = DailySummaryService(
            provider: provider,
            generator: generator,
            fallbackGenerator: fallbackGenerator,
            store: store,
            userId: userId,
            coordinator: coordinator,
            now: restoreDate ?? now
        )
        // A restored service keeps the tone it was given back; only a fresh one takes the default.
        if restoreDate == nil { service.tone = tone }
        return service
    }
}

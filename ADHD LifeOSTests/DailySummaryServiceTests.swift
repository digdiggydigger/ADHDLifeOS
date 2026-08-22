//
//  DailySummaryServiceTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The screen-state machine behind the Daily Executive Summary card. Both collaborators are
/// faked, so nothing here touches Firestore, the network, or a real clock.
@MainActor
final class DailySummaryServiceTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_787_000_000)

    func testStartsIdle() {
        let service = makeService()
        XCTAssertEqual(service.state, .idle)
        XCTAssertNil(service.copyText)
    }

    func testGenerateProducesALoadedSummaryTaggedWithSourceAndTone() async {
        let service = makeService(tone: .coaching)
        await service.generate(now: now)

        guard case .loaded(let generated) = service.state else {
            return XCTFail("expected loaded, got \(service.state)")
        }
        XCTAssertEqual(generated.content.headline, "stub headline")
        XCTAssertEqual(generated.tone, .coaching)
        XCTAssertEqual(generated.source, .localSynthesis)
        XCTAssertEqual(generated.generatedAt, now)
    }

    func testGenerateAsksTheProviderForTheCurrentlySelectedTone() async {
        let provider = FakeDailySummaryDataProvider()
        let service = makeService(provider: provider)
        service.tone = .bulleted
        await service.generate(now: now)
        XCTAssertEqual(provider.requestedTones, [.bulleted])
    }

    func testAFailedGenerationSurfacesTheMessageAndKeepsNoSummary() async {
        let service = makeService(generator: FailingDailySummaryGenerator())
        await service.generate(now: now)
        XCTAssertEqual(service.state, .failed("generator unavailable"))
        XCTAssertNil(service.copyText)
    }

    func testAFailedDataLoadIsReportedRatherThanSilentlyEmpty() async {
        let provider = FakeDailySummaryDataProvider()
        provider.error = SimpleError("could not read today's tasks")
        let service = makeService(provider: provider)
        await service.generate(now: now)
        XCTAssertEqual(service.state, .failed("could not read today's tasks"))
    }

    /// Regenerating after a failure must be able to succeed — a stuck error state would strand
    /// the card behind one bad network moment.
    func testRegeneratingAfterAFailureRecovers() async {
        let generator = ToggleableDailySummaryGenerator()
        let service = makeService(generator: generator)

        generator.shouldFail = true
        await service.generate(now: now)
        XCTAssertEqual(service.state, .failed("generator unavailable"))

        generator.shouldFail = false
        await service.generate(now: now)
        guard case .loaded = service.state else {
            return XCTFail("expected recovery, got \(service.state)")
        }
    }

    func testCopyTextIsAvailableOnlyOnceASummaryExists() async {
        let service = makeService()
        XCTAssertNil(service.copyText)
        await service.generate(now: now)
        let text = try? XCTUnwrap(service.copyText)
        XCTAssertTrue(text?.contains("stub headline") ?? false)
    }

    /// Changing tone leaves the existing summary on screen — it is still a true record of the
    /// day. Only pressing generate replaces it.
    func testChangingToneKeepsTheExistingSummaryUntilRegenerated() async {
        let service = makeService()
        await service.generate(now: now)
        service.tone = .gentle
        guard case .loaded = service.state else {
            return XCTFail("tone change should not clear the summary")
        }
    }

    // MARK: - Degrading when the model is unreachable

    /// A model outage must not cost the user their day. The on-device synthesis is honest — it only
    /// restates what actually happened — so it stands in, and the provenance line says so.
    func testAModelFailureDegradesToTheOnDeviceSynthesis() async {
        let service = makeService(
            generator: FailingDailySummaryGenerator(),
            fallbackGenerator: StubbedDailySummaryGenerator()
        )
        await service.generate(now: now)

        guard case .loaded(let generated) = service.state else {
            return XCTFail("expected the fallback summary, got \(service.state)")
        }
        XCTAssertEqual(generated.content.headline, "stub headline")
        XCTAssertEqual(generated.source, .localSynthesis)
    }

    /// A fallback summary is as much a record of the day as any other, so it is remembered too.
    func testAFallbackSummaryIsRemembered() async {
        let store = FakeDailySummaryStore()
        let service = makeService(
            generator: FailingDailySummaryGenerator(),
            fallbackGenerator: StubbedDailySummaryGenerator(),
            store: store,
            userId: "uid-1"
        )
        await service.generate(now: now)

        XCTAssertEqual(store.snapshot?.summary?.source, .localSynthesis)
    }

    /// The fallback rewords the day; it cannot invent one. If the day itself couldn't be read there
    /// is nothing honest to synthesize from, so a Firestore failure stays an error.
    func testAFailedDataLoadIsNotPaperedOverByTheFallback() async {
        let provider = FakeDailySummaryDataProvider()
        provider.error = SimpleError("could not read today's tasks")
        let service = makeService(
            provider: provider, fallbackGenerator: StubbedDailySummaryGenerator()
        )
        await service.generate(now: now)

        XCTAssertEqual(service.state, .failed("could not read today's tasks"))
    }

    /// If both generators fail, the reader is shown the model's error rather than the stand-in's —
    /// that is the one that says what actually broke.
    func testIfTheFallbackAlsoFailsTheModelsErrorIsReported() async {
        let service = makeService(
            generator: FailingDailySummaryGenerator(),
            fallbackGenerator: SecondaryFailingDailySummaryGenerator()
        )
        await service.generate(now: now)

        XCTAssertEqual(service.state, .failed("generator unavailable"))
    }

    // MARK: - Remembering across appearances

    /// The card's `@StateObject` does not survive Home re-identifying itself on a tab switch, so a
    /// generated summary has to be recoverable from the store rather than from view state.
    func testARestoredServiceReloadsTodaysSummaryAndItsTone() async {
        let store = FakeDailySummaryStore()
        let first = makeService(tone: .bulleted, store: store, userId: "uid-1")
        await first.generate(now: now)

        let second = makeService(store: store, userId: "uid-1", restoringAsOf: now.addingTimeInterval(600))

        XCTAssertEqual(second.tone, .bulleted)
        guard case .loaded(let generated) = second.state else {
            return XCTFail("expected the stored summary back, got \(second.state)")
        }
        XCTAssertEqual(generated.content.headline, "stub headline")
        XCTAssertEqual(generated.generatedAt, now)
        XCTAssertTrue(second.hasSummary)
    }

    func testASummaryFromAnEarlierDayIsNotRestored() async {
        let store = FakeDailySummaryStore()
        let first = makeService(tone: .gentle, store: store, userId: "uid-1")
        await first.generate(now: now)

        let tomorrow = now.addingTimeInterval(60 * 60 * 24)
        let second = makeService(store: store, userId: "uid-1", restoringAsOf: tomorrow)

        XCTAssertEqual(second.state, .idle)
        // The tone is a preference, not a record of a day — it survives the date it was chosen on.
        XCTAssertEqual(second.tone, .gentle)
    }

    func testAnotherAccountsSummaryIsNotRestored() async {
        let store = FakeDailySummaryStore()
        let first = makeService(tone: .coaching, store: store, userId: "uid-1")
        await first.generate(now: now)

        let second = makeService(store: store, userId: "uid-2", restoringAsOf: now)

        XCTAssertEqual(second.state, .idle)
        XCTAssertEqual(second.tone, .energizing)
    }

    func testChangingToneIsRemembered() {
        let store = FakeDailySummaryStore()
        let service = makeService(store: store, userId: "uid-1")

        service.tone = .bulleted

        XCTAssertEqual(store.snapshot?.tone, .bulleted)
    }

    /// A failed generation is a transient state; the summary already stored is still a true record
    /// of the day and must not be erased by it — including when the tone is changed afterwards.
    func testAFailedGenerationDoesNotEraseTheStoredSummary() async {
        let store = FakeDailySummaryStore()
        let generator = ToggleableDailySummaryGenerator()
        let service = makeService(generator: generator, store: store, userId: "uid-1")
        await service.generate(now: now)

        generator.shouldFail = true
        await service.generate(now: now)
        service.tone = .gentle

        XCTAssertEqual(service.state, .failed("generator unavailable"))
        XCTAssertEqual(store.snapshot?.summary?.content.headline, "stub headline")
    }

    /// The default configuration remembers nothing, so previews and tests never touch defaults.
    func testAServiceWithNoStoreStartsIdle() {
        XCTAssertEqual(makeService().state, .idle)
    }

    // MARK: - Helpers

    private func makeService(
        tone: DailySummaryTone = .energizing,
        provider: FakeDailySummaryDataProvider = FakeDailySummaryDataProvider(),
        generator: any DailySummaryGenerating = StubbedDailySummaryGenerator(),
        fallbackGenerator: (any DailySummaryGenerating)? = nil,
        store: (any DailySummaryStoring)? = nil,
        userId: String? = nil,
        restoringAsOf restoreDate: Date? = nil
    ) -> DailySummaryService {
        let service = DailySummaryService(
            provider: provider,
            generator: generator,
            fallbackGenerator: fallbackGenerator,
            store: store,
            userId: userId,
            now: restoreDate ?? now
        )
        // A restored service keeps the tone it was given back; only a fresh one takes the default.
        if restoreDate == nil { service.tone = tone }
        return service
    }
}

// MARK: - Fakes

private struct SimpleError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}

/// In-memory stand-in for `UserDefaultsDailySummaryStore` — the round trip through defaults is
/// covered in `DailySummarySnapshotTests`; these tests only care what the service hands it.
private final class FakeDailySummaryStore: DailySummaryStoring, @unchecked Sendable {
    private(set) var snapshot: DailySummarySnapshot?

    func read() -> DailySummarySnapshot? { snapshot }
    func write(_ snapshot: DailySummarySnapshot) { self.snapshot = snapshot }
}

private final class FakeDailySummaryDataProvider: DailySummaryDataProviding, @unchecked Sendable {
    var error: Error?
    private(set) var requestedTones: [DailySummaryTone] = []

    func loadRequest(tone: DailySummaryTone, date: Date) async throws -> DailySummaryRequest {
        requestedTones.append(tone)
        if let error { throw error }
        return DailySummaryRequest(
            date: date, tone: tone, tasks: [], focusSessions: [], journalEntries: [],
            capturesCount: 0, lifeAreaNames: [:], calendar: Calendar(identifier: .gregorian)
        )
    }
}

private struct StubbedDailySummaryGenerator: DailySummaryGenerating {
    var source: DailySummarySource { .localSynthesis }
    func generate(_ request: DailySummaryRequest) async throws -> DailySummaryContent {
        DailySummaryContent(
            headline: "stub headline", dopamineWins: [], journalReflections: "r",
            focusStaminaInsight: "f", gentleTomorrowKickstart: ["k"]
        )
    }
}

private struct FailingDailySummaryGenerator: DailySummaryGenerating {
    var source: DailySummarySource { .model }
    func generate(_ request: DailySummaryRequest) async throws -> DailySummaryContent {
        throw SimpleError("generator unavailable")
    }
}

/// A stand-in that is itself broken, so the "both failed" path has two distinguishable errors.
private struct SecondaryFailingDailySummaryGenerator: DailySummaryGenerating {
    var source: DailySummarySource { .localSynthesis }
    func generate(_ request: DailySummaryRequest) async throws -> DailySummaryContent {
        throw SimpleError("fallback unavailable")
    }
}

private final class ToggleableDailySummaryGenerator: DailySummaryGenerating, @unchecked Sendable {
    var shouldFail = false
    var source: DailySummarySource { .localSynthesis }
    func generate(_ request: DailySummaryRequest) async throws -> DailySummaryContent {
        if shouldFail { throw SimpleError("generator unavailable") }
        return DailySummaryContent(
            headline: "stub headline", dopamineWins: [], journalReflections: "r",
            focusStaminaInsight: "f", gentleTomorrowKickstart: ["k"]
        )
    }
}

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

    // MARK: - Helpers

    private func makeService(
        tone: DailySummaryTone = .energizing,
        provider: FakeDailySummaryDataProvider = FakeDailySummaryDataProvider(),
        generator: any DailySummaryGenerating = StubbedDailySummaryGenerator()
    ) -> DailySummaryService {
        let service = DailySummaryService(provider: provider, generator: generator)
        service.tone = tone
        return service
    }
}

// MARK: - Fakes

private struct SimpleError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
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

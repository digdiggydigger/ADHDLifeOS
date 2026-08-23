//
//  DailySummaryTestDoubles.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

// Shared by DailySummaryServiceTests and DailySummaryRebuildTests. Split out when the former
// crossed SwiftLint's file_length and type_body_length limits — the fakes are the same doubles
// either way, and duplicating them would let the two suites drift apart.

struct SimpleError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}

/// In-memory stand-in for `UserDefaultsDailySummaryStore` — the round trip through defaults is
/// covered in `DailySummarySnapshotTests`; these tests only care what the service hands it.
final class FakeDailySummaryStore: DailySummaryStoring, @unchecked Sendable {
    private(set) var snapshot: DailySummarySnapshot?

    func read() -> DailySummarySnapshot? { snapshot }
    func write(_ snapshot: DailySummarySnapshot) { self.snapshot = snapshot }
}

final class FakeDailySummaryDataProvider: DailySummaryDataProviding, @unchecked Sendable {
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

struct StubbedDailySummaryGenerator: DailySummaryGenerating {
    var source: DailySummarySource { .localSynthesis }
    func generate(_ request: DailySummaryRequest) async throws -> DailySummaryContent {
        DailySummaryContent(
            headline: "stub headline", dopamineWins: [], journalReflections: "r",
            focusStaminaInsight: "f", gentleTomorrowKickstart: ["k"]
        )
    }
}

struct FailingDailySummaryGenerator: DailySummaryGenerating {
    var source: DailySummarySource { .model }
    func generate(_ request: DailySummaryRequest) async throws -> DailySummaryContent {
        throw SimpleError("generator unavailable")
    }
}

/// A stand-in that is itself broken, so the "both failed" path has two distinguishable errors.
struct SecondaryFailingDailySummaryGenerator: DailySummaryGenerating {
    var source: DailySummarySource { .localSynthesis }
    func generate(_ request: DailySummaryRequest) async throws -> DailySummaryContent {
        throw SimpleError("fallback unavailable")
    }
}

/// Holds generation open until a test releases it, so "mid-flight" is a state the test can stand
/// in rather than a race it has to win. Counts its calls so joining a generation is
/// distinguishable from paying for a second one.
actor GatedDailySummaryGenerator: DailySummaryGenerating {
    private let gate: Gate
    private(set) var callCount = 0

    init(gate: Gate) {
        self.gate = gate
    }

    nonisolated var source: DailySummarySource { .model }

    func generate(_ request: DailySummaryRequest) async throws -> DailySummaryContent {
        callCount += 1
        await gate.wait()
        return DailySummaryContent(
            headline: "gated headline", dopamineWins: [], journalReflections: "r",
            focusStaminaInsight: "f", gentleTomorrowKickstart: ["k"]
        )
    }
}

/// The failing counterpart to `GatedDailySummaryGenerator`, and it exists for the same reason.
/// A generator that throws *immediately* can start and finish inside a single scheduling slice,
/// so a test waiting to observe "generating" may be waiting for a state that was never visible.
/// That race is lost only under load — which is exactly when it is hardest to read as a race
/// rather than a real failure. Holding the failure behind the gate makes mid-flight a state the
/// test stands in, rather than one it has to catch.
actor GatedFailingDailySummaryGenerator: DailySummaryGenerating {
    private let gate: Gate

    init(gate: Gate) {
        self.gate = gate
    }

    nonisolated var source: DailySummarySource { .model }

    func generate(_ request: DailySummaryRequest) async throws -> DailySummaryContent {
        await gate.wait()
        throw SimpleError("generator unavailable")
    }
}

final class ToggleableDailySummaryGenerator: DailySummaryGenerating, @unchecked Sendable {
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

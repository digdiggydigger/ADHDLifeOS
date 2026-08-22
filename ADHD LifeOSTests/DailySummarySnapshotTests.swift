//
//  DailySummarySnapshotTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The record the Daily Executive Summary card keeps between appearances, and the two guards that
/// decide whether it may be read back: it must belong to the signed-in account, and it must be a
/// record of the day being shown. Both are pure — no view, no defaults, no clock.
final class DailySummarySnapshotTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)
    private let monday = Date(timeIntervalSince1970: 1_787_000_000)

    private func sampleSummary(generatedAt: Date) -> GeneratedDailySummary {
        GeneratedDailySummary(
            content: DailySummaryContent(
                headline: "Three finished today.",
                dopamineWins: ["Shipped the capture fix."],
                journalReflections: "1 entry written today.",
                focusStaminaInsight: "42 minutes of focused work today.",
                gentleTomorrowKickstart: ["Start with the smallest one."]
            ),
            tone: .coaching,
            generatedAt: generatedAt,
            source: .model
        )
    }

    private func sampleSnapshot(
        userId: String? = "uid-1",
        tone: DailySummaryTone = .coaching,
        generatedAt: Date? = nil
    ) -> DailySummarySnapshot {
        DailySummarySnapshot(
            userId: userId,
            tone: tone,
            summary: generatedAt.map(sampleSummary)
        )
    }

    // MARK: - Model

    func testInitStampsTheCurrentVersion() {
        XCTAssertEqual(sampleSnapshot().version, DailySummarySnapshot.currentVersion)
    }

    func testCodableRoundTripPreservesEveryField() throws {
        let original = sampleSnapshot(generatedAt: monday)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DailySummarySnapshot.self, from: data)

        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.summary?.source, .model)
        XCTAssertEqual(decoded.summary?.tone, .coaching)
    }

    // MARK: - Ownership

    func testASnapshotBelongsToTheAccountThatWroteIt() {
        XCTAssertTrue(sampleSnapshot(userId: "uid-1").belongs(to: "uid-1"))
    }

    /// The summary carries task titles and journal reflections. Another account signing in on the
    /// same device must never be handed them.
    func testASnapshotDoesNotBelongToADifferentAccount() {
        XCTAssertFalse(sampleSnapshot(userId: "uid-1").belongs(to: "uid-2"))
    }

    /// An unattributed snapshot is unclaimable rather than universally claimable — "nobody wrote
    /// this" must not read as "everybody may have it".
    func testAnUnattributedSnapshotBelongsToNobody() {
        XCTAssertFalse(sampleSnapshot(userId: nil).belongs(to: "uid-1"))
        XCTAssertFalse(sampleSnapshot(userId: nil).belongs(to: nil))
        XCTAssertFalse(sampleSnapshot(userId: "uid-1").belongs(to: nil))
    }

    // MARK: - Same-day guard

    func testASummaryIsReadableLaterOnTheSameDay() {
        let tenMinutesLater = monday.addingTimeInterval(600)
        let snapshot = sampleSnapshot(generatedAt: monday)

        XCTAssertEqual(
            snapshot.summary(on: tenMinutesLater, calendar: calendar)?.generatedAt, monday
        )
    }

    /// Yesterday's summary is a true record of yesterday. Presenting it as today's would be a lie,
    /// so it is dropped and the card falls back to its idle synthesis.
    func testASummaryFromAnEarlierDayIsNotReadableToday() {
        let nextDay = monday.addingTimeInterval(60 * 60 * 24)
        let snapshot = sampleSnapshot(generatedAt: monday)

        XCTAssertNil(snapshot.summary(on: nextDay, calendar: calendar))
    }

    func testASnapshotWithNoSummaryReadsBackAsNothing() {
        XCTAssertNil(sampleSnapshot(generatedAt: nil).summary(on: monday, calendar: calendar))
    }

    // MARK: - Store

    private func makeDefaults(
        _ suiteName: String = "DailySummarySnapshotTests"
    ) -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    func testStoreRoundTripsASnapshot() {
        let store = UserDefaultsDailySummaryStore(defaults: makeDefaults())
        let snapshot = sampleSnapshot(tone: .gentle, generatedAt: monday)

        store.write(snapshot)

        XCTAssertEqual(store.read(), snapshot)
    }

    func testStoreReadsNothingBeforeAnythingIsWritten() {
        XCTAssertNil(UserDefaultsDailySummaryStore(defaults: makeDefaults()).read())
    }

    /// Same rule as `FocusWidgetSnapshotStore`: a payload stamped with a version this build doesn't
    /// know is discarded rather than half-decoded.
    func testStoreRefusesASnapshotFromAnUnknownVersion() throws {
        let defaults = makeDefaults()
        let store = UserDefaultsDailySummaryStore(defaults: defaults)
        var raw = try XCTUnwrap(
            JSONSerialization.jsonObject(
                with: try JSONEncoder().encode(sampleSnapshot(generatedAt: monday))
            ) as? [String: Any]
        )
        raw["version"] = DailySummarySnapshot.currentVersion + 1
        defaults.set(
            try JSONSerialization.data(withJSONObject: raw),
            forKey: UserDefaultsDailySummaryStore.snapshotKey
        )

        XCTAssertNil(store.read())
    }

    func testStoreRefusesCorruptData() {
        let defaults = makeDefaults()
        let store = UserDefaultsDailySummaryStore(defaults: defaults)
        defaults.set(Data("not json".utf8), forKey: UserDefaultsDailySummaryStore.snapshotKey)

        XCTAssertNil(store.read())
    }

    /// Unavailable defaults degrade to "remembers nothing" rather than trapping — the card still
    /// works, it just forgets.
    func testStoreWithNoDefaultsIsAHarmlessNoOp() {
        let store = UserDefaultsDailySummaryStore(defaults: nil)
        store.write(sampleSnapshot(generatedAt: monday))
        XCTAssertNil(store.read())
    }
}

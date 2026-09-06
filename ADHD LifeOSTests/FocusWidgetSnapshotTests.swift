//
//  FocusWidgetSnapshotTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The compact payload the app publishes into the App Group for the Home Screen widget to read.
/// The widget extension has no Firebase, so this file IS the contract between the two processes —
/// it has to survive a round trip, and it has to refuse anything it doesn't recognise rather than
/// render a half-decoded stat.
final class FocusWidgetSnapshotTests: XCTestCase {
    private let suiteName = "FocusWidgetSnapshotTests"

    private func makeDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func sampleSnapshot(generatedAt: Date = Date(timeIntervalSince1970: 1_800_000_000)) -> FocusWidgetSnapshot {
        FocusWidgetSnapshot(
            generatedAt: generatedAt,
            activeGoal: FocusWidgetSnapshot.ActiveGoal(
                title: "Take a 10-minute walk",
                lifeAreaName: "Health",
                emoji: "🫀",
                focusDurationSeconds: 900,
                nudgeCount: 10
            ),
            week: FocusWidgetSnapshot.WeekStats(
                focusedSeconds: 1260,
                sessionCount: 3,
                activeDayCount: 1,
                dailyAverageSeconds: 180,
                streak: 1,
                dailyGoalMinutes: 30,
                dailyFocusedSeconds: [0, 0, 1260, 0, 0, 0, 0]
            )
        )
    }

    // MARK: - Model

    func testInit_stampsTheCurrentVersion() {
        XCTAssertEqual(sampleSnapshot().version, FocusWidgetSnapshot.currentVersion)
    }

    func testCodableRoundTrip_preservesEveryField() throws {
        let original = sampleSnapshot()

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FocusWidgetSnapshot.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    func testGoalProgress_isDerivedFromTheWeekAgainstTheDailyGoal() {
        // 1260s logged against 7 days × 30m of goal.
        let week = sampleSnapshot().week
        XCTAssertEqual(week.goalProgress, 1260.0 / (30.0 * 60.0 * 7.0), accuracy: 0.0001)
    }

    func testGoalProgress_clampsToOne() {
        let week = FocusWidgetSnapshot.WeekStats(
            focusedSeconds: 999_999, sessionCount: 9, activeDayCount: 7,
            dailyAverageSeconds: 9999, streak: 7, dailyGoalMinutes: 30,
            dailyFocusedSeconds: Array(repeating: 99_999, count: 7)
        )

        XCTAssertEqual(week.goalProgress, 1)
    }

    func testGoalProgress_withNoGoal_isZeroRatherThanInfinite() {
        let week = FocusWidgetSnapshot.WeekStats(
            focusedSeconds: 600, sessionCount: 1, activeDayCount: 1,
            dailyAverageSeconds: 85, streak: 1, dailyGoalMinutes: 0,
            dailyFocusedSeconds: [600, 0, 0, 0, 0, 0, 0]
        )

        XCTAssertEqual(week.goalProgress, 0)
    }

    func testPlaceholder_hasNoFabricatedHistory() {
        // The gallery preview must never invent focus time the user hasn't done.
        let placeholder = FocusWidgetSnapshot.placeholder

        XCTAssertEqual(placeholder.week.focusedSeconds, 0)
        XCTAssertEqual(placeholder.week.dailyFocusedSeconds.count, 7)
        XCTAssertNil(placeholder.activeGoal)
    }

    // MARK: - Store

    func testStore_writeThenRead_returnsTheSameSnapshot() {
        let store = FocusWidgetSnapshotStore(defaults: makeDefaults())
        let snapshot = sampleSnapshot()

        store.write(snapshot)

        XCTAssertEqual(store.read(), snapshot)
    }

    func testStore_readOnAFreshInstall_isNil() {
        let store = FocusWidgetSnapshotStore(defaults: makeDefaults())

        XCTAssertNil(store.read(), "nothing published yet — the widget shows its empty state")
    }

    func testStore_readRejectsAForeignVersion() throws {
        let defaults = makeDefaults()
        // A structurally VALID payload stamped by a future build of the app: it decodes cleanly,
        // so only the version guard can reject it. Numbers this build can't vouch for must not
        // reach the Home Screen.
        var future = try XCTUnwrap(
            String(data: try JSONEncoder().encode(sampleSnapshot()), encoding: .utf8)
        )
        future = future.replacingOccurrences(
            of: "\"version\":\(FocusWidgetSnapshot.currentVersion)", with: "\"version\":99"
        )
        XCTAssertTrue(
            future.contains("\"version\":99"),
            "the version stamp must be rewritten for this test to mean anything"
        )
        defaults.set(Data(future.utf8), forKey: FocusWidgetSnapshotStore.snapshotKey)

        XCTAssertNil(FocusWidgetSnapshotStore(defaults: defaults).read())
    }

    func testStore_readRejectsCorruptData() {
        let defaults = makeDefaults()
        defaults.set(Data("not json".utf8), forKey: FocusWidgetSnapshotStore.snapshotKey)

        XCTAssertNil(FocusWidgetSnapshotStore(defaults: defaults).read())
    }

    func testStore_withNoAppGroupContainer_readsAndWritesWithoutCrashing() {
        // `UserDefaults(suiteName:)` returns nil if the entitlement isn't provisioned; the app must
        // degrade to "no widget data", never trap.
        let store = FocusWidgetSnapshotStore(defaults: nil)

        store.write(sampleSnapshot())

        XCTAssertNil(store.read())
    }

    func testStore_overwritesThePreviousSnapshot() {
        let store = FocusWidgetSnapshotStore(defaults: makeDefaults())
        store.write(sampleSnapshot())

        let newer = sampleSnapshot(generatedAt: Date(timeIntervalSince1970: 1_800_009_999))
        store.write(newer)

        XCTAssertEqual(store.read()?.generatedAt, newer.generatedAt)
    }

    func testStore_clearRemovesTheStoredSnapshot() {
        // The session-end sweep (E's fold call, 2026-09-06): the payload carries no owner field
        // and its reader is the widget process, which has no auth concept — so unless the store
        // is actually emptied, the last user's task titles keep rendering after sign-out.
        let store = FocusWidgetSnapshotStore(defaults: makeDefaults())
        store.write(sampleSnapshot())
        XCTAssertNotNil(store.read(), "the write must land for the clear to prove anything")

        store.clear()

        XCTAssertNil(store.read())
    }

    func testStore_clearWithNoAppGroupContainer_doesNotCrash() {
        FocusWidgetSnapshotStore(defaults: nil).clear()
    }
}

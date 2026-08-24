//
//  MomentumPreferencesTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// "What counts as momentum" — the scoreboard's preferences: the daily goal behind the closure
/// ring, the streak toggle, and the two counting toggles their event stamps eventually earned
/// (captures' `clearedAt` in M7, nudges' `last_fired_at` in M9). Stored in app-local UserDefaults
/// behind a protocol seam, the `DailySummaryStoring` arrangement.
final class MomentumPreferencesTests: XCTestCase {

    func testDefaults_matchTheConceptsSeed() {
        XCTAssertEqual(MomentumPreferences.default.dailyGoal, 5)
        XCTAssertTrue(MomentumPreferences.default.showStreaks)
    }

    /// The ring divides by this number and the Stepper can't be trusted to be the only writer —
    /// a decoded document, a migration, or a future writer all pass through `normalized()`.
    func testNormalized_clampsTheGoalIntoTheSupportedRange() {
        XCTAssertEqual(MomentumPreferences(dailyGoal: 0, showStreaks: true).normalized().dailyGoal, 1)
        XCTAssertEqual(MomentumPreferences(dailyGoal: 99, showStreaks: true).normalized().dailyGoal, 12)
        XCTAssertEqual(MomentumPreferences(dailyGoal: 7, showStreaks: false).normalized().dailyGoal, 7)
    }

    func testDefaults_captureCountingStartsOff() {
        XCTAssertFalse(MomentumPreferences.default.countClearedCaptures)
    }

    /// Preferences stored by the M2 build predate this key. They must decode with the user's
    /// goal and streak choice INTACT — resetting someone's goal because we added a toggle would
    /// be a silent data loss.
    func testDecode_legacyPreferencesWithoutTheNewKey_keepTheirValues() throws {
        let legacy = Data(#"{"dailyGoal":8,"showStreaks":false}"#.utf8)

        let decoded = try JSONDecoder().decode(MomentumPreferences.self, from: legacy)

        XCTAssertEqual(decoded.dailyGoal, 8)
        XCTAssertFalse(decoded.showStreaks)
        XCTAssertFalse(decoded.countClearedCaptures)
        XCTAssertFalse(decoded.countNudges)
    }

    func testDefaults_nudgeCountingStartsOff() {
        XCTAssertFalse(MomentumPreferences.default.countNudges)
    }

    /// Preferences stored by the M7 build predate `countNudges`. Same contract as the M2
    /// migration above: adding a toggle must never reset what the user already chose.
    func testDecode_m7EraPreferencesWithoutTheNudgeKey_keepTheirValues() throws {
        let m7Era = Data(#"{"dailyGoal":8,"showStreaks":false,"countClearedCaptures":true}"#.utf8)

        let decoded = try JSONDecoder().decode(MomentumPreferences.self, from: m7Era)

        XCTAssertEqual(decoded.dailyGoal, 8)
        XCTAssertFalse(decoded.showStreaks)
        XCTAssertTrue(decoded.countClearedCaptures)
        XCTAssertFalse(decoded.countNudges)
    }

    /// Display-only, so it ships at the concept's own default (on) — unlike the counting
    /// toggles, an enabled chart cannot misstate anything.
    func testDefaults_chartsStartOn() {
        XCTAssertTrue(MomentumPreferences.default.showCharts)
    }

    /// Preferences stored by the M9 build predate `showCharts`; the migration contract again.
    func testDecode_m9EraPreferencesWithoutTheChartsKey_keepTheirValues() throws {
        let m9Era = Data(
            #"{"dailyGoal":8,"showStreaks":false,"countClearedCaptures":true,"countNudges":true}"#.utf8
        )

        let decoded = try JSONDecoder().decode(MomentumPreferences.self, from: m9Era)

        XCTAssertEqual(decoded.dailyGoal, 8)
        XCTAssertFalse(decoded.showStreaks)
        XCTAssertTrue(decoded.countClearedCaptures)
        XCTAssertTrue(decoded.countNudges)
        XCTAssertTrue(decoded.showCharts)
    }

    // MARK: - Store

    private func makeStore() -> (store: UserDefaultsMomentumPreferencesStore, defaults: UserDefaults) {
        let suiteName = "MomentumPreferencesTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (UserDefaultsMomentumPreferencesStore(defaults: defaults), defaults)
    }

    func testStore_roundTripsPreferences() {
        let (store, _) = makeStore()
        let prefs = MomentumPreferences(dailyGoal: 8, showStreaks: false)

        store.write(prefs)

        XCTAssertEqual(store.read(), prefs)
    }

    func testStore_emptyDefaultsReadAsTheDefaults() {
        let (store, _) = makeStore()

        XCTAssertEqual(store.read(), .default)
    }

    /// Corrupt data degrades to the defaults instead of trapping — forgetful, never broken.
    func testStore_corruptDataReadsAsTheDefaults() {
        let (store, defaults) = makeStore()
        defaults.set(Data("not json".utf8), forKey: UserDefaultsMomentumPreferencesStore.preferencesKey)

        XCTAssertEqual(store.read(), .default)
    }

    /// An out-of-range goal written by anything (an old build, a bad migration) comes back
    /// clamped, so the ring can never divide by zero.
    func testStore_readNormalizesWhatItFinds() throws {
        let (store, defaults) = makeStore()
        let rogue = try JSONEncoder().encode(MomentumPreferences(dailyGoal: 0, showStreaks: true))
        defaults.set(rogue, forKey: UserDefaultsMomentumPreferencesStore.preferencesKey)

        XCTAssertEqual(store.read().dailyGoal, 1)
    }
}

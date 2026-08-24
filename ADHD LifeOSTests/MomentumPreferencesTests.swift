//
//  MomentumPreferencesTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// "What counts as momentum" — the scoreboard's two live preferences: the daily goal behind the
/// closure ring and the streak toggle. Stored in app-local UserDefaults behind a protocol seam,
/// the `DailySummaryStoring` arrangement. (The concept's capture/nudge counting toggles are
/// deliberately NOT here — nothing stamps when a capture clears or a nudge fires "done", so the
/// ring could not honestly count them yet.)
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

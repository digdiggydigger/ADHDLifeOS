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

    // MARK: - Settings additions (E's 2026-08-25 audit)

    func testDefaults_settingsAdditionsStartAtTodaysBehaviour() {
        let defaults = MomentumPreferences.default
        XCTAssertEqual(defaults.focusDailyGoalMinutes, 30, "the analytics goal ships at its old constant")
        XCTAssertEqual(defaults.defaultSprintMinutes, 15, "the sprint default ships at standardDurationSeconds")
        XCTAssertTrue(defaults.hapticsEnabled)
        XCTAssertTrue(defaults.soundEnabled)
    }

    func testDecode_preSettingsPayloadKeepsChoicesAndGainsTheDefaults() throws {
        let legacy = #"{"dailyGoal":7,"showStreaks":false,"countClearedCaptures":true,"#
            + #""countNudges":true,"showCharts":false}"#
        let decoded = try JSONDecoder().decode(MomentumPreferences.self, from: Data(legacy.utf8))

        XCTAssertEqual(decoded.dailyGoal, 7, "existing choices must survive the upgrade")
        XCTAssertFalse(decoded.showStreaks)
        XCTAssertEqual(decoded.focusDailyGoalMinutes, 30)
        XCTAssertEqual(decoded.defaultSprintMinutes, 15)
        XCTAssertTrue(decoded.hapticsEnabled)
        XCTAssertTrue(decoded.soundEnabled)
    }

    func testNormalized_clampsTheNewSteppersIntoTheirRanges() {
        var preferences = MomentumPreferences.default
        preferences.focusDailyGoalMinutes = 999
        preferences.defaultSprintMinutes = 0

        let normalized = preferences.normalized()

        XCTAssertEqual(normalized.focusDailyGoalMinutes, MomentumPreferences.focusGoalRange.upperBound)
        XCTAssertEqual(normalized.defaultSprintMinutes, MomentumPreferences.sprintMinutesRange.lowerBound)
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

    // MARK: - Location switches (block 4b)

    func testDecode_missingArrivalNudgesReadsAsOn() throws {
        let legacy = #"{"dailyGoal":7,"showStreaks":false}"#
        let decoded = try JSONDecoder().decode(MomentumPreferences.self, from: Data(legacy.utf8))

        XCTAssertTrue(decoded.arrivalNudgesEnabled)
    }

    /// The bug this pins (found 2026-08-27): `normalized()` rebuilt the struct WITHOUT the
    /// location flags, so both `read()` and `write()` silently reset them to their defaults —
    /// the Settings toggle could never actually stick off.
    func testNormalized_preservesTheLocationSwitches() {
        var preferences = MomentumPreferences.default
        preferences.locationTaggingEnabled = false
        preferences.arrivalNudgesEnabled = false

        let normalized = preferences.normalized()

        XCTAssertFalse(normalized.locationTaggingEnabled, "off must survive normalization")
        XCTAssertFalse(normalized.arrivalNudgesEnabled, "off must survive normalization")
    }

    // MARK: - The celebration switches (F-CTACelebrations-2; E's #3 and F5)

    /// E's #3: the full-screen celebrations are ON by default, because playing them is what the app
    /// already does and the switch exists to turn that off. F5: the chime is OFF by default — a
    /// sound nobody asked for is the one kind of feedback that cannot be politely ignored.
    func testDefaults_celebrationsOnAndCelebrationSoundsOff() {
        XCTAssertTrue(MomentumPreferences.default.celebrationsEnabled)
        XCTAssertFalse(MomentumPreferences.default.celebrationSoundsEnabled)
    }

    /// Every preferences blob already on a phone predates both keys, so both have to arrive at
    /// their defaults with the rest of the document untouched. `celebrationsEnabled` must come back
    /// TRUE: spelled `?? false`, the upgrade would silently turn the celebrations off for everyone
    /// who already has the app — the one direction a migration bug here can go unnoticed.
    func testDecode_preCelebrationPayloadKeepsChoicesAndGainsTheSwitchDefaults() throws {
        let legacy = #"{"dailyGoal":7,"showStreaks":false,"hapticsEnabled":false,"soundEnabled":false}"#
        let decoded = try JSONDecoder().decode(MomentumPreferences.self, from: Data(legacy.utf8))

        XCTAssertEqual(decoded.dailyGoal, 7, "existing choices must survive the upgrade")
        XCTAssertFalse(decoded.hapticsEnabled, "and so must the switches the user already turned off")
        XCTAssertTrue(decoded.celebrationsEnabled, "a missing key must read as ON, never as Bool's zero value")
        XCTAssertFalse(decoded.celebrationSoundsEnabled)
    }

    /// `testNormalized_preservesTheLocationSwitches`' bug in its general form, and the reason the
    /// record calls this a FOUR-place edit: `normalized()` rebuilds the struct field by field, so a
    /// field it forgets silently resets on every read AND write.
    ///
    /// Both switches are set AWAY from their defaults on purpose. Asserting a field's own default
    /// value proves nothing, because the omission this test exists to catch resets it to exactly
    /// that — an assertion that `celebrationSoundsEnabled` is still `false` would be green on the
    /// broken tree.
    func testNormalized_preservesBothCelebrationSwitchesAwayFromTheirDefaults() {
        var preferences = MomentumPreferences.default
        preferences.celebrationsEnabled = false
        preferences.celebrationSoundsEnabled = true

        let normalized = preferences.normalized()

        XCTAssertFalse(normalized.celebrationsEnabled, "off must survive normalization")
        XCTAssertTrue(normalized.celebrationSoundsEnabled, "on must survive normalization")
    }

    /// The same property through the real store, which normalizes on both sides — so this is the
    /// end-to-end version of the row actually sticking where the user left it.
    func testStore_roundTripsBothCelebrationSwitchesAwayFromTheirDefaults() {
        let (store, _) = makeStore()
        var prefs = MomentumPreferences.default
        prefs.celebrationsEnabled = false
        prefs.celebrationSoundsEnabled = true

        store.write(prefs)

        XCTAssertFalse(store.read().celebrationsEnabled)
        XCTAssertTrue(store.read().celebrationSoundsEnabled)
    }

    func testStore_roundTripsTheLocationSwitchesOff() {
        let (store, _) = makeStore()
        var prefs = MomentumPreferences.default
        prefs.locationTaggingEnabled = false
        prefs.arrivalNudgesEnabled = false

        store.write(prefs)

        XCTAssertFalse(store.read().locationTaggingEnabled)
        XCTAssertFalse(store.read().arrivalNudgesEnabled)
    }
}

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

    /// REVERSED (`F-E1-WeeklyChain`). The seed was a daily goal of 5 that nobody chose — HOME-10.
    /// E's round 3: *"Preset goals → 'Off until you set one.' No ring and no percentage until the
    /// user chooses a goal in Settings."* Round 5b: the weekly chain's N is *"3 days"*.
    func testDefaults_goalsAreOffUntilSetAndTheChainAsksForThreeDays() {
        XCTAssertNil(MomentumPreferences.default.dailyGoal, "no daily close goal until the user sets one")
        XCTAssertNil(MomentumPreferences.default.focusDailyGoalMinutes, "no daily focus goal until set")
        XCTAssertEqual(MomentumPreferences.default.weeklyActiveDayGoal, 3)
        XCTAssertTrue(MomentumPreferences.default.showStreaks, "the chain's display is on by default")
    }

    /// REVERSED: the clamp still guards a SET goal, and an unset one passes through as unset —
    /// `normalized()` must never turn "no goal" into a goal of 1.
    func testNormalized_clampsTheGoalIntoTheSupportedRange() {
        XCTAssertEqual(MomentumPreferences(dailyGoal: 0, showStreaks: true).normalized().dailyGoal, 1)
        XCTAssertEqual(MomentumPreferences(dailyGoal: 99, showStreaks: true).normalized().dailyGoal, 12)
        XCTAssertEqual(MomentumPreferences(dailyGoal: 7, showStreaks: false).normalized().dailyGoal, 7)
        XCTAssertNil(MomentumPreferences(dailyGoal: nil, showStreaks: true).normalized().dailyGoal)
        var focus = MomentumPreferences.default
        focus.focusDailyGoalMinutes = nil
        XCTAssertNil(focus.normalized().focusDailyGoalMinutes)
    }

    func testNormalized_clampsTheWeeklyChainGoalIntoOneToSeven() {
        var preferences = MomentumPreferences.default
        preferences.weeklyActiveDayGoal = 0
        XCTAssertEqual(preferences.normalized().weeklyActiveDayGoal, 1)
        preferences.weeklyActiveDayGoal = 9
        XCTAssertEqual(preferences.normalized().weeklyActiveDayGoal, 7)
        preferences.weeklyActiveDayGoal = 4
        XCTAssertEqual(preferences.normalized().weeklyActiveDayGoal, 4)
    }

    // MARK: - Goals off until set: the migration (`F-E1-WeeklyChain`)

    /// Every install before E1 stored 5 and 30 because those were the defaults, not because anyone
    /// chose them (HOME-10) — so they decode as "no goal". A stored value the user DID move the
    /// Stepper to is a choice, and survives (the `…keepTheirValues` tests below hold that line).
    func testDecode_preChainPayloadWithTheOldDefaultsReadsAsNoGoal() throws {
        let legacy = Data(#"{"dailyGoal":5,"showStreaks":true,"focusDailyGoalMinutes":30}"#.utf8)

        let decoded = try JSONDecoder().decode(MomentumPreferences.self, from: legacy)

        XCTAssertNil(decoded.dailyGoal)
        XCTAssertNil(decoded.focusDailyGoalMinutes)
        XCTAssertEqual(decoded.weeklyActiveDayGoal, 3, "a pre-chain payload gains the chain's default")
    }

    func testDecode_preChainPayloadKeepsAGoalTheUserMoved() throws {
        let legacy = Data(#"{"dailyGoal":8,"showStreaks":true,"focusDailyGoalMinutes":45}"#.utf8)

        let decoded = try JSONDecoder().decode(MomentumPreferences.self, from: legacy)

        XCTAssertEqual(decoded.dailyGoal, 8)
        XCTAssertEqual(decoded.focusDailyGoalMinutes, 45)
    }

    /// **The trap the naive rule falls into.** "Stored 5 means nobody chose it" is only true of a
    /// document written BEFORE E1. After it, 5 is exactly what someone who turns the goal on and
    /// leaves the Stepper alone has chosen — and erasing it on the next launch would be a silent
    /// reset of a real choice. The chain's key is the version marker: present means post-E1.
    func testDecode_postChainPayloadKeepsAGoalOfFiveThatWasChosen() throws {
        let chosen = MomentumPreferences(dailyGoal: 5, showStreaks: true, focusDailyGoalMinutes: 30)

        let decoded = try JSONDecoder().decode(
            MomentumPreferences.self, from: JSONEncoder().encode(chosen)
        )

        XCTAssertEqual(decoded.dailyGoal, 5)
        XCTAssertEqual(decoded.focusDailyGoalMinutes, 30)
    }

    func testStore_roundTripsGoalsLeftOff() {
        let (store, _) = makeStore()
        var prefs = MomentumPreferences.default
        prefs.weeklyActiveDayGoal = 5

        store.write(prefs)

        XCTAssertEqual(store.read(), prefs)
        XCTAssertNil(store.read().dailyGoal)
        XCTAssertNil(store.read().focusDailyGoalMinutes)
    }

    /// Settings' "Set a daily goal" toggle: on starts the Stepper at the old seed, off clears it —
    /// and turning it on again after moving the Stepper keeps nothing stale.
    func testSettingTheDailyGoalOnAndOff() {
        var prefs = MomentumPreferences.default
        prefs.setDailyGoalEnabled(true)
        XCTAssertEqual(prefs.dailyGoal, MomentumPreferences.dailyGoalStartingValue)
        XCTAssertEqual(MomentumPreferences.dailyGoalStartingValue, 5)
        prefs.dailyGoal = 9
        prefs.setDailyGoalEnabled(true)
        XCTAssertEqual(prefs.dailyGoal, 9, "an already-set goal is not reset by a redundant on")
        prefs.setDailyGoalEnabled(false)
        XCTAssertNil(prefs.dailyGoal)
    }

    func testSettingTheFocusGoalOnAndOff() {
        var prefs = MomentumPreferences.default
        prefs.setFocusGoalEnabled(true)
        XCTAssertEqual(prefs.focusDailyGoalMinutes, MomentumPreferences.focusGoalStartingMinutes)
        XCTAssertEqual(MomentumPreferences.focusGoalStartingMinutes, 30)
        prefs.setFocusGoalEnabled(false)
        XCTAssertNil(prefs.focusDailyGoalMinutes)
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
        // REVERSED (`F-E1-WeeklyChain`): the focus goal was always on at 30; round 3 turns it off.
        XCTAssertNil(defaults.focusDailyGoalMinutes, "the analytics goal is off until the user sets one")
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
        XCTAssertNil(decoded.focusDailyGoalMinutes, "REVERSED (F-E1): an absent focus goal is no goal")
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

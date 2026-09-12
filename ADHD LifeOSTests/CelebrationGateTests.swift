//
//  CelebrationGateTests.swift
//  ADHD LifeOSTests
//
//  `F-CTACelebrations-2`: the two celebration gates on `AppFeedback`, the home every "read at FIRE
//  time" preference lives in (E's 2026-08-25 audit, and `hapticsEnabled()`'s own arrangement).
//
//  The property under test is not "does it return the stored Bool" but "does it return TODAY's
//  stored Bool" — a gate that read once and cached would need a relaunch to take effect, which is
//  precisely the bug this arrangement exists to avoid. So each test reads, changes the stored
//  preference, and reads again through the same gate.
//

import XCTest
@testable import ADHD_LifeOS

final class CelebrationGateTests: XCTestCase {

    /// Test double for the preferences seam: the real store reads `UserDefaults.standard`, which
    /// would leak the running simulator's own settings into these assertions (and would let a test
    /// write E's).
    private final class FakePreferencesStore: MomentumPreferencesStoring {
        var preferences: MomentumPreferences

        init(_ preferences: MomentumPreferences) { self.preferences = preferences }

        func read() -> MomentumPreferences { preferences.normalized() }
        func write(_ preferences: MomentumPreferences) { self.preferences = preferences.normalized() }
    }

    private func store(celebrations: Bool, sounds: Bool) -> FakePreferencesStore {
        var preferences = MomentumPreferences.default
        preferences.celebrationsEnabled = celebrations
        preferences.celebrationSoundsEnabled = sounds
        return FakePreferencesStore(preferences)
    }

    /// E's #3: one switch over every full-screen celebration. The celebration layer evaluates this
    /// as each Confirm lands, so the answer has to follow the switch with no relaunch.
    func testCelebrationsEnabled_followsTheStoredSwitchOnEveryRead() {
        let store = self.store(celebrations: true, sounds: false)

        XCTAssertTrue(AppFeedback.celebrationsEnabled(store: store))

        store.preferences.celebrationsEnabled = false

        XCTAssertFalse(
            AppFeedback.celebrationsEnabled(store: store),
            "the gate answered from a cached read, so flipping the switch would need a relaunch"
        )
    }

    /// E's F5: the chime is its own switch, so turning the celebrations' sound off must not touch
    /// the celebrations themselves — and the two gates must not read each other's field.
    func testCelebrationSoundsEnabled_followsTheStoredSwitchOnEveryRead() {
        let store = self.store(celebrations: true, sounds: false)

        XCTAssertFalse(AppFeedback.celebrationSoundsEnabled(store: store))

        store.preferences.celebrationSoundsEnabled = true

        XCTAssertTrue(
            AppFeedback.celebrationSoundsEnabled(store: store),
            "the gate answered from a cached read, so flipping the switch would need a relaunch"
        )
        XCTAssertTrue(
            AppFeedback.celebrationsEnabled(store: store),
            "turning the chime on changed the Celebrations switch, so the two gates share a field"
        )
    }
}

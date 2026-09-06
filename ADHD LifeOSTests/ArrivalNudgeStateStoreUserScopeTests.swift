//
//  ArrivalNudgeStateStoreUserScopeTests.swift
//  ADHD LifeOSTests
//
//  The snapshot sign-out leak — the family's third member, folded on E's word (2026-09-06;
//  run store and tray were F-RoutineRecord-1). The at-place snapshot carries one account's
//  place names and custom messages in app-local UserDefaults, and until this it survived
//  sign-out: the next account's background wake could nudge with the previous account's
//  words. Same fix as `RoutineRunStoreUserScopeTests` pins for the run store: keys scoped
//  per user, the scope read at call time, and a session ending sweeps every user's keys.
//  The cooldowns are scoped with it — they are that account's bounce history, and a fresh
//  account must not inherit a suppressed place from the last one.
//

import XCTest
@testable import ADHD_LifeOS

final class ArrivalNudgeStateStoreUserScopeTests: XCTestCase {
    private let noon = Date(timeIntervalSince1970: 1_756_296_000)

    private func scratchDefaults() -> UserDefaults {
        let name = "arrival-scope-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    func testASnapshotWrittenByOneUser_isInvisibleToAnother() {
        let defaults = scratchDefaults()
        let alice = UserDefaultsArrivalNudgeStateStore(defaults: defaults, userScope: { "alice" })
        let bob = UserDefaultsArrivalNudgeStateStore(defaults: defaults, userScope: { "bob" })

        alice.writeSnapshot(snapshot())
        alice.writeCooldowns(cooldowns())

        XCTAssertNotNil(alice.readSnapshot())
        XCTAssertNil(bob.readSnapshot(), "Bob's wake must never nudge with Alice's place names")
        XCTAssertEqual(alice.readCooldowns(), cooldowns())
        XCTAssertEqual(
            bob.readCooldowns(), TriggerCooldownState(),
            "and Bob must not inherit Alice's bounce history"
        )
    }

    func testSignedOut_readsNothingAndDropsWrites() {
        let defaults = scratchDefaults()
        let signedOut = UserDefaultsArrivalNudgeStateStore(defaults: defaults, userScope: { nil })
        let alice = UserDefaultsArrivalNudgeStateStore(defaults: defaults, userScope: { "alice" })
        alice.writeSnapshot(snapshot())

        signedOut.writeSnapshot(snapshot())
        signedOut.writeCooldowns(cooldowns())

        XCTAssertNil(signedOut.readSnapshot())
        XCTAssertEqual(signedOut.readCooldowns(), TriggerCooldownState())
        XCTAssertNotNil(alice.readSnapshot(), "and a signed-out write touched nobody's snapshot")
    }

    /// The scope is read at CALL time, not construction: the trigger service and the handler
    /// build their stores once at launch and must follow the session underneath them.
    func testTheScopeFollowsTheSessionAtCallTime() {
        let defaults = scratchDefaults()
        var current: String? = "alice"
        let store = UserDefaultsArrivalNudgeStateStore(defaults: defaults, userScope: { current })
        store.writeSnapshot(snapshot())

        current = "bob"

        XCTAssertNil(store.readSnapshot())
        current = "alice"
        XCTAssertNotNil(store.readSnapshot())
    }

    func testClearEveryUser_removesEveryScopedKeyAndTheLegacyOnes() {
        let defaults = scratchDefaults()
        let alice = UserDefaultsArrivalNudgeStateStore(defaults: defaults, userScope: { "alice" })
        let bob = UserDefaultsArrivalNudgeStateStore(defaults: defaults, userScope: { "bob" })
        alice.writeSnapshot(snapshot())
        alice.writeCooldowns(cooldowns())
        bob.writeSnapshot(snapshot())
        // What a build before the fold left behind — the leak itself, under both unscoped keys.
        defaults.set(Data("stale".utf8), forKey: UserDefaultsArrivalNudgeStateStore.legacySnapshotKey)
        defaults.set(Data("stale".utf8), forKey: UserDefaultsArrivalNudgeStateStore.legacyCooldownsKey)

        alice.clearEveryUser()

        XCTAssertNil(alice.readSnapshot())
        XCTAssertNil(bob.readSnapshot())
        XCTAssertEqual(alice.readCooldowns(), TriggerCooldownState())
        XCTAssertNil(defaults.data(forKey: UserDefaultsArrivalNudgeStateStore.legacySnapshotKey))
        XCTAssertNil(defaults.data(forKey: UserDefaultsArrivalNudgeStateStore.legacyCooldownsKey))
    }

    private func snapshot() -> AtPlaceSnapshot {
        AtPlaceSnapshot(entries: [
            AtPlaceSnapshot.PlaceEntry(
                placeId: UUID(), displayName: "Tesco 🛒", openTaskTitles: ["Buy AA batteries"],
                arrivalMessage: nil, actions: [], latitude: nil, longitude: nil
            )
        ])
    }

    private func cooldowns() -> TriggerCooldownState {
        TriggerCooldownState(lastFired: ["arrival-tesco": noon])
    }
}

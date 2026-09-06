//
//  RoutineRunStoreUserScopeTests.swift
//  ADHD LifeOSTests
//
//  The run-store sign-out leak (register item B2, folded into F-RoutineRecord-1). The live
//  run is app-local UserDefaults, and until this it survived sign-out: one account's place
//  name could surface on another account's Today. The key is now per user, and a signed-out
//  app neither reads nor writes one.
//

import XCTest
@testable import ADHD_LifeOS

final class RoutineRunStoreUserScopeTests: XCTestCase {
    private let noon = Date(timeIntervalSince1970: 1_756_296_000)

    private func scratchDefaults() -> UserDefaults {
        let name = "routine-scope-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    func testARunWrittenByOneUser_isInvisibleToAnother() {
        let defaults = scratchDefaults()
        let alice = UserDefaultsRoutineRunStore(defaults: defaults, userScope: { "alice" })
        let bob = UserDefaultsRoutineRunStore(defaults: defaults, userScope: { "bob" })

        alice.write(run())

        XCTAssertNotNil(alice.readLiveRun(now: noon))
        XCTAssertNil(bob.readLiveRun(now: noon), "Bob must never see Alice's place on his Today")
    }

    func testSignedOut_readsNothingAndDropsWrites() {
        let defaults = scratchDefaults()
        let signedOut = UserDefaultsRoutineRunStore(defaults: defaults, userScope: { nil })
        let alice = UserDefaultsRoutineRunStore(defaults: defaults, userScope: { "alice" })
        alice.write(run())

        signedOut.write(run())

        XCTAssertNil(signedOut.readLiveRun(now: noon))
        XCTAssertFalse(signedOut.updateMatching(run()))
        XCTAssertNotNil(alice.readLiveRun(now: noon), "and a signed-out write touched nobody's run")
    }

    /// The scope is read at CALL time, not construction: the stores built at launch (RootView,
    /// Home, the handler) must follow the session as it changes underneath them.
    func testTheScopeFollowsTheSessionAtCallTime() {
        let defaults = scratchDefaults()
        var current: String? = "alice"
        let store = UserDefaultsRoutineRunStore(defaults: defaults, userScope: { current })
        store.write(run())

        current = "bob"

        XCTAssertNil(store.readLiveRun(now: noon))
        current = "alice"
        XCTAssertNotNil(store.readLiveRun(now: noon))
    }

    func testClearEveryUser_removesEveryScopedRunAndTheLegacyKey() {
        let defaults = scratchDefaults()
        let alice = UserDefaultsRoutineRunStore(defaults: defaults, userScope: { "alice" })
        let bob = UserDefaultsRoutineRunStore(defaults: defaults, userScope: { "bob" })
        alice.write(run())
        bob.write(run())
        // A run left behind by a build that keyed it without a user — the leak itself.
        defaults.set(Data("stale".utf8), forKey: UserDefaultsRoutineRunStore.legacyRunKey)

        alice.clearEveryUser()

        XCTAssertNil(alice.readLiveRun(now: noon))
        XCTAssertNil(bob.readLiveRun(now: noon))
        XCTAssertNil(defaults.data(forKey: UserDefaultsRoutineRunStore.legacyRunKey))
    }

    private func run() -> RoutineRun {
        let gymId = UUID()
        let actions = [
            PlaceAction(id: UUID(), direction: .arrival, kind: .openApp(scheme: "spotify", displayName: "Spotify")),
            PlaceAction(id: UUID(), direction: .arrival, kind: .openApp(scheme: "gym", displayName: "Gym"))
        ]
        return RoutineRun.make(
            event: PlaceTriggerEvent(placeId: gymId, kind: .arrival, occurredAt: noon),
            entry: AtPlaceSnapshot.PlaceEntry(
                placeId: gymId, displayName: "Gym 🏋️", openTaskTitles: [],
                arrivalMessage: nil, actions: actions, latitude: nil, longitude: nil
            ),
            plan: PlaceRoutinePlan.make(actions, for: .arrival)
        )
    }
}

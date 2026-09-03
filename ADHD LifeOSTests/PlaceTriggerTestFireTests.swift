//
//  PlaceTriggerTestFireTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The DEBUG-only test-fire pin (E's 2026-09-01 field-gate ask): a button on the Places list
/// drives the REAL `PlaceTriggerEventHandler` fan-out without a physical fence crossing. The
/// contract under test: the snapshot is built live from the place being fired (a just-edited
/// action fires without waiting for a replan), the cooldown is neither consulted nor consumed
/// (repeat fires work, and a real walk minutes later is not inoculated), and a failed tasks
/// fetch degrades to an empty task list rather than a dead button.
@MainActor
final class PlaceTriggerTestFireTests: XCTestCase {

    private final class FakeNotifier: ImmediateNotifying {
        private(set) var postedTitles: [String] = []
        func post(title: String, body: String, identifier: String, userInfo: [String: String]) async {
            postedTitles.append(title)
        }

        func post(
            title: String, body: String, identifier: String,
            userInfo: [String: String], categoryIdentifier: String
        ) async {
            postedTitles.append(title)
        }

        func removeDelivered(identifiers: [String]) async {}
    }

    private final class FakeRecorder: LocationEventRecording {
        private(set) var recorded: [LocationEvent] = []
        func record(_ event: LocationEvent) async throws {
            recorded.append(event)
        }
    }

    private let placeId = UUID()

    private var gym: Place {
        Place(
            id: placeId, name: "Gym",
            coordinate: PlaceCoordinate(latitude: 51.5152, longitude: -0.1418),
            radiusMetres: 150, emoji: "🏋️", nudgeOnArrival: true
        )
    }

    private func makeGym(actions: [PlaceAction]) -> Place {
        var place = gym
        place.actions = actions
        return place
    }

    // MARK: - The store: fixed snapshot, cooldown neither read nor kept

    func testStore_servesInjectedSnapshot_andIgnoresSnapshotWrites() {
        let snapshot = AtPlaceSnapshot.build(places: [gym], tasks: [])
        let store = TestFireArrivalStateStore(snapshot: snapshot)

        XCTAssertEqual(store.readSnapshot(), snapshot)

        store.writeSnapshot(AtPlaceSnapshot(entries: []))
        XCTAssertEqual(store.readSnapshot(), snapshot, "A test fire must never replace the live snapshot")
    }

    func testStore_cooldownsAlwaysEmpty_evenAfterAWrite() {
        let store = TestFireArrivalStateStore(snapshot: AtPlaceSnapshot(entries: []))
        let event = PlaceTriggerEvent(placeId: placeId, kind: .arrival, occurredAt: .now)

        store.writeCooldowns(TriggerCooldown.recording(event, in: TriggerCooldownState()))

        XCTAssertEqual(
            store.readCooldowns(), TriggerCooldownState(),
            "A test fire must not inoculate the place against a real crossing"
        )
    }

    // MARK: - fire(): the real handler, driven repeatably

    func testFire_postsExternalNotification_onEveryFire_notJustTheFirst() async {
        let notifier = FakeNotifier()
        let place = makeGym(actions: [
            PlaceAction(id: UUID(), direction: .arrival, kind: .openApp(scheme: "spotify", displayName: "Spotify"))
        ])

        for _ in 1...2 {
            await PlaceTriggerTestFire.fire(
                place: place, kind: .arrival,
                fetchTasks: { [] },
                makeHandler: { store in
                    PlaceTriggerEventHandler(
                        recorder: FakeRecorder(), notifier: notifier, store: store,
                        isEnabled: { true },
                        journalWriter: { _ in false }, captureWriter: { _ in false }
                    )
                }
            )
        }

        let externals = notifier.postedTitles.filter { $0.contains("Spotify") }
        XCTAssertEqual(
            externals.count, 2,
            "The 30-minute cooldown would silence a real second crossing; the test button must not be silenced"
        )
    }

    func testFire_departureKind_reachesTheHandlerAsDeparture() async {
        let recorder = FakeRecorder()
        let place = makeGym(actions: [])

        await PlaceTriggerTestFire.fire(
            place: place, kind: .departure,
            fetchTasks: { [] },
            makeHandler: { store in
                PlaceTriggerEventHandler(
                    recorder: recorder, notifier: FakeNotifier(), store: store,
                    isEnabled: { true },
                    journalWriter: { _ in false }, captureWriter: { _ in false }
                )
            }
        )

        XCTAssertEqual(recorder.recorded.map(\.kind), [.departure])
        XCTAssertEqual(recorder.recorded.map(\.placeId), [place.id])
    }

    func testFire_failedTasksFetch_stillFires_withEmptyTaskList() async {
        struct Unreachable: Error {}
        let notifier = FakeNotifier()
        let place = makeGym(actions: [
            PlaceAction(id: UUID(), direction: .arrival, kind: .openApp(scheme: "spotify", displayName: "Spotify"))
        ])

        await PlaceTriggerTestFire.fire(
            place: place, kind: .arrival,
            fetchTasks: { throw Unreachable() },
            makeHandler: { store in
                PlaceTriggerEventHandler(
                    recorder: FakeRecorder(), notifier: notifier, store: store,
                    isEnabled: { true },
                    journalWriter: { _ in false }, captureWriter: { _ in false }
                )
            }
        )

        XCTAssertEqual(
            notifier.postedTitles.filter { $0.contains("Spotify") }.count, 1,
            "Offline must degrade to an empty task list, not a dead button"
        )
    }
}

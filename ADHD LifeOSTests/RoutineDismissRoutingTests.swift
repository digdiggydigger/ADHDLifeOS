//
//  RoutineDismissRoutingTests.swift
//  ADHD LifeOSTests
//
//  Site 3 of the routine record (F-RoutineRecord-1): a SWIPE on the routine banner. iOS only
//  reports a dismissal when the category asks for it (`.customDismissAction`), and it arrives
//  through the same delegate callback as a tap, distinguished by the action identifier alone.
//  Getting that wrong in either direction is bad: routing a dismiss through the tap router
//  would START the routine the user just cleared.
//

import XCTest
import UserNotifications
@testable import ADHD_LifeOS

@MainActor
final class RoutineDismissRoutingTests: XCTestCase {
    private let noon = Date(timeIntervalSince1970: 1_756_296_000)

    // MARK: - The pure decision

    func testDismissOnARoutineBanner_namesTheRunKey() {
        let run = gymRun()

        let key = RoutineDismissRouting.dismissedRunKey(
            notificationIdentifier: PlaceRoutineNotificationContent.identifier(placeId: run.placeId, kind: .arrival),
            actionIdentifier: UNNotificationDismissActionIdentifier,
            userInfo: PlaceRoutineNotificationContent.userInfo(for: run)
        )

        XCTAssertEqual(key, run.id)
    }

    func testTapOnARoutineBanner_isNotADismissal() {
        let run = gymRun()

        let key = RoutineDismissRouting.dismissedRunKey(
            notificationIdentifier: PlaceRoutineNotificationContent.identifier(placeId: run.placeId, kind: .arrival),
            actionIdentifier: UNNotificationDefaultActionIdentifier,
            userInfo: PlaceRoutineNotificationContent.userInfo(for: run)
        )

        XCTAssertNil(key, "the default action is the tap — the tap router's business")
    }

    func testDismissOnAnotherSpecies_isNotOurs() {
        let run = gymRun()

        let key = RoutineDismissRouting.dismissedRunKey(
            notificationIdentifier: "placeAction-\(UUID().uuidString)",
            actionIdentifier: UNNotificationDismissActionIdentifier,
            userInfo: PlaceRoutineNotificationContent.userInfo(for: run)
        )

        XCTAssertNil(key)
    }

    func testDismissWithABrokenPayload_isClaimedButNamesNothing() {
        let key = RoutineDismissRouting.dismissedRunKey(
            notificationIdentifier: "\(PlaceRoutineNotificationContent.identifierPrefix)broken",
            actionIdentifier: UNNotificationDismissActionIdentifier,
            userInfo: ["place_routine_run_id": "not-a-uuid"]
        )

        XCTAssertNil(key)
    }

    // MARK: - The doing half

    func testHandle_recordsTheDismissalOnce() async {
        let recorder = FakeRoutineRunRecorder()
        let sut = RoutineDismissRecorder(recorder: recorder)
        let run = gymRun()

        let claimed = sut.handle(
            notificationIdentifier: PlaceRoutineNotificationContent.identifier(placeId: run.placeId, kind: .arrival),
            actionIdentifier: UNNotificationDismissActionIdentifier,
            userInfo: PlaceRoutineNotificationContent.userInfo(for: run),
            now: noon
        )
        await sut.recordTask?.value

        XCTAssertTrue(claimed)
        XCTAssertEqual(recorder.events, ["dismissed"])
        XCTAssertEqual(recorder.dismissed.first?.runId, run.id)
        XCTAssertEqual(recorder.dismissed.first?.at, noon)
    }

    func testHandle_leavesATapAlone() async {
        let recorder = FakeRoutineRunRecorder()
        let sut = RoutineDismissRecorder(recorder: recorder)
        let run = gymRun()

        let claimed = sut.handle(
            notificationIdentifier: PlaceRoutineNotificationContent.identifier(placeId: run.placeId, kind: .arrival),
            actionIdentifier: UNNotificationDefaultActionIdentifier,
            userInfo: PlaceRoutineNotificationContent.userInfo(for: run),
            now: noon
        )

        XCTAssertFalse(claimed, "a tap falls through to the routers that start the routine")
        XCTAssertTrue(recorder.events.isEmpty)
    }

    /// A dismiss on OUR prefix with nothing usable inside is still ours — the placeAction greed
    /// rule applied to dismissals — so it must not fall through and be mistaken for a tap.
    func testHandle_claimsABrokenRoutineDismissalWithoutRecording() async {
        let recorder = FakeRoutineRunRecorder()
        let sut = RoutineDismissRecorder(recorder: recorder)

        let claimed = sut.handle(
            notificationIdentifier: "\(PlaceRoutineNotificationContent.identifierPrefix)broken",
            actionIdentifier: UNNotificationDismissActionIdentifier,
            userInfo: [:],
            now: noon
        )

        XCTAssertTrue(claimed)
        XCTAssertTrue(recorder.events.isEmpty)
    }

    // MARK: - Fixture

    private func gymRun() -> RoutineRun {
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

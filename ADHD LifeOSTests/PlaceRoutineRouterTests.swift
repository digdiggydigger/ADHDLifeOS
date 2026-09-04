//
//  PlaceRoutineRouterTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The third pending-door replay (F-Routines-3): the routine notification's tap survives a
/// cold launch and a signed-out moment, claims ONLY its own prefix, and hands the door the
/// minted run key — broken payloads deliver nil, which the door resolves to Today.
@MainActor
final class PlaceRoutineRouterTests: XCTestCase {

    /// A recording activator, not the real one: these tests are about the ROUTING rules —
    /// prefix greed, pending, replay-once — and a real activator would create runs in the
    /// process of proving them. What the tap creates lives in `RoutineDeferredLoggingTests`.
    private func makeRouter() -> PlaceRoutineNotificationRouter {
        PlaceRoutineNotificationRouter(activator: RecordingRoutineActivator())
    }

    private func identifier(_ runId: UUID = UUID(), placeId: UUID = UUID()) -> String {
        PlaceRoutineNotificationContent.identifier(placeId: placeId, kind: .arrival)
    }

    func testHandle_claimsOnlyItsOwnPrefix() {
        let router = makeRouter()

        XCTAssertTrue(router.handle(
            notificationIdentifier: identifier(), userInfo: [:]
        ), "our prefix is ours even when the payload is broken — the greed rule, applied to us")
        XCTAssertFalse(router.handle(
            notificationIdentifier: "placeAction-\(UUID().uuidString)", userInfo: [:]
        ), "the per-action species belongs to its own router")
        XCTAssertFalse(router.handle(
            notificationIdentifier: "focusCheckpoint", userInfo: [:]
        ))
    }

    func testHandle_whenConnected_deliversTheRunKey() {
        let router = makeRouter()
        let runId = UUID()
        var delivered: [UUID??] = []
        router.connect { delivered.append($0) }

        router.handle(
            notificationIdentifier: identifier(),
            userInfo: [PlaceRoutineNotificationContent.runIdUserInfoKey: runId.uuidString]
        )

        XCTAssertEqual(delivered.count, 1)
        XCTAssertEqual(delivered.first ?? nil, runId)
    }

    func testHandle_brokenPayload_deliversNilSoTheDoorFallsBackToToday() {
        let router = makeRouter()
        var delivered: [UUID?] = []
        router.connect { delivered.append($0) }

        router.handle(
            notificationIdentifier: identifier(),
            userInfo: [PlaceRoutineNotificationContent.runIdUserInfoKey: "not-a-uuid"]
        )

        XCTAssertEqual(delivered, [nil], "never a blank routine screen — nil resolves to Today")
    }

    func testColdLaunchTap_isHeldPending_andReplaysOnConnect() {
        let router = makeRouter()
        let runId = UUID()

        router.handle(
            notificationIdentifier: identifier(),
            userInfo: [PlaceRoutineNotificationContent.runIdUserInfoKey: runId.uuidString]
        )
        var delivered: [UUID?] = []
        router.connect { delivered.append($0) }

        XCTAssertEqual(delivered, [runId], "the cold-launch tap must not be dropped")

        router.connect { delivered.append($0) }
        XCTAssertEqual(delivered, [runId], "a replayed door replays ONCE")
    }
}

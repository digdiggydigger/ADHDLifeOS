//
//  FocusNotificationResponseTests.swift
//  ADHD LifeOSTests
//

import UserNotifications
import XCTest
@testable import ADHD_LifeOS

/// What a tap on a delivered notification asks the sprint engine to do.
///
/// iOS gives no way to dismiss a Live Activity at an exact instant while the app is suspended, so
/// between a sprint's deadline and the next unlock the card is still there (rendering a correct
/// terminal frame, but there). The "Sprint complete" notification is the deliberate route out: a tap
/// settles the sprint, which ends the Activity. Relying on `scenePhase` alone does not cover it —
/// a cold launch FROM the notification never fires an `.active` transition, and a tap taken while
/// the app is already foregrounded doesn't either.
final class FocusNotificationResponseTests: XCTestCase {
    private func route(_ identifier: String, action: String = UNNotificationDefaultActionIdentifier)
        -> FocusNotificationResponse {
        FocusNotificationResponse.route(notificationIdentifier: identifier, actionIdentifier: action)
    }

    func testTappingTheSprintCompleteNotification_settlesTheSprint() {
        XCTAssertEqual(route("focusSprint.complete"), .settleSprint)
    }

    /// A checkpoint tap settles too. `syncNow` is idempotent — on a still-running sprint it just
    /// catches the count up — and a checkpoint notification is quite often the one still on screen
    /// when the sprint has since run out.
    func testTappingACheckpointNotification_alsoSettlesTheSprint() {
        XCTAssertEqual(route("focusSprint.checkpoint.0"), .settleSprint)
        XCTAssertEqual(route("focusSprint.checkpoint.11"), .settleSprint)
    }

    /// The three notification features share one delegate. A task's countdown nudge or a Nudges-tab
    /// reminder has nothing to do with the sprint engine and must not poke it.
    func testTappingAnotherFeaturesNotification_isIgnored() {
        XCTAssertEqual(route("taskCountdownNudge.\(UUID().uuidString).0"), .ignore)
        XCTAssertEqual(route("nudgeNotification.\(UUID().uuidString)"), .ignore)
    }

    /// The namespace match is the full `focusSprint.` prefix, dot included — a bare prefix match
    /// would claim any future identifier that merely started with the same letters.
    func testAnIdentifierThatOnlyLooksLikeTheNamespace_isIgnored() {
        XCTAssertEqual(route("focusSprintSomethingElse"), .ignore)
    }

    func testSwipingTheNotificationAway_isNotATapAndSettlesNothing() {
        // Dismissing is the user saying "not now" — it must not end their sprint.
        XCTAssertEqual(route("focusSprint.complete", action: UNNotificationDismissActionIdentifier), .ignore)
    }

    func testAnUnknownCustomAction_isIgnored() {
        XCTAssertEqual(route("focusSprint.complete", action: "some.future.action"), .ignore)
    }

    // MARK: - Router

    @MainActor
    func testTap_withTheEngineConnected_settlesImmediately() {
        let router = FocusNotificationRouter()
        var settles = 0
        router.connect { settles += 1 }

        router.handle(
            notificationIdentifier: "focusSprint.complete",
            actionIdentifier: UNNotificationDefaultActionIdentifier
        )

        XCTAssertEqual(settles, 1)
    }

    @MainActor
    func testTap_beforeTheEngineExists_isReplayedAsSoonAsItDoes() {
        // The cold-launch case: iOS delivers the tap during app launch, and `FocusSessionService`
        // is not built until RootView's body first runs. Dropping the tap would leave exactly the
        // lingering Activity this whole route exists to clear.
        let router = FocusNotificationRouter()
        router.handle(
            notificationIdentifier: "focusSprint.complete",
            actionIdentifier: UNNotificationDefaultActionIdentifier
        )

        var settles = 0
        router.connect { settles += 1 }

        XCTAssertEqual(settles, 1)
    }

    @MainActor
    func testAReplayedTap_isNotReplayedAgainOnAReconnect() {
        let router = FocusNotificationRouter()
        router.handle(
            notificationIdentifier: "focusSprint.complete",
            actionIdentifier: UNNotificationDefaultActionIdentifier
        )
        router.connect {}

        var settles = 0
        router.connect { settles += 1 }

        XCTAssertEqual(settles, 0, "the pending tap was already spent")
    }

    @MainActor
    func testAnIgnoredNotification_neitherSettlesNorQueues() {
        let router = FocusNotificationRouter()
        router.handle(
            notificationIdentifier: "nudgeNotification.\(UUID().uuidString)",
            actionIdentifier: UNNotificationDefaultActionIdentifier
        )

        var settles = 0
        router.connect { settles += 1 }

        XCTAssertEqual(settles, 0)
    }

    @MainActor
    func testRepeatedTaps_eachSettleOnce() {
        let router = FocusNotificationRouter()
        var settles = 0
        router.connect { settles += 1 }

        router.handle(
            notificationIdentifier: "focusSprint.checkpoint.0",
            actionIdentifier: UNNotificationDefaultActionIdentifier
        )
        router.handle(
            notificationIdentifier: "focusSprint.complete",
            actionIdentifier: UNNotificationDefaultActionIdentifier
        )

        XCTAssertEqual(settles, 2)
    }
}

//
//  PlaceRoutineNotificationReplayTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

#if DEBUG
/// The DEBUG replay's selection rule (Block A). It performs a real tap rather than simulating
/// one — the identifier and userInfo it hands the router are the delivered notification's own —
/// so what is left to get wrong is WHICH notification, and whether the banner is cleared after.
@MainActor
final class PlaceRoutineNotificationReplayTests: XCTestCase {

    private func routine(_ suffix: String) -> PlaceRoutineNotificationReplay.Delivered {
        (
            identifier: "\(PlaceRoutineNotificationContent.identifierPrefix)\(suffix)",
            userInfo: [PlaceRoutineNotificationContent.runIdUserInfoKey: suffix]
        )
    }

    func testOpensTheNEWESTRoutineNotification() async {
        var routed: [String] = []
        let opened = await PlaceRoutineNotificationReplay.openLatest(
            delivered: { [self.routine("old"), self.routine("new")] },
            route: { identifier, _ in routed.append(identifier) },
            remove: { _ in }
        )

        XCTAssertTrue(opened)
        XCTAssertEqual(
            routed, ["\(PlaceRoutineNotificationContent.identifierPrefix)new"],
            "deliveredNotifications() is oldest-first, so the LAST match is the live crossing"
        )
    }

    func testIgnoresEveryOtherSpecies() async {
        var routed: [String] = []
        let opened = await PlaceRoutineNotificationReplay.openLatest(
            delivered: {
                [
                    self.routine("gym"),
                    (identifier: "placeAction-\(UUID().uuidString)", userInfo: [:]),
                    (identifier: "arrivalNudge-x-arrival", userInfo: [:])
                ]
            },
            route: { identifier, _ in routed.append(identifier) },
            remove: { _ in }
        )

        XCTAssertTrue(opened)
        XCTAssertEqual(
            routed, ["\(PlaceRoutineNotificationContent.identifierPrefix)gym"],
            "a per-action notification is a different species with a different router"
        )
    }

    func testCarriesTheUserInfoThroughUntouched() async {
        let run = RoutineRun(
            id: UUID(), placeId: UUID(), direction: .arrival, startedAt: Date(),
            displayName: "Gym 🏋️", customMessage: nil,
            steps: [RoutineRun.Step(
                action: PlaceAction(
                    id: UUID(), direction: .arrival,
                    kind: .openApp(scheme: "spotify", displayName: "Spotify")
                ),
                state: .pending
            )]
        )
        var carried: [AnyHashable: Any] = [:]

        _ = await PlaceRoutineNotificationReplay.openLatest(
            delivered: {
                [(
                    identifier: PlaceRoutineNotificationContent.identifier(
                        placeId: run.placeId, kind: .arrival
                    ),
                    userInfo: PlaceRoutineNotificationContent.userInfo(for: run)
                )]
            },
            route: { _, userInfo in carried = userInfo },
            remove: { _ in }
        )

        XCTAssertEqual(
            PlaceRoutineNotificationContent.run(fromUserInfo: carried), run,
            "the whole point is that the payload reaches the router unaltered"
        )
    }

    func testClearsTheBannerItOpened() async {
        var removed: [String] = []
        _ = await PlaceRoutineNotificationReplay.openLatest(
            delivered: { [self.routine("gym")] },
            route: { _, _ in },
            remove: { removed = $0 }
        )

        XCTAssertEqual(
            removed, ["\(PlaceRoutineNotificationContent.identifierPrefix)gym"],
            "a real tap clears the banner; leaving it would re-open a routine already underway"
        )
    }

    func testWithNothingDelivered_reportsSoAndRoutesNothing() async {
        var routed = 0
        let opened = await PlaceRoutineNotificationReplay.openLatest(
            attempts: 1,
            delivered: { [] },
            route: { _, _ in routed += 1 },
            remove: { _ in }
        )

        XCTAssertFalse(opened)
        XCTAssertEqual(routed, 0)
    }

    /// The race the polling exists for: fire the crossing, open the notification immediately.
    /// The post sits behind an authorization request and a tasks fetch, so the banner lands a
    /// beat later — and a single look would call that "nothing delivered".
    func testWaitsForABannerThatHasNotLandedYet() async {
        var looks = 0
        var routed: [String] = []
        let opened = await PlaceRoutineNotificationReplay.openLatest(
            interval: .milliseconds(1),
            delivered: {
                looks += 1
                return looks < 3 ? [] : [self.routine("gym")]
            },
            route: { identifier, _ in routed.append(identifier) },
            remove: { _ in }
        )

        XCTAssertTrue(opened, "a banner arriving on the third look is still the banner")
        XCTAssertEqual(routed, ["\(PlaceRoutineNotificationContent.identifierPrefix)gym"])
    }
}
#endif

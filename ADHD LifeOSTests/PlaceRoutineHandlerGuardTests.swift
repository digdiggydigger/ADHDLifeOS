//
//  PlaceRoutineHandlerGuardTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The routine branch's GUARDS (F-Routines-2-Notify): everything that must keep today's
/// behaviour byte-for-byte — below the 2-step threshold, below iOS 17 — plus the settled
/// kill-switch split (the run is a record; only the notification honours the switch) and
/// newest-wins replacement. The branch's own behaviour lives in `PlaceRoutineHandlerTests`;
/// the shared rig in `RoutineHandlerHarness`.
@MainActor
final class PlaceRoutineHandlerGuardTests: XCTestCase {

    func testKillSwitchOff_stillWritesTheRun_andTouchesNoTray() async {
        let harness = RoutineHandlerHarness(enabled: false)
        harness.installGym(actions: [harness.spotifyAction(), harness.textAction()])

        await harness.sut.handle(harness.event(.arrival))

        XCTAssertNotNil(harness.runStore.run, "the run and its Today card are PULL surfaces —"
            + " records like the auto-runs; only the notification honours the switch")
        XCTAssertTrue(harness.notifier.posted.isEmpty)
        XCTAssertTrue(
            harness.notifier.removedDelivered.isEmpty,
            "with the switch off the tray is not touched at all — removal rides the post"
        )
    }

    func testOneTapStep_keepsTodaysDirectNotification_andWritesNoRun() async {
        let harness = RoutineHandlerHarness()
        let spotify = harness.spotifyAction()
        harness.installGym(
            actions: [harness.journalAction(), spotify],
            taskTitles: ["Buy protein"], arrivalMessage: "Time to train"
        )

        await harness.sut.handle(harness.event(.arrival))

        XCTAssertTrue(harness.runStore.writes.isEmpty, "one tap-step is not a routine")
        XCTAssertEqual(harness.notifier.posted.count, 2)
        let expected = PlaceActionNotificationContent.external(
            for: spotify, placeName: "Gym 🏋️", kind: .arrival
        )
        let direct = harness.notifier.posted[0]
        XCTAssertEqual(direct.title, expected.title)
        XCTAssertEqual(direct.body, expected.body)
        XCTAssertEqual(direct.identifier, PlaceActionNotificationContent.identifier(for: spotify))
        XCTAssertEqual(direct.category, "", "the per-action species carries no category")
        // The userInfo JSON's key order is nondeterministic per encode — the identical-path
        // claim is that the SAME ACTION rides the tap, so decode it back and compare that.
        XCTAssertEqual(
            PlaceActionNotificationContent.action(fromUserInfo: direct.userInfo),
            spotify,
            "below the threshold the per-action path ships exactly today's tap payload"
        )
        XCTAssertEqual(
            harness.notifier.posted[1].body,
            "Time to train — 1 thing lives here: Buy protein · Journaled \u{201C}Leg day\u{201D}",
            "and the nudge still composes message, tasks AND the auto-run report itself"
        )
    }

    func testBelowIOS17_keepsThePerActionSpray_andWritesNoRun() async {
        let harness = RoutineHandlerHarness(routineScreenAvailable: false)
        harness.installGym(actions: [harness.spotifyAction(), harness.textAction()])

        await harness.sut.handle(harness.event(.arrival))

        XCTAssertTrue(
            harness.runStore.writes.isEmpty,
            "a run keyed to a screen this device cannot show would be a notification whose"
                + " tap can do nothing — below iOS 17 the spray stays"
        )
        XCTAssertEqual(harness.notifier.posted.count, 2)
        XCTAssertTrue(harness.notifier.posted.allSatisfy {
            $0.identifier.hasPrefix(PlaceActionNotificationContent.identifierPrefix)
        })
    }

    func testAQualifyingCrossing_replacesTheLiveRun_newestWins() async {
        let harness = RoutineHandlerHarness()
        harness.installGym(actions: [harness.spotifyAction(), harness.textAction()])
        let otherPlaceRun = RoutineRun.make(
            event: PlaceTriggerEvent(placeId: UUID(), kind: .arrival, occurredAt: harness.noon),
            entry: nil,
            plan: PlaceRoutinePlan.make(
                [harness.spotifyAction(), harness.textAction()], for: .arrival
            )
        )
        harness.runStore.run = otherPlaceRun

        await harness.sut.handle(harness.event(.arrival))

        XCTAssertEqual(harness.runStore.endCount, 0, "replacement is a WRITE, not an end")
        XCTAssertEqual(
            harness.runStore.run?.placeId, harness.gymId,
            "one live run globally — newest wins"
        )
    }
}

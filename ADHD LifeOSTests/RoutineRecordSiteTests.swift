//
//  RoutineRecordSiteTests.swift
//  ADHD LifeOSTests
//
//  The crossing and tap WRITE SITES of the routine record (F-RoutineRecord-1, sites 1, 2 and
//  5). E's rule, 2026-09-06: an OFFER is recorded — whether or not it is ever tapped — as an
//  explicit exception to Block A's "the crossing writes nothing". Block A's other half stands
//  and is re-pinned here: the crossing still runs no auto-step and writes no journal line, and
//  still writes no RUN to the local store. The offer record is the one sanctioned trace.
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class RoutineRecordSiteTests: XCTestCase {

    // MARK: - Site 1: the crossing records the OFFER it posted

    func testPostedRoutineBanner_recordsTheOffer() async {
        let harness = RoutineHandlerHarness()
        harness.installGym(
            actions: [harness.journalAction(), harness.spotifyAction(), harness.textAction()],
            arrivalMessage: "Time to train"
        )

        await harness.sut.handle(harness.event(.arrival))

        XCTAssertEqual(harness.routineRecorder.events, ["offered"])
        let offered = harness.routineRecorder.offered.first
        let carried = PlaceRoutineNotificationContent.run(fromUserInfo: harness.notifier.posted[0].userInfo)
        XCTAssertEqual(offered?.id, carried?.id, "the document id IS the run key the banner carries")
        XCTAssertEqual(offered?.phase, .offered)
        XCTAssertEqual(offered?.offeredAt, harness.noon)
        XCTAssertEqual(offered?.customMessage, "Time to train")
        // Block A's other half, unchanged: the sanctioned exception is the OFFER record alone.
        XCTAssertNil(harness.runStore.run, "still no run in the local store until the tap")
        XCTAssertTrue(harness.writers.journalInputs.isEmpty, "still no journal line until the tap")
    }

    func testKillSwitchOff_postsNothingAndRecordsNoOffer() async {
        let harness = RoutineHandlerHarness(enabled: false)
        harness.installGym(actions: [harness.spotifyAction(), harness.textAction()])

        await harness.sut.handle(harness.event(.arrival))

        XCTAssertTrue(harness.notifier.posted.isEmpty)
        XCTAssertTrue(harness.routineRecorder.events.isEmpty, "nothing was offered, so nothing is recorded")
    }

    func testCooldownSuppressedCrossing_recordsNoOffer() async {
        let harness = RoutineHandlerHarness()
        harness.installGym(actions: [harness.spotifyAction(), harness.textAction()])

        await harness.sut.handle(harness.event(.arrival))
        await harness.sut.handle(harness.event(.departure, at: harness.noon.addingTimeInterval(60)))
        await harness.sut.handle(harness.event(.arrival, at: harness.noon.addingTimeInterval(120)))

        let offers = harness.routineRecorder.events.filter { $0 == "offered" }
        XCTAssertEqual(offers.count, 1, "the bounce-return inside the cooldown offered nothing")
    }

    func testBelowThreshold_recordsNoOffer() async {
        let harness = RoutineHandlerHarness()
        harness.installGym(actions: [harness.spotifyAction()])

        await harness.sut.handle(harness.event(.arrival))

        XCTAssertEqual(harness.notifier.posted.count, 1, "the direct one-tap notification")
        XCTAssertTrue(harness.routineRecorder.events.isEmpty, "one step is not a routine, so no record")
    }

    func testBelowTheScreenGate_recordsNoOffer() async {
        let harness = RoutineHandlerHarness(routineScreenAvailable: false)
        harness.installGym(actions: [harness.spotifyAction(), harness.textAction()])

        await harness.sut.handle(harness.event(.arrival))

        XCTAssertTrue(harness.routineRecorder.events.isEmpty)
    }

    // MARK: - Site 2: the tap records the START

    func testTap_recordsStartedAndStampsTheRunsActivation() async {
        let harness = RoutineHandlerHarness()
        harness.installGym(actions: [harness.spotifyAction(), harness.textAction()])
        await harness.sut.handle(harness.event(.arrival))
        let tapTime = harness.noon.addingTimeInterval(45)

        await harness.tapLatestRoutineNotification(at: tapTime)

        XCTAssertEqual(harness.routineRecorder.events, ["offered", "started"])
        XCTAssertEqual(harness.routineRecorder.started.first?.runId, harness.runStore.run?.id)
        XCTAssertEqual(harness.routineRecorder.started.first?.at, tapTime)
        XCTAssertEqual(
            harness.runStore.run?.activatedAt, tapTime,
            "the stored run carries the TAP time so the screen can measure time spent without Firestore"
        )
    }

    func testSecondTapOnTheSameBanner_recordsNothingMore() async {
        let harness = RoutineHandlerHarness()
        harness.installGym(actions: [harness.spotifyAction(), harness.textAction()])
        await harness.sut.handle(harness.event(.arrival))

        await harness.tapLatestRoutineNotification()
        await harness.tapLatestRoutineNotification(at: harness.noon.addingTimeInterval(300))

        XCTAssertEqual(harness.routineRecorder.events, ["offered", "started"], "a way back in, not a second start")
    }

    func testTapWhileAnotherRunIsLive_endsThatRunAsReplacedBeforeStarting() async {
        let rig = ActivationRig()
        let older = rig.run(steps: [(rig.spotifyAction, .pending), (rig.journalAction, .autoDone)])
        rig.runStore.run = older
        let newer = rig.run(steps: [(rig.spotifyAction, .pending), (rig.journalAction, .autoDone)])

        _ = rig.sut.activate(userInfo: PlaceRoutineNotificationContent.userInfo(for: newer), now: rig.noon)
        await rig.sut.recordTask?.value

        XCTAssertEqual(rig.recorder.events, ["ended:replaced", "started"], "order is the claim")
        XCTAssertEqual(rig.recorder.ended.first?.runId, older.id)
        XCTAssertEqual(rig.recorder.started.first?.runId, newer.id)
    }

    // MARK: - Site 5: the departure crossing ENDS the arrival run as left_place

    func testDepartureCrossing_endsTheLiveArrivalRunAsLeftPlace() async {
        let harness = RoutineHandlerHarness()
        harness.installGym(actions: [harness.spotifyAction(), harness.textAction()])
        await harness.sut.handle(harness.event(.arrival))
        await harness.tapLatestRoutineNotification()
        let liveId = harness.runStore.run?.id

        await harness.sut.handle(harness.event(.departure, at: harness.noon.addingTimeInterval(600)))

        XCTAssertEqual(harness.routineRecorder.events, ["offered", "started", "ended:left_place"])
        XCTAssertEqual(harness.routineRecorder.ended.first?.runId, liveId)
        XCTAssertEqual(harness.routineRecorder.ended.first?.at, harness.noon.addingTimeInterval(600))
    }

    func testDepartureWithNoLiveRun_recordsNoEnd() async {
        let harness = RoutineHandlerHarness()
        harness.installGym(actions: [harness.spotifyAction(), harness.textAction()])

        await harness.sut.handle(harness.event(.departure))

        XCTAssertFalse(harness.routineRecorder.events.contains { $0.hasPrefix("ended") })
    }

    /// A failed write must not take the routine with it: the run is in the store and the door
    /// opens whether or not Firestore answered.
    func testRecorderFailure_doesNotStopTheTapFromStartingTheRoutine() async {
        let harness = RoutineHandlerHarness()
        harness.installGym(actions: [harness.spotifyAction(), harness.textAction()])
        await harness.sut.handle(harness.event(.arrival))
        harness.routineRecorder.error = URLError(.notConnectedToInternet)

        let opened = await harness.tapLatestRoutineNotification()

        XCTAssertNotNil(opened)
        XCTAssertEqual(harness.runStore.run?.id, opened)
    }
}

//
//  RoutineDeferredLoggingTests.swift
//  ADHD LifeOSTests
//
//  Block A (E's spec, confirmed twice on 2026-09-04): "the routine card and journal logging
//  must only happen after the notification has been tapped", and "only logging when action is
//  actually taken via the notification to initiate the routine".
//
//  The consequence E was asked about directly and confirmed: **swiping the banner away leaves
//  NO trace** — no run, no card, no journal line. That is intended, not an oversight, and it is
//  what the first half of this file pins. The second half pins the other side of the bargain:
//  the tap has to be able to CREATE what the crossing declined to write, which is why the
//  notification's userInfo widened from a bare run UUID to the whole frozen run.
//
//  Two things E settled that are NOT deferred, and each has a test here so a later reading of
//  the rule cannot quietly take them with it:
//  - the silent `location_events` timeline record (sensing, not a user-visible log);
//  - ending a live arrival run on its departure crossing (a deletion, never a creation — defer
//    it and "ROUTINE LIVE" haunts Today until midnight, the exact defect check 3 caught).
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class RoutineDeferredLoggingTests: XCTestCase {

    // MARK: - The crossing writes nothing

    func testQualifyingArrival_writesNoRun_andRunsNoAutoStep() async {
        let harness = RoutineHandlerHarness()
        harness.installGym(
            actions: [harness.journalAction(), harness.spotifyAction(), harness.textAction()],
            arrivalMessage: "Time to train"
        )

        await harness.sut.handle(harness.event(.arrival))

        XCTAssertNil(harness.runStore.run, "the crossing must leave NO run — the tap creates it")
        XCTAssertTrue(harness.runStore.writes.isEmpty, "and must not have written one at all")
        XCTAssertTrue(
            harness.writers.journalInputs.isEmpty,
            "the journal auto-step waits for the tap: swiping the banner away leaves no trace"
        )
        XCTAssertTrue(harness.writers.captureInputs.isEmpty)
    }

    func testQualifyingArrival_stillRecordsTheSilentTimelineEvent() async {
        let harness = RoutineHandlerHarness()
        harness.installGym(actions: [harness.spotifyAction(), harness.textAction()])

        await harness.sut.handle(harness.event(.arrival))

        XCTAssertEqual(
            harness.recorder.recorded.map(\.placeId), [harness.gymId],
            "sensing, not logging (E's call): the timeline record is not what the rule is about"
        )
    }

    func testQualifyingArrival_postsTheNotificationCarryingTheWholeRun() async {
        let harness = RoutineHandlerHarness()
        harness.installGym(
            actions: [harness.journalAction(), harness.spotifyAction(), harness.textAction()],
            arrivalMessage: "Time to train"
        )

        await harness.sut.handle(harness.event(.arrival))

        XCTAssertEqual(harness.notifier.posted.count, 1)
        let posted = harness.notifier.posted[0]
        let carried = PlaceRoutineNotificationContent.run(fromUserInfo: posted.userInfo)
        XCTAssertNotNil(
            carried,
            "with nothing written there is nothing to resolve — the run has to RIDE the tap"
        )
        XCTAssertEqual(carried?.placeId, harness.gymId)
        XCTAssertEqual(carried?.direction, .arrival)
        XCTAssertEqual(carried?.startedAt, harness.noon, "frozen at the CROSSING, not the tap")
        XCTAssertEqual(carried?.steps.map(\.state), [.autoDone, .pending, .pending])
        XCTAssertEqual(
            posted.userInfo[PlaceRoutineNotificationContent.runIdUserInfoKey],
            carried?.id.uuidString,
            "the id key stays: the door's stale rule and older delivered banners both read it"
        )
    }

    func testTheNotificationBodyIsForwardLooking_becauseNothingHasRunYet() async {
        let harness = RoutineHandlerHarness()
        harness.installGym(
            actions: [harness.journalAction(), harness.spotifyAction(), harness.textAction()],
            arrivalMessage: "Time to train"
        )

        await harness.sut.handle(harness.event(.arrival))

        XCTAssertEqual(
            harness.notifier.posted[0].body,
            "Time to train · Will journal \u{201C}Leg day\u{201D}"
                + " · 2 steps ready — Open Spotify · Text Ben. Tap to run.",
            "\u{201C}Journaled\u{201D} was past tense reporting a completed write; nothing has run"
        )
    }

    /// The scope line E drew: routines only. A place whose crossing does NOT qualify has no
    /// routine to initiate, so its auto-runs keep happening at the crossing exactly as shipped.
    func testNonQualifyingArrival_stillAutoRunsAtTheCrossing() async {
        let harness = RoutineHandlerHarness()
        harness.installGym(actions: [harness.journalAction(), harness.spotifyAction()])

        await harness.sut.handle(harness.event(.arrival))

        XCTAssertEqual(
            harness.writers.journalInputs.count, 1,
            "one tap-step is not a routine — this path is unchanged, and must stay unchanged"
        )
        XCTAssertNil(harness.runStore.run)
    }

    // MARK: - The tap creates it

    func testTap_createsTheRun_andRunsTheAutoSteps() async {
        let rig = ActivationRig()
        let run = rig.run(steps: [(rig.journalAction, .autoDone), (rig.spotifyAction, .pending)])

        let opened = rig.sut.activate(userInfo: rig.userInfo(for: run), now: rig.noon)

        XCTAssertEqual(opened, run.id, "the door opens on the run the tap just created")
        XCTAssertEqual(rig.runStore.run?.id, run.id, "and the run now exists")
        await rig.settle()
        XCTAssertEqual(
            rig.writers.journalInputs.map(\.body), ["Leg day"],
            "the auto step runs at the tap — this is the write E deferred, arriving on time"
        )
        XCTAssertEqual(
            rig.writers.journalInputs.first?.locationStamp?.placeId, rig.gymId,
            "still stamped with the place: the crossing is the evidence E was there"
        )
    }

    func testSecondTap_opensWithoutRunningTheAutoStepsTwice() async {
        let rig = ActivationRig()
        let run = rig.run(steps: [(rig.journalAction, .autoDone), (rig.spotifyAction, .pending)])
        let info = rig.userInfo(for: run)

        _ = rig.sut.activate(userInfo: info, now: rig.noon)
        await rig.settle()
        let opened = rig.sut.activate(userInfo: info, now: rig.noon)
        await rig.settle()

        XCTAssertEqual(opened, run.id)
        XCTAssertEqual(
            rig.writers.journalInputs.count, 1,
            "a run already started is OPENED, never restarted — two journal lines is the bug"
        )
        XCTAssertEqual(rig.runStore.writes.count, 1)
    }

    func testAStalePayload_opensTodayAndWritesNothing() async {
        let rig = ActivationRig()
        let run = rig.run(steps: [(rig.journalAction, .autoDone), (rig.spotifyAction, .pending)])
        let tomorrow = rig.noon.addingTimeInterval(24 * 3600)

        let opened = rig.sut.activate(userInfo: rig.userInfo(for: run), now: tomorrow)
        await rig.settle()

        XCTAssertNil(opened, "yesterday's banner opens Today, never a routine out of its day")
        XCTAssertNil(rig.runStore.run)
        XCTAssertTrue(rig.writers.journalInputs.isEmpty)
    }

    /// A banner posted by the PREVIOUS build carries only the run UUID, and its run is already
    /// in the store. It must still open — an app update must not strand a delivered tap.
    func testAnIdOnlyPayload_stillOpensTheStoredRun() async {
        let rig = ActivationRig()
        let run = rig.run(steps: [(rig.spotifyAction, .pending)])
        rig.runStore.run = run

        let opened = rig.sut.activate(
            userInfo: [PlaceRoutineNotificationContent.runIdUserInfoKey: run.id.uuidString],
            now: rig.noon
        )
        await rig.settle()

        XCTAssertEqual(opened, run.id)
        XCTAssertTrue(rig.runStore.writes.isEmpty, "it is already there — nothing to create")
        XCTAssertTrue(rig.writers.journalInputs.isEmpty)
    }

    func testABrokenPayload_opensTodayAndWritesNothing() async {
        let rig = ActivationRig()

        let opened = rig.sut.activate(userInfo: ["nonsense": "value"], now: rig.noon)
        await rig.settle()

        XCTAssertNil(opened)
        XCTAssertNil(rig.runStore.run)
    }
}

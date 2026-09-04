//
//  PlaceRoutineHandlerTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The handler's routine branch (F-Routines-2-Notify): at 2+ tap-steps one routine
/// notification replaces the per-action spray; the run rides that notification rather than
/// being written (Block A — the crossing writes NOTHING, the tap creates everything); and —
/// the field-walk killer the plan pins — ENDING a run executes BEFORE the cooldown guard, so
/// a departure swallowed by its own 30-minute cooldown still ends the run instead of leaving
/// "routine live" on Today until midnight. The guard branches that must NOT move live in
/// `PlaceRoutineHandlerGuardTests`; deferral itself in `RoutineDeferredLoggingTests`; the
/// shared rig in `RoutineHandlerHarness`.
@MainActor
final class PlaceRoutineHandlerTests: XCTestCase {

    func testQualifyingArrival_postsOneRoutineNotification_notThePerActionSpray() async {
        let harness = RoutineHandlerHarness()
        harness.installGym(
            actions: [harness.journalAction(), harness.spotifyAction(), harness.textAction()],
            arrivalMessage: "Time to train"
        )

        await harness.sut.handle(harness.event(.arrival))

        XCTAssertNil(harness.runStore.run, "the crossing OFFERS the routine; the tap creates it")
        XCTAssertEqual(
            harness.notifier.posted.count, 1,
            "ONE notification — no spray, and no task nudge when nothing is open here"
        )
        let posted = harness.notifier.posted[0]
        XCTAssertEqual(posted.identifier, "placeRoutine-\(harness.gymId.uuidString)-arrival")
        XCTAssertEqual(posted.category, PlaceRoutineNotificationContent.categoryIdentifier)
        let carried = PlaceRoutineNotificationContent.run(fromUserInfo: posted.userInfo)
        XCTAssertEqual(
            carried?.steps.map(\.state), [.autoDone, .pending, .pending],
            "the offered run mirrors the plan: auto steps pre-ticked, tap-steps pending"
        )
        XCTAssertEqual(posted.title, "You're at Gym 🏋️")
        XCTAssertEqual(
            posted.body,
            "Time to train · Will journal \u{201C}Leg day\u{201D}"
                + " · 2 steps ready — Open Spotify · Text Ben. Tap to run.",
            "the routine ABSORBS the custom message; the auto step is named, not yet run"
        )
        XCTAssertTrue(
            harness.writers.journalInputs.isEmpty,
            "and nothing has been written — that is the whole of E's rule"
        )
    }

    func testTheTapCreatesTheRunTheNotificationOffered() async {
        let harness = RoutineHandlerHarness()
        harness.installGym(actions: [harness.spotifyAction(), harness.textAction()])

        await harness.sut.handle(harness.event(.arrival))
        let opened = await harness.tapLatestRoutineNotification()

        XCTAssertNotNil(harness.runStore.run, "the tap is where the routine starts existing")
        XCTAssertEqual(opened, harness.runStore.run?.id, "and the door opens on exactly it")
        let writeIndex = harness.log.events.firstIndex(of: "run-write")
        let postIndex = harness.log.events.firstIndex { $0.hasPrefix("post:") }
        XCTAssertLessThan(
            postIndex ?? .max, writeIndex ?? .min,
            "the order INVERTED under deferral: post first, write only once tapped"
        )
    }

    func testTrayHygiene_removesThePlacesDeliveredPerActionNotifications() async {
        let harness = RoutineHandlerHarness()
        let spotify = harness.spotifyAction()
        let text = harness.textAction()
        harness.installGym(actions: [harness.journalAction(), spotify, text])

        await harness.sut.handle(harness.event(.arrival))

        XCTAssertEqual(
            harness.notifier.removedDelivered,
            [[
                PlaceActionNotificationContent.identifier(for: spotify),
                PlaceActionNotificationContent.identifier(for: text)
            ]],
            "one crossing must never leave two eras of notification competing in the tray"
        )
    }

    func testQualifyingArrival_withTasks_alsoPostsTheTasksOnlyNudge() async {
        let harness = RoutineHandlerHarness()
        harness.installGym(
            actions: [harness.journalAction(), harness.spotifyAction(), harness.textAction()],
            taskTitles: ["Buy protein"], arrivalMessage: "Time to train"
        )

        await harness.sut.handle(harness.event(.arrival))

        XCTAssertEqual(
            harness.notifier.posted.count, 2, "two SPECIES: the routine and the task nudge"
        )
        let nudge = harness.notifier.posted[1]
        XCTAssertEqual(nudge.identifier, "arrivalNudge-\(harness.gymId.uuidString)-arrival")
        XCTAssertEqual(nudge.category, "", "the task nudge keeps its own un-categorised species")
        XCTAssertEqual(
            nudge.body, "1 thing lives here — Buy protein",
            "the routine absorbed the message and the report — the nudge carries tasks ALONE"
        )
    }

    /// Today's card is a PULL surface with exactly one push: this signal. A routine made only
    /// of tap-steps writes NOTHING to Firestore, so without it a run that starts while Today is
    /// on screen leaves the card invisible, and an ENDED run leaves a stale one.
    ///
    /// Under deferral the announcement moves WITH the creation, from the crossing to the tap.
    /// A crossing that announced a routine nobody had started yet would be announcing nothing.
    func testTheTapAnnouncesItselfSoTodayCanPickItUp() async {
        let harness = RoutineHandlerHarness()
        harness.installGym(actions: [harness.spotifyAction(), harness.textAction()])
        var announcements = 0
        let token = NotificationCenter.default.addObserver(
            forName: DataChangeSignal.name, object: nil, queue: .main
        ) { _ in announcements += 1 }
        defer { NotificationCenter.default.removeObserver(token) }

        await harness.sut.handle(harness.event(.arrival))
        XCTAssertEqual(announcements, 0, "the crossing changed nothing, so it announces nothing")

        await harness.tapLatestRoutineNotification()

        XCTAssertGreaterThan(
            announcements, 0,
            "nothing told Today a routine had started, and no Firestore write would either"
        )
    }

    func testStackedCooldowns_theRunEndingOutrunsTheGuard() async {
        let harness = RoutineHandlerHarness()
        harness.installGym(
            actions: [harness.journalAction(), harness.spotifyAction(), harness.textAction()],
            arrivalMessage: "Time to train", departureMessage: "Towel?"
        )
        let noon = harness.noon

        // t0 — arrive, and TAP: the routine posts, the tap starts it, the arrival cooldown is
        // consumed. Under deferral the run cannot exist without that second step.
        await harness.sut.handle(harness.event(.arrival, at: noon))
        await harness.tapLatestRoutineNotification()
        let firstRun = harness.runStore.run
        XCTAssertNotNil(firstRun)
        XCTAssertEqual(harness.notifier.posted.count, 1)
        XCTAssertEqual(harness.writers.journalInputs.count, 1, "the tap ran the auto step")

        // t0+10 — leave: the arrival run ends; the departure message posts (its own cooldown
        // consumed). No departure steps, so no departure routine is offered.
        await harness.sut.handle(harness.event(.departure, at: noon.addingTimeInterval(600)))
        XCTAssertNil(harness.runStore.run, "the place's departure ends its arrival run")
        XCTAssertEqual(harness.notifier.posted.count, 2)

        // t0+15 — return: the arrival cooldown SWALLOWS the crossing. Nothing posts, so there
        // is nothing to tap, so no routine — which is the shape deferral gives this case. The
        // pre-Block-A rule ("creation sits before the guard, newest wins") dissolved with it:
        // creation now follows the notification, and a swallowed crossing posts none.
        await harness.sut.handle(harness.event(.arrival, at: noon.addingTimeInterval(900)))
        XCTAssertNil(harness.runStore.run, "a swallowed crossing offers nothing to start")
        XCTAssertEqual(harness.notifier.posted.count, 2, "the swallowed crossing posts NOTHING")
        XCTAssertEqual(harness.writers.journalInputs.count, 1, "and re-runs nothing")

        // t0+20 — leave again with a run live: the departure cooldown swallows the crossing,
        // and the run must STILL end — the field-walk killer, and the one run write a crossing
        // still makes. Miss this and "routine live" sits on Today until midnight.
        harness.runStore.run = firstRun
        await harness.sut.handle(harness.event(.departure, at: noon.addingTimeInterval(1200)))
        XCTAssertNil(harness.runStore.run, "a swallowed departure still ends the run")
        XCTAssertEqual(harness.notifier.posted.count, 2)
    }
}

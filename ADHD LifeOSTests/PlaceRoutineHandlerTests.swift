//
//  PlaceRoutineHandlerTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The handler's routine branch (F-Routines-2-Notify): at 2+ tap-steps one routine
/// notification replaces the per-action spray; the run record is written BEFORE the post;
/// and — the field-walk killer the plan pins — run lifecycle executes BEFORE the cooldown
/// guard, so a departure swallowed by its own 30-minute cooldown still ends the run instead
/// of leaving "routine live" on Today until midnight. The guard branches that must NOT move
/// live in `PlaceRoutineHandlerGuardTests`; the shared rig in `RoutineHandlerHarness`.
@MainActor
final class PlaceRoutineHandlerTests: XCTestCase {

    func testQualifyingArrival_postsOneRoutineNotification_notThePerActionSpray() async {
        let harness = RoutineHandlerHarness()
        harness.installGym(
            actions: [harness.journalAction(), harness.spotifyAction(), harness.textAction()],
            arrivalMessage: "Time to train"
        )

        await harness.sut.handle(harness.event(.arrival))

        let run = harness.runStore.run
        XCTAssertNotNil(run, "a qualifying crossing writes the run")
        XCTAssertEqual(
            run?.steps.map(\.state), [.autoDone, .pending, .pending],
            "the run mirrors the routine plan: auto steps pre-ticked, tap-steps pending"
        )
        XCTAssertEqual(
            harness.notifier.posted.count, 1,
            "ONE notification — no spray, and no task nudge when nothing is open here"
        )
        let posted = harness.notifier.posted[0]
        XCTAssertEqual(posted.identifier, "placeRoutine-\(harness.gymId.uuidString)-arrival")
        XCTAssertEqual(posted.category, PlaceRoutineNotificationContent.categoryIdentifier)
        XCTAssertEqual(
            posted.userInfo,
            [PlaceRoutineNotificationContent.runIdUserInfoKey: run?.id.uuidString ?? "MISSING"]
        )
        XCTAssertEqual(posted.title, "You're at Gym 🏋️")
        XCTAssertEqual(
            posted.body,
            "Time to train · Journaled \u{201C}Leg day\u{201D}"
                + " · 2 steps ready — Open Spotify · Text Ben. Tap to run.",
            "the routine ABSORBS the custom message and the auto-run report"
        )
        XCTAssertEqual(harness.writers.journalInputs.count, 1, "auto-runs still run themselves")
    }

    func testTheRunIsWritten_beforeTheNotificationPosts() async {
        let harness = RoutineHandlerHarness()
        harness.installGym(actions: [harness.spotifyAction(), harness.textAction()])

        await harness.sut.handle(harness.event(.arrival))

        let writeIndex = harness.log.events.firstIndex(of: "run-write")
        let postIndex = harness.log.events.firstIndex { $0.hasPrefix("post:") }
        XCTAssertNotNil(writeIndex)
        XCTAssertNotNil(postIndex)
        XCTAssertLessThan(
            writeIndex ?? .max, postIndex ?? .min,
            "a posted notification keyed to a run that does not exist yet is the plan's own bug"
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
    /// of tap-steps writes NOTHING to Firestore, so without it a crossing that lands while
    /// Today is on screen leaves the card invisible, and an ENDED run leaves a stale one.
    func testAQualifyingCrossing_announcesItselfSoTodayCanPickItUp() async {
        let harness = RoutineHandlerHarness()
        harness.installGym(actions: [harness.spotifyAction(), harness.textAction()])
        var announcements = 0
        let token = NotificationCenter.default.addObserver(
            forName: DataChangeSignal.name, object: nil, queue: .main
        ) { _ in announcements += 1 }
        defer { NotificationCenter.default.removeObserver(token) }

        await harness.sut.handle(harness.event(.arrival))

        XCTAssertGreaterThan(
            announcements, 0,
            "nothing told Today a routine had started, and no Firestore write would either"
        )
    }

    func testStackedCooldowns_theRunLifecycleOutrunsTheGuard() async {
        let harness = RoutineHandlerHarness()
        harness.installGym(
            actions: [harness.journalAction(), harness.spotifyAction(), harness.textAction()],
            arrivalMessage: "Time to train", departureMessage: "Towel?"
        )
        let noon = harness.noon

        // t0 — arrive: run created, routine posted, arrival cooldown consumed.
        await harness.sut.handle(harness.event(.arrival, at: noon))
        let firstRun = harness.runStore.run
        XCTAssertNotNil(firstRun)
        XCTAssertEqual(harness.notifier.posted.count, 1)

        // t0+10 — leave: the arrival run ends; the departure message posts (its own cooldown
        // consumed). No departure steps, so no departure run.
        await harness.sut.handle(harness.event(.departure, at: noon.addingTimeInterval(600)))
        XCTAssertNil(harness.runStore.run, "the place's departure ends its arrival run")
        XCTAssertEqual(harness.notifier.posted.count, 2)

        // t0+15 — return: the arrival cooldown SWALLOWS the crossing (no notification, no
        // re-run of the journal line) — but the run is still created: lifecycle is a RECORD,
        // and E, standing in the gym, must find the routine on Today.
        await harness.sut.handle(harness.event(.arrival, at: noon.addingTimeInterval(900)))
        let secondRun = harness.runStore.run
        XCTAssertNotNil(secondRun, "newest-wins creation sits BEFORE the cooldown guard")
        XCTAssertNotEqual(secondRun?.id, firstRun?.id, "a fresh run key every crossing")
        XCTAssertEqual(harness.notifier.posted.count, 2, "the swallowed crossing posts NOTHING")
        XCTAssertEqual(harness.writers.journalInputs.count, 1, "and re-runs nothing")

        // t0+20 — leave again: the departure cooldown swallows the crossing too, and the run
        // must STILL end — the field-walk killer. Miss this and "routine live" sits on Today
        // until midnight.
        await harness.sut.handle(harness.event(.departure, at: noon.addingTimeInterval(1200)))
        XCTAssertNil(harness.runStore.run, "a swallowed departure still ends the run")
        XCTAssertEqual(harness.notifier.posted.count, 2)
    }
}

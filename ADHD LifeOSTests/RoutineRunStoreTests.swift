//
//  RoutineRunStoreTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The run record and its lifetime rules (F-Routines-2-Notify, E's settled call #3): an
/// arrival run lives until the same place's departure crossing; a departure run gets the
/// `RoutineDefaults.departureRunWindow`; and EVERY run dies with its own calendar day — the
/// lazy end-of-day sweep, evaluated on read, because the arc deliberately owns no timer and
/// no background wake.
final class RoutineRunStoreTests: XCTestCase {

    private let noonUTC = Date(timeIntervalSince1970: 1_756_296_000)
    private let gymId = UUID()

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func journal() -> PlaceAction {
        PlaceAction(id: UUID(), direction: .arrival, kind: .journalLine(body: "Leg day"))
    }

    private func spotify() -> PlaceAction {
        PlaceAction(
            id: UUID(), direction: .arrival,
            kind: .openApp(scheme: "spotify", displayName: "Spotify")
        )
    }

    private func text() -> PlaceAction {
        PlaceAction(
            id: UUID(), direction: .arrival,
            kind: .textContact(contactName: "Ben", phoneNumber: "+44111", messageBody: "Here!")
        )
    }

    private func gymEntry(
        arrivalMessage: String? = nil, departureMessage: String? = nil, actions: [PlaceAction]
    ) -> AtPlaceSnapshot.PlaceEntry {
        AtPlaceSnapshot.PlaceEntry(
            placeId: gymId, displayName: "Gym 🏋️", openTaskTitles: [],
            arrivalMessage: arrivalMessage, departureMessage: departureMessage,
            actions: actions, latitude: 51.5152, longitude: -0.1418
        )
    }

    private func arrival(at date: Date? = nil) -> PlaceTriggerEvent {
        PlaceTriggerEvent(placeId: gymId, kind: .arrival, occurredAt: date ?? noonUTC)
    }

    private func departure(at date: Date? = nil, placeId: UUID? = nil) -> PlaceTriggerEvent {
        PlaceTriggerEvent(placeId: placeId ?? gymId, kind: .departure, occurredAt: date ?? noonUTC)
    }

    private func makeRun(
        event: PlaceTriggerEvent? = nil, entry: AtPlaceSnapshot.PlaceEntry? = nil,
        actions: [PlaceAction]? = nil
    ) -> RoutineRun {
        let actions = actions ?? [journal(), spotify(), text()]
        return RoutineRun.make(
            event: event ?? arrival(),
            entry: entry ?? gymEntry(arrivalMessage: "Time to train", actions: actions),
            plan: PlaceRoutinePlan.make(actions, for: (event ?? arrival()).kind)
        )
    }

    // MARK: - Minting the record

    func testMake_freezesTheCrossingIntoTheRecord() {
        let actions = [journal(), spotify(), text()]
        let run = makeRun(actions: actions)

        XCTAssertEqual(run.placeId, gymId)
        XCTAssertEqual(run.direction, .arrival)
        XCTAssertEqual(run.startedAt, noonUTC)
        XCTAssertEqual(run.displayName, "Gym 🏋️")
        XCTAssertEqual(run.customMessage, "Time to train")
        XCTAssertEqual(
            run.steps.map(\.action.id), actions.map(\.id),
            "steps keep the saved array order — order IS the routine"
        )
        XCTAssertEqual(
            run.steps.map(\.state), [.autoDone, .pending, .pending],
            "auto-run kinds are minted pre-ticked (E's settled call #4); tap-steps start pending"
        )
    }

    func testMake_mintsAFreshRunKeyEveryTime() {
        // The run UUID is the stale-tap rule: a tap carrying an old run's key must MISMATCH
        // the new run, so the key can never be a composed place|direction|date value.
        XCTAssertNotEqual(makeRun().id, makeRun().id)
    }

    func testMake_departureRun_carriesTheDepartureMessageNotTheArrivalOne() {
        let actions = [
            PlaceAction(id: UUID(), direction: .departure, kind: .openURL(urlString: "https://a.example")),
            PlaceAction(id: UUID(), direction: .departure, kind: .startSprint(minutes: 10))
        ]
        let entry = gymEntry(
            arrivalMessage: "Time to train", departureMessage: "Grab your towel", actions: actions
        )

        let run = RoutineRun.make(
            event: departure(), entry: entry,
            plan: PlaceRoutinePlan.make(actions, for: .departure)
        )

        XCTAssertEqual(run.direction, .departure)
        XCTAssertEqual(run.customMessage, "Grab your towel")
    }

    // MARK: - What ends a run (the crossing half; expiry is below)

    func testEnds_onlyOnTheRunsOwnPlaceDeparting() {
        let arrivalRun = makeRun()

        XCTAssertTrue(RoutineRunLifecycle.ends(arrivalRun, on: departure()))
        XCTAssertFalse(
            RoutineRunLifecycle.ends(arrivalRun, on: departure(placeId: UUID())),
            "another place's departure says nothing about this run"
        )
        XCTAssertFalse(
            RoutineRunLifecycle.ends(arrivalRun, on: arrival()),
            "a repeat arrival never ends a run — newest-wins replacement handles it"
        )
    }

    func testEnds_neverEndsADepartureRun() {
        // A departure run has no closing crossing — you already left. Its lifetime is the
        // 30-minute window plus the day sweep, nothing else.
        let actions = [
            PlaceAction(id: UUID(), direction: .departure, kind: .openURL(urlString: "https://a.example")),
            PlaceAction(id: UUID(), direction: .departure, kind: .startSprint(minutes: 10))
        ]
        let departureRun = RoutineRun.make(
            event: departure(), entry: gymEntry(actions: actions),
            plan: PlaceRoutinePlan.make(actions, for: .departure)
        )

        XCTAssertFalse(RoutineRunLifecycle.ends(departureRun, on: departure()))
    }

    // MARK: - Expiry (the lazy half)

    func testIsLive_arrivalRunLivesUntilItsDayEnds() {
        let run = makeRun()

        XCTAssertTrue(RoutineRunLifecycle.isLive(
            run, now: noonUTC.addingTimeInterval(11 * 3600 + 59 * 60), calendar: utcCalendar
        ), "an arrival run has no window — the day is its outer bound")
        XCTAssertFalse(RoutineRunLifecycle.isLive(
            run, now: noonUTC.addingTimeInterval(12 * 3600 + 60), calendar: utcCalendar
        ), "the end-of-day sweep: a run never haunts tomorrow's Today")
    }

    func testIsLive_departureRunDiesAtTheWindow() {
        let actions = [
            PlaceAction(id: UUID(), direction: .departure, kind: .openURL(urlString: "https://a.example")),
            PlaceAction(id: UUID(), direction: .departure, kind: .startSprint(minutes: 10))
        ]
        let run = RoutineRun.make(
            event: departure(), entry: gymEntry(actions: actions),
            plan: PlaceRoutinePlan.make(actions, for: .departure)
        )

        XCTAssertTrue(RoutineRunLifecycle.isLive(
            run, now: noonUTC.addingTimeInterval(RoutineDefaults.departureRunWindow - 60),
            calendar: utcCalendar
        ))
        XCTAssertFalse(RoutineRunLifecycle.isLive(
            run, now: noonUTC.addingTimeInterval(RoutineDefaults.departureRunWindow),
            calendar: utcCalendar
        ), "the window is exclusive — at exactly 30 minutes the run is over")
    }

    // MARK: - The store (UserDefaults, lazy sweep on read)

    private func scratchDefaults() -> UserDefaults {
        let suiteName = "RoutineRunStoreTests"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    func testStore_writeThenRead_roundTrips() {
        let store = UserDefaultsRoutineRunStore(defaults: scratchDefaults(), calendar: utcCalendar)
        let run = makeRun()

        store.write(run)

        XCTAssertEqual(store.readLiveRun(now: noonUTC.addingTimeInterval(600)), run)
    }

    func testStore_readSweepsADeadRunOut() {
        let defaults = scratchDefaults()
        let store = UserDefaultsRoutineRunStore(defaults: defaults, calendar: utcCalendar)
        store.write(makeRun())

        let tomorrow = noonUTC.addingTimeInterval(24 * 3600)

        XCTAssertNil(store.readLiveRun(now: tomorrow))
        XCTAssertNil(
            defaults.data(forKey: UserDefaultsRoutineRunStore.runKey),
            "the lazy sweep CLEARS the dead run — reading is the arc's only expiry mechanism"
        )
    }

    func testStore_endLiveRunClears() {
        let store = UserDefaultsRoutineRunStore(defaults: scratchDefaults(), calendar: utcCalendar)
        store.write(makeRun())

        store.endLiveRun()

        XCTAssertNil(store.readLiveRun(now: noonUTC))
    }

    func testStore_updateMatching_refusesToResurrectAReplacedRun() {
        let store = UserDefaultsRoutineRunStore(defaults: scratchDefaults(), calendar: utcCalendar)
        let original = makeRun()
        let replacement = makeRun()
        store.write(original)
        store.write(replacement)

        var stale = original
        stale.steps = []

        XCTAssertFalse(
            store.updateMatching(stale),
            "a run that ended (or was replaced) under an open screen must STAY gone —"
                + " a blind write here would resurrect it on Today"
        )
        XCTAssertEqual(store.readLiveRun(now: noonUTC), replacement)
        XCTAssertTrue(store.updateMatching(replacement), "the live run still updates")
    }

    func testStore_endRunId_endsOnlyThatRun() {
        let store = UserDefaultsRoutineRunStore(defaults: scratchDefaults(), calendar: utcCalendar)
        let original = makeRun()
        let replacement = makeRun()
        store.write(original)
        store.write(replacement)

        store.end(runId: original.id)
        XCTAssertEqual(
            store.readLiveRun(now: noonUTC), replacement,
            "the screen's completion path must never end a newer run that replaced it mid-view"
        )

        store.end(runId: replacement.id)
        XCTAssertNil(store.readLiveRun(now: noonUTC))
    }

    func testStore_corruptDataDegradesToNoRun() {
        let defaults = scratchDefaults()
        defaults.set(Data("not a run".utf8), forKey: UserDefaultsRoutineRunStore.runKey)
        let store = UserDefaultsRoutineRunStore(defaults: defaults, calendar: utcCalendar)

        XCTAssertNil(store.readLiveRun(now: noonUTC))
    }
}

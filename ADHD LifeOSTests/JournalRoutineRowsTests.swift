//
//  JournalRoutineRowsTests.swift
//  ADHD LifeOSTests
//
//  The routine record on the Journal (F-RoutineRecord-2-Surfaces): E's calls, verbatim in
//  substance — TWO rows per run (started, finished) and the OFFER rows, muted; an unfinished
//  run read gently, never "abandoned"; a swiped offer says "cleared", a timed-out one "not
//  opened". Names resolve through the CURRENT place like `locationEventLine`, so a rename
//  updates every row.
//
//  E's device-walk call (2026-09-06, after seeing real data): the "All activity" switch hides
//  EVERY routine row, not only the offers. Off — the default on every launch — the Journal
//  shows the arrival rows alone; on, it shows the whole routine story.
//

import XCTest
@testable import ADHD_LifeOS

final class JournalRoutineRowsTests: XCTestCase {
    private let noon = Date(timeIntervalSince1970: 1_756_296_000)

    // MARK: - Which rows exist

    func testAStartedRun_isOneStartedRow_stampedAtTheTap() {
        let gym = place()
        var run = record(placeId: gym.id)
        run.started(at: noon.addingTimeInterval(60))

        let entries = JournalTimeline.days(
            logs: [], tasks: [], routineRuns: [run], places: [gym], showAllActivity: true, asOf: noon
        ).flatMap(\.entries)

        XCTAssertEqual(entries.count, 1)
        guard case .routineStarted(let shown) = entries[0] else { return XCTFail("not a started row") }
        XCTAssertEqual(shown.id, run.id)
        XCTAssertEqual(entries[0].timestamp, noon.addingTimeInterval(60))
    }

    func testAFinishedRun_isTwoRows_withDistinctIdentities() {
        let gym = place()
        var run = record(placeId: gym.id)
        run.started(at: noon.addingTimeInterval(60))
        run.ended(at: noon.addingTimeInterval(600), reason: .completed)

        let entries = JournalTimeline.days(
            logs: [], tasks: [], routineRuns: [run], places: [gym], showAllActivity: true, asOf: noon
        ).flatMap(\.entries)

        XCTAssertEqual(entries.count, 2, "E's call: two rows per run, not one that updates")
        XCTAssertEqual(entries.map(\.timestamp), [noon.addingTimeInterval(600), noon.addingTimeInterval(60)])
        XCTAssertNotEqual(entries[0].id, entries[1].id, "one document, two rows — the ids must differ")
        guard case .routineEnded = entries[0], case .routineStarted = entries[1] else {
            return XCTFail("expected the finished row above the started row, newest first")
        }
    }

    /// E's device-walk call: the switch hides EVERY routine row. Off, the Journal shows the
    /// crossing alone; nothing about the routine — offered, started or finished — is a line.
    func testEveryRoutineRow_isHiddenUntilTheSwitchIsOn() {
        let gym = place()
        let offer = record(placeId: gym.id)
        var finished = record(placeId: gym.id)
        finished.started(at: noon.addingTimeInterval(60))
        finished.ended(at: noon.addingTimeInterval(600), reason: .completed)
        let arrival = LocationEvent(id: UUID(), placeId: gym.id, kind: .arrival, occurredAt: noon)

        let hidden = JournalTimeline.days(
            logs: [], tasks: [], locationEvents: [arrival], routineRuns: [offer, finished], places: [gym], asOf: noon
        ).flatMap(\.entries)
        let shown = JournalTimeline.days(
            logs: [], tasks: [], locationEvents: [arrival], routineRuns: [offer, finished], places: [gym],
            showAllActivity: true, asOf: noon
        ).flatMap(\.entries)

        XCTAssertEqual(hidden.count, 1, "off: the arrival row alone")
        guard case .locationEvent = hidden[0] else { return XCTFail("the surviving row must be the arrival") }
        XCTAssertEqual(shown.count, 4, "on: arrival + offered + started + finished")
    }

    func testAnOffer_isHiddenUntilTheSwitchIsOn() {
        let gym = place()
        let offer = record(placeId: gym.id)

        let hidden = JournalTimeline.days(
            logs: [], tasks: [], routineRuns: [offer], places: [gym], asOf: noon
        ).flatMap(\.entries)
        let shown = JournalTimeline.days(
            logs: [], tasks: [], routineRuns: [offer], places: [gym], showAllActivity: true, asOf: noon
        ).flatMap(\.entries)

        XCTAssertTrue(hidden.isEmpty, "off by default: an unopened offer is not a line in the day")
        XCTAssertEqual(shown.count, 1)
        guard case .routineOffered = shown[0] else { return XCTFail("not an offered row") }
        XCTAssertEqual(shown[0].timestamp, noon, "stamped at the crossing")
        XCTAssertTrue(shown[0].isMuted)
    }

    func testSwipedAndExpiredOffers_areOfferRows_whenTheSwitchIsOn() {
        let gym = place()
        var swiped = record(placeId: gym.id)
        swiped.dismissed(at: noon.addingTimeInterval(30))
        var expired = record(placeId: gym.id)
        expired.expired(at: noon.addingTimeInterval(7_200))

        let entries = JournalTimeline.days(
            logs: [], tasks: [], routineRuns: [swiped, expired], places: [gym], showAllActivity: true, asOf: noon
        ).flatMap(\.entries)

        XCTAssertEqual(entries.count, 2)
        XCTAssertTrue(entries.allSatisfy(\.isMuted))
    }

    func testStartedAndFinishedRows_areNeverMuted() {
        let gym = place()
        var run = record(placeId: gym.id)
        run.started(at: noon.addingTimeInterval(60))
        run.ended(at: noon.addingTimeInterval(600), reason: .leftPlace)

        let entries = JournalTimeline.days(
            logs: [], tasks: [], routineRuns: [run], places: [gym], showAllActivity: true, asOf: noon
        ).flatMap(\.entries)

        XCTAssertEqual(entries.count, 2)
        XCTAssertFalse(entries.contains(where: \.isMuted))
    }

    /// Like location rows: ambient garnish for the Everything view only. A life-area filter
    /// or any other chip shows none of them — a routine has no life area.
    func testRoutineRows_appearUnderEverythingOnly() {
        let gym = place()
        var run = record(placeId: gym.id)
        run.started(at: noon.addingTimeInterval(60))

        let underWritten = JournalTimeline.days(
            logs: [], tasks: [], routineRuns: [run], places: [gym], showAllActivity: true,
            filter: .written, asOf: noon
        ).flatMap(\.entries)
        let underAnArea = JournalTimeline.days(
            logs: [], tasks: [], routineRuns: [run], places: [gym], showAllActivity: true,
            lifeAreaId: UUID(), asOf: noon
        ).flatMap(\.entries)

        XCTAssertTrue(underWritten.isEmpty)
        XCTAssertTrue(underAnArea.isEmpty)
    }

    func testADanglingPlace_dropsTheRow() {
        var run = record(placeId: UUID())
        run.started(at: noon.addingTimeInterval(60))

        let days = JournalTimeline.days(
            logs: [], tasks: [], routineRuns: [run], places: [place()], showAllActivity: true, asOf: noon
        )

        XCTAssertTrue(days.isEmpty, "a deleted place must not leave an empty day header either")
    }

    func testTheArrivalRow_staysBesideTheRoutineRows() {
        let gym = place()
        var run = record(placeId: gym.id)
        run.started(at: noon.addingTimeInterval(60))
        let arrival = LocationEvent(id: UUID(), placeId: gym.id, kind: .arrival, occurredAt: noon)

        let entries = JournalTimeline.days(
            logs: [], tasks: [], locationEvents: [arrival], routineRuns: [run], places: [gym],
            showAllActivity: true, asOf: noon
        ).flatMap(\.entries)

        XCTAssertEqual(entries.count, 2, "E's call: the arrival is the fact of the crossing and it stays")
    }

    // MARK: - The words

    func testStartedLine() {
        let gym = place()
        var run = record(placeId: gym.id)
        run.started(at: noon.addingTimeInterval(60))

        XCTAssertEqual(
            JournalTimeline.routineLine(.started, for: run, places: [gym]),
            "Started routine at Gym 🏋️"
        )
    }

    func testFinishedLine_countsDoneOfTotal() {
        let gym = place()
        var run = record(placeId: gym.id)
        run.started(at: noon.addingTimeInterval(60))
        run.completedStepsCount = 3
        run.ended(at: noon.addingTimeInterval(600), reason: .completed)

        XCTAssertEqual(
            JournalTimeline.routineLine(.ended, for: run, places: [gym]),
            "Finished routine at Gym 🏋️ · 3 of 4 done"
        )
    }

    /// Recorded fully, read gently (E's call): what happened, never why it stopped.
    func testUnfinishedLine_saysWhatHappened_neverAbandoned() {
        let gym = place()
        for reason in [RoutineRunEndReason.leftPlace, .windowLapsed, .dayEnded, .replaced] {
            var run = record(placeId: gym.id)
            run.started(at: noon.addingTimeInterval(60))
            run.completedStepsCount = 2
            run.ended(at: noon.addingTimeInterval(600), reason: reason)

            let line = JournalTimeline.routineLine(.ended, for: run, places: [gym])

            XCTAssertEqual(line, "Routine at Gym 🏋️ · 2 of 4 done", "\(reason)")
        }
    }

    func testOfferedLine_clearedForASwipe_notOpenedOtherwise() {
        let gym = place()
        var swiped = record(placeId: gym.id)
        swiped.dismissed(at: noon.addingTimeInterval(30))
        var expired = record(placeId: gym.id)
        expired.expired(at: noon.addingTimeInterval(7_200))
        let pending = record(placeId: gym.id)

        XCTAssertEqual(
            JournalTimeline.routineLine(.offered, for: swiped, places: [gym]),
            "Routine offered at Gym 🏋️ · cleared"
        )
        XCTAssertEqual(
            JournalTimeline.routineLine(.offered, for: expired, places: [gym]),
            "Routine offered at Gym 🏋️ · not opened"
        )
        XCTAssertEqual(
            JournalTimeline.routineLine(.offered, for: pending, places: [gym]),
            "Routine offered at Gym 🏋️ · not opened"
        )
    }

    func testLines_resolveThroughTheCurrentPlace_andSkipAMissingEmoji() {
        let plain = place(name: "The Office", emoji: nil)
        var run = record(placeId: plain.id)
        run.started(at: noon.addingTimeInterval(60))

        XCTAssertEqual(
            JournalTimeline.routineLine(.started, for: run, places: [plain]),
            "Started routine at The Office"
        )
        XCTAssertNil(JournalTimeline.routineLine(.started, for: run, places: []))
    }

    // MARK: - Fixtures

    private func place(name: String = "Gym", emoji: String? = "🏋️") -> Place {
        Place(
            id: UUID(), name: name,
            coordinate: PlaceCoordinate(latitude: 51.5152, longitude: -0.1418),
            radiusMetres: 150, emoji: emoji, actions: []
        )
    }

    /// Four steps, one auto — the routine journey's gym — so "N of 4" is the total.
    private func record(placeId: UUID) -> RoutineRunRecord {
        let actions = [
            PlaceAction(id: UUID(), direction: .arrival, kind: .journalLine(body: "Leg day")),
            PlaceAction(id: UUID(), direction: .arrival, kind: .openApp(scheme: "snapchat", displayName: "Snapchat")),
            PlaceAction(id: UUID(), direction: .arrival, kind: .openApp(scheme: "gym", displayName: "Gym")),
            PlaceAction(id: UUID(), direction: .arrival, kind: .openApp(scheme: "spotify", displayName: "Spotify"))
        ]
        let run = RoutineRun.make(
            event: PlaceTriggerEvent(placeId: placeId, kind: .arrival, occurredAt: noon),
            entry: AtPlaceSnapshot.PlaceEntry(
                placeId: placeId, displayName: "Gym 🏋️", openTaskTitles: [],
                arrivalMessage: nil, actions: actions, latitude: nil, longitude: nil
            ),
            plan: PlaceRoutinePlan.make(actions, for: .arrival)
        )
        return RoutineRunRecord.offered(run, now: noon)
    }
}

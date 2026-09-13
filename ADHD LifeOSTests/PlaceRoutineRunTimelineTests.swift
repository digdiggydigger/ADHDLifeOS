//
//  PlaceRoutineRunTimelineTests.swift
//  ADHD LifeOSTests
//
//  `F-CTACelebrations-6`'s detail section — E's 2026-09-13 addition to the congratulation:
//  *"a small section within the empty-space … that display detailed data and info about that
//  specific routine that was run."*
//
//  **E's six answers, and two of them REVERSE an earlier answer:**
//  1. "Time started" is BOTH lines — the crossing (arrived) and the tap that opened it.
//  2. "Time finished" is BOTH lines — the last step resolved and the Completed tap.
//  3. The facts are the total time, the time per step, and a comparison with the usual.
//  4. A long list SCROLLS (reverses answer 6's "shrink to fit, no scrolling").
//  5. The view STAYS UNTIL DISMISSED (reverses R5's auto-leave).
//  6. The detail block is pinned under the summary, above the scrolling list.
//

import XCTest
@testable import ADHD_LifeOS

final class PlaceRoutineRunTimelineTests: XCTestCase {

    private func XCTUnwrap0(_ zone: TimeZone?) -> TimeZone { zone ?? .gmt }

    private let arrival = Date(timeIntervalSince1970: 1_756_296_000)   // the crossing
    private var activation: Date { arrival.addingTimeInterval(2_400) } // +40 min: the tap

    private func step(
        _ state: RoutineStepState, resolvedAt: Date?, name: String = "Snapchat"
    ) -> RoutineRun.Step {
        RoutineRun.Step(
            action: PlaceAction(
                id: UUID(), direction: .arrival,
                kind: .openApp(scheme: name.lowercased(), displayName: name)
            ),
            state: state, resolvedAt: resolvedAt
        )
    }

    private func run(_ steps: [RoutineRun.Step], activated: Bool = true) -> RoutineRun {
        var run = RoutineRun(
            id: UUID(), placeId: UUID(), direction: .arrival,
            startedAt: arrival, displayName: "Gym 🏋️", customMessage: nil, steps: steps
        )
        run.activatedAt = activated ? activation : nil
        return run
    }

    // MARK: - E's answers 1 and 2: four moments, not two

    /// The model already held both, and they answer different questions: you arrive, dismiss
    /// the banner, and open the routine forty minutes later.
    func testTheTimelineKeepsTheCrossingAndTheTapApart() {
        let timeline = PlaceRoutineRunTimeline.make(
            run: run([step(.done, resolvedAt: activation.addingTimeInterval(600))]),
            confirmedAt: activation.addingTimeInterval(900)
        )
        XCTAssertEqual(timeline.arrivedAt, arrival)
        XCTAssertEqual(timeline.startedAt, activation)
    }

    /// E's R1 is what makes these differ: Completed can be tapped long after the last step.
    func testTheTimelineKeepsTheLastStepAndTheConfirmationApart() {
        let lastStep = activation.addingTimeInterval(600)
        let confirmed = activation.addingTimeInterval(3_000)
        let timeline = PlaceRoutineRunTimeline.make(
            run: run([
                step(.done, resolvedAt: activation.addingTimeInterval(120)),
                step(.skipped, resolvedAt: lastStep)
            ]),
            confirmedAt: confirmed
        )
        XCTAssertEqual(timeline.lastStepAt, lastStep, "the LATEST resolution, not the first")
        XCTAssertEqual(timeline.confirmedAt, confirmed)
    }

    /// **The rule that stops this screen inventing a second truth.**
    /// `RoutineRunRecord.timeSpentSeconds` measures activation → last interaction, with the
    /// comment "never to the end stamp: a run ended by a departure an hour later … must not
    /// claim that hour". If the congratulation derived its total from the Completed tap, one
    /// run would report two different lengths — here and in the Journal.
    func testTheTotalMatchesTheRecordsOwnDefinitionAndNotTheConfirmationTap() {
        let lastStep = activation.addingTimeInterval(600)
        let timeline = PlaceRoutineRunTimeline.make(
            run: run([step(.done, resolvedAt: lastStep)]),
            confirmedAt: activation.addingTimeInterval(3_000)
        )
        XCTAssertEqual(timeline.workedDuration, 600)
    }

    /// A run minted by an older build, or a banner that never activated, has no tap to measure
    /// from. `nil` rather than a number derived from the crossing, which would silently include
    /// the forty minutes before anyone opened it.
    func testARunWithNoTapHasNoTotalRatherThanAWrongOne() {
        let timeline = PlaceRoutineRunTimeline.make(
            run: run([step(.done, resolvedAt: activation)], activated: false),
            confirmedAt: activation
        )
        XCTAssertNil(timeline.startedAt)
        XCTAssertNil(timeline.workedDuration)
    }

    // MARK: - E's answer 3: the time per step

    /// Each step's own stretch: from whatever was resolved before it to its own stamp. Auto
    /// steps all resolve at activation, so they read as instant — which is true.
    func testEachStepsDurationRunsFromThePreviousResolution() {
        let run = run([
            step(.autoDone, resolvedAt: activation),
            step(.done, resolvedAt: activation.addingTimeInterval(120)),
            step(.done, resolvedAt: activation.addingTimeInterval(300))
        ])
        XCTAssertEqual(PlaceRoutineStepDuration.durations(for: run), [0, 120, 180])
    }

    func testAPendingOrUnstampedStepHasNoDuration() {
        let run = run([
            step(.done, resolvedAt: activation.addingTimeInterval(60)),
            step(.pending, resolvedAt: nil)
        ])
        XCTAssertEqual(PlaceRoutineStepDuration.durations(for: run), [60, nil])
    }

    /// Undo clears a stamp and a step can be re-resolved out of order, so the durations are
    /// computed over the resolutions in TIME order rather than in list order.
    func testStepsResolvedOutOfOrderStillEachGetTheirOwnStretch() {
        let run = run([
            step(.done, resolvedAt: activation.addingTimeInterval(300)),
            step(.done, resolvedAt: activation.addingTimeInterval(100))
        ])
        XCTAssertEqual(
            PlaceRoutineStepDuration.durations(for: run), [200, 100],
            "the step resolved SECOND in time took 200 s, whichever row it occupies"
        )
    }

    // MARK: - E's answer 3: compare with your usual

    private func record(worked seconds: Int, placeId: UUID, id: UUID = UUID()) -> RoutineRunRecord {
        var record = RoutineRunRecord.offered(
            RoutineRun(
                id: id, placeId: placeId, direction: .arrival,
                startedAt: arrival, displayName: "Gym 🏋️", customMessage: nil, steps: []
            ),
            now: arrival
        )
        record.status = .ended
        record.timeSpentSeconds = seconds
        return record
    }

    func testWithNoPastRunsOfThisRoutineThereIsNothingToCompareWith() {
        let place = UUID()
        XCTAssertEqual(
            PlaceRoutineComparison.verdict(
                worked: 600, history: [], placeId: place, direction: .arrival, excluding: UUID()
            ),
            .noHistory
        )
    }

    /// Only THIS routine's own past runs count — the same place and the same direction. A
    /// leaving-the-office routine says nothing about how long the gym usually takes.
    func testOnlyThisRoutinesOwnPastRunsCount() {
        let place = UUID()
        let other = record(worked: 60, placeId: UUID())
        XCTAssertEqual(
            PlaceRoutineComparison.verdict(
                worked: 600, history: [other], placeId: place, direction: .arrival, excluding: UUID()
            ),
            .noHistory,
            "another place's run leaked into this routine's history"
        )
    }

    func testABestEverRunSaysSo() {
        let place = UUID()
        let history = [record(worked: 900, placeId: place), record(worked: 1_200, placeId: place)]
        XCTAssertEqual(
            PlaceRoutineComparison.verdict(
                worked: 600, history: history, placeId: place, direction: .arrival, excluding: UUID()
            ),
            .fastestYet
        )
    }

    /// The band is what stops a routine that is nine seconds off its median claiming a result.
    func testARunInsideTheUsualBandReadsAsTypical() {
        let place = UUID()
        let history = [
            record(worked: 600, placeId: place),
            record(worked: 620, placeId: place),
            record(worked: 580, placeId: place)
        ]
        XCTAssertEqual(
            PlaceRoutineComparison.verdict(
                worked: 610, history: history, placeId: place, direction: .arrival, excluding: UUID()
            ),
            .usual(typical: 600)
        )
    }

    func testAMarkedlyLongerRunSaysThatToo() {
        let place = UUID()
        let history = [
            record(worked: 600, placeId: place),
            record(worked: 600, placeId: place)
        ]
        XCTAssertEqual(
            PlaceRoutineComparison.verdict(
                worked: 1_800, history: history, placeId: place, direction: .arrival, excluding: UUID()
            ),
            .longerThanUsual(typical: 600)
        )
    }

    /// **The run being celebrated is in its OWN history, and that is not hypothetical.**
    /// `complete()` writes `recorder.ended(...)` fire-and-forget, and the congratulation then
    /// fetches every routine run — so this run's own record is usually already there, with the
    /// very time being compared. Left in, it is always its own `quickest`, "fastest yet" could
    /// essentially never fire, and it drags the median toward itself. Worse, whether it is
    /// there at all depends on whether a network write landed first, so the verdict would be
    /// TIMING-DEPENDENT — green on a fast connection and wrong on a slow one.
    func testTheRunBeingCelebratedIsNeverItsOwnHistory() {
        let place = UUID()
        let runId = UUID()
        let history = [
            record(worked: 100, placeId: place, id: runId),
            record(worked: 900, placeId: place)
        ]
        XCTAssertEqual(
            PlaceRoutineComparison.verdict(
                worked: 600, history: history, placeId: place,
                direction: .arrival, excluding: runId
            ),
            .fastestYet,
            "this run counted itself, so it can never beat its own time"
        )
    }

    /// A run with no measurable total cannot be compared with anything.
    func testARunWithNoTotalIsNeverCompared() {
        let place = UUID()
        XCTAssertEqual(
            PlaceRoutineComparison.verdict(
                worked: nil, history: [record(worked: 600, placeId: place)],
                placeId: place, direction: .arrival, excluding: UUID()
            ),
            .noHistory
        )
    }

    // MARK: - The words

    /// Durations carry SECONDS below a minute, because a routine step is often that quick and
    /// "0 min" would read as a bug.
    func testADurationReadsInTheLargestUnitThatStillSaysSomething() {
        XCTAssertEqual(PlaceRoutineTimeFormatting.duration(45), "45s")
        XCTAssertEqual(PlaceRoutineTimeFormatting.duration(600), "10m")
        XCTAssertEqual(PlaceRoutineTimeFormatting.duration(4_500), "1h 15m")
        XCTAssertEqual(PlaceRoutineTimeFormatting.duration(3_600), "1h")
    }

    /// E asked for `hh:mm:ss` by name, so the seconds stay — but through the reader's own
    /// locale rather than a hard 24-hour format, because this app is headed for a public
    /// launch and half the world writes 1:00:00 PM.
    func testAClockTimeCarriesTheSecondsEAskedFor() {
        XCTAssertEqual(
            PlaceRoutineTimeFormatting.clock(
                arrival, locale: Locale(identifier: "en_GB"),
                timeZone: XCTUnwrap0(TimeZone(identifier: "Europe/London"))
            ),
            "13:00:00"
        )
    }

    func testAClockTimeFollowsTheReadersLocaleRatherThanAFixedTwentyFourHourClock() {
        let american = PlaceRoutineTimeFormatting.clock(
            arrival, locale: Locale(identifier: "en_US"),
            timeZone: XCTUnwrap0(TimeZone(identifier: "Europe/London"))
        )
        XCTAssertTrue(american.hasPrefix("1:00:00"), american)
        XCTAssertTrue(
            american.uppercased().contains("PM"), "a 12-hour locale must keep its meridiem: \(american)"
        )
    }

    func testAZeroDurationReadsAsInstantRatherThanAsZeroSeconds() {
        XCTAssertEqual(PlaceRoutineTimeFormatting.duration(0), "instant")
    }
}

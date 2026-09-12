//
//  DailyGoalTrackerTests.swift
//  ADHD LifeOSTests
//
//  `F-CTACelebrations-5`: E's third full-screen milestone — **the Momentum daily goal**, F7, "the
//  moment the count crosses the goal, any tab", about a second after the action, once per day.
//
//  **This is the milestone with no site.** The other three hang off a button: someone tapped
//  Sorted, or Done for now, and the tap is the event. Nothing is tapped here — Home's ring count is
//  a SUM over three reloading data sources, and the "event" is a number changing while the user may
//  be on another tab entirely. Every test below exists because a sum that moves is not the same
//  thing as an achievement:
//
//  - the first load moves it from nothing to everything;
//  - a reload whose nudges fetch failed drops it and the next one puts it back;
//  - turning "count cleared captures" on in Settings raises it without anything being done;
//  - lowering the goal in Settings puts the count over it without anything being done.
//
//  Each of those would be a full-screen celebration the user did not earn — the loudest possible
//  false positive, and one they cannot dismiss.
//

import CoreGraphics
import XCTest
@testable import ADHD_LifeOS

final class DailyGoalTrackerTests: XCTestCase {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private var noon: Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: 12, hour: 12))!
    }

    private func rules(goal: Int, captures: Bool = true, nudges: Bool = true) -> DailyGoalRules {
        DailyGoalRules(goal: goal, countsClearedCaptures: captures, countsNudges: nudges)
    }

    // MARK: - The crossing itself

    func testCrossing_isTrueOnlyWhenTheCountArrivesAtTheGoal() {
        XCTAssertTrue(DailyGoalCrossing.crossed(previous: 4, current: 5, goal: 5))
        XCTAssertTrue(DailyGoalCrossing.crossed(previous: 3, current: 7, goal: 5))
    }

    func testCrossing_isFalseBelowTheGoalAndFalseOnceAlreadyOverIt() {
        XCTAssertFalse(DailyGoalCrossing.crossed(previous: 3, current: 4, goal: 5))
        XCTAssertFalse(DailyGoalCrossing.crossed(previous: 5, current: 6, goal: 5))
    }

    /// A goal of zero is crossed by standing still, so it is not a goal.
    func testCrossing_isFalseForAGoalOfZero() {
        XCTAssertFalse(DailyGoalCrossing.crossed(previous: 0, current: 0, goal: 0))
    }

    // MARK: - The tracker: what a moving number is allowed to mean

    /// **Home's first load takes the count from 0 to whatever today already was.** Opening the app
    /// having closed six tasks on another device is not a crossing, and F7's "once per day" would
    /// not save it — it is the first thing that happens.
    func testTheFirstObservationNeverCounts() {
        var tracker = DailyGoalTracker()
        XCTAssertFalse(tracker.observe(count: 6, rules: rules(goal: 5), settled: true))
    }

    func testARiseAcrossTheGoalCountsExactlyOnce() {
        var tracker = DailyGoalTracker()
        _ = tracker.observe(count: 3, rules: rules(goal: 5), settled: true)
        XCTAssertTrue(tracker.observe(count: 5, rules: rules(goal: 5), settled: true))
        XCTAssertFalse(
            tracker.observe(count: 6, rules: rules(goal: 5), settled: true),
            "The count kept rising past a goal it had already crossed."
        )
    }

    /// **The transient-drop guard, and it is the one that protects a real user.** A reload whose
    /// nudges fetch failed reports 0 extra dismissals; the next good reload puts them back. Without
    /// the settled gate that is a rise from 3 to 6 across a goal of 5 — and the user did nothing.
    func testAnUnsettledObservationNeitherCountsNorMovesTheBaseline() {
        var tracker = DailyGoalTracker()
        _ = tracker.observe(count: 6, rules: rules(goal: 5), settled: true)
        XCTAssertFalse(tracker.observe(count: 3, rules: rules(goal: 5), settled: false))
        XCTAssertFalse(
            tracker.observe(count: 6, rules: rules(goal: 5), settled: true),
            "A failed fetch dropped the baseline, so recovering from it read as a fresh crossing."
        )
    }

    /// **Lowering the goal under the count is not an achievement**, and Settings is one sheet away
    /// from the ring.
    func testLoweringTheGoalUnderTheCountNeverCounts() {
        var tracker = DailyGoalTracker()
        _ = tracker.observe(count: 4, rules: rules(goal: 8), settled: true)
        XCTAssertFalse(tracker.observe(count: 4, rules: rules(goal: 3), settled: true))
    }

    /// **Nor is turning a counting rule ON.** "Count cleared captures" can take the ring from 3 to
    /// 8 with a single tap in Settings, which is the same shape as lowering the goal and needs the
    /// same answer — the rules are part of what the number MEANS, so a change to them re-baselines.
    func testTurningOnACountingRuleNeverCounts() {
        var tracker = DailyGoalTracker()
        _ = tracker.observe(count: 3, rules: rules(goal: 5, captures: false), settled: true)
        XCTAssertFalse(tracker.observe(count: 8, rules: rules(goal: 5, captures: true), settled: true))
    }

    /// A re-baseline is not a free pass: the very next real crossing still counts.
    func testACrossingAfterARuleChangeStillCounts() {
        var tracker = DailyGoalTracker()
        _ = tracker.observe(count: 3, rules: rules(goal: 5, captures: false), settled: true)
        _ = tracker.observe(count: 3, rules: rules(goal: 5, captures: true), settled: true)
        XCTAssertTrue(tracker.observe(count: 5, rules: rules(goal: 5, captures: true), settled: true))
    }

    // MARK: - Once per day, per ACCOUNT

    private func defaults(_ name: String = #function) -> UserDefaults {
        let suite = UserDefaults(suiteName: "DailyGoalTrackerTests.\(name)")!
        suite.removePersistentDomain(forName: "DailyGoalTrackerTests.\(name)")
        return suite
    }

    func testAMilestoneIsMarkedForTheDayAndReadsBackAsCelebrated() {
        let store = defaults()
        XCTAssertFalse(
            CelebrationDayMarking.hasCelebrated(
                .dailyGoal, uid: "abc", asOf: noon, calendar: calendar, in: store
            )
        )
        CelebrationDayMarking.markCelebrated(
            .dailyGoal, uid: "abc", asOf: noon, calendar: calendar, in: store
        )
        XCTAssertTrue(
            CelebrationDayMarking.hasCelebrated(
                .dailyGoal, uid: "abc", asOf: noon.addingTimeInterval(6 * 3600),
                calendar: calendar, in: store
            ),
            "F7: once per day — and an undo-and-recross must not replay it."
        )
    }

    func testTomorrowIsANewDay() {
        let store = defaults()
        CelebrationDayMarking.markCelebrated(
            .dailyGoal, uid: "abc", asOf: noon, calendar: calendar, in: store
        )
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: noon)!
        XCTAssertFalse(
            CelebrationDayMarking.hasCelebrated(
                .dailyGoal, uid: "abc", asOf: tomorrow, calendar: calendar, in: store
            )
        )
    }

    /// **Keyed by uid, and that is the entire point** — `NudgeFirstRunMarker`'s lesson exactly. A
    /// per-device key would let a second account on one phone inherit the first's "already
    /// celebrated today", so a real crossing would be silently swallowed.
    func testASecondAccountOnTheSamePhoneNeverInheritsTheFirstsDay() {
        let store = defaults()
        CelebrationDayMarking.markCelebrated(
            .dailyGoal, uid: "abc", asOf: noon, calendar: calendar, in: store
        )
        XCTAssertFalse(
            CelebrationDayMarking.hasCelebrated(
                .dailyGoal, uid: "xyz", asOf: noon, calendar: calendar, in: store
            )
        )
    }

    func testEachMilestoneKeepsItsOwnDay() {
        let store = defaults()
        CelebrationDayMarking.markCelebrated(
            .dailyGoal, uid: "abc", asOf: noon, calendar: calendar, in: store
        )
        XCTAssertFalse(
            CelebrationDayMarking.hasCelebrated(
                .inboxZero, uid: "abc", asOf: noon, calendar: calendar, in: store
            )
        )
    }

    // MARK: - An origin recorded while its tab was parked off screen

    /// **Measured, not reasoned about** (render probe, 2026-09-12): a `.celebrationPopOrigin` on a
    /// view inside a tab that `AppTabContent` has parked reports **(10196.5, 451.0)** where the
    /// visible tab reports **(196.5, 451.0)**. `.offset` reaches a `.global` frame reading.
    ///
    /// That matters here and nowhere else in the app, because the daily goal is the only site that
    /// fires from a tab the user is not looking at (E's F7, "any tab"). Handing that origin over
    /// would throw R-h's fallback pop 10,000 pt off screen — the milestone would be silent in
    /// exactly the case R-h exists to prevent.
    func testAnOriginRecordedWhileItsTabWasParkedIsNotAPlaceToPopFrom() {
        XCTAssertNil(CelebrationPopOrigin.onScreen(CGPoint(x: 10_196.5, y: 451)))
        XCTAssertNil(CelebrationPopOrigin.onScreen(CGPoint(x: 196.5, y: 10_451)))
    }

    func testAnOriginOnTheVisibleTabIsHandedOverUnchanged() {
        XCTAssertEqual(CelebrationPopOrigin.onScreen(CGPoint(x: 196.5, y: 451)), CGPoint(x: 196.5, y: 451))
        XCTAssertNil(CelebrationPopOrigin.onScreen(nil))
    }

    // MARK: - What VoiceOver is told (E's call, 2026-09-12)

    /// **E chose "the daily goal only".** The other two milestones leave the user on a screen that
    /// states the outcome — an empty inbox, a card reading "7 of 7 days" — and each has a haptic of
    /// its own. This one fires on ANY tab about a second after the action, the ring may not be on
    /// screen at all, and the site has no haptic (R-d: the CENTRE plays `.success` for it), so a
    /// VoiceOver user would otherwise never learn it happened.
    func testTheDailyGoalAnnouncementNamesTheNumbersThatWereReached() {
        XCTAssertEqual(
            DailyGoalAnnouncement.text(count: 5, goal: 5), "Daily goal reached — 5 of 5 closed today"
        )
        XCTAssertEqual(
            DailyGoalAnnouncement.text(count: 7, goal: 5), "Daily goal reached — 7 of 5 closed today"
        )
    }
}

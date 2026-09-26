//
//  TodayCardCopyTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// `F-E3-OneCardToday`: every word Today's one card and the lines under it say, from board `59`
/// (the frames E chose H1 from) and the round-5 record.
final class TodayCardCopyTests: XCTestCase {

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }()

    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: 26, hour: 10))!
    }

    private func task(due: Int? = nil, effortMinutes: Int? = nil) -> TaskSummary {
        TaskSummary(
            lifeAreaId: nil,
            status: .open,
            title: "Reply to Priya",
            dueDate: due.map { calendar.date(byAdding: .day, value: $0, to: now)! },
            focusDurationSeconds: effortMinutes.map { $0 * 60 }
        )
    }

    private func eyebrow(_ slot: TodaySlot) -> String? {
        TodayCardCopy.eyebrow(for: slot, asOf: now, calendar: calendar, locale: Locale(identifier: "en_GB"))
    }

    // MARK: - The eyebrow (sentence case here; `sectionLabel()` capitalises it on screen)

    func testThePinnedEyebrow() {
        XCTAssertEqual(eyebrow(.pinned(task(due: 0))), "Next · Pinned")
    }

    func testTheSuggestedEyebrowSaysWhenItIsDue() {
        XCTAssertEqual(eyebrow(.suggested(task(due: 0))), "Suggested · Due today")
        XCTAssertEqual(eyebrow(.suggested(task())), "Suggested")
        XCTAssertEqual(eyebrow(.suggested(task(due: 2))), "Suggested")
    }

    /// Round 8: *"Still open"* replaced "Overdue" — the app never tallies what was missed.
    func testAnOverdueSuggestionSaysStillOpenNeverOverdue() {
        XCTAssertEqual(eyebrow(.suggested(task(due: -3))), "Suggested · Still open")
    }

    func testThePausedEyebrowCountsTheMinutesAlreadyDone() {
        let sprint = TodayPausedSprint(taskId: nil, taskTitle: "Draft", durationSeconds: 1_200, remainingSeconds: 480)
        XCTAssertEqual(eyebrow(.paused(sprint)), "Paused · 12 min in")
    }

    func testTheLeaveByEyebrowNamesTheTimeAndTheCommitment() {
        let dentist = TodayLeaveBy(
            title: "Dentist",
            leaveAt: calendar.date(from: DateComponents(year: 2026, month: 9, day: 26, hour: 14, minute: 20))!
        )
        XCTAssertEqual(eyebrow(.leaveBy(dentist, task: nil)), "Leave by 14:20 · Dentist")
    }

    /// The place pair draws its own cards, and an empty Today draws none — neither has an eyebrow.
    func testThePlaceAndTheEmptySlotHaveNoEyebrow() {
        XCTAssertNil(eyebrow(.place))
        XCTAssertNil(eyebrow(.nothing))
    }

    // MARK: - The buttons

    /// "Start N min" promises exactly the sprint that launches — the same resolution
    /// `FocusSprintPlan` uses, so a task with no stored length says the default.
    func testStartNamesTheSprintThatWillRun() {
        XCTAssertEqual(TodayCardCopy.startTitle(for: task(effortMinutes: 15), defaultSprintMinutes: 25), "Start 15 min")
        XCTAssertEqual(TodayCardCopy.startTitle(for: task(), defaultSprintMinutes: 25), "Start 25 min")
    }

    func testThePinTogglesLabelSaysWhatTappingDoes() {
        XCTAssertEqual(TodayCardCopy.pinLabel(isPinned: false), "Pin to Today")
        XCTAssertEqual(TodayCardCopy.pinLabel(isPinned: true), "Unpin")
    }

    // MARK: - The paused card

    func testThePausedDetailSaysWhatIsLeftOfWhat() {
        let sprint = TodayPausedSprint(taskId: nil, taskTitle: "Draft", durationSeconds: 1_200, remainingSeconds: 480)
        XCTAssertEqual(TodayCardCopy.pausedDetail(sprint), "8 min left of 20")
    }

    /// A part-minute left is still time to finish — rounding it down to 0 would read as "done".
    func testThePausedDetailRoundsAPartMinuteLeftUp() {
        let sprint = TodayPausedSprint(taskId: nil, taskTitle: "Draft", durationSeconds: 1_500, remainingSeconds: 30)
        XCTAssertEqual(TodayCardCopy.pausedDetail(sprint), "1 min left of 25")
    }

    // MARK: - The "then" rows and the done line

    func testAThenRowsMetaNamesTheAreaAndTheLength() {
        let home = LifeArea(id: UUID(), name: "Home", colour: "🏠", sortOrder: 0)
        XCTAssertEqual(TodayCardCopy.thenMeta(area: home, focusDurationSeconds: 900), "🏠 Home · 15 min")
        XCTAssertEqual(TodayCardCopy.thenMeta(area: home, focusDurationSeconds: nil), "🏠 Home")
        XCTAssertEqual(TodayCardCopy.thenMeta(area: nil, focusDurationSeconds: 900), "15 min")
        XCTAssertNil(TodayCardCopy.thenMeta(area: nil, focusDurationSeconds: nil))
    }

    /// Idea 9, board `59`: *"✓ 3 done today · Week review ›"* — with no daily goal set, which is
    /// every install until Settings turns one on (`F-E1`).
    func testTheDoneLineCountsWhatWasDone() {
        XCTAssertEqual(TodayCardCopy.doneTodayLine(count: 3, goal: nil), "3 done today")
        XCTAssertEqual(TodayCardCopy.doneTodayLine(count: 0, goal: nil), "0 done today")
    }

    /// E, 2026-09-26 (Q2, board `E3-Q2`): *"'3 of 5 done today' once a daily goal is set"*. With the
    /// ring gone this line is the only place a chosen goal can be seen; it counts what was done
    /// against it, never what is missing, and it keeps counting past the goal.
    func testWithADailyGoalTheDoneLineSaysTheGoal() {
        XCTAssertEqual(TodayCardCopy.doneTodayLine(count: 3, goal: 5), "3 of 5 done today")
        XCTAssertEqual(TodayCardCopy.doneTodayLine(count: 7, goal: 5), "7 of 5 done today")
    }
}

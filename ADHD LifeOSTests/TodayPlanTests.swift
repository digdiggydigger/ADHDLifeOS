//
//  TodayPlanTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// `F-E3-OneCardToday`: what takes Today's ONE card, and what the "then" list under it holds.
///
/// E's round 5a, verbatim: *"Leave by (inside 30 min) > live routine > paused sprint (Resume) >
/// pinned task > suggestion... Only a hard deadline outranks where you are."* E's 2026-09-24 Step 0
/// answer adds that the live-routine card and the arrival card COUNT AS the one card together, so
/// "where you are" is either of them. Round 5b: *"'Not this one' → 'Back in the list, not
/// re-suggested today.' The skipped task stays tappable in the 'then' list."*
final class TodayPlanTests: XCTestCase {

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }()

    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: 26, hour: 10))!
    }

    private func task(
        _ title: String,
        due: Int? = nil,
        effortMinutes: Int? = nil,
        priority: TaskPriority = .p3
    ) -> TaskSummary {
        TaskSummary(
            lifeAreaId: nil,
            status: .open,
            title: title,
            priority: priority,
            dueDate: due.map { calendar.date(byAdding: .day, value: $0, to: now)! },
            focusDurationSeconds: effortMinutes.map { $0 * 60 }
        )
    }

    private let paused = TodayPausedSprint(
        taskId: nil, taskTitle: "Draft the brief", durationSeconds: 1_200, remainingSeconds: 480
    )

    private func plan(
        _ tasks: [TaskSummary],
        pinned: UUID? = nil,
        skipped: Set<UUID> = [],
        pausedSprint: TodayPausedSprint? = nil,
        hasPlaceCard: Bool = false,
        leaveBy: TodayLeaveBy? = nil
    ) -> TodayPlan {
        TodayPlan.build(
            openTasks: tasks,
            pinnedTaskId: pinned,
            skippedTaskIds: skipped,
            pausedSprint: pausedSprint,
            hasPlaceCard: hasPlaceCard,
            leaveBy: leaveBy,
            asOf: now,
            calendar: calendar
        )
    }

    // MARK: - The slot order

    func testNothingOpen_leavesTheSlotEmpty() {
        XCTAssertEqual(plan([]).slot, .nothing)
        XCTAssertNil(plan([]).headlineTask)
    }

    func testWithNothingElse_theSuggestionTakesTheSlot() {
        let reply = task("Reply to Priya", due: 0, effortMinutes: 15)
        XCTAssertEqual(plan([reply]).slot, .suggested(reply))
    }

    /// The suggestion is `bestNextMove`'s answer, not a new ranking — the H1 card replaced
    /// `BestNextMoveCard` and inherits its choice (shortest due task first).
    func testTheSuggestionIsTheBestNextMove() {
        let long = task("Long", due: 0, effortMinutes: 45)
        let short = task("Short", due: 0, effortMinutes: 15)
        XCTAssertEqual(plan([long, short]).slot, .suggested(short))
    }

    func testAPinnedTaskBeatsTheSuggestion() {
        let short = task("Short", due: 0, effortMinutes: 15)
        let chosen = task("Chosen", effortMinutes: 60)
        XCTAssertEqual(plan([short, chosen], pinned: chosen.id).slot, .pinned(chosen))
    }

    /// A pin whose task has closed (or been deleted) is not a pin any more — the slot falls
    /// through to the suggestion rather than showing nothing.
    func testAPinOnATaskThatIsNoLongerOpen_isIgnored() {
        let short = task("Short", due: 0, effortMinutes: 15)
        XCTAssertEqual(plan([short], pinned: UUID()).slot, .suggested(short))
    }

    func testAPausedSprintBeatsAPin() {
        let chosen = task("Chosen")
        XCTAssertEqual(plan([chosen], pinned: chosen.id, pausedSprint: paused).slot, .paused(paused))
    }

    func testWhereYouAreBeatsAPausedSprint() {
        XCTAssertEqual(plan([task("A")], pausedSprint: paused, hasPlaceCard: true).slot, .place)
    }

    func testOnlyAHardDeadlineOutranksWhereYouAre() {
        let reply = task("Reply", due: 0, effortMinutes: 15)
        let dentist = TodayLeaveBy(title: "Dentist", leaveAt: now.addingTimeInterval(20 * 60))
        XCTAssertEqual(
            plan([reply], pausedSprint: paused, hasPlaceCard: true, leaveBy: dentist).slot,
            .leaveBy(dentist, task: reply)
        )
    }

    // MARK: - "Not this one"

    func testASkippedTaskIsNotSuggestedAgain() {
        let short = task("Short", due: 0, effortMinutes: 15)
        let long = task("Long", due: 0, effortMinutes: 45)
        XCTAssertEqual(plan([short, long], skipped: [short.id]).slot, .suggested(long))
    }

    func testSkippingEverything_leavesNothingToSuggest() {
        let only = task("Only", due: 0)
        XCTAssertEqual(plan([only], skipped: [only.id]).slot, .nothing)
    }

    /// Skipping is a suggestion's verb. A task the user PINNED stays pinned even if it was
    /// skipped earlier the same day — the pin is the later, explicit choice.
    func testAPinOutranksAnEarlierSkip() {
        let chosen = task("Chosen", due: 0)
        XCTAssertEqual(plan([chosen], pinned: chosen.id, skipped: [chosen.id]).slot, .pinned(chosen))
    }

    // MARK: - The "then" list

    func testTheThenListHoldsWhatIsDueExceptTheCardsTask() {
        let short = task("Short", due: 0, effortMinutes: 15)
        let overdue = task("Overdue", due: -2, effortMinutes: 30)
        let later = task("Later", due: 3)
        let undated = task("Undated")
        XCTAssertEqual(plan([short, overdue, later, undated]).thenTasks, [overdue])
    }

    /// Round 5b: "Back in the list" — including when the skipped task has no date, which is the
    /// case `bestNextMove`'s fallback to `topTask` produces.
    func testASkippedUndatedTaskComesBackInTheThenList() {
        let undated = task("Undated", priority: .p1)
        let other = task("Other", priority: .p2)
        let result = plan([undated, other], skipped: [undated.id])
        XCTAssertEqual(result.slot, .suggested(other))
        XCTAssertEqual(result.thenTasks, [undated])
    }

    /// A pinned task that something else displaced (a routine, a paused sprint) must not vanish:
    /// it leads the list, because the user chose it.
    func testAPinnedTaskDisplacedFromTheCardLeadsTheThenList() {
        let due = task("Due", due: 0)
        let chosen = task("Chosen")
        let result = plan([due, chosen], pinned: chosen.id, hasPlaceCard: true)
        XCTAssertEqual(result.slot, .place)
        XCTAssertEqual(result.thenTasks, [chosen, due])
    }

    func testThePausedSprintsTaskIsNotRepeatedInTheThenList() {
        let drafting = task("Draft the brief", due: 0)
        let sprint = TodayPausedSprint(
            taskId: drafting.id, taskTitle: drafting.title, durationSeconds: 1_200, remainingSeconds: 480
        )
        let other = task("Other", due: 0)
        XCTAssertEqual(plan([drafting, other], pausedSprint: sprint).thenTasks, [other])
    }

    // MARK: - The headline the widget publishes

    /// The Home Screen widget used `topTask` while Today led with `bestNextMove`, so the two
    /// disagreed whenever anything was due. Both now read this one value.
    func testTheHeadlineIsThePinElseTheSuggestion() {
        let short = task("Short", due: 0, effortMinutes: 15)
        let chosen = task("Chosen")
        XCTAssertEqual(plan([short, chosen]).headlineTask, short)
        XCTAssertEqual(plan([short, chosen], pinned: chosen.id).headlineTask, chosen)
    }

    /// Where you are and a paused sprint take the CARD, not the widget's Active Goal — the widget
    /// shows the sprint in its own section, and the task you would do next is still the answer.
    func testTheHeadlineSurvivesThePlaceAndThePausedSprint() {
        let short = task("Short", due: 0, effortMinutes: 15)
        XCTAssertEqual(plan([short], pausedSprint: paused, hasPlaceCard: true).headlineTask, short)
    }

    // MARK: - The paused sprint's projection

    func testAPausedSprintIsBuiltOnlyWhenTheSprintIsPaused() {
        let running = FocusWidgetSnapshot.ActiveSprint(
            taskTitle: "Draft", emoji: "💼", durationSeconds: 1_200,
            deadline: now.addingTimeInterval(600), pausedRemainingSeconds: nil, checkpointSeconds: []
        )
        let pausedSprint = FocusWidgetSnapshot.ActiveSprint(
            taskTitle: "Draft", emoji: "💼", durationSeconds: 1_200,
            deadline: nil, pausedRemainingSeconds: 480, checkpointSeconds: []
        )
        let id = UUID()
        XCTAssertNil(TodayPausedSprint.from(status: ActiveSprintStatus(taskId: id, isPaused: false), sprint: running))
        XCTAssertNil(TodayPausedSprint.from(status: nil, sprint: pausedSprint))
        XCTAssertEqual(
            TodayPausedSprint.from(status: ActiveSprintStatus(taskId: id, isPaused: true), sprint: pausedSprint),
            TodayPausedSprint(taskId: id, taskTitle: "Draft", durationSeconds: 1_200, remainingSeconds: 480)
        )
    }
}

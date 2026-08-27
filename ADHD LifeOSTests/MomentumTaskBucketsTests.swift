//
//  MomentumTaskBucketsTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The Tasks tab's Momentum grouping (Concept C, block M3; narrowed in F-V3-Tasks-rebuild): due-time
/// buckets instead of life areas — Due today, Tomorrow, and the evidence pile, Closed today. The
/// long tail (later / undated) is deliberately NOT here (E's b11 call): Momentum is today's page,
/// and the rest lives under the Open filter. Same `LifeAreaTaskGroup` container the list renders.
final class MomentumTaskBucketsTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: 14, hour: 9, minute: 41))!
    }

    private func task(
        _ title: String,
        dueDaysFromNow: Int? = nil,
        status: TaskStatus = .open,
        priority: TaskPriority = .p3,
        focusSeconds: Int? = nil,
        completedDaysAgo: Int? = nil
    ) -> TaskItem {
        TaskItem(
            id: UUID(), lifeAreaId: nil, title: title, status: status, priority: priority,
            dueDate: dueDaysFromNow.map { calendar.date(byAdding: .day, value: $0, to: now)! },
            focusDurationSeconds: focusSeconds,
            completedAt: completedDaysAgo.map { calendar.date(byAdding: .day, value: -$0, to: now)! }
        )
    }

    func testGroup_bucketsByDueness_inFixedOrder() {
        let groups = MomentumTaskBuckets.group(
            tasks: [
                task("Closed", status: .done, completedDaysAgo: 0),
                task("Tomorrow", dueDaysFromNow: 1),
                task("Today", dueDaysFromNow: 0)
            ],
            asOf: now, calendar: calendar
        )

        XCTAssertEqual(
            groups.map(\.lifeAreaName),
            ["Due today · 1", "Tomorrow · 1", "Closed today · 1"]
        )
    }

    /// The long tail is Momentum's biggest overwhelm risk, so it is excluded outright: tasks due
    /// beyond tomorrow, and undated tasks, render only under the Open filter (E's b11 call).
    func testGroup_excludesLaterAndUndatedTasks() {
        let groups = MomentumTaskBuckets.group(
            tasks: [task("Undated"), task("Later", dueDaysFromNow: 3), task("Today", dueDaysFromNow: 0)],
            asOf: now, calendar: calendar
        )

        XCTAssertEqual(groups.map(\.lifeAreaName), ["Due today · 1"])
    }

    /// Overdue is not its own shame pile — it joins Due today, the same "due now" reading the
    /// scoreboard uses.
    func testGroup_overdueJoinsDueToday() {
        let groups = MomentumTaskBuckets.group(
            tasks: [task("Overdue", dueDaysFromNow: -2), task("Today", dueDaysFromNow: 0)],
            asOf: now, calendar: calendar
        )

        XCTAssertEqual(groups.map(\.lifeAreaName), ["Due today · 2"])
    }

    func testGroup_emptyBucketsAreOmitted() {
        let groups = MomentumTaskBuckets.group(
            tasks: [task("Tomorrow", dueDaysFromNow: 1)], asOf: now, calendar: calendar
        )

        XCTAssertEqual(groups.map(\.lifeAreaName), ["Tomorrow · 1"])
    }

    /// Yesterday's closures are not today's evidence — they belong to the Done filter, not here.
    func testGroup_dropsOldClosures() {
        let groups = MomentumTaskBuckets.group(
            tasks: [task("Old win", status: .done, completedDaysAgo: 1)],
            asOf: now, calendar: calendar
        )

        XCTAssertTrue(groups.isEmpty)
    }

    /// Within a bucket: urgency first, and inside one priority the quick win leads.
    func testGroup_withinBucket_priorityThenShortestEffort() {
        let groups = MomentumTaskBuckets.group(
            tasks: [
                task("P2 quick", dueDaysFromNow: 0, priority: .p2, focusSeconds: 900),
                task("P1 deep", dueDaysFromNow: 0, priority: .p1, focusSeconds: 1500),
                task("P2 slow", dueDaysFromNow: 0, priority: .p2, focusSeconds: 1800)
            ],
            asOf: now, calendar: calendar
        )

        XCTAssertEqual(groups.first?.tasks.map(\.title), ["P1 deep", "P2 quick", "P2 slow"])
    }

    /// Bucket groups need identities that don't collide with each other (they all have a nil
    /// life-area id) or with the life-area grouping's "unassigned".
    func testGroup_bucketIdsAreDistinct() {
        let groups = MomentumTaskBuckets.group(
            tasks: [
                task("Today", dueDaysFromNow: 0),
                task("Tomorrow", dueDaysFromNow: 1),
                task("Closed", status: .done, completedDaysAgo: 0)
            ],
            asOf: now, calendar: calendar
        )

        XCTAssertEqual(Set(groups.map(\.id)).count, groups.count)
    }
}

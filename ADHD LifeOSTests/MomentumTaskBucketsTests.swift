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
///
/// *Annotated by `F-D3-TasksAnytimeRow` (2026-09-24):* "undated" no longer belongs to that
/// sentence; "later" still does. Round 6 gave undated tasks a fourth bucket, "Anytime · N", last
/// on the board and folded by default — *"the tail stays folded, but a new task is visible where
/// it was added."* Round 8b kept the other half of b11: *"future-dated tasks are untouched."*
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
                task("Undated"),
                task("Closed", status: .done, completedDaysAgo: 0),
                task("Tomorrow", dueDaysFromNow: 1),
                task("Today", dueDaysFromNow: 0)
            ],
            asOf: now, calendar: calendar
        )

        // `F-D3`: the undated task is FIRST in the input and must still render LAST — Anytime is
        // the folded tail, below the evidence pile (round 6).
        XCTAssertEqual(
            groups.map(\.lifeAreaName),
            ["Due today · 1", "Tomorrow · 1", "Closed today · 1", "Anytime · 1"]
        )
    }

    /// The long tail is Momentum's biggest overwhelm risk (E's b11 call), and this test used to
    /// assert that BOTH halves of it were excluded outright.
    ///
    /// *Reversed by `F-D3-TasksAnytimeRow` (2026-09-24), not deleted.* Round 6: *"The Tasks board
    /// gains one collapsed 'Anytime · N' row at the bottom: the tail stays folded, but a new task
    /// is visible where it was added."* Round 8b settled the scope: *"Undated tasks already live
    /// in Anytime, and future-dated tasks are untouched."* So the point of the test is now
    /// "undated is visible, beyond-tomorrow is not" — and the second half is b11, unchanged.
    func testGroup_undatedGoesToAnytime_laterStaysExcluded() {
        let groups = MomentumTaskBuckets.group(
            tasks: [task("Undated"), task("Later", dueDaysFromNow: 3), task("Today", dueDaysFromNow: 0)],
            asOf: now, calendar: calendar
        )

        XCTAssertEqual(groups.map(\.lifeAreaName), ["Due today · 1", "Anytime · 1"])
        XCTAssertEqual(groups.last?.customId, "momentum-anytime")
        XCTAssertEqual(groups.last?.tasks.map(\.title), ["Undated"])
        XCTAssertFalse(
            groups.flatMap(\.tasks).map(\.title).contains("Later"),
            "A task due beyond tomorrow must stay off the board — round 8b: future-dated tasks are untouched"
        )
    }

    /// Anytime is the undated OPEN bucket. A closed undated task is today's evidence (or the Done
    /// filter's), never the tail — the done branch runs first and must keep doing so.
    func testGroup_closedUndatedTaskIsEvidenceNotAnytime() {
        let groups = MomentumTaskBuckets.group(
            tasks: [
                task("Closed undated today", status: .done, completedDaysAgo: 0),
                task("Closed undated long ago", status: .done, completedDaysAgo: 3)
            ],
            asOf: now, calendar: calendar
        )

        XCTAssertEqual(groups.map(\.lifeAreaName), ["Closed today · 1"])
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
                task("Closed", status: .done, completedDaysAgo: 0),
                task("Undated")
            ],
            asOf: now, calendar: calendar
        )

        // `F-D3`: four buckets now, so four distinct ids — the count pins that Anytime is present.
        XCTAssertEqual(groups.count, 4)
        XCTAssertEqual(Set(groups.map(\.id)).count, groups.count)
    }
}

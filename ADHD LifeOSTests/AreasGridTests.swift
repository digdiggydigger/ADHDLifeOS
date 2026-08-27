//
//  AreasGridTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The pure arithmetic behind the Areas tab (F-V3-Areas): per-area counts for the grid cards,
/// the unfiled-captures count, the meta line that never prints a zero, and the week-share bar
/// with its honest "Nothing in X" caption.
final class AreasGridTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        cal.locale = Locale(identifier: "en_US")
        return cal
    }

    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: 14, hour: 9, minute: 41))!
    }

    private let work = LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 0)
    private let health = LifeArea(id: UUID(), name: "Health", colour: "🫀", sortOrder: 1)

    private func doneTask(daysAgo: Int, areaId: UUID?) -> TaskItem {
        let stamp = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
        return TaskItem(
            id: UUID(), lifeAreaId: areaId, title: "Done", status: .done,
            priority: .p3, dueDate: nil, completedAt: stamp
        )
    }

    private func openTask(areaId: UUID?) -> TaskSummary {
        TaskSummary(
            id: UUID(), lifeAreaId: areaId, status: .open, title: "Open", priority: .p3,
            notes: nil, dueDate: nil, focusDurationSeconds: nil, nudgesCount: nil
        )
    }

    private func log(areaId: UUID?) -> Log {
        Log(
            id: UUID(), lifeAreaId: areaId, type: .journal, body: "entry",
            entryDate: now, createdAt: now
        )
    }

    private func capture(areaId: UUID?) -> Capture {
        var capture = Capture(id: UUID(), content: "note", kind: .note, processed: false, createdAt: now)
        capture.lifeAreaId = areaId
        return capture
    }

    func testBuild_countsTasksLogsAndCapturesPerArea() {
        let items = AreasGrid.build(
            areas: [work, health],
            openTasks: [openTask(areaId: work.id), openTask(areaId: work.id), openTask(areaId: nil)],
            allTasks: [doneTask(daysAgo: 1, areaId: work.id), doneTask(daysAgo: 20, areaId: health.id)],
            logs: [log(areaId: work.id), log(areaId: nil)],
            captures: [capture(areaId: health.id), capture(areaId: nil)],
            asOf: now,
            calendar: calendar
        )
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].momentum.closedThisWeek, 1)
        XCTAssertEqual(items[0].momentum.open, 2)
        XCTAssertEqual(items[0].logCount, 1)
        XCTAssertEqual(items[0].captureCount, 0)
        // Health's only closure is 20 days old: outside the week, but still its lastClosedAt.
        XCTAssertEqual(items[1].momentum.closedThisWeek, 0)
        XCTAssertEqual(items[1].captureCount, 1)
        XCTAssertNotNil(items[1].momentum.lastClosedAt)
    }

    func testMetaLine_omitsZeroesAndPluralises() {
        XCTAssertEqual(AreasGrid.metaLine(taskCount: 3, logCount: 1, captureCount: 0), "3 tasks · 1 log")
        XCTAssertEqual(AreasGrid.metaLine(taskCount: 1, logCount: 0, captureCount: 2), "1 task · 2 captures")
        XCTAssertEqual(AreasGrid.metaLine(taskCount: 0, logCount: 0, captureCount: 0), "Nothing here yet")
    }

    func testUnfiledCount_countsOnlyArealessUnprocessedCaptures() {
        let captures = [capture(areaId: nil), capture(areaId: work.id), capture(areaId: nil)]
        XCTAssertEqual(AreasGrid.unfiledCount(captures: captures), 2)
    }

    func testWeekShare_fractionsAndCaption() {
        let tasks = [
            doneTask(daysAgo: 0, areaId: work.id), doneTask(daysAgo: 1, areaId: work.id),
            doneTask(daysAgo: 2, areaId: health.id), doneTask(daysAgo: 20, areaId: health.id)
        ]
        let share = AreasGrid.weekShare(
            areas: [work, health], allTasks: tasks, asOf: now, calendar: calendar
        )
        XCTAssertEqual(share?.segments.map(\.count), [2, 1])
        XCTAssertEqual(share?.segments[0].fraction ?? 0, 2.0 / 3.0, accuracy: 0.001)
        XCTAssertEqual(share?.caption, "3 items closed: 2 Work, 1 Health.")
    }

    func testWeekShare_namesTheQuietAreasAndHidesWhenEmpty() {
        let tasks = [doneTask(daysAgo: 0, areaId: work.id)]
        let share = AreasGrid.weekShare(
            areas: [work, health], allTasks: tasks, asOf: now, calendar: calendar
        )
        XCTAssertEqual(share?.caption, "1 item closed: 1 Work. Nothing in Health.")

        XCTAssertNil(AreasGrid.weekShare(areas: [work, health], allTasks: [], asOf: now, calendar: calendar))
    }
}

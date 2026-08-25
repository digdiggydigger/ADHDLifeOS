//
//  JournalTimelineTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The v3 Journal timeline (F-V3-Journal): entries and closed tasks share one day-grouped
/// stream — newest day first, chronological within a day — with the filter and header line.
final class JournalTimelineTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        cal.locale = Locale(identifier: "en_US")
        return cal
    }

    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: 14, hour: 9, minute: 41))!
    }

    private func log(daysAgo: Int, hour: Int, areaId: UUID? = nil) -> Log {
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
        return Log(
            id: UUID(), lifeAreaId: areaId, type: .journal, body: "entry",
            entryDate: calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)!,
            createdAt: now
        )
    }

    private func doneTask(daysAgo: Int, hour: Int, areaId: UUID? = nil) -> TaskItem {
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
        return TaskItem(
            id: UUID(), lifeAreaId: areaId, title: "Done", status: .done,
            priority: .p3, dueDate: nil,
            completedAt: calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
        )
    }

    func testDays_groupAndOrder() {
        let days = JournalTimeline.days(
            logs: [log(daysAgo: 0, hour: 4), log(daysAgo: 1, hour: 9)],
            tasks: [doneTask(daysAgo: 0, hour: 5), doneTask(daysAgo: 1, hour: 17)],
            asOf: now, calendar: calendar
        )
        XCTAssertEqual(days.count, 2)
        XCTAssertEqual(days[0].title, "Today")
        XCTAssertEqual(days[1].title, "Yesterday")
        // Newest first WITHIN the day too (E's 2026-08-25 ordering call): the whole scroll is one
        // monotonic newest→oldest flow, so the 05:00 closure precedes the 04:00 entry.
        if case .closedTask = days[0].entries[0] {} else { XCTFail("Expected the closure first") }
        if case .log = days[0].entries[1] {} else { XCTFail("Expected the log second") }
    }

    func testFilters_splitWrittenFromClosed() {
        let logs = [log(daysAgo: 0, hour: 4)]
        let tasks = [doneTask(daysAgo: 0, hour: 5)]
        XCTAssertEqual(
            JournalTimeline.days(logs: logs, tasks: tasks, filter: .written, asOf: now, calendar: calendar)
                .flatMap(\.entries).count,
            1
        )
        XCTAssertEqual(
            JournalTimeline.days(logs: logs, tasks: tasks, filter: .closed, asOf: now, calendar: calendar)
                .flatMap(\.entries).count,
            1
        )
    }

    func testAreaFilter_appliesToBothStreams() {
        let area = UUID()
        let days = JournalTimeline.days(
            logs: [log(daysAgo: 0, hour: 4, areaId: area), log(daysAgo: 0, hour: 6)],
            tasks: [doneTask(daysAgo: 0, hour: 5, areaId: area), doneTask(daysAgo: 0, hour: 7)],
            lifeAreaId: area,
            asOf: now, calendar: calendar
        )
        XCTAssertEqual(days.flatMap(\.entries).count, 2)
    }

    func testHeaderLine_countsTheRollingWeek() {
        XCTAssertEqual(
            JournalTimeline.headerLine(
                logs: [log(daysAgo: 2, hour: 9), log(daysAgo: 20, hour: 9)],
                tasks: [doneTask(daysAgo: 0, hour: 5), doneTask(daysAgo: 30, hour: 5)],
                asOf: now, calendar: calendar
            ),
            "1 closed · 1 written this week"
        )
    }

    // MARK: - Sprints and captures in the stream (E's note, 2026-08-25)

    private func sprint(
        daysAgo: Int, hour: Int,
        focusedSeconds: Int = 1_500, plannedSeconds: Int = 1_500,
        completedNaturally: Bool = true, emoji: String = "💼"
    ) -> CompletedFocusSession {
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
        let ended = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
        return CompletedFocusSession(
            id: UUID(), taskId: nil, taskTitle: "Draft the report", lifeAreaEmoji: emoji,
            plannedSeconds: plannedSeconds, focusedSeconds: focusedSeconds,
            checkpointsReached: 0, completedNaturally: completedNaturally,
            startedAt: ended.addingTimeInterval(-Double(focusedSeconds)), endedAt: ended
        )
    }

    private func capture(daysAgo: Int, hour: Int, areaId: UUID? = nil) -> Capture {
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
        return Capture(
            id: UUID(), content: "a stray thought", kind: .note, processed: false,
            createdAt: calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)!,
            lifeAreaId: areaId
        )
    }

    func testDays_interleaveAllFourKindsNewestFirst() {
        let days = JournalTimeline.days(
            logs: [log(daysAgo: 0, hour: 4)],
            tasks: [doneTask(daysAgo: 0, hour: 7)],
            sprints: [sprint(daysAgo: 0, hour: 6)],
            captures: [capture(daysAgo: 0, hour: 5)],
            asOf: now, calendar: calendar
        )
        XCTAssertEqual(days.count, 1)
        let entries = days[0].entries
        XCTAssertEqual(entries.count, 4)
        if case .closedTask = entries[0] {} else { XCTFail("07:00 closure first") }
        if case .focusSprint = entries[1] {} else { XCTFail("06:00 sprint second") }
        if case .capture = entries[2] {} else { XCTFail("05:00 capture third") }
        if case .log = entries[3] {} else { XCTFail("04:00 log last") }
    }

    /// Sub-minute sprints are false starts — a mis-tap or an instant abandon — and E's call
    /// (2026-08-25) is that they stay out of the timeline entirely, whatever the filter.
    func testDays_hideSubMinuteSprints() {
        for filter in [JournalTimeline.Filter.everything, .sprints] {
            let entries = JournalTimeline.days(
                logs: [], tasks: [],
                sprints: [
                    sprint(daysAgo: 0, hour: 6, focusedSeconds: 45, completedNaturally: false),
                    sprint(daysAgo: 0, hour: 7, focusedSeconds: 60, completedNaturally: false)
                ],
                filter: filter, asOf: now, calendar: calendar
            ).flatMap(\.entries)
            XCTAssertEqual(entries.count, 1, "only the 60-second sprint survives under \(filter)")
        }
    }

    func testDayHeader_namesTheFocusTotalWhenSprintsExist() {
        let days = JournalTimeline.days(
            logs: [log(daysAgo: 0, hour: 4)], tasks: [],
            sprints: [
                sprint(daysAgo: 0, hour: 6, focusedSeconds: 900),
                sprint(daysAgo: 0, hour: 7, focusedSeconds: 600)
            ],
            asOf: now, calendar: calendar
        )
        XCTAssertEqual(days[0].focusedMinutes, 25)
        XCTAssertEqual(days[0].headerLine, "Today · 25 min focused")
    }

    func testDayHeader_staysBareWithoutSprints() {
        let days = JournalTimeline.days(
            logs: [log(daysAgo: 0, hour: 4)], tasks: [],
            asOf: now, calendar: calendar
        )
        XCTAssertEqual(days[0].focusedMinutes, 0)
        XCTAssertEqual(days[0].headerLine, "Today")
    }

    func testHeaderLine_countsTheWeeksSprints() {
        XCTAssertEqual(
            JournalTimeline.headerLine(
                logs: [log(daysAgo: 2, hour: 9)],
                tasks: [doneTask(daysAgo: 0, hour: 5)],
                sprints: [
                    sprint(daysAgo: 1, hour: 6),
                    sprint(daysAgo: 3, hour: 6),
                    sprint(daysAgo: 20, hour: 6),
                    sprint(daysAgo: 0, hour: 7, focusedSeconds: 30, completedNaturally: false)
                ],
                asOf: now, calendar: calendar
            ),
            "1 closed · 1 written · 2 sprints this week",
            "outside the window and sub-minute false starts both stay uncounted"
        )
    }

    func testHeaderLine_singularSprint() {
        XCTAssertEqual(
            JournalTimeline.headerLine(
                logs: [], tasks: [], sprints: [sprint(daysAgo: 0, hour: 6)],
                asOf: now, calendar: calendar
            ),
            "0 closed · 0 written · 1 sprint this week"
        )
    }

    func testFilters_sprintsAndCapturedIsolateTheirKinds() {
        let logs = [log(daysAgo: 0, hour: 4)]
        let tasks = [doneTask(daysAgo: 0, hour: 7)]
        let sprints = [sprint(daysAgo: 0, hour: 6)]
        let captures = [capture(daysAgo: 0, hour: 5)]

        let sprintEntries = JournalTimeline.days(
            logs: logs, tasks: tasks, sprints: sprints, captures: captures,
            filter: .sprints, asOf: now, calendar: calendar
        ).flatMap(\.entries)
        XCTAssertEqual(sprintEntries.count, 1)
        if case .focusSprint = sprintEntries[0] {} else { XCTFail("sprints filter leaks other kinds") }

        let capturedEntries = JournalTimeline.days(
            logs: logs, tasks: tasks, sprints: sprints, captures: captures,
            filter: .captured, asOf: now, calendar: calendar
        ).flatMap(\.entries)
        XCTAssertEqual(capturedEntries.count, 1)
        if case .capture = capturedEntries[0] {} else { XCTFail("captured filter leaks other kinds") }

        // The pre-existing filters must not pick up the new streams.
        XCTAssertEqual(
            JournalTimeline.days(
                logs: logs, tasks: tasks, sprints: sprints, captures: captures,
                filter: .written, asOf: now, calendar: calendar
            ).flatMap(\.entries).count,
            1
        )
    }

    func testAreaFilter_capturesFollowTheLifeAreaId_sprintsAreLeftToTheCaller() {
        let area = UUID()
        let entries = JournalTimeline.days(
            logs: [], tasks: [],
            sprints: [sprint(daysAgo: 0, hour: 6)],
            captures: [capture(daysAgo: 0, hour: 5, areaId: area), capture(daysAgo: 0, hour: 8)],
            lifeAreaId: area,
            asOf: now, calendar: calendar
        ).flatMap(\.entries)
        // One matching capture survives; the sprint stays because the document carries no
        // life-area id — the view pre-filters sprints by their stamped emoji instead.
        XCTAssertEqual(entries.count, 2)
    }

    func testSprintLine_naturalCompletionSaysTheMinutesPlainly() {
        XCTAssertEqual(
            JournalTimeline.sprintLine(for: sprint(daysAgo: 0, hour: 6)),
            "25 min sprint"
        )
    }

    func testSprintLine_earlyStopSaysFocusedOfPlanned() {
        XCTAssertEqual(
            JournalTimeline.sprintLine(
                for: sprint(daysAgo: 0, hour: 6, focusedSeconds: 720, completedNaturally: false)
            ),
            "12 of 25 min sprint"
        )
    }

    // The chips on a log row resolve against the one already-fetched tag list, exactly like the
    // capture rows — attach order, dangling ids dropped, nothing fetched per row.
    func testTags_resolveALogsMembershipInAttachOrder() {
        let errands = Tag(id: UUID(), name: "errands")
        let deep = Tag(id: UUID(), name: "deep-work")
        let entry = Log(
            id: UUID(), lifeAreaId: nil, type: .log, body: "x",
            entryDate: now, createdAt: now,
            tagIds: [deep.id, UUID(), errands.id]
        )

        XCTAssertEqual(JournalTimeline.tags(for: entry, from: [errands, deep]), [deep, errands])
        XCTAssertEqual(
            JournalTimeline.tags(
                for: Log(id: UUID(), lifeAreaId: nil, type: .log, body: "x", entryDate: now, createdAt: now),
                from: [errands]
            ),
            []
        )
    }

    func testSprintLine_subMinuteSprintFloorsToOneMinute() {
        XCTAssertEqual(
            JournalTimeline.sprintLine(
                for: sprint(
                    daysAgo: 0, hour: 6, focusedSeconds: 45, plannedSeconds: 45,
                    completedNaturally: true
                )
            ),
            "1 min sprint"
        )
    }
}

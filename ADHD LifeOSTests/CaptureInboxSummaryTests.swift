//
//  CaptureInboxSummaryTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The Inbox header's at-a-glance summary. An ADHD triage screen should answer "how much is
/// waiting, and what kind of thing is it?" before the user reads a single row — otherwise an
/// undifferentiated list is just another pile.
final class CaptureInboxSummaryTests: XCTestCase {
    private func capture(_ kind: CaptureKind) -> Capture {
        Capture(id: UUID(), content: "Something", kind: kind, processed: false, createdAt: Date())
    }

    // MARK: - Weekly counterweight (Concept C S1, block M10)

    /// Deterministic clock for the window tests — the shared-fixture arrangement from
    /// `MomentumScoreboardTests`.
    private var utcCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    private var fixedNow: Date {
        utcCalendar.date(from: DateComponents(year: 2026, month: 8, day: 14, hour: 9, minute: 41))!
    }

    private func weekCapture(createdDaysAgo: Int, clearedDaysAgo: Int? = nil) -> Capture {
        Capture(
            id: UUID(), content: "x", kind: .note, processed: clearedDaysAgo != nil,
            createdAt: utcCalendar.date(byAdding: .day, value: -createdDaysAgo, to: fixedNow)!,
            clearedAt: clearedDaysAgo.map { utcCalendar.date(byAdding: .day, value: -$0, to: fixedNow)! }
        )
    }

    /// "2 captured · 1 cleared this week" — the same trailing-seven-day rolling window as
    /// `MomentumScoreboard.closedThisWeek`, so Monday morning doesn't wipe the board.
    func testWeeklyCounterweight_countsTheTrailingSevenDaysIncludingToday() {
        let line = CaptureInboxSummary.weeklyCounterweight(
            for: [
                weekCapture(createdDaysAgo: 0),
                weekCapture(createdDaysAgo: 6),
                weekCapture(createdDaysAgo: 7),
                weekCapture(createdDaysAgo: 10, clearedDaysAgo: 6),
                weekCapture(createdDaysAgo: 10, clearedDaysAgo: 7)
            ],
            asOf: fixedNow, calendar: utcCalendar
        )

        XCTAssertEqual(line, "2 captured · 1 cleared this week")
    }

    /// The honest-data rule (M7's): a processed capture with no `clearedAt` predates the stamp
    /// and belongs to no particular week — it must never inflate "cleared".
    func testWeeklyCounterweight_unstampedProcessedCapturesBelongToNoWeek() {
        var unstamped = weekCapture(createdDaysAgo: 10)
        unstamped.processed = true

        let line = CaptureInboxSummary.weeklyCounterweight(
            for: [unstamped, weekCapture(createdDaysAgo: 0)],
            asOf: fixedNow, calendar: utcCalendar
        )

        XCTAssertEqual(line, "1 captured · 0 cleared this week")
    }

    /// Clearing old backlog is a win the line must be able to state: cleared can exceed captured.
    func testWeeklyCounterweight_clearingOldBacklogCanExceedCaptures() {
        let line = CaptureInboxSummary.weeklyCounterweight(
            for: [weekCapture(createdDaysAgo: 10, clearedDaysAgo: 0)],
            asOf: fixedNow, calendar: utcCalendar
        )

        XCTAssertEqual(line, "0 captured · 1 cleared this week")
    }

    /// A week with no movement drops the line entirely — "0 captured · 0 cleared" is a shrug,
    /// not information.
    func testWeeklyCounterweight_nilWhenNothingMovedThisWeek() {
        let line = CaptureInboxSummary.weeklyCounterweight(
            for: [weekCapture(createdDaysAgo: 10)],
            asOf: fixedNow, calendar: utcCalendar
        )

        XCTAssertNil(line)
    }

    // MARK: - Headline

    func testHeadline_countsWhatIsWaiting() {
        XCTAssertEqual(CaptureInboxSummary.headline(count: 3, filter: .unprocessed), "3 to triage")
    }

    func testHeadline_singularAtOne() {
        XCTAssertEqual(CaptureInboxSummary.headline(count: 1, filter: .unprocessed), "1 to triage")
    }

    func testHeadline_emptyInboxReadsAsDone_notAsZero() {
        XCTAssertEqual(
            CaptureInboxSummary.headline(count: 0, filter: .unprocessed), "Inbox clear",
            "'0 to triage' frames an empty inbox as a deficit; it is the win state"
        )
    }

    /// Found in-simulator, 2026-08-20: the Promoted tab was headed "1 to triage", which is exactly
    /// backwards — those captures are the ones already dealt with.
    func testHeadline_onThePromotedTab_describesWhatWasTriaged() {
        XCTAssertEqual(CaptureInboxSummary.headline(count: 3, filter: .promoted), "3 promoted")
        XCTAssertEqual(CaptureInboxSummary.headline(count: 1, filter: .promoted), "1 promoted")
        XCTAssertEqual(CaptureInboxSummary.headline(count: 0, filter: .promoted), "Nothing promoted yet")
    }

    func testHeadline_onTheSeenFilter_describesTheArchive() {
        XCTAssertEqual(CaptureInboxSummary.headline(count: 3, filter: .seen), "3 seen")
        XCTAssertEqual(CaptureInboxSummary.headline(count: 1, filter: .seen), "1 seen")
        XCTAssertEqual(CaptureInboxSummary.headline(count: 0, filter: .seen), "Nothing seen yet")
    }

    // MARK: - Oldest-age line (Concept C, block M5)

    /// "oldest is 18 hours old" — the inbox's honest ageing line. Hours under two days, then
    /// days; under an hour rounds to the friendliest true statement.
    func testOldestLine_readsHoursThenDays() {
        let now = Date()
        func aged(_ hours: Double) -> Capture {
            Capture(
                id: UUID(), content: "x", kind: .note, processed: false,
                createdAt: now.addingTimeInterval(-hours * 3600)
            )
        }

        XCTAssertEqual(
            CaptureInboxSummary.oldestLine(for: [aged(18), aged(3)], asOf: now),
            "oldest is 18 hours old"
        )
        XCTAssertEqual(
            CaptureInboxSummary.oldestLine(for: [aged(50)], asOf: now),
            "oldest is 2 days old"
        )
        XCTAssertEqual(
            CaptureInboxSummary.oldestLine(for: [aged(0.5)], asOf: now),
            "oldest is under an hour old"
        )
        XCTAssertEqual(CaptureInboxSummary.oldestLine(for: [aged(1)], asOf: now), "oldest is 1 hour old")
    }

    func testOldestLine_nilWhenNothingIsWaiting() {
        XCTAssertNil(CaptureInboxSummary.oldestLine(for: [], asOf: Date()))
    }

    // MARK: - Breakdown

    func testBreakdown_namesEachKindPresent() {
        let captures = [capture(.note), capture(.note), capture(.voice)]

        XCTAssertEqual(CaptureInboxSummary.breakdown(for: captures), "2 notes · 1 voice memo")
    }

    func testBreakdown_omitsKindsWithNothingWaiting() {
        let breakdown = CaptureInboxSummary.breakdown(for: [capture(.photo)])

        XCTAssertEqual(breakdown, "1 photo")
        XCTAssertFalse(breakdown.contains("note"))
    }

    func testBreakdown_usesAStableKindOrderRegardlessOfArrival() {
        let arrivalOrder = [capture(.photo), capture(.note), capture(.link), capture(.voice), capture(.task)]

        XCTAssertEqual(
            CaptureInboxSummary.breakdown(for: arrivalOrder),
            "1 note · 1 task · 1 link · 1 voice memo · 1 photo",
            "the same inbox must always read the same way, whatever order things were captured in"
        )
    }

    func testBreakdown_pluralisesEveryKind() {
        let captures = [
            capture(.note), capture(.note), capture(.task), capture(.task),
            capture(.link), capture(.link), capture(.voice), capture(.voice),
            capture(.photo), capture(.photo)
        ]

        XCTAssertEqual(
            CaptureInboxSummary.breakdown(for: captures),
            "2 notes · 2 tasks · 2 links · 2 voice memos · 2 photos"
        )
    }

    func testBreakdown_withNothingWaiting_isEmptySoTheHeaderCanHideIt() {
        XCTAssertTrue(CaptureInboxSummary.breakdown(for: []).isEmpty)
    }
}

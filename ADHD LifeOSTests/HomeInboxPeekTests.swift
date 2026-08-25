//
//  HomeInboxPeekTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Today's inbox card (E's 2026-08-25 note: "no intuitive way to see my captures") — the pure
/// presentation behind it: which captures peek, in what order, and what the lines say.
final class HomeInboxPeekTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        cal.locale = Locale(identifier: "en_US")
        return cal
    }

    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: 25, hour: 9, minute: 41))!
    }

    private func capture(minutesAgo: Int, content: String = "thought") -> Capture {
        Capture(
            id: UUID(), content: content, kind: .note, processed: false,
            createdAt: now.addingTimeInterval(TimeInterval(-minutesAgo * 60))
        )
    }

    func testPeek_newestFirstCappedAtThree() {
        let peek = HomeInboxPeek.peek([
            capture(minutesAgo: 30, content: "third"),
            capture(minutesAgo: 5, content: "first"),
            capture(minutesAgo: 90, content: "fourth"),
            capture(minutesAgo: 10, content: "second")
        ])

        XCTAssertEqual(peek.map(\.content), ["first", "second", "third"])
    }

    func testCountLine_saysWaitingOrClear() {
        XCTAssertEqual(HomeInboxPeek.countLine(0), "Inbox clear")
        XCTAssertEqual(HomeInboxPeek.countLine(1), "1 waiting")
        XCTAssertEqual(HomeInboxPeek.countLine(4), "4 waiting")
    }

    func testOverflowLine_namesOnlyWhatThePeekCannotShow() {
        XCTAssertNil(HomeInboxPeek.overflowLine(total: 3))
        XCTAssertEqual(HomeInboxPeek.overflowLine(total: 4), "and 1 more")
        XCTAssertEqual(HomeInboxPeek.overflowLine(total: 6), "and 3 more")
    }

    /// The day's throughput line (E's 2026-08-25 follow-up): silent at zero — the card celebrates
    /// what moved, it never announces that nothing did.
    func testHandledLine_namesTodaysThroughputOrStaysSilent() {
        XCTAssertNil(HomeInboxPeek.handledLine(0))
        XCTAssertEqual(HomeInboxPeek.handledLine(1), "1 handled today")
        XCTAssertEqual(HomeInboxPeek.handledLine(3), "3 handled today")
    }

    /// Same day → the clock time; older → the date. The bare time was useless on anything older
    /// than today — the same lesson `CaptureRowPresentation.caption` already learned.
    func testTimeLabel_clockTodayDateOtherwise() {
        let today = capture(minutesAgo: 30)
        let lastWeek = Capture(
            id: UUID(), content: "old", kind: .note, processed: false,
            createdAt: calendar.date(byAdding: .day, value: -6, to: now)!
        )

        XCTAssertEqual(
            HomeInboxPeek.timeLabel(for: today, asOf: now, calendar: calendar),
            today.createdAt.formatted(date: .omitted, time: .shortened)
        )
        XCTAssertEqual(
            HomeInboxPeek.timeLabel(for: lastWeek, asOf: now, calendar: calendar),
            lastWeek.createdAt.formatted(date: .abbreviated, time: .omitted)
        )
    }
}

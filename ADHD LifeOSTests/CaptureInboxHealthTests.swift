//
//  CaptureInboxHealthTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The v3 inbox's health arithmetic (F-V3-Inbox): the week's captured-per-day bars, the
/// cleared-vs-captured progress, and the sitting line that says the backlog out loud.
final class CaptureInboxHealthTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: 14, hour: 9, minute: 41))!
    }

    private func capture(daysAgo: Int, clearedDaysAgo: Int? = nil) -> Capture {
        var capture = Capture(
            id: UUID(), content: "note", kind: .note, processed: clearedDaysAgo != nil,
            createdAt: calendar.date(byAdding: .day, value: -daysAgo, to: now)!
        )
        capture.clearedAt = clearedDaysAgo.map { calendar.date(byAdding: .day, value: -$0, to: now)! }
        return capture
    }

    func testWeekHealth_countsCapturedClearedAndPerDay() {
        let captures = [
            capture(daysAgo: 0),
            capture(daysAgo: 1, clearedDaysAgo: 0),
            capture(daysAgo: 1),
            capture(daysAgo: 6, clearedDaysAgo: 5),
            capture(daysAgo: 20)
        ]
        let health = CaptureInboxSummary.weekHealth(for: captures, asOf: now, calendar: calendar)
        XCTAssertEqual(health?.captured, 4)
        XCTAssertEqual(health?.cleared, 2)
        XCTAssertEqual(health?.capturedPerDay, [1, 0, 0, 0, 0, 2, 1])
    }

    func testWeekHealth_nilWhenNothingMoved() {
        XCTAssertNil(CaptureInboxSummary.weekHealth(for: [capture(daysAgo: 30)], asOf: now, calendar: calendar))
        XCTAssertNil(CaptureInboxSummary.weekHealth(for: [], asOf: now, calendar: calendar))
    }

    func testProgressFraction_isClearedOverCaptured() {
        XCTAssertEqual(CaptureInboxSummary.progressFraction(captured: 11, cleared: 7) ?? 0, 7.0 / 11, accuracy: 0.001)
        XCTAssertEqual(CaptureInboxSummary.progressFraction(captured: 3, cleared: 5), 1)
        XCTAssertNil(CaptureInboxSummary.progressFraction(captured: 0, cleared: 0))
    }

    func testSittingLine_speaksSmallNumbersAsWords() {
        XCTAssertEqual(
            CaptureInboxSummary.sittingLine(count: 4),
            "Four are still sitting here — decide or bin them."
        )
        XCTAssertEqual(
            CaptureInboxSummary.sittingLine(count: 1),
            "One is still sitting here — decide or bin it."
        )
        XCTAssertEqual(
            CaptureInboxSummary.sittingLine(count: 12),
            "12 are still sitting here — decide or bin them."
        )
        XCTAssertNil(CaptureInboxSummary.sittingLine(count: 0))
    }
}

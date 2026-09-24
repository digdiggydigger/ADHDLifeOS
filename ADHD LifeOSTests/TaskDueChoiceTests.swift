//
//  TaskDueChoiceTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The S1-style task composer's "When is it due?" chips — pure mapping between a chip choice and
/// `TaskCreateService.dueDate`, so the view stays dumb. "Today" means start-of-day, the exact
/// convention the capture fan's fast-task path established (`QuickCaptureView.saveTask`).
final class TaskDueChoiceTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: 25, hour: 9, minute: 41))!
    }

    func testResolvedDueDate_perChoice() {
        let today = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        XCTAssertNil(TaskDueChoice.notYet.resolvedDueDate(existing: nil, asOf: now, calendar: calendar))
        XCTAssertEqual(
            TaskDueChoice.today.resolvedDueDate(existing: nil, asOf: now, calendar: calendar),
            today
        )
        XCTAssertEqual(
            TaskDueChoice.tomorrow.resolvedDueDate(existing: nil, asOf: now, calendar: calendar),
            tomorrow
        )
    }

    func testResolvedDueDate_customKeepsAnExistingDateAndSeedsNowWithoutOne() {
        let picked = calendar.date(from: DateComponents(year: 2026, month: 9, day: 2, hour: 15))!
        XCTAssertEqual(
            TaskDueChoice.custom.resolvedDueDate(existing: picked, asOf: now, calendar: calendar),
            picked,
            "switching to the picker must not clobber a date already chosen"
        )
        XCTAssertEqual(
            TaskDueChoice.custom.resolvedDueDate(existing: nil, asOf: now, calendar: calendar),
            now,
            "the picker needs a concrete date to start from"
        )
    }

    func testChoice_recognisesTheDateItProduced() {
        for choice in TaskDueChoice.allCases where choice != .custom {
            let date = choice.resolvedDueDate(existing: nil, asOf: now, calendar: calendar)
            XCTAssertEqual(
                TaskDueChoice.choice(for: date, asOf: now, calendar: calendar), choice,
                "\(choice) must round-trip"
            )
        }
    }

    func testChoice_anyOtherDateReadsAsCustom() {
        let picked = calendar.date(from: DateComponents(year: 2026, month: 9, day: 2, hour: 15))!
        XCTAssertEqual(TaskDueChoice.choice(for: picked, asOf: now, calendar: calendar), .custom)
        // A time WITHIN today that is not start-of-day is still a deliberate pick.
        XCTAssertEqual(TaskDueChoice.choice(for: now, asOf: now, calendar: calendar), .custom)
    }

    /// **REVERSED by `F-D2-ComposerKeyboardLayout`** — the fourth segment read "Pick a date" (with a
    /// calendar glyph in the round 7b boards) until E chose, in round 7b: *"Text, then the date. It
    /// reads 'Date' in LabelPrimary like its neighbours, with no calendar glyph."*
    func testTitles_areTheChipCopy() {
        XCTAssertEqual(TaskDueChoice.notYet.title, "Not yet")
        XCTAssertEqual(TaskDueChoice.today.title, "Today")
        XCTAssertEqual(TaskDueChoice.tomorrow.title, "Tomorrow")
        XCTAssertEqual(TaskDueChoice.custom.title, "Date")
    }

    // MARK: - F-D2: "Text, then the date"

    private var enGB: Locale { Locale(identifier: "en_GB") }

    /// Round 7b, E: *"Once a date is picked, Date becomes the selected segment and shows that date
    /// ('Fri 26')."* 2026-08-28 is a Friday.
    func testDateSegment_showsThePickedDayOnceItIsTheSelection() {
        let friday = calendar.date(from: DateComponents(year: 2026, month: 8, day: 28))!
        XCTAssertEqual(
            TaskDueChoice.custom.segmentTitle(
                selected: .custom, dueDate: friday, asOf: now, calendar: calendar, locale: enGB
            ),
            "Fri 28"
        )
    }

    /// Until a day is picked — and whenever another segment is the selection — it reads "Date".
    /// Today and Tomorrow ALSO hold a due date, so a label keyed on the date alone would print
    /// "Tue 25" on the Date segment while Today is lit: two segments naming one day.
    func testDateSegment_readsDateUnlessItIsTheSelection() {
        let today = calendar.startOfDay(for: now)
        let cases: [(TaskDueChoice, Date?)] = [(.notYet, nil), (.today, today), (.custom, nil)]
        for (selected, due) in cases {
            XCTAssertEqual(
                TaskDueChoice.custom.segmentTitle(
                    selected: selected, dueDate: due, asOf: now, calendar: calendar, locale: enGB
                ),
                "Date",
                "with \(selected) selected"
            )
        }
    }

    /// The other three segments are their own words whatever is selected.
    func testOtherSegments_alwaysReadTheirTitle() {
        let friday = calendar.date(from: DateComponents(year: 2026, month: 8, day: 28))!
        for choice in [TaskDueChoice.notYet, .today, .tomorrow] {
            XCTAssertEqual(
                choice.segmentTitle(selected: .custom, dueDate: friday, asOf: now, calendar: calendar, locale: enGB),
                choice.title
            )
        }
    }

    /// "Fri 26" names ONE day only while the day of the month cannot come round again: inside four
    /// weeks of today. Past that the segment says the month instead, so a date three months out
    /// never reads as this month's.
    func testDateSegment_namesTheMonthOnceTheDayNumberCouldRepeat() {
        let inFourWeeks = calendar.date(byAdding: .day, value: 27, to: calendar.startOfDay(for: now))!
        let pastFourWeeks = calendar.date(byAdding: .day, value: 28, to: calendar.startOfDay(for: now))!
        let lastWeek = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: now))!
        func label(_ date: Date) -> String {
            TaskDueChoice.custom.segmentTitle(
                selected: .custom, dueDate: date, asOf: now, calendar: calendar, locale: enGB
            )
        }
        XCTAssertEqual(label(inFourWeeks), "Mon 21", "27 days out is still inside the window")
        // `hasPrefix`, not equality: CLDR spells en_GB's September "Sep" on macOS and "Sept" on
        // some iOS runtimes, and the claim is day-then-month, not the abbreviation.
        XCTAssertTrue(label(pastFourWeeks).hasPrefix("22 Sep"), "got \(label(pastFourWeeks))")
        XCTAssertEqual(label(lastWeek), "18 Aug", "a past day is never shown as a weekday")
    }

    /// E's Step 0 answer (2026-09-24, "date only"): the composer's picker offers a DAY, so a pick is
    /// stored as that day's start — the same convention Today and Tomorrow already use. A precise
    /// time is set on the task's detail screen.
    func testPickedDueDate_isTheStartOfThePickedDay() {
        let picked = calendar.date(from: DateComponents(year: 2026, month: 9, day: 2, hour: 15, minute: 30))!
        XCTAssertEqual(
            TaskDueChoice.pickedDueDate(picked, calendar: calendar),
            calendar.date(from: DateComponents(year: 2026, month: 9, day: 2))!
        )
    }

    /// One date, one segment: picking today's or tomorrow's day in the calendar lights THAT segment,
    /// because it is the same stored value the segment itself writes.
    func testPickedDueDate_readsBackAsTodayOrTomorrowWhenItIsOne() {
        let laterToday = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now)!
        let tomorrowNoon = calendar.date(byAdding: .hour, value: 27, to: calendar.startOfDay(for: now))!
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: now)!
        func readBack(_ picked: Date) -> TaskDueChoice {
            TaskDueChoice.choice(
                for: TaskDueChoice.pickedDueDate(picked, calendar: calendar), asOf: now, calendar: calendar
            )
        }
        XCTAssertEqual(readBack(laterToday), .today)
        XCTAssertEqual(readBack(tomorrowNoon), .tomorrow)
        XCTAssertEqual(readBack(nextWeek), .custom)
    }
}

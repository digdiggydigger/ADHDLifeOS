//
//  HomeNudgesDoorTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Today's nudges module as a DOOR rather than a footer (E's screenshot note, 2026-08-28: "make
/// it stand out more and more prominent to the user's eye").
///
/// The quiet state — nothing due, some scheduled — was a grey caps eyebrow over a grey chevron
/// row, sitting between a bold ring and a loud blue CTA, and it read as the end of the screen
/// rather than a section of it. E chose the Capture inbox card's anatomy for it: icon tile, title,
/// subtitle, count chip, and the next few nudges listed underneath with when they fire.
///
/// That last part is the reason this file exists. "4 scheduled" says a number; "Water the plants,
/// tomorrow 09:00" says something you can act on, and it is the only version worth the extra
/// height.
final class HomeNudgesDoorTests: XCTestCase {
    /// Fixed so "today"/"tomorrow" are decidable: Friday 28 August 2026, 05:18 local — the moment
    /// on E's screenshot.
    private let now = Date(timeIntervalSince1970: 1_787_890_680)
    private let zone = TimeZone(identifier: "Europe/London")!
    private let locale = Locale(identifier: "en_GB")

    private func nudge(
        _ label: String,
        schedule: String,
        active: Bool = true,
        lastFiredAt: Date? = nil,
        createdAt: Date? = nil
    ) -> Nudge {
        let created = createdAt ?? Date(timeIntervalSince1970: 1_785_571_200) // 1 Aug 2026
        return Nudge(
            id: UUID(), label: label, schedule: schedule, active: active,
            lastFiredAt: lastFiredAt, createdAt: created, updatedAt: created
        )
    }

    // MARK: - The header the card leads with

    /// Nothing due is the state a schedule is FOR, so it reads as settled — never as a count of
    /// nothing, the rule "Inbox clear" already follows.
    func testDoorSubtitle_nothingDueButSomeScheduled() {
        XCTAssertEqual(
            HomeNudgesSection.doorSubtitle(dueCount: 0, scheduledCount: 4),
            "Nothing due — all on time."
        )
    }

    func testDoorSubtitle_somethingDue() {
        XCTAssertEqual(
            HomeNudgesSection.doorSubtitle(dueCount: 2, scheduledCount: 3),
            "Waiting on you — clear them when you can."
        )
    }

    func testDoorSubtitle_noNudgesAtAll() {
        XCTAssertEqual(
            HomeNudgesSection.doorSubtitle(dueCount: 0, scheduledCount: 0),
            "Recurring reminders you set for yourself."
        )
    }

    /// The chip counts the thing that MATTERS in each state: what is waiting on you if anything
    /// is, otherwise how many are simply on the books.
    func testChipText_prefersDueOverScheduled() {
        XCTAssertEqual(HomeNudgesSection.chipText(dueCount: 2, scheduledCount: 3), "2 due")
        XCTAssertEqual(HomeNudgesSection.chipText(dueCount: 1, scheduledCount: 0), "1 due")
    }

    func testChipText_fallsBackToScheduled() {
        XCTAssertEqual(HomeNudgesSection.chipText(dueCount: 0, scheduledCount: 4), "4 scheduled")
        XCTAssertEqual(HomeNudgesSection.chipText(dueCount: 0, scheduledCount: 1), "1 scheduled")
    }

    func testChipText_nothingAtAll() {
        XCTAssertEqual(HomeNudgesSection.chipText(dueCount: 0, scheduledCount: 0), "None yet")
    }

    // MARK: - When the next one fires

    /// Later the same day reads as a time alone — the day is implied by "today" being now.
    func testNextFireLine_laterToday() {
        let evening = nudge("Water the plants", schedule: "0 18 * * 0,1,2,3,4,5,6")
        XCTAssertEqual(
            HomeNudgesSection.nextFireLine(for: evening, now: now, timeZone: zone, locale: locale),
            "Today 18:00"
        )
    }

    /// Already past today, so the daily schedule rolls to tomorrow.
    func testNextFireLine_rollsToTomorrowOncePastTodaysTime() {
        let earlyMorning = nudge(
            "Take meds", schedule: "0 5 * * 0,1,2,3,4,5,6",
            lastFiredAt: Date(timeIntervalSince1970: 1_787_890_200) // 05:10 today, just fired
        )
        XCTAssertEqual(
            HomeNudgesSection.nextFireLine(for: earlyMorning, now: now, timeZone: zone, locale: locale),
            "Tomorrow 05:00"
        )
    }

    /// Further out than tomorrow, the weekday is named — "in 4 days" makes you do arithmetic.
    func testNextFireLine_namesTheWeekdayBeyondTomorrow() {
        let mondayOnly = nudge("Weekly review", schedule: "30 9 * * 1")
        XCTAssertEqual(
            HomeNudgesSection.nextFireLine(for: mondayOnly, now: now, timeZone: zone, locale: locale),
            "Mon 09:30"
        )
    }

    /// A schedule the app cannot parse gets NO line rather than an invented one — the same rule
    /// `NudgeSchedule.summary` already follows.
    func testNextFireLine_unparseableScheduleSaysNothing() {
        let broken = nudge("Mystery", schedule: "*/5 * * * *")
        XCTAssertNil(
            HomeNudgesSection.nextFireLine(for: broken, now: now, timeZone: zone, locale: locale)
        )
    }

    /// A paused nudge is not waiting for you, so it has no next fire to report.
    func testNextFireLine_inactiveNudgeSaysNothing() {
        let paused = nudge("Paused", schedule: "0 18 * * 0,1,2,3,4,5,6", active: false)
        XCTAssertNil(
            HomeNudgesSection.nextFireLine(for: paused, now: now, timeZone: zone, locale: locale)
        )
    }

    // MARK: - Which upcoming ones get a row

    /// Soonest first: the row you most need is the one about to happen, not the one added first.
    func testUpcoming_soonestFirst() {
        let evening = nudge("Water the plants", schedule: "0 18 * * 0,1,2,3,4,5,6")
        let monday = nudge("Weekly review", schedule: "30 9 * * 1")
        let noon = nudge("Stand up", schedule: "0 12 * * 0,1,2,3,4,5,6")

        let ordered = HomeNudgesSection.upcoming(
            all: [monday, evening, noon], due: [], now: now, timeZone: zone
        )

        XCTAssertEqual(ordered.map(\.label), ["Stand up", "Water the plants", "Weekly review"])
    }

    /// Today is the densest screen in the app, so the rows are capped and the rest are named —
    /// the same bargain `HomeInboxPeek` and the due cards already make.
    func testUpcoming_isCappedAtTheSectionMaximum() {
        let many = (0..<6).map { nudge("N\($0)", schedule: "0 \(10 + $0) * * 0,1,2,3,4,5,6") }

        let shown = HomeNudgesSection.upcoming(all: many, due: [], now: now, timeZone: zone)

        XCTAssertEqual(shown.count, HomeNudgesSection.maxCards)
    }

    /// A due nudge already has its own card above; listing it again under "next up" would be the
    /// same nudge twice on one screen.
    func testUpcoming_excludesWhatIsAlreadyDue() {
        let due = nudge("Take meds", schedule: "0 5 * * 0,1,2,3,4,5,6")
        let later = nudge("Water the plants", schedule: "0 18 * * 0,1,2,3,4,5,6")

        let shown = HomeNudgesSection.upcoming(
            all: [due, later], due: [due], now: now, timeZone: zone
        )

        XCTAssertEqual(shown.map(\.label), ["Water the plants"])
    }

    /// Paused nudges are not upcoming; they are not waiting at all.
    func testUpcoming_excludesInactive() {
        let paused = nudge("Paused", schedule: "0 6 * * 0,1,2,3,4,5,6", active: false)
        let live = nudge("Water the plants", schedule: "0 18 * * 0,1,2,3,4,5,6")

        let shown = HomeNudgesSection.upcoming(
            all: [paused, live], due: [], now: now, timeZone: zone
        )

        XCTAssertEqual(shown.map(\.label), ["Water the plants"])
    }

    /// An unparseable schedule has no position in a soonest-first list, so it cannot claim a row.
    func testUpcoming_excludesWhatCannotBeScheduled() {
        let broken = nudge("Mystery", schedule: "*/5 * * * *")
        let live = nudge("Water the plants", schedule: "0 18 * * 0,1,2,3,4,5,6")

        let shown = HomeNudgesSection.upcoming(
            all: [broken, live], due: [], now: now, timeZone: zone
        )

        XCTAssertEqual(shown.map(\.label), ["Water the plants"])
    }

    func testUpcomingOverflowLine_namesOnlyWhatTheRowsCannotShow() {
        XCTAssertNil(HomeNudgesSection.upcomingOverflowLine(scheduledCount: 3))
        XCTAssertEqual(HomeNudgesSection.upcomingOverflowLine(scheduledCount: 4), "and 1 more scheduled")
        XCTAssertEqual(HomeNudgesSection.upcomingOverflowLine(scheduledCount: 6), "and 3 more scheduled")
    }

    // MARK: - Whether Today shows the section at all (F-FirstNudgeReachable)

    /// Content always shows. This is the uncontroversial case and the one that already worked.
    func testShouldRender_withNudges_isTrue() {
        XCTAssertTrue(HomeNudgesSection.shouldRenderSection(hasAny: true, hasEverHadAny: false))
        XCTAssertTrue(HomeNudgesSection.shouldRenderSection(hasAny: true, hasEverHadAny: true))
    }

    /// The bug this predicate exists for. A brand-new account has no nudges and has never had
    /// one, and the door is the ONLY route to the Nudges screen — so hiding it here left the
    /// feature unreachable by anything the user could do.
    func testShouldRender_emptyAndNeverHadAny_isTrue_soAFirstNudgeCanBeMade() {
        XCTAssertTrue(HomeNudgesSection.shouldRenderSection(hasAny: false, hasEverHadAny: false))
    }

    /// And the original decision is preserved rather than reversed: once you have had a nudge,
    /// an empty schedule goes back to being silent. "An empty schedule is not news" was right
    /// about a status card; it was only wrong about the feature's sole entrance.
    func testShouldRender_emptyButHasHadSome_isFalse_theOriginalSilence() {
        XCTAssertFalse(HomeNudgesSection.shouldRenderSection(hasAny: false, hasEverHadAny: true))
    }
}

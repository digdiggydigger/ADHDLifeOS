//
//  HomeNudgesSectionTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Today's nudges module, the pure half. Nudges lost their tab when Captures took the slot back
/// (E, 2026-08-28), so a due nudge is now met AND dismissed on Today — which means Today has to
/// decide how many it can hold and how to say what it is not showing.
final class HomeNudgesSectionTests: XCTestCase {
    private func nudge(label: String, lastFiredAt: Date?, active: Bool = true) -> Nudge {
        Nudge(
            id: UUID(),
            label: label,
            schedule: "0 9 * * 0,1,2,3,4,5,6",
            active: active,
            lastFiredAt: lastFiredAt,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }

    // MARK: - Which nudges get a card

    func testCards_capsAtThree_soTodayStaysAGlance() {
        let due = (1...5).map { nudge(label: "Nudge \($0)", lastFiredAt: Date(timeIntervalSince1970: Double($0))) }

        XCTAssertEqual(HomeNudgesSection.cards(due).count, HomeNudgesSection.maxCards)
        XCTAssertEqual(HomeNudgesSection.maxCards, 3)
    }

    /// Oldest-due first: the nudge that has waited longest is the one you meet, not whichever the
    /// server happened to return first. Measured from the same reference moment `NudgeDueness`
    /// uses, so "waited longest" means the same thing in both places.
    func testCards_showTheLongestWaitingFirst() {
        let recent = nudge(label: "Recent", lastFiredAt: Date(timeIntervalSince1970: 3_000))
        let ancient = nudge(label: "Ancient", lastFiredAt: Date(timeIntervalSince1970: 1_000))
        let middling = nudge(label: "Middling", lastFiredAt: Date(timeIntervalSince1970: 2_000))

        XCTAssertEqual(
            HomeNudgesSection.cards([recent, ancient, middling]).map(\.label),
            ["Ancient", "Middling", "Recent"]
        )
    }

    /// A nudge that has never fired falls back to `createdAt` — the same fallback dueness uses.
    func testCards_aNeverFiredNudgeSortsByItsCreationDate() {
        let neverFired = nudge(label: "Never fired", lastFiredAt: nil)
        let firedLater = nudge(label: "Fired later", lastFiredAt: Date(timeIntervalSince1970: 1_800_000_000))

        XCTAssertEqual(
            HomeNudgesSection.cards([firedLater, neverFired]).map(\.label),
            ["Never fired", "Fired later"]
        )
    }

    // MARK: - What the section says about what it is not showing

    func testOverflowLine_namesOnlyTheHiddenOnes() {
        XCTAssertNil(HomeNudgesSection.overflowLine(dueCount: 3))
        XCTAssertEqual(HomeNudgesSection.overflowLine(dueCount: 4), "and 1 more due")
        XCTAssertEqual(HomeNudgesSection.overflowLine(dueCount: 7), "and 4 more due")
    }

    func testOverflowLine_silentWhenEverythingDueIsOnScreen() {
        XCTAssertNil(HomeNudgesSection.overflowLine(dueCount: 0))
        XCTAssertNil(HomeNudgesSection.overflowLine(dueCount: 1))
    }

    // MARK: - The eyebrow

    func testCountLine_namesBothHalvesWhenSomethingIsDue() {
        XCTAssertEqual(
            HomeNudgesSection.countLine(dueCount: 2, scheduledCount: 5), "2 due · 5 scheduled"
        )
    }

    /// Nothing due is the state a nudge schedule EXISTS to produce, so it reads as settled rather
    /// than as "0 due" — the same rule the inbox's "Inbox clear" follows.
    func testCountLine_nothingDueIsNotRenderedAsAZero() {
        XCTAssertEqual(
            HomeNudgesSection.countLine(dueCount: 0, scheduledCount: 4), "Nothing due · 4 scheduled"
        )
        XCTAssertEqual(HomeNudgesSection.countLine(dueCount: 0, scheduledCount: 0), "No nudges yet")
    }

    // MARK: - Scheduled count

    func testScheduledCount_countsActiveNudgesThatAreNotDue() {
        let due = nudge(label: "Due", lastFiredAt: nil)
        let waiting = nudge(label: "Waiting", lastFiredAt: nil)

        XCTAssertEqual(HomeNudgesSection.scheduledCount(all: [due, waiting], due: [due]), 1)
    }

    /// A paused nudge is not waiting for you, so it is not "scheduled".
    func testScheduledCount_excludesInactiveNudges() {
        let due = nudge(label: "Due", lastFiredAt: nil)
        let paused = nudge(label: "Paused", lastFiredAt: nil, active: false)

        XCTAssertEqual(HomeNudgesSection.scheduledCount(all: [due, paused], due: [due]), 0)
    }
}

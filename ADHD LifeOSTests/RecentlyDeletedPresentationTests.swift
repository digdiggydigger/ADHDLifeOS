//
//  RecentlyDeletedPresentationTests.swift
//  ADHD LifeOSTests
//
//  `F-C3-RecentlyDeleted`: the screen's words and its countdown, as pure values.
//
//  Kept out of the view body for the reason every presentation type here is — view bodies are
//  ~0% covered by design, so a rule left inside one is a rule nothing checks. `ToolsRoutinesCatalog`
//  is the house pattern this follows, including its rule about interpolating a constant rather
//  than spelling it: copy reading "30 days" beside a `retention` of 14 is a lie no compiler catches.
//

import XCTest
@testable import ADHD_LifeOS

final class RecentlyDeletedPresentationTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let day: TimeInterval = 24 * 60 * 60

    private func item(
        _ title: String, kind: RecentlyDeletedItem.Kind = .task, deletedDaysAgo: Double
    ) -> RecentlyDeletedItem {
        RecentlyDeletedItem(
            itemId: UUID(), kind: kind, title: title,
            deletedAt: now.addingTimeInterval(-deletedDaysAgo * day)
        )
    }

    // MARK: - The countdown, and its agreement with the purge

    func testTheRetentionWindowIsReadFromSoftDeleteRatherThanSpelledOut() {
        XCTAssertEqual(
            RecentlyDeletedPresentation.retentionDays, Int(SoftDelete.retention / (24 * 60 * 60)),
            "The screen's window is a second spelling of `SoftDelete.retention`, so retuning the"
                + " constant would leave the copy lying about how long the user has."
        )
    }

    func testAFreshDeleteHasTheWholeWindowLeft() {
        XCTAssertEqual(
            RecentlyDeletedPresentation.daysRemaining(deletedAt: now, now: now),
            RecentlyDeletedPresentation.retentionDays
        )
    }

    /// Part of a day left still reads as a whole day — rounding UP, because rounding down would
    /// tell someone with eleven hours that they have none.
    func testAPartDayRemainingRoundsUpRatherThanDown() {
        let almostGone = now.addingTimeInterval(-(SoftDelete.retention - 0.5 * day))
        XCTAssertEqual(
            RecentlyDeletedPresentation.daysRemaining(deletedAt: almostGone, now: now), 1
        )
    }

    /// **The invariant that matters, and the two readings that could drift apart.**
    /// `SoftDelete.isPurgeable` uses `>`, so an item at exactly the retention boundary is KEPT.
    /// A countdown computed independently could show `0` for an item the purge keeps (fine — it
    /// is its last day) but must never show a POSITIVE number for one the purge would take. That
    /// direction is the promise: time shown is time the user actually has.
    func testNoItemThePurgeWouldTakeIsEverShownTimeRemaining() {
        for elapsedDays in stride(from: 0.0, through: 40.0, by: 0.25) {
            let deletedAt = now.addingTimeInterval(-elapsedDays * day)
            let remaining = RecentlyDeletedPresentation.daysRemaining(deletedAt: deletedAt, now: now)
            if remaining > 0 {
                XCTAssertFalse(
                    SoftDelete.isPurgeable(deletedAt: deletedAt, asOf: now),
                    "At \(elapsedDays) days the screen promises \(remaining) more, and the next"
                        + " launch would purge it."
                )
            }
        }
    }

    /// The boundary itself, pinned rather than left to the sweep: exactly the retention window is
    /// NOT purgeable, and the screen says so in words rather than showing a bare zero.
    func testTheExactBoundaryIsTheLastDayAndIsNotPurged() {
        let exactly = now.addingTimeInterval(-SoftDelete.retention)
        XCTAssertFalse(SoftDelete.isPurgeable(deletedAt: exactly, asOf: now))
        XCTAssertEqual(RecentlyDeletedPresentation.daysRemaining(deletedAt: exactly, now: now), 0)
        XCTAssertEqual(RecentlyDeletedPresentation.remainingPhrase(daysRemaining: 0), "Last day")
    }

    /// A stamp from a device with a fast clock is still a delete (`SoftDelete`'s own rule), and it
    /// reads as MORE time rather than as an error — the honest thing to show, since the purge will
    /// also wait.
    func testAFutureStampReadsAsMoreTimeNotAsAnError() {
        let fromTheFuture = now.addingTimeInterval(2 * day)
        let remaining = RecentlyDeletedPresentation.daysRemaining(deletedAt: fromTheFuture, now: now)
        XCTAssertGreaterThan(remaining, RecentlyDeletedPresentation.retentionDays)
        XCTAssertFalse(SoftDelete.isPurgeable(deletedAt: fromTheFuture, asOf: now))
    }

    func testTheRemainingPhraseNeverSaysOneDays() {
        XCTAssertEqual(RecentlyDeletedPresentation.remainingPhrase(daysRemaining: 1), "1 day left")
        XCTAssertEqual(RecentlyDeletedPresentation.remainingPhrase(daysRemaining: 9), "9 days left")
    }

    // MARK: - The list

    /// Newest DELETED first, not newest created. `fetchDeletedTasks()` orders by `created_at`
    /// because that is the index the collection already has; the order a person expects here is
    /// the order they did the deleting, and the item about to expire has to be findable.
    func testRowsAreOrderedByWhenTheyWereDeletedNewestFirst() {
        let content = RecentlyDeletedPresentation.content(
            from: [
                item("Older", deletedDaysAgo: 9),
                item("Newest", deletedDaysAgo: 1),
                item("Middle", kind: .capture, deletedDaysAgo: 4)
            ],
            now: now
        )

        guard case .rows(let rows) = content else { return XCTFail("expected rows") }
        XCTAssertEqual(rows.map(\.title), ["Newest", "Middle", "Older"])
    }

    /// Tasks and captures share one list, so the row has to say which it is — restoring the wrong
    /// one is a real mistake and the titles alone will not always tell them apart.
    func testARowNamesItsKindAndItsRemainingTime() {
        let content = RecentlyDeletedPresentation.content(
            from: [item("Ring the dentist", deletedDaysAgo: 3)], now: now
        )

        guard case .rows(let rows) = content, let row = rows.first else { return XCTFail("expected a row") }
        XCTAssertEqual(row.title, "Ring the dentist")
        XCTAssertEqual(row.subtitle, "Task · 27 days left")
        XCTAssertEqual(row.glyph, "checklist", "a task's row wears the glyph its own tab wears")
    }

    func testACapturesRowWearsTheCapturesGlyphAndWord() {
        let content = RecentlyDeletedPresentation.content(
            from: [item("Idle thought", kind: .capture, deletedDaysAgo: 0)], now: now
        )

        guard case .rows(let rows) = content, let row = rows.first else { return XCTFail("expected a row") }
        XCTAssertEqual(row.subtitle, "Capture · 30 days left")
        XCTAssertEqual(row.glyph, "tray.full")
    }

    /// Per-ROW and never on a container — an identifier on a container is inherited by its
    /// children and renames the Restore button out from under itself, the trap
    /// `ToolsRoutinesCatalog` records.
    func testEachRowCarriesItsOwnIdentifier() {
        let one = item("A", deletedDaysAgo: 1)
        let two = item("B", kind: .capture, deletedDaysAgo: 2)
        let content = RecentlyDeletedPresentation.content(from: [one, two], now: now)

        guard case .rows(let rows) = content else { return XCTFail("expected rows") }
        XCTAssertEqual(Set(rows.map(\.accessibilityIdentifier)).count, 2)
        XCTAssertTrue(rows[0].accessibilityIdentifier.hasPrefix("recentlyDeletedRow-"))
    }

    /// A task and a capture that happened to share an id are two rows, not one. Firestore ids are
    /// per-collection, so nothing prevents it, and a `ForEach` over a colliding id drops one
    /// silently.
    func testARowsIdentityIncludesItsCollection() {
        let shared = UUID()
        let content = RecentlyDeletedPresentation.content(
            from: [
                RecentlyDeletedItem(itemId: shared, kind: .task, title: "T", deletedAt: now),
                RecentlyDeletedItem(itemId: shared, kind: .capture, title: "C", deletedAt: now)
            ],
            now: now
        )

        guard case .rows(let rows) = content else { return XCTFail("expected rows") }
        XCTAssertEqual(Set(rows.map(\.id)).count, 2)
    }

    func testAnEmptyListIsItsOwnStateRatherThanNoRows() {
        XCTAssertEqual(RecentlyDeletedPresentation.content(from: [], now: now), .empty)
    }

    // MARK: - The words

    /// Every sentence that names the window interpolates it, so they go wrong together or not at
    /// all. There were three until E dropped the two delete confirmations; the sentence that used
    /// to teach the window at the moment of the delete went with them, and these two are now the
    /// only places it is said.
    func testEverySentenceThatNamesTheWindowInterpolatesIt() {
        let window = "\(RecentlyDeletedPresentation.retentionDays)"
        for copy in [
            RecentlyDeletedPresentation.sectionCaption,
            RecentlyDeletedPresentation.emptyBody
        ] {
            XCTAssertTrue(copy.contains(window), "\"\(copy)\" does not name the real window.")
        }
    }

    /// **The sentence that MOVES (§2.7).** "This can't be undone" was under task detail's Delete
    /// button, where soft delete made it false. It belongs here, where it is true — and Q10's
    /// sanctioned friction is exactly this. The other half of the fix is
    /// `testNeitherUndoableDeleteAsksForConfirmationAnyMore`: the false sentence's own dialog is
    /// gone, so no soft delete claims to be permanent anywhere.
    func testThisCantBeUndoneNowBelongsToDeleteForeverWhereItIsTrue() {
        XCTAssertEqual(RecentlyDeletedPresentation.DeleteForever.message, "This can't be undone.")
        for copy in [
            RecentlyDeletedPresentation.sectionCaption,
            RecentlyDeletedPresentation.emptyBody,
            RecentlyDeletedPresentation.toolsRowLoadingSubtitle
        ] {
            XCTAssertFalse(
                copy.contains("can't be undone"),
                "\"\(copy)\" claims a soft delete is permanent."
            )
        }
    }

    func testTheDeleteForeverConfirmNamesWhichKindOfThingItIsAbout() {
        XCTAssertEqual(
            RecentlyDeletedPresentation.DeleteForever.title(for: .task), "Delete this task forever?"
        )
        XCTAssertEqual(
            RecentlyDeletedPresentation.DeleteForever.title(for: .capture),
            "Delete this capture forever?"
        )
    }

    // MARK: - The Tools row

    /// The row on Tools is one line and has to earn a tap, so it carries the one number that
    /// changes what the user would do: how long the SOONEST departure has.
    func testTheToolsRowNamesTheCountAndTheSoonestDeparture() {
        let subtitle = RecentlyDeletedPresentation.toolsRowSubtitle(
            for: [item("A", deletedDaysAgo: 29.6), item("B", deletedDaysAgo: 1)], now: now
        )
        XCTAssertEqual(subtitle, "2 items · 1 day left")
    }

    func testTheToolsRowNeverSaysOneItems() {
        XCTAssertEqual(
            RecentlyDeletedPresentation.toolsRowSubtitle(for: [item("A", deletedDaysAgo: 0)], now: now),
            "1 item · 30 days left"
        )
    }

    /// Shown rather than hidden when empty, the `ToolsRoutinesSection` rule: a row that vanishes
    /// can never teach what fills it, and a brand-new account is in exactly this state.
    func testTheToolsRowSaysSoWhenNothingIsWaiting() {
        XCTAssertEqual(
            RecentlyDeletedPresentation.toolsRowSubtitle(for: [], now: now), "Nothing waiting"
        )
    }
}

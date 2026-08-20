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

    // MARK: - Headline

    func testHeadline_countsWhatIsWaiting() {
        XCTAssertEqual(CaptureInboxSummary.headline(count: 3), "3 to triage")
    }

    func testHeadline_singularAtOne() {
        XCTAssertEqual(CaptureInboxSummary.headline(count: 1), "1 to triage")
    }

    func testHeadline_emptyInboxReadsAsDone_notAsZero() {
        XCTAssertEqual(
            CaptureInboxSummary.headline(count: 0), "Inbox clear",
            "'0 to triage' frames an empty inbox as a deficit; it is the win state"
        )
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

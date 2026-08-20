//
//  CaptureRowDetailTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The detail a collapsed Inbox row shows beneath its title — the half of the web original's card
/// (`src/components/CaptureInboxView.tsx`) the native row was missing.
///
/// The web row tells you what a capture IS without opening it: the note or transcript in a quoted
/// block, and a "Captured 17:04 • voice note" caption. Ours showed a title and "Note · 2 minutes
/// ago" (E, 2026-08-20: "not up to the same level").
final class CaptureRowDetailTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func capture(
        content: String = "The retro idea about standups",
        kind: CaptureKind = .voice,
        title: String? = "Standup thought",
        createdAt: Date? = nil
    ) -> Capture {
        Capture(
            id: UUID(), content: content, kind: kind, processed: false,
            createdAt: createdAt ?? now, title: title
        )
    }

    // MARK: - Secondary text

    func testSecondaryText_isTheCapturesOwnWordsBeneathItsTitle() {
        let text = CaptureRowPresentation.secondaryText(for: capture())

        XCTAssertEqual(text, "The retro idea about standups")
    }

    /// The row must never quote back the line it is already showing as the headline. `primaryText`
    /// falls through to `content` when there is no title, and without this guard an untitled note
    /// rendered the same sentence twice.
    func testSecondaryText_isNilWhenTheContentIsAlreadyTheTitleLine() {
        let untitled = capture(content: "Ring the dentist", kind: .note, title: nil)

        XCTAssertEqual(CaptureRowPresentation.primaryText(for: untitled), "Ring the dentist")
        XCTAssertNil(CaptureRowPresentation.secondaryText(for: untitled))
    }

    func testSecondaryText_isNilWhenThereIsNothingToQuote() {
        XCTAssertNil(CaptureRowPresentation.secondaryText(for: capture(content: "   ")))
        XCTAssertNil(CaptureRowPresentation.secondaryText(for: capture(content: "")))
    }

    func testSecondaryText_isTrimmed() {
        XCTAssertEqual(
            CaptureRowPresentation.secondaryText(for: capture(content: "  spaced out \n")),
            "spaced out"
        )
    }

    /// A link capture's headline comes from its preview title, so its own content (the URL, or a
    /// note about it) is still worth showing underneath.
    func testSecondaryText_survivesALinkWhoseTitleCameFromItsPreview() {
        var link = capture(content: "Read this before Thursday", kind: .link, title: nil)
        link.linkPreview = CaptureLinkPreview(
            url: "https://example.com", title: "An article", description: nil, thumbnailURL: nil
        )

        XCTAssertEqual(CaptureRowPresentation.primaryText(for: link), "An article")
        XCTAssertEqual(CaptureRowPresentation.secondaryText(for: link), "Read this before Thursday")
    }

    // MARK: - Caption

    func testCaption_readsCapturedThenTheTimeThenTheKind() {
        // The web's "Captured 14:32 • voice note", which says WHEN the thought was dumped —
        // the thing you actually want when scanning a backlog.
        let caption = CaptureRowPresentation.caption(for: capture(createdAt: now), now: now)

        XCTAssertTrue(caption.hasPrefix("Captured "), caption)
        XCTAssertTrue(caption.contains("voice note"), caption)
    }

    /// The web prints a bare clock time, which is useless on anything older than today. A capture
    /// from last week says which day it was.
    func testCaption_forAnOlderCapture_namesTheDayNotJustTheClock() {
        let today = CaptureRowPresentation.caption(for: capture(createdAt: now), now: now)
        let lastWeek = CaptureRowPresentation.caption(
            for: capture(createdAt: now.addingTimeInterval(-7 * 24 * 60 * 60)), now: now
        )

        XCTAssertNotEqual(today, lastWeek)
        XCTAssertGreaterThan(
            lastWeek.count, today.count,
            "the older caption carries a date the today one doesn't need: \(lastWeek) vs \(today)"
        )
    }

    func testCaption_hasTheSameShapeForEveryKind() {
        let captions = CaptureKind.allCases.map { kind in
            CaptureRowPresentation.caption(for: capture(kind: kind, createdAt: now), now: now)
        }

        XCTAssertTrue(captions.allSatisfy { $0.hasPrefix("Captured ") }, "\(captions)")
        XCTAssertEqual(Set(captions).count, CaptureKind.allCases.count, "each kind names itself")
    }

    func testCaption_namesTheKindInLowerCaseProse() {
        // "Captured 14:32 · voice note" reads as a sentence; "Voice note" mid-line does not.
        XCTAssertTrue(
            CaptureRowPresentation.caption(for: capture(kind: .photo, createdAt: now), now: now)
                .contains("photo note"),
            CaptureRowPresentation.caption(for: capture(kind: .photo, createdAt: now), now: now)
        )
    }
}

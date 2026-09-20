//
//  ComposerDraftFilingTests.swift
//  ADHD LifeOSTests
//
//  `F-C2-DraftsToInbox`, the drafts half. E, round 2: *"Unsent text → 'Inbox catches it'. A
//  composer closed with text files it into the Capture Inbox as a note."* Q4: *"never block with a
//  modal and never lose user input."*
//
//  **One rule, three composers.** The Quick Capture, task and journal composers each close in their
//  own way; if each decided for itself what counts as "text worth keeping", they would drift. The
//  rule is here, pure, and the three call it.
//

import XCTest
@testable import ADHD_LifeOS

final class ComposerDraftFilingTests: XCTestCase {

    // MARK: - What counts as text worth keeping

    func testTypedTextIsKept() {
        XCTAssertTrue(ComposerDraftFiling.shouldFile("Book the dentist before Friday"))
    }

    /// **An untouched composer must file NOTHING**, or every opened-and-closed composer litters the
    /// inbox with empty notes — which would make the inbox useless and the feature a nuisance
    /// rather than a safety net.
    func testAnUntouchedComposerFilesNothing() {
        XCTAssertFalse(ComposerDraftFiling.shouldFile(""))
    }

    /// Whitespace is not text. A stray space or a newline from the keyboard is an untouched
    /// composer as far as the user is concerned, and `CaptureValidation` would reject it anyway —
    /// better to decide here than to send a doomed write and swallow its error.
    func testWhitespaceAloneIsNotTextWorthKeeping() {
        for text in [" ", "\n", "\t", "   \n  \t "] {
            XCTAssertFalse(
                ComposerDraftFiling.shouldFile(text),
                "\(text.debugDescription) was filed — an untouched composer would litter the inbox."
            )
        }
    }

    // MARK: - What the capsule says it kept

    /// The capsule names what it kept, and its subject line is one line — so the subject is the
    /// draft's FIRST line rather than its first 40 characters, which would cut mid-sentence.
    func testTheSubjectIsTheDraftsFirstLine() {
        XCTAssertEqual(
            ComposerDraftFiling.subject(for: "Book the dentist\nand the optician"),
            "Book the dentist"
        )
    }

    /// Leading blank lines are skipped rather than yielding an empty subject — a journal entry that
    /// begins with a return would otherwise name itself "".
    func testLeadingBlankLinesAreSkipped() {
        XCTAssertEqual(ComposerDraftFiling.subject(for: "\n\n  Ask Sam about the key"), "Ask Sam about the key")
    }

    /// **A long draft is truncated, and VoiceOver is the reason.** The capsule draws one line and
    /// truncates visually on its own, but `accessibilityAnnouncement` SPEAKS the subject whole —
    /// and a journal entry is the one composer whose text runs to paragraphs. Without this, filing
    /// one would read the whole paragraph aloud as an interruption.
    func testALongDraftIsCutShortSoTheAnnouncementStaysAnAnnouncement() {
        let long = String(repeating: "a", count: 200)
        let subject = ComposerDraftFiling.subject(for: long)

        XCTAssertEqual(subject.count, ComposerDraftFiling.subjectLimit)
        XCTAssertTrue(subject.hasSuffix("…"), "A cut subject must say it was cut.")
    }

    /// A draft at exactly the limit is not cut, and gains no ellipsis promising more that is not
    /// there. The off-by-one that would show "…" on a complete sentence.
    func testADraftExactlyAtTheLimitIsLeftWhole() {
        let exact = String(repeating: "b", count: ComposerDraftFiling.subjectLimit)

        XCTAssertEqual(ComposerDraftFiling.subject(for: exact), exact)
        XCTAssertFalse(ComposerDraftFiling.subject(for: exact).hasSuffix("…"))
    }

    /// Trailing whitespace on the kept line goes; the user did not type it deliberately.
    func testTheSubjectIsTrimmed() {
        XCTAssertEqual(ComposerDraftFiling.subject(for: "  Renew the passport   \n"), "Renew the passport")
    }
}

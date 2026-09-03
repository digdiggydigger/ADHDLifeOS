//
//  CaptureSearchRefinementTests.swift
//  ADHD LifeOSTests
//
//  Search over the capture inbox (F-Search-2-Captures).
//
//  **The load-bearing test here is the photo capture.** A capture may have no title AND no
//  content — a photo dropped in with nothing typed is the ordinary case — and this repo has
//  already shipped a bug of exactly that shape once: the inbox triage card hand-rolled its own
//  title logic instead of calling `CaptureRowPresentation.primaryText`, and photo captures
//  rendered as a BLANK card (fixed in `eddef9b`). A search that filtered on `title` and `content`
//  would repeat it in a quieter form: the capture would still be visible, but unfindable, and
//  nothing would look broken.
//
//  So matching goes through the same presentation rule the ROW uses. The contract is "you can
//  find what you can see", which is a claim about `primaryText` and `secondaryText`, not about
//  the model's fields.
//

import XCTest
@testable import ADHD_LifeOS

final class CaptureSearchRefinementTests: XCTestCase {

    // MARK: - Fixtures

    private func capture(
        kind: CaptureKind = .note,
        title: String? = nil,
        content: String = "",
        linkTitle: String? = nil
    ) -> Capture {
        Capture(
            id: UUID(),
            content: content,
            kind: kind,
            processed: false,
            createdAt: Date(timeIntervalSince1970: 1_755_000_000),
            title: title,
            lifeAreaId: nil,
            mediaURL: nil,
            mediaContentType: nil,
            thumbnailURL: nil,
            linkPreview: linkTitle.map {
                CaptureLinkPreview(
                    url: "https://example.com/x", title: $0, description: nil, thumbnailURL: nil
                )
            },
            aiAssessment: nil
        )
    }

    // MARK: - The empty query

    func testAnEmptyQueryReturnsEverything() {
        let all = [capture(title: "Dentist"), capture(content: "Call the landlord")]

        XCTAssertEqual(CaptureSearchRefinement.apply(captures: all, searchText: ""), all)
    }

    func testAWhitespaceOnlyQueryReturnsEverything() {
        let all = [capture(title: "Dentist")]

        XCTAssertEqual(CaptureSearchRefinement.apply(captures: all, searchText: "   \n "), all)
    }

    // MARK: - What it matches

    func testMatchesTheTitle() {
        let hit = capture(title: "Book the dentist")
        let miss = capture(title: "Call the landlord")

        XCTAssertEqual(
            CaptureSearchRefinement.apply(captures: [hit, miss], searchText: "dentist"), [hit]
        )
    }

    /// With a title present the content becomes the row's SECONDARY line. It must still be
    /// searchable — the words a person actually typed are usually there, not in the title.
    func testMatchesTheContentBeneathATitle() {
        let hit = capture(title: "Errand", content: "pick up the prescription")
        let miss = capture(title: "Errand", content: "post the parcel")

        XCTAssertEqual(
            CaptureSearchRefinement.apply(captures: [hit, miss], searchText: "prescription"), [hit]
        )
    }

    func testMatchesContentWhenThereIsNoTitle() {
        let hit = capture(content: "remember the bin day")

        XCTAssertEqual(
            CaptureSearchRefinement.apply(captures: [hit], searchText: "bin day"), [hit]
        )
    }

    /// A link with no title of its own shows its preview's title, so that is what search has to
    /// match — `primaryText` already resolves it and this proves search inherited that.
    func testMatchesALinksPreviewTitleWhenTheCaptureHasNone() {
        let hit = capture(kind: .link, content: "https://example.com/x", linkTitle: "Roasting chickpeas")

        XCTAssertEqual(
            CaptureSearchRefinement.apply(captures: [hit], searchText: "chickpeas"), [hit]
        )
    }

    // MARK: - The capture with nothing in it

    /// **The test this file exists for.** No title, no content — the row displays "Photo capture",
    /// so that is the only string a person could possibly search for, and it must work. Filtering
    /// on the model's fields would leave this capture visible in the list and impossible to find.
    func testAPhotoCaptureWithNoWordsIsFoundByWhatTheRowShows() {
        let photo = capture(kind: .photo)
        XCTAssertEqual(
            CaptureRowPresentation.primaryText(for: photo), "Photo capture",
            "The fixture is wrong, not the search: this capture should be falling through to the"
                + " photo placeholder."
        )

        XCTAssertEqual(
            CaptureSearchRefinement.apply(captures: [photo], searchText: "photo"), [photo],
            "A photo capture with no title and no content cannot be found by anything. It is"
                + " visible in the inbox and unreachable by search — the quiet form of the blank"
                + " card this repo shipped in `eddef9b`."
        )
    }

    func testAnEmptyNonPhotoCaptureIsFoundByItsPlaceholderToo() {
        let empty = capture(kind: .note)
        XCTAssertEqual(CaptureRowPresentation.primaryText(for: empty), "Untitled capture")

        XCTAssertEqual(
            CaptureSearchRefinement.apply(captures: [empty], searchText: "untitled"), [empty]
        )
    }

    // MARK: - Agreeing with the tasks filter

    func testCaseInsensitiveLikeTheTasksFilter() {
        let hit = capture(title: "Dentist")

        XCTAssertEqual(CaptureSearchRefinement.apply(captures: [hit], searchText: "DENTIST"), [hit])
        XCTAssertEqual(CaptureSearchRefinement.apply(captures: [hit], searchText: "dEnTiSt"), [hit])
    }

    /// **Deliberately NOT diacritic-insensitive**, because `TaskListRefinement` is not. Two search
    /// fields in one app that disagree about whether "cafe" finds "café" is worse than either
    /// answer on its own. If E wants folding, both change together — this test is what makes that
    /// a single decision rather than a drift.
    func testDiacriticsBehaveExactlyAsTheyDoForTasks() {
        let capturesResult = CaptureSearchRefinement.apply(
            captures: [capture(title: "Café run")], searchText: "cafe"
        )
        let tasksResult = TaskListRefinement.apply(
            tasks: [
                TaskItem(
                    id: UUID(), lifeAreaId: nil, title: "Café run",
                    status: .open, priority: .p3, dueDate: nil
                )
            ],
            searchText: "cafe"
        )

        XCTAssertEqual(
            capturesResult.isEmpty, tasksResult.isEmpty,
            "Captures and Tasks now disagree about whether an unaccented query matches an"
                + " accented word. One app, one answer."
        )
    }

    func testOrderIsPreserved() {
        let first = capture(title: "Alpha task")
        let second = capture(title: "Beta task")
        let third = capture(title: "Gamma task")

        XCTAssertEqual(
            CaptureSearchRefinement.apply(
                captures: [first, second, third], searchText: "task"
            ),
            [first, second, third],
            "Search re-ordered the inbox. It filters; the list's own order is not its business."
        )
    }

    func testNoMatchesReturnsEmptyRatherThanEverything() {
        let all = [capture(title: "Dentist"), capture(title: "Landlord")]

        XCTAssertTrue(
            CaptureSearchRefinement.apply(captures: all, searchText: "zzz").isEmpty,
            "A query matching nothing fell back to returning the whole list, which reads as"
                + " search being broken rather than as an empty result."
        )
    }
}

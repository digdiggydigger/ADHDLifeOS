//
//  CaptureListRefinementTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The sort and kind-filter controls E asked for on the Capture Inbox and the Captures tab
/// (2026-08-24): pure list refinement over an already-fetched slice, so both screens share one
/// rule and the service's loaded state stays the untouched truth.
final class CaptureListRefinementTests: XCTestCase {
    private func capture(_ content: String, kind: CaptureKind = .note, minutesAgo: Double) -> Capture {
        Capture(
            id: UUID(), content: content, kind: kind, processed: false,
            createdAt: Date().addingTimeInterval(-minutesAgo * 60)
        )
    }

    func testApply_newestFirstIsTheDefaultOrder() {
        let refined = CaptureListRefinement.apply(
            captures: [capture("old", minutesAgo: 60), capture("new", minutesAgo: 1)],
            newestFirst: true, kind: nil
        )

        XCTAssertEqual(refined.map(\.content), ["new", "old"])
    }

    func testApply_oldestFirstFlipsTheOrder() {
        let refined = CaptureListRefinement.apply(
            captures: [capture("new", minutesAgo: 1), capture("old", minutesAgo: 60)],
            newestFirst: false, kind: nil
        )

        XCTAssertEqual(refined.map(\.content), ["old", "new"])
    }

    func testApply_kindFilterKeepsOnlyThatKind() {
        let refined = CaptureListRefinement.apply(
            captures: [
                capture("a note", minutesAgo: 1),
                capture("a link", kind: .link, minutesAgo: 2),
                capture("a photo", kind: .photo, minutesAgo: 3)
            ],
            newestFirst: true, kind: .link
        )

        XCTAssertEqual(refined.map(\.content), ["a link"])
    }

    func testApply_filterAndSortCompose() {
        let refined = CaptureListRefinement.apply(
            captures: [
                capture("new note", minutesAgo: 1),
                capture("old note", minutesAgo: 90),
                capture("a link", kind: .link, minutesAgo: 5)
            ],
            newestFirst: false, kind: .note
        )

        XCTAssertEqual(refined.map(\.content), ["old note", "new note"])
    }
}

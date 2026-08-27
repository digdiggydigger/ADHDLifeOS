//
//  AreaDetailPresentationTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The pure presentation behind the v3 area screen (F-V3-AreaDetail): the content-filter chips
/// with their counts, the momentum ring's line, and the captures genuinely filed to this area.
final class AreaDetailPresentationTests: XCTestCase {
    private let areaId = UUID()

    private func capture(areaId: UUID?) -> Capture {
        var capture = Capture(id: UUID(), content: "note", kind: .note, processed: false, createdAt: .now)
        capture.lifeAreaId = areaId
        return capture
    }

    func testFilterTitles_carryTheirCounts() {
        XCTAssertEqual(AreaDetailFilter.tasks.title(count: 3), "Tasks 3")
        XCTAssertEqual(AreaDetailFilter.journal.title(count: 1), "Journal 1")
        XCTAssertEqual(AreaDetailFilter.captures.title(count: 0), "Captures 0")
        XCTAssertEqual(AreaDetailFilter.all.title(count: 9), "All")
    }

    func testRingLine_statesTheWeeklyRate() {
        XCTAssertEqual(
            AreaDetailPresentation.ringLine(rate: 0.67, areaName: "Work & Career"),
            "67% of this week's Work & Career items closed"
        )
        XCTAssertEqual(
            AreaDetailPresentation.ringLine(rate: 1, areaName: "Health"),
            "All of this week's Health items closed"
        )
        XCTAssertEqual(
            AreaDetailPresentation.ringLine(rate: nil, areaName: "Hobbies"),
            "Nothing here has moved this week"
        )
    }

    func testCapturesFiledHere_keepsOnlyThisAreasCaptures() {
        let filed = capture(areaId: areaId)
        let elsewhere = capture(areaId: UUID())

        XCTAssertEqual(
            AreaDetailPresentation.capturesFiledHere([filed, elsewhere], areaId: areaId), [filed]
        )
    }

    /// The bug this replaced: the screen also listed every capture with NO area, matched on
    /// `lifeAreaId == nil` — a predicate that never mentions the area on screen. One unfiled
    /// capture therefore rendered on EVERY area's detail at once, each with its own "File here".
    /// An area shows what is filed here; the inbox owns what is filed nowhere.
    func testCapturesFiledHere_neverShowsAnUnfiledCapture() {
        let unfiled = capture(areaId: nil)

        XCTAssertTrue(
            AreaDetailPresentation.capturesFiledHere([unfiled], areaId: areaId).isEmpty,
            "an area-less capture belongs to the inbox, not to all eight areas simultaneously"
        )
    }
}

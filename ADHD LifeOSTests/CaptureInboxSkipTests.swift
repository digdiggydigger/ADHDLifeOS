//
//  CaptureInboxSkipTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The service half of SUGG-b9, in its own file so `CaptureInboxServiceTests` stays inside the
/// 250-line type-body budget.
@MainActor
final class CaptureInboxSkipTests: XCTestCase {

    /// SUGG-b9: Skip is a service-level rotation — the view hands the top capture back and the
    /// next one surfaces. It must survive a refresh: the skip list keys on ids, and the refetch
    /// replaces the array but not the list.
    func testSkip_sendsTheTopToTheBack_andSurvivesRefresh() async {
        let fake = FakeCaptureClientAdapting()
        let first = Capture(id: UUID(), content: "first", kind: .note, processed: false, createdAt: Date())
        let second = Capture(id: UUID(), content: "second", kind: .note, processed: false, createdAt: Date())
        fake.fetchUnprocessedCapturesResult = .success([first, second])
        let sut = CaptureInboxService(client: fake)
        await sut.load()

        sut.skip(first)
        XCTAssertEqual(sut.displayedCaptures, [second, first])

        await sut.refresh()
        XCTAssertEqual(
            sut.displayedCaptures, [second, first],
            "a signal-driven refetch must not undo the skip"
        )
    }
}

//
//  SoftDeleteTests.swift
//  ADHD LifeOSTests
//
//  `F-C3-RecentlyDeleted`: the two questions a soft delete asks, both pure.
//
//  **Why this is a type and not two `if`s at the read sites.** The spec's own warning is that
//  `whereField("deleted_at", isEqualTo: NSNull())` matches only documents where the field is
//  explicitly present and null — so every task and capture written before this block would be
//  excluded from every list by a server-side filter. The answer is to keep fetching as today and
//  decide live-ness in the client, which means the decision is made in a dozen places and must
//  therefore be one function.
//

import XCTest
@testable import ADHD_LifeOS

final class SoftDeleteTests: XCTestCase {

    // MARK: - isLive

    /// The case that matters most and is easiest to get wrong: every document written before this
    /// block has no `deleted_at` key at all, so it decodes as `nil` — and `nil` MUST mean live.
    func testADocumentWithNoStampIsLive() {
        XCTAssertTrue(SoftDelete.isLive(deletedAt: nil))
    }

    func testADocumentWithAStampIsNotLive() {
        XCTAssertFalse(SoftDelete.isLive(deletedAt: Date(timeIntervalSince1970: 0)))
    }

    /// A stamp in the FUTURE is still a delete. A second device with a fast clock can write one,
    /// and "deleted, but not yet" is not a state this app has — the user tapped delete.
    func testAFutureStampIsStillNotLive() {
        XCTAssertFalse(SoftDelete.isLive(deletedAt: Date().addingTimeInterval(86_400)))
    }

    // MARK: - isPurgeable

    /// E's Step 0 answer 1: the purge runs in the app on launch, clearing anything older than 30
    /// days. The boundary is asserted from both sides because "older than" is exactly the kind of
    /// comparison that ships as `>=` by accident and purges a day early.
    func testAnItemDeletedJustUnderThirtyDaysAgoIsNotPurgeable() {
        let now = Date(timeIntervalSince1970: 1_000_000_000)
        let deletedAt = now.addingTimeInterval(-(SoftDelete.retention - 60))
        XCTAssertFalse(SoftDelete.isPurgeable(deletedAt: deletedAt, asOf: now))
    }

    func testAnItemDeletedJustOverThirtyDaysAgoIsPurgeable() {
        let now = Date(timeIntervalSince1970: 1_000_000_000)
        let deletedAt = now.addingTimeInterval(-(SoftDelete.retention + 60))
        XCTAssertTrue(SoftDelete.isPurgeable(deletedAt: deletedAt, asOf: now))
    }

    /// A live item is never purgeable, whatever the clock says. The purge iterates documents it
    /// fetched as deleted, but it is the only irreversible operation in the block, so it does not
    /// get to assume its caller filtered correctly.
    func testALiveItemIsNeverPurgeable() {
        XCTAssertFalse(SoftDelete.isPurgeable(deletedAt: nil, asOf: Date()))
    }

    func testTheRetentionWindowIsThirtyDays() {
        XCTAssertEqual(SoftDelete.retention, 30 * 24 * 60 * 60)
    }

    /// The two functions must never both answer "yes" for one stamp: an item cannot be live and
    /// purgeable at once. Swept rather than spot-checked, because this is the invariant that
    /// keeps a reordered guard from deleting something a list is still showing.
    func testNothingIsEverBothLiveAndPurgeable() {
        let now = Date(timeIntervalSince1970: 1_000_000_000)
        let offsets: [TimeInterval] = [
            -SoftDelete.retention * 2, -SoftDelete.retention, -60, 0, 60, SoftDelete.retention
        ]
        for offset in offsets {
            let stamp = now.addingTimeInterval(offset)
            XCTAssertFalse(
                SoftDelete.isLive(deletedAt: stamp) && SoftDelete.isPurgeable(deletedAt: stamp, asOf: now),
                "A stamp at \(offset)s was reported both live and purgeable"
            )
        }
    }
}

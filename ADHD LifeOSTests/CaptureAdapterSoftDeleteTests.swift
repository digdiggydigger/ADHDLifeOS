//
//  CaptureAdapterSoftDeleteTests.swift
//  ADHD LifeOSTests
//
//  `F-C3-RecentlyDeleted`: the capture adapter's soft-delete pair, in its own file because the
//  parent had reached SwiftLint's 250-line type-body ceiling. A LOCATION split, nothing else —
//  `FirebaseCaptureClientAdapterTests`' header applies verbatim.
//

import XCTest
@testable import ADHD_LifeOS

/// Discarding a capture stamps `deletedAt` and the document survives thirty days; its hard twin
/// is gone from `CaptureClientAdapting` entirely, which is what the always-empty
/// `deletedCaptureIds` witness asserts.
final class CaptureAdapterSoftDeleteTests: XCTestCase {
    private var store: FakeCaptureBackingStore!
    private var adapter: FirebaseCaptureClientAdapter!

    override func setUp() {
        super.setUp()
        store = FakeCaptureBackingStore()
        adapter = FirebaseCaptureClientAdapter(store: store)
    }

    override func tearDown() {
        adapter = nil
        store = nil
        super.tearDown()
    }

    /// **Reversed by `F-C3-RecentlyDeleted`**: discarding a capture stamps `deletedAt` and the
    /// document survives thirty days. Its hard twin is gone from this seam entirely.
    func testSoftDeleteCapture_forwardsTheIdAndStampsIt() async throws {
        let id = UUID()
        let before = Date()

        try await adapter.softDeleteCapture(id: id)

        XCTAssertEqual(store.softDeletedCaptureIds, [id])
        XCTAssertEqual(store.deletedCaptureIds, [], "the adapter reached the HARD delete")
        let stamp = try XCTUnwrap(store.softDeleteCaptureStamps.first)
        XCTAssertGreaterThanOrEqual(stamp, before)
        XCTAssertLessThanOrEqual(stamp, Date())
    }

    func testRestoreCapture_forwardsTheId() async throws {
        let id = UUID()

        try await adapter.restoreCapture(id: id)

        XCTAssertEqual(store.restoredCaptureIds, [id])
    }
}

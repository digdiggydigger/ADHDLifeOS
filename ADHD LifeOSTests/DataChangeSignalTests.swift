//
//  DataChangeSignalTests.swift
//  ADHD LifeOSTests
//

import Combine
import XCTest
@testable import ADHD_LifeOS

/// BUG-b7 / BUG-b1 / SUGG-b4 (E's checklist, 2026-08-26): screens went stale because nothing told
/// them user data changed — a task added on one surface, an area recoloured in Settings, a capture
/// taken through the global fan. Every successful Firestore write now posts this signal, and each
/// screen refetches through ONE shared debounced publisher, so a burst of writes (create + attach
/// tags) lands as a single reload rather than one per write.
final class DataChangeSignalTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func testPost_reachesASubscriber() {
        let delivered = expectation(description: "signal delivered")
        DataChangeSignal.debouncedPublisher(interval: .milliseconds(50))
            .sink { delivered.fulfill() }
            .store(in: &cancellables)
        DataChangeSignal.post()
        wait(for: [delivered], timeout: 2)
    }

    func testBurstOfPosts_coalescesIntoOneDelivery() {
        let delivered = expectation(description: "exactly one delivery")
        delivered.expectedFulfillmentCount = 1
        delivered.assertForOverFulfill = true
        DataChangeSignal.debouncedPublisher(interval: .milliseconds(100))
            .sink { delivered.fulfill() }
            .store(in: &cancellables)
        for _ in 0..<5 { DataChangeSignal.post() }
        wait(for: [delivered], timeout: 2)
        // Hold the window open past a second debounce interval: over-fulfilment inside it would
        // mean the burst was NOT coalesced, and assertForOverFulfill turns that into a failure.
        let settle = expectation(description: "quiet tail")
        settle.isInverted = true
        wait(for: [settle], timeout: 0.3)
    }
}

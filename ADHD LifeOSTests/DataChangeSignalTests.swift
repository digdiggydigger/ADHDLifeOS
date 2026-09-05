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

    /// The round-2 field-walk defect (2026-09-04), reduced to its mechanism.
    ///
    /// `debouncedPublisher` was a FACTORY, so every SwiftUI body evaluation built a brand-new
    /// debounce chain and `onReceive` resubscribed to it. A body evaluation inside the 600ms
    /// window — switching tabs is one — tore the pending chain down before it could fire, and
    /// the change was lost. On device that showed as Today keeping a stale routine card after a
    /// departure crossing, while an ARRIVAL refreshed fine: the arrival's journal auto-step
    /// writes to Firestore and posts a SECOND signal after the tab switch has settled, which
    /// masked the fault.
    ///
    /// Subscribing AFTER the post is exactly what a resubscribing view does. The debounce has to
    /// live in a permanently-retained pipeline, not in the subscriber's own chain, for the value
    /// to survive that.
    func testASubscriberJoiningDuringTheWindowStillReceivesTheChange() {
        let delivered = expectation(description: "change survived a resubscribe")

        DataChangeSignal.post()

        // Inside the debounce window, and deliberately not on the first run-loop turn — a body
        // evaluation lands somewhere arbitrary within it.
        DataChangeSignal.changes
            .sink { delivered.fulfill() }
            .store(in: &cancellables)

        wait(for: [delivered], timeout: 3)
    }

    /// The same stream every time, so a resubscribe rejoins rather than restarts. A factory
    /// cannot satisfy this, which is what made the defect possible.
    func testTheSharedStreamSurvivesASubscriberCancelling() {
        var firstBag = Set<AnyCancellable>()
        DataChangeSignal.changes.sink { _ in }.store(in: &firstBag)
        firstBag.removeAll()                       // the "old" view goes away

        let delivered = expectation(description: "stream still live for the next subscriber")
        DataChangeSignal.changes
            .sink { delivered.fulfill() }
            .store(in: &cancellables)
        DataChangeSignal.post()
        wait(for: [delivered], timeout: 3)
    }
}

//
//  CaptureDiscPanObserverTests.swift
//  ADHD LifeOSTests
//

import UIKit
import XCTest
@testable import ADHD_LifeOS

/// F-DiscPill's window-level pan observer, tested at its `react(to:)` seam — the recognizer and
/// the key window cannot exist in a unit test, but the mapping from recognizer state to the
/// activity model is where a wrong case would silently strand the disc as a pill (or never
/// shrink it at all).
@MainActor
final class CaptureDiscPanObserverTests: XCTestCase {

    private final class Counter {
        var began = 0
        var ended = 0
    }

    private func makeObserver(_ counter: Counter) -> CaptureDiscPanObserver {
        CaptureDiscPanObserver(
            onDragBegan: { counter.began += 1 },
            onDragEnded: { counter.ended += 1 }
        )
    }

    func testBeganFiresTheShrinkOnly() {
        let counter = Counter()
        makeObserver(counter).react(to: .began)
        XCTAssertEqual(counter.began, 1)
        XCTAssertEqual(counter.ended, 0)
    }

    func testChangedFiresNothing() {
        // .changed streams continuously during a drag; forwarding it would cancel-and-reschedule
        // work on every frame for no state change.
        let counter = Counter()
        makeObserver(counter).react(to: .changed)
        XCTAssertEqual(counter.began, 0)
        XCTAssertEqual(counter.ended, 0)
    }

    func testEveryTerminalStateFiresTheRestore() {
        // .cancelled (an incoming call, a system gesture) and .failed must restore too, or the
        // disc would be stranded as a pill with no touch left to end it.
        for state: UIGestureRecognizer.State in [.ended, .cancelled, .failed] {
            let counter = Counter()
            makeObserver(counter).react(to: state)
            XCTAssertEqual(counter.began, 0, "state \(state.rawValue) must not shrink")
            XCTAssertEqual(counter.ended, 1, "state \(state.rawValue) must restore")
        }
    }

    func testPossibleFiresNothing() {
        let counter = Counter()
        makeObserver(counter).react(to: .possible)
        XCTAssertEqual(counter.began, 0)
        XCTAssertEqual(counter.ended, 0)
    }

    func testObserverNeverBlocksOtherRecognizers() {
        // The KeyboardTapAway contract: this recognizer listens ALONGSIDE scrolls, swipes and
        // buttons. Refusing simultaneous recognition would make the scroll detector break
        // scrolling itself.
        let observer = makeObserver(Counter())
        XCTAssertTrue(
            observer.gestureRecognizer(
                UIPanGestureRecognizer(),
                shouldRecognizeSimultaneouslyWith: UITapGestureRecognizer()
            )
        )
    }
}

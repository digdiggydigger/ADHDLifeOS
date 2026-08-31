//
//  CaptureDiscPanObserverTests.swift
//  ADHD LifeOSTests
//

import UIKit
import XCTest
@testable import ADHD_LifeOS

/// F-PillStay's window-level pan observer, tested at its `react(to:translationY:)` seam — the
/// recognizer and the key window cannot exist in a unit test, but the mapping from recognizer
/// state to the activity model is where a wrong case would strand the disc or deafen the pill.
///
/// The terminal states (`.ended/.cancelled/.failed`) are deliberately SILENT now: that silence
/// is the stickiness E asked for ("stay in pill form until the page is scrolled upwards").
@MainActor
final class CaptureDiscPanObserverTests: XCTestCase {

    private final class Recorder {
        var began = 0
        var moves: [CGFloat] = []
    }

    private func makeObserver(_ recorder: Recorder) -> CaptureDiscPanObserver {
        CaptureDiscPanObserver(
            onDragBegan: { recorder.began += 1 },
            onDragMoved: { recorder.moves.append($0) }
        )
    }

    func testBeganResetsTheAnchorOnly() {
        let recorder = Recorder()
        makeObserver(recorder).react(to: .began, translationY: 0)
        XCTAssertEqual(recorder.began, 1)
        XCTAssertEqual(recorder.moves, [])
    }

    func testChangedForwardsTheTranslation() {
        let recorder = Recorder()
        let observer = makeObserver(recorder)
        observer.react(to: .changed, translationY: -40)
        observer.react(to: .changed, translationY: 25)
        XCTAssertEqual(recorder.began, 0)
        XCTAssertEqual(recorder.moves, [-40, 25])
    }

    func testTerminalStatesAreSilent() {
        // No restore on lift, cancel, or failure — the pill's persistence through the end of
        // the gesture IS the feature. A forwarded terminal event here would quietly reinvent
        // the settle-timer behaviour this block removed.
        for state: UIGestureRecognizer.State in [.ended, .cancelled, .failed, .possible] {
            let recorder = Recorder()
            makeObserver(recorder).react(to: state, translationY: -99)
            XCTAssertEqual(recorder.began, 0, "state \(state.rawValue) must not begin")
            XCTAssertEqual(recorder.moves, [], "state \(state.rawValue) must not move")
        }
    }

    func testObserverNeverBlocksOtherRecognizers() {
        // The KeyboardTapAway contract: this recognizer listens ALONGSIDE scrolls, swipes and
        // buttons. Refusing simultaneous recognition would make the scroll detector break
        // scrolling itself.
        let observer = makeObserver(Recorder())
        XCTAssertTrue(
            observer.gestureRecognizer(
                UIPanGestureRecognizer(),
                shouldRecognizeSimultaneouslyWith: UITapGestureRecognizer()
            )
        )
    }
}

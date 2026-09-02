//
//  TabBarScrollActivityTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The tab bar's MOMENTARY scroll signal (F-Tools-2-Morph).
///
/// It is a second model on purpose. `CaptureDiscScrollActivity` is directional and **sticky by
/// construction** — E's 2026-08-31 verdict was "stay in pill form until the page is scrolled
/// upwards again", and nothing in it runs on a timer — so it cannot express "only while the page
/// is actually moving". Editing it would break a behaviour E has already settled.
///
/// **The problem this type exists to solve is momentum.** A `UIPanGestureRecognizer` tracks the
/// FINGER, not the page, and `CaptureDiscPanObserver` deliberately does not forward `.ended`. So
/// after the lift the page keeps gliding while nothing reports movement at all, and a naive
/// signal would snap the bar back to its resting shape mid-glide — precisely the wrong moment.
/// The answer is a settle timer restarted on every movement, which carries the bar through the
/// lift and most of the deceleration.
@MainActor
final class TabBarScrollActivityTests: XCTestCase {

    /// Captures the work the model schedules instead of running it, so a 300ms interval costs
    /// nothing and "did it restart?" is answerable rather than a race.
    private final class TestScheduler {
        private(set) var scheduled: [(delay: TimeInterval, work: () -> Void)] = []

        func schedule(after delay: TimeInterval, _ work: @escaping () -> Void) {
            scheduled.append((delay, work))
        }

        func fire(_ index: Int) {
            scheduled[index].work()
        }

        var count: Int { scheduled.count }
    }

    private func makeActivity() -> (TabBarScrollActivity, TestScheduler) {
        let scheduler = TestScheduler()
        let activity = TabBarScrollActivity(scheduleSettle: scheduler.schedule)
        return (activity, scheduler)
    }

    func testStartsStill() {
        let (activity, _) = makeActivity()
        XCTAssertFalse(activity.isMoving)
    }

    func testMovementMarksTheBarMoving() {
        let (activity, _) = makeActivity()
        activity.dragMoved()
        XCTAssertTrue(activity.isMoving)
    }

    func testSettlingAfterTheIntervalReturnsToStill() {
        let (activity, scheduler) = makeActivity()
        activity.dragMoved()
        XCTAssertEqual(scheduler.count, 1)
        scheduler.fire(0)
        XCTAssertFalse(activity.isMoving)
    }

    /// **The momentum guard.** A second movement inside the interval must RESTART the countdown,
    /// not let the first one fire — otherwise the bar snaps back mid-scroll.
    func testMovementInsideTheIntervalRestartsItRatherThanFiringEarly() {
        let (activity, scheduler) = makeActivity()
        activity.dragMoved()
        activity.dragMoved()
        XCTAssertEqual(scheduler.count, 2, "Each movement schedules its own settle")

        scheduler.fire(0)
        XCTAssertTrue(
            activity.isMoving,
            "The FIRST settle fired after a second movement and stopped the bar early"
        )
        scheduler.fire(1)
        XCTAssertFalse(activity.isMoving, "The latest settle should be the one that lands")
    }

    /// Ten movements in a row, then only the last settle fires — the shape of a real scroll,
    /// which delivers `.changed` continuously.
    func testAStreamOfMovementsOnlySettlesOnTheLast() {
        let (activity, scheduler) = makeActivity()
        for _ in 1...10 { activity.dragMoved() }
        for index in 0..<9 {
            scheduler.fire(index)
            XCTAssertTrue(activity.isMoving, "Stale settle \(index) stopped the bar")
        }
        scheduler.fire(9)
        XCTAssertFalse(activity.isMoving)
    }

    /// RootView calls this on a tab change, for the same reason the disc's model has one: a bar
    /// left mid-morph on a screen the user never scrolled reads as a bug.
    func testResetReturnsToStillImmediately() {
        let (activity, _) = makeActivity()
        activity.dragMoved()
        activity.reset()
        XCTAssertFalse(activity.isMoving)
    }

    /// A settle scheduled before a reset must not resurrect anything when it lands.
    func testASettleLandingAfterAResetChangesNothing() {
        let (activity, scheduler) = makeActivity()
        activity.dragMoved()
        activity.reset()
        scheduler.fire(0)
        XCTAssertFalse(activity.isMoving)
    }

    /// Movement after a reset still works — reset is a restore, not a teardown.
    func testMovementAfterAResetStillMarksMoving() {
        let (activity, _) = makeActivity()
        activity.dragMoved()
        activity.reset()
        activity.dragMoved()
        XCTAssertTrue(activity.isMoving)
    }

    /// The interval is a named, tunable constant — E has not seen it on device yet, so it will
    /// almost certainly move. It must not be a literal at the scheduling site.
    func testTheSettleIntervalIsTheNamedConstant() {
        let (activity, scheduler) = makeActivity()
        activity.dragMoved()
        XCTAssertEqual(scheduler.scheduled[0].delay, TabBarScrollActivity.settleInterval)
    }

    /// The band the spec allows. Retune inside it freely; outside it, the bar either flickers on
    /// every pause or hangs in its scrolled shape long after the page has stopped.
    func testTheSettleIntervalStaysInTheBandTheDesignAllows() {
        XCTAssertGreaterThanOrEqual(TabBarScrollActivity.settleInterval, 0.25)
        XCTAssertLessThanOrEqual(TabBarScrollActivity.settleInterval, 0.35)
    }
}

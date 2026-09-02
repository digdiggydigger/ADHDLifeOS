//
//  TabBarScrollActivityTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The tab bar's floating-state rule (F-Tools-2-Morph, revised on E's device verdict).
///
/// **It is a POSITION rule, not a motion rule.** The first cut was momentary — B only while the
/// page was actually moving — and E's verdict after using it was: *"much rather if the bar
/// contracts into the floating card while the page is moving in a downwards direction, but also
/// stays as the floating card until the screen view is manually scrolled upwards past a certain
/// point"*. Asked what "a certain point" meant, E chose **near the top of the page**.
///
/// Reading the scroll POSITION rather than the gesture makes the whole momentum problem vanish:
/// there is no longer any question of what the page is doing after the finger lifts, because the
/// offset is the truth and it keeps arriving through the deceleration. The settle timer, the
/// injected scheduler and the generation counter all went with it.
///
/// **The capture disc is deliberately NOT changed.** E was asked directly whether one shared rule
/// should govern both and chose *"only the bar gets the near-top rule"* — the disc keeps
/// restoring on any small up-scroll (its 2026-08-31 call). The two speak the same grammar and
/// answer to different numbers.
@MainActor
final class TabBarScrollActivityTests: XCTestCase {

    func testStartsFullWidth() {
        let activity = TabBarScrollActivity()
        XCTAssertFalse(activity.isFloating)
    }

    func testScrollingDownPastTheThresholdContractsTheBar() {
        let activity = TabBarScrollActivity()
        activity.offsetChanged(distanceFromTop: TabBarScrollActivity.contractDistance + 1)
        XCTAssertTrue(activity.isFloating)
    }

    func testASmallScrollLeavesTheBarAlone() {
        let activity = TabBarScrollActivity()
        activity.offsetChanged(distanceFromTop: TabBarScrollActivity.contractDistance - 1)
        XCTAssertFalse(activity.isFloating, "The bar contracted before the page had really moved")
    }

    /// **The behaviour E asked for.** Scrolling back up part-way must NOT restore the bar — it
    /// holds its floating shape for the whole read.
    func testScrollingBackUpPartWayKeepsTheBarFloating() {
        let activity = TabBarScrollActivity()
        activity.offsetChanged(distanceFromTop: 400)
        activity.offsetChanged(distanceFromTop: 200)
        activity.offsetChanged(distanceFromTop: TabBarScrollActivity.contractDistance + 1)
        XCTAssertTrue(
            activity.isFloating,
            "The bar expanded mid-page. It should hold until the page is back near the top."
        )
    }

    func testReturningNearTheTopRestoresTheFullWidthBar() {
        let activity = TabBarScrollActivity()
        activity.offsetChanged(distanceFromTop: 400)
        activity.offsetChanged(distanceFromTop: TabBarScrollActivity.nearTopDistance)
        XCTAssertFalse(activity.isFloating)
    }

    func testReturningAllTheWayToTheTopRestoresTheFullWidthBar() {
        let activity = TabBarScrollActivity()
        activity.offsetChanged(distanceFromTop: 400)
        activity.offsetChanged(distanceFromTop: 0)
        XCTAssertFalse(activity.isFloating)
    }

    /// Rubber-banding above the top gives a NEGATIVE distance. That is still the top.
    func testRubberBandingAboveTheTopCountsAsTheTop() {
        let activity = TabBarScrollActivity()
        activity.offsetChanged(distanceFromTop: 400)
        activity.offsetChanged(distanceFromTop: -60)
        XCTAssertFalse(activity.isFloating)
    }

    /// **Hysteresis is the point of having two numbers.** Between them the bar holds whatever it
    /// already was, so a page resting in the band cannot flap between the two shapes as the
    /// offset jitters by a point.
    func testTheBandBetweenTheThresholdsHoldsWhicheverStateItWasIn() {
        let midBand = (TabBarScrollActivity.nearTopDistance
            + TabBarScrollActivity.contractDistance) / 2

        let rising = TabBarScrollActivity()
        rising.offsetChanged(distanceFromTop: midBand)
        XCTAssertFalse(rising.isFloating, "Reached the band from the top — should still be full")

        let falling = TabBarScrollActivity()
        falling.offsetChanged(distanceFromTop: 400)
        falling.offsetChanged(distanceFromTop: midBand)
        XCTAssertTrue(falling.isFloating, "Reached the band from below — should still be floating")
    }

    func testTheThresholdsLeaveRoomForHysteresis() {
        XCTAssertLessThan(
            TabBarScrollActivity.nearTopDistance, TabBarScrollActivity.contractDistance,
            "Equal thresholds are no hysteresis at all — the bar would flap on a jittery offset."
        )
    }

    /// RootView calls this on a tab change: a bar left floating over a screen the user never
    /// scrolled reads as a bug, and the new tab's offset will not arrive until it is touched.
    func testResetRestoresTheFullWidthBarImmediately() {
        let activity = TabBarScrollActivity()
        activity.offsetChanged(distanceFromTop: 400)
        activity.reset()
        XCTAssertFalse(activity.isFloating)
    }

    func testScrollingAfterAResetStillContracts() {
        let activity = TabBarScrollActivity()
        activity.offsetChanged(distanceFromTop: 400)
        activity.reset()
        activity.offsetChanged(distanceFromTop: 400)
        XCTAssertTrue(activity.isFloating)
    }
}

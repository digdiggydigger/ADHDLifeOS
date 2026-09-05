//
//  UITestScrolling.swift
//  ADHD LifeOSUITests
//
//  Its own file because `UITestSession` is at its 400-line ceiling, and because this is one
//  finding rather than another utility: the suite had FOUR hand-rolled copies of a
//  scroll-into-reach loop, every one of them stopping at existence and tapping into momentum.
//  That was the whole of the "row exists at a sane frame and is never hittable" defect.
//

import XCTest

extension UITestSession {
    /// Scrolls `element` into REACH — which is two different problems, and every copy of this
    /// loop in the suite solved only the first.
    ///
    /// 1. **Existence.** Today and the nudges screen are `LazyVStack`s, so a row below the fold
    ///    is not merely unhittable — it is absent from the hierarchy, and `waitForExistence`
    ///    waits out its whole timeout for something that will never arrive.
    /// 2. **Rest, and it is worse than a stale read.** `swipeUp()` returns while the previous
    ///    gesture is still in flight, and a swipe issued into that window is SWALLOWED — a tight
    ///    loop does not scroll at all. The row still comes into EXISTENCE, because a `LazyVStack`
    ///    builds ahead of the viewport, which is what makes the bug so convincing: the element is
    ///    there, at a frame, and simply never reachable.
    ///
    /// FIVE hand-rolled copies of this existed (`CaptureDiscClearanceUITests`,
    /// `FirstRunJourneyUITests`, twice in `RenderHarnessUITests`, and `SignedInJourneySupport`),
    /// every one of them a tight swipe loop. That is the whole of the "row exists at a sane frame
    /// and is never hittable" defect that cost two sessions and read like a launch blocker.
    /// **The app was never at fault.**
    ///
    /// Returns whether it ended up hittable.
    @discardableResult
    @MainActor
    static func scrollUntilHittable(
        _ element: XCUIElement, in app: XCUIApplication, attempts: Int = 16
    ) -> Bool {
        var remaining = attempts
        while !element.exists, remaining > 0 {
            app.swipeUp()
            // The settle belongs here too, and this is the measured reason: a probe ran the two
            // shapes back to back, 12 rounds each, same account, one variable. Tight loop — the
            // row sat at y=1133 on an 874pt screen, unmoved, 12 times out of 12. With 0.5s
            // between swipes it came to rest at y=452 and was hittable 12 times out of 12.
            Thread.sleep(forTimeInterval: 0.5)
            remaining -= 1
        }
        guard element.exists else { return false }

        // No early bail on "the frame did not move". That was the obvious optimisation and it is
        // wrong here: Today's sections arrive from Firestore AFTER launch, so a page that is not
        // yet scrollable reports an unmoved frame, the loop concludes there is no scroll to be
        // had, and it gives up on a row that is about to be 500pt below the fold. Measured: the
        // row sat at y=1377 on an 874pt screen with the bail in place. The attempt cap is what
        // bounds the cost; a stationary frame is not evidence of anything.
        for _ in 0..<attempts {
            if element.isHittable { return true }
            app.swipeUp()
            Thread.sleep(forTimeInterval: 0.5)
        }
        return element.isHittable
    }
}

//
//  TabBarScrollActivity.swift
//  ADHD LifeOS
//

import Combine
import CoreGraphics
import Foundation

/// F-Tools-2-Morph's state: should the tab bar be the floating card right now?
///
/// **A POSITION rule, not a motion rule** — and it started as the other thing. The first cut was
/// MOMENTARY, B only while the page was actually moving, which is what E chose from the concepts.
/// Using it changed E's mind: *"much rather if the bar contracts into the floating card while the
/// page is moving in a downwards direction, but also stays as the floating card until the screen
/// view is manually scrolled upwards past a certain point"*. Asked what that point was, E chose
/// **near the top of the page**.
///
/// Reading position rather than gesture makes the momentum problem disappear rather than solving
/// it. The momentary model had to reason about what the page was doing after the finger lifted —
/// a pan recogniser tracks the finger, not the page — and needed a settle timer, an injected
/// scheduler and a generation counter to cover the glide. The offset is simply the truth, and it
/// keeps arriving through the deceleration. All of that machinery is gone.
///
/// **The capture disc is deliberately NOT governed by this.** E was asked whether one shared rule
/// should drive both and answered *"only the bar gets the near-top rule"*: the disc keeps its own
/// 2026-08-31 behaviour, restoring on any small up-scroll. The two speak the same directional
/// grammar and answer to different numbers, on purpose.
@MainActor
final class TabBarScrollActivity: ObservableObject {
    @Published private(set) var isFloating = false

    /// How far down the page you must be before the bar contracts. Small enough that the bar is
    /// out of the way as soon as you are actually reading, big enough that a rubber-band twitch
    /// at the top does not trigger it.
    nonisolated static let contractDistance: CGFloat = 24

    /// What counts as "near the top" — E's phrase, and the only thing that brings the bar back.
    nonisolated static let nearTopDistance: CGFloat = 8

    /// `distanceFromTop` is the scroll view's offset below its own resting position: 0 at the
    /// top, negative while rubber-banding above it.
    ///
    /// The gap between the two thresholds is **hysteresis, and it is the reason there are two
    /// numbers rather than one**. Inside the band the bar holds whatever it already was, so a
    /// page left resting near the boundary cannot flap between the two shapes as the offset
    /// jitters by a point.
    func offsetChanged(distanceFromTop: CGFloat) {
        if distanceFromTop > Self.contractDistance {
            if !isFloating { isFloating = true }
        } else if distanceFromTop <= Self.nearTopDistance {
            if isFloating { isFloating = false }
        }
    }

    /// The one restore that isn't a scroll: a tab change. The new tab's offset will not arrive
    /// until something touches it, and a bar left floating over a screen the user never scrolled
    /// reads as a bug — the same reasoning as the disc's `reset()`.
    func reset() {
        if isFloating { isFloating = false }
    }
}

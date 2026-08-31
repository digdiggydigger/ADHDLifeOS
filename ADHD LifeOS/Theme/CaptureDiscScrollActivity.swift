//
//  CaptureDiscScrollActivity.swift
//  ADHD LifeOS
//

import Combine
import CoreGraphics
import Foundation

/// F-PillStay's state: should the capture disc be a pill right now?
///
/// E's second motion verdict (2026-08-31) replaced F-DiscPill's settle-timer model: *"I want
/// this to stay in pill form until the page is scrolled upwards again."* So the pill is
/// DIRECTIONAL and STICKY — scrolling down (finger travelling up) collapses the disc and it
/// stays collapsed through the lift, the momentum and the reading; scrolling up (finger
/// travelling down) restores it. Nothing here runs on a timer any more, and there is no
/// "drag ended" input at all: stickiness by construction, not by a flag.
///
/// The latch: a directional anchor that re-bases on every flip. State changes only after
/// `directionThreshold` points of travel in the NEW direction, so touch jitter cannot flap the
/// disc, and a mid-drag reversal flips it without a new touch.
@MainActor
final class CaptureDiscScrollActivity: ObservableObject {
    @Published private(set) var prefersPill = false

    /// How far the finger must travel in the opposite direction before the state flips.
    /// Small enough that the disc answers an up-scroll immediately; big enough that a resting
    /// finger's tremor is silent.
    nonisolated static let directionThreshold: CGFloat = 12

    private var anchorY: CGFloat = 0

    /// A new touch's translation starts at zero — re-base so the first `dragMoved` measures
    /// travel within THIS gesture, not against the last one's endpoint.
    func dragBegan() {
        anchorY = 0
    }

    /// `translationY` is the pan's cumulative translation: negative = finger moving up =
    /// scrolling DOWN the page.
    func dragMoved(translationY: CGFloat) {
        let travel = translationY - anchorY
        if travel <= -Self.directionThreshold {
            anchorY = translationY
            if !prefersPill { prefersPill = true }
        } else if travel >= Self.directionThreshold {
            anchorY = translationY
            if prefersPill { prefersPill = false }
        }
    }

    /// The one restore that isn't a scroll: a context switch (RootView calls this on a tab
    /// change) starts fresh — a sticky pill over a page the user never scrolled reads as a bug.
    func reset() {
        if prefersPill { prefersPill = false }
    }
}

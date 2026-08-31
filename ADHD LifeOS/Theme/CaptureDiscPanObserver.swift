//
//  CaptureDiscPanObserver.swift
//  ADHD LifeOS
//

import UIKit

/// F-PillStay's scroll detector: one window-level `UIPanGestureRecognizer`, in the
/// `KeyboardTapAway` mould and for the same reason — every tab, every pushed screen, and every
/// screen added later, with zero per-screen wiring. SwiftUI on iOS 16 offers no scroll-activity
/// API, and threading an offset `PreferenceKey` through eleven scroll containers is exactly the
/// per-screen drift the clearance work just finished stamping out.
///
/// Since E's sticky-pill verdict (2026-08-31) the observer forwards DIRECTION, not just
/// existence: `.began` re-bases the model's anchor and `.changed` streams the cumulative
/// translation. The terminal states are deliberately not forwarded — the pill persisting
/// through the end of the gesture IS the feature ("stay in pill form until the page is
/// scrolled upwards again").
///
/// The recognizer never blocks anyone — `cancelsTouchesInView` stays false and recognition is
/// always simultaneous, so scrolls, swipes and buttons run exactly as before. A mostly
/// horizontal drag (a task-card swipe) never accumulates the vertical travel the model's latch
/// needs, so it changes nothing.
@MainActor
final class CaptureDiscPanObserver: NSObject, UIGestureRecognizerDelegate {
    /// Strongly held for the app's lifetime once installed; the recognizer holds its delegate
    /// weakly, so someone must own this object.
    private static var shared: CaptureDiscPanObserver?

    private let onDragBegan: @MainActor () -> Void
    private let onDragMoved: @MainActor (CGFloat) -> Void

    init(
        onDragBegan: @escaping @MainActor () -> Void,
        onDragMoved: @escaping @MainActor (CGFloat) -> Void
    ) {
        self.onDragBegan = onDragBegan
        self.onDragMoved = onDragMoved
    }

    /// Installs the recognizer on the scene's key window. Idempotent — RootView calls this from
    /// `onAppear`, which can fire again after auth-state swaps; the first install's callbacks
    /// win, which is safe because they capture RootView's `@StateObject` activity model, the
    /// one object that outlives every such swap.
    static func installOnKeyWindow(
        onDragBegan: @escaping @MainActor () -> Void,
        onDragMoved: @escaping @MainActor (CGFloat) -> Void
    ) {
        guard shared == nil else { return }
        let window = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first
        guard let window else { return }
        let coordinator = CaptureDiscPanObserver(onDragBegan: onDragBegan, onDragMoved: onDragMoved)
        let pan = UIPanGestureRecognizer(target: coordinator, action: #selector(handlePan))
        pan.cancelsTouchesInView = false
        pan.delegate = coordinator
        window.addGestureRecognizer(pan)
        shared = coordinator
    }

    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        react(to: recognizer.state, translationY: recognizer.translation(in: recognizer.view).y)
    }

    /// The state mapping, split from the selector so it is unit-testable without a window.
    /// Terminal states fall through to nothing on purpose — see the type comment.
    func react(to state: UIGestureRecognizer.State, translationY: CGFloat) {
        switch state {
        case .began:
            onDragBegan()
        case .changed:
            onDragMoved(translationY)
        case .possible, .ended, .cancelled, .failed:
            break
        @unknown default:
            break
        }
    }

    /// Never block anyone else — this recognizer only listens alongside the scroll it detects.
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

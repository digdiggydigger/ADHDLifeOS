//
//  CaptureDiscPanObserver.swift
//  ADHD LifeOS
//

import UIKit

/// F-DiscPill's scroll detector: one window-level `UIPanGestureRecognizer`, in the
/// `KeyboardTapAway` mould and for the same reason — every tab, every pushed screen, and every
/// screen added later, with zero per-screen wiring. SwiftUI on iOS 16 offers no scroll-activity
/// API, and threading an offset `PreferenceKey` through eleven scroll containers is exactly the
/// per-screen drift the clearance work just finished stamping out.
///
/// "Scrolling" here is any drag: a task-card swipe or a slider drag also means the user is
/// working the content under the disc, and a smaller disc during ANY of it is the point.
/// The recognizer never blocks anyone — `cancelsTouchesInView` stays false and recognition is
/// always simultaneous, so scrolls, swipes and buttons run exactly as before.
@MainActor
final class CaptureDiscPanObserver: NSObject, UIGestureRecognizerDelegate {
    /// Strongly held for the app's lifetime once installed; the recognizer holds its delegate
    /// weakly, so someone must own this object.
    private static var shared: CaptureDiscPanObserver?

    private let onDragBegan: @MainActor () -> Void
    private let onDragEnded: @MainActor () -> Void

    init(onDragBegan: @escaping @MainActor () -> Void, onDragEnded: @escaping @MainActor () -> Void) {
        self.onDragBegan = onDragBegan
        self.onDragEnded = onDragEnded
    }

    /// Installs the recognizer on the scene's key window. Idempotent — RootView calls this from
    /// `onAppear`, which can fire again after auth-state swaps; the first install's callbacks
    /// win, which is safe because they capture RootView's `@StateObject` activity model, the
    /// one object that outlives every such swap.
    static func installOnKeyWindow(
        onDragBegan: @escaping @MainActor () -> Void, onDragEnded: @escaping @MainActor () -> Void
    ) {
        guard shared == nil else { return }
        let window = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first
        guard let window else { return }
        let coordinator = CaptureDiscPanObserver(onDragBegan: onDragBegan, onDragEnded: onDragEnded)
        let pan = UIPanGestureRecognizer(target: coordinator, action: #selector(handlePan))
        pan.cancelsTouchesInView = false
        pan.delegate = coordinator
        window.addGestureRecognizer(pan)
        shared = coordinator
    }

    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        react(to: recognizer.state)
    }

    /// The state mapping, split from the selector so it is unit-testable without a window.
    ///
    /// `.changed` is deliberately silent — it streams every frame of a drag and forwarding it
    /// would cancel-and-reschedule the settle timer continuously for no state change. All three
    /// terminal states restore: `.cancelled` (an incoming call, a system gesture) and `.failed`
    /// would otherwise strand the disc as a pill with no touch left to end it.
    func react(to state: UIGestureRecognizer.State) {
        switch state {
        case .began:
            onDragBegan()
        case .ended, .cancelled, .failed:
            onDragEnded()
        case .possible, .changed:
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

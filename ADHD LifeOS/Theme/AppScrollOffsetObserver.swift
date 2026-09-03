//
//  AppScrollOffsetObserver.swift
//  ADHD LifeOS
//

import UIKit

/// Reports how far down the page the user currently is, for `TabBarScrollActivity`.
///
/// **Window-level, with zero per-screen wiring** — the `CaptureDiscPanObserver` /
/// `KeyboardTapAway` mould, and for the same reason. The alternative is a `GeometryReader` +
/// `PreferenceKey` modifier applied at each of the app's scroll containers, which is exactly the
/// per-screen drift the capture-disc clearance work spent a block stamping out: eleven call
/// sites, and a screen that forgets one silently never contracts the bar.
///
/// **Why position rather than the pan translation `CaptureDiscPanObserver` already streams.** A
/// pan recogniser tracks the FINGER, not the page. It says nothing after the lift, while the
/// scroll view is still gliding, and nothing at all about where in the page you have ended up —
/// and E's rule is a position one: the bar holds its floating shape *until the page is scrolled
/// back near the top*. `contentOffset` answers that directly, and KVO keeps answering it through
/// the whole deceleration.
///
/// The pan recogniser here exists only to learn **which** scroll view to watch: a hit test at the
/// touch point. `AppTabContent` keeps every visited tab alive, so simply walking the window for a
/// `UIScrollView` would find the hidden tabs' as readily as the visible one. It never blocks
/// anyone — `cancelsTouchesInView` stays false and recognition is always simultaneous — and it is
/// a second recogniser rather than an extra callback on `CaptureDiscPanObserver` because that one
/// is the DISC's, its behaviour is settled, and it deliberately forwards no touch location.
@MainActor
final class AppScrollOffsetObserver: NSObject, UIGestureRecognizerDelegate {
    /// Strongly held for the app's lifetime once installed; the recognizer holds its delegate
    /// weakly, so someone must own this object.
    private static var shared: AppScrollOffsetObserver?

    private let onOffsetChanged: @MainActor (CGFloat) -> Void
    private var observation: NSKeyValueObservation?
    private weak var observed: UIScrollView?
    /// Suppresses duplicate reports. `contentOffset` fires for horizontal movement too, and a
    /// resting scroll view can emit the same value repeatedly.
    private var lastReported: CGFloat = .nan

    init(onOffsetChanged: @escaping @MainActor (CGFloat) -> Void) {
        self.onOffsetChanged = onOffsetChanged
    }

    /// Idempotent, matching `CaptureDiscPanObserver` — RootView calls this from `onAppear`, which
    /// can fire again after an auth-state swap. The first install's callback wins, which is safe
    /// because it captures RootView's `@StateObject`, the one object that outlives those swaps.
    static func installOnKeyWindow(onOffsetChanged: @escaping @MainActor (CGFloat) -> Void) {
        guard shared == nil else { return }
        let window = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first
        guard let window else { return }
        let coordinator = AppScrollOffsetObserver(onOffsetChanged: onOffsetChanged)
        let pan = UIPanGestureRecognizer(target: coordinator, action: #selector(handlePan))
        pan.cancelsTouchesInView = false
        pan.delegate = coordinator
        window.addGestureRecognizer(pan)
        shared = coordinator
    }

    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        guard recognizer.state == .began, let view = recognizer.view else { return }
        let point = recognizer.location(in: view)
        guard let hit = view.hitTest(point, with: nil) else { return }
        guard let scrollView = Self.enclosingScrollView(of: hit) else { return }
        watch(scrollView)
    }

    /// The nearest scroll view at or above the touched view. Nearest, not outermost: a horizontal
    /// chip strip inside a vertical page would otherwise hand back the page and report an offset
    /// the user is not actually driving.
    static func enclosingScrollView(of view: UIView) -> UIScrollView? {
        var candidate: UIView? = view
        while let current = candidate {
            if let scrollView = current as? UIScrollView, scrollView.isScrollEnabled {
                return scrollView
            }
            candidate = current.superview
        }
        return nil
    }

    /// How far below its resting position a scroll view sits: 0 at the top, negative while
    /// rubber-banding above it. The inset matters — a page with a large top safe area or a
    /// refresh control rests at a negative `contentOffset.y`, and without adding it back every
    /// screen would look permanently scrolled.
    static func distanceFromTop(of scrollView: UIScrollView) -> CGFloat {
        scrollView.contentOffset.y + scrollView.adjustedContentInset.top
    }

    private func watch(_ scrollView: UIScrollView) {
        guard observed !== scrollView else { return }
        observed = scrollView
        lastReported = .nan
        // `.initial` so a tap on an already-scrolled page reports where it is, rather than
        // waiting for the first movement.
        observation = scrollView.observe(\.contentOffset, options: [.initial, .new]) { view, _ in
            let distance = Self.distanceFromTop(of: view)
            // KVO for `contentOffset` fires on the main thread — UIKit only ever mutates it
            // there — but that is not something the compiler can be shown, hence the hop. It is
            // gated on a real change so a scroll does not queue one per frame for nothing.
            Task { @MainActor [weak self] in
                self?.report(distance)
            }
        }
    }

    private func report(_ distance: CGFloat) {
        guard lastReported.isNaN || abs(distance - lastReported) >= 1 else { return }
        lastReported = distance
        onOffsetChanged(distance)
    }

    /// Never block anyone else — this recognizer only listens alongside the scroll it measures.
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

//
//  KeyboardTapAway.swift
//  ADHD LifeOS
//

import UIKit

/// b5, round two (E's on-device verdict, 2026-08-26): the Done bar and scroll-drag shipped first
/// and work, but the gesture people actually reach for is tapping AWAY from the field. One
/// window-level `UITapGestureRecognizer` provides it everywhere — every tab, every sheet and
/// cover (they present in the same `UIWindow`), and every screen added later, with zero
/// per-screen wiring.
///
/// `cancelsTouchesInView` stays false, so the tap still does whatever it was going to do —
/// a button tapped mid-edit both fires AND drops the keyboard, which is the iOS-native feel.
/// The delegate ignores touches inside text inputs, so tapping a field only ever moves focus.
final class KeyboardTapAway: NSObject, UIGestureRecognizerDelegate {
    /// Strongly held for the app's lifetime once installed; the recognizer holds its delegate
    /// weakly, so someone must own this object.
    private static var shared: KeyboardTapAway?

    /// Whether the touched view, or any ancestor, is an editable text view. Ancestors only —
    /// never descendants: a form row CONTAINING a field must still count as "outside", or the
    /// gesture would go dead across whole form screens. SwiftUI's fields are UIKit-backed
    /// (`UITextField`/`UITextView`), but touches land on private subviews, hence the climb.
    static func isInsideTextInput(_ view: UIView?) -> Bool {
        var current = view
        while let candidate = current {
            if candidate is UITextField || candidate is UITextView { return true }
            current = candidate.superview
        }
        return false
    }

    /// Installs the recognizer on the scene's key window. Idempotent — RootView calls this from
    /// `onAppear`, which can fire again after auth-state swaps.
    static func installOnKeyWindow() {
        guard shared == nil else { return }
        let window = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first
        guard let window else { return }
        let coordinator = KeyboardTapAway()
        let tap = UITapGestureRecognizer(target: coordinator, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        tap.requiresExclusiveTouchType = false
        tap.delegate = coordinator
        window.addGestureRecognizer(tap)
        shared = coordinator
    }

    @objc private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
        )
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        !Self.isInsideTextInput(touch.view)
    }

    /// Never block anyone else — scrolls, swipes, buttons and SwiftUI's own gestures all run
    /// exactly as before; this recognizer only listens alongside them.
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

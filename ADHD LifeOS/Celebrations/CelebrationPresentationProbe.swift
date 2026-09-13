//
//  CelebrationPresentationProbe.swift
//  ADHD LifeOS
//
//  `F-CTACelebrations-Surfaces`: **how the centre knows a sheet is up.**
//
//  E's call, 2026-09-13, choosing between two designs put to them: a house modifier on all 26
//  `.sheet` / `.fullScreenCover` presenters, or asking UIKit. **E chose asking UIKit**, and in the
//  same breath chose that the hold applies behind alerts, confirmation dialogs and system pickers
//  too — which the per-presenter design could not have done at any price, because the app does not
//  present those and never sees them come or go.
//
//  **The precedent is `AppScrollOffsetObserver`, and its own doc comment makes the argument:** the
//  alternative to a window-level reader is "a modifier applied at each of the app's scroll
//  containers, which is exactly the per-screen drift the capture-disc clearance work spent a block
//  stamping out: eleven call sites, and a screen that forgets one silently never contracts the
//  bar." Three observers here already walk `connectedScenes → keyWindow` for the same reason.
//  E's ARCH answer (one drawing layer per surface, not a passthrough `UIWindow`) is untouched by
//  this: that decided where a celebration is DRAWN, not whether the app may read UIKit's state.
//
//  **Why a recursive walk rather than `rootViewController.presentedViewController`.** UIKit
//  forwards most modal presentations up to the root, so the one-line read is right most of the
//  time — but a controller that `definesPresentationContext` presents from where it stands, and
//  whether SwiftUI ever does that for a `.sheet` is not provable from here. The walk covers both
//  and costs a handful of pointer reads on a tree a dozen deep.
//

import UIKit

/// Whether ANY view controller is presented over the app's window right now — the app's own sheets
/// and covers, `.alert`, `.confirmationDialog`, the share sheet, the camera and contact pickers,
/// and iOS's own interruptions such as the "Save Password?" sheet.
///
/// One read-only question, deliberately: the centre asks it and decides, exactly as a site asks the
/// centre and decides nothing.
protocol PresentationProbing {
    var isAnythingPresented: Bool { get }
}

/// The real one, and the app's default.
///
/// Sheets and covers present in the SAME `UIWindow` as the tabs (`KeyboardTapAway` records this and
/// relies on it), so one window is the whole search.
struct KeyWindowPresentationProbe: PresentationProbing {
    var isAnythingPresented: Bool {
        guard let root = Self.keyWindowRoot() else { return false }
        return Self.presentsAnything(root)
    }

    /// The controller at the base of the scene's key window, or `nil` before a scene is up — in
    /// which case nothing can be presented over it either, so `false` is the honest answer rather
    /// than a guess.
    static func keyWindowRoot() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?
            .rootViewController
    }

    /// Anything presented at `controller` or anywhere in the container tree beneath it.
    ///
    /// Children, not the presented chain: one presentation anywhere is the whole answer, so there
    /// is nothing to learn by walking deeper into what is already known to be up.
    static func presentsAnything(_ controller: UIViewController) -> Bool {
        if controller.presentedViewController != nil { return true }
        return controller.children.contains { presentsAnything($0) }
    }
}

/// Nothing is ever presented. The default in tests, and the reason every one of them has to say so
/// out loud when it means the opposite.
struct NothingPresentedProbe: PresentationProbing {
    var isAnythingPresented: Bool { false }
}

//
//  AppDeepLink.swift
//  ADHD LifeOS
//

import Foundation

/// What an incoming URL means. The app has one registered scheme (`adhdlifeos`), shared by the
/// auth callback and — since the Home Screen widget — by widget taps, so `onOpenURL` has to tell
/// them apart rather than assuming everything is an auth callback (which is what it did before,
/// and which would have fed every widget tap into `AuthService.completeSession(from:)`).
enum AppDeepLink: Equatable {
    /// A magic-link / OAuth return, handled by `AuthService`.
    case authCallback
    /// A Home Screen widget tap. Nothing to do: launching the app already lands on Home, which is
    /// what the widget shows.
    case focusWidget
    /// The Life Areas widget's tap — lands on the Areas tab (E's 2026-08-25 widgets note).
    case areasTab
    /// A capture-type button on the Quick Capture widget — opens the composer with that kind
    /// already chosen, exactly like the fan's discs. The URL path spells `CaptureKind.rawValue`;
    /// the widget target writes those strings by hand because it cannot see the enum, and the
    /// route test locks the contract from this side.
    case captureComposer(CaptureKind)

    /// The host the widget stamps on its `widgetURL`.
    static let widgetHost = "widget"

    static func route(_ url: URL) -> AppDeepLink {
        guard url.host == widgetHost else { return .authCallback }
        let path = url.pathComponents.filter { $0 != "/" }
        if path.first == "areas" { return .areasTab }
        if path.count == 2, path[0] == "capture", let kind = CaptureKind(rawValue: path[1]) {
            return .captureComposer(kind)
        }
        // Unknown widget paths — including a capture kind a newer widget knows and this build
        // doesn't — still launch the app rather than reaching the auth layer.
        return .focusWidget
    }
}

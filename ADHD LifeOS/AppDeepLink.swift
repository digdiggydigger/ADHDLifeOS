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

    /// The host the widget stamps on its `widgetURL`.
    static let widgetHost = "widget"

    static func route(_ url: URL) -> AppDeepLink {
        url.host == widgetHost ? .focusWidget : .authCallback
    }
}

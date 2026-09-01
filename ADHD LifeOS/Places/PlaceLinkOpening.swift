//
//  PlaceLinkOpening.swift
//  ADHD LifeOS
//
//  How a tapped place-action URL actually opens (F-AppDirectory-2-Links). NOT 17-gated: the
//  notification-tap path compiles at the app's 16.0 floor, and `.universalLinksOnly` is
//  available from iOS 10.
//

import Foundation

/// How a URL should be opened. Web links go universal-first — the app if installed, the web if
/// not, which is the arc's whole premise — and scheme URLs have no web form, so they get one
/// plain open.
enum PlaceLinkOpenPlan: Equatable {
    case universalFirst(URL)
    case direct(URL)

    static func plan(for url: URL) -> PlaceLinkOpenPlan {
        let scheme = url.scheme?.lowercased()
        return scheme == "https" || scheme == "http" ? .universalFirst(url) : .direct(url)
    }
}

/// Runs a plan against an injected `open` primitive (`UIApplication.open` in the app; a
/// recorder in tests).
///
/// THE LOAD-BEARING SHAPE: attempt 1 is issued SYNCHRONOUSLY inside `run` — the notification
/// tap's first `UIApplication.open` must ride the delegate callback's user-initiated
/// attribution (the `0c65ca5` field lesson; an async hop invites iOS's "wants to open X"
/// dialog). The plain-open fallback lives in attempt 1's completion: it is the failure path,
/// where attribution no longer matters. The honest failure banner fires only after the LAST
/// attempt fails — never in between, never silence.
@MainActor
struct PlaceLinkOpener {
    let open: (URL, _ universalLinksOnly: Bool, _ completion: @escaping (Bool) -> Void) -> Void
    let notifyFailure: (String) -> Void

    func run(_ plan: PlaceLinkOpenPlan, failureBody: String) {
        switch plan {
        case .direct(let url):
            open(url, false) { success in
                guard !success else { return }
                notifyFailure(failureBody)
            }
        case .universalFirst(let url):
            open(url, true) { success in
                guard !success else { return }
                open(url, false) { fallbackSuccess in
                    guard !fallbackSuccess else { return }
                    notifyFailure(failureBody)
                }
            }
        }
    }
}

//
//  AppDeepLinkTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The app registers ONE URL scheme (`adhdlifeos`), and until the Home Screen widget existed every
/// URL that arrived on it was an auth callback — `onOpenURL` handed all of them straight to
/// `AuthService.completeSession(from:)`. A widget tap now arrives on that same scheme, so the two
/// must be told apart before the auth layer ever sees them.
final class AppDeepLinkTests: XCTestCase {
    private func route(_ string: String) -> AppDeepLink {
        AppDeepLink.route(URL(string: string)!)
    }

    func testWidgetTap_routesToTheWidgetDestination() {
        XCTAssertEqual(route("adhdlifeos://widget/focus"), .focusWidget)
    }

    func testAuthCallback_stillRoutesToAuth() {
        XCTAssertEqual(route("adhdlifeos://auth-callback#access_token=abc"), .authCallback)
        XCTAssertEqual(route("adhdlifeos://login-callback?code=xyz"), .authCallback)
    }

    func testUniversalLink_routesToAuth() {
        XCTAssertEqual(route("https://adhdlifeos.example/auth?code=xyz"), .authCallback)
    }

    func testWidgetHostIsMatchedExactly_notByPrefix() {
        XCTAssertEqual(
            route("adhdlifeos://widgetry/focus"), .authCallback,
            "only the widget host itself may bypass the auth handler"
        )
    }
}

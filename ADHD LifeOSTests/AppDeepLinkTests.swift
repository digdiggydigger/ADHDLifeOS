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

    // MARK: - The two new medium widgets (E's 2026-08-25 note)

    func testLifeAreasWidgetTap_routesToTheAreasTab() {
        XCTAssertEqual(route("adhdlifeos://widget/areas"), .areasTab)
    }

    /// The Quick Capture widget's five buttons — the URL path spells the kind's raw value, which
    /// is the contract the widget target writes by hand (it cannot see `CaptureKind`).
    func testCaptureButtons_routeToTheComposerWithTheirKind() {
        for kind in CaptureKind.allCases {
            XCTAssertEqual(
                route("adhdlifeos://widget/capture/\(kind.rawValue)"),
                .captureComposer(kind),
                "\(kind.rawValue) must open its own composer"
            )
        }
    }

    /// A kind this build doesn't know (older app, newer widget) still launches the app rather
    /// than reaching the auth layer or crashing — the same resolve-to-safe rule as everywhere.
    func testUnknownCapturePath_fallsBackToThePlainWidgetLaunch() {
        XCTAssertEqual(route("adhdlifeos://widget/capture/hologram"), .focusWidget)
        XCTAssertEqual(route("adhdlifeos://widget/capture"), .focusWidget)
        XCTAssertEqual(route("adhdlifeos://widget/unknown-surface"), .focusWidget)
    }

    // MARK: - Cold launch (E's on-device note, 2026-08-25)

    /// The widget doors target the signed-in tab hierarchy, which does not exist yet while auth
    /// is still restoring on a dead launch — the handler that knows these routes was mounted on
    /// the TabView, so the launch URL arrived before anyone listening for it. RootView now holds
    /// these routes as pending until the tabs exist; this is the list of what must be held.
    func testWidgetDoors_mustBeHeldForTheSignedInUI() {
        XCTAssertTrue(AppDeepLink.areasTab.requiresSignedInUI)
        for kind in CaptureKind.allCases {
            XCTAssertTrue(
                AppDeepLink.captureComposer(kind).requiresSignedInUI,
                "\(kind.rawValue)'s composer only exists inside the signed-in tabs"
            )
        }
    }

    func testNonDoorRoutes_areNeverHeld() {
        XCTAssertFalse(
            AppDeepLink.authCallback.requiresSignedInUI,
            "auth callbacks have their own always-mounted App-level handler"
        )
        XCTAssertFalse(
            AppDeepLink.focusWidget.requiresSignedInUI,
            "a plain launch is already the whole action"
        )
    }
}

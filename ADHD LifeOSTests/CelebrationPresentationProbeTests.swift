//
//  CelebrationPresentationProbeTests.swift
//  ADHD LifeOSTests
//
//  `F-CTACelebrations-Surfaces`: the **default** probe, against a real `UIWindow` and real
//  presentations.
//
//  **This file exists because of `F-CTACelebrations-7`'s lesson, and it is the same shape.** There,
//  every test in `CelebrationSoundTests` injected the asset loader, so a fully green suite had
//  never once proved that `NSDataAsset(name:)` resolves the chime — the one thing every user
//  depends on. Here every test in `CelebrationUnknownSheetHoldTests` injects the probe, so nothing
//  in it would notice if the window walk returned `false` for every sheet in the app and quietly
//  disabled the whole block. **Whenever a seam is injected everywhere for testability, ask what
//  exercises the real one.**
//
//  The window is built and made key here rather than borrowed, and the previous key window is put
//  back, so the hosted app's own window is left as it was found.
//

import UIKit
import XCTest
@testable import ADHD_LifeOS

@MainActor
final class CelebrationPresentationProbeTests: XCTestCase {

    private var window: UIWindow!
    private var previousKeyWindow: UIWindow?
    private let probe = KeyWindowPresentationProbe()

    override func setUp() async throws {
        try await super.setUp()
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "No window scene — the unit target hosts the app, so there should be one."
        )
        previousKeyWindow = scene.keyWindow
        window = UIWindow(windowScene: scene)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
    }

    override func tearDown() async throws {
        if let presented = window.rootViewController?.presentedViewController {
            await dismiss(from: presented.presentingViewController)
        }
        window.isHidden = true
        window = nil
        previousKeyWindow?.makeKeyAndVisible()
        try await super.tearDown()
    }

    /// The baseline, and the one that fails if the probe simply answers `true`.
    func testTheProbeReadsClearOverAWindowWithNothingPresented() {
        XCTAssertFalse(probe.isAnythingPresented)
    }

    /// The ordinary case: SwiftUI's `.sheet` and `.fullScreenCover` both come out as a controller
    /// presented in the app's one window (`KeyboardTapAway` records that they share it).
    func testTheProbeSeesAControllerPresentedFromTheWindowRoot() async throws {
        let root = try XCTUnwrap(window.rootViewController)
        await present(UIViewController(), from: root)
        XCTAssertTrue(probe.isAnythingPresented)
    }

    /// **The reason the walk recurses.** A controller that defines its own presentation context
    /// presents from where it stands, so the root's `presentedViewController` stays `nil` and the
    /// one-line read — which is what this started as — reports the screen as clear while a modal is
    /// covering it.
    func testTheProbeSeesAPresentationFromAChildRatherThanTheRoot() async throws {
        let root = try XCTUnwrap(window.rootViewController)
        let child = UIViewController()
        root.addChild(child)
        child.view.frame = root.view.bounds
        root.view.addSubview(child.view)
        child.didMove(toParent: root)
        child.definesPresentationContext = true

        let presented = UIViewController()
        presented.modalPresentationStyle = .currentContext
        await present(presented, from: child)

        XCTAssertNil(
            root.presentedViewController,
            "The child did not keep the presentation, so this test proves nothing about recursion."
        )
        XCTAssertNotNil(child.presentedViewController)
        XCTAssertTrue(probe.isAnythingPresented)
    }

    /// The release side. The centre polls this exact read to decide a held celebration can play, so
    /// a probe that latched on would hold every celebration for R-g's sixty seconds and drop it.
    func testTheProbeReadsClearAgainOnceTheControllerIsDismissed() async throws {
        let root = try XCTUnwrap(window.rootViewController)
        await present(UIViewController(), from: root)
        XCTAssertTrue(probe.isAnythingPresented)
        await dismiss(from: root)
        XCTAssertFalse(probe.isAnythingPresented)
    }

    // MARK: - Helpers

    private func present(_ controller: UIViewController, from presenter: UIViewController) async {
        await withCheckedContinuation { continuation in
            presenter.present(controller, animated: false) { continuation.resume() }
        }
    }

    private func dismiss(from presenter: UIViewController?) async {
        guard let presenter else { return }
        await withCheckedContinuation { continuation in
            presenter.dismiss(animated: false) { continuation.resume() }
        }
    }
}

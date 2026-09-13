//
//  CelebrationUnknownSheetCompositionTests.swift
//  ADHD LifeOSTests
//
//  `F-CTACelebrations-Surfaces`: the centre and the REAL probe, over a REAL SwiftUI sheet, with
//  nothing injected but the clock.
//
//  **Why this file exists when the other three are green.** They prove three things separately: the
//  centre holds when a probe says a sheet is up; the real probe sees a SwiftUI sheet; the app's
//  centre is built with the real probe. Each is true and none of them is the claim — which is that
//  a milestone asked for while a sheet is up is HELD, and plays when it closes. This repo's most
//  expensive recurring defect is exactly that gap: seven instances of a component whose every part
//  was correct and whose whole was never reachable (`dead-shared-component`, and the guards that
//  missed instance 7 were ten purpose-built ones).
//
//  So this is the composition, end to end — and the only seam left injected is `now`, because R-g
//  is sixty seconds long and a test may not take sixty seconds to run.
//
//  What it still does NOT prove is that the app's five request sites fire while a sheet is up; that
//  is the shape of the thing, and it is what E's device pass is for.
//

import Combine
import SwiftUI
import UIKit
import XCTest
@testable import ADHD_LifeOS

@MainActor
final class CelebrationUnknownSheetCompositionTests: XCTestCase {

    private let launch = Date(timeIntervalSince1970: 1_800_000_000)
    private var window: UIWindow!
    private var previousKeyWindow: UIWindow?
    private var isSheetUp = SheetFlag()

    /// A reference the SwiftUI host reads, so the sheet can be taken down from the test body.
    private final class SheetFlag: ObservableObject {
        @Published var isUp = true
        /// What the probe answered from inside SwiftUI's own `onDismiss`. See the test below.
        var probeInsideOnDismiss: Bool?
    }

    override func setUp() async throws {
        try await super.setUp()
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        )
        previousKeyWindow = scene.keyWindow
        isSheetUp = SheetFlag()
        window = UIWindow(windowScene: scene)
        window.rootViewController = UIHostingController(rootView: Host(flag: isSheetUp))
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
    }

    override func tearDown() async throws {
        window.rootViewController = nil
        window.isHidden = true
        window = nil
        previousKeyWindow?.makeKeyAndVisible()
        try await super.tearDown()
    }

    /// The block, whole: a sheet nothing told the centre about, a milestone, and the celebration
    /// arriving after the sheet has gone rather than underneath it.
    func testAMilestoneAskedForBehindARealSwiftUISheetIsHeldAndPlaysWhenItCloses() async throws {
        let clock = Clock(launch)
        let center = CelebrationCenter(
            now: { clock.now }, celebrationsGate: { true }, chime: { _ in }, feel: { _ in }
        )
        try await waitUntil { KeyWindowPresentationProbe().isAnythingPresented }

        XCTAssertEqual(center.request(.milestone(.inboxZero), at: nil), .fullScreen)
        XCTAssertTrue(
            center.bursts.isEmpty,
            "Drawn on the root layer while a sheet covered it — the defect this block closes, and "
                + "the composition is the only thing here that could have caught it."
        )
        XCTAssertEqual(center.held.count, 1)

        isSheetUp.isUp = false
        try await waitUntil { !KeyWindowPresentationProbe().isAnythingPresented }
        clock.advance(0.3)
        center.pollHeldBursts()

        XCTAssertEqual(center.bursts.count, 1)
        XCTAssertEqual(center.bursts[0].surface, .root)
        XCTAssertEqual(center.bursts[0].kind, .milestone(.inboxZero))
    }

    /// The control, and it is the one that would catch a probe wired to `true`: the same centre,
    /// the same window, no sheet.
    func testAMilestoneAskedForWithTheSheetAlreadyDownDrawsAtOnce() async throws {
        let clock = Clock(launch)
        let center = CelebrationCenter(
            now: { clock.now }, celebrationsGate: { true }, chime: { _ in }, feel: { _ in }
        )
        isSheetUp.isUp = false
        try await waitUntil { !KeyWindowPresentationProbe().isAnythingPresented }

        XCTAssertEqual(center.request(.milestone(.inboxZero), at: nil), .fullScreen)
        XCTAssertEqual(center.bursts.count, 1)
        XCTAssertTrue(center.held.isEmpty)
    }

    /// **The shipped path this block could have slowed down, and the fact that says it did not.**
    ///
    /// `surfaceDismissed` used to release a held burst unconditionally; it now asks `isBlocked`
    /// first, so that a tracked surface closing cannot put the burst under an untracked one that
    /// is still up. The Create Task sheet's inbox-zero celebration — shipped in
    /// `F-CTACelebrations-5`, verified on E's phone — goes through exactly that line, and if
    /// SwiftUI ran `onDismiss` while the presentation was still standing, that celebration would
    /// have quietly started waiting for the 0.25 s watch instead of playing at once.
    ///
    /// It does not: `onDismiss` runs after the teardown, so the probe reads clear inside it and
    /// the release is immediate. That is a fact about SwiftUI rather than about this app, which is
    /// why it is pinned here — the day it changes, the sheet path gets slower and nothing else in
    /// the suite would notice.
    func testSwiftUIRunsOnDismissAfterTheSheetIsAlreadyTornDown() async throws {
        try await waitUntil { KeyWindowPresentationProbe().isAnythingPresented }
        isSheetUp.isUp = false
        try await waitUntil { self.isSheetUp.probeInsideOnDismiss != nil }
        XCTAssertEqual(
            isSheetUp.probeInsideOnDismiss, false,
            "SwiftUI now runs `onDismiss` while the presentation still stands, so every burst held "
                + "behind a self-dismissing sheet waits for the hold watch instead of playing at "
                + "once. `releaseHeldIfClear` is the line to look at."
        )
    }

    // MARK: - Support

    private final class Clock {
        var now: Date
        init(_ now: Date) { self.now = now }
        func advance(_ seconds: TimeInterval) { now = now.addingTimeInterval(seconds) }
    }

    private struct Host: View {
        @ObservedObject var flag: SheetFlag

        var body: some View {
            Color.clear.sheet(
                isPresented: $flag.isUp,
                onDismiss: {
                    flag.probeInsideOnDismiss = KeyWindowPresentationProbe().isAnythingPresented
                },
                content: { Text("an untracked sheet") }
            )
        }
    }

    /// SwiftUI presents and dismisses on later turns of the run loop, so the condition is polled.
    private func waitUntil(
        _ condition: @MainActor () -> Bool, line: UInt = #line
    ) async throws {
        for _ in 0..<50 {
            if condition() { return }
            _ = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                    continuation.resume(returning: true)
                }
            }
        }
        XCTFail("The window never reached the expected state.", line: line)
    }
}

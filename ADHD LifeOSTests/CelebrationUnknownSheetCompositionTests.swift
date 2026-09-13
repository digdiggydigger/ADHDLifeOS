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
        /// Set by the sheet CONTENT's `onAppear`. **The reason it exists:**
        /// `isAnythingPresented` is a reading of the whole key window, so waiting on it to learn
        /// that *this* test's sheet is up is satisfied just as well by a leftover presentation
        /// from the class that ran before. That made this file flaky — it passed twice and then
        /// timed out — and, worse, it could have made the positive assertions vacuous. This flag
        /// is the sheet's own, so it cannot be answered by anyone else's.
        var didAppear = false
        /// What the probe answered from inside SwiftUI's own `onDismiss`. Doubles as this test's
        /// own signal that the sheet is GONE, for the same reason.
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
        // Every test starts with the sheet genuinely up, proved by the sheet's OWN signal and then
        // confirmed through the probe — so no test has to race the presentation itself.
        try await waitUntil("this test's own sheet to appear") { self.isSheetUp.didAppear }
        try await waitUntil("the probe to see it") { KeyWindowPresentationProbe().isAnythingPresented }
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
        XCTAssertEqual(center.request(.milestone(.inboxZero), at: nil), .fullScreen)
        XCTAssertTrue(
            center.bursts.isEmpty,
            "Drawn on the root layer while a sheet covered it — the defect this block closes, and "
                + "the composition is the only thing here that could have caught it."
        )
        XCTAssertEqual(center.held.count, 1)

        isSheetUp.isUp = false
        try await waitUntil("this test's own sheet to go") { self.isSheetUp.probeInsideOnDismiss != nil }
        XCTAssertFalse(KeyWindowPresentationProbe().isAnythingPresented)
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
        try await waitUntil("this test's own sheet to go") { self.isSheetUp.probeInsideOnDismiss != nil }
        XCTAssertFalse(KeyWindowPresentationProbe().isAnythingPresented)

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
        isSheetUp.isUp = false
        try await waitUntil("`onDismiss` to run") { self.isSheetUp.probeInsideOnDismiss != nil }
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
                content: {
                    Text("an untracked sheet").onAppear { flag.didAppear = true }
                }
            )
        }
    }

    /// SwiftUI presents and dismisses on later turns of the run loop, so the condition is polled.
    ///
    /// **Deadline-based, not a fixed iteration count.** The count version budgeted 50 × 20 ms = 1 s
    /// of wall clock, which is ample on an idle machine and not ample at all inside a 3,000-test
    /// suite — it timed out once for no better reason than the run being busier that time.
    private func waitUntil(
        _ what: String, line: UInt = #line, _ condition: @MainActor () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            if condition() { return }
            _ = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                    continuation.resume(returning: true)
                }
            }
        }
        XCTFail("Waited 5 s for \(what) and it never happened.", line: line)
    }
}

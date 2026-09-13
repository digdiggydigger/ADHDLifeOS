//
//  CelebrationProbeSwiftUISheetTests.swift
//  ADHD LifeOSTests
//
//  `F-CTACelebrations-Surfaces`: the probe against **SwiftUI's own presentations**, hosted for real.
//
//  **`CelebrationPresentationProbeTests` does not cover this, and the difference is the whole
//  block.** That file presents a `UIViewController` the way UIKit does, and proves the walk finds
//  it. Every sheet in this app is a SwiftUI `.sheet` or `.fullScreenCover`, presented by machinery
//  nobody here wrote — and if SwiftUI seats those somewhere the walk does not reach, the block
//  compiles, the suite is green and not one celebration is ever held.
//
//  It is `F-CTACelebrations-7`'s lesson for the third time: *whenever a seam is injected everywhere
//  for testability, ask what exercises the real one* — and then ask whether the test of the real
//  one is exercising the real INPUT. A UIKit `present(_:animated:)` is not what the app does.
//
//  `.alert` and `.confirmationDialog` are here because E chose them explicitly (2026-09-13): the
//  hold covers them too, and they are the two the per-presenter design could never have caught.
//

import SwiftUI
import UIKit
import XCTest
@testable import ADHD_LifeOS

@MainActor
final class CelebrationProbeSwiftUISheetTests: XCTestCase {

    private var window: UIWindow!
    private var previousKeyWindow: UIWindow?
    private let probe = KeyWindowPresentationProbe()

    override func setUp() async throws {
        try await super.setUp()
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        )
        previousKeyWindow = scene.keyWindow
        window = UIWindow(windowScene: scene)
    }

    override func tearDown() async throws {
        window.rootViewController = nil
        window.isHidden = true
        window = nil
        previousKeyWindow?.makeKeyAndVisible()
        try await super.tearDown()
    }

    /// Quick Capture's shape — `RootView.swift`'s `.fullScreenCover`, the most-opened surface in
    /// the app and the one E named first.
    func testTheProbeSeesASwiftUIFullScreenCover() async throws {
        try await assertProbeSees(AnyView(CoverHost()))
    }

    /// Settings, Add Task, the Journal composer, the focus sprint detail, add nudge and the Life
    /// Area / Place / Tag editors — twenty-odd call sites of exactly this.
    func testTheProbeSeesASwiftUISheet() async throws {
        try await assertProbeSees(AnyView(SheetHost()))
    }

    /// E's call, 2026-09-13: the hold covers alerts too. A celebration behind one is every bit as
    /// invisible, and the app does not present it, so nothing could have tagged it.
    func testTheProbeSeesASwiftUIAlert() async throws {
        try await assertProbeSees(AnyView(AlertHost()))
    }

    /// The other half of E's answer, and the app has several — the focus bar's Stop is one.
    func testTheProbeSeesASwiftUIConfirmationDialog() async throws {
        try await assertProbeSees(AnyView(DialogHost()))
    }

    /// The control: the same host with nothing presented reads clear, so the four above are
    /// detecting the presentation rather than the hosting.
    func testTheProbeReadsClearForTheSameHostWithNothingPresented() async throws {
        try await host(AnyView(NothingHost()))
        XCTAssertFalse(probe.isAnythingPresented)
    }

    // MARK: - Hosting

    private func assertProbeSees(_ view: AnyView, line: UInt = #line) async throws {
        try await host(view)
        let seen = await settle { self.probe.isAnythingPresented }
        XCTAssertTrue(
            seen,
            "SwiftUI seated this presentation somewhere the key-window walk does not reach, so the "
                + "centre holds nothing and every celebration behind it is invisible again.",
            line: line
        )
    }

    private func host(_ view: AnyView) async throws {
        window.rootViewController = UIHostingController(rootView: view)
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        await settle { false }
    }

    /// SwiftUI presents on a later turn of the run loop, so the answer is polled rather than read
    /// once. Returns as soon as the condition holds, and at the deadline otherwise.
    @discardableResult
    private func settle(_ condition: @MainActor () -> Bool) async -> Bool {
        for _ in 0..<40 {
            if condition() { return true }
            await Task.yield()
            _ = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { continuation.resume(returning: true) }
            }
        }
        return condition()
    }

    // MARK: - Hosts
    //
    // `.constant(true)` rather than a state flip: the presentation is up from the first body, so
    // there is no tap to simulate and nothing to wait for but SwiftUI itself.

    private struct NothingHost: View {
        var body: some View { Color.clear }
    }

    private struct SheetHost: View {
        var body: some View {
            Color.clear.sheet(isPresented: .constant(true)) { Text("sheet") }
        }
    }

    private struct CoverHost: View {
        var body: some View {
            Color.clear.fullScreenCover(isPresented: .constant(true)) { Text("cover") }
        }
    }

    private struct AlertHost: View {
        var body: some View {
            Color.clear.alert("alert", isPresented: .constant(true)) { Button("OK") {} }
        }
    }

    private struct DialogHost: View {
        var body: some View {
            Color.clear.confirmationDialog("dialog", isPresented: .constant(true)) {
                Button("OK") {}
            }
        }
    }
}

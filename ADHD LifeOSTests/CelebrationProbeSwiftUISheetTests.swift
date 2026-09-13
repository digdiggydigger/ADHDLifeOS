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
        // **A known-clear baseline, and it is not ceremony.** The probe reads the whole key
        // window, so a presentation left standing by the class that ran before would answer the
        // positive tests here without this file's own host ever presenting anything — and would
        // fail the control for the same reason. Starting from proven-clear means any `true` seen
        // afterwards belongs to this test.
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        try await settle("the window to start clear") { !self.probe.isAnythingPresented }
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
        host(AnyView(NothingHost()))
        // Pumped for as long as a real presentation takes to appear, so "clear" means the probe is
        // reading presentations rather than that nothing has had time to happen. The window was
        // proved clear in `setUp`, so this is the control for all four tests above.
        await pump(0.4)
        XCTAssertFalse(probe.isAnythingPresented)
    }

    // MARK: - Hosting

    private func assertProbeSees(_ view: AnyView, line: UInt = #line) async throws {
        host(view)
        do {
            try await settle("the probe to see the presentation") { self.probe.isAnythingPresented }
        } catch {
            XCTFail(
                "SwiftUI seated this presentation somewhere the key-window walk does not reach, so "
                    + "the centre holds nothing and every celebration behind it is invisible again.",
                line: line
            )
        }
    }

    private func host(_ view: AnyView) {
        window.rootViewController = UIHostingController(rootView: view)
        window.layoutIfNeeded()
    }

    /// SwiftUI presents on a later turn of the run loop, so the answer is polled rather than read
    /// once.
    ///
    /// **Deadline-based, not a fixed iteration count.** The count version budgeted 40 × 20 ms of
    /// wall clock, which is ample on an idle machine and not ample inside a 3,000-test suite —
    /// the sibling composition file timed out once for no better reason than a busier run.
    private func settle(_ what: String, _ condition: @MainActor () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            if condition() { return }
            _ = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { continuation.resume(returning: true) }
            }
        }
        throw ProbeWaitTimeout(what: what)
    }

    /// Turns the run loop for a fixed stretch without asserting anything — for the control, which
    /// is waiting to see that nothing happens.
    private func pump(_ seconds: TimeInterval) async {
        let deadline = Date().addingTimeInterval(seconds)
        while Date() < deadline {
            _ = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { continuation.resume(returning: true) }
            }
        }
    }

    private struct ProbeWaitTimeout: Error, CustomStringConvertible {
        let what: String
        var description: String { "Waited 5 s for \(what) and it never happened." }
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

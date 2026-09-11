//
//  FocusCelebrationModernPathCallSiteTests.swift
//  ADHD LifeOSTests
//
//  F-ModernIOS-2-Celebration — CLAUDE.md §7.4's call-site half, for §7.1's second two-branch
//  exemplar. `FocusCompletionCelebrationMotionTests` proves WHICH mode a celebration resolves to;
//  nothing there proves the view has a floor branch at all. A tick that exists only behind
//  `#available(iOS 26.0, *)` passes every one of those tests and draws NOTHING on iOS 16–25 — the
//  "absent" shape §7.1 forbids for feedback.
//
//  These read ORDER inside a scoped region, not bare presence, and the reason is concrete: the
//  view's own `drawOnAvailable` flag is `if #available(iOS 26.0, *) { return true }` — the gate's
//  string, on a line that draws nothing — and `} else {` is the commonest line in Swift. Bare
//  presence of either would pass on a build that had dropped the floor tick.
//
//  They read the VIEW file by path. The pure types moved to `FocusCompletionCelebrationPose.swift`
//  in this block, and the view kept its name so this path and `FocusCompletionCelebrationCallSiteTests`'
//  stay true.
//

import XCTest
@testable import ADHD_LifeOS

final class FocusCelebrationModernPathCallSiteTests: XCTestCase {

    private static let viewFile = "Focus/FocusCompletionCelebration.swift"

    /// The tick site, in order: the iOS 26 gate — in the SAME condition as the resolved mode, so a
    /// Reduce Motion card never reaches it — the draw-on tick inside it, the `else`, and the floor
    /// tick inside that, scaled and faded off the pose. Scoped to the property the gate opens, so a
    /// `} else {` anywhere else in the file cannot stand in for this one.
    func testTheCelebrationCarriesBothTheModernAndTheFloorBranch() throws {
        let source = try Self.appCode(Self.viewFile)
        guard let gate = source.range(of: "if motion == .modern, #available(iOS 26.0, *) {") else {
            XCTFail(
                "The celebration's tick has no iOS 26 gate conditioned on the resolved mode. Without"
                    + " `motion == .modern` in the same condition, a Reduce Motion user on iOS 26 reaches"
                    + " the draw-on, which does not honour Reduce Motion itself."
            )
            return
        }
        let rest = source[gate.lowerBound...]
        let site = rest[..<(rest.range(of: "\n    }\n")?.lowerBound ?? rest.endIndex)]

        var cursor = site.startIndex
        for (form, meaning) in [
            ("FocusCompletionDrawOnTick(", "the draw-on tick, inside the gate"),
            ("} else {", "the floor branch"),
            (".scaleEffect(pose.checkmarkScale)", "the floor tick's scale, inside the floor branch"),
            (".opacity(pose.checkmarkOpacity)", "the floor tick's fade, inside the floor branch")
        ] {
            guard let found = site.range(of: form, range: cursor..<site.endIndex) else {
                XCTFail(
                    "The celebration's tick site has no `\(form)` where \(meaning) belongs — missing, or"
                        + " out of order. §7.1: a degraded site ships BOTH branches, and a 16–25 phone's"
                        + " celebration IS the floor branch."
                )
                return
            }
            cursor = found.upperBound
        }
    }

    /// The draw-on lives in its own `@available(iOS 26.0, *)` type (§7.1: a modern branch longer
    /// than a few lines), arrives as an INSERTION-ONLY `.drawOn` transition, and no symbol effect
    /// appears anywhere above that declaration — so nothing in the ungated body can reach one.
    ///
    /// `AsymmetricTransition(insertion:removal:)`, not the approved plan's
    /// `.asymmetric(insertion: .symbolEffect(.drawOn), removal: .identity)`, which does not compile
    /// against the 26.5 SDK: `asymmetric` exists only on `AnyTransition`, and the symbol-effect
    /// transition is a `Transition`. Removal is `.identity`, so a Confirm, or `.id(celebrates)`
    /// rebuilding the view, never draws the tick OFF.
    func testTheDrawOnTickSitsBehindTheGateInItsOwnAvailableType() throws {
        let source = try Self.appCode(Self.viewFile)
        let declaration = try XCTUnwrap(
            source.range(of: "@available(iOS 26.0, *)\nprivate struct FocusCompletionDrawOnTick"),
            "The view file has no `@available(iOS 26.0, *)` `FocusCompletionDrawOnTick`, so the iOS 26"
                + " tick is either missing or not isolated in its own gated type."
        )
        let tickType = source[declaration.upperBound...]
        XCTAssertTrue(
            tickType.contains(".symbolEffect(.drawOn"),
            "The iOS 26 tick does not draw itself on — the one thing the tier adds over the floor."
        )
        XCTAssertTrue(
            tickType.contains("AsymmetricTransition(insertion:"),
            "The draw-on is no longer an insertion transition, so the stroke is not tied to the tick's"
                + " arrival — the form whose second-push and Confirm frames were checked for a stray draw."
        )
        XCTAssertTrue(
            tickType.contains("removal: .identity"),
            "The draw-on transition is not insertion-only, so a Confirm or a rebuild draws the tick off."
        )
        XCTAssertFalse(
            source[..<declaration.lowerBound].contains(".symbolEffect("),
            "A symbol effect sits outside the gated type, where Reduce Motion and the floor can reach it."
        )
    }

    /// The two beats, fired from `onAppear` for EVERY armed pose: the halo on block 4's burst
    /// animation in every mode, the tick on the animation its mode resolves, both scaled off the
    /// pose. The guard reads `isArmed` — the old `pose == .armed` recognised only the floor's
    /// opening, so it would leave the Reduce Motion opening frozen with its halo up and no tick.
    func testTheFloorPathIsStillTheTwoBeatBurst() throws {
        let source = try Self.appCode(Self.viewFile)
        for (form, failure) in [
            (
                "guard pose.isArmed else { return }",
                "`onAppear` does not animate every armed pose, so the Reduce Motion opening never fades."
            ),
            (
                "withAnimation(FocusCompletionCelebrationMetrics.burstAnimation)",
                "The halo no longer runs on the burst animation."
            ),
            (
                "withAnimation(FocusCompletionCelebrationMetrics.checkmarkAnimation(for: motion))",
                "The tick's animation is not chosen by the resolved mode, so Reduce Motion still springs."
            ),
            (".scaleEffect(pose.burstScale)", "The halo is not scaled off the pose."),
            (".scaleEffect(pose.checkmarkScale)", "The floor tick is not scaled off the pose.")
        ] {
            XCTAssertTrue(source.contains(form), failure)
        }
        for (form, failure) in [
            (
                "pose == .armed",
                "The celebration still animates only the floor's armed pose; the reduced opening freezes."
            ),
            (
                "withAnimation(FocusCompletionCelebrationMetrics.checkmarkAnimation) {",
                "The tick still lands on one animation for every mode, so Reduce Motion gets the spring."
            )
        ] {
            XCTAssertFalse(source.contains(form), failure)
        }
    }

    // MARK: - Reading the tree

    /// The same source with every comment line removed, because the view's header documents the
    /// ladder in prose that names the very forms asserted above.
    private static func appCode(_ relativePath: String) throws -> String {
        try appSource(relativePath)
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    private static func appSource(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // ADHD LifeOSTests
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("ADHD LifeOS")
            .appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw ModernPathSourceError.unreadable(url.path)
        }
        return text
    }

    /// Loud rather than skipped — a guard that quietly disables itself is the failure mode these
    /// tests exist to prevent.
    private enum ModernPathSourceError: Error, CustomStringConvertible {
        case unreadable(String)

        var description: String {
            switch self {
            case .unreadable(let path):
                return "Could not read \(path). This test reads the tree it was compiled from"
                    + " (`#filePath`)."
            }
        }
    }
}

//
//  ModernAPIPolicyCallSiteTests.swift
//  ADHD LifeOSTests
//
//  F-ModernIOS-1-Policy — `CLAUDE.md` §7.1's worked example, pinned. The policy is "the best
//  available API per site behind `#available`, with a complete iOS 16 branch beside it", and a
//  policy with no test behind it decays back into prose. Until this block §7 read as a ban on
//  anything above the floor and `testTheCelebrationUsesNothingAboveTheiOS16Floor` enforced that
//  reading; E repealed both together (2026-09-11) so the suite never contradicts the house rule.
//
//  The exemplar is `View.haptic(_:trigger:)` because it is the one site in the tree that already
//  had both halves: `.sensoryFeedback` behind the gate and the UIKit performer in the `else`. Every
//  other `#available(iOS 17…)` in the app is a wholesale-ABSENT feature (Places, the routine
//  screen) — an `if` with no `else` — which §7.1 permits for whole features and never for feedback.
//
//  Reads ORDER inside the helper, not bare presence: `} else {` is the commonest line in Swift, and
//  a helper whose floor call drifted out of the `else` would still "contain" every string.
//

import XCTest
@testable import ADHD_LifeOS

final class ModernAPIPolicyCallSiteTests: XCTestCase {

    /// The gate, the modern API inside it, the `else`, then the floor call inside that — in that
    /// order, inside `haptic(_:trigger:)` itself. Drop the `else` and a 16.x phone gets no haptic
    /// at all: the "absent" shape §7.1 reserves for whole features, applied to feedback.
    func testTheHouseHapticHelperIsTheTwoBranchExemplar() throws {
        let source = try Self.appCode("Theme/Haptics.swift")
        let start = try XCTUnwrap(
            source.range(of: "func haptic<"),
            "`View.haptic(_:trigger:)` is gone from `Theme/Haptics.swift`. CLAUDE.md §7.1 names it as"
                + " the two-branch exemplar — move the policy's pointer in the same change."
        )
        let rest = source[start.upperBound...]
        let helper = rest[..<(rest.range(of: "\n    func ")?.lowerBound ?? rest.endIndex)]

        var cursor = helper.startIndex
        for (form, meaning) in [
            ("if #available(iOS 17.0, *) {", "the iOS 17 gate"),
            (".sensoryFeedback(", "the modern API, inside the gate"),
            ("} else {", "the iOS 16 branch"),
            ("Haptics.play(feel)", "the UIKit performer, inside the iOS 16 branch")
        ] {
            guard let found = helper.range(of: form, range: cursor..<helper.endIndex) else {
                XCTFail(
                    "`haptic(_:trigger:)` has no `\(form)` where \(meaning) belongs — missing, or out"
                        + " of order. §7.1: a degraded site ships BOTH branches, and the floor branch"
                        + " carries the same feedback."
                )
                return
            }
            cursor = found.upperBound
        }
    }

    // MARK: - Reading the tree

    /// The same source with every comment line removed, because `Haptics.swift` documents the
    /// split in prose that names the very forms asserted above.
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
            throw PolicySourceError.unreadable(url.path)
        }
        return text
    }

    /// Loud rather than skipped — a guard that quietly disables itself is the failure mode these
    /// tests exist to prevent.
    private enum PolicySourceError: Error, CustomStringConvertible {
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

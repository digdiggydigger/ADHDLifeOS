//
//  ModernAPIPolicyCallSiteTests.swift
//  ADHD LifeOSTests
//
//  F-ModernIOS-1-Policy — `CLAUDE.md` §7.1's worked example, pinned. The policy is "the best
//  available API per site behind `#available`, with a complete floor branch beside it", and a
//  policy with no test behind it decays back into prose. Until that block §7 read as a ban on
//  anything above the floor and `testTheCelebrationUsesNothingAboveTheiOS16Floor` enforced that
//  reading; E repealed both together (2026-09-11) so the suite never contradicts the house rule.
//
//  **REVERSED by `F-Floor18` (E, 2026-09-23: "iOS 18, before F-D2").** The exemplar used to be
//  `View.haptic(_:trigger:)`, the one site with both halves: `.sensoryFeedback` behind an iOS 17
//  gate and the UIKit performer in the `else`. That floor branch is exactly what the block removed
//  — `.sensoryFeedback` (iOS 17) now sits BELOW the 18 floor, so a gate around it would be dead
//  code the compiler never flags (`DeploymentFloorTests` is the tree-wide guard). This file now
//  pins the helper's NEW shape: still the house API §3 prescribes, still gated on Settings at fire
//  time, and with no availability check and no UIKit fallback inside it. §7.1's exemplar pointer
//  moved to the celebration tick (`FocusCelebrationModernPathCallSiteTests`), whose iOS 26 gate
//  and iOS 18–25 `else` are the two-branch shape that remains.
//
//  Reads comment-stripped source, because this file's own history names the forms it asserts
//  are gone.
//

import XCTest
@testable import ADHD_LifeOS

final class ModernAPIPolicyCallSiteTests: XCTestCase {

    /// The helper exists, calls `.sensoryFeedback`, consults the Settings gate — and carries no
    /// `#available` and no `Haptics.play` fallback. A gate reappearing here would compile and run
    /// perfectly on every simulator this project uses while shipping an unreachable branch.
    func testTheHouseHapticHelperIsUngatedSensoryFeedback() throws {
        let source = try Self.appCode("Theme/Haptics.swift")
        let start = try XCTUnwrap(
            source.range(of: "func haptic<"),
            "`View.haptic(_:trigger:)` is gone from `Theme/Haptics.swift`. CLAUDE.md §3 names it as"
                + " the house haptic API — move the pointer in the same change."
        )
        let rest = source[start.upperBound...]
        let helper = rest[..<(rest.range(of: "\n    func ")?.lowerBound ?? rest.endIndex)]

        XCTAssertTrue(
            helper.contains("sensoryFeedback(feel.sensoryFeedback, trigger: trigger)"),
            "`haptic(_:trigger:)` no longer calls `.sensoryFeedback` with the feel's mapping and"
                + " the caller's trigger."
        )
        XCTAssertTrue(
            helper.contains("AppFeedback.hapticsEnabled()"),
            "`haptic(_:trigger:)` no longer consults the Settings gate at fire time, so switching"
                + " haptics off in Settings would not silence state-driven feedback."
        )
        for form in ["#available(", "} else {", "Haptics.play(feel)"] {
            XCTAssertFalse(
                helper.contains(form),
                "`haptic(_:trigger:)` carries `\(form)` again. The UIKit floor branch was removed by"
                    + " F-Floor18: `.sensoryFeedback` is iOS 17 and the floor is 18, so the branch"
                    + " can never run and the compiler will never say so."
            )
        }
    }

    /// The whole file, not just the helper: `HapticFeel.sensoryFeedback` used to sit in an
    /// `@available(iOS 17.0, *)` extension of its own.
    func testTheHapticsFileCarriesNoAvailabilityCheck() throws {
        let source = try Self.appCode("Theme/Haptics.swift")
        XCTAssertFalse(
            source.contains("available(iOS"),
            "`Theme/Haptics.swift` names an iOS version in an availability check. Nothing in it"
                + " needs one at the 18 floor (F-Floor18)."
        )
    }

    // MARK: - Reading the tree

    /// The same source with every comment line removed, because `Haptics.swift` documents the
    /// history of the split in prose that names the very forms asserted absent above.
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

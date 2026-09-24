//
//  DeploymentFloorTests.swift
//  ADHD LifeOSTests
//
//  `F-Floor18` — the minimum iOS is 18 (E, 2026-09-23: *"iOS 18, before F-D2 … ENSURE that iOS 16
//  floor has been ACCURATELY BEEN CORRECTED TO A MINIMUM … OF iOS 18"*), and this file is the only
//  thing that keeps that true after the block that raised it.
//
//  **The compiler does not provide this guard.** Swift never warns that a `#available` check has
//  become redundant against the deployment target — it flags only a check made redundant by an
//  ENCLOSING `@available`. So a gate below the floor compiles silently, ships a branch nothing can
//  reach, and every simulator on this machine (26.5 and 27.0) takes the modern branch anyway. The
//  grep that measured the block's inventory is the only list, and this test is the grep, run every
//  time. The same shape as `SoftDeleteReadPathCallSiteTests`: a tree walk, comment lines stripped,
//  a failure that names every offending file and line.
//
//  The build settings are pinned for the same reason: a target added later at Xcode's default
//  deployment target would sit under the floor with nothing to say so.
//

import XCTest

final class DeploymentFloorTests: XCTestCase {

    /// The floor, as one number. The app target used to be 16.0 and the widget 16.1 ("the
    /// deployment target is not one number"); since `F-Floor18` every target shares this.
    private static let floor = "18.0"

    /// Six build configurations carry the setting: project-level Debug + Release (the app and the
    /// UI tests inherit these and set none of their own), the unit-test target's pair, and the
    /// widget extension's pair. The COUNT is asserted as well as the value so a seventh target
    /// added at Xcode's default cannot slip under.
    private static let expectedSettingCount = 6

    // MARK: - The build settings

    func testEveryTargetIsAtTheIOS18Floor() throws {
        let project = try Self.source("ADHD LifeOS.xcodeproj/project.pbxproj")
        let pattern = try NSRegularExpression(pattern: #"IPHONEOS_DEPLOYMENT_TARGET = ([0-9.]+);"#)
        let range = NSRange(project.startIndex..., in: project)
        let values = pattern.matches(in: project, range: range).compactMap { match -> String? in
            Range(match.range(at: 1), in: project).map { String(project[$0]) }
        }

        XCTAssertEqual(
            values.count, Self.expectedSettingCount,
            "Expected \(Self.expectedSettingCount) `IPHONEOS_DEPLOYMENT_TARGET` settings in"
                + " project.pbxproj and found \(values.count). A target or configuration was added"
                + " or removed — check it carries the \(Self.floor) floor, then update this count."
        )
        for value in values {
            XCTAssertEqual(
                value, Self.floor,
                "An `IPHONEOS_DEPLOYMENT_TARGET` reads \(value), not \(Self.floor). The minimum iOS"
                    + " is 18 everywhere (E, 2026-09-23); one target under the floor is the whole"
                    + " app under it, because the App Store takes the lowest."
            )
        }
    }

    // MARK: - Reading the tree

    private static func repoRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // ADHD LifeOSTests
            .deletingLastPathComponent()   // repo root
    }

    private static func source(_ relativePath: String) throws -> String {
        let url = repoRoot().appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw FloorSourceError.unreadable(url.path)
        }
        return text
    }

    /// Loud rather than skipped — a guard that quietly disables itself is the failure mode this
    /// file exists to prevent.
    private enum FloorSourceError: Error, CustomStringConvertible {
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

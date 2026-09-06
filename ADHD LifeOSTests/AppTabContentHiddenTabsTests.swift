//
//  AppTabContentHiddenTabsTests.swift
//  ADHD LifeOSTests
//
//  The tab-root "not hittable" defect (register B3, chased across 60+ probe rounds), finally
//  caught with its state on 2026-09-06 by the routine-record journey: the accessibility tree
//  at the failure listed the HIDDEN Today tab's elements beside the visible Tools tab's, and
//  Today's momentum ring sat exactly over the Places card's centre. `accessibilityHidden` is
//  applied to every hidden tab and does not reach them, because each tab is a `NavigationStack`
//  — a UIKit navigation controller underneath — and the SwiftUI flag stops at that boundary.
//  XCUITest's hit-test then resolves the point to the hidden tab and refuses the tap; which
//  tabs were visited, and where their content rests, is why the failing set shuffled.
//
//  The fix is geometric, which no flag can be argued past: a hidden tab is moved clear off the
//  screen, so no point on it can resolve to anything of a hidden tab's.
//

import XCTest
@testable import ADHD_LifeOS

final class AppTabContentHiddenTabsTests: XCTestCase {

    func testHiddenTabsAreMovedOffScreen() throws {
        let source = try Self.code("AppTabContent.swift")

        XCTAssertTrue(
            source.contains(".offset(x: tab == selection ? 0 : AppTabContentLayout.hiddenTabOffset)"),
            "a hidden tab must be OFF-SCREEN, not merely transparent: its UIKit-hosted subtree"
                + " stays in the accessibility tree and steals hit-tests from the visible tab"
        )
        XCTAssertTrue(
            source.contains(".accessibilityHidden(tab != selection)"),
            "and still hidden from VoiceOver — the offset is for hit-testing, the flag for reading"
        )
    }

    func testTheOffsetClearsAnyScreenWidth() {
        XCTAssertGreaterThanOrEqual(
            AppTabContentLayout.hiddenTabOffset, 10_000,
            "wider than any device, in either orientation, with room for a scrolled-out width"
        )
    }

    private static func code(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ADHD LifeOS")
            .appendingPathComponent(relativePath)
        guard let source = try? String(contentsOf: url, encoding: .utf8) else {
            throw SourceError.unreadable(url.path)
        }
        var output = ""
        var index = source.startIndex
        while index < source.endIndex {
            if source[index...].hasPrefix("//") {
                while index < source.endIndex, source[index] != "\n" {
                    index = source.index(after: index)
                }
            } else {
                output.append(source[index])
                index = source.index(after: index)
            }
        }
        return output
    }

    private enum SourceError: Error, CustomStringConvertible {
        case unreadable(String)
        var description: String {
            switch self {
            case .unreadable(let path): return "Could not read \(path)."
            }
        }
    }
}

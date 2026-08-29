//
//  CaptureDiscClearanceCallSiteTests.swift
//  ADHD LifeOSTests
//
//  A CALL-SITE test, which is unusual here and deliberate.
//
//  This repo's most repeated defect has one shape: a shared helper is written, documented and
//  unit-tested, and then no view calls it while views hand-roll drifting copies. Three shipped
//  bugs had exactly that shape before 2026-08-29, and `CaptureDiscMetrics.clearance` was the
//  fourth — it said in its own doc comment that ANY bottom-of-scroll content lands under the
//  capture disc, and two screens out of ten called it.
//
//  A test over pure types cannot see that: the helper is correct in every one of those bugs.
//  A SwiftUI body is not reachable from XCTest either. So this reads the SOURCE, which is the
//  layer the claim actually lives in.
//
//  It does not catch a brand-new screen added without the modifier — that would need a classifier
//  over every file, and a list of ten screens that is wrong loudly beats a classifier that is
//  wrong quietly. The geometry itself is asserted on two representative screens by
//  `CaptureDiscClearanceUITests`.
//

import XCTest

final class CaptureDiscClearanceCallSiteTests: XCTestCase {

    /// Every screen that renders INSIDE the `TabView` the capture disc overlays — the five tab
    /// roots and everything pushed into their navigation stacks. Sheets and full-screen covers
    /// are deliberately absent: they are presented ABOVE the disc and hide it entirely.
    ///
    /// `Journal/JournalTimelineSections.swift` is absent for a measured reason, not an oversight:
    /// the Journal's composer bar is a `safeAreaInset(edge: .bottom)` that already occupies the
    /// disc's band, and it carries the TRAILING half of the same clearance
    /// (`JournalView.captureDiscClearance`). Adding the vertical form on top would open a dead
    /// 84pt gap under a screen that has been through six colour and layout passes.
    ///
    /// `LifeAreaEditor/LifeAreaEditorListView.swift` is absent for a different one: it is pushed
    /// from Areas (under the disc) AND from Settings (a sheet, above it), so the clearance is a
    /// property of the PRESENTATION, not of the screen — `AreasView` applies it at its call site.
    private static let screensUnderTheDisc = [
        "Home/HomeView.swift",
        "Home/WeekReviewView.swift",
        "Tasks/TaskListView.swift",
        // The task detail screen's `Form` lives in the sections file, not the primary one — that
        // split happened in this same block, and this test caught the stale entry.
        "Tasks/TaskDetailFormSections.swift",
        "Areas/AreasView.swift",
        "Nudges/NudgesView.swift",
        "Capture/CaptureInboxView.swift",
        "Capture/CaptureDetailView.swift",
        "LifeAreaDetail/LifeAreaDetailView.swift"
    ]

    func testEveryScreenUnderTheCaptureDiscCallsTheSharedClearance() throws {
        let missing = try Self.screensUnderTheDisc.filter { relativePath in
            try !Self.appSource(relativePath).contains(".captureDiscClearance()")
        }
        XCTAssertEqual(
            missing, [],
            "These screens render under the capture disc and never call `.captureDiscClearance()`,"
                + " so their last row sits under an opaque 60pt circle with nothing below it to"
                + " scroll to. Either add the modifier or move the file out of"
                + " `screensUnderTheDisc` with the reason."
        )
    }

    /// The vertical clearance has exactly ONE implementation.
    ///
    /// `padding(.bottom, CaptureDiscMetrics.clearance)` was the hand-rolled form, on one screen,
    /// while nine others had nothing. A second spelling is how the next drift starts, so it is
    /// spelled once — inside the modifier — and nowhere else.
    func testNoScreenHandRollsTheBottomClearance() throws {
        let handRolled = try Self.allAppSources()
            .filter { $0.path.lastPathComponent != "Theme.swift" }
            .filter { $0.text.contains("padding(.bottom, CaptureDiscMetrics.clearance)") }
            .map { $0.path.lastPathComponent }
            .sorted()
        XCTAssertEqual(
            handRolled, [],
            "These files spell the bottom clearance out by hand instead of calling"
                + " `.captureDiscClearance()`. One helper, one spelling — see this file's header."
        )
    }

    /// The trailing form is a different measurement with a different fix (a pinned bar's controls
    /// sitting under the disc, not a scroll's last row), so it stays a direct read of the metric.
    /// Asserted here only so the two never collapse into one another unnoticed.
    func testTrailingClearanceStillReadsTheMetricDirectly() throws {
        let trailing = try Self.allAppSources()
            .filter { $0.text.contains("padding(.trailing, CaptureDiscMetrics.clearance)") }
            .map { $0.path.lastPathComponent }
            .sorted()
        XCTAssertEqual(
            trailing, ["CaptureInboxSections.swift"],
            "The trailing clearance moved. It lifts a PINNED BAR's controls out from under the"
                + " disc — `JournalView` names its own copy `captureDiscClearance` — and is not"
                + " interchangeable with the bottom form."
        )
    }

    // MARK: - Reading the tree

    /// The repo root, derived from this file's own compile-time path — the same trick that lets a
    /// test assert about files rather than about values.
    private static var appRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // ADHD LifeOSTests
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("ADHD LifeOS")
    }

    private static func appSource(_ relativePath: String) throws -> String {
        let url = appRoot.appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw ClearanceSourceError.unreadable(url.path)
        }
        return text
    }

    private static func allAppSources() throws -> [(path: URL, text: String)] {
        guard let walker = FileManager.default.enumerator(
            at: appRoot, includingPropertiesForKeys: nil
        ) else {
            throw ClearanceSourceError.unreadable(appRoot.path)
        }
        let swiftFiles = walker.compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" }
        guard !swiftFiles.isEmpty else { throw ClearanceSourceError.unreadable(appRoot.path) }
        return try swiftFiles.map { url in
            guard let text = try? String(contentsOf: url, encoding: .utf8) else {
                throw ClearanceSourceError.unreadable(url.path)
            }
            return (url, text)
        }
    }

    /// Loud rather than skipped. A source tree this test cannot read is a broken guard, and a
    /// guard that quietly disables itself is the failure mode these tests exist to prevent.
    private enum ClearanceSourceError: Error, CustomStringConvertible {
        case unreadable(String)

        var description: String {
            switch self {
            case .unreadable(let path):
                return "Could not read the app sources at \(path)."
                    + " This test reads the tree it was compiled from (`#filePath`)."
            }
        }
    }
}

//
//  LifeAreasWidgetCopyTests.swift
//  ADHD LifeOSTests
//
//  The Life Areas widget's copy, read from SOURCE — the view compiles only into the widget
//  extension, which the unit target deliberately does not link (the static-product rule), so
//  a type-level copy test cannot reach it.
//

import XCTest

final class LifeAreasWidgetCopyTests: XCTestCase {

    /// E's word, picked 2026-09-07 (register B2): the app is LifeOS on every other surface, and
    /// this signed-out empty state was the last line still calling it Momentum — caught by the
    /// widget-fold device evidence (`screenshots/widget-session-fold/01-…`).
    func testTheEmptyStateNamesTheAppLifeOS() throws {
        let widget = try Self.widgetSource("LifeAreasWidget.swift")

        XCTAssertTrue(
            widget.contains("Open LifeOS once and your areas will appear here."),
            "the signed-out empty state must name the app the way every other surface does"
        )
        XCTAssertFalse(
            widget.contains("Open Momentum once"),
            "the stale name must be GONE, not merely joined by the new line"
        )
    }

    // MARK: - Reading the tree

    private static func widgetSource(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // ADHD LifeOSTests
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("FocusTimerWidget")
            .appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw WidgetSourceError.unreadable(url.path)
        }
        return text
    }

    private enum WidgetSourceError: Error, CustomStringConvertible {
        case unreadable(String)

        var description: String {
            switch self {
            case .unreadable(let path): return "could not read \(path)"
            }
        }
    }
}

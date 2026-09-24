//
//  ComposerKeyboardBarCallSiteTests.swift
//  ADHD LifeOSTests
//
//  `F-D2-ComposerKeyboardLayout`: round 7b's L3, asserted by reading the tree.
//
//  E, round 7b: *"L3 · Rides on the keyboard. The title owns the page. Every choice and Add sit in
//  one bar just above the keyboard: the four 'when' segments on top; Area | Time | Add below, with
//  Add trailing."* And the Date segment: *"Text, then the date."*
//
//  **Every claim here fails SILENTLY in a behaviour test.** Where the bar is mounted, whether its
//  container has a floor branch at all, whether the date picker is a popover or a sheet, whether a
//  time is offered — each is a fact about the source that compiles, runs and passes every other
//  test when it is wrong. `ComposerKeyboardBarUITests` owns the one claim only a running app can
//  make: that opening a choice leaves the keyboard up.
//

import XCTest
@testable import ADHD_LifeOS

final class ComposerKeyboardBarCallSiteTests: XCTestCase {

    private static let view = "Tasks/TaskCreateView.swift"
    private static let bar = "Tasks/TaskComposerKeyboardBar.swift"
    private static let controls = "Tasks/TaskComposerControls.swift"

    // MARK: - The bar rides the keyboard

    /// **Through `safeAreaInset(edge: .bottom)`** — findings §L: "SwiftUI's keyboard avoidance
    /// lifts it on every OS", which makes it the floor path. And never through the `.keyboard`
    /// toolbar placement, which "is a single row, too small for L3's two".
    func testTheBarRidesTheKeyboardThroughTheBottomInset() throws {
        // The line that opens the bar must sit directly inside a bottom inset. Two insets exist
        // (the stacked form pins Add in one), so "the first inset contains the bar" would be a
        // statement about file order, not about the bar.
        let lines = try Self.appCode(Self.view)
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        let barLine = try XCTUnwrap(
            lines.firstIndex { $0.hasPrefix("TaskComposerKeyboardBar(") },
            "The composer never builds the keyboard bar"
        )
        XCTAssertEqual(
            lines[barLine - 1], ".safeAreaInset(edge: .bottom) {",
            "The keyboard bar is not the content of a bottom safe-area inset"
        )
        for file in [Self.view, Self.bar, Self.controls] {
            XCTAssertFalse(
                try Self.appCode(file).contains("placement: .keyboard"),
                "\(file) puts composer controls in the one-row `.keyboard` toolbar"
            )
        }
    }

    /// **Both branches, in order, scoped to the container.** §7.1: a degraded site ships a complete
    /// floor branch beside the modern one — here Liquid Glass on 26+ (`virtual-keyboards.md ›
    /// Mobile`: "apply Liquid Glass to the view that contains your controls") and the bar material
    /// every other composer footer already wears on 18–25. §7.4: a test that asserted only the
    /// gate would stay green on a build that dropped the floor.
    func testTheBarsContainerCarriesBothTheGlassAndTheFloorBranch() throws {
        let source = try Self.appCode(Self.bar)
        guard let gate = source.range(of: "if #available(iOS 26.0, *) {") else {
            XCTFail("The keyboard bar's container has no iOS 26 gate")
            return
        }
        let rest = source[gate.lowerBound...]
        let site = rest[..<(rest.range(of: "\n    }\n")?.lowerBound ?? rest.endIndex)]
        var cursor = site.startIndex
        for (form, meaning) in [
            (".glassEffect(", "the Liquid Glass container, inside the gate"),
            ("} else {", "the floor branch"),
            (".background(.bar", "the floor's bar material, inside the floor branch"),
            (".strokeBorder(Color.cardBorder", "the floor's hairline edge, inside the floor branch")
        ] {
            guard let found = site.range(of: form, range: cursor..<site.endIndex) else {
                XCTFail("The bar's container has no `\(form)` where \(meaning) belongs — missing, or out of order")
                return
            }
            cursor = found.upperBound
        }
    }

    // MARK: - The Date segment

    /// **E's Step 0 answer, 2026-09-24: date only.** The popover offers a day — a precise time is the
    /// detail screen's — and it is a popover, never a sheet (Q4, "maximum one sheet deep"), which
    /// `presentationCompactAdaptation(.popover)` guarantees on iPhone at the 18 floor.
    func testTheDatePickerOffersADayInAPopoverNeverASheet() throws {
        let controls = try Self.appCode(Self.controls)
        XCTAssertTrue(controls.contains("displayedComponents: [.date]"), "The composer's picker does not offer a day")
        XCTAssertFalse(controls.contains(".hourAndMinute"), "The composer's picker still offers a time")
        XCTAssertTrue(controls.contains(".popover(isPresented:"), "The date picker is not a popover")
        XCTAssertTrue(
            controls.contains(".presentationCompactAdaptation(.popover)"),
            "The popover adapts to a sheet on iPhone — a second sheet on top of the composer"
        )
        for file in [Self.view, Self.bar, Self.controls] {
            let source = try Self.appCode(file)
            XCTAssertFalse(source.contains(".sheet("), "\(file) presents a sheet from inside the composer")
            XCTAssertFalse(source.contains(".fullScreenCover("), "\(file) presents a cover from inside the composer")
        }
    }

    /// **Text only, then the date.** Findings §L: `segmented-controls.md › Content`, "either text or
    /// images — not a mix"; and the label comes from `segmentTitle`, which is what turns "Date" into
    /// "Fri 26" once a day is picked.
    func testTheDateSegmentIsTextOnlyAndShowsThePickedDay() throws {
        let controls = try Self.appCode(Self.controls)
        XCTAssertFalse(controls.contains("\"calendar\""), "The Date segment still carries a calendar glyph")
        XCTAssertTrue(controls.contains(".segmentTitle("), "The segments do not read their label from `segmentTitle`")
    }

    /// **The selection recolours in place — no sliding indicator.** That is the decision that keeps
    /// this block free of a Reduce Motion site (§7.2): a `matchedGeometryEffect` slide would be an
    /// "appears/moves" site owing a fade and an RM-on device pass (§7.3).
    func testTheSegmentsRecolourInPlace() throws {
        for file in [Self.bar, Self.controls] {
            XCTAssertFalse(
                try Self.appCode(file).contains("matchedGeometryEffect"),
                "\(file) slides the selection — that is a Reduce Motion site this block did not plan"
            )
        }
    }

    /// **E, 2026-09-24: "Let it settle."** On iOS 27 opening a choice puts the keyboard down, and
    /// E chose to let the bar rest at the bottom rather than re-focus the title, which would bring
    /// the keyboard back and the bar with it on every choice (research §3.2's drop-and-jump). So
    /// the composer must hold no focus state it could re-assert.
    func testAChoiceLetsTheBarSettleRatherThanBouncingBack() throws {
        for file in [Self.view, Self.bar, Self.controls] {
            let source = try Self.appCode(file)
            XCTAssertFalse(source.contains("@FocusState"), "\(file) holds focus state it could re-assert")
            XCTAssertFalse(source.contains(".focused("), "\(file) binds the title's focus")
        }
    }

    // MARK: - Accessibility sizes

    /// **L1's stacked form at accessibility sizes** — carried in the option E chose: "At AX3 the bar
    /// cannot share the screen with the keyboard ... the choices scroll under the title and Add
    /// stays pinned." The boxed title is L1's (the board's AX3 column).
    func testAccessibilitySizesFallBackToTheStackedForm() throws {
        let view = try Self.appCode(Self.view)
        XCTAssertTrue(
            view.contains("usesStackedForm(at: typeSize)"), "The composer never chooses its layout by text size"
        )
        XCTAssertTrue(view.contains("TaskComposerKeyboardBar("), "The composer lost the keyboard bar")
        XCTAssertTrue(view.contains("ComposerTextBox("), "The stacked form lost L1's boxed title")
        XCTAssertTrue(
            view.contains("TaskComposerAddButton(service: service, compact: false"),
            "The stacked form has no pinned full-width Add"
        )
    }

    // MARK: - Reading the tree

    private static func appCode(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ADHD LifeOS")
            .appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw SourceError.missing(url.path)
        }
        return text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    private enum SourceError: Error, CustomStringConvertible {
        case missing(String)

        var description: String {
            switch self {
            case .missing(let what): return "Could not find \(what) in the tree this test was compiled from."
            }
        }
    }
}

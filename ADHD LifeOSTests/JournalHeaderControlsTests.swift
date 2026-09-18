//
//  JournalHeaderControlsTests.swift
//  ADHD LifeOSTests
//
//  `F-JournalDoorUnpinned` (E's option 04, 2026-09-18): the pinned "One line about today…" bar is
//  gone, so the header pencil is the Journal's ONLY door to a new entry — and it was a 40pt circle,
//  under §3's 44pt floor. A SwiftUI body cannot be measured from XCTest, so the geometry is held
//  the house way: the size is a named metric whose VALUE is asserted here, and the controls are
//  read from SOURCE to prove they are sized by it (the `FocusBarCollapseCallSiteTests` shape).
//  Either half alone is the repo's most repeated defect: a correct metric nothing reads.
//
//  **REVERSED 2026-09-18 (`F-JournalPencilDisc`), and the history is the point.** Block 1 grew both
//  header circles 40 → 44 through `JournalHeaderMetrics.controlSize`. Step 0 then put the filled
//  pencil in a toolbar in front of E, and E moved it: *"move the filled pencil icon disc down to
//  the left-hand side of the FAB Icon. make the filled pencil disc inline with the FAB icon"*,
//  **"Keep the nav bar"** (the large title, the eye ALONE top right), and a **42pt** disc — *"decrease
//  the size of the filled pencil disc from 48pt to 42pt"*. So neither control is a header circle
//  any more, `JournalHeaderMetrics` is DELETED (nothing read it once both left — the dead-component
//  pattern), and the three tests below are block 1's three, turned to what E chose.
//

import XCTest
@testable import ADHD_LifeOS

final class JournalHeaderControlsTests: XCTestCase {

    /// §3: every touch target is at least 44 × 44.
    ///
    /// *Reversed 2026-09-18: was `testTheHeaderControlsMeetTheTouchFloor`, which held
    /// `JournalHeaderMetrics.controlSize` ≥ 44 as a real frame.* The pencil is now E's 42pt disc in
    /// the capture disc's row, which a real 44pt frame would move — the 16pt gap and the shared
    /// centre line are E's too. So it takes the house `AppTabBarMetrics.slotHitOverflow` shape
    /// instead: the LAYOUT stays 42 and the hit shape reaches 44. The eye needs no number here: it
    /// is a system toolbar item, whose target is the system's.
    func testThePencilDiscsTargetMeetsTheTouchFloorWhileItsLayoutStaysEsNumber() {
        XCTAssertEqual(
            JournalComposeDiscMetrics.diameter, 42,
            "E's number for the pencil disc — 48 first, then *\"decrease … from 48pt to 42pt\"*."
        )
        XCTAssertEqual(
            JournalComposeDiscMetrics.hitOverflow,
            max(0, (AppTabBarPresentation.minimumTouchTarget - JournalComposeDiscMetrics.diameter) / 2),
            "The overflow is §3's shortfall shared between both sides, as `slotHitOverflow` spells it."
        )
        XCTAssertGreaterThanOrEqual(
            JournalComposeDiscMetrics.diameter + 2 * JournalComposeDiscMetrics.hitOverflow,
            AppTabBarPresentation.minimumTouchTarget,
            "The pencil disc — the Journal's ONLY door to a new entry — takes taps under §3's 44pt."
        )
    }

    /// *Reversed 2026-09-18: was `testBothHeaderCirclesAreSizedByTheSharedMetric`.* The two
    /// circles were one family in the drawn header; E kept the nav bar instead, with the eye alone
    /// in its toolbar, so the claim now is that the SYSTEM bar is back and the eye lives in it.
    func testTheEyeLivesAloneInTheRestoredNavigationBar() throws {
        let view = try Self.code("Journal/JournalView.swift")
        for anchor in [
            ".navigationTitle(\"Journal\")",
            ".navigationBarTitleDisplayMode(.large)",
            "ToolbarItem(placement: .topBarTrailing)",
            "JournalAllActivityButton(isOn: $showAllActivity)"
        ] {
            XCTAssertTrue(
                view.contains(anchor), "JournalView no longer carries `\(anchor)` — E's \"Keep the nav bar\"."
            )
        }
        XCTAssertFalse(
            view.contains(".toolbar(.hidden, for: .navigationBar)"),
            "The Journal hides its navigation bar again, so the large title and the eye are gone."
        )
        XCTAssertFalse(
            view.contains("Text(\"Journal\")"),
            "The header draws its own \"Journal\" beside the system's large title — two titles."
        )
        XCTAssertFalse(
            view.contains("square.and.pencil"),
            "A pencil is still drawn in the Journal's content. E moved it beside the + disc."
        )
        let eye = try Self.code("Journal/JournalAllActivityButton.swift")
        XCTAssertFalse(
            eye.contains("Circle()"),
            "The eye still draws its own circle. In the toolbar the system draws its chrome (a glass"
                + " circle on 26+); a hand-drawn one would sit inside it."
        )
    }

    /// *Reversed 2026-09-18: was `testThePencilStillOpensTheComposer`, which found the pencil's
    /// `Button` in the header.* The disc lives in the root overlay now, outside `JournalView`, so
    /// its tap cannot reach the private `isPresentingComposer` directly: it travels DOWN as a count
    /// the Journal watches — the re-tap's own shape (`TabNavigationCoordinator.reselect`). All three
    /// hops are pinned, because any one missing is a door that opens nothing.
    func testThePencilDiscOpensTheComposerThroughTheRequest() throws {
        let root = try Self.flattened("RootView.swift")
        XCTAssertTrue(
            root.contains("onWriteEntry: { tabNavigation.requestJournalEntry() }"),
            "RootView never routes the pencil disc's tap into the coordinator, so it opens nothing."
        )
        XCTAssertTrue(
            try Self.flattened("TabNavigation.swift").contains(".onChange(of: coordinator.journalEntryRequests)"),
            "The Journal's listener does not watch the coordinator's request count, so it hears nothing."
        )
        let view = try Self.flattened("Journal/JournalView.swift")
        guard let listener = view.range(of: ".onJournalEntryRequest {") else {
            return XCTFail("JournalView never listens for the pencil disc's request.")
        }
        let tail = view[listener.upperBound...]
        let closing = tail.range(of: "}")?.lowerBound ?? tail.endIndex
        XCTAssertTrue(
            tail[..<closing].contains("isPresentingComposer = true"),
            "JournalView hears the request and does not present the composer."
        )
        let disc = try Self.code("Journal/JournalComposeDisc.swift")
        XCTAssertTrue(
            disc.contains(".accessibilityIdentifier(\"journalComposeButton\")"), "The journeys find the door by this."
        )
        XCTAssertTrue(disc.contains(".accessibilityLabel(\"Write an entry\")"))
    }

    /// E's **"B (Recommended)"**: the eye OFF in the LABEL colour — black in light, white in dark,
    /// as E saw it in (b) — and ON in accent. Spelled explicitly, because Step 0 measured that the
    /// DEFAULT differs by tier: label colour on 26/27, accent below 26, where an OFF eye would read ON.
    /// Not `.secondary` and not `LabelSecondary`: that was the old circle's quiet glyph, not E's B.
    func testTheEyesOffStyleIsTheLabelColourAndItsOnStyleIsAccent() throws {
        let eye = try Self.code("Journal/JournalAllActivityButton.swift")
        XCTAssertTrue(
            eye.contains(".foregroundStyle(isOn ? Color.accentColor : Color.primary)"),
            "The eye's colours are not E's B — OFF in the label colour, ON in accent."
        )
        XCTAssertFalse(eye.contains("LabelSecondary"), "The OFF eye is quiet grey again, not E's label colour.")
        XCTAssertFalse(eye.contains(".secondary"), "The OFF eye is `.secondary`, not E's label colour.")
        for kept in ["Haptics.play(.light)", ".accessibilityLabel(\"All activity\")", ".isSelected"] {
            XCTAssertTrue(eye.contains(kept), "The eye lost `\(kept)` — only its chrome was meant to change.")
        }
    }

    // MARK: - Reading the tree

    private static var appRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // ADHD LifeOSTests
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("ADHD LifeOS")
    }

    /// The same code on one line, each line trimmed and joined by a single space, so an anchor
    /// does not have to know how a call was wrapped.
    private static func flattened(_ relativePath: String) throws -> String {
        try code(relativePath)
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: " ")
    }

    /// The source with `//` comments stripped, so a doc comment that NAMES a pattern — the history
    /// these files keep on purpose — can never satisfy or trip an assertion about code.
    private static func code(_ relativePath: String) throws -> String {
        let url = appRoot.appendingPathComponent(relativePath)
        let source = try String(contentsOf: url, encoding: .utf8)
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
}

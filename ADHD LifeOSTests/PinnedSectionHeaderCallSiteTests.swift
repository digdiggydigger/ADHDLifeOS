//
//  PinnedSectionHeaderCallSiteTests.swift
//  ADHD LifeOSTests
//
//  Reachability for the shared pinned-header treatment.
//
//  `PinnedSectionHeaderTests` proves the treatment is the right one. It cannot prove anybody uses
//  it — and a shared helper that nothing calls, while screens hand-roll drifting copies, is this
//  repo's most repeated defect (six instances and counting). The whole point of F-Tools-4-Headers
//  was ONE treatment so a future screen cannot invent its own, which is a claim about call sites.
//
//  **Comment lines are stripped before searching, and that is a scar from the block before this
//  one.** `ToolsPageCallSiteTests` shipped a guard that stayed green on a broken tree because the
//  doc comment written in the same commit contained the string it searched for. `Theme.swift`'s
//  own documentation quotes `.background(.bar)` while explaining why it is gone — searching the
//  raw text would report the defect as still present, and searching for its absence elsewhere
//  would be satisfiable by prose. Assertions here are about CODE.
//

import XCTest

final class PinnedSectionHeaderCallSiteTests: XCTestCase {

    /// Every screen with a sticky list, and the fact that it uses the shared treatment.
    private static let screensWithPinnedHeaders = [
        "Tasks/TaskListView.swift",
        "Places/PlaceAppPickerView.swift"
    ]

    func testEveryPinnedHeaderUsesTheSharedTreatment() throws {
        let missing = try Self.screensWithPinnedHeaders.filter { path in
            try !Self.appCode(path).contains(".pinnedSectionHeader()")
        }
        XCTAssertEqual(
            missing, [],
            "These screens pin section headers and do not use `pinnedSectionHeader()`, so each is"
                + " free to drift into its own chrome — which is exactly how the app ended up"
                + " with a near-white `.bar` strip on rounded cards."
        )
    }

    /// The other direction, and the one a name search cannot do: **find the SHAPE**, not the
    /// name. A hand-rolled copy never mentions the helper, so it is caught by what it does —
    /// painting a background onto a header — not by what it is called.
    func testNoScreenHandRollsAHeaderBackground() throws {
        let handRolled = try Self.allAppCode()
            // The one deliberate `.bar` in the app: `ComposerFooterSurface`, the PINNED BOTTOM
            // BAR's surface. It is a different job with a different answer — E's 2026-08-25
            // review asked for the boundary between scrolling content and a fixed footer to be
            // VISIBLE, which is the opposite of what a header wants — so it keeps the material
            // and its hairline top edge.
            .filter { $0.name != "ComposerChips.swift" }
            .filter { $0.code.contains("background(.bar)") }
            .map(\.name)
            .sorted()
        XCTAssertEqual(
            handRolled, [],
            "These files paint `.bar` behind something themselves. If it is a pinned header, use"
                + " `pinnedSectionHeader()`; if it is a footer bar, use `composerFooterSurface()`."
        )
    }

    /// A sticky list is the state the treatment exists for, so a NEW one must not appear without
    /// this list growing. It is the `CaptureDiscClearanceCallSiteTests` posture, and for its
    /// stated reason: a list of screens that is wrong loudly beats a classifier that is wrong
    /// quietly.
    func testNoUnknownScreenPinsItsOwnSectionHeaders() throws {
        let pinning = try Self.allAppCode()
            .filter { $0.code.contains("pinnedViews: [.sectionHeaders]") }
            .map(\.name)
            .sorted()
        let known = Self.screensWithPinnedHeaders
            .map { ($0 as NSString).lastPathComponent }
            .sorted()
        XCTAssertEqual(
            pinning, known,
            "A screen pins section headers that this test does not know about. Add it to"
                + " `screensWithPinnedHeaders` — and check it adopted `pinnedSectionHeader()`"
                + " rather than inventing a header of its own."
        )
    }

    /// The treatment has ONE home. A second copy in a feature folder is how the app ends up with
    /// two spellings that disagree six weeks later — `cardEdges()` is already file-private in
    /// `PlaceAppPickerView` while `TaskListView` hand-rolls the identical card, which is the same
    /// story one turn earlier.
    func testTheTreatmentIsDefinedOnlyInTheThemeLayer() throws {
        let definitions = try Self.allAppCode()
            .filter { $0.code.contains("func pinnedSectionHeader()") }
            .map(\.name)
            .sorted()
        XCTAssertEqual(
            definitions, ["Theme.swift"],
            "`pinnedSectionHeader()` is declared outside the theme layer. One treatment means one"
                + " definition, beside `sectionLabel()` and `bentoCard()`."
        )
    }

    // MARK: - Reading the tree

    /// Source with comment lines removed — see this file's header for why that matters.
    private static func stripComments(_ text: String) -> String {
        text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    private static var appRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // ADHD LifeOSTests
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("ADHD LifeOS")
    }

    private static func appCode(_ relativePath: String) throws -> String {
        let url = appRoot.appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw HeaderSourceError.unreadable(url.path)
        }
        return stripComments(text)
    }

    private static func allAppCode() throws -> [(name: String, code: String)] {
        guard let walker = FileManager.default.enumerator(
            at: appRoot, includingPropertiesForKeys: nil
        ) else {
            throw HeaderSourceError.unreadable(appRoot.path)
        }
        let swiftFiles = walker.compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" }
        guard !swiftFiles.isEmpty else { throw HeaderSourceError.unreadable(appRoot.path) }
        return try swiftFiles.map { url in
            guard let text = try? String(contentsOf: url, encoding: .utf8) else {
                throw HeaderSourceError.unreadable(url.path)
            }
            return (url.lastPathComponent, stripComments(text))
        }
    }

    /// Loud rather than skipped. A guard that quietly disables itself is the failure mode these
    /// tests exist to prevent.
    private enum HeaderSourceError: Error, CustomStringConvertible {
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

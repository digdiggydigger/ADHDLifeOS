//
//  AppSearchCallSiteTests.swift
//  ADHD LifeOSTests
//
//  Reachability for the bottom search row, and a guard against the bug that caused this arc.
//
//  **`.searchable` on a tab-root screen is now a defect, not a style choice.** iOS 26 renders that
//  field as a capsule pinned to the bottom of the screen and docks it into a `TabView`'s bar where
//  one exists. This app has no `TabView` — one folds a sixth tab into a "More" list — so the
//  capsule stands alone and lands UNDER the custom tab bar, where it cannot be tapped. E
//  photographed exactly that on Tasks, and Tasks search was unreachable for the whole of the Tools
//  arc without anything failing.
//
//  Nothing in a unit test can see a capsule behind a bar. What a test CAN see is the modifier that
//  summons it, so that is what this reads.
//
//  Comment lines are stripped before searching — the scar from `ToolsPageCallSiteTests`, where a
//  doc comment written in the same commit satisfied the very `contains` that was meant to prove
//  the code had changed. Several files below explain `.searchable` in prose while not calling it.
//

import XCTest

final class AppSearchCallSiteTests: XCTestCase {

    /// The ONE place `.searchable` is still legitimate: the app picker is presented as a `.sheet`
    /// from the place-actions editor, so no tab bar sits under it and iOS 26's placement is
    /// correct there. Named rather than pattern-matched, so a second exemption has to be argued.
    private static let sheetPresentedSearchScreens = ["PlaceAppPickerView.swift"]

    func testNoTabRootScreenUsesSystemSearchable() throws {
        let offenders = try Self.allAppCode()
            .filter { !Self.sheetPresentedSearchScreens.contains($0.name) }
            .filter { $0.code.contains(".searchable(") }
            .map(\.name)
            .sorted()
        XCTAssertEqual(
            offenders, [],
            "These screens call `.searchable(`. With no `TabView` in this app, iOS 26 puts that"
                + " field in a capsule at the bottom of the screen — underneath the custom tab"
                + " bar, where the user cannot reach it. Use the bottom search row instead:"
                + " add the scope to `AppSearchScope` and present a surface."
        )
    }

    /// The exemption must stay TRUE, or it silently licenses a real bug. If the picker stops being
    /// sheet-presented, its `.searchable` becomes the same defect.
    func testTheExemptScreenIsStillSheetPresented() throws {
        let editor = try Self.appCode("Places/PlaceActionsEditorView.swift")
        XCTAssertTrue(
            editor.contains(".sheet(isPresented: $isPickingApp)"),
            "`PlaceAppPickerView` is no longer presented as a sheet, so it is exempt from the"
                + " `.searchable` guard for a reason that has stopped being true."
        )
    }

    // MARK: - The row reaches the screen

    /// The model can be perfectly correct and drive nothing — this repo's most repeated defect.
    func testRootViewDrivesTheScopeFromTheSelectedTab() throws {
        let root = try Self.appCode("RootView.swift")
        XCTAssertTrue(
            root.contains("searchModel.activate(AppSearchScope.scope(for: tab))"),
            "The search scope is no longer driven from `selectedTab`. Registering it from a"
                + " screen's `onAppear` looks equivalent and is not: `AppTabContent` keeps every"
                + " visited tab alive, so appearance callbacks fire once and then never again."
        )
        XCTAssertTrue(
            root.contains("searchScope: searchModel.scope"),
            "The scope never reaches `RootBottomOverlay`, so the row can never appear."
        )
        XCTAssertTrue(
            root.contains("environmentObject(searchModel)"),
            "The search model is not injected, so any screen reading it traps the moment its body"
                + " is built."
        )
    }

    func testTheOverlayRendersTheRowBesideTheDisc() throws {
        let overlay = try Self.appCode("RootBottomOverlay.swift")
        XCTAssertTrue(
            overlay.contains("AppSearchRow("),
            "`RootBottomOverlay` never renders `AppSearchRow`, so the field exists and nothing"
                + " draws it."
        )
        XCTAssertTrue(
            overlay.contains("HStack(spacing: AppSearchRowMetrics.rowSpacing)"),
            "The row and the capture disc are no longer laid out by one `HStack`. E's layout is"
                + " \"centres aligned\" — two views agreeing on a number is how that drifts."
        )
    }

    func testTasksPresentsTheSurface() throws {
        let tasks = try Self.appCode("Tasks/TaskListView.swift")
        XCTAssertTrue(
            tasks.contains("TaskSearchSurface("),
            "Tasks never presents the search surface, so the row opens nothing."
        )
        XCTAssertTrue(
            tasks.contains("tasksService.searchText = $0"),
            "The shared query no longer reaches `TasksService`, so typing filters nothing."
        )
    }

    /// One definition of "matches". A second filter here would disagree with the board's the first
    /// time either changed.
    func testTheSurfaceReusesTheBoardsRefinement() throws {
        XCTAssertTrue(
            try Self.appCode("Tasks/TaskSearchSurface.swift").contains("TaskListRefinement.apply("),
            "The search surface filters with something other than `TaskListRefinement`, so the"
                + " board and the search can now disagree about what a query matches."
        )
    }

    // MARK: - Reading the tree

    private static func stripComments(_ text: String) -> String {
        text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    private static var appRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ADHD LifeOS")
    }

    private static func appCode(_ relativePath: String) throws -> String {
        let url = appRoot.appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw SearchSourceError.unreadable(url.path)
        }
        return stripComments(text)
    }

    private static func allAppCode() throws -> [(name: String, code: String)] {
        guard let walker = FileManager.default.enumerator(
            at: appRoot, includingPropertiesForKeys: nil
        ) else {
            throw SearchSourceError.unreadable(appRoot.path)
        }
        let swiftFiles = walker.compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" }
        guard !swiftFiles.isEmpty else { throw SearchSourceError.unreadable(appRoot.path) }
        return try swiftFiles.map { url in
            guard let text = try? String(contentsOf: url, encoding: .utf8) else {
                throw SearchSourceError.unreadable(url.path)
            }
            return (url.lastPathComponent, stripComments(text))
        }
    }

    /// Loud rather than skipped — a guard that quietly disables itself is the failure mode these
    /// tests exist to prevent.
    private enum SearchSourceError: Error, CustomStringConvertible {
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

//
//  AppSearchScopeTests.swift
//  ADHD LifeOSTests
//
//  The bottom search row's pure rules (F-Search-1-Row; the depth joined in F-TabDepth-2).
//
//  **Why this arc exists, in one paragraph, because the reason is easy to lose.** iOS 26 renders
//  `.searchable` as a capsule pinned to the BOTTOM of the screen, docking it into a `TabView`'s
//  bar where one exists. The Tools arc deleted the `TabView` — it folds a sixth tab into "More" —
//  so the capsule stood alone and landed UNDER the custom bar, where it cannot be tapped. E
//  photographed it, rejected moving search to the navigation bar, and asked for the field to sit
//  ABOVE the bar sharing the capture disc's row.
//
//  **The depth (F-TabDepth-2).** E's screenshot of 2026-09-08: a task's DETAIL screen, pushed
//  from the Tasks list, with "Search tasks" still sitting beside the capture disc. The row is
//  mounted once at the root, and the root derived its scope from the selected tab ALONE, so it
//  never learned the tab had gone deeper. The rule takes the depth now — block 1's coordinator
//  reports it — and answers `.none` for any tab that is not at its top-level page.
//
//  So the field is ours now, and its rules live here rather than in a view body, which is ~0%
//  covered by design.
//

import XCTest
@testable import ADHD_LifeOS

final class AppSearchScopeTests: XCTestCase {

    // MARK: - Which tabs have search

    func testTasksIsTheOnlySearchableTabInThisBlock() {
        XCTAssertEqual(AppSearchScope.scope(for: .tasks, isAtRoot: true), .tasks)
        for tab in AppTab.allCases where tab != .tasks {
            XCTAssertEqual(
                AppSearchScope.scope(for: tab, isAtRoot: true), AppSearchScope.none,
                "\(tab) reports a search scope. Captures and Journal are blocks 2 and 3 — adding"
                    + " their cases before their screens exist ships a scope nothing renders,"
                    + " which is this repo's most repeated defect in its gated-off form."
            )
        }
    }

    /// Totality: a tab with no answer is a tab whose row silently vanishes — at either depth.
    func testEveryTabIsAnsweredAtEitherDepth() {
        for tab in AppTab.allCases {
            for isAtRoot in [true, false] {
                XCTAssertNotNil(
                    AppSearchScope.scope(for: tab, isAtRoot: isAtRoot),
                    "\(tab) has no search scope at all (isAtRoot: \(isAtRoot))."
                )
            }
        }
    }

    // MARK: - The depth (F-TabDepth-2)

    /// E's screenshot, 2026-09-08 06:20: a task's detail pushed from the list, and *"Search
    /// tasks"* still beside the capture disc, searching a list the user cannot see.
    func testTasksBelowItsTopLevelPageHasNoScope() {
        XCTAssertEqual(
            AppSearchScope.scope(for: .tasks, isAtRoot: false), AppSearchScope.none,
            "Tasks reports a search scope with a screen pushed over its list. That is E's"
                + " screenshot of 2026-09-08: \"Search tasks\" sitting beside the capture disc"
                + " under a task's detail — the row was derived from the tab alone, so the root"
                + " never learned the tab had gone deeper."
        )
    }

    /// The depth rule is total, not a Tasks special case: when Captures or Journal gains a
    /// scope, its pushed screens inherit the rule on the day the case is added.
    func testNoTabHasAScopeBelowItsTopLevelPage() {
        for tab in AppTab.allCases {
            XCTAssertEqual(
                AppSearchScope.scope(for: tab, isAtRoot: false), AppSearchScope.none,
                "\(tab) reports a search scope below its top-level page, so its row would sit"
                    + " under whatever that tab has pushed."
            )
        }
    }

    // MARK: - The copy

    func testASearchableScopeCarriesAPlaceholderAndNoneDoesNot() {
        let tasks = AppSearchScope.tasks.placeholder
        XCTAssertNotNil(tasks, "The Tasks scope has no placeholder at all.")
        XCTAssertFalse(
            tasks?.isEmpty ?? true,
            "The Tasks scope's placeholder is empty, so the field would render as a blank capsule"
                + " with nothing saying what it searches."
        )
        XCTAssertNil(
            AppSearchScope.none.placeholder,
            "`.none` handed back a placeholder. There is no field on those screens to put it in."
        )
    }

    func testTheRowIsShownExactlyWhereThereIsSomethingToSearch() {
        XCTAssertTrue(AppSearchScope.tasks.showsRow)
        XCTAssertFalse(
            AppSearchScope.none.showsRow,
            "A search row would render on a screen with nothing to search — it would also steal"
                + " the bottom clearance those screens do not pay for."
        )
    }
}

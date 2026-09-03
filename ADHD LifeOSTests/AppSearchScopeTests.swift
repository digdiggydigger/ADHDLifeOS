//
//  AppSearchScopeTests.swift
//  ADHD LifeOSTests
//
//  The bottom search row's pure rules (F-Search-1-Row).
//
//  **Why this arc exists, in one paragraph, because the reason is easy to lose.** iOS 26 renders
//  `.searchable` as a capsule pinned to the BOTTOM of the screen, docking it into a `TabView`'s
//  bar where one exists. The Tools arc deleted the `TabView` — it folds a sixth tab into "More" —
//  so the capsule stood alone and landed UNDER the custom bar, where it cannot be tapped. E
//  photographed it, rejected moving search to the navigation bar, and asked for the field to sit
//  ABOVE the bar sharing the capture disc's row.
//
//  So the field is ours now, and its rules live here rather than in a view body, which is ~0%
//  covered by design.
//

import XCTest
@testable import ADHD_LifeOS

final class AppSearchScopeTests: XCTestCase {

    // MARK: - Which tabs have search

    /// **This list grows one block at a time, on purpose.** A scope exists only once the screen
    /// that renders its surface exists — adding `.journal` before F-Search-3 would ship a case
    /// nothing draws, which is this repo's most repeated defect in its gated-off form. This test
    /// failed the moment `.captures` landed in F-Search-2, which is the guard working: it forces
    /// the list and the shipped surfaces to be reconciled by hand rather than drifting apart.
    func testOnlyScreensWithASurfaceReportAScope() {
        let searchable: [AppTab: AppSearchScope] = [
            .tasks: .tasks,      // F-Search-1
            .captures: .captures // F-Search-2
            // .journal arrives with its surface in F-Search-3.
        ]
        for tab in AppTab.allCases {
            XCTAssertEqual(
                AppSearchScope.scope(for: tab), searchable[tab] ?? AppSearchScope.none,
                "\(tab)'s search scope disagrees with the surfaces that actually exist. Either the"
                    + " screen gained one and this table did not, or a scope was added ahead of"
                    + " the screen that renders it."
            )
        }
    }

    /// Totality: a tab with no answer is a tab whose row silently vanishes.
    func testEveryTabIsAnswered() {
        for tab in AppTab.allCases {
            XCTAssertNotNil(
                AppSearchScope.scope(for: tab),
                "\(tab) has no search scope at all."
            )
        }
    }

    // MARK: - The copy

    func testEverySearchableScopeCarriesAPlaceholder() {
        for scope in [AppSearchScope.tasks, .captures] {
            let placeholder = scope.placeholder
            XCTAssertNotNil(placeholder, "\(scope) has no placeholder at all.")
            XCTAssertFalse(
                placeholder?.isEmpty ?? true,
                "\(scope)'s placeholder is empty, so its field renders as a blank capsule with"
                    + " nothing saying what it searches."
            )
        }
    }

    func testTheTasksPlaceholderIsSpecificAndNoneHasNothing() {
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
        XCTAssertTrue(AppSearchScope.captures.showsRow)
        XCTAssertFalse(
            AppSearchScope.none.showsRow,
            "A search row would render on a screen with nothing to search — it would also steal"
                + " the bottom clearance those screens do not pay for."
        )
    }
}

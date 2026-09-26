//
//  TodayOneCardCallSiteTests.swift
//  ADHD LifeOSTests
//
//  `F-E3-OneCardToday`'s reachability and retirement guards — what the pure `TodayPlan` tests
//  cannot see, because it lives in a SwiftUI body or in which file a line sits.
//
//  Source is read with comment lines stripped and flattened to one line — the `*CallSiteTests`
//  house shape — so re-flowing a call never breaks a guard.
//

import XCTest
@testable import ADHD_LifeOS

final class TodayOneCardCallSiteTests: XCTestCase {

    // MARK: - The focus history outlives the charts that used to fetch it

    /// `FocusAnalyticsSection` was the ONLY writer of `publishedHistory`, through its load
    /// callback. Round 3 takes both charts off Today — and that history also feeds the weekly
    /// chain's "finished a sprint" signal, the gain line on Close, the week review and the Home
    /// Screen widget. Deleting the section alone breaks none of their tests and blanks all four.
    func testHomeReadsItsOwnFocusHistory() throws {
        let loader = try flattened("Home/HomeView+FocusHistory.swift")
        XCTAssertTrue(loader.contains("try? await focusHistoryReader.fetchHistory()"),
                      "Home no longer fetches the focus history itself.")
        XCTAssertTrue(loader.contains("publishedHistory = sessions"),
                      "The fetch never reaches `publishedHistory`, so the chain and the widget read [].")
        XCTAssertTrue(loader.contains("publishWidgetSnapshot(sprint: widgetSprint)"),
                      "A landed history must republish the widget, as the section's callback did.")
    }

    /// The same three triggers the charts reloaded on: first load, pull-to-refresh, and every
    /// finished sprint (`focusReloadToken` is RootView's `completedSprintCount`).
    func testTheHistoryReloadsOnTheChartsThreeTriggers() throws {
        let home = try flattened("Home/HomeView.swift")
        XCTAssertTrue(home.contains(".task(id: focusReloadToken + pullRefreshCount) { await loadFocusHistory() }"),
                      "The history must refetch on appear, on a pull and on every finished sprint.")
    }

    func testTheFocusChartsAreOffToday() throws {
        XCTAssertEqual(try occurrences(of: "FocusAnalyticsSection(", under: "Home"), [],
                       "Round 3: *\"Both charts come off Today.\"* (`F-E4` moves one into Week review.)")
    }

    // MARK: - Nudges stays reachable: its door moved to Tools (E, 2026-09-24)

    /// `NudgesView(` had exactly one production door, Today's nudges card, and Structure C removes
    /// it. E's Step 0 answer: *"the Nudges manager door moves to Tools, beside Routines."* A feature
    /// with no door is `F-FirstNudgeReachable`'s defect exactly.
    func testToolsHasTheNudgesDoorBesideRoutines() throws {
        let tools = try flattened("Tools/ToolsView.swift")
        let routines = try XCTUnwrap(tools.range(of: "ToolsRoutinesSection(")?.lowerBound)
        let nudges = try XCTUnwrap(tools.range(of: "ToolsNudgesSection(")?.lowerBound,
                                   "Tools draws no Nudges door, so the Nudges screen is unreachable.")
        XCTAssertLessThan(routines, nudges, "Beside Routines — directly after it.")
        XCTAssertTrue(tools.contains("case .nudges: NudgesView(service: nudgesService) .captureDiscClearance()"),
                      "The Nudges push must reach `NudgesView` with Tools' service, under the disc's clearance.")
    }

    /// Tools builds its `NudgesService` in `init`, where no `@Environment` value can be read — so,
    /// like Home, it hands the service the centre (the seven-day streak) and the undo slot in
    /// `.task`. Without them a dismissal on the Tools-pushed screen celebrates and records nothing.
    func testToolsHandsItsNudgesServiceTheCentreAndTheUndoSlot() throws {
        let tools = try flattened("Tools/ToolsView.swift")
        XCTAssertTrue(tools.contains("nudgesService.celebrate = celebrate"))
        XCTAssertTrue(tools.contains("nudgesService.recordAction = recordAction"))
    }

    // MARK: - Two week-review doors, one review (round 5b: "Both")

    /// Today's done line and the Areas row must open the SAME review — so both build it through
    /// `WeekReviewView(inputs:)`, and nothing else constructs one from loose parts.
    func testBothWeekReviewDoorsBuildTheReviewTheSameWay() throws {
        let doors = try occurrences(of: "WeekReviewView(", under: "").filter { $0 != "WeekReviewView.swift" }
        XCTAssertEqual(doors, ["AreasWeekReviewDoor.swift", "HomeWeekReviewRow.swift"])
        for door in doors {
            let path = door == "HomeWeekReviewRow.swift" ? "Home/\(door)" : "Areas/\(door)"
            XCTAssertTrue(try flattened(path).contains("WeekReviewView(inputs:"),
                          "\(door) builds the review from loose parts, so the two doors can drift.")
        }
    }

    /// *"...AND a row sits at the top of the Areas tab."*
    func testTheAreasRowSitsAtTheTopOfTheTab() throws {
        let areas = try flattened("Areas/AreasView.swift")
        let row = try XCTUnwrap(areas.range(of: "identifier: \"areasWeekReviewRow\"")?.lowerBound,
                                "The Areas tab has no Week review row.")
        let grid = try XCTUnwrap(areas.range(of: "grid(items: items)")?.lowerBound)
        XCTAssertLessThan(row, grid, "The row sits at the TOP — above the area grid.")
    }

    // MARK: - Today: one card, a "then" list, one done line (round 3, "C · One next thing")

    func testTodayDrawsOneCardThenTheListThenTheDoneLine() throws {
        let home = try flattened("Home/HomeView.swift")
        let card = try XCTUnwrap(home.range(of: "oneCardSection")?.lowerBound, "Today draws no one card.")
        let then = try XCTUnwrap(home.range(of: "thenSection")?.lowerBound, "Today draws no \"then\" list.")
        let done = try XCTUnwrap(home.range(of: "doneTodayLine")?.lowerBound, "Today draws no done line.")
        XCTAssertLessThan(card, then)
        XCTAssertLessThan(then, done)
    }

    /// The slot order is `TodayPlan`'s, tested there — so the one thing a body can get wrong is
    /// which inputs it hands over. `leaveBy: nil` is the site `F-F5`'s calendar read will fill.
    func testTheCardIsChosenByOnePlanFedEveryInput() throws {
        XCTAssertEqual(try occurrences(of: "TodayPlan.build(", under: ""), ["HomeView+Today.swift"])
        let today = try flattened("Home/HomeView+Today.swift")
        for input in [
            "openTasks: homeService.openTasks",
            "pinnedTaskId: pinnedTaskId",
            "skippedTaskIds: skippedTaskIds",
            "pausedSprint: TodayPausedSprint.from(status: activeSprint, sprint: widgetSprint)",
            "hasPlaceCard: liveRoutineRun != nil || arrivalSurface != nil",
            "leaveBy: nil"
        ] {
            XCTAssertTrue(today.contains(input), "Today's plan is missing its input `\(input)`.")
        }
    }

    /// E, 2026-09-24: the live-routine card and the arrival card COUNT AS the one card, unchanged.
    func testThePlaceSlotDrawsTheRoutineAndArrivalPairUnchanged() throws {
        let today = try flattened("Home/HomeView+Today.swift")
        XCTAssertTrue(
            today.contains("case .place: VStack(alignment: .leading, spacing: 16) { arrivalAndRoutineCards }")
        )
    }

    /// The Home Screen widget published `topTask` while Today led with `bestNextMove`, so they
    /// disagreed whenever anything was due; under pin semantics the widget must publish the winner.
    func testTheWidgetPublishesWhatTheCardLeadsWith() throws {
        let refresh = try flattened("Home/HomeView+Refresh.swift")
        XCTAssertTrue(refresh.contains("activeGoal: todayPlan.headlineTask"))
        XCTAssertFalse(try flattened("Home/HomeService.swift").contains("var activeGoal"),
                       "`HomeService.activeGoal` (topTask) has no reader once the widget follows the card.")
    }

    /// `F-E1`: Close reads "Close it — makes today count" until today counts. The card takes its
    /// title from the SAME context Task Detail does, so the two can never disagree — and that
    /// context is still built in exactly one place on Home.
    func testTheCardsCloseSaysWhatTaskDetailSays() throws {
        let today = try flattened("Home/HomeView+Today.swift")
        XCTAssertTrue(today.contains("closeTitle: momentumContext(for: task.lifeAreaId).closeButtonTitle"))
        let sections = try flattened("Home/HomeMomentumSections.swift")
        XCTAssertEqual(sections.components(separatedBy: "MomentumTaskContext.build(").count - 1, 1)
    }

    func testTheCardsButtonsReachTheirActions() throws {
        let today = try flattened("Home/HomeView+Today.swift")
        XCTAssertTrue(today.contains("onClose: { Task { await closeTask(task) } }"),
                      "Close must go through `closeTask`, which records the undo capsule.")
        XCTAssertTrue(today.contains("onResume: onToggleSprintPause"),
                      "Resume must reach the app-wide sprint's pause toggle.")
        XCTAssertTrue(today.contains("onStart: { startSprint(task) }"))
    }

    /// Both choices are per ACCOUNT (the `NudgeFirstRunMarker` lesson) — and a write is read back
    /// at once, so the card answers the tap it was given.
    func testThePinAndNotThisOneWriteTheirStoresPerAccount() throws {
        let choices = try flattened("Home/HomeView+Today.swift")
        for call in ["TodayPinStore.pin(", "TodayPinStore.unpin(", "TodaySkipStore.skip(",
                     "authService.signedInUser?.id.uuidString", "refreshTodayChoices()"] {
            XCTAssertTrue(choices.contains(call), "Today's choices never call `\(call)`.")
        }
        XCTAssertTrue(try flattened("Home/HomeView.swift").contains("if phase == .active { refreshTodayChoices() }"),
                      "Coming back to the app on a new day must drop yesterday's skips.")
    }

    /// Round 5a: *"Due nudges sit at the top of the 'then' list with a bell."*
    func testDueNudgesLeadTheThenListWithABell() throws {
        let today = try flattened("Home/HomeView+Today.swift")
        let nudges = try XCTUnwrap(today.range(of: "NudgeDueCard(")?.lowerBound, "Due nudges left Today.")
        let tasks = try XCTUnwrap(today.range(of: "ForEach(plan.thenTasks")?.lowerBound)
        XCTAssertLessThan(nudges, tasks, "Due nudges come FIRST in the \"then\" list.")
        XCTAssertTrue(today.contains("showsBell: true"))
    }

    /// The daily goal's full-screen celebration used to pop from the ring. The ring is gone, so it
    /// pops from the done line — which counts the SAME number, so the pop never leaves a line that
    /// contradicts it.
    func testTheDoneLineCountsTheGoalsNumberAndHostsItsPop() throws {
        let line = try flattened("Home/HomeWeekReviewRow.swift")
        XCTAssertTrue(line.contains("TodayCardCopy.doneTodayLine(count: ringCount"))
        XCTAssertTrue(line.contains(".celebrationPopOrigin { doneLineOrigin = $0 }"))
        XCTAssertTrue(try flattened("Home/HomeView+DailyGoal.swift")
            .contains("CelebrationPopOrigin.onScreen(doneLineOrigin)"))
    }

    func testTheNextStepIsEditableFromTheCard() throws {
        let today = try flattened("Home/HomeView+Today.swift")
        XCTAssertTrue(today.contains("TodayNextStep.payload("))
        XCTAssertTrue(today.contains("taskDetailClient.updateTask("))
    }

    func testTheCardHasACompactAccessibilityLayout() throws {
        XCTAssertTrue(try flattened("Home/HomeTodayCard.swift").contains("TodayCardLayout.isCompact("))
    }

    // MARK: - Retired with Today's old sections

    /// Round 3: life areas and the inbox peek leave Today, both charts come off it, and the ring
    /// goes with the scoreboard (round 8b). These names — and the helpers only they reached — must
    /// not come back, reversed from the tests that pinned them rather than deleted with them.
    func testTodaysOldSectionsAreGone() throws {
        let retired = [
            "HomeLifeAreasSection", "AreaMomentumList", "MomentumClosedTodayCard", "lifeAreasCollapsed",
            "isArranging", "submitReorder(", "reorderLifeAreas(", "LifeAreaReorderPayload",
            "HomeInboxPeek", "inboxPeekCard", "inspectedCaptureDoor", "closedWeekChartSection",
            "closedCaption(", "MomentumRingCard", "ringProgress(", "onRingOrigin", "BestNextMoveCard",
            "NudgeFirstRunMarker", "shouldRenderSection(", "firstRunDirective", "nudgesDoorCard",
            "doorSubtitle(", "chipText(", "nextFireLine(", "upcomingOverflowLine(", "nextFire(",
            "isPresentingNudges"
        ]
        for name in retired {
            XCTAssertEqual(try occurrences(of: name, under: ""), [], "`\(name)` is back.")
        }
    }

    // MARK: - Reading the tree

    private func occurrences(of needle: String, under folder: String) throws -> [String] {
        let root = Self.appRoot.appendingPathComponent(folder)
        guard let walker = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else {
            throw SiteError.unreadable(root.path)
        }
        var found: [String] = []
        for case let url as URL in walker where url.pathExtension == "swift" {
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
            if stripped(text).contains(needle) { found.append(url.lastPathComponent) }
        }
        return found.sorted()
    }

    private func flattened(_ path: String) throws -> String {
        let url = Self.appRoot.appendingPathComponent(path)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw SiteError.unreadable(url.path)
        }
        return stripped(text)
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: " ")
    }

    private func stripped(_ text: String) -> String {
        text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    private static let appRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("ADHD LifeOS")

    private enum SiteError: Error, CustomStringConvertible {
        case unreadable(String)

        var description: String {
            switch self {
            case .unreadable(let path): return "could not read \(path)"
            }
        }
    }
}

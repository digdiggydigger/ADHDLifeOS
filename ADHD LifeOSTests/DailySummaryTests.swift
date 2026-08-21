//
//  DailySummaryTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The Daily Executive Summary's pure layer: what gets sent to the generator, what comes back,
/// how it copies to the clipboard, and the offline synthesis that stands in for the model while
/// the Cloud Function is being built. Everything here is deterministic on its inputs — no dates,
/// no randomness, no network.
@MainActor
final class DailySummaryTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_787_000_000)

    // MARK: - Tone

    func testEveryToneHasADistinctLabelAndGlyph() {
        let labels = Set(DailySummaryTone.allCases.map(\.label))
        let glyphs = Set(DailySummaryTone.allCases.map(\.systemImage))
        XCTAssertEqual(labels.count, DailySummaryTone.allCases.count)
        XCTAssertEqual(glyphs.count, DailySummaryTone.allCases.count)
    }

    /// The four tones are the web original's, and the raw values travel to the backend — a rename
    /// here silently changes the prompt the function builds, so they are pinned.
    func testToneWireValuesMatchTheWebOriginal() {
        XCTAssertEqual(
            DailySummaryTone.allCases.map(\.rawValue),
            ["energizing", "gentle", "coaching", "bulleted"]
        )
    }

    // MARK: - Request building

    func testRequestCarriesOnlyTodaysCompletedTasks() {
        let request = makeRequest(tasks: [
            task("shipped it", status: .done, completedAt: now),
            task("yesterday's", status: .done, completedAt: now.addingTimeInterval(-86_400)),
            task("still open", status: .open, completedAt: nil)
        ])
        XCTAssertEqual(request.completedTasks.map(\.title), ["shipped it"])
    }

    func testRequestCarriesOpenTasksAsInProgressCappedAtFive() {
        let open = (1...8).map { task("open \($0)", status: .open, completedAt: nil) }
        let request = makeRequest(tasks: open)
        XCTAssertEqual(request.inProgressTasks.count, 5)
        XCTAssertEqual(request.inProgressTasks.first?.title, "open 1")
    }

    /// Focus minutes come from sprints that ended today, and are rounded down to whole minutes —
    /// a 90-second sprint is "1 minute", not "1.5".
    func testFocusMinutesSumsTodaysSessionsOnly() {
        let request = makeRequest(sessions: [
            session(focusedSeconds: 1_500, endedAt: now),            // 25m
            session(focusedSeconds: 90, endedAt: now),               // 1m (floored)
            session(focusedSeconds: 3_600, endedAt: now.addingTimeInterval(-86_400))
        ])
        XCTAssertEqual(request.focusMinutesTotal, 26)
    }

    func testRequestResolvesLifeAreaNamesAndFallsBackForUnassigned() {
        let areaId = UUID()
        let request = makeRequest(
            tasks: [
                TaskItem(id: UUID(), lifeAreaId: areaId, title: "in an area", status: .done,
                         priority: .p2, dueDate: nil, completedAt: now),
                task("no area", status: .done, completedAt: now)
            ],
            lifeAreaNames: [areaId: "Health"]
        )
        let names = Set(request.completedTasks.map(\.lifeAreaName))
        XCTAssertEqual(names, ["Health", "General"])
    }

    func testRequestIsEncodableWithSnakeCaseFreeCamelCaseKeys() throws {
        let request = makeRequest(tasks: [task("done", status: .done, completedAt: now)])
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any]
        )
        // The function reads these verbatim — the same silent-drop trap as the capture endpoint.
        XCTAssertNotNil(json["tone"])
        XCTAssertNotNil(json["focusMinutesTotal"])
        XCTAssertNotNil(json["completedTasks"])
        XCTAssertNotNil(json["inProgressTasks"])
        XCTAssertNotNil(json["journalEntries"])
    }

    // MARK: - Copy formatting

    func testCopyTextContainsEverySectionInOrder() {
        let text = DailySummaryCopyFormatter.text(for: sampleSummary, on: now)
        for fragment in ["Daily Summary", "A good day", "Dopamine Wins", "shipped the thing",
                         "Reflections", "felt steady", "Focus & Stamina", "26 minutes",
                         "Tomorrow", "start small"] {
            XCTAssertTrue(text.contains(fragment), "missing \(fragment)")
        }
        let winsIndex = try? XCTUnwrap(text.range(of: "Dopamine Wins"))
        let tomorrowIndex = try? XCTUnwrap(text.range(of: "Tomorrow"))
        XCTAssertNotNil(winsIndex)
        XCTAssertNotNil(tomorrowIndex)
    }

    func testCopyTextBulletsListSections() {
        let text = DailySummaryCopyFormatter.text(for: sampleSummary, on: now)
        XCTAssertTrue(text.contains("• shipped the thing"))
        XCTAssertTrue(text.contains("• start small"))
    }

    /// An empty list must not leave a dangling header with nothing under it.
    func testCopyTextOmitsEmptyListSections() {
        let empty = DailySummaryContent(
            headline: "Quiet day", dopamineWins: [], journalReflections: "Nothing logged.",
            focusStaminaInsight: "No sprints yet.", gentleTomorrowKickstart: []
        )
        let text = DailySummaryCopyFormatter.text(for: empty, on: now)
        XCTAssertFalse(text.contains("Dopamine Wins"))
        XCTAssertFalse(text.contains("Tomorrow"))
        XCTAssertTrue(text.contains("Quiet day"))
    }

    // MARK: - Offline synthesis (the stub standing in for the Cloud Function)

    func testStubSynthesisIsDeterministicForTheSameRequest() async throws {
        let request = makeRequest(tasks: [task("ship it", status: .done, completedAt: now)])
        let generator = StubDailySummaryGenerator()
        let first = try await generator.generate(request)
        let second = try await generator.generate(request)
        XCTAssertEqual(first, second)
    }

    func testStubSynthesisNamesRealCompletedWork() async throws {
        let request = makeRequest(tasks: [
            task("ship the capture fix", status: .done, completedAt: now)
        ])
        let content = try await StubDailySummaryGenerator().generate(request)
        XCTAssertTrue(
            content.dopamineWins.contains { $0.contains("ship the capture fix") },
            "wins should quote the actual task: \(content.dopamineWins)"
        )
    }

    func testStubSynthesisHandlesAnEmptyDayWithoutInventingWins() async throws {
        let content = try await StubDailySummaryGenerator().generate(makeRequest())
        XCTAssertTrue(content.dopamineWins.isEmpty)
        XCTAssertFalse(content.headline.isEmpty)
        XCTAssertFalse(content.gentleTomorrowKickstart.isEmpty)
    }

    /// Tone has to change the words — otherwise the picker is decoration.
    func testStubSynthesisVariesHeadlineByTone() async throws {
        let generator = StubDailySummaryGenerator()
        var headlines: Set<String> = []
        for tone in DailySummaryTone.allCases {
            let content = try await generator.generate(makeRequest(tone: tone))
            headlines.insert(content.headline)
        }
        XCTAssertEqual(headlines.count, DailySummaryTone.allCases.count)
    }

    func testBulletedToneProducesListShapedOutput() async throws {
        let request = makeRequest(
            tone: .bulleted,
            tasks: [task("a", status: .done, completedAt: now), task("b", status: .done, completedAt: now)]
        )
        let content = try await StubDailySummaryGenerator().generate(request)
        XCTAssertGreaterThanOrEqual(content.dopamineWins.count, 2)
    }

    // MARK: - Helpers

    private var sampleSummary: DailySummaryContent {
        DailySummaryContent(
            headline: "A good day",
            dopamineWins: ["shipped the thing"],
            journalReflections: "You felt steady.",
            focusStaminaInsight: "26 minutes of focused work.",
            gentleTomorrowKickstart: ["start small"]
        )
    }

    private func makeRequest(
        tone: DailySummaryTone = .energizing,
        tasks: [TaskItem] = [],
        sessions: [CompletedFocusSession] = [],
        journal: [Log] = [],
        captures: Int = 0,
        lifeAreaNames: [UUID: String] = [:]
    ) -> DailySummaryRequest {
        DailySummaryRequest(
            date: now, tone: tone, tasks: tasks, focusSessions: sessions,
            journalEntries: journal, capturesCount: captures,
            lifeAreaNames: lifeAreaNames, calendar: Calendar(identifier: .gregorian)
        )
    }

    private func task(_ title: String, status: TaskStatus, completedAt: Date?) -> TaskItem {
        TaskItem(id: UUID(), lifeAreaId: nil, title: title, status: status,
                 priority: .p2, dueDate: nil, completedAt: completedAt)
    }

    private func session(focusedSeconds: Int, endedAt: Date) -> CompletedFocusSession {
        CompletedFocusSession(
            id: UUID(), taskId: nil, taskTitle: "sprint", lifeAreaEmoji: "🎯",
            plannedSeconds: focusedSeconds, focusedSeconds: focusedSeconds,
            checkpointsReached: 0, completedNaturally: true,
            startedAt: endedAt.addingTimeInterval(-Double(focusedSeconds)), endedAt: endedAt
        )
    }
}

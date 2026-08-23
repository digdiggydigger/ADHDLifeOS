//
//  FirebaseDailySummaryDataAdapterTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Assembles today's raw material for the Daily Executive Summary — five Firestore reads folded
/// into one request. Split from the generator on purpose, so "what happened today" and "how it is
/// worded" fail independently.
///
/// It carries one real rule rather than being a pass-through, and that rule is the reason this file
/// exists: **only untriaged captures count as offloaded today.** A promoted capture has already
/// become a task, so counting it here would credit the same piece of work twice.
final class FirebaseDailySummaryDataAdapterTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_755_000_000)
    private var store: FakeDailySummaryDataBackingStore!
    private var adapter: FirebaseDailySummaryDataAdapter!

    override func setUp() {
        super.setUp()
        store = FakeDailySummaryDataBackingStore()
        adapter = FirebaseDailySummaryDataAdapter(store: store)
    }

    override func tearDown() {
        adapter = nil
        store = nil
        super.tearDown()
    }

    // MARK: - The double-counting rule

    func testCapturesCount_countsOnlyUntriagedCaptures() async throws {
        store.captures = [
            Self.capture(content: "Still in the inbox", processed: false),
            Self.capture(content: "Also waiting", processed: false),
            Self.capture(content: "Already promoted to a task", processed: true)
        ]

        let request = try await adapter.loadRequest(tone: .energizing, date: now)

        XCTAssertEqual(
            request.capturesCount, 2,
            "a promoted capture is already counted as a task — counting it here credits the work twice"
        )
    }

    func testCapturesCount_isZeroWhenEverythingHasBeenTriaged() async throws {
        store.captures = [Self.capture(content: "Promoted", processed: true)]

        let request = try await adapter.loadRequest(tone: .energizing, date: now)

        XCTAssertEqual(request.capturesCount, 0)
    }

    func testCapturesCount_isZeroWithNoCaptures() async throws {
        let request = try await adapter.loadRequest(tone: .energizing, date: now)

        XCTAssertEqual(request.capturesCount, 0)
    }

    // MARK: - Assembling the request

    func testTheRequestCarriesTheRequestedToneAndDate() async throws {
        let request = try await adapter.loadRequest(tone: .coaching, date: now)

        XCTAssertEqual(request.tone, .coaching)
        XCTAssertEqual(request.date, now)
    }

    /// Every collection reaches the request through `DailySummaryRequest`'s own projection, so these
    /// assert on what the prompt actually sees rather than on the raw documents.
    func testTheRequestCarriesEveryCollectionItRead() async throws {
        store.tasks = [
            Self.task(title: "Draft the brief", status: .done, completedAt: now),
            Self.task(title: "Still open", status: .open, completedAt: nil)
        ]
        store.logs = [Self.log(body: "Slept badly, still shipped")]
        store.focusSessions = [Self.session()]

        let request = try await adapter.loadRequest(tone: .energizing, date: now)

        XCTAssertEqual(request.completedTasks.map(\.title), ["Draft the brief"])
        XCTAssertEqual(request.inProgressTasks.map(\.title), ["Still open"])
        XCTAssertEqual(request.journalEntries.map(\.body), ["Slept badly, still shipped"])
        XCTAssertEqual(request.focusMinutesTotal, 25, "1500 focused seconds is 25 minutes")
    }

    /// Every read happens exactly once. They run concurrently because they are independent, and
    /// doing them in sequence would make the button feel broken on a slow connection.
    func testEveryCollectionIsReadExactlyOnce() async throws {
        _ = try await adapter.loadRequest(tone: .energizing, date: now)

        XCTAssertEqual(store.tasksCallCount, 1)
        XCTAssertEqual(store.logsCallCount, 1)
        XCTAssertEqual(store.focusSessionsCallCount, 1)
        XCTAssertEqual(store.capturesCallCount, 1)
        XCTAssertEqual(store.includeArchivedArguments.count, 1)
    }

    // MARK: - Life-area names

    func testLifeAreaNames_resolveOntoTheTasksThatReferenceThem() async throws {
        let health = LifeArea(id: UUID(), name: "Health", colour: "🏃", sortOrder: 0)
        store.lifeAreas = [health]
        store.tasks = [Self.task(title: "Walk", status: .done, completedAt: now, lifeAreaId: health.id)]

        let request = try await adapter.loadRequest(tone: .energizing, date: now)

        XCTAssertEqual(request.completedTasks.first?.lifeAreaName, "Health")
    }

    /// A task in no area is named rather than blank — the prompt reads better with "General" than
    /// with an empty string, and the web did the same.
    func testAnUnassignedTaskFallsBackToTheGeneralAreaName() async throws {
        store.tasks = [Self.task(title: "Loose end", status: .done, completedAt: now, lifeAreaId: nil)]

        let request = try await adapter.loadRequest(tone: .energizing, date: now)

        XCTAssertEqual(request.completedTasks.first?.lifeAreaName, DailySummaryRequest.unassignedLifeAreaName)
    }

    /// Duplicate ids keep the first name rather than trapping — building a dictionary from a
    /// collection that should have unique ids but might not must never crash the summary.
    func testDuplicateLifeAreaIdsKeepTheFirstNameAndDoNotTrap() async throws {
        let id = UUID()
        store.lifeAreas = [
            LifeArea(id: id, name: "First", colour: "🏃", sortOrder: 0),
            LifeArea(id: id, name: "Second", colour: "💼", sortOrder: 1)
        ]
        store.tasks = [Self.task(title: "Walk", status: .done, completedAt: now, lifeAreaId: id)]

        let request = try await adapter.loadRequest(tone: .energizing, date: now)

        XCTAssertEqual(request.completedTasks.first?.lifeAreaName, "First")
    }

    /// Pins current behaviour, which is that the name map is built from ACTIVE areas only: a task
    /// filed under an area archived later resolves no name in the summary. Reported to E rather
    /// than changed here — it is a product call, not a refactor.
    func testLifeAreaNames_areReadFromActiveAreasOnly() async throws {
        _ = try await adapter.loadRequest(tone: .energizing, date: now)

        XCTAssertEqual(store.includeArchivedArguments, [false])
    }

    // MARK: - Failures

    /// A Firestore failure is deliberately NOT degraded anywhere downstream — the on-device
    /// fallback rewords the day, it cannot invent one. So each read must be able to fail the whole
    /// request rather than quietly yielding an empty day.
    func testAnyFailedReadFailsTheWholeRequest() async {
        let failures: [(String, (FakeDailySummaryDataBackingStore) -> Void)] = [
            ("tasks", { $0.tasksError = FirebaseManagerError.notSignedIn }),
            ("logs", { $0.logsError = FirebaseManagerError.notSignedIn }),
            ("focus sessions", { $0.focusSessionsError = FirebaseManagerError.notSignedIn }),
            ("captures", { $0.capturesError = FirebaseManagerError.notSignedIn }),
            ("life areas", { $0.lifeAreasError = FirebaseManagerError.notSignedIn })
        ]

        for (label, applyFailure) in failures {
            let failing = FakeDailySummaryDataBackingStore()
            applyFailure(failing)
            let adapter = FirebaseDailySummaryDataAdapter(store: failing)

            await XCTAssertThrowsErrorAsync(try await adapter.loadRequest(tone: .energizing, date: now)) { error in
                XCTAssertEqual(
                    error as? FirebaseManagerError, .notSignedIn,
                    "a failed \(label) read must surface, not become an empty day"
                )
            }
        }
    }

    // MARK: - Fixtures

    private static func capture(content: String, processed: Bool) -> Capture {
        Capture(
            id: UUID(),
            content: content,
            kind: .note,
            processed: processed,
            createdAt: Date(timeIntervalSince1970: 1_755_000_000),
            title: nil,
            status: processed ? .processed : .inbox,
            lifeAreaId: nil,
            mediaURL: nil,
            mediaContentType: nil,
            thumbnailURL: nil,
            linkPreview: nil,
            aiAssessment: nil
        )
    }

    private static func task(
        title: String,
        status: TaskStatus,
        completedAt: Date?,
        lifeAreaId: UUID? = nil
    ) -> TaskItem {
        TaskItem(
            id: UUID(), lifeAreaId: lifeAreaId, title: title,
            status: status, priority: .p2, dueDate: nil, completedAt: completedAt
        )
    }

    private static func log(body: String) -> Log {
        Log(
            id: UUID(), lifeAreaId: nil, type: .journal, body: body,
            entryDate: Date(timeIntervalSince1970: 1_755_000_000),
            createdAt: Date(timeIntervalSince1970: 1_755_000_000),
            energyLevel: .low, moodEmoji: nil
        )
    }

    private static func session() -> CompletedFocusSession {
        CompletedFocusSession(
            id: UUID(), taskId: nil, taskTitle: "Draft the brief", lifeAreaEmoji: "💼",
            plannedSeconds: 1_500, focusedSeconds: 1_500, checkpointsReached: 2,
            completedNaturally: true,
            startedAt: Date(timeIntervalSince1970: 1_755_000_000),
            endedAt: Date(timeIntervalSince1970: 1_755_001_500)
        )
    }
}

//
//  FirebaseManagerSeedTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// `FirebaseManager+Seed` — the starter content every new account gets, written once on first
/// sign-in. Untestable before the emulator for a quieter reason than account deletion: seeding
/// runs exactly once per account and is then permanently short-circuited by the `seeded_at`
/// marker, so on a real project there is no second chance to observe it. A bug here is invisible
/// to E (whose account seeded months ago) and permanent for the user who hits it.
///
/// Skips when the Emulator Suite is not running — see `FirebaseEmulatorHarness`.
final class FirebaseManagerSeedTests: XCTestCase {
    private var manager: FirebaseManager { .shared }

    override func setUp() async throws {
        try await super.setUp()
        try await FirebaseEmulatorHarness.requireEmulator()
    }

    override func tearDown() async throws {
        await FirebaseEmulatorHarness.tearDownCurrentUser()
        try await super.tearDown()
    }

    // MARK: - What a new account starts with

    /// Ordered by `sort_order`, which is also the order they appear in Home's grid — so this
    /// pins the arrangement a new user actually sees, not just the set of names.
    func testSeed_writesTheSixLifeAreasInGridOrder() async throws {
        try await FirebaseEmulatorHarness.signUpSeededUser()

        let areas = try await manager.fetchLifeAreas(includeArchived: true)

        XCTAssertEqual(areas.map(\.name), ["Health", "Work", "Home", "Money", "Relationships", "Growth"])
        XCTAssertEqual(areas.map(\.sortOrder), [0, 1, 2, 3, 4, 5])
    }

    /// `colour` carries an emoji rather than a hex string — the app-wide convention, and the
    /// thing most likely to be "fixed" by someone reading the field name literally.
    func testSeed_storesEmojiInTheColourField() async throws {
        try await FirebaseEmulatorHarness.signUpSeededUser()

        let areas = try await manager.fetchLifeAreas(includeArchived: true)

        XCTAssertEqual(areas.map(\.colour), ["🫀", "💼", "🏠", "💰", "💬", "🌱"])
    }

    func testSeed_writesTheFiveBaselineTags() async throws {
        try await FirebaseEmulatorHarness.signUpSeededUser()

        let tags = try await manager.fetchTags()

        // `fetchTags` orders by name, so this is alphabetical rather than declaration order.
        XCTAssertEqual(tags.map(\.name), ["focus", "quick-win", "someday", "urgent", "waiting-on"])
    }

    /// Compared as a set: all three seed tasks share one `createdAt`, so their `created_at`
    /// ordering is genuinely undefined and asserting a sequence would be flaky by construction.
    func testSeed_writesTheThreeStarterTasks() async throws {
        try await FirebaseEmulatorHarness.signUpSeededUser()

        let tasks = try await manager.fetchTasks()

        XCTAssertEqual(Set(tasks.map(\.title)), [
            "Check off your first task",
            "Take a 10-minute walk",
            "Capture three things on your mind"
        ])
    }

    func testSeed_writesOneWelcomeJournalEntry() async throws {
        try await FirebaseEmulatorHarness.signUpSeededUser()

        let logs = try await manager.fetchLogs()

        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.type, .journal)
        XCTAssertTrue(logs.first?.body.hasPrefix("Welcome to ADHD LifeOS") == true)
    }

    // MARK: - The cross-references between seeded documents

    /// The starter tasks point at seeded life areas by id. Those ids are generated at seed time,
    /// so a wrong lookup here yields a task filed under nothing — which renders as "Unassigned"
    /// and looks like a data bug to the user.
    func testSeed_filesTheWalkTaskUnderHealthAndTheFirstTaskUnderGrowth() async throws {
        try await FirebaseEmulatorHarness.signUpSeededUser()
        let areas = try await manager.fetchLifeAreas(includeArchived: true)
        let health = try XCTUnwrap(areas.first { $0.name == "Health" })
        let growth = try XCTUnwrap(areas.first { $0.name == "Growth" })

        let tasks = try await manager.fetchTasks()
        let walk = try XCTUnwrap(tasks.first { $0.title == "Take a 10-minute walk" })
        let first = try XCTUnwrap(tasks.first { $0.title == "Check off your first task" })

        XCTAssertEqual(walk.lifeAreaId, health.id)
        XCTAssertEqual(first.lifeAreaId, growth.id)
    }

    /// `tag_ids` is written by hand into the batch (it is not part of `TaskDetail`'s `Codable`),
    /// so nothing else would catch it being dropped or misspelled.
    func testSeed_preTagsTheFirstTaskAsQuickWin() async throws {
        try await FirebaseEmulatorHarness.signUpSeededUser()
        let tasks = try await manager.fetchTasks()
        let first = try XCTUnwrap(tasks.first { $0.title == "Check off your first task" })

        let tags = try await manager.fetchTags(for: .task, parentId: first.id)

        XCTAssertEqual(tags.map(\.name), ["quick-win"])
    }

    /// One task is due tomorrow so a new user's Home has something dated on it. Asserted as a
    /// coarse window rather than an exact stamp — the seed uses the client clock at write time.
    func testSeed_givesTheWalkTaskATomorrowDueDate() async throws {
        try await FirebaseEmulatorHarness.signUpSeededUser()
        let tasks = try await manager.fetchTasks()
        let walk = try XCTUnwrap(tasks.first { $0.title == "Take a 10-minute walk" })

        let due = try XCTUnwrap(walk.dueDate)
        let hoursAway = due.timeIntervalSinceNow / 3600
        XCTAssertGreaterThan(hoursAway, 23)
        XCTAssertLessThan(hoursAway, 25)
    }

    /// The other two carry no due date at all — a new account should not open onto three things
    /// that all look scheduled.
    func testSeed_leavesTheOtherStarterTasksUndated() async throws {
        try await FirebaseEmulatorHarness.signUpSeededUser()
        let tasks = try await manager.fetchTasks()

        let undated = tasks.filter { $0.dueDate == nil }.map(\.title)
        XCTAssertEqual(Set(undated), ["Check off your first task", "Capture three things on your mind"])
    }

    // MARK: - Idempotency

    /// `seedDefaultContentIfNeeded` runs on EVERY sign-in, not just the first. Without the
    /// `seeded_at` marker doing its job, a user would accumulate six more life areas each time
    /// they signed in.
    func testSeed_onASecondSignIn_writesNothingFurther() async throws {
        let user = try await FirebaseEmulatorHarness.signUpSeededUser()
        let email = try XCTUnwrap(user.email)
        try manager.signOut()

        _ = try await manager.signIn(email: email, password: FirebaseEmulatorHarness.password)

        let areas = try await manager.fetchLifeAreas(includeArchived: true)
        let tags = try await manager.fetchTags()
        let tasks = try await manager.fetchTasks()
        XCTAssertEqual(areas.count, 6, "a second sign-in re-seeded the account")
        XCTAssertEqual(tags.count, 5)
        XCTAssertEqual(tasks.count, 3)
    }

    /// Called directly and repeatedly, it stays a no-op — the marker is the guard, not the
    /// sign-in path that happens to call it.
    func testSeed_calledRepeatedly_isANoOp() async throws {
        try await FirebaseEmulatorHarness.signUpSeededUser()

        try await manager.seedDefaultContentIfNeeded()
        try await manager.seedDefaultContentIfNeeded()

        let areas = try await manager.fetchLifeAreas(includeArchived: true)
        XCTAssertEqual(areas.count, 6)
    }

    /// A user who deleted their starter content should not have it grow back on next launch.
    /// This is the marker's second job: it survives the content it describes.
    func testSeed_afterTheUserDeletesTheirLifeAreas_doesNotRestoreThem() async throws {
        try await FirebaseEmulatorHarness.signUpSeededUser()
        let areas = try await manager.fetchLifeAreas(includeArchived: true)
        for area in areas {
            try await manager.deleteLifeArea(id: area.id)
        }

        try await manager.seedDefaultContentIfNeeded()

        let after = try await manager.fetchLifeAreas(includeArchived: true)
        XCTAssertEqual(after.count, 0, "seeding grew the user's deleted areas back")
    }

    func testSeed_whenSignedOut_throwsNotSignedIn() async throws {
        try await FirebaseEmulatorHarness.signUpSeededUser()
        try manager.signOut()

        do {
            try await manager.seedDefaultContentIfNeeded()
            XCTFail("expected notSignedIn")
        } catch let error as FirebaseManagerError {
            XCTAssertEqual(error, .notSignedIn)
        }
    }
}

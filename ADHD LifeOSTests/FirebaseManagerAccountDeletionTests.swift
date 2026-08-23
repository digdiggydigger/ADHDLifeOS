//
//  FirebaseManagerAccountDeletionTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// `FirebaseManager+AccountDeletion` — the App Store 5.1.1(v) erasure path, and the one piece of
/// this app that genuinely could not be tested before the emulator existed: running it against
/// the live project destroys the signed-in user's entire dataset, so there was no safe manual
/// check and no way to write an automated one.
///
/// These run only with the Emulator Suite up (`firebase emulators:start`); without it they skip.
/// See `FirebaseEmulatorHarness` for the interlock that stops them ever reaching production.
final class FirebaseManagerAccountDeletionTests: XCTestCase {
    private var manager: FirebaseManager { .shared }

    override func setUp() async throws {
        try await super.setUp()
        try await FirebaseEmulatorHarness.requireEmulator()
    }

    override func tearDown() async throws {
        await FirebaseEmulatorHarness.tearDownCurrentUser()
        try await super.tearDown()
    }

    // MARK: - The cascade

    /// The headline guarantee. Every per-user collection is populated — seeding covers life
    /// areas, tags, tasks and logs; the rest are written here — and after one call all of them
    /// read back empty.
    func testDeleteAllUserData_emptiesEveryPerUserCollection() async throws {
        try await FirebaseEmulatorHarness.signUpSeededUser()
        try await manager.saveCapture(Self.makeCapture())
        try await manager.createNudge(Self.makeNudge())
        try await manager.saveFocusSession(Self.makeFocusSession())

        // Guard the test itself: if the arrangement silently wrote nothing, an "everything is
        // empty" assertion afterwards would pass while proving nothing at all.
        let areasBefore = try await manager.fetchLifeAreas(includeArchived: true)
        XCTAssertFalse(areasBefore.isEmpty, "seeding should have populated life areas")
        let capturesBefore = try await manager.fetchCaptures()
        XCTAssertFalse(capturesBefore.isEmpty)

        try await manager.deleteAllUserData()

        let tasks = try await manager.fetchTasks()
        let areas = try await manager.fetchLifeAreas(includeArchived: true)
        let tags = try await manager.fetchTags()
        let logs = try await manager.fetchLogs()
        let captures = try await manager.fetchCaptures()
        let nudges = try await manager.fetchNudges()
        let sessions = try await manager.fetchFocusSessions()

        XCTAssertEqual(tasks.count, 0, "tasks survived the cascade")
        XCTAssertEqual(areas.count, 0, "life areas survived the cascade")
        XCTAssertEqual(tags.count, 0, "tags survived the cascade")
        XCTAssertEqual(logs.count, 0, "logs survived the cascade — check the rules allow owner delete")
        XCTAssertEqual(captures.count, 0, "captures survived the cascade")
        XCTAssertEqual(nudges.count, 0, "nudges survived the cascade")
        XCTAssertEqual(sessions.count, 0, "focus sessions survived the cascade")
    }

    /// The journal is append-only everywhere else in the app — no update, no delete — so its
    /// deletion here is the one that a rules regression would break first, and silently. Called
    /// out on its own because `deleteAllUserData` aborts on the throw, which would leave the
    /// account half-erased but still signed in.
    func testDeleteAllUserData_deletesJournalLogsDespiteTheAppHavingNoOtherDeletePath() async throws {
        try await FirebaseEmulatorHarness.signUpSeededUser()
        try await manager.appendLog(Self.makeLog())
        let before = try await manager.fetchLogs()
        XCTAssertFalse(before.isEmpty)

        try await manager.deleteAllUserData()

        let after = try await manager.fetchLogs()
        XCTAssertEqual(after.count, 0)
    }

    /// The `users/{uid}` profile doc carries the `seeded_at` marker, so deleting it is what makes
    /// a future account start fresh rather than believing it was already seeded. Asserted
    /// behaviourally — re-running the seed repopulates — rather than by probing for the marker,
    /// which would need a production accessor that exists only for this test.
    func testDeleteAllUserData_clearsTheSeedMarkerSoTheAccountCanSeedAgain() async throws {
        try await FirebaseEmulatorHarness.signUpSeededUser()
        try await manager.deleteAllUserData()
        let afterWipe = try await manager.fetchLifeAreas(includeArchived: true)
        XCTAssertEqual(afterWipe.count, 0)

        try await manager.seedDefaultContentIfNeeded()

        let reseeded = try await manager.fetchLifeAreas(includeArchived: true)
        XCTAssertEqual(reseeded.count, 6, "the seed marker outlived the profile doc")
    }

    func testDeleteAllUserData_whenSignedOut_throwsNotSignedIn() async throws {
        try await FirebaseEmulatorHarness.signUpSeededUser()
        try manager.signOut()

        do {
            try await manager.deleteAllUserData()
            XCTFail("expected notSignedIn")
        } catch let error as FirebaseManagerError {
            XCTAssertEqual(error, .notSignedIn)
        }
    }

    // MARK: - The ordering contract

    /// `+AccountDeletion`'s doc comment states the contract: data first, auth user second,
    /// because the security rules scope every document to its signed-in owner. This is that
    /// contract as an executable fact — reverse the order and the data is stranded, reachable
    /// only by a console admin.
    func testDeletingTheAuthUserFirst_strandsTheDataItWasSupposedToErase() async throws {
        try await FirebaseEmulatorHarness.signUpSeededUser()

        try await manager.deleteAuthUser()

        do {
            try await manager.deleteAllUserData()
            XCTFail("expected the wipe to be impossible once the auth user is gone")
        } catch let error as FirebaseManagerError {
            XCTAssertEqual(error, .notSignedIn)
        }
    }

    // MARK: - Reauthentication

    func testAccountReauthMethod_forAnEmailPasswordUser_isPassword() async throws {
        try await FirebaseEmulatorHarness.signUpSeededUser()

        XCTAssertEqual(manager.accountReauthMethod(), .password)
    }

    /// No session, no reauth method — the Settings flow uses `nil` to mean "nothing to
    /// reauthenticate", which must not be confused with "password".
    func testAccountReauthMethod_whenSignedOut_isNil() async throws {
        try await FirebaseEmulatorHarness.signUpSeededUser()
        try manager.signOut()

        XCTAssertNil(manager.accountReauthMethod())
    }

    func testReauthenticateWithPassword_withTheCorrectPassword_succeeds() async throws {
        try await FirebaseEmulatorHarness.signUpSeededUser()

        try await manager.reauthenticateWithPassword(FirebaseEmulatorHarness.password)
    }

    /// The gate that stands between someone holding an unlocked phone and an irreversible
    /// deletion. A wrong password must throw rather than fall through.
    func testReauthenticateWithPassword_withAWrongPassword_throws() async throws {
        try await FirebaseEmulatorHarness.signUpSeededUser()

        do {
            try await manager.reauthenticateWithPassword("not-the-password")
            XCTFail("a wrong password reauthenticated")
        } catch {
            // Raw Firebase error by design — `FirebaseAccountDeletionAdapter` is the layer that
            // maps it to `AccountDeletionError`, and that mapping is tested separately.
        }
    }

    func testReauthenticateWithPassword_whenSignedOut_throwsNotSignedIn() async throws {
        try await FirebaseEmulatorHarness.signUpSeededUser()
        try manager.signOut()

        do {
            try await manager.reauthenticateWithPassword(FirebaseEmulatorHarness.password)
            XCTFail("expected notSignedIn")
        } catch let error as FirebaseManagerError {
            XCTAssertEqual(error, .notSignedIn)
        }
    }

    // MARK: - The auth user

    func testDeleteAuthUser_endsTheSession() async throws {
        try await FirebaseEmulatorHarness.signUpSeededUser()
        XCTAssertNotNil(manager.currentUser)

        try await manager.deleteAuthUser()

        XCTAssertNil(manager.currentUser)
    }

    func testDeleteAuthUser_whenSignedOut_throwsNotSignedIn() async throws {
        try await FirebaseEmulatorHarness.signUpSeededUser()
        try manager.signOut()

        do {
            try await manager.deleteAuthUser()
            XCTFail("expected notSignedIn")
        } catch let error as FirebaseManagerError {
            XCTAssertEqual(error, .notSignedIn)
        }
    }

    /// A deleted account's credentials must stop working — otherwise "delete my account" left
    /// the account behind.
    func testDeleteAuthUser_makesTheCredentialsUnusable() async throws {
        let user = try await FirebaseEmulatorHarness.signUpSeededUser()
        let email = try XCTUnwrap(user.email)
        try await manager.deleteAuthUser()

        do {
            _ = try await manager.signIn(email: email, password: FirebaseEmulatorHarness.password)
            XCTFail("a deleted account signed back in")
        } catch {
            // Expected — the account no longer exists.
        }
    }

    // MARK: - Fixtures

    private static func makeCapture() -> Capture {
        Capture(
            id: UUID(),
            content: "a thought worth erasing",
            kind: .note,
            processed: false,
            createdAt: Date()
        )
    }

    private static func makeNudge() -> Nudge {
        let now = Date()
        return Nudge(
            id: UUID(),
            label: "Stand up",
            schedule: "0 9 * * 1,2,3,4,5",
            active: true,
            lastFiredAt: nil,
            createdAt: now,
            updatedAt: now
        )
    }

    private static func makeFocusSession() -> CompletedFocusSession {
        let ended = Date()
        return CompletedFocusSession(
            id: UUID(),
            taskId: nil,
            taskTitle: "A finished sprint",
            lifeAreaEmoji: "🌱",
            plannedSeconds: 1500,
            focusedSeconds: 1500,
            checkpointsReached: 3,
            completedNaturally: true,
            startedAt: ended.addingTimeInterval(-1500),
            endedAt: ended
        )
    }

    private static func makeLog() -> Log {
        let now = Date()
        return Log(
            id: UUID(),
            lifeAreaId: nil,
            type: .journal,
            body: "An entry the append-only rules will not let the app delete on its own.",
            entryDate: now,
            createdAt: now
        )
    }
}

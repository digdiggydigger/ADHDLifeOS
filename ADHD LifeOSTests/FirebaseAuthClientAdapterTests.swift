//
//  FirebaseAuthClientAdapterTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The adapter carrying the cutover's one genuine data-shape compromise: Firebase UIDs are opaque
/// 28-character strings, while `AuthUser.id` is a `UUID` (a Cognito-era assumption). The UID is
/// hashed into a *stable* UUID, and "stable" is the whole contract — so it is what these tests
/// spend most of their effort on.
final class FirebaseAuthClientAdapterTests: XCTestCase {
    private var store: FakeAuthBackingStore!
    private var adapter: FirebaseAuthClientAdapter!

    override func setUp() {
        super.setUp()
        store = FakeAuthBackingStore()
        adapter = FirebaseAuthClientAdapter(store: store)
    }

    override func tearDown() {
        adapter = nil
        store = nil
        super.tearDown()
    }

    // MARK: - The derived UUID

    /// Same account, same `AuthUser.id`, every launch and every device. A non-deterministic
    /// derivation would look fine in one session and silently change identity in the next.
    func testDerivedId_isStableAcrossCalls() async throws {
        store.signInResult = FirebaseAuthUser(uid: "xcKeMrUiFoZRGQOEUMNW8y6aXmc2", email: "e@example.com")

        let first = try await adapter.signIn(email: "e@example.com", password: "pw")
        let second = try await adapter.signIn(email: "e@example.com", password: "pw")

        XCTAssertEqual(first.id, second.id)
    }

    func testDerivedId_differsBetweenAccounts() async throws {
        store.signInResult = FirebaseAuthUser(uid: "uid-one", email: nil)
        let first = try await adapter.signIn(email: "a@example.com", password: "pw")

        store.signInResult = FirebaseAuthUser(uid: "uid-two", email: nil)
        let second = try await adapter.signIn(email: "b@example.com", password: "pw")

        XCTAssertNotEqual(first.id, second.id)
    }

    /// The derivation stamps RFC 4122 version and variant bits, so the result is a well-formed
    /// UUID rather than 16 arbitrary bytes wearing a UUID's clothes.
    func testDerivedId_isAWellFormedRFC4122UUID() async throws {
        store.signInResult = FirebaseAuthUser(uid: "xcKeMrUiFoZRGQOEUMNW8y6aXmc2", email: nil)

        let user = try await adapter.signIn(email: "e@example.com", password: "pw")

        let characters = Array(user.id.uuidString)
        XCTAssertEqual(characters[14], "5", "version nibble")
        XCTAssertTrue("89AB".contains(characters[19]), "variant nibble, got \(characters[19])")
    }

    /// The derived value is for `AuthUser` only — every Firestore path is scoped by the raw
    /// Firebase UID, never this. Nothing should be able to round-trip it back to a UID.
    func testDerivedId_isNotTheRawUID() async throws {
        store.signInResult = FirebaseAuthUser(uid: "xcKeMrUiFoZRGQOEUMNW8y6aXmc2", email: nil)

        let user = try await adapter.signIn(email: "e@example.com", password: "pw")

        XCTAssertFalse(user.id.uuidString.contains("xcKeMrUi"))
    }

    // MARK: - Restore

    func testRestoredUser_withNoSession_isNil() async {
        store.currentUser = nil

        let user = await adapter.restoredUser()

        XCTAssertNil(user)
        XCTAssertEqual(store.seedCallCount, 0, "nothing to seed without a session")
    }

    func testRestoredUser_returnsTheSignedInUser() async {
        store.currentUser = FirebaseAuthUser(uid: "uid-restored", email: "e@example.com")

        let user = await adapter.restoredUser()

        XCTAssertEqual(user?.email, "e@example.com")
    }

    /// An account whose first entry into the app is a restored session — console-created, or a
    /// reinstall — still gets the starter content.
    func testRestoredUser_seedsStarterContent() async {
        store.currentUser = FirebaseAuthUser(uid: "uid-restored", email: nil)

        _ = await adapter.restoredUser()

        XCTAssertEqual(store.seedCallCount, 1)
    }

    /// Seeding is best-effort: a session that is already live must not be thrown away because the
    /// starter content could not be written.
    func testRestoredUser_survivesASeedingFailure() async {
        store.currentUser = FirebaseAuthUser(uid: "uid-restored", email: "e@example.com")
        store.seedError = FirebaseManagerError.notSignedIn

        let user = await adapter.restoredUser()

        XCTAssertNotNil(user)
    }

    // MARK: - Sign in

    func testSignIn_forwardsTheCredentials() async throws {
        _ = try await adapter.signIn(email: "e@example.com", password: "hunter2")

        XCTAssertEqual(store.signInCredentials.first?.email, "e@example.com")
        XCTAssertEqual(store.signInCredentials.first?.password, "hunter2")
    }

    func testSignIn_wrapsFailureAsInvalidCredentials() async {
        store.signInError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.signIn(email: "e@example.com", password: "wrong")) { error in
            XCTAssertEqual(error as? AuthServiceError, .invalidCredentials(Self.notSignedInMessage))
        }
    }

    // MARK: - Sign in with Apple

    func testSignInWithApple_forwardsTheTokenNonceAndName() async throws {
        _ = try await adapter.signInWithApple(idToken: "token", rawNonce: "nonce", displayName: "E")

        XCTAssertEqual(store.appleCredentials.first?.idToken, "token")
        XCTAssertEqual(store.appleCredentials.first?.rawNonce, "nonce", "Firebase re-hashes this to reject replays")
        XCTAssertEqual(store.appleCredentials.first?.displayName, "E")
    }

    func testSignInWithApple_wrapsFailureWithItsOwnCase() async {
        store.appleSignInError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(
            try await adapter.signInWithApple(idToken: "token", rawNonce: "nonce", displayName: nil)
        ) { error in
            XCTAssertEqual(error as? AuthServiceError, .appleSignInFailed(Self.notSignedInMessage))
        }
    }

    // MARK: - Magic links: stubbed, not silently no-op

    /// Email/password is the only sign-in path. These throw rather than quietly doing nothing, so
    /// a caller can never sit waiting for a link that was never sent.
    func testRequestOTP_isUnavailable() async {
        await XCTAssertThrowsErrorAsync(
            try await adapter.requestOTP(email: "e@example.com", redirectTo: nil)
        ) { error in
            guard case .magicLinkUnavailable = error as? AuthServiceError else {
                return XCTFail("expected .magicLinkUnavailable, got \(error)")
            }
        }
    }

    func testCompleteSession_isUnavailable() async {
        let url = URL(string: "https://example.com/callback")!

        await XCTAssertThrowsErrorAsync(try await adapter.completeSession(from: url)) { error in
            guard case .magicLinkUnavailable = error as? AuthServiceError else {
                return XCTFail("expected .magicLinkUnavailable, got \(error)")
            }
        }
    }

    // MARK: - Sign out

    func testSignOut_forwardsToTheStore() async throws {
        try await adapter.signOut()

        XCTAssertEqual(store.signOutCallCount, 1)
    }

    func testSignOut_wrapsFailure() async {
        store.signOutError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.signOut()) { error in
            XCTAssertEqual(error as? AuthServiceError, .signOutFailed(Self.notSignedInMessage))
        }
    }

    // MARK: - ID token

    func testValidIDToken_returnsTheToken() async throws {
        store.storedIDToken = "a-real-token"

        let token = try await adapter.validIDToken()

        XCTAssertEqual(token, "a-real-token")
    }

    /// Callers must treat a throw as a forced sign-out, so "no session" cannot come back as an
    /// empty string or a nil that reads as success.
    func testValidIDToken_withNoSession_isASessionExpiry() async {
        store.storedIDToken = nil

        await XCTAssertThrowsErrorAsync(try await adapter.validIDToken()) { error in
            guard case .sessionExpired = error as? AuthServiceError else {
                return XCTFail("expected .sessionExpired, got \(error)")
            }
        }
    }

    /// A rejected refresh token is equally a forced sign-out.
    func testValidIDToken_whenTheRefreshFails_isASessionExpiry() async {
        store.idTokenError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.validIDToken()) { error in
            XCTAssertEqual(error as? AuthServiceError, .sessionExpired(Self.notSignedInMessage))
        }
    }

    private static let notSignedInMessage = FirebaseManagerError.notSignedIn.errorDescription ?? ""
}

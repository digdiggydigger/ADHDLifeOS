//
//  FirebaseAccountDeletionAdapterTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The App Store 5.1.1(v) erasure path, and until now the largest untested piece of the app
/// (0.00%, 0/46). Its one non-trivial job is telling `requiresRecentLogin` — a *pause* for
/// reauthentication — apart from every other failure, which is terminal. Getting that backwards
/// either strands the user on an error they could have cleared, or hides a real failure behind a
/// password prompt that will never succeed.
final class FirebaseAccountDeletionAdapterTests: XCTestCase {
    private var store: FakeAccountDeletionBackingStore!
    private var adapter: FirebaseAccountDeletionAdapter!

    override func setUp() {
        super.setUp()
        store = FakeAccountDeletionBackingStore()
        adapter = FirebaseAccountDeletionAdapter(store: store)
    }

    override func tearDown() {
        adapter = nil
        store = nil
        super.tearDown()
    }

    // MARK: - Which proof of identity the account can offer

    func testReauthMethod_passesThroughTheLinkedProvider() async {
        for method in [AccountReauthMethod.password, .apple] {
            store.reauthMethod = method

            let resolved = await adapter.reauthMethod()

            XCTAssertEqual(resolved, method)
        }
    }

    /// `nil` when nobody is signed in. Deletion will fail anyway, but the UI must not be asked to
    /// collect a proof that doesn't exist.
    func testReauthMethod_isNilWithNoSignedInUser() async {
        store.reauthMethod = nil

        let resolved = await adapter.reauthMethod()

        XCTAssertNil(resolved)
    }

    // MARK: - Data deletion

    func testDeleteAllUserData_succeedsQuietly() async throws {
        try await adapter.deleteAllUserData()

        XCTAssertEqual(store.deleteDataCallCount, 1)
    }

    /// A rejected Firestore delete has to surface as its own case: the caller must then NOT delete
    /// the auth account, or the remaining data is orphaned behind rules that scope every document
    /// to an owner who no longer exists.
    func testDeleteAllUserData_wrapsFailureAsDataDeletionFailed() async {
        store.deleteDataError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.deleteAllUserData()) { error in
            XCTAssertEqual(error as? AccountDeletionError, .dataDeletionFailed(Self.notSignedInMessage))
        }
    }

    /// The journal cascade is the one that needed the 2026-08-19 rules revision allowing owner
    /// delete on `logs`. Under the earlier append-only rules it is rejected — and that must abort
    /// deletion rather than press on to the auth account.
    func testDeleteAllUserData_aRejectedCascadeIsNotSwallowed() async {
        store.deleteDataError = Self.permissionDenied

        await XCTAssertThrowsErrorAsync(try await adapter.deleteAllUserData()) { error in
            guard case .dataDeletionFailed = error as? AccountDeletionError else {
                return XCTFail("expected .dataDeletionFailed, got \(error)")
            }
        }
        XCTAssertEqual(store.deleteAuthCallCount, 0, "the auth account must not be touched after a failed cascade")
    }

    // MARK: - Auth deletion: the pause-vs-terminal distinction

    func testDeleteAuthAccount_succeedsQuietly() async throws {
        try await adapter.deleteAuthAccount()

        XCTAssertEqual(store.deleteAuthCallCount, 1)
    }

    /// Firebase demanding a fresh sign-in before a destructive call is a pause, not a failure.
    func testDeleteAuthAccount_requiresRecentLoginBecomesTheTypedPause() async {
        store.deleteAuthError = Self.requiresRecentLogin

        await XCTAssertThrowsErrorAsync(try await adapter.deleteAuthAccount()) { error in
            XCTAssertEqual(error as? AccountDeletionError, .recentLoginRequired)
        }
    }

    func testDeleteAuthAccount_anyOtherFailureIsTerminal() async {
        store.deleteAuthError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.deleteAuthAccount()) { error in
            XCTAssertEqual(error as? AccountDeletionError, .accountDeletionFailed(Self.notSignedInMessage))
        }
    }

    /// The domain check is load-bearing, exactly as it is for Firestore's `notFound`: the same
    /// numeric code from another domain is not Firebase Auth's recent-login demand, and treating it
    /// as one would prompt for a password that cannot fix anything.
    func testDeleteAuthAccount_theSameCodeFromAnotherDomainIsNotAPause() async {
        store.deleteAuthError = NSError(
            domain: "SomeOtherDomain", code: AuthErrorMapping.requiresRecentLoginCode
        )

        await XCTAssertThrowsErrorAsync(try await adapter.deleteAuthAccount()) { error in
            guard case .accountDeletionFailed = error as? AccountDeletionError else {
                return XCTFail("expected .accountDeletionFailed, got \(error)")
            }
        }
    }

    /// A different Auth error is still terminal — only the recent-login code is a pause.
    func testDeleteAuthAccount_anotherAuthErrorCodeIsStillTerminal() async {
        store.deleteAuthError = NSError(
            domain: AuthErrorMapping.errorDomain, code: AuthErrorMapping.requiresRecentLoginCode + 1
        )

        await XCTAssertThrowsErrorAsync(try await adapter.deleteAuthAccount()) { error in
            guard case .accountDeletionFailed = error as? AccountDeletionError else {
                return XCTFail("expected .accountDeletionFailed, got \(error)")
            }
        }
    }

    // MARK: - Reauthentication

    func testReauthenticateWithPassword_forwardsThePassword() async throws {
        try await adapter.reauthenticate(password: "hunter2")

        XCTAssertEqual(store.passwords, ["hunter2"])
    }

    /// A wrong password is a plain failure the user can retry — never `recentLoginRequired`, which
    /// would loop the flow back to the prompt they just answered.
    func testReauthenticateWithPassword_wrapsFailureAsReauthenticationFailed() async {
        store.passwordReauthError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.reauthenticate(password: "wrong")) { error in
            XCTAssertEqual(error as? AccountDeletionError, .reauthenticationFailed(Self.notSignedInMessage))
        }
    }

    /// Even a `requiresRecentLogin`-shaped error here stays a reauthentication failure: this call
    /// *is* the recent login, so re-prompting for one would spin.
    func testReauthenticateWithPassword_doesNotRemapToRecentLoginRequired() async {
        store.passwordReauthError = Self.requiresRecentLogin

        await XCTAssertThrowsErrorAsync(try await adapter.reauthenticate(password: "hunter2")) { error in
            guard case .reauthenticationFailed = error as? AccountDeletionError else {
                return XCTFail("expected .reauthenticationFailed, got \(error)")
            }
        }
    }

    func testReauthenticateWithApple_forwardsTheTokenAndNonce() async throws {
        try await adapter.reauthenticateWithApple(idToken: "token", rawNonce: "nonce")

        XCTAssertEqual(store.appleCredentials.first?.idToken, "token")
        XCTAssertEqual(
            store.appleCredentials.first?.rawNonce, "nonce",
            "Firebase re-hashes the raw nonce to reject a replayed token"
        )
    }

    func testReauthenticateWithApple_wrapsFailureAsReauthenticationFailed() async {
        store.appleReauthError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(
            try await adapter.reauthenticateWithApple(idToken: "token", rawNonce: "nonce")
        ) { error in
            XCTAssertEqual(error as? AccountDeletionError, .reauthenticationFailed(Self.notSignedInMessage))
        }
    }

    private static let notSignedInMessage = FirebaseManagerError.notSignedIn.errorDescription ?? ""

    private static var requiresRecentLogin: Error {
        NSError(domain: AuthErrorMapping.errorDomain, code: AuthErrorMapping.requiresRecentLoginCode)
    }

    private static var permissionDenied: Error {
        NSError(
            domain: FirestoreErrorMapping.errorDomain,
            code: 7,
            userInfo: [NSLocalizedDescriptionKey: "Missing or insufficient permissions."]
        )
    }
}

/// Firebase Auth's error facts, derived from the SDK rather than hardcoded, for the same reason
/// `FirestoreErrorMapping` exposes its own: the unit-test target does not link the Firebase SDK, and
/// writing `"FIRAuthErrorDomain"`/17014 into a test would work today and drift silently.
final class AuthErrorMappingTests: XCTestCase {
    func testRecognisesFirebaseAuthsRecentLoginDemand() {
        let error = NSError(
            domain: AuthErrorMapping.errorDomain, code: AuthErrorMapping.requiresRecentLoginCode
        )

        XCTAssertTrue(AuthErrorMapping.isRecentLoginRequired(error))
    }

    func testRejectsAnotherAuthErrorCode() {
        let error = NSError(
            domain: AuthErrorMapping.errorDomain, code: AuthErrorMapping.requiresRecentLoginCode + 1
        )

        XCTAssertFalse(AuthErrorMapping.isRecentLoginRequired(error))
    }

    func testRejectsTheSameCodeFromAnotherDomain() {
        let error = NSError(domain: "SomeOtherDomain", code: AuthErrorMapping.requiresRecentLoginCode)

        XCTAssertFalse(AuthErrorMapping.isRecentLoginRequired(error))
    }

    func testRejectsAPlainSwiftError() {
        XCTAssertFalse(AuthErrorMapping.isRecentLoginRequired(FirebaseManagerError.notSignedIn))
    }
}

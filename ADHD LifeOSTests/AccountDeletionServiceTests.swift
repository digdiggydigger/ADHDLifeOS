//
//  AccountDeletionServiceTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The account-deletion state machine behind Settings → Delete Account (App Store 5.1.1(v)).
/// The two invariants everything else hangs off:
/// - Firestore data is deleted BEFORE the Auth account — once the Auth user is gone, the
///   security rules would forbid touching the data, so the reverse order orphans it forever.
/// - A `requiresRecentLogin` rejection pauses (never aborts) the flow for re-authentication,
///   and the post-reauth retry must NOT re-run the cascade the first attempt already finished.
@MainActor
final class AccountDeletionServiceTests: XCTestCase {
    private var client: FakeAccountDeletionClientAdapting!
    private var service: AccountDeletionService!

    override func setUp() {
        super.setUp()
        client = FakeAccountDeletionClientAdapting()
        service = AccountDeletionService(client: client)
    }

    // MARK: - Happy path

    func testRequestDeletion_deletesDataThenAccount_thenCompletes() async {
        await service.requestDeletion()

        XCTAssertEqual(service.phase, .completed)
        XCTAssertNil(service.errorMessage)
        XCTAssertEqual(client.callLog, ["deleteAllUserData", "deleteAuthAccount"])
    }

    // MARK: - Cascade failure aborts BEFORE the auth account is touched

    func testDataDeletionFailure_abortsWithoutTouchingAuthAccount() async {
        client.deleteAllUserDataResult = .failure(
            AccountDeletionError.dataDeletionFailed("rules rejected the journal delete")
        )

        await service.requestDeletion()

        XCTAssertEqual(service.phase, .idle)
        XCTAssertEqual(service.errorMessage, "rules rejected the journal delete")
        XCTAssertEqual(client.deleteAuthAccountCallCount, 0)
    }

    // MARK: - Stale session → reauth → retry

    func testRecentLoginRequired_pausesForReauth_withTheClientsMethod() async {
        client.reauthMethodResult = .apple
        client.deleteAuthAccountResults = [.failure(AccountDeletionError.recentLoginRequired)]

        await service.requestDeletion()

        XCTAssertEqual(service.phase, .reauthRequired(.apple))
        XCTAssertNil(service.errorMessage, "Needing reauth is a pause, not an error")
    }

    func testPasswordReauth_retriesAccountDelete_withoutRerunningTheCascade() async {
        client.deleteAuthAccountResults = [
            .failure(AccountDeletionError.recentLoginRequired),
            .success(())
        ]
        await service.requestDeletion()
        XCTAssertEqual(service.phase, .reauthRequired(.password))

        await service.completeReauth(password: "hunter2")

        XCTAssertEqual(service.phase, .completed)
        XCTAssertEqual(client.lastReauthPassword, "hunter2")
        XCTAssertEqual(client.deleteAllUserDataCallCount, 1, "Cascade must not re-run after reauth")
        XCTAssertEqual(client.deleteAuthAccountCallCount, 2)
    }

    func testAppleReauth_retriesAccountDelete() async {
        client.reauthMethodResult = .apple
        client.deleteAuthAccountResults = [
            .failure(AccountDeletionError.recentLoginRequired),
            .success(())
        ]
        await service.requestDeletion()

        await service.completeAppleReauth(idToken: "jwt", rawNonce: "nonce")

        XCTAssertEqual(service.phase, .completed)
        XCTAssertEqual(client.lastAppleIDToken, "jwt")
        XCTAssertEqual(client.lastAppleRawNonce, "nonce")
        XCTAssertEqual(client.deleteAllUserDataCallCount, 1)
    }

    func testFailedReauth_staysInReauthPhase_withError() async {
        client.deleteAuthAccountResults = [.failure(AccountDeletionError.recentLoginRequired)]
        client.reauthenticatePasswordResult = .failure(
            AccountDeletionError.reauthenticationFailed("Wrong password.")
        )
        await service.requestDeletion()

        await service.completeReauth(password: "wrong")

        XCTAssertEqual(service.phase, .reauthRequired(.password))
        XCTAssertEqual(service.errorMessage, "Wrong password.")
    }

    func testCancelReauth_returnsToIdle() async {
        client.deleteAuthAccountResults = [.failure(AccountDeletionError.recentLoginRequired)]
        await service.requestDeletion()

        service.cancel()

        XCTAssertEqual(service.phase, .idle)
        XCTAssertNil(service.errorMessage)
    }

    // MARK: - Generic auth-delete failure

    func testGenericAccountDeleteFailure_surfacesErrorAndReturnsToIdle() async {
        client.deleteAuthAccountResults = [
            .failure(AccountDeletionError.accountDeletionFailed("network down"))
        ]

        await service.requestDeletion()

        XCTAssertEqual(service.phase, .idle)
        XCTAssertEqual(service.errorMessage, "network down")
    }
}

/// Deletion's final hand-off: the Auth user no longer exists, so this must not route through
/// `signOut()` (whose client call could fail) — it just resets local state to `signedOut`,
/// which `RootView` animates back to `LoginView`.
@MainActor
final class AuthServiceAccountDeletionTests: XCTestCase {
    func testCompleteAccountDeletion_resetsToSignedOut() async {
        let client = FakeAuthClientAdapting()
        client.signInResult = .success(AuthUser(id: UUID(), email: "e@example.com"))
        let service = AuthService(client: client)
        await service.signIn(email: "e@example.com", password: "pw")
        guard case .signedIn = service.state else {
            return XCTFail("Precondition: expected signedIn")
        }

        service.completeAccountDeletion()

        XCTAssertEqual(service.state, .signedOut)
        XCTAssertNil(service.errorMessage)
        XCTAssertEqual(client.signOutCallCount, 0, "The deleted account has no session to sign out")
    }
}

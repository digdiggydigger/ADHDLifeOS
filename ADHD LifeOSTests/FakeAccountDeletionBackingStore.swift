//
//  FakeAccountDeletionBackingStore.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

/// Recording stand-in for the Firebase surface behind `FirebaseAccountDeletionAdapter`.
///
/// Records every call before throwing any configured error, so "was called and failed" stays
/// distinguishable from "was never called" — which matters more here than anywhere else: the
/// ordering contract is that data deletion must complete before the auth account is touched, and
/// proving a call did *not* happen is how that gets asserted.
final class FakeAccountDeletionBackingStore: AccountDeletionBackingStore {
    var reauthMethod: AccountReauthMethod?

    var deleteDataError: Error?
    var deleteAuthError: Error?
    var passwordReauthError: Error?
    var appleReauthError: Error?

    private(set) var reauthMethodCallCount = 0
    private(set) var deleteDataCallCount = 0
    private(set) var deleteAuthCallCount = 0
    private(set) var passwords: [String] = []
    private(set) var appleCredentials: [AppleReauth] = []

    /// Named record rather than a tuple — SwiftLint caps tuples at two members.
    struct AppleReauth {
        let idToken: String
        let rawNonce: String
    }

    func accountReauthMethod() -> AccountReauthMethod? {
        reauthMethodCallCount += 1
        return reauthMethod
    }

    func deleteAllUserData() async throws {
        deleteDataCallCount += 1
        if let deleteDataError { throw deleteDataError }
    }

    func deleteAuthUser() async throws {
        deleteAuthCallCount += 1
        if let deleteAuthError { throw deleteAuthError }
    }

    func reauthenticateWithPassword(_ password: String) async throws {
        passwords.append(password)
        if let passwordReauthError { throw passwordReauthError }
    }

    func reauthenticateWithApple(idToken: String, rawNonce: String) async throws {
        appleCredentials.append(AppleReauth(idToken: idToken, rawNonce: rawNonce))
        if let appleReauthError { throw appleReauthError }
    }
}

//
//  FakeAccountDeletionClientAdapting.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

final class FakeAccountDeletionClientAdapting: AccountDeletionClientAdapting, @unchecked Sendable {
    var reauthMethodResult: AccountReauthMethod? = .password
    var deleteAllUserDataResult: Result<Void, Error> = .success(())
    /// Consumed in order — lets a test make the FIRST auth-delete attempt fail with
    /// `recentLoginRequired` and the post-reauth retry succeed.
    var deleteAuthAccountResults: [Result<Void, Error>] = [.success(())]
    var reauthenticatePasswordResult: Result<Void, Error> = .success(())
    var reauthenticateAppleResult: Result<Void, Error> = .success(())

    /// Call order across every method, so tests can assert data-before-account sequencing.
    private(set) var callLog: [String] = []
    private(set) var deleteAllUserDataCallCount = 0
    private(set) var deleteAuthAccountCallCount = 0
    private(set) var lastReauthPassword: String?
    private(set) var lastAppleIDToken: String?
    private(set) var lastAppleRawNonce: String?

    func reauthMethod() async -> AccountReauthMethod? {
        callLog.append("reauthMethod")
        return reauthMethodResult
    }

    func deleteAllUserData() async throws {
        callLog.append("deleteAllUserData")
        deleteAllUserDataCallCount += 1
        try deleteAllUserDataResult.get()
    }

    func deleteAuthAccount() async throws {
        callLog.append("deleteAuthAccount")
        deleteAuthAccountCallCount += 1
        let result = deleteAuthAccountResults.isEmpty
            ? .success(())
            : deleteAuthAccountResults.removeFirst()
        try result.get()
    }

    func reauthenticate(password: String) async throws {
        callLog.append("reauthenticate(password)")
        lastReauthPassword = password
        try reauthenticatePasswordResult.get()
    }

    func reauthenticateWithApple(idToken: String, rawNonce: String) async throws {
        callLog.append("reauthenticateWithApple")
        lastAppleIDToken = idToken
        lastAppleRawNonce = rawNonce
        try reauthenticateAppleResult.get()
    }
}

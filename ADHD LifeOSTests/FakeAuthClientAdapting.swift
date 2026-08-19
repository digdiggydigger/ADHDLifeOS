//
//  FakeAuthClientAdapting.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

final class FakeAuthClientAdapting: AuthClientAdapting, @unchecked Sendable {
    var restoredUserResult: AuthUser?
    var signInResult: Result<AuthUser, Error> = .failure(
        AuthServiceError.invalidCredentials("not configured")
    )
    var requestOTPResult: Result<Void, Error> = .success(())
    var completeSessionResult: Result<AuthUser, Error> = .failure(
        AuthServiceError.sessionExchangeFailed("not configured")
    )
    var signOutResult: Result<Void, Error> = .success(())
    var validIDTokenResult: Result<String, Error> = .success("fake-id-token")
    var signInWithAppleResult: Result<AuthUser, Error> = .failure(
        AuthServiceError.appleSignInFailed("not configured")
    )

    private(set) var signInCallCount = 0
    private(set) var signInWithAppleCallCount = 0
    private(set) var lastAppleIDToken: String?
    private(set) var lastAppleRawNonce: String?
    private(set) var lastAppleDisplayName: String?
    private(set) var lastSignInEmail: String?
    private(set) var lastSignInPassword: String?
    private(set) var requestOTPCallCount = 0
    private(set) var completeSessionCallCount = 0
    private(set) var signOutCallCount = 0
    private(set) var validIDTokenCallCount = 0
    private(set) var restoredUserCallCount = 0

    func restoredUser() async -> AuthUser? {
        restoredUserCallCount += 1
        return restoredUserResult
    }

    func signIn(email: String, password: String) async throws -> AuthUser {
        signInCallCount += 1
        lastSignInEmail = email
        lastSignInPassword = password
        return try signInResult.get()
    }

    func requestOTP(email: String, redirectTo: URL?) async throws {
        requestOTPCallCount += 1
        try requestOTPResult.get()
    }

    func completeSession(from url: URL) async throws -> AuthUser {
        completeSessionCallCount += 1
        return try completeSessionResult.get()
    }

    func signOut() async throws {
        signOutCallCount += 1
        try signOutResult.get()
    }

    func validIDToken() async throws -> String {
        validIDTokenCallCount += 1
        return try validIDTokenResult.get()
    }

    func signInWithApple(idToken: String, rawNonce: String, displayName: String?) async throws -> AuthUser {
        signInWithAppleCallCount += 1
        lastAppleIDToken = idToken
        lastAppleRawNonce = rawNonce
        lastAppleDisplayName = displayName
        return try signInWithAppleResult.get()
    }
}

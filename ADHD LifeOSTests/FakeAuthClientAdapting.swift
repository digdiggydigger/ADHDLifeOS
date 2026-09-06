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
    var signUpResult: Result<AuthUser, Error> = .failure(
        AuthServiceError.signUpFailed("not configured")
    )
    var sendPasswordResetResult: Result<Void, Error> = .success(())
    var updateDisplayNameResult: Result<AuthUser, Error> = .failure(
        AuthServiceError.displayNameUpdateFailed("not configured")
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
    private(set) var signUpCallCount = 0
    private(set) var lastSignUpEmail: String?
    private(set) var lastSignUpPassword: String?
    private(set) var lastSignUpDisplayName: String?
    private(set) var sendPasswordResetCallCount = 0
    private(set) var lastPasswordResetEmail: String?
    /// Recorded separately from the value, because `nil` is a MEANINGFUL argument here — clearing
    /// the name — and "was it called with nil" and "was it called at all" are different questions.
    private(set) var updateDisplayNameCalled = false
    private(set) var lastUpdatedDisplayName: String?

    func updateDisplayName(_ displayName: String?) async throws -> AuthUser {
        updateDisplayNameCalled = true
        lastUpdatedDisplayName = displayName
        return try updateDisplayNameResult.get()
    }

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

    func signUp(email: String, password: String, displayName: String?) async throws -> AuthUser {
        signUpCallCount += 1
        lastSignUpEmail = email
        lastSignUpPassword = password
        lastSignUpDisplayName = displayName
        return try signUpResult.get()
    }

    func sendPasswordReset(email: String) async throws {
        sendPasswordResetCallCount += 1
        lastPasswordResetEmail = email
        try sendPasswordResetResult.get()
    }

    func requestOTP(email: String, redirectTo: URL?) async throws {
        requestOTPCallCount += 1
        try requestOTPResult.get()
    }

    func completeSession(from url: URL) async throws -> AuthUser {
        completeSessionCallCount += 1
        return try completeSessionResult.get()
    }

    /// Fires as the client signs out, so a test can assert what ran BEFORE it.
    var onSignOut: (() -> Void)?

    func signOut() async throws {
        signOutCallCount += 1
        onSignOut?()
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

//
//  FakeAuthBackingStore.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

/// Recording stand-in for the Firebase Auth surface behind `FirebaseAuthClientAdapter`.
final class FakeAuthBackingStore: AuthBackingStore {
    var currentUser: FirebaseAuthUser?
    var signInResult = FirebaseAuthUser(uid: "uid-signed-in", email: "e@example.com")
    var signUpResult = FirebaseAuthUser(uid: "uid-new", email: "e@example.com")
    var appleSignInResult = FirebaseAuthUser(uid: "uid-apple", email: "e@privaterelay.appleid.com")
    var storedIDToken: String? = "id-token"

    var signInError: Error?
    var signUpError: Error?
    var passwordResetError: Error?
    var appleSignInError: Error?
    var signOutError: Error?
    var seedError: Error?
    var idTokenError: Error?

    private(set) var seedCallCount = 0
    private(set) var signInCredentials: [Credentials] = []
    private(set) var appleCredentials: [AppleCredentials] = []
    private(set) var signOutCallCount = 0
    private(set) var signUpCredentials: [SignUpCredentials] = []
    private(set) var passwordResetEmails: [String] = []

    /// Named records rather than tuples — SwiftLint caps tuples at two members.
    struct Credentials {
        let email: String
        let password: String
    }

    struct SignUpCredentials {
        let email: String
        let password: String
        let displayName: String?
    }

    struct AppleCredentials {
        let idToken: String
        let rawNonce: String
        let displayName: String?
    }

    func seedDefaultContentIfNeeded() async throws {
        seedCallCount += 1
        if let seedError { throw seedError }
    }

    func signIn(email: String, password: String) async throws -> FirebaseAuthUser {
        signInCredentials.append(Credentials(email: email, password: password))
        if let signInError { throw signInError }
        return signInResult
    }

    func signUp(email: String, password: String, displayName: String?) async throws -> FirebaseAuthUser {
        signUpCredentials.append(
            SignUpCredentials(email: email, password: password, displayName: displayName)
        )
        if let signUpError { throw signUpError }
        return signUpResult
    }

    func sendPasswordReset(email: String) async throws {
        passwordResetEmails.append(email)
        if let passwordResetError { throw passwordResetError }
    }

    func signInWithApple(idToken: String, rawNonce: String, displayName: String?) async throws -> FirebaseAuthUser {
        appleCredentials.append(
            AppleCredentials(idToken: idToken, rawNonce: rawNonce, displayName: displayName)
        )
        if let appleSignInError { throw appleSignInError }
        return appleSignInResult
    }

    func signOut() throws {
        signOutCallCount += 1
        if let signOutError { throw signOutError }
    }

    func idToken(forcingRefresh: Bool) async throws -> String? {
        if let idTokenError { throw idTokenError }
        return storedIDToken
    }
}

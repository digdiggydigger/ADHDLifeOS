//
//  AuthBackingStore.swift
//  ADHD LifeOS
//

import Foundation

/// The Firebase Auth surface `FirebaseAuthClientAdapter` uses. See `LifeAreaEditorBackingStore`
/// for why the seam exists and why it is one narrow protocol per adapter.
///
/// This is the store that changed its adapter most: `validIDToken()` previously reached
/// `Auth.auth().currentUser` directly, bypassing the manager entirely, which nothing could stub.
/// It now goes through `idToken(forcingRefresh:)` like every other call.
protocol AuthBackingStore {
    var currentUser: FirebaseAuthUser? { get }
    func seedDefaultContentIfNeeded() async throws
    func signUp(email: String, password: String, displayName: String?) async throws -> FirebaseAuthUser
    func signIn(email: String, password: String) async throws -> FirebaseAuthUser
    func signInWithApple(idToken: String, rawNonce: String, displayName: String?) async throws -> FirebaseAuthUser
    func signOut() throws
    /// Firebase sends the email itself; there is no in-app "new password" screen and no token to
    /// carry. Succeeds whether or not the address has an account — see `AuthService`.
    func sendPasswordReset(email: String) async throws
    /// `nil` means no stored session; a throw means the refresh itself was rejected. Callers treat
    /// both as a forced sign-out, but only one of them is an error.
    func idToken(forcingRefresh: Bool) async throws -> String?
}

extension FirebaseManager: AuthBackingStore {}

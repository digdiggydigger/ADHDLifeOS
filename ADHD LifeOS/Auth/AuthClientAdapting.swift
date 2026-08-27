//
//  AuthClientAdapting.swift
//  ADHD LifeOS
//

import Foundation

/// Thin seam over the Supabase auth client so `AuthService` is testable without a network.
protocol AuthClientAdapting: Sendable {
    func restoredUser() async -> AuthUser?
    func signIn(email: String, password: String) async throws -> AuthUser
    /// Creates the account and returns the session it just opened — there is no separate
    /// sign-in step afterwards. `displayName` is already trimmed-to-nil by the caller.
    func signUp(email: String, password: String, displayName: String?) async throws -> AuthUser
    /// Asks the provider to email a reset link. Deliberately returns nothing on success: the
    /// screen's confirmation must not depend on whether the account exists.
    func sendPasswordReset(email: String) async throws
    func requestOTP(email: String, redirectTo: URL?) async throws
    func completeSession(from url: URL) async throws -> AuthUser
    func signOut() async throws

    /// Returns a current, non-expired ID token, transparently refreshing if the cached one has
    /// expired or is within a short buffer of expiring. Throws if the user is fully signed out
    /// (no stored session) or the refresh itself fails (e.g. a revoked/expired refresh token) —
    /// callers must treat a throw as a forced sign-out. Added in Stage C.1 for `life-os-api-gw`
    /// bearer-token auth; Supabase's own `AuthClient` never needed this since `PostgrestClient`
    /// read its session internally.
    func validIDToken() async throws -> String

    /// Exchanges an Apple identity token (plus the raw nonce whose SHA-256 digest rode in the
    /// authorization request) for a signed-in session. Takes Foundation values, not
    /// `ASAuthorization` — the view extracts them, so this seam stays constructible in tests.
    /// `displayName` is Apple's one-time-only full name from the FIRST authorization; adapters
    /// should persist it, since Apple never sends it again.
    func signInWithApple(idToken: String, rawNonce: String, displayName: String?) async throws -> AuthUser
}

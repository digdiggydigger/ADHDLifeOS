//
//  AuthClientAdapting.swift
//  ADHD LifeOS
//

import Foundation

/// Thin seam over the Supabase auth client so `AuthService` is testable without a network.
protocol AuthClientAdapting: Sendable {
    func restoredUser() async -> AuthUser?
    func signIn(email: String, password: String) async throws -> AuthUser
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
}

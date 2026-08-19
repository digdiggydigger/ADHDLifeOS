//
//  AccountDeletionClientAdapting.swift
//  ADHD LifeOS
//

import Foundation

/// Thin seam over the Firebase deletion/reauth calls so `AccountDeletionService` is testable
/// without a network — same `*Adapting` convention as every other feature.
protocol AccountDeletionClientAdapting: Sendable {
    /// Which proof of identity the signed-in account can offer for reauthentication, from its
    /// linked providers. `nil` when no user is signed in (deletion will fail anyway).
    func reauthMethod() async -> AccountReauthMethod?

    /// Deletes every per-user Firestore document (all subcollections + the profile doc) and
    /// makes a best-effort sweep of capture media in Storage. Throws
    /// `AccountDeletionError.dataDeletionFailed` if any Firestore delete is rejected — the
    /// caller must then NOT delete the auth account, or the remaining data is orphaned.
    func deleteAllUserData() async throws

    /// Deletes the Firebase Auth user. Throws `AccountDeletionError.recentLoginRequired` when
    /// Firebase demands a fresh sign-in before honouring the destructive call.
    func deleteAuthAccount() async throws

    func reauthenticate(password: String) async throws
    func reauthenticateWithApple(idToken: String, rawNonce: String) async throws
}

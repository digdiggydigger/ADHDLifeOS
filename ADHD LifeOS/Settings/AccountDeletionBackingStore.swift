//
//  AccountDeletionBackingStore.swift
//  ADHD LifeOS
//

import Foundation

/// The Firebase surface `FirebaseAccountDeletionAdapter` uses. See `LifeAreaEditorBackingStore`
/// for why the seam exists and why it is one narrow protocol per adapter.
///
/// Domain-neutral on purpose, mirroring `FirebaseManager+AccountDeletion`: raw Firebase errors come
/// through unmapped, and the adapter is the layer that turns them into `AccountDeletionError` —
/// including the `requiresRecentLogin` distinction that is the whole reason this adapter is worth
/// testing.
///
/// ORDERING CONTRACT, inherited from the manager: `deleteAllUserData()` must run to completion
/// BEFORE `deleteAuthUser()`. The security rules scope every document to the signed-in owner, so
/// once the auth user is gone the remaining data is unreachable by anyone but a console admin.
/// Enforcing that sequence is `AccountDeletionService`'s job, not this protocol's — but a fake here
/// can prove the auth call did not happen after a failed cascade.
protocol AccountDeletionBackingStore {
    func accountReauthMethod() -> AccountReauthMethod?
    func deleteAllUserData() async throws
    func deleteAuthUser() async throws
    func reauthenticateWithPassword(_ password: String) async throws
    func reauthenticateWithApple(idToken: String, rawNonce: String) async throws
}

extension FirebaseManager: AccountDeletionBackingStore {}

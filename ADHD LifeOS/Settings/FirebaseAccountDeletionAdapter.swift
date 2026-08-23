//
//  FirebaseAccountDeletionAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `AccountDeletionClientAdapting` over `AccountDeletionBackingStore`
/// (`FirebaseManager` in the app, a recording fake in tests): the domain-mapping half of the
/// manager/adapter split. Its one non-trivial job is telling `requiresRecentLogin` (a pause for
/// reauthentication) apart from every other failure (terminal, surfaced to the user).
struct FirebaseAccountDeletionAdapter: AccountDeletionClientAdapting {
    private let store: AccountDeletionBackingStore

    init(store: AccountDeletionBackingStore = FirebaseManager.shared) {
        self.store = store
    }

    func reauthMethod() async -> AccountReauthMethod? {
        store.accountReauthMethod()
    }

    func deleteAllUserData() async throws {
        do {
            try await store.deleteAllUserData()
        } catch {
            throw AccountDeletionError.dataDeletionFailed(Self.message(for: error))
        }
    }

    func deleteAuthAccount() async throws {
        do {
            try await store.deleteAuthUser()
        } catch where AuthErrorMapping.isRecentLoginRequired(error) {
            throw AccountDeletionError.recentLoginRequired
        } catch {
            throw AccountDeletionError.accountDeletionFailed(Self.message(for: error))
        }
    }

    /// Deliberately does **not** remap `requiresRecentLogin`: this call *is* the recent login, so
    /// re-prompting for one would loop the flow back to the prompt the user just answered.
    func reauthenticate(password: String) async throws {
        do {
            try await store.reauthenticateWithPassword(password)
        } catch {
            throw AccountDeletionError.reauthenticationFailed(Self.message(for: error))
        }
    }

    func reauthenticateWithApple(idToken: String, rawNonce: String) async throws {
        do {
            try await store.reauthenticateWithApple(idToken: idToken, rawNonce: rawNonce)
        } catch {
            throw AccountDeletionError.reauthenticationFailed(Self.message(for: error))
        }
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}

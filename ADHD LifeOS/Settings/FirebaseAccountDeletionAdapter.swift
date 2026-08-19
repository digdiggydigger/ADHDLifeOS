//
//  FirebaseAccountDeletionAdapter.swift
//  ADHD LifeOS
//

import FirebaseAuth
import Foundation

/// Production `AccountDeletionClientAdapting` over `FirebaseManager`: the domain-mapping half of
/// the manager/adapter split. Its one non-trivial job is telling `requiresRecentLogin` (a pause
/// for reauthentication) apart from every other failure (terminal, surfaced to the user).
struct FirebaseAccountDeletionAdapter: AccountDeletionClientAdapting {
    private let manager: FirebaseManager

    init(manager: FirebaseManager = .shared) {
        self.manager = manager
    }

    func reauthMethod() async -> AccountReauthMethod? {
        manager.accountReauthMethod()
    }

    func deleteAllUserData() async throws {
        do {
            try await manager.deleteAllUserData()
        } catch {
            throw AccountDeletionError.dataDeletionFailed(Self.message(for: error))
        }
    }

    func deleteAuthAccount() async throws {
        do {
            try await manager.deleteAuthUser()
        } catch where Self.isRecentLoginRequired(error) {
            throw AccountDeletionError.recentLoginRequired
        } catch {
            throw AccountDeletionError.accountDeletionFailed(Self.message(for: error))
        }
    }

    func reauthenticate(password: String) async throws {
        do {
            try await manager.reauthenticateWithPassword(password)
        } catch {
            throw AccountDeletionError.reauthenticationFailed(Self.message(for: error))
        }
    }

    func reauthenticateWithApple(idToken: String, rawNonce: String) async throws {
        do {
            try await manager.reauthenticateWithApple(idToken: idToken, rawNonce: rawNonce)
        } catch {
            throw AccountDeletionError.reauthenticationFailed(Self.message(for: error))
        }
    }

    private static func isRecentLoginRequired(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == AuthErrorDomain
            && nsError.code == AuthErrorCode.requiresRecentLogin.rawValue
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}

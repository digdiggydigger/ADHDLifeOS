//
//  AccountDeletionService.swift
//  ADHD LifeOS
//

import Combine
import Foundation

/// State machine for Settings → Delete Account (App Store 5.1.1(v)). Two ordering invariants,
/// both locked by `AccountDeletionServiceTests`:
///
/// - **Data before account.** Firestore's rules only let the OWNER touch `users/{uid}`, so the
///   cascade must finish while the auth user still exists; deleting the account first would
///   orphan the data beyond the app's reach. A cascade failure therefore aborts the whole flow
///   before the account is touched.
/// - **`requiresRecentLogin` pauses, never aborts.** The flow parks in
///   `.reauthRequired(method)` for the UI to collect a password or a fresh Apple grant, then
///   retries ONLY the account delete — the cascade that already ran is not repeated.
@MainActor
final class AccountDeletionService: ObservableObject {
    @Published private(set) var phase: AccountDeletionPhase = .idle
    @Published var errorMessage: String?

    private let client: AccountDeletionClientAdapting
    /// Survives the reauth pause so the retry skips the already-finished cascade. Never reset
    /// on cancel: the data really is gone, and re-seeding on next sign-in covers the half-state.
    private var hasDeletedData = false

    init(client: AccountDeletionClientAdapting) {
        self.client = client
    }

    var isBusy: Bool {
        switch phase {
        case .deletingData, .deletingAccount, .reauthenticating: return true
        case .idle, .reauthRequired, .completed: return false
        }
    }

    func requestDeletion() async {
        errorMessage = nil

        if !hasDeletedData {
            phase = .deletingData
            do {
                try await client.deleteAllUserData()
                hasDeletedData = true
            } catch {
                errorMessage = Self.message(for: error)
                phase = .idle
                return
            }
        }

        phase = .deletingAccount
        do {
            try await client.deleteAuthAccount()
            phase = .completed
        } catch AccountDeletionError.recentLoginRequired {
            phase = .reauthRequired(await client.reauthMethod() ?? .password)
        } catch {
            errorMessage = Self.message(for: error)
            phase = .idle
        }
    }

    func completeReauth(password: String) async {
        await performReauth(method: .password) {
            try await self.client.reauthenticate(password: password)
        }
    }

    func completeAppleReauth(idToken: String, rawNonce: String) async {
        await performReauth(method: .apple) {
            try await self.client.reauthenticateWithApple(idToken: idToken, rawNonce: rawNonce)
        }
    }

    func cancel() {
        errorMessage = nil
        phase = .idle
    }

    private func performReauth(method: AccountReauthMethod, _ reauth: () async throws -> Void) async {
        errorMessage = nil
        phase = .reauthenticating
        do {
            try await reauth()
        } catch {
            errorMessage = Self.message(for: error)
            phase = .reauthRequired(method)
            return
        }
        await requestDeletion()
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}

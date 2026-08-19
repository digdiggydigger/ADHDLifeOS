//
//  AccountDeletionModels.swift
//  ADHD LifeOS
//

import Foundation

/// How a stale session re-proves itself before Firebase will honour a destructive
/// `user.delete()`: with the account's password, or a fresh Sign in with Apple grant.
enum AccountReauthMethod: Equatable, Sendable {
    case password
    case apple
}

enum AccountDeletionError: LocalizedError, Equatable {
    /// Firebase's `requiresRecentLogin`: the session is too old for a destructive operation.
    /// A pause for re-authentication, never a terminal failure.
    case recentLoginRequired
    case dataDeletionFailed(String)
    case accountDeletionFailed(String)
    case reauthenticationFailed(String)

    var errorDescription: String? {
        switch self {
        case .recentLoginRequired:
            return "Please confirm it's you before deleting this account."
        case .dataDeletionFailed(let message),
             .accountDeletionFailed(let message),
             .reauthenticationFailed(let message):
            return message
        }
    }
}

/// The deletion flow's observable phase — one enum so the Settings UI derives every affordance
/// (progress rows, reauth prompts, button disabling) from a single source of truth (§6).
enum AccountDeletionPhase: Equatable, Sendable {
    case idle
    /// Firestore cascade in flight.
    case deletingData
    /// Auth-account delete in flight.
    case deletingAccount
    /// Paused: Firebase demanded a recent login; the UI must collect the matching proof.
    case reauthRequired(AccountReauthMethod)
    case reauthenticating
    /// The account and its data are gone; the caller resets auth state to signed-out.
    case completed
}

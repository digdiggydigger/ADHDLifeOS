//
//  FirebaseAuthClientAdapter.swift
//  ADHD LifeOS
//

import CryptoKit
import Foundation

/// Production `AuthClientAdapting` backed by Firebase Auth, replacing both the Cognito adapter
/// and the Supabase bridge. Two deliberate deviations, both with in-repo precedent:
///
/// - **`AuthUser.id` is derived, not native.** Firebase UIDs are opaque 28-char strings, while
///   `AuthUser.id` is a `UUID` (a Cognito-era assumption — its `sub` claims were UUIDs). Nothing
///   in the app consumes `AuthUser.id` semantically (checked at cutover: only preview stubs
///   construct one), so the UID is hashed into a *stable* UUID — same user, same UUID, every
///   launch. All Firestore scoping uses the raw Firebase UID, never this derived value.
/// - **Magic links throw `magicLinkUnavailable`,** exactly as `AWSAuthClientAdapter` did
///   (Stage C.1 stub-and-hide precedent): email/password is the only sign-in path. Password
///   RESET is a different thing and is real (2026-08-28) — Firebase owns that flow end to end,
///   so no token ever reaches the app.
struct FirebaseAuthClientAdapter: AuthClientAdapting {
    private let store: AuthBackingStore

    init(store: AuthBackingStore = FirebaseManager.shared) {
        self.store = store
    }

    func restoredUser() async -> AuthUser? {
        guard let user = store.currentUser else { return nil }
        // Same best-effort seeding hook as signIn/signUp: an account whose first entry into the
        // app is a restored session (console-created account, reinstalled device) — or whose
        // data was cleared server-side — still gets the starter content. The `seeded_at` marker
        // makes this a single cheap read on every normal launch.
        try? await store.seedDefaultContentIfNeeded()
        return Self.authUser(from: user)
    }

    func signIn(email: String, password: String) async throws -> AuthUser {
        do {
            return Self.authUser(from: try await store.signIn(email: email, password: password))
        } catch {
            throw AuthServiceError.invalidCredentials(Self.message(for: error))
        }
    }

    /// Creating an account IS signing in — Firebase opens the session as part of `createUser`,
    /// and `FirebaseManager.signUp` seeds the starter content on the way through, exactly as
    /// `signIn` does. Without that seeding a brand-new account would land on an empty Home with
    /// no life areas at all.
    func signUp(email: String, password: String, displayName: String?) async throws -> AuthUser {
        do {
            return Self.authUser(from: try await store.signUp(
                email: email, password: password, displayName: displayName
            ))
        } catch {
            throw AuthServiceError.signUpFailed(Self.message(for: error))
        }
    }

    func sendPasswordReset(email: String) async throws {
        do {
            try await store.sendPasswordReset(email: email)
        } catch {
            throw AuthServiceError.passwordResetFailed(Self.message(for: error))
        }
    }

    func signInWithApple(idToken: String, rawNonce: String, displayName: String?) async throws -> AuthUser {
        do {
            return Self.authUser(from: try await store.signInWithApple(
                idToken: idToken, rawNonce: rawNonce, displayName: displayName
            ))
        } catch {
            throw AuthServiceError.appleSignInFailed(Self.message(for: error))
        }
    }

    func requestOTP(email: String, redirectTo: URL?) async throws {
        throw AuthServiceError.magicLinkUnavailable(
            "Magic-link sign-in isn't available — use your email and password."
        )
    }

    func completeSession(from url: URL) async throws -> AuthUser {
        throw AuthServiceError.magicLinkUnavailable(
            "Magic-link sign-in isn't available — use your email and password."
        )
    }

    func signOut() async throws {
        do {
            try store.signOut()
        } catch {
            throw AuthServiceError.signOutFailed(Self.message(for: error))
        }
    }

    /// Kept for protocol completeness: the Firebase SDK attaches auth to Firestore/Storage calls
    /// itself, so unlike the AWS adapters nothing in the app consumes this token anymore.
    func validIDToken() async throws -> String {
        do {
            guard let token = try await store.idToken(forcingRefresh: false) else {
                throw AuthServiceError.sessionExpired("You've been signed out — please sign in again.")
            }
            return token
        } catch let error as AuthServiceError {
            throw error
        } catch {
            throw AuthServiceError.sessionExpired(Self.message(for: error))
        }
    }

    private static func authUser(from user: FirebaseAuthUser) -> AuthUser {
        AuthUser(id: stableUUID(fromFirebaseUID: user.uid), email: user.email)
    }

    /// SHA-256 the UID, take 16 bytes, stamp RFC 4122 version/variant bits — deterministic, so
    /// the same account maps to the same `AuthUser.id` across launches and devices.
    private static func stableUUID(fromFirebaseUID uid: String) -> UUID {
        let digest = SHA256.hash(data: Data(uid.utf8))
        var bytes = [UInt8](digest.prefix(16))
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}

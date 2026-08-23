//
//  AuthService.swift
//  ADHD LifeOS
//

import Combine
import Foundation

@MainActor
final class AuthService: ObservableObject {
    @Published private(set) var state: AuthState = .unknown
    @Published private(set) var errorMessage: String?

    private let client: AuthClientAdapting
    /// The authenticated (Cognito) client, exposed read-only so screens presented with only an
    /// `AuthService` (e.g. `SettingsView`) can build their own AWS adapters without re-threading the
    /// client through the whole view tree. Same instance that scopes every AWS request to the user.
    var authClient: AuthClientAdapting { client }
    private let redirectURL: URL?
    init(client: AuthClientAdapting, redirectURL: URL? = nil) {
        self.client = client
        self.redirectURL = redirectURL
    }

    func restoreSession() async {
        if let user = await client.restoredUser() {
            state = .signedIn(user)
        } else {
            state = .signedOut
        }
    }

    func signIn(email: String, password: String) async {
        errorMessage = nil
        do {
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
            let user = try await client.signIn(email: trimmedEmail, password: trimmedPassword)
            state = .signedIn(user)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    /// Sign in with Apple, after the view has extracted the identity token and raw nonce from
    /// `ASAuthorization`. No Supabase-bridge attempt: the bridge predates the Firebase cutover
    /// and is `nil` in production wiring; an Apple identity has no bridge password anyway.
    func signInWithApple(idToken: String, rawNonce: String, displayName: String?) async {
        errorMessage = nil
        do {
            let user = try await client.signInWithApple(
                idToken: idToken, rawNonce: rawNonce, displayName: displayName
            )
            state = .signedIn(user)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func requestMagicLink(email: String) async {
        errorMessage = nil
        do {
            try await client.requestOTP(email: email, redirectTo: redirectURL)
            state = .linkSent(email: email)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func completeSession(from url: URL) async {
        errorMessage = nil
        do {
            let user = try await client.completeSession(from: url)
            state = .signedIn(user)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    /// Hand-off from a completed account deletion: the Firebase user no longer exists, so this
    /// deliberately does NOT route through `signOut()` (whose client call could fail against a
    /// dead session) — it only resets local state, which `RootView` animates back to `LoginView`.
    func completeAccountDeletion() {
        errorMessage = nil
        state = .signedOut
    }

    func signOut() async {
        errorMessage = nil
        do {
            try await client.signOut()
            state = .signedOut
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

//
//  AuthService.swift
//  ADHD LifeOS
//

import Combine
import Foundation

@MainActor
final class AuthService: ObservableObject {
    @Published private(set) var state: AuthState = .unknown

    /// Who is signed in, or `nil` in every other state — including `.unknown`, where a session is
    /// still being restored and no answer is yet honest. Screens that show account facts read
    /// this rather than unwrapping `state` themselves, so "signed in" is spelled once.
    var signedInUser: AuthUser? {
        guard case .signedIn(let user) = state else { return nil }
        return user
    }
    @Published private(set) var errorMessage: String?
    /// The address a reset link was just sent to, or `nil`. Drives the screen's confirmation line
    /// — and it is set on EVERY successful request, whether or not that address has an account,
    /// because saying otherwise would make this screen an email-enumeration oracle.
    @Published private(set) var passwordResetSentTo: String?

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
        clearTransientMessages()
        do {
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
            let user = try await client.signIn(email: trimmedEmail, password: trimmedPassword)
            state = .signedIn(user)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    /// Creating an account and signing in are ONE step: Firebase opens the session as part of
    /// creating the user, so a success lands straight in `.signedIn` and `RootView` moves the app
    /// on by itself. Everything is normalized here rather than in the view, so the network only
    /// ever sees trimmed values and a blank name is `nil` rather than "".
    func signUp(email: String, password: String, displayName: String?) async {
        clearTransientMessages()
        guard let normalizedEmail = AuthFormValidation.normalizedEmail(email) else {
            errorMessage = AuthServiceError.signUpFailed(Self.notAnAddress).errorDescription
            return
        }
        do {
            let user = try await client.signUp(
                email: normalizedEmail,
                password: password.trimmingCharacters(in: .whitespacesAndNewlines),
                displayName: displayName.flatMap(AuthFormValidation.normalizedDisplayName)
            )
            state = .signedIn(user)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    /// Firebase owns the reset from here — the email, the web form, the new password — so there is
    /// no token to carry and no second screen to build. An implausible address is refused locally
    /// rather than sent, because the confirmation is deliberately identical for an address that
    /// has no account, and a silent no-op would be indistinguishable from success.
    func sendPasswordReset(email: String) async {
        clearTransientMessages()
        guard let normalizedEmail = AuthFormValidation.normalizedEmail(email) else {
            errorMessage = AuthServiceError.passwordResetFailed(Self.notAnAddress).errorDescription
            return
        }
        do {
            try await client.sendPasswordReset(email: normalizedEmail)
            passwordResetSentTo = normalizedEmail
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    /// Wipes whatever the last action left on screen. Called when the segmented control switches
    /// mode: a "reset link sent" line hanging over the Create form is a lie about what just
    /// happened, and so is a sign-in error over a sign-up attempt.
    func clearTransientMessages() {
        errorMessage = nil
        passwordResetSentTo = nil
    }

    private static let notAnAddress = "That doesn't look like an email address."

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

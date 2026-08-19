//
//  LoginView.swift
//  ADHD LifeOS
//

import AuthenticationServices
import SwiftUI

struct LoginView: View {
    @ObservedObject var authService: AuthService
    /// Cognito's admin-created, `AllowAdminCreateUserOnly` user pool has no OTP/magic-link path
    /// (Stage C.1). Defaults to `false` so the active adapter hides this UI, while the underlying
    /// state machine (`AuthService.requestMagicLink`/`.linkSent`) stays intact for a future
    /// reintroduction — stub-and-hide, not deletion.
    var showsMagicLink: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    @State private var email = ""
    @State private var password = ""
    @State private var isSubmittingPassword = false
    @State private var isSubmittingMagicLink = false
    /// The raw session nonce for the in-flight Apple authorization. Its SHA-256 digest rides in
    /// the Apple request; the raw value goes to Firebase, which verifies the pair (replay
    /// protection). Cleared the moment the authorization completes, success or not.
    @State private var currentAppleNonce: String?
    @State private var isSubmittingApple = false
    /// Apple-flow failures present as an alert (a modal flow deserves a modal error), while the
    /// email/password path keeps its established inline error line.
    @State private var appleAlertMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Sign in")
                .font(.largeTitle.bold())
                .tracking(-0.5)

            if showsMagicLink, case .linkSent(let sentEmail) = authService.state {
                checkYourEmailView(email: sentEmail)
            } else {
                appleSection
                orDivider
                formView
            }

            Spacer()
        }
        .padding(16)
        .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: isSubmittingApple)
        .alert(
            "Couldn't sign in with Apple",
            isPresented: Binding(
                get: { appleAlertMessage != nil },
                set: { if !$0 { appleAlertMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(appleAlertMessage ?? "")
        }
    }

    // MARK: - Sign in with Apple

    private var appleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SignInWithAppleButton(.signIn, onRequest: handleAppleRequest, onCompletion: handleAppleCompletion)
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 48)
                .allowsHitTesting(!isSubmittingApple && !isSubmittingPassword)
                .accessibilityIdentifier("signInWithAppleButton")

            if isSubmittingApple {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Completing sign-in…")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .transition(.opacity)
                .accessibilityIdentifier("appleSignInProgress")
            }
        }
    }

    private func handleAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = AppleSignInNonce.randomNonce()
        currentAppleNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = AppleSignInNonce.sha256Hex(nonce)
    }

    /// Extraction is the only part of the flow that touches `ASAuthorization` (unconstructible
    /// in tests), so it stays here and thin — everything after the guard goes through the
    /// tested `AuthService.signInWithApple` seam. A user-cancelled sheet is not an error.
    private func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        let rawNonce = currentAppleNonce
        currentAppleNonce = nil

        switch result {
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            appleAlertMessage = error.localizedDescription
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8),
                  let rawNonce else {
                appleAlertMessage = "Apple didn't return a usable credential — please try again."
                return
            }
            // Apple provides the full name ONLY on the very first authorization for this app;
            // format it now or lose it.
            let displayName = credential.fullName
                .map { PersonNameComponentsFormatter().string(from: $0) }
                .flatMap { $0.isEmpty ? nil : $0 }
            Task { await submitApple(idToken: idToken, rawNonce: rawNonce, displayName: displayName) }
        }
    }

    private func submitApple(idToken: String, rawNonce: String, displayName: String?) async {
        isSubmittingApple = true
        defer { isSubmittingApple = false }
        await authService.signInWithApple(idToken: idToken, rawNonce: rawNonce, displayName: displayName)
        // Success flips `authService.state` and RootView transitions to the tabs on its own;
        // a failure lands in `errorMessage`, mirrored into this flow's modal alert.
        if let message = authService.errorMessage {
            appleAlertMessage = message
        }
    }

    // MARK: - Email/password fallback

    private var orDivider: some View {
        HStack(spacing: 8) {
            VStack { Divider() }
            Text("or continue with email")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize()
            VStack { Divider() }
        }
        .accessibilityElement(children: .combine)
    }

    private var formView: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("loginEmailField")

            SecureField("Password", text: $password)
                .textContentType(.password)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("loginPasswordField")

            if let errorMessage = authService.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.octagon.fill")
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .accessibilityIdentifier("loginErrorMessage")
            }

            Button {
                Task { await submitPassword() }
            } label: {
                if isSubmittingPassword {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Sign In")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(email.isEmpty || password.isEmpty || isSubmittingPassword || isSubmittingApple)
            .accessibilityIdentifier("signInButton")

            if showsMagicLink {
                Button {
                    Task { await submitMagicLink() }
                } label: {
                    if isSubmittingMagicLink {
                        ProgressView()
                    } else {
                        Text("Email me a sign-in link")
                    }
                }
                .buttonStyle(.plain)
                .disabled(email.isEmpty || isSubmittingMagicLink)
                .accessibilityIdentifier("magicLinkButton")
            }
        }
    }

    private func checkYourEmailView(email: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Check your email")
                .font(.title2.bold())
            Text("We sent a sign-in link to \(email). Tap it on this device to continue.")
                .foregroundStyle(.secondary)
        }
        .accessibilityIdentifier("checkYourEmailState")
    }

    private func submitPassword() async {
        isSubmittingPassword = true
        defer { isSubmittingPassword = false }
        await authService.signIn(email: email, password: password)
    }

    private func submitMagicLink() async {
        isSubmittingMagicLink = true
        defer { isSubmittingMagicLink = false }
        await authService.requestMagicLink(email: email)
    }
}

#if DEBUG
private struct PreviewAuthClientAdapting: AuthClientAdapting {
    func restoredUser() async -> AuthUser? { nil }

    func signIn(email: String, password: String) async throws -> AuthUser {
        AuthUser(id: UUID(), email: email)
    }

    func requestOTP(email: String, redirectTo: URL?) async throws {}

    func completeSession(from url: URL) async throws -> AuthUser {
        AuthUser(id: UUID(), email: "preview@example.com")
    }

    func signOut() async throws {}

    func validIDToken() async throws -> String { "preview-token" }

    func signInWithApple(idToken: String, rawNonce: String, displayName: String?) async throws -> AuthUser {
        AuthUser(id: UUID(), email: "preview@privaterelay.appleid.com")
    }
}

#Preview("Light") {
    LoginView(authService: AuthService(client: PreviewAuthClientAdapting()))
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    LoginView(authService: AuthService(client: PreviewAuthClientAdapting()))
        .preferredColorScheme(.dark)
}
#endif

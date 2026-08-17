//
//  LoginView.swift
//  ADHD LifeOS
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var authService: AuthService
    /// Cognito's admin-created, `AllowAdminCreateUserOnly` user pool has no OTP/magic-link path
    /// (Stage C.1). Defaults to `false` so the active `AWSAuthClientAdapter` hides this UI, while
    /// the underlying state machine (`AuthService.requestMagicLink`/`.linkSent`) stays intact for
    /// a future reintroduction — stub-and-hide, not deletion.
    var showsMagicLink: Bool = false

    @State private var email = ""
    @State private var password = ""
    @State private var isSubmittingPassword = false
    @State private var isSubmittingMagicLink = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Sign in")
                .font(.largeTitle.bold())

            if showsMagicLink, case .linkSent(let sentEmail) = authService.state {
                checkYourEmailView(email: sentEmail)
            } else {
                formView
            }

            Spacer()
        }
        .padding()
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
                Text(errorMessage)
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
            .disabled(email.isEmpty || password.isEmpty || isSubmittingPassword)
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
        VStack(alignment: .leading, spacing: 12) {
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
}

#Preview {
    LoginView(authService: AuthService(client: PreviewAuthClientAdapting()))
}
#endif

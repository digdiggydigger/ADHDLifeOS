//
//  AccountDeletionSection.swift
//  ADHD LifeOS
//

import AuthenticationServices
import SwiftUI

/// Settings → Account → Delete Account (App Store 5.1.1(v)): the destructive row plus every
/// affordance of the flow — explicit "cannot be undone" confirmation, phase-specific progress,
/// the stale-session reauthentication prompts (password alert, or a fresh Sign in with Apple
/// grant in a sheet), and terminal-error alerts. Self-contained so `SettingsView` embeds one
/// line; the parent only learns of success via `onDeleted`.
struct AccountDeletionSection: View {
    @ObservedObject var service: AccountDeletionService
    /// Fired once the account and its data are gone — the parent resets auth state, which
    /// `RootView` animates back to `LoginView`.
    let onDeleted: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var showConfirmation = false
    @State private var showPasswordPrompt = false
    @State private var showAppleSheet = false
    @State private var reauthPassword = ""
    /// Set before the Apple sheet dismisses on a submitted grant, so `onDismiss` can tell a
    /// completed reauth from the user swiping the sheet away (which cancels the flow).
    @State private var appleReauthSubmitted = false

    var body: some View {
        Section {
            deleteRow
        } header: {
            Text("Delete Account")
        } footer: {
            Text(
                "Permanently deletes your account and everything in it — tasks, life areas, "
                + "journal, captures, nudges, and focus history. This cannot be undone."
            )
        }
        .confirmationDialog(
            "Delete your account?",
            isPresented: $showConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Account & All Data", role: .destructive) {
                Task { await service.requestDeletion() }
            }
            .accessibilityIdentifier("confirmDeleteAccountButton")
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "This permanently erases your account and every task, life area, journal "
                + "entry, capture, and focus session. This cannot be undone."
            )
        }
        .alert("Confirm it's you", isPresented: $showPasswordPrompt) {
            SecureField("Password", text: $reauthPassword)
            Button("Delete Account", role: .destructive) {
                let password = reauthPassword
                reauthPassword = ""
                Task { await service.completeReauth(password: password) }
            }
            .accessibilityIdentifier("reauthDeleteAccountButton")
            Button("Cancel", role: .cancel) {
                reauthPassword = ""
                service.cancel()
            }
        } message: {
            Text("Deleting an account needs a recent sign-in. Enter your password to continue.")
        }
        .sheet(isPresented: $showAppleSheet, onDismiss: handleAppleSheetDismiss) {
            appleReauthSheet
        }
        .alert(
            "Couldn't delete account",
            isPresented: Binding(
                get: { service.errorMessage != nil },
                set: { if !$0 { service.errorMessage = nil } }
            )
        ) {
            if case .reauthRequired(let method) = service.phase {
                Button("Try Again") {
                    service.errorMessage = nil
                    presentReauthUI(for: method)
                }
                Button("Cancel", role: .cancel) { service.cancel() }
            } else {
                Button("OK", role: .cancel) { service.errorMessage = nil }
            }
        } message: {
            Text(service.errorMessage ?? "")
        }
        .onChange(of: service.phase) { phase in
            switch phase {
            case .reauthRequired(let method) where service.errorMessage == nil:
                presentReauthUI(for: method)
            case .completed:
                onDeleted()
            default:
                break
            }
        }
    }

    // MARK: - Row

    @ViewBuilder
    private var deleteRow: some View {
        if let progressText {
            // Label-with-spinner, not colour or opacity, conveys the in-flight state (§4).
            HStack(spacing: 8) {
                ProgressView()
                Text(progressText)
                    .foregroundStyle(.secondary)
            }
            .accessibilityIdentifier("accountDeletionProgressRow")
        } else {
            Button(role: .destructive) {
                showConfirmation = true
            } label: {
                Text("Delete Account…")
            }
            .accessibilityIdentifier("deleteAccountButton")
        }
    }

    private var progressText: String? {
        switch service.phase {
        case .deletingData: return "Deleting your data…"
        case .deletingAccount: return "Removing your account…"
        case .reauthenticating: return "Confirming it's you…"
        case .idle, .reauthRequired, .completed: return nil
        }
    }

    private func presentReauthUI(for method: AccountReauthMethod) {
        switch method {
        case .password: showPasswordPrompt = true
        case .apple: showAppleSheet = true
        }
    }

    // MARK: - Apple reauthentication sheet

    private var appleReauthSheet: some View {
        AppleReauthSheetContent(
            colorScheme: colorScheme,
            onCredential: { idToken, rawNonce in
                appleReauthSubmitted = true
                showAppleSheet = false
                Task { await service.completeAppleReauth(idToken: idToken, rawNonce: rawNonce) }
            },
            onCancel: { showAppleSheet = false }
        )
        .presentationDetents([.medium])
    }

    private func handleAppleSheetDismiss() {
        if appleReauthSubmitted {
            appleReauthSubmitted = false
        } else if case .reauthRequired = service.phase {
            service.cancel()
        }
    }
}

/// The reauthentication sheet body: explains WHY Apple is being asked again, then runs the same
/// nonce-protected authorization as the login screen — but the resulting credential goes to
/// `reauthenticate(with:)`, not a fresh sign-in.
private struct AppleReauthSheetContent: View {
    let colorScheme: ColorScheme
    let onCredential: (_ idToken: String, _ rawNonce: String) -> Void
    let onCancel: () -> Void

    @State private var currentNonce: String?
    @State private var extractionFailed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Confirm it's you")
                    .font(.title2.bold())
                    .tracking(-0.5)
                Text(
                    "Deleting an account needs a recent sign-in. Confirm with Apple to "
                    + "continue — your account will then be permanently deleted."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            SignInWithAppleButton(.signIn, onRequest: handleRequest, onCompletion: handleCompletion)
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 48)
                .accessibilityIdentifier("appleReauthButton")

            if extractionFailed {
                Label(
                    "Apple didn't return a usable credential — please try again.",
                    systemImage: "exclamationmark.octagon.fill"
                )
                .font(.footnote)
                .foregroundStyle(.red)
            }

            Button("Cancel", action: onCancel)
                .frame(maxWidth: .infinity)

            Spacer()
        }
        .padding(24)
    }

    private func handleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = AppleSignInNonce.randomNonce()
        currentNonce = nonce
        // No scopes: this is reauthentication of an existing account, not enrolment.
        request.requestedScopes = []
        request.nonce = AppleSignInNonce.sha256Hex(nonce)
    }

    private func handleCompletion(_ result: Result<ASAuthorization, Error>) {
        let rawNonce = currentNonce
        currentNonce = nil

        switch result {
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            extractionFailed = true
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8),
                  let rawNonce else {
                extractionFailed = true
                return
            }
            onCredential(idToken, rawNonce)
        }
    }
}

#if DEBUG
private struct PreviewDeletionClient: AccountDeletionClientAdapting {
    func reauthMethod() async -> AccountReauthMethod? { .password }
    func deleteAllUserData() async throws {}
    func deleteAuthAccount() async throws { throw AccountDeletionError.recentLoginRequired }
    func reauthenticate(password: String) async throws {}
    func reauthenticateWithApple(idToken: String, rawNonce: String) async throws {}
}

#Preview("Delete row — Light") {
    Form {
        AccountDeletionSection(
            service: AccountDeletionService(client: PreviewDeletionClient()),
            onDeleted: {}
        )
    }
    .preferredColorScheme(.light)
}

#Preview("Delete row — Dark") {
    Form {
        AccountDeletionSection(
            service: AccountDeletionService(client: PreviewDeletionClient()),
            onDeleted: {}
        )
    }
    .preferredColorScheme(.dark)
}
#endif

//
//  LoginView.swift
//  ADHD LifeOS
//
//  The v3 front door (E's 2026-08-28 design call). It was the last screen still wearing V1: a
//  stock `.roundedBorder` form on the default background, which predated the Momentum redesign
//  entirely — and it could only SIGN IN, against an account someone had to create in the Firebase
//  console by hand.
//
//  E chose the shape from sketches: the quiet-continuation look (large title, carded fields, the
//  composer's footer and primary button, a quiet "Forgot password?") wearing the one-screen
//  segmented flow (Sign in | Create account, one set of fields, the button relabels). Where the
//  two sketches disagreed — sketch 1 titled the screen "Sign in", sketch 2 titled it with the app
//  name — the app name wins: with the segmented control naming the mode directly underneath, a
//  mode-shaped title says the same word twice.
//
//  Sign in with Apple stays BUILT AND DORMANT behind `showsSignInWithApple` (E, 2026-08-19: the
//  free developer account blocks device deploys while the entitlement is attached). Untouched.
//

import AuthenticationServices
import SwiftUI

struct LoginView: View {
    @ObservedObject var authService: AuthService
    /// Magic-link sign-in has no Firebase path (the Stage C.1 stub-and-hide flag, kept). Defaults
    /// to `false`, so the active adapter hides the UI while `AuthService.requestMagicLink` /
    /// `.linkSent` stay compiled for a future reintroduction.
    var showsMagicLink: Bool = false
    /// Sign in with Apple is HIDDEN (E, 2026-08-19): the free Apple Developer account blocks
    /// device deployment while the `com.apple.developer.applesignin` entitlement is attached, so
    /// E removed the capability in Xcode. Same stub-and-hide precedent as `showsMagicLink` — the
    /// whole pipeline underneath (`AppleSignInNonce`, `AuthService.signInWithApple`,
    /// `FirebaseManager.signInWithApple`, the reauth path in account deletion) stays compiled and
    /// tested. To reactivate on a paid account: re-add the capability in Xcode (which restores the
    /// entitlement), enable the Apple provider in the Firebase console, and flip this to `true`.
    var showsSignInWithApple: Bool = false

    @Environment(\.colorScheme) var colorScheme

    @State var mode: AuthFormValidation.Mode = .signIn
    @State var email = ""
    @State var password = ""
    @State var displayName = ""
    /// The reveal toggle stands in for a confirm-password field (E's call): it catches a typo
    /// better and halves the typing. Off by default, which also keeps the field a `SecureField`
    /// for the signed-in UI journeys that address it as one.
    @State var isPasswordRevealed = false
    @State var isSubmitting = false
    @State var isSubmittingMagicLink = false
    /// The raw session nonce for the in-flight Apple authorization. Its SHA-256 digest rides in
    /// the Apple request; the raw value goes to Firebase, which verifies the pair (replay
    /// protection). Cleared the moment the authorization completes, success or not.
    @State private var currentAppleNonce: String?
    @State var isSubmittingApple = false
    /// Apple-flow failures present as an alert (a modal flow deserves a modal error), while the
    /// email/password path keeps its established inline error line.
    @State private var appleAlertMessage: String?

    /// `initialMode` exists for the previews — the app itself always opens on Sign in, since the
    /// overwhelmingly common case is someone who already has an account.
    init(
        authService: AuthService,
        showsMagicLink: Bool = false,
        showsSignInWithApple: Bool = false,
        initialMode: AuthFormValidation.Mode = .signIn
    ) {
        self.authService = authService
        self.showsMagicLink = showsMagicLink
        self.showsSignInWithApple = showsSignInWithApple
        _mode = State(initialValue: initialMode)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                if showsMagicLink, case .linkSent(let sentEmail) = authService.state {
                    checkYourEmailView(email: sentEmail)
                } else {
                    if showsSignInWithApple {
                        appleSection
                        orDivider
                    }
                    modePicker
                    fieldsSection
                    messagesSection
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.pageBackground.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) { footerBar }
        .animation(
            .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0),
            value: mode
        )
        .animation(
            .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0),
            value: isSubmittingApple
        )
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

    // MARK: - Actions

    var canSubmit: Bool {
        AuthFormValidation.canSubmit(mode: mode, email: email, password: password)
            && !isSubmitting && !isSubmittingApple
    }

    /// One entry point for both modes, so the button never disagrees with the segmented control
    /// about which thing it is doing.
    func submit() async {
        isSubmitting = true
        defer { isSubmitting = false }
        switch mode {
        case .signIn:
            await authService.signIn(email: email, password: password)
        case .createAccount:
            await authService.signUp(email: email, password: password, displayName: displayName)
        }
        // A success flips `authService.state` and `RootView` moves the app on by itself, so this
        // is the last moment either outcome can be felt.
        Haptics.play(authService.errorMessage == nil ? .solid : .error)
    }

    func requestPasswordReset() async {
        isSubmitting = true
        defer { isSubmitting = false }
        await authService.sendPasswordReset(email: email)
        Haptics.play(authService.passwordResetSentTo == nil ? .error : .solid)
    }

    /// Switching mode clears what the other one left behind: a "reset link sent" line hanging over
    /// the Create form is a lie about what just happened.
    func select(_ newMode: AuthFormValidation.Mode) {
        guard newMode != mode else { return }
        Haptics.play(.selection)
        mode = newMode
        authService.clearTransientMessages()
    }

    func submitMagicLink() async {
        isSubmittingMagicLink = true
        defer { isSubmittingMagicLink = false }
        await authService.requestMagicLink(email: email)
    }

    // MARK: - Sign in with Apple (dormant — see `showsSignInWithApple`)

    private var appleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SignInWithAppleButton(.signIn, onRequest: handleAppleRequest, onCompletion: handleAppleCompletion)
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 48)
                .allowsHitTesting(!isSubmittingApple && !isSubmitting)
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
            let appleName = credential.fullName
                .map { PersonNameComponentsFormatter().string(from: $0) }
                .flatMap { $0.isEmpty ? nil : $0 }
            Task { await submitApple(idToken: idToken, rawNonce: rawNonce, displayName: appleName) }
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
}

#if DEBUG
private struct PreviewAuthClientAdapting: AuthClientAdapting {
    func restoredUser() async -> AuthUser? { nil }

    func signIn(email: String, password: String) async throws -> AuthUser {
        AuthUser(id: UUID(), email: email)
    }

    func signUp(email: String, password: String, displayName: String?) async throws -> AuthUser {
        AuthUser(id: UUID(), email: email)
    }

    func sendPasswordReset(email: String) async throws {}

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

#Preview("Sign in — Light") {
    LoginView(authService: AuthService(client: PreviewAuthClientAdapting()))
        .preferredColorScheme(.light)
}

#Preview("Sign in — Dark") {
    LoginView(authService: AuthService(client: PreviewAuthClientAdapting()))
        .preferredColorScheme(.dark)
}

#Preview("Create account — Light") {
    LoginView(
        authService: AuthService(client: PreviewAuthClientAdapting()),
        initialMode: .createAccount
    )
    .preferredColorScheme(.light)
}

#Preview("Create account — Dark") {
    LoginView(
        authService: AuthService(client: PreviewAuthClientAdapting()),
        initialMode: .createAccount
    )
    .preferredColorScheme(.dark)
}
#endif

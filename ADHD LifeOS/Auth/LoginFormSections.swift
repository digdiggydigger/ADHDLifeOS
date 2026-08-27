//
//  LoginFormSections.swift
//  ADHD LifeOS
//
//  `LoginView`'s pieces, split out for that file's length budget once the screen grew a second
//  mode — the `JournalTimelineSections` / `CaptureInboxSections` arrangement. Same file-private
//  state, same view, just the chrome.
//

import SwiftUI

extension LoginView {

    // MARK: - Header

    var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("ADHD LifeOS")
                .font(.largeTitle.bold())
                .tracking(-0.5)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var subtitle: String {
        switch mode {
        case .signIn: return "Welcome back."
        case .createAccount: return "One account, and everything in it stays yours."
        }
    }

    /// The mode switch IS the route between the two — which is why neither the header nor the
    /// footer carries a second "new here?" link. One way in, in one place.
    var modePicker: some View {
        Picker("", selection: Binding(get: { mode }, set: select)) {
            ForEach(AuthFormValidation.Mode.allCases) { option in
                Text(option.title).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .disabled(isSubmitting || isSubmittingApple)
        .accessibilityIdentifier("authModePicker")
    }

    // MARK: - Fields

    var fieldsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if mode == .createAccount {
                fieldCard {
                    TextField("Your name (optional)", text: $displayName)
                        .textContentType(.name)
                        .accessibilityIdentifier("signUpNameField")
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            fieldCard {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .accessibilityIdentifier("loginEmailField")
            }

            fieldCard {
                HStack(spacing: 8) {
                    passwordField
                    revealButton
                }
            }

            if let hint = AuthFormValidation.passwordHint(mode: mode, password: password) {
                Text(hint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("signUpPasswordHint")
            }

            if mode == .signIn {
                forgotPasswordButton
            }
        }
    }

    /// The reveal swaps the field type, so BOTH spellings carry the same identifier: the signed-in
    /// UI journeys address it as `secureTextFields["loginPasswordField"]`, which is what it is
    /// whenever nobody has deliberately revealed it.
    @ViewBuilder
    private var passwordField: some View {
        if isPasswordRevealed {
            TextField("Password", text: $password)
                .textContentType(mode == .createAccount ? .newPassword : .password)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .accessibilityIdentifier("loginPasswordField")
        } else {
            SecureField("Password", text: $password)
                .textContentType(mode == .createAccount ? .newPassword : .password)
                .accessibilityIdentifier("loginPasswordField")
        }
    }

    private var revealButton: some View {
        Button {
            Haptics.play(.selection)
            isPasswordRevealed.toggle()
        } label: {
            Image(systemName: isPasswordRevealed ? "eye.slash" : "eye")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPasswordRevealed ? "Hide password" : "Show password")
        .accessibilityIdentifier("loginPasswordRevealButton")
    }

    /// Tinted only while it would actually do something. `.buttonStyle(.plain)` does not dim a
    /// disabled button, so with an empty email this read as a live link and did nothing when
    /// tapped (caught in the simulator, 2026-08-28). The colour reinforces the disabled state
    /// rather than carrying it alone — `.disabled` is still what VoiceOver announces.
    private var forgotPasswordButton: some View {
        let canRequest = AuthFormValidation.canRequestReset(email: email) && !isSubmitting
        return Button {
            Task { await requestPasswordReset() }
        } label: {
            Text("Forgot password?")
                .font(.footnote)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(canRequest ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
        .disabled(!canRequest)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .accessibilityIdentifier("forgotPasswordButton")
    }

    private func fieldCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .frame(minHeight: 44)
            .background(
                Color("CardSurfaceSecondary"),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
    }

    // MARK: - Messages

    @ViewBuilder
    var messagesSection: some View {
        if let sentTo = authService.passwordResetSentTo {
            // Deliberately says nothing about whether that address HAS an account — see
            // `AuthService.sendPasswordReset`.
            Label(
                "If \(sentTo) has an account, a reset link is on its way.",
                systemImage: "envelope"
            )
            .font(.footnote)
            .foregroundStyle(Color("StateGo"))
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("passwordResetConfirmation")
        }
        if let errorMessage = authService.errorMessage {
            Label(errorMessage, systemImage: "exclamationmark.octagon.fill")
                .font(.footnote)
                .foregroundStyle(Color("StateRisk"))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("loginErrorMessage")
        }
        if showsMagicLink {
            Button {
                Task { await submitMagicLink() }
            } label: {
                if isSubmittingMagicLink {
                    ProgressView()
                } else {
                    Text("Email me a sign-in link")
                        .font(.footnote)
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tint)
            .frame(minHeight: 44)
            .disabled(email.isEmpty || isSubmittingMagicLink)
            .accessibilityIdentifier("magicLinkButton")
        }
    }

    func checkYourEmailView(email: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Check your email")
                .font(.title2.bold())
            Text("We sent a sign-in link to \(email). Tap it on this device to continue.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityIdentifier("checkYourEmailState")
    }

    var orDivider: some View {
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

    // MARK: - Footer

    var footerBar: some View {
        VStack(spacing: 8) {
            Text("Your data is yours, and stays in your account.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                Task { await submit() }
            } label: {
                if isSubmitting {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text(mode.title)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(!canSubmit)
            .accessibilityIdentifier(
                mode == .signIn ? "signInButton" : "createAccountButton"
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .composerFooterSurface()
    }
}

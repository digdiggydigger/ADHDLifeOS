//
//  SettingsView.swift
//  ADHD LifeOS
//

import SwiftUI

/// Grouped, five-section Settings screen (see `docs/ARCHITECTURE.md` §3). Container is `Form` —
/// Apple's purpose-built settings surface, explicitly sanctioned over the `CLAUDE.md` §2
/// `ScrollView`+`LazyVStack` default for "basic Settings structures". `Form` gives native
/// inset-grouped styling, free section headers/footers, and correct Dynamic Type row growth
/// without hand-rolled spacing. Every section is live as of the 2026-08-25 audit: the last
/// placeholder (About & Diagnostics) became the real version/build row, and the preference
/// sections (momentum, focus, feedback) live in `SettingsPreferenceSections.swift`.
///
/// **Places is no longer here (F-Tools-3-Page, E's 2026-09-02 call).** It moved to the Tools tab
/// and has exactly one door now. **Life Areas deliberately did NOT** — it gained a Tools card and
/// kept `settingsLifeAreasRow`, because it is genuinely both a setting and a tool. The split is
/// asymmetric on purpose and is knowingly the opposite of the de-duplication the Captures rethink
/// spent two blocks on; `ToolsPageCallSiteTests` holds both halves so neither drifts back.
struct SettingsView: View {
    @ObservedObject var authService: AuthService
    private let authorizationReader: NotificationAuthorizationReading
    private let tagEditorClient: TagEditorClientAdapting
    private let lifeAreaEditorClient: LifeAreaEditorClientAdapting
    /// Owned here (not by the section) so the flow's phase survives the section's own identity
    /// changes, and previews/tests can inject a fake client through the same default-param door.
    @StateObject private var accountDeletionService: AccountDeletionService
    @Environment(\.dismiss) private var dismiss
    @State private var permissionState: NotificationPermissionState = .unknown
    @State private var isEditingName = false
    @State private var draftName = ""
    @State private var nameError: String?
    /// Internal, not private: the preference sections live in `SettingsPreferenceSections.swift`
    /// (the `HomeAccessoryStrips` arrangement) to keep this type inside its body budget.
    let momentumPreferencesStore: MomentumPreferencesStoring
    @State var momentumPreferences: MomentumPreferences

    init(
        authService: AuthService,
        authorizationReader: NotificationAuthorizationReading = NotificationCenterAuthorizationReader(),
        tagEditorClient: TagEditorClientAdapting? = nil,
        lifeAreaEditorClient: LifeAreaEditorClientAdapting? = nil,
        accountDeletionClient: AccountDeletionClientAdapting? = nil,
        momentumPreferencesStore: MomentumPreferencesStoring = UserDefaultsMomentumPreferencesStore()
    ) {
        self.authService = authService
        self.authorizationReader = authorizationReader
        self.momentumPreferencesStore = momentumPreferencesStore
        _momentumPreferences = State(initialValue: momentumPreferencesStore.read())
        // Default param keeps HomeView's `SettingsView(authService:)` call site unchanged (block-1
        // precedent); tests/previews inject a fake. The Firebase adapters carry their own auth
        // scoping via `FirebaseManager`, so no auth client gets threaded through anymore.
        self.tagEditorClient = tagEditorClient ?? FirebaseTagEditorClientAdapter()
        self.lifeAreaEditorClient = lifeAreaEditorClient ?? FirebaseLifeAreaEditorClientAdapter()
        _accountDeletionService = StateObject(wrappedValue: AccountDeletionService(
            client: accountDeletionClient ?? FirebaseAccountDeletionAdapter()
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                momentumSection
                focusSection
                feedbackSection
                appearanceSection
                notificationsSection
                lifeAreasSection
                accountSection
                aboutSection
                tagEditorSection
                // Destructive actions sit LAST, isolated in their own section, per HIG.
                AccountDeletionSection(service: accountDeletionService) {
                    authService.completeAccountDeletion()
                    dismiss()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityIdentifier("settingsDoneButton")
                }
            }
            .task {
                permissionState = await authorizationReader.authorizationStatus()
            }
        }
    }

    // MARK: - Appearance (F-V3-Settings)

    @AppStorage(AppearancePreference.storageKey) private var appearanceRaw =
        AppearancePreference.system.rawValue

    private var appearanceSection: some View {
        let current = AppearancePreference(rawValue: appearanceRaw) ?? .system
        return Section {
            Picker("Appearance", selection: $appearanceRaw) {
                ForEach(AppearancePreference.allCases) { option in
                    Label(option.title, systemImage: option.systemImage)
                        .tag(option.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .haptic(.selection, trigger: appearanceRaw)
            .accessibilityIdentifier("settingsAppearancePicker")
        } header: {
            Text("Appearance")
        } footer: {
            Text(current.explanation)
        }
    }

    // MARK: - Section 1 — Notifications (real, read-only)

    private var notificationsSection: some View {
        Section {
            // `LabeledContent` (iOS 16+) is the idiomatic Form title-value row: it lays the label
            // and status out correctly and, unlike a hand-rolled HStack, reflows to a stacked
            // layout at accessibility Dynamic Type sizes instead of wrapping into narrow columns.
            LabeledContent("System Permission") {
                permissionStatusView
            }
            .accessibilityIdentifier("settingsNotificationStatusRow")

            Button {
                openIOSSettings()
            } label: {
                Label("Open iOS Settings", systemImage: "arrow.up.forward.app")
            }
            .accessibilityIdentifier("openIOSSettingsButton")
        } header: {
            Text("Notifications")
        } footer: {
            Text(
                "ADHD LifeOS schedules reminders for tasks and nudges. This shows whether iOS "
                + "currently allows them — change it in the Settings app."
            )
        }
    }

    @ViewBuilder
    private var permissionStatusView: some View {
        if permissionState == .unknown {
            ProgressView()
        } else {
            // `Label` (not a bare HStack) so VoiceOver reads glyph + text as one element, and the
            // distinct glyph per state means status is never conveyed by colour alone.
            Label(permissionState.displayText, systemImage: permissionState.iconSystemImageName)
                .foregroundStyle(permissionState.tint)
        }
    }

    // MARK: - Section 2 — Life Areas (live — pushes the Life Areas editor)

    private var lifeAreasSection: some View {
        Section {
            // Closure-based `NavigationLink` to match the list→detail push inside the editor — one
            // consistent link style down the whole Settings stack (trap b). Identifier kept verbatim
            // (`settingsLifeAreasRow`) so nothing that targets it breaks. Reorder is deliberately NOT
            // here — it is a Home-screen drag toggle in block 3 — so the caption no longer mentions it.
            NavigationLink {
                LifeAreaEditorListView(client: lifeAreaEditorClient)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Life Areas")
                    Text("Rename, re-emoji, recolour, create, and archive your Home grid.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityIdentifier("settingsLifeAreasRow")
        }
    }

    // MARK: - Section 3 — Account (real, Sign Out)

    /// Who you are signed in as, then the way out.
    ///
    /// Neither fact was shown anywhere in the app until now. The sign-up form has collected a name
    /// since the auth rebuild and wrote it to the server twice over, and the email was equally
    /// invisible — so the only way to tell which account a device was on was to sign out and read
    /// the address you typed back in. `LabeledContent` is the house pattern for a title-value Form
    /// row (§7): it reflows at accessibility Dynamic Type sizes instead of wrapping into columns.
    ///
    /// A missing name renders NO row rather than "Not set" — the field is optional, Apple's
    /// private-relay path never supplies one, and an empty row is a worse answer than silence.
    private var accountSection: some View {
        Section {
            // The row still hides when there is no name — the note above still holds. What is new
            // is a way IN when it is hidden: the name used to be written once at sign-up and
            // nothing could set it afterwards, so on E's own account (created before the sign-up
            // form collected one) this row could never appear at all. Verified against the live
            // Auth record rather than assumed.
            if let name = authService.signedInUser?.displayName {
                Button {
                    beginEditingName(current: name)
                } label: {
                    LabeledContent("Name", value: name)
                }
                .accessibilityIdentifier("settingsAccountNameRow")
                .accessibilityHint("Change the name on this account")
            } else {
                Button("Add your name") { beginEditingName(current: "") }
                    .accessibilityIdentifier("settingsAddAccountNameButton")
            }
            if let email = authService.signedInUser?.email {
                LabeledContent("Email", value: email)
                    .accessibilityIdentifier("settingsAccountEmailRow")
            }
            Button(role: .destructive) {
                Haptics.play(.warning)
                Task { await authService.signOut() }
            } label: {
                Text("Sign Out")
            }
            .accessibilityIdentifier("signOutButton")
        } header: {
            Text("Account")
        } footer: {
            if let nameError {
                Text(nameError)
                    .foregroundStyle(Color("StateRisk"))
                    .accessibilityIdentifier("settingsAccountNameError")
            }
        }
        .alert("Your name", isPresented: $isEditingName) {
            TextField("Name", text: $draftName)
                .textInputAutocapitalization(.words)
                .accessibilityIdentifier("settingsAccountNameField")
            Button("Save") { Task { await saveName() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Leave it empty to remove your name.")
        }
    }

    /// Opens the rename alert. Split out so both entry points — the value row and the "Add your
    /// name" button — start from the same place and cannot drift.
    private func beginEditingName(current: String) {
        nameError = nil
        draftName = current
        isEditingName = true
    }

    /// Saves, and reports rather than swallows.
    ///
    /// `AuthService.updateDisplayName` already normalises through the one validation rule and
    /// leaves the displayed name untouched when the write fails, so this only has to surface the
    /// message. Clearing is the same call with an empty field — which is why the alert says so.
    private func saveName() async {
        let saved = await authService.updateDisplayName(draftName)
        nameError = saved ? nil : authService.errorMessage
        if saved { Haptics.play(.solid) }
    }

    // MARK: - Section 4 — About (live: version & build, E's 2026-08-25 call)

    private var aboutSection: some View {
        Section {
            LabeledContent("Version", value: AboutInfo.current.formatted)
                .accessibilityIdentifier("settingsAboutRow")
        } header: {
            Text("About")
        }
    }

    // MARK: - Section 5 — Tag Editor (live — pushes the Tag Editor)

    private var tagEditorSection: some View {
        Section {
            NavigationLink {
                TagEditorListView(client: tagEditorClient)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tag Editor")
                    Text("Rename, merge, and delete tags.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityIdentifier("settingsTagEditorRow")
        }
    }

    // MARK: - Helpers

    private func openIOSSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#if DEBUG
private struct PreviewAuthClientAdapting: AuthClientAdapting {
    func restoredUser() async -> AuthUser? { nil }
    func signIn(email: String, password: String) async throws -> AuthUser { fatalError("unused in preview") }
    func requestOTP(email: String, redirectTo: URL?) async throws {}
    func completeSession(from url: URL) async throws -> AuthUser { fatalError("unused in preview") }
    func signUp(email: String, password: String, displayName: String?) async throws -> AuthUser {
        AuthUser(id: UUID(), email: email)
    }

    func updateDisplayName(_ displayName: String?) async throws -> AuthUser {
        AuthUser(id: UUID(), email: "preview@example.com", displayName: displayName)
    }
    func sendPasswordReset(email: String) async throws {}

    func signOut() async throws {}
    func validIDToken() async throws -> String { "preview-token" }
    func signInWithApple(idToken: String, rawNonce: String, displayName: String?) async throws -> AuthUser {
        fatalError("unused in preview")
    }
}

/// Preview-only reader so the canvas renders a concrete status without a real notification center.
private struct PreviewAuthorizationReader: NotificationAuthorizationReading {
    let state: NotificationPermissionState
    func authorizationStatus() async -> NotificationPermissionState { state }
}

private func previewSettingsView(_ state: NotificationPermissionState) -> some View {
    SettingsView(
        authService: AuthService(client: PreviewAuthClientAdapting()),
        authorizationReader: PreviewAuthorizationReader(state: state),
        tagEditorClient: PreviewTagEditorClient(tags: []),
        lifeAreaEditorClient: PreviewLifeAreaEditorClient(areas: [])
    )
}

#Preview("Light — Allowed") {
    previewSettingsView(.authorized)
        .preferredColorScheme(.light)
}

#Preview("Dark — Denied") {
    previewSettingsView(.denied)
        .preferredColorScheme(.dark)
}
#endif

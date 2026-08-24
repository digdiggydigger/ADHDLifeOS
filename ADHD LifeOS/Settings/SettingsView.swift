//
//  SettingsView.swift
//  ADHD LifeOS
//

import SwiftUI

/// Grouped, five-section Settings screen (see `docs/ARCHITECTURE.md` §3). Container is `Form` —
/// Apple's purpose-built settings surface, explicitly sanctioned over the `CLAUDE.md` §2
/// `ScrollView`+`LazyVStack` default for "basic Settings structures". `Form` gives native
/// inset-grouped styling, free section headers/footers, and correct Dynamic Type row growth
/// without hand-rolled spacing. Only Notifications (read-only status) and Account (Sign Out) are
/// live; Life Areas, About & Diagnostics, and Tag Editor are visible-but-disabled placeholders.
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
    private let momentumPreferencesStore: MomentumPreferencesStoring
    @State private var momentumPreferences: MomentumPreferences

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

    // MARK: - Section 0 — What counts as momentum (Concept C, block M2)

    private var momentumSection: some View {
        Section {
            Stepper(
                value: Binding(
                    get: { momentumPreferences.dailyGoal },
                    set: { newValue in
                        momentumPreferences.dailyGoal = newValue
                        momentumPreferencesStore.write(momentumPreferences)
                    }
                ),
                in: MomentumPreferences.goalRange
            ) {
                LabeledContent(
                    "Daily goal",
                    value: "\(momentumPreferences.dailyGoal) \(momentumPreferences.dailyGoal == 1 ? "item" : "items")"
                )
            }
            .accessibilityIdentifier("settingsMomentumGoalStepper")

            Toggle("Show streaks", isOn: Binding(
                get: { momentumPreferences.showStreaks },
                set: { newValue in
                    momentumPreferences.showStreaks = newValue
                    momentumPreferencesStore.write(momentumPreferences)
                }
            ))
            .accessibilityIdentifier("settingsMomentumStreaksToggle")

            Toggle("Count cleared captures", isOn: Binding(
                get: { momentumPreferences.countClearedCaptures },
                set: { newValue in
                    momentumPreferences.countClearedCaptures = newValue
                    momentumPreferencesStore.write(momentumPreferences)
                }
            ))
            .accessibilityIdentifier("settingsMomentumCapturesToggle")
        } header: {
            Text("What counts as momentum")
        } footer: {
            Text(
                "Turn streaks off and the app keeps every number but stops counting consecutive "
                    + "days. Counting cleared captures lets anything you archive, promote or "
                    + "journal from the inbox advance the ring too."
            )
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
                    Text("Rename, re-emoji, create, and archive your Home grid.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityIdentifier("settingsLifeAreasRow")
        }
    }

    // MARK: - Section 3 — Account (real, Sign Out)

    private var accountSection: some View {
        Section {
            Button(role: .destructive) {
                Task { await authService.signOut() }
            } label: {
                Text("Sign Out")
            }
            .accessibilityIdentifier("signOutButton")
        } header: {
            Text("Account")
        }
    }

    // MARK: - Section 4 — About & Diagnostics (disabled placeholder)

    private var aboutSection: some View {
        Section {
            disabledPlaceholderRow(
                title: "About & Diagnostics",
                caption: "Version, environment, and last refresh.",
                identifier: "settingsAboutRow"
            )
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

    /// A visible-but-disabled row: a real title plus a brief secondary caption, greyed via the
    /// semantic `.secondary` style (not `.opacity`, per `CLAUDE.md` §4) and `.disabled(true)` so it
    /// reads as inert to VoiceOver. No `.contentShape` — it is intentionally not interactive.
    private func disabledPlaceholderRow(title: String, caption: String, identifier: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
            Text(caption)
                .font(.footnote)
        }
        .foregroundStyle(.secondary)
        .disabled(true)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }

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

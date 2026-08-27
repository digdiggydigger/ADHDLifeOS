//
//  LifeAreaEditorListView.swift
//  ADHD LifeOS
//

import SwiftUI

/// Life Areas list — reached from Settings → Life Areas. Active areas first, then a separate
/// **Archived** section (omitted entirely when nothing is archived). Rows push a detail screen; a
/// `+` toolbar button opens the create sheet. Every push is a **closure-based** `NavigationLink` to
/// match the closure link in Settings that pushed this list — mixing closure and value links in one
/// stack silently breaks the push (trap b, confirmed on device in the Tag Editor block).
struct LifeAreaEditorListView: View {
    @StateObject private var service: LifeAreaEditorService
    @State private var isPresentingAdd = false

    init(client: LifeAreaEditorClientAdapting) {
        _service = StateObject(wrappedValue: LifeAreaEditorService(client: client))
    }

    var body: some View {
        Group {
            switch service.state {
            case .loading:
                ProgressView()
                    .accessibilityIdentifier("lifeAreaEditorLoadingIndicator")
            case .loaded:
                loadedContent
            case .failed(let message):
                errorState(message)
            }
        }
        .navigationTitle("Life Areas")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingAdd = true
                } label: {
                    Label("Add Life Area", systemImage: "plus")
                }
                .accessibilityIdentifier("addLifeAreaButton")
            }
        }
        .sheet(isPresented: $isPresentingAdd) {
            AddLifeAreaSheet(service: service)
                .keyboardDismissal()
        }
        .overlay(alignment: .bottom) {
            infoToast
        }
        .task {
            await service.load()
        }
    }

    @ViewBuilder
    private var loadedContent: some View {
        List {
            Section {
                ForEach(service.activeAreas) { area in
                    areaRow(area)
                }
            } footer: {
                Text(service.activeAreas.count == 1 ? "1 active area" : "\(service.activeAreas.count) active areas")
            }

            if !service.archivedAreas.isEmpty {
                Section {
                    ForEach(service.archivedAreas) { area in
                        areaRow(area)
                    }
                } header: {
                    Text("Archived")
                } footer: {
                    Text("Archived areas are hidden from the Home grid. Their tasks and notes move to Unassigned.")
                }
            }
        }
        .accessibilityIdentifier("lifeAreaEditorList")
    }

    private func areaRow(_ area: EditableLifeArea) -> some View {
        NavigationLink {
            LifeAreaEditorDetailView(area: area, service: service)
        } label: {
            rowLabel(area)
        }
        .accessibilityIdentifier(LifeAreaEditorPresentation.rowIdentifier(for: area.id))
    }

    /// Emoji + name as one `Label` (VoiceOver reads it as a single element); an archived row adds a
    /// text "Archived" badge and greys via the semantic `.secondary` style — never `.opacity` (§4),
    /// and never colour alone: the badge carries the meaning in words.
    @ViewBuilder
    private func rowLabel(_ area: EditableLifeArea) -> some View {
        if area.archived {
            LabeledContent {
                Text(LifeAreaEditorPresentation.archivedBadge)
                    .font(.footnote)
            } label: {
                Label {
                    Text(area.name)
                } icon: {
                    Text(area.colour)
                }
            }
            .foregroundStyle(.secondary)
        } else {
            Label {
                Text(area.name)
            } icon: {
                Text(area.colour)
            }
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 8) {
            Text("Couldn't load your life areas")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .accessibilityIdentifier("lifeAreaEditorErrorMessage")
    }

    @ViewBuilder
    private var infoToast: some View {
        if let info = service.infoMessage {
            Text(info)
                .font(.footnote)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.bottom, 16)
                .accessibilityIdentifier("lifeAreaEditorInfoToast")
                .task(id: info) {
                    try? await Task.sleep(nanoseconds: 2_500_000_000)
                    service.infoMessage = nil
                }
        }
    }
}

/// The `+` create sheet: a name field, the emoji picker (a default is pre-selected so `POST` always
/// has a `colour`), and Save. A name clash is a real `409` (no dedup): if the holder is archived the
/// alert offers "Unarchive it instead?"; otherwise it is Cancel-only.
private struct AddLifeAreaSheet: View {
    @ObservedObject var service: LifeAreaEditorService
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var colour = EmojiPalette.lifeArea.first ?? "🏠"
    @State private var showConflictAlert = false

    private var canSave: Bool {
        LifeAreaEditorValidation.normalizeNewName(name) != nil && !service.isMutating
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Life area name", text: $name)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("addLifeAreaNameField")
                } header: {
                    Text("Name")
                }

                Section {
                    EmojiPicker(selection: $colour)
                } header: {
                    Text("Emoji")
                }

                if let error = service.errorMessage {
                    Section {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("addLifeAreaErrorMessage")
                    }
                }
            }
            .navigationTitle("New Life Area")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("addLifeAreaCancelButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if await service.create(name: name, colour: colour) {
                                Haptics.play(.solid)
                                dismiss()
                            } else {
                                Haptics.play(.error)
                            }
                        }
                    }
                    .disabled(!canSave)
                    .accessibilityIdentifier("addLifeAreaSaveButton")
                }
            }
            .onChange(of: service.pendingCreateConflict) { conflict in
                showConflictAlert = (conflict != nil)
            }
            .alert(
                service.pendingCreateConflict
                    .map { LifeAreaEditorPresentation.createConflictTitle(name: $0.name) } ?? "",
                isPresented: $showConflictAlert,
                presenting: service.pendingCreateConflict
            ) { conflict in
                if conflict.archived {
                    Button("Unarchive it instead?") {
                        Task {
                            if await service.unarchiveConflicting(conflict) { dismiss() }
                        }
                    }
                    Button("Cancel", role: .cancel) { service.cancelCreateConflict() }
                } else {
                    Button("OK", role: .cancel) { service.cancelCreateConflict() }
                }
            } message: { conflict in
                Text(
                    conflict.archived
                        ? LifeAreaEditorPresentation.createConflictArchivedMessage(name: conflict.name)
                        : LifeAreaEditorPresentation.createConflictLiveMessage(name: conflict.name)
                )
            }
        }
    }
}

#if DEBUG
private let previewAreas: [EditableLifeArea] = [
    EditableLifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 1, archived: false),
    EditableLifeArea(id: UUID(), name: "Health", colour: "🫀", sortOrder: 2, archived: false),
    EditableLifeArea(id: UUID(), name: "Old Side Project", colour: "🗂️", sortOrder: 3, archived: true)
]

#Preview("List — Light") {
    NavigationStack {
        LifeAreaEditorListView(client: PreviewLifeAreaEditorClient(areas: previewAreas))
    }
    .preferredColorScheme(.light)
}

#Preview("List — Dark") {
    NavigationStack {
        LifeAreaEditorListView(client: PreviewLifeAreaEditorClient(areas: previewAreas))
    }
    .preferredColorScheme(.dark)
}

#Preview("List — no archived (section absent)") {
    NavigationStack {
        LifeAreaEditorListView(
            client: PreviewLifeAreaEditorClient(areas: Array(previewAreas.prefix(2)))
        )
    }
    .preferredColorScheme(.light)
}
#endif

//
//  LifeAreaEditorDetailView.swift
//  ADHD LifeOS
//

import SwiftUI

/// Life Area detail — pushed on row tap. A name field and emoji picker are **staged** behind an
/// explicit Save; Archive / Unarchive applies **immediately** and confirms via the list's info toast
/// (E's locked split, mirroring the Tag Editor's directly-analogous screen). Save is disabled while
/// nothing changed or a mutation is in flight. A rename clash surfaces a **Cancel-only** alert —
/// unarchiving the holder cannot resolve a rename, so no such button is offered even when the holder
/// is archived (it just says so).
struct LifeAreaEditorDetailView: View {
    let area: EditableLifeArea
    @ObservedObject var service: LifeAreaEditorService
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var colour: String
    @State private var showRenameConflictAlert = false

    init(area: EditableLifeArea, service: LifeAreaEditorService) {
        self.area = area
        self.service = service
        _name = State(initialValue: area.name)
        _colour = State(initialValue: area.colour)
    }

    private var canSave: Bool {
        guard !service.isMutating else { return false }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return trimmed != area.name || colour != area.colour
    }

    var body: some View {
        Form {
            Section {
                TextField("Life area name", text: $name)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("lifeAreaDetailNameField")
            } header: {
                Text("Name")
            }

            Section {
                LifeAreaEmojiPicker(selection: $colour)
            } header: {
                Text("Emoji")
            }

            if let error = service.errorMessage {
                Section {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("lifeAreaDetailErrorMessage")
                }
            }

            Section {
                Button {
                    Task {
                        if await service.setArchived(area, archived: !area.archived) { dismiss() }
                    }
                } label: {
                    Label(
                        area.archived ? "Unarchive Life Area" : "Archive Life Area",
                        systemImage: area.archived ? "tray.and.arrow.up" : "archivebox"
                    )
                }
                .disabled(service.isMutating)
                .accessibilityIdentifier("lifeAreaArchiveButton")
            } footer: {
                Text(
                    area.archived
                        ? "Unarchiving returns this area to your Home grid."
                        : "Archiving hides this area from your Home grid. Its tasks and notes move to "
                            + "Unassigned. You can unarchive it any time."
                )
            }
        }
        .navigationTitle(area.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    Task {
                        if await service.saveEdits(to: area, name: name, colour: colour) { dismiss() }
                    }
                }
                .disabled(!canSave)
                .accessibilityIdentifier("lifeAreaSaveButton")
            }
        }
        .onChange(of: service.pendingRenameConflict) { conflict in
            showRenameConflictAlert = (conflict != nil)
        }
        .alert(
            service.pendingRenameConflict.map { LifeAreaEditorPresentation.renameConflictTitle(name: $0.name) } ?? "",
            isPresented: $showRenameConflictAlert,
            presenting: service.pendingRenameConflict
        ) { _ in
            // Cancel-only in both cases — there is no merge for life areas, and unarchiving cannot
            // resolve a rename. Returns to the field with the typed name intact.
            Button("OK", role: .cancel) { service.cancelRenameConflict() }
        } message: { conflict in
            Text(LifeAreaEditorPresentation.renameConflictMessage(name: conflict.name, archived: conflict.archived))
        }
    }
}

#if DEBUG
/// Preview/adapter double. `createOutcome`/`updateOutcome` are configurable so a preview can render
/// the `409` alert paths (including `archived: true`) in the canvas — a block requirement.
final class PreviewLifeAreaEditorClient: LifeAreaEditorClientAdapting, @unchecked Sendable {
    var areas: [EditableLifeArea]
    var updateOutcome: LifeAreaUpdateOutcome
    var createOutcome: LifeAreaCreateOutcome

    init(
        areas: [EditableLifeArea],
        updateOutcome: LifeAreaUpdateOutcome = .updated,
        createOutcome: LifeAreaCreateOutcome? = nil
    ) {
        self.areas = areas
        self.updateOutcome = updateOutcome
        self.createOutcome = createOutcome
            ?? .created(EditableLifeArea(id: UUID(), name: "New", colour: "🏠", sortOrder: 99, archived: false))
    }

    func fetchLifeAreas() async throws -> [EditableLifeArea] { areas }
    func update(id: UUID, name: String?, colour: String?) async throws -> LifeAreaUpdateOutcome { updateOutcome }
    func setArchived(id: UUID, archived: Bool) async throws {}
    func create(name: String, colour: String) async throws -> LifeAreaCreateOutcome { createOutcome }
}

private func previewDetail(
    area: EditableLifeArea,
    updateOutcome: LifeAreaUpdateOutcome
) -> some View {
    let client = PreviewLifeAreaEditorClient(areas: [area], updateOutcome: updateOutcome)
    let service = LifeAreaEditorService(client: client)
    return NavigationStack {
        LifeAreaEditorDetailView(area: area, service: service)
    }
}

#Preview("Detail — Light") {
    previewDetail(
        area: EditableLifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 1, archived: false),
        updateOutcome: .updated
    )
    .preferredColorScheme(.light)
}

#Preview("Detail — Dark (rename 409, archived holder)") {
    previewDetail(
        area: EditableLifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 1, archived: false),
        updateOutcome: .nameConflict(LifeAreaNameConflict(id: UUID(), name: "Health", archived: true))
    )
    .preferredColorScheme(.dark)
}

#Preview("Detail — archived area (Unarchive)") {
    previewDetail(
        area: EditableLifeArea(id: UUID(), name: "Old Project", colour: "🗂️", sortOrder: 5, archived: true),
        updateOutcome: .updated
    )
    .preferredColorScheme(.light)
}
#endif

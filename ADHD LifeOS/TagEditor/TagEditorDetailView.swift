//
//  TagEditorDetailView.swift
//  ADHD LifeOS
//

import SwiftUI

/// Tag detail — pushed on row tap. A name field (rename), the usage count as read-only text, and a
/// destructive Delete. Both irreversible actions go through a centre-screen `.alert` (E's locked
/// decisions): a rename that clashes offers Merge / Cancel; Delete confirms while naming the usage
/// count (§8). Save is disabled while the name is unchanged/empty or a mutation is in flight.
struct TagEditorDetailView: View {
    let tag: EditableTag
    @ObservedObject var service: TagEditorService
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var showMergeAlert = false
    @State private var showDeleteAlert = false

    init(tag: EditableTag, service: TagEditorService) {
        self.tag = tag
        self.service = service
        _name = State(initialValue: tag.name)
    }

    private var canSave: Bool {
        guard !service.isMutating else { return false }
        if case .valid = TagEditorValidation.renameChange(current: tag.name, proposed: name) {
            return true
        }
        return false
    }

    var body: some View {
        Form {
            Section {
                TextField("Tag name", text: $name)
                    // Tag names are matched verbatim server-side (dedup/merge); iOS's default
                    // sentence-case + autocorrect would silently mangle them.
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("tagDetailNameField")
            } header: {
                Text("Name")
            }

            Section {
                LabeledContent("Usage") {
                    Text(TagEditorPresentation.usagePhrase(count: tag.usageCount))
                }
                .accessibilityIdentifier("tagDetailUsageRow")
            }

            if let error = service.errorMessage {
                Section {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("tagDetailErrorMessage")
                }
            }

            Section {
                Button(role: .destructive) {
                    Haptics.play(.warning)
                    showDeleteAlert = true
                } label: {
                    Label("Delete Tag", systemImage: "trash")
                }
                .accessibilityIdentifier("tagDeleteButton")
            }
        }
        .navigationTitle(tag.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    Task {
                        if await service.rename(tag: tag, to: name) {
                            Haptics.play(.solid)
                            dismiss()
                        } else {
                            Haptics.play(.error)
                        }
                    }
                }
                .disabled(!canSave)
                .accessibilityIdentifier("tagSaveButton")
            }
        }
        // Drive the rename-clash alert from the service's single source of truth.
        .onChange(of: service.pendingMergeConflict) { conflict in
            showMergeAlert = (conflict != nil)
        }
        .alert(
            service.pendingMergeConflict.map { TagEditorPresentation.mergeAlertTitle(conflictingName: $0.name) } ?? "",
            isPresented: $showMergeAlert,
            presenting: service.pendingMergeConflict
        ) { conflict in
            Button("Merge", role: .destructive) {
                Task {
                    if await service.confirmMerge(tag: tag, into: conflict.name) { dismiss() }
                }
            }
            Button("Cancel", role: .cancel) {
                // Writes nothing; returns to the field with the typed name intact.
                service.cancelMerge()
            }
        } message: { conflict in
            Text(
                TagEditorPresentation.mergeAlertMessage(
                    survivorName: conflict.name, survivorUsageCount: conflict.usageCount
                )
            )
        }
        .alert("Delete Tag", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                Task {
                    if await service.delete(tag: tag) { dismiss() }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(TagEditorPresentation.deleteConfirmMessage(name: tag.name, usageCount: tag.usageCount))
        }
    }
}

#if DEBUG
private func previewDetail(renameOutcome: TagRenameOutcome) -> some View {
    let client = PreviewTagEditorClient(
        tags: [EditableTag(id: UUID(), name: "errands", usageCount: 12)],
        renameOutcome: renameOutcome
    )
    let service = TagEditorService(client: client)
    return NavigationStack {
        TagEditorDetailView(
            tag: EditableTag(id: UUID(), name: "work", usageCount: 3),
            service: service
        )
    }
}

#Preview("Detail — Light") {
    previewDetail(renameOutcome: .renamed)
        .preferredColorScheme(.light)
}

#Preview("Detail — Dark (409 merge path)") {
    // renameOutcome .needsMerge so tapping Save renders the merge alert in the canvas.
    previewDetail(
        renameOutcome: .needsMerge(TagRenameConflict(id: UUID(), name: "errands", usageCount: 12))
    )
    .preferredColorScheme(.dark)
}
#endif

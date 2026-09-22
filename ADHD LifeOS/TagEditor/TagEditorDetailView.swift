//
//  TagEditorDetailView.swift
//  ADHD LifeOS
//

import SwiftUI

/// Tag detail — pushed on row tap. A name field (rename), the usage count as read-only text, and a
/// destructive Delete. Save is disabled while the name is unchanged/empty or a mutation is in
/// flight.
///
/// **ONE alert remains, and it is the irreversible one.** A rename that clashes still offers
/// Merge / Cancel, because a merge genuinely cannot be undone. The DELETE's confirm is gone
/// (`F-C4-TagsRecentlyDeleted`, E's call 2026-09-22): the delete became a 30-day stamp, and
/// `alerts.md › Best practices` asks for an alert on an uncommon destructive action *"that they
/// can't undo"*. In its place the delete records an Undo capsule — which is also the only thing
/// that shows a result, since a tag delete's real effect is chips vanishing from tasks and
/// captures on screens the user is not looking at.
struct TagEditorDetailView: View {
    let tag: EditableTag
    @ObservedObject var service: TagEditorService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.recordAction) private var recordAction

    @State private var name: String
    @State private var showMergeAlert = false

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
                    Task { await performDelete() }
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
    }

    /// Only on a landed delete: record the capsule and pop. A failed delete leaves the error on
    /// screen and stays put — `TaskDetailFormSections.performDelete()` is the shape.
    ///
    /// **The subject is read from `tag`, which is a `let` on this view**, so unlike task detail
    /// there is no race with the write making it unreadable.
    private func performDelete() async {
        let tagId = tag.id
        let subject = tag.name
        guard await service.softDelete(tag: tag) else { return }
        // **`[service, tagId]`, and the SERVICE is right here where `F-C3` said it was wrong.**
        // Task detail captured the adapter because `performDelete()` dismissed the screen that
        // owned its service. This service is owned by `TagEditorListView` — the screen being
        // returned TO — so it outlives this view by construction, and holding it is what lets the
        // restore reload the list the user is now looking at rather than writing a field and
        // leaving the row missing.
        recordAction.record(
            RecentAction(kind: .tagDeleted, subject: subject) { [service, tagId] in
                await service.restore(tagId: tagId)
            }
        )
        dismiss()
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

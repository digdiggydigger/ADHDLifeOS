//
//  TagEditorListView.swift
//  ADHD LifeOS
//

import SwiftUI

/// Tag Editor list — reached from Settings → Tag Editor. Lists every tag with its usage count
/// (sorted case-insensitively by the service), pushes a detail screen on row tap (E's locked
/// decision: all actions visible, nothing swipe-hidden), and creates a tag via a `+` toolbar
/// button. A `Form` is used per the same `CLAUDE.md` §2 Settings carve-out block 1 relied on.
struct TagEditorListView: View {
    @StateObject private var service: TagEditorService
    @State private var isPresentingAdd = false

    init(client: TagEditorClientAdapting) {
        _service = StateObject(wrappedValue: TagEditorService(client: client))
    }

    var body: some View {
        Group {
            switch service.state {
            case .loading:
                ProgressView()
                    .accessibilityIdentifier("tagEditorLoadingIndicator")
            case .loaded:
                loadedContent
            case .failed(let message):
                errorState(message)
            }
        }
        .navigationTitle("Tag Editor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingAdd = true
                } label: {
                    Label("Add Tag", systemImage: "plus")
                }
                .accessibilityIdentifier("addTagButton")
            }
        }
        .sheet(isPresented: $isPresentingAdd) {
            AddTagSheet(service: service)
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
        if service.tags.isEmpty {
            emptyState
        } else {
            List {
                Section {
                    ForEach(service.tags) { tag in
                        // Closure-based destination to match the Settings row that pushed this list
                        // — mixing a closure link with a value-based `NavigationLink(value:)` +
                        // `navigationDestination` in one stack silently breaks the push (Apple's
                        // documented "don't mix link styles"; confirmed on device 2026-07-30).
                        NavigationLink {
                            TagEditorDetailView(tag: tag, service: service)
                        } label: {
                            // `LabeledContent` (not a hand-rolled HStack+Spacer) so the name and count
                            // reflow to a stacked layout at accessibility Dynamic Type sizes — §7's
                            // house pattern for Form rows.
                            LabeledContent(tag.name) {
                                Text(TagEditorPresentation.usagePhrase(count: tag.usageCount))
                            }
                        }
                        .accessibilityIdentifier(TagEditorPresentation.rowIdentifier(for: tag.id))
                    }
                } footer: {
                    Text(service.tags.count == 1 ? "1 tag" : "\(service.tags.count) tags")
                }
            }
            .accessibilityIdentifier("tagEditorList")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No tags yet.")
                .font(.headline)
            Text("Tap + to create your first tag.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("tagEditorEmptyState")
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 8) {
            Text("Couldn't load your tags")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .accessibilityIdentifier("tagEditorErrorMessage")
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
                .accessibilityIdentifier("tagEditorInfoToast")
                .task(id: info) {
                    // Brief, non-modal: auto-dismiss so the dedup notice never blocks the list.
                    try? await Task.sleep(nanoseconds: 2_500_000_000)
                    service.infoMessage = nil
                }
        }
    }
}

/// The `+` add-tag sheet: a single name field + Save. Uses the unchanged `POST /tags` (server-side
/// dedup), so an existing name is not an error — the service surfaces a brief notice instead.
private struct AddTagSheet: View {
    @ObservedObject var service: TagEditorService
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    private var canSave: Bool {
        TagEditorValidation.normalizeNewName(name) != nil && !service.isMutating
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Tag name", text: $name)
                        // Tag names are matched verbatim server-side (dedup/merge); iOS's default
                        // sentence-case + autocorrect would silently mangle them.
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("addTagNameField")
                }
                if let error = service.errorMessage {
                    Section {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("New Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("addTagCancelButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if await service.create(name: name) {
                                Haptics.play(.solid)
                                dismiss()
                            } else {
                                Haptics.play(.error)
                            }
                        }
                    }
                    .disabled(!canSave)
                    .accessibilityIdentifier("addTagSaveButton")
                }
            }
        }
    }
}

#if DEBUG
/// Preview/adapter double. `renameResult`/`fetchResults` are configurable so a preview can render
/// the `409` alert path in the canvas (block requirement).
final class PreviewTagEditorClient: TagEditorClientAdapting, @unchecked Sendable {
    var tags: [EditableTag]
    var renameOutcome: TagRenameOutcome

    init(tags: [EditableTag], renameOutcome: TagRenameOutcome = .renamed) {
        self.tags = tags
        self.renameOutcome = renameOutcome
    }

    func fetchTags() async throws -> [EditableTag] { tags }
    func renameTag(id: UUID, to name: String) async throws -> TagRenameOutcome { renameOutcome }
    func mergeTag(id: UUID, into name: String) async throws {}
    func deleteTag(id: UUID) async throws {}
    func createTag(name: String) async throws -> TagCreateOutcome {
        .created(EditableTag(id: UUID(), name: name, usageCount: 0))
    }
}

private let previewTags = [
    EditableTag(id: UUID(), name: "errands", usageCount: 12),
    EditableTag(id: UUID(), name: "reading", usageCount: 1),
    EditableTag(id: UUID(), name: "someday", usageCount: 0)
]

#Preview("List — Light") {
    NavigationStack {
        TagEditorListView(client: PreviewTagEditorClient(tags: previewTags))
    }
    .preferredColorScheme(.light)
}

#Preview("List — Dark") {
    NavigationStack {
        TagEditorListView(client: PreviewTagEditorClient(tags: previewTags))
    }
    .preferredColorScheme(.dark)
}

#Preview("Empty — Dark") {
    NavigationStack {
        TagEditorListView(client: PreviewTagEditorClient(tags: []))
    }
    .preferredColorScheme(.dark)
}
#endif

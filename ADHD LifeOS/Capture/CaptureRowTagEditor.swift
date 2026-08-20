//
//  CaptureRowTagEditor.swift
//  ADHD LifeOS
//

import SwiftUI

/// The Inbox triage row's tag editor: current tags as removable chips, a search field, matching
/// suggestions, and a create-new affordance when nothing matches.
///
/// Extracted from `CaptureRowView` in the 2026-08-20 Inbox pass so that view fits its type-body
/// budget again. This is the SAFE half of the row to move: it is pure UI over closures and owns
/// only its own list/query state. The row keeps the life-area picker, whose superseded-PATCH
/// cancellation and rollback are load-bearing and covered by `CaptureInboxLifeAreaRaceTests` —
/// deliberately not relocated by a design pass.
///
/// Behaviour is carried over verbatim, accessibility identifiers included, so the existing UI tests
/// and muscle memory both still find it.
struct CaptureRowTagEditor: View {
    let onLoadTags: () async -> [Tag]
    let onLoadAllTags: () async -> [Tag]
    let onAddExistingTag: (UUID) async -> Void
    let onCreateTag: (String) async -> Void
    let onRemoveTag: (UUID) async -> Void

    @State private var currentTags: [Tag] = []
    @State private var allTags: [Tag] = []
    @State private var tagQuery = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !currentTags.isEmpty {
                currentTagsRow
            }

            TextField("Add a tag", text: $tagQuery)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("captureTagSearchField")

            if !trimmedTagQuery.isEmpty {
                ForEach(filteredTagSuggestions) { tag in
                    Button(tag.name) {
                        let tagId = tag.id
                        Task {
                            await onAddExistingTag(tagId)
                            tagQuery = ""
                            currentTags = await onLoadTags()
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("captureTagSuggestion-\(tag.name)")
                }
                if !tagQueryMatchesExistingTag {
                    Button("Create \"\(trimmedTagQuery)\"") {
                        let name = trimmedTagQuery
                        Task {
                            await onCreateTag(name)
                            tagQuery = ""
                            currentTags = await onLoadTags()
                            allTags = await onLoadAllTags()
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("captureCreateTagButton")
                }
            }
        }
        // The row only renders this while expanded, so loading on appear keeps the previous
        // `.task(id: isExpanded)` timing: tags are fetched when the editor comes into existence.
        .task {
            currentTags = await onLoadTags()
            allTags = await onLoadAllTags()
        }
    }

    private var currentTagsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(currentTags) { tag in
                    HStack(spacing: 4) {
                        Text(tag.name)
                            .font(.caption)
                        Button {
                            let tagId = tag.id
                            Task {
                                await onRemoveTag(tagId)
                                currentTags = await onLoadTags()
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                        }
                        .accessibilityIdentifier("captureRemoveTagButton-\(tag.name)")
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.secondarySystemBackground), in: Capsule())
                }
            }
        }
        .accessibilityIdentifier("captureCurrentTagsRow")
    }

    private var trimmedTagQuery: String {
        tagQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filteredTagSuggestions: [Tag] {
        let currentTagIds = Set(currentTags.map(\.id))
        return allTags.filter {
            !currentTagIds.contains($0.id) && $0.name.localizedCaseInsensitiveContains(trimmedTagQuery)
        }
    }

    private var tagQueryMatchesExistingTag: Bool {
        allTags.contains { $0.name.localizedCaseInsensitiveCompare(trimmedTagQuery) == .orderedSame }
    }
}

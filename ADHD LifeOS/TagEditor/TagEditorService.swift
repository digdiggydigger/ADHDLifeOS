//
//  TagEditorService.swift
//  ADHD LifeOS
//

import Combine
import Foundation

/// Owns the tag-editor list state and every mutation. Mutations are **serialised** — a second
/// `PATCH`/`DELETE` cannot begin while one is in flight (`isMutating`) — closing the superseded-
/// response race class fixed for Life Areas in `8e19a08`; the views also disable Save while
/// `isMutating`. After any successful merge, delete, or create the list is **reloaded** from the
/// server rather than mutated locally, because those operations change *other* tags' counts and a
/// stale count is the number the delete confirm quotes.
@MainActor
final class TagEditorService: ObservableObject {
    enum LoadState: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    @Published private(set) var state: LoadState = .loading
    @Published private(set) var tags: [EditableTag] = []
    @Published private(set) var isMutating = false
    /// Non-`nil` drives the rename-clash `.alert`; set only when a rename returns `409`.
    @Published var pendingMergeConflict: TagRenameConflict?
    /// A human-readable failure surfaced to the user; never a raw decoding error.
    @Published var errorMessage: String?
    /// A brief, non-error notice (e.g. a create that deduped into an existing tag).
    @Published var infoMessage: String?

    private let client: TagEditorClientAdapting

    init(client: TagEditorClientAdapting) {
        self.client = client
    }

    func load() async {
        state = .loading
        do {
            tags = Self.sorted(try await client.fetchTags())
            state = .loaded
        } catch {
            state = .failed(Self.message(for: error))
        }
    }

    /// Rename `tag` to `newName`. Returns `true` when the caller (detail screen) should pop back to
    /// the list. A `409` sets `pendingMergeConflict` (drives the alert) and returns `false` — the
    /// screen stays put with the typed name intact so E can edit or merge.
    @discardableResult
    func rename(tag: EditableTag, to newName: String) async -> Bool {
        errorMessage = nil
        switch TagEditorValidation.renameChange(current: tag.name, proposed: newName) {
        case .invalidEmpty, .unchanged:
            // Save is disabled in these states; if reached anyway, write nothing.
            return false
        case .valid(let name):
            guard !isMutating else { return false }
            isMutating = true
            defer { isMutating = false }
            do {
                switch try await client.renameTag(id: tag.id, to: name) {
                case .renamed:
                    await reload()
                    return true
                case .needsMerge(let conflict):
                    pendingMergeConflict = conflict
                    return false
                }
            } catch {
                errorMessage = Self.message(for: error)
                return false
            }
        }
    }

    /// Confirm a merge from the rename-clash alert: re-`PATCH` with `onConflict: "merge"`, then
    /// reload (the survivor's count changes). Returns `true` to pop back to the list.
    @discardableResult
    func confirmMerge(tag: EditableTag, into name: String) async -> Bool {
        guard !isMutating else { return false }
        isMutating = true
        defer { isMutating = false }
        pendingMergeConflict = nil
        errorMessage = nil
        do {
            try await client.mergeTag(id: tag.id, into: name)
            await reload()
            return true
        } catch {
            errorMessage = Self.message(for: error)
            return false
        }
    }

    /// Cancel the merge — writes nothing, just dismisses the alert.
    func cancelMerge() {
        pendingMergeConflict = nil
    }

    /// Delete `tag` (cascade handled server-side), then reload. Returns `true` to pop to the list.
    @discardableResult
    func delete(tag: EditableTag) async -> Bool {
        guard !isMutating else { return false }
        isMutating = true
        defer { isMutating = false }
        errorMessage = nil
        do {
            try await client.deleteTag(id: tag.id)
            await reload()
            return true
        } catch {
            errorMessage = Self.message(for: error)
            return false
        }
    }

    /// Create a tag from the add sheet. `POST /tags` dedups server-side, so an existing name is not
    /// an error: it surfaces a brief notice instead of adding a phantom row. Returns `true` when the
    /// sheet should dismiss.
    @discardableResult
    func create(name rawName: String) async -> Bool {
        errorMessage = nil
        infoMessage = nil
        guard let name = TagEditorValidation.normalizeNewName(rawName) else { return false }
        guard !isMutating else { return false }
        isMutating = true
        defer { isMutating = false }
        do {
            switch try await client.createTag(name: name) {
            case .created:
                await reload()
                return true
            case .alreadyExisted(let existing):
                infoMessage = "\"\(existing.name)\" already exists."
                await reload()
                return true
            }
        } catch {
            errorMessage = Self.message(for: error)
            return false
        }
    }

    private func reload() async {
        do {
            tags = Self.sorted(try await client.fetchTags())
        } catch {
            // The mutation itself succeeded; a reload failure is a soft error — surface it but keep
            // the screen usable rather than flipping the whole list into a failed state.
            errorMessage = Self.message(for: error)
        }
    }

    /// Case-insensitive sort by name. Pure and static so it is unit-testable directly.
    static func sorted(_ tags: [EditableTag]) -> [EditableTag] {
        tags.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}

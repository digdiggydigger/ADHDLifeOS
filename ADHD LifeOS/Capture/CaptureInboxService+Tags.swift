//
//  CaptureInboxService+Tags.swift
//  ADHD LifeOS
//
//  The capture tag methods, in their own file for the same reason as `+Triage`: the service is at
//  its type-body budget. None of these touch `state`, whose `private(set)` writers must stay in
//  the main file; `client`/`triageErrorMessage`/`message(for:)` are internal for exactly this
//  arrangement.
//

import Foundation

@MainActor
extension CaptureInboxService {
    // MARK: - Composer draft tags (E's directive: tags at the point of capture)

    /// Attaches the draft's selected tags to a just-created capture. Non-blocking like every
    /// tag path here: the capture already exists, so a failed attach WARNS rather than failing
    /// the save (a re-save would duplicate the capture). Selection resets either way.
    func attachDraftTags(to capture: Capture) async {
        let selected = newCaptureTagIds
        newCaptureTagIds = []
        guard !selected.isEmpty else { return }
        for tagId in selected {
            do {
                try await client.addTag(captureId: capture.id, tagId: tagId)
            } catch {
                warningMessage = "Saved, but some tags could not be attached."
            }
        }
    }

    /// Creates a tag from the composer (server dedups by name) and selects it for the draft.
    @discardableResult
    func createTagForDraft(name: String) async -> Tag? {
        triageErrorMessage = nil
        do {
            let tag = try await client.createTag(name: name)
            if !newCaptureTagIds.contains(tag.id) {
                newCaptureTagIds.append(tag.id)
            }
            return tag
        } catch {
            triageErrorMessage = Self.message(for: error)
            return nil
        }
    }

    /// Failures here are swallowed to an empty list rather than surfaced — a failed tag-search
    /// fetch shouldn't block the rest of the triage UI, same "non-blocking" spirit as
    /// `refresh()`.
    func fetchAllTags() async -> [Tag] {
        (try? await client.fetchAllTags()) ?? []
    }

    func fetchTags(for capture: Capture) async -> [Tag] {
        (try? await client.fetchTags(captureId: capture.id)) ?? []
    }

    @discardableResult
    func addExistingTag(capture: Capture, tagId: UUID) async -> Bool {
        triageErrorMessage = nil
        do {
            try await client.addTag(captureId: capture.id, tagId: tagId)
            return true
        } catch {
            triageErrorMessage = Self.message(for: error)
            return false
        }
    }

    /// Creates a new tag (server dedups by name) then attaches it to the capture. Returns the
    /// created/deduped tag on success so the caller can update its local tag list without a
    /// second fetch.
    @discardableResult
    func createAndAddTag(capture: Capture, name: String) async -> Tag? {
        triageErrorMessage = nil
        do {
            let tag = try await client.createTag(name: name)
            try await client.addTag(captureId: capture.id, tagId: tag.id)
            return tag
        } catch {
            triageErrorMessage = Self.message(for: error)
            return nil
        }
    }

    @discardableResult
    func removeTag(capture: Capture, tagId: UUID) async -> Bool {
        triageErrorMessage = nil
        do {
            try await client.removeTag(captureId: capture.id, tagId: tagId)
            return true
        } catch {
            triageErrorMessage = Self.message(for: error)
            return false
        }
    }
}

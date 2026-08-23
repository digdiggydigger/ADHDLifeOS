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

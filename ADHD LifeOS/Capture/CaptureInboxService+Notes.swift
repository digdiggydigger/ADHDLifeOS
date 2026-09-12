//
//  CaptureInboxService+Notes.swift
//  ADHD LifeOS
//
//  The capture detail screen's three writers — the life-area assignment, the server re-read and the
//  annotation — in their own file so `CaptureInboxService` stays inside its length budget. Moved
//  here by `F-CTACelebrations-5`'s room-first commit, with the file at 397 of SwiftLint's 400.
//
//  The `+Triage` arrangement exactly: `client`, `triageErrorMessage`, `message(for:)` and now
//  `replaceCapture` are internal rather than private for this reason — still owned by the service,
//  just reachable from here. `replaceCapture` itself could not move, because it writes `state`,
//  whose setter is `private(set)` and so has to keep every writer in the type's own file.
//

import Foundation

@MainActor
extension CaptureInboxService {
    /// Assigns (or clears, via `lifeAreaId: nil`) a capture's Life Area. Updates the loaded list
    /// in place on success so the row reflects the change without a full reload.
    @discardableResult
    func updateLifeArea(capture: Capture, lifeAreaId: UUID?) async -> Bool {
        triageErrorMessage = nil
        do {
            let updated = try await client.updateCapture(
                id: capture.id, changes: CaptureUpdate(lifeAreaId: .some(lifeAreaId))
            )
            replaceCapture(updated)
            return true
        } catch {
            triageErrorMessage = Self.message(for: error)
            return false
        }
    }

    /// The detail screen's re-fetch (the `TaskDetailView` precedent: the push carries an id, the
    /// screen re-reads the server's document rather than trusting a possibly stale list row).
    /// Throws rather than publishing a message — the failure belongs to the detail screen's own
    /// local state, not to the list behind it.
    func fetchCaptureDetail(id: UUID) async throws -> Capture {
        try await client.fetchCapture(id: id)
    }

    /// Saves (or, for whitespace-only input, clears) the user's annotation. Returns the server's
    /// re-read document so the detail screen can adopt it; the loaded list gets the same copy so
    /// the row behind the detail agrees without a reload. `nil` means the write failed and
    /// `triageErrorMessage` says why.
    @discardableResult
    func saveNotes(capture: Capture, notes: String) async -> Capture? {
        triageErrorMessage = nil
        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let updated = try await client.updateCapture(
                id: capture.id,
                changes: CaptureUpdate(notes: trimmed.isEmpty ? .some(nil) : .some(trimmed))
            )
            replaceCapture(updated)
            return updated
        } catch {
            triageErrorMessage = Self.message(for: error)
            return nil
        }
    }
}

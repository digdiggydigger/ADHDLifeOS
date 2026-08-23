//
//  CaptureInboxService+Triage.swift
//  ADHD LifeOS
//
//  The two triage exits added on 2026-08-20 (Inbox block 2), in their own file so
//  `CaptureInboxService` stays inside its length budgets. `client`/`journalClient`/`message(for:)`
//  are internal rather than private for exactly this reason — they are still owned by the service,
//  just reachable from this extension.
//

import Foundation

@MainActor
extension CaptureInboxService {
    /// Discards a capture outright. The triage exit for something that is neither a task nor worth
    /// keeping: without it, a stray thought sat in the inbox forever, because promote-to-task was
    /// the ONLY way anything could leave.
    ///
    /// Deliberately not optimistic — the row disappears only once the delete has landed. An
    /// optimistic removal that failed would look exactly like a successful discard while the
    /// capture was still there on the next load.
    @discardableResult
    func discard(capture: Capture) async -> Bool {
        triageErrorMessage = nil
        do {
            try await client.deleteCapture(id: capture.id)
            removeCapture(id: capture.id)
            return true
        } catch {
            triageErrorMessage = Self.message(for: error)
            return false
        }
    }

    /// Archives a capture as "seen" — the exit for "noted, nothing to do". Unlike discard the
    /// capture survives, in the Captures tab, still unprocessed and still promotable. Same
    /// non-optimistic discipline as discard: the row leaves only once the write has landed.
    @discardableResult
    func markSeen(capture: Capture) async -> Bool {
        await setSeen(capture: capture, to: true)
    }

    /// Sends a seen capture back to the inbox — the undo for an archive that was premature. An
    /// explicit `false` lands on the document (see `FirestoreFieldPayloads`); the row leaves the
    /// Seen list it was tapped on.
    @discardableResult
    func undoSeen(capture: Capture) async -> Bool {
        await setSeen(capture: capture, to: false)
    }

    private func setSeen(capture: Capture, to seen: Bool) async -> Bool {
        triageErrorMessage = nil
        do {
            _ = try await client.updateCapture(id: capture.id, changes: CaptureUpdate(seen: seen))
            removeCapture(id: capture.id)
            return true
        } catch {
            triageErrorMessage = Self.message(for: error)
            return false
        }
    }

    /// Writes the capture into the journal and retires it — the web inbox's "Log to Journal" path.
    ///
    /// Order is load-bearing: the entry is written FIRST and the capture is only marked processed
    /// once that succeeded. The reverse order would retire a capture whose entry never landed,
    /// which loses the thought entirely — the one outcome an inbox exists to prevent.
    ///
    /// Deviation from the web, flagged rather than silently dropped: its journal promote also
    /// collects energy and mood. The native `Log` model has neither field (see `LogModels.swift`),
    /// so porting them would be a schema change, not a UI port.
    @discardableResult
    func logToJournal(
        capture: Capture,
        energyLevel: EnergyLevel? = nil,
        moodEmoji: String? = nil
    ) async -> Bool {
        triageErrorMessage = nil
        guard let journalClient else {
            triageErrorMessage = "Journal is unavailable."
            return false
        }

        let normalized: NormalizedCreateLogInput
        switch LogValidation.normalizeCreateLogInput(
            body: Self.journalBody(for: capture), type: .journal, lifeAreaId: capture.lifeAreaId,
            energyLevel: energyLevel, moodEmoji: moodEmoji
        ) {
        case .success(let value):
            normalized = value
        case .failure(let error):
            triageErrorMessage = error.errorDescription
            return false
        }

        do {
            _ = try await journalClient.createLog(normalized)
            try await client.markProcessed(captureId: capture.id)
            removeCapture(id: capture.id)
            return true
        } catch {
            triageErrorMessage = Self.message(for: error)
            return false
        }
    }

    /// A titled capture keeps BOTH lines — the headline it was given and whatever it pointed at —
    /// because for a link capture the title alone loses the URL and the content alone loses the
    /// point. Untitled captures are just their content.
    private static func journalBody(for capture: Capture) -> String {
        guard let title = capture.title?.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty,
              title != capture.content.trimmingCharacters(in: .whitespacesAndNewlines)
        else { return capture.content }
        return "\(title)\n\(capture.content)"
    }
}

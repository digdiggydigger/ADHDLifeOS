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
    func logToJournal(capture: Capture) async -> Bool {
        triageErrorMessage = nil
        guard let journalClient else {
            triageErrorMessage = "Journal is unavailable."
            return false
        }

        let normalized: NormalizedCreateLogInput
        switch LogValidation.normalizeCreateLogInput(
            body: Self.journalBody(for: capture), type: .journal, lifeAreaId: capture.lifeAreaId
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

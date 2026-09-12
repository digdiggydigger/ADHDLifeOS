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
    var displayedCaptures: [Capture] {
        CaptureSkipOrdering.apply(
            captures: CaptureListRefinement.apply(
                captures: captures, newestFirst: sortNewestFirst, kind: kindFilter
            ),
            skippedIds: skippedIds
        )
    }

    /// Sends a capture to the back of the displayed queue. Skipping one already at the back
    /// re-stamps its position, which is what tapping Skip on it again should mean.
    func skip(_ capture: Capture) {
        skippedIds.removeAll { $0 == capture.id }
        skippedIds.append(capture.id)
        record(.skipped(captureId: capture.id), sortedInto: nil)
    }

    /// **Sorted** — the triage verb E asked for on 2026-08-28, and since the A2/A3 audit the ONLY
    /// way a capture reaches the `seen` state from anywhere in the app.
    ///
    /// A life area is required, so the exit stamp and the filing land in ONE write and a capture
    /// can never end up sorted-but-unfiled. The capture detail screen used to reach the same state
    /// through an unconditional `markSeen`; it now calls this, so the requirement holds wherever
    /// the tap happens. Same non-optimistic discipline as every other exit — the row leaves only
    /// once the write has landed, and a failure offers no undo, because nothing happened.
    @discardableResult
    func sort(capture: Capture, into lifeAreaId: UUID) async -> Bool {
        triageErrorMessage = nil
        do {
            _ = try await client.updateCapture(
                id: capture.id,
                changes: CaptureUpdate(
                    lifeAreaId: .some(lifeAreaId), seen: true, clearedAt: .some(Date())
                )
            )
            removeCapture(id: capture.id)
            await refreshCountsAfterExit()
            await celebrateIfInboxCleared(capture)   // E's F3, doing verb 1 of 3
            record(
                .sorted(captureId: capture.id, previousLifeAreaId: capture.lifeAreaId),
                sortedInto: lifeAreaId
            )
            return true
        } catch {
            triageErrorMessage = Self.message(for: error)
            return false
        }
    }

    /// Takes back the last reversible action, and is then SPENT — one undo, never a loop that
    /// re-reverses itself on a second tap.
    ///
    /// A skip is in-memory, so it reverses instantly. A sort has to un-write: the exit stamp goes,
    /// `seen` goes explicitly false, and the area returns to whatever it was BEFORE — including
    /// nil, since an undone sort must not leave behind the area it only just wrote. The list comes
    /// back through `refresh()`, the quiet path that never blanks a list already on screen.
    @discardableResult
    func undoLastTriageAction() async -> Bool {
        guard let action = lastTriageAction else { return false }
        switch action {
        case .skipped(let captureId):
            skippedIds.removeAll { $0 == captureId }
            clearLastTriageAction()
            return true
        case .journaled(let captureId, let logId):
            return await undoJournalEntry(captureId: captureId, logId: logId)
        case .sorted(let captureId, let previousLifeAreaId):
            triageErrorMessage = nil
            do {
                _ = try await client.updateCapture(
                    id: captureId,
                    changes: CaptureUpdate(
                        lifeAreaId: .some(previousLifeAreaId), seen: false, clearedAt: .some(nil)
                    )
                )
                clearLastTriageAction()
                await refresh()
                // `refresh()` only ever corrects the tab being stood on. Undo moved the capture
                // OFF another slice, so that one is stale in exactly the way an exit leaves it.
                await refreshCountsAfterExit()
                return true
            } catch {
                triageErrorMessage = Self.message(for: error)
                return false
            }
        }
    }

    func clearLastTriageAction() {
        lastTriageAction = nil
        lastSortedAreaId = nil
    }

    private func record(_ action: CaptureTriageAction, sortedInto: UUID?) {
        lastTriageAction = action
        lastSortedAreaId = sortedInto
    }

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
            await refreshCountsAfterExit()
            return true
        } catch {
            triageErrorMessage = Self.message(for: error)
            return false
        }
    }

    /// Sends a sorted capture back to the inbox — the way out of a decision taken too early, and
    /// now the ONLY writer of `seen` besides `sort`.
    ///
    /// There used to be a forward twin, `markSeen`, reached from the capture detail screen: it
    /// wrote the same state with no life area required, so a capture could land in the **Sorted**
    /// slice having never been sorted anywhere (the audit's A3). The rule belongs to the state,
    /// not to whichever screen happens to write it, so the forward direction is `sort` everywhere
    /// and this is what remains.
    ///
    /// An explicit `false` lands on the document rather than a delete (see
    /// `FirestoreFieldPayloads`), the exit stamp is deleted (M7), and the row leaves the Sorted
    /// list it was tapped on. Non-optimistic like every other exit: the row goes only once the
    /// write has landed.
    @discardableResult
    func undoSeen(capture: Capture) async -> Bool {
        triageErrorMessage = nil
        do {
            _ = try await client.updateCapture(
                id: capture.id,
                changes: CaptureUpdate(seen: false, clearedAt: .some(nil))
            )
            removeCapture(id: capture.id)
            await refreshCountsAfterExit()
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
            let entry = try await journalClient.createLog(normalized)
            try await client.markProcessed(captureId: capture.id)
            removeCapture(id: capture.id)
            await refreshCountsAfterExit()
            await celebrateIfInboxCleared(capture)   // E's F3, doing verb 2 of 3
            record(.journaled(captureId: capture.id, logId: entry.id), sortedInto: nil)
            return true
        } catch {
            triageErrorMessage = Self.message(for: error)
            return false
        }
    }

    /// Reverses "Journal it": the capture comes back to the inbox and the entry it wrote is
    /// deleted.
    ///
    /// **The order is the reverse of the forward path's, for the same reason.** Writing the entry
    /// first and retiring the capture second means a half-failure never loses the thought;
    /// restoring the capture first and deleting the entry second means the same thing coming back.
    /// Delete-first would, on a failed restore, erase the thought from both places at once — the
    /// one outcome an inbox exists to prevent.
    ///
    /// So a failed restore reverses nothing, deletes nothing, and leaves the offer standing. A
    /// failed delete still counts as an undo — the capture is back, which is what was asked — but
    /// says plainly what it left behind, the same shape as promotion's partial-failure warning.
    private func undoJournalEntry(captureId: UUID, logId: UUID) async -> Bool {
        triageErrorMessage = nil
        do {
            try await client.markUnprocessed(captureId: captureId)
        } catch {
            triageErrorMessage = Self.message(for: error)
            return false
        }
        do {
            try await journalClient?.deleteLog(id: logId)
        } catch {
            warningMessage = "Capture is back in your inbox, but its journal entry couldn't be removed."
        }
        clearLastTriageAction()
        await refresh()
        await refreshCountsAfterExit()
        return true
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

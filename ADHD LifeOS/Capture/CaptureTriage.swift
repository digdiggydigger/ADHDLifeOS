//
//  CaptureTriage.swift
//  ADHD LifeOS
//

import Foundation

/// A triage action that can be taken back, described by what REVERSING it means.
///
/// Only the two actions the card owns outright are here. "Task it" opens the promote sheet (a
/// flow, not an instant), and "Journal it" writes a `Log` and marks the capture processed — undoing
/// that would need a log-delete and an unprocess path that do not exist yet. An Undo offered for
/// something it cannot actually reverse is worse than no Undo, so neither is claimed.
enum CaptureTriageAction: Equatable, Sendable {
    /// `previousLifeAreaId` is what the capture was filed under BEFORE the sort — restoring it is
    /// the whole job, since sorting may have replaced an area or written the first one.
    case sorted(captureId: UUID, previousLifeAreaId: UUID?)
    case skipped(captureId: UUID)
}

/// The rules behind **Sorted** — the triage verb E asked for on 2026-08-28 ("capturing is fine,
/// deciding isn't").
///
/// Sorted is not a new state: `seen` has existed since the third-exit block, but it was reachable
/// only from capture detail and it required nothing. The verb now carries a condition — **a life
/// area is required**, tags stay optional (E's call) — so "dealt with" always also means "and I
/// know where it lives". Pure and total, so the card, the button's enabled state and the undo bar
/// all read the same rules.
enum CaptureTriage {
    /// A pick staged on the card, and WHICH capture it was staged for. The card is a queue —
    /// sorting one advances to the next — so an unkeyed pick would silently file the next capture
    /// wherever the last one went.
    ///
    /// `lifeAreaId` is optional because "cleared" has to be expressible: E can now tap the lit chip
    /// to unmake the choice (2026-08-28), and on an already-filed capture that has to STICK rather
    /// than spring back to the stored area.
    struct StagedSelection: Equatable, Sendable {
        let captureId: UUID
        let lifeAreaId: UUID?
    }

    /// The one resolution: the area this capture would be sorted into right now.
    ///
    /// A staged record for THIS capture wins outright — including an empty one, which is what
    /// makes deselection stick. With nothing staged the chips open on the capture's own area, so a
    /// capture filed in the composer shows where it lives rather than presenting the choice as
    /// unmade, and is already sorted enough to go without E re-picking.
    ///
    /// Everything reads this — the chips, the button's enabled state, its glow, and the write —
    /// so they cannot disagree about what is chosen.
    static func area(staged: StagedSelection?, for capture: Capture) -> UUID? {
        guard let staged, staged.captureId == capture.id else { return capture.lifeAreaId }
        return staged.lifeAreaId
    }

    /// The requirement, restated in one place: sorting files a capture, so it needs somewhere to
    /// file it.
    static func canSort(area: UUID?) -> Bool {
        area != nil
    }

    /// How much the Sorted button should shout. E's 2026-08-28 screenshot note: it must be
    /// eye-catching ONLY once the requirement is met — before that it was indistinguishable from
    /// its own disabled state, so nothing on screen said what was missing.
    ///
    /// Derived from `canSort` rather than restated, so the glow and the tap can never disagree.
    enum SortedEmphasis: Equatable, Sendable {
        /// Quiet and unavailable — an area has not been chosen.
        case waiting
        /// Lit: this will file the capture and clear it from the inbox.
        case ready
    }

    static func emphasis(area: UUID?) -> SortedEmphasis {
        canSort(area: area) ? .ready : .waiting
    }

    /// What the undo bar says happened. A deleted area degrades to the bare verb rather than
    /// quoting a raw UUID — the `CapturePlaceLabel` rule, applied to areas.
    static func confirmation(
        for action: CaptureTriageAction, sortedInto: UUID?, lifeAreas: [LifeArea]
    ) -> String {
        switch action {
        case .skipped:
            return "Skipped — it'll come back round"
        case .sorted:
            guard let sortedInto, let area = lifeAreas.first(where: { $0.id == sortedInto }) else {
                return "Sorted"
            }
            return "Sorted to \(area.colour) \(area.name)"
        }
    }
}

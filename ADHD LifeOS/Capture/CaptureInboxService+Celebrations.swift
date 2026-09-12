//
//  CaptureInboxService+Celebrations.swift
//  ADHD LifeOS
//
//  `F-CTACelebrations-5`: **inbox zero**, the first of E's four full-screen milestones (F3, F8).
//
//  **Why the listener is here and not in the five screens that host a service.** The Inbox, the
//  Captures tab, the pushed capture detail, Home's inbox peek and the Journal timeline all reach
//  the same three verbs. A listener in each would be five copies of one rule, and a sixth door
//  would simply never celebrate — the failure mode the register calls a dead shared component,
//  except inverted: the component would be alive and unreachable from the newest caller.
//
//  **R-a is the whole of the interesting logic.** Every exit — sort, journal, promote, discard,
//  undo-seen — funnels through the same `removeCapture`, so a listener placed one level down would
//  celebrate a BINNED inbox exactly as loudly as a cleared one. E named three doing verbs; the
//  other two call nothing here, and `testDiscardingTheLastCaptureCelebratesNothing` is what keeps
//  it that way.
//

import Foundation

@MainActor
extension CaptureInboxService {
    /// Called by `sort`, `logToJournal` and `promoteToTask` once the exit has landed and the
    /// capture has left the list. Silent unless this capture was genuinely waiting AND nothing is
    /// waiting now.
    ///
    /// The origin is `nil`: the site has already thrown its own pop from the control that was
    /// tapped (`F-CTACelebrations-4`), and a milestone has no origin but the screen.
    func celebrateIfInboxCleared(_ capture: Capture) async {
        guard CaptureInboxZero.wasWaiting(capture), await isInboxNowEmpty() else { return }
        celebrate.request(.milestone(.inboxZero), at: nil)
    }

    /// **Two shapes, and the second is not an optimisation.** A screen holding the to-triage list
    /// already has the answer in memory — `removeCapture` has just rewritten it — and asking the
    /// server would cost a round trip to learn something it knows. A door built for ONE capture
    /// (`JournalCaptureDoor`, Home's inbox peek) has no list at all, and an empty `state` there
    /// means "never loaded", not "nothing waiting". So it asks, once.
    ///
    /// **A fetch that FAILED is not an empty inbox.** `?? []` would read a dropped connection as
    /// "you cleared everything" and throw a full-screen celebration at it — the same mistake
    /// `HomeService.allTasks` records for the arrival card, where an emptied list is not "don't
    /// know" but the positive claim "there is nothing".
    private func isInboxNowEmpty() async -> Bool {
        if filter == .unprocessed, case .loaded(let remaining) = state {
            return remaining.isEmpty
        }
        guard let stillWaiting = try? await client.fetchUnprocessedCaptures() else { return false }
        return stillWaiting.isEmpty
    }
}

/// The one predicate behind the milestone, pure so it can be read rather than inferred.
enum CaptureInboxZero {
    /// Whether this capture was in the to-triage queue before the verb that just retired it.
    ///
    /// The two flags are orthogonal by design (see `Capture.seen`): a sorted capture stays
    /// unprocessed so it can still be promoted later. Both therefore have to be checked — a
    /// capture promoted from the **Captures** tab was already sorted, so it was never one of the
    /// ones the inbox was counting and cannot be what emptied it. This matches exactly what
    /// `FirebaseCaptureClientAdapter.fetchUnprocessedCaptures` returns.
    static func wasWaiting(_ capture: Capture) -> Bool {
        !capture.processed && capture.seen != true
    }
}

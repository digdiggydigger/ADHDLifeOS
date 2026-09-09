//
//  FocusSessionService+Completions.swift
//  ADHD LifeOS
//
//  The unconfirmed-completion stack (F-FocusCard-2), in its own file so `FocusSessionService`
//  stays inside its length budget — the same arrangement as `FocusSessionService+Persistence`,
//  and the reason `unconfirmedCompletions` is published without a `private(set)`: that scopes the
//  setter to the file that declares the property, and this is a different one.
//

import Foundation

extension FocusSessionService {
    /// Raises a confirmation card for a sprint that ran its countdown out, and persists the stack
    /// in the same move.
    ///
    /// **Newest first**, so E's iOS-notification presentation reads straight off the array: the
    /// card in front is `.first` and a card's depth is its index. Called synchronously from
    /// `stop()` BEFORE the history write, so the card exists even if Firestore hangs.
    ///
    /// The whole stack is rewritten rather than appended to, because `write` takes the array: it
    /// keeps the persisted order identical to the published one by construction.
    func pushUnconfirmedCompletion(_ record: CompletedFocusSession) {
        unconfirmedCompletions.insert(record, at: 0)
        sprintStore?.writeUnconfirmedCompletions(unconfirmedCompletions)
    }

    /// The Confirm button: dismiss the card, finalise the record, and release the collapse.
    ///
    /// **Finalising is a RE-SAVE, not a partial update, and that is for correctness rather than
    /// economy.** `FirebaseManager.save(_:id:in:)` is `setData` keyed on `id.uuidString` with no
    /// merge — a full upsert. If the provisional write failed (offline: `log` swallows the error
    /// into `logErrorMessage` and the card still shows), an `update` against a document that was
    /// never created would throw, whereas the re-save creates it. Nothing here needs a new
    /// backing-store method, a `FirestoreFieldPayloads` entry or an adapter change.
    ///
    /// **This is the only thing in the app that clears `isCardCollapsed`, and since 2026-09-09 it
    /// clears it only when no sprint is running.** Block 1 shipped collapse deliberately sticky —
    /// E: the card stays collapsed *"until the user has tapped the final, and new, 'Confirmed'
    /// button"* — and block 2 honoured that unconditionally. **Stacking is what made the
    /// consequence visible**, in E's own scenario: a routine auto-starts sprint B while card A is
    /// still waiting, so confirming the OLD card A blew open the NEW sprint B's card, undoing a
    /// collapse the user had just made by hand. E was shown three candidate rules and chose *reset
    /// only if no sprint is running*: the original rule still governs the case it was written
    /// about, and nothing yanks open a card the user just collapsed.
    ///
    /// Only the RESET is conditional. The dismissal, the re-persist and the finalise all happen
    /// either way — `testConfirmLeavesARunningSprintsCardCollapsed` asserts that too, because a
    /// guard placed around the whole tail would pass its headline assertion.
    ///
    /// The dismissal and the persist happen BEFORE the write for the same reason the push does:
    /// the user's tap must land on screen whether or not Firestore answers.
    func confirmCompletion(_ record: CompletedFocusSession) async {
        unconfirmedCompletions.removeAll { $0.id == record.id }
        sprintStore?.writeUnconfirmedCompletions(unconfirmedCompletions)
        if !isActive { setCardCollapsed(false) }
        await log(record.confirmed(at: now()))
    }

    /// Reinstates the stack a relaunch inherited. Called from `restorePersistedSprint` ABOVE its
    /// `guard session == nil, let saved = sprintStore.read()`, which is not a detail: a sprint
    /// that completed cleared its own stored state, so on exactly the path that leaves cards
    /// waiting there is no sprint to read and that guard returns early.
    func restoreUnconfirmedCompletions() {
        guard let sprintStore else { return }
        unconfirmedCompletions = sprintStore.readUnconfirmedCompletions()
    }
}

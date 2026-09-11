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

/// The stamp a natural completion leaves on the service (F-FocusCard-4): the ordinal of this
/// launch's completions, which is what the success haptic keys on, and the record it raised, which
/// is what the burst keys on.
///
/// One value rather than two properties because they are one event. The ordinal exists so the
/// haptic's trigger CHANGES on every completion — `unconfirmedCompletions.count` also falls on
/// Confirm and would buzz on dismissal, and `completedSprintCount` is bumped by manual stops too,
/// which raise no card. The record id exists so only the card that just finished bursts: one keyed
/// to the stack would fire for cards the user never saw, and one keyed to "the front card" would
/// replay on every Confirm that reveals the next.
struct FocusConfirmableCompletion: Equatable {
    let ordinal: Int
    let recordID: UUID
}

/// The stamp a Confirm leaves on the service (F-ConfirmCelebration-1, E's approved R2): the ordinal
/// of this launch's Confirms, which the Confirm haptic and the full-screen celebration key on, and
/// whether that Confirm emptied the stack, which block 2's fireworks will key on.
///
/// **A second stamp, never `FocusConfirmableCompletion` reused.** That one keys the completion
/// haptic and the in-ring burst, and Confirm must leave it alone: written on Confirm it would
/// re-celebrate a card the Confirm merely revealed.
struct FocusConfirmation: Equatable {
    let ordinal: Int
    let clearedStack: Bool
}

extension FocusSessionService {
    /// How many cards have been confirmed this launch. The Confirm haptic's trigger.
    var confirmationCount: Int { latestConfirmation?.ordinal ?? 0 }

    /// How many sprints have finished NATURALLY this launch. The success haptic's trigger — see
    /// `FocusConfirmableCompletion` for why neither existing counter would do.
    var confirmableCompletionCount: Int { latestConfirmableCompletion?.ordinal ?? 0 }

    /// The record whose card should burst, or `nil` when nothing finished this launch.
    var celebratingCompletionID: UUID? { latestConfirmableCompletion?.recordID }

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
        // The ONLY writer of the stamp. Confirm leaves it alone (a revealed card must not
        // re-celebrate) and so does the restore (a relaunch must not replay one).
        latestConfirmableCompletion = FocusConfirmableCompletion(
            ordinal: confirmableCompletionCount + 1, recordID: record.id
        )
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

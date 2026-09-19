//
//  RecentActionCenter.swift
//  ADHD LifeOS
//
//  `F-C1-UndoCapsule`: the app's ONE undo slot.
//
//  **One slot, one occupant, last-writer-wins across kinds — and that is a real behaviour change.**
//  Before this block the Capture Inbox held its own `lastTriageAction`, which survived unrelated
//  navigation and was spent only by a new triage or by being taken. E chose "one bottom bar
//  everywhere" (round 2, Option 1), and one bar means one slot: **closing a task after sorting a
//  capture spends the capture's undo**, and the reverse. E was not asked about that collision
//  because it follows from the choice rather than sitting beside it; it is named here, and in the
//  block report, rather than quietly softened with a second slot.
//
//  Owned by the App (`ADHD_LifeOSApp`) exactly as `CelebrationCenter` is, and for the same reason:
//  built in `RootView` it would be rebuilt on every auth-state swap, dropping whatever was pending.
//

import Foundation

/// The one pending undo, and the only thing that can run it.
@MainActor
final class RecentActionCenter: ObservableObject, RecentActionRecording {
    /// What the capsule draws, or nothing. `private(set)` with a single private writer below, so
    /// "exactly one bare assignment in the whole app target" is a property a test can hold —
    /// `UndoCapsuleCallSiteTests` does, inheriting that guard from the retired closure card.
    @Published private(set) var pendingAction: RecentAction?

    func record(_ action: RecentAction) {
        setPendingAction(action)
    }

    /// Dismissal, never reversal. Replacing or clearing a pending action must not RUN its undo —
    /// the user chose not to take it, which is not the same as taking it.
    func clear() {
        setPendingAction(nil)
    }

    /// Takes the pending action back, and is then SPENT. The slot is emptied BEFORE the reversal
    /// is awaited, so a second tap during a slow network write cannot run the same reversal twice —
    /// which on a task close would reopen and then re-close it.
    func undo() async {
        guard let action = pendingAction else { return }
        setPendingAction(nil)
        await action.undo()
    }

    /// The ONLY writer. Kept private and singular so no site can leave the slot in a state the
    /// capsule never animates into.
    private func setPendingAction(_ action: RecentAction?) {
        pendingAction = action
    }
}

//
//  RecentActionRecording.swift
//  ADHD LifeOS
//
//  `F-C1-UndoCapsule`: the narrow door a SITE speaks through, and the two environment keys behind
//  it.
//
//  **Two keys, exactly as `CelebrationRequesting` has two, and for the same reason.** A site only
//  ever TELLS — `record.record(...)` — so it gets a protocol with an inert default and needs no
//  `if let`, no `init` change, and no setup in any preview or snapshot test. The CAPSULE has to
//  redraw when the slot changes, and `@Environment` does not subscribe to an `ObservableObject`'s
//  `objectWillChange`, so the drawing side takes the object itself and hands it to a child holding
//  `@ObservedObject`. `CelebrationLayer` is the precedent, verbatim.
//
//  A singleton was rejected for the reason `FirebaseManager` records: it cannot be tested at any
//  price. `.environmentObject` was rejected because a missing one traps the moment a body is built.
//

import SwiftUI

/// What a site sees. Two methods: say what just happened, and take it back off the board.
protocol RecentActionRecording {
    /// Records a reversible action, replacing whatever was pending. See `RecentActionCenter` for
    /// why replacing never runs the outgoing reversal.
    func record(_ action: RecentAction)
    /// Drops the pending action WITHOUT reversing it — dismissal, not undo.
    func clear()
}

/// The environment default: everything is recorded, nothing is remembered. A preview that renders
/// a close button draws the button and no capsule, and needs no setup to do it.
struct InertRecentActionRecorder: RecentActionRecording {
    func record(_ action: RecentAction) {}
    func clear() {}
}

private struct RecentActionRecordingKey: EnvironmentKey {
    static let defaultValue: any RecentActionRecording = InertRecentActionRecorder()
}

/// `nil`, not a shared instance: a capsule slot that cannot see the centre draws nothing, which is
/// right for a preview and wrong for the app — so the app's wiring is asserted by
/// `UndoCapsuleCallSiteTests` rather than left to a default that would hide the mistake.
private struct RecentActionCenterKey: EnvironmentKey {
    static let defaultValue: RecentActionCenter? = nil
}

extension EnvironmentValues {
    /// What a SITE reaches for: `recordAction.record(RecentAction(...))`.
    var recordAction: any RecentActionRecording {
        get { self[RecentActionRecordingKey.self] }
        set { self[RecentActionRecordingKey.self] = newValue }
    }

    /// What the CAPSULE and the inbox's header arrow reach for — the observable object, because
    /// both have to redraw when the slot changes and a protocol cannot publish.
    var recentActionCenter: RecentActionCenter? {
        get { self[RecentActionCenterKey.self] }
        set { self[RecentActionCenterKey.self] = newValue }
    }
}

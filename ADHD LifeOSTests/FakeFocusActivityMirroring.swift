//
//  FakeFocusActivityMirroring.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

/// Records the exact lifecycle event sequence `FocusSessionService` sends its Live Activity
/// mirror, so tests can assert ordering — e.g. a replacement start must end the old Activity
/// BEFORE starting the new one.
@MainActor
final class FakeFocusActivityMirroring: FocusActivityMirroring {
    enum Event: Equatable {
        case started(FocusActivitySnapshot)
        case restored(FocusActivitySnapshot)
        case updated(FocusActivitySnapshot)
        case ended(completedNaturally: Bool)
    }

    private(set) var events: [Event] = []

    var startedSnapshots: [FocusActivitySnapshot] {
        events.compactMap {
            if case .started(let snapshot) = $0 { return snapshot }
            return nil
        }
    }

    var updatedSnapshots: [FocusActivitySnapshot] {
        events.compactMap {
            if case .updated(let snapshot) = $0 { return snapshot }
            return nil
        }
    }

    func sprintStarted(_ snapshot: FocusActivitySnapshot) {
        events.append(.started(snapshot))
    }

    func sprintRestored(_ snapshot: FocusActivitySnapshot) {
        events.append(.restored(snapshot))
    }

    func sprintUpdated(_ snapshot: FocusActivitySnapshot) {
        events.append(.updated(snapshot))
    }

    func sprintEnded(completedNaturally: Bool) {
        events.append(.ended(completedNaturally: completedNaturally))
    }
}

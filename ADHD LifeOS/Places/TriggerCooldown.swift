//
//  TriggerCooldown.swift
//  ADHD LifeOS
//

import Foundation

/// When each place last actually nudged, per direction. Persisted (a background relaunch has no
/// memory of the launch before it), keyed "placeId|kind".
struct TriggerCooldownState: Codable, Equatable {
    var lastFired: [String: Date] = [:]
}

/// The bounce guard: region edges are ~Wi-Fi-accurate, so a device parked NEAR one can cross it
/// repeatedly without moving. One nudge per place per direction per interval — and only a FIRED
/// nudge consumes it, so an empty arrival never inoculates the place against the real one later.
enum TriggerCooldown {
    /// Half an hour: long enough to swallow any bounce, short enough that a genuine second visit
    /// in one day still nudges.
    static let minimumInterval: TimeInterval = 30 * 60

    static func shouldFire(
        _ event: PlaceTriggerEvent, state: TriggerCooldownState, now: Date
    ) -> Bool {
        guard let last = state.lastFired[key(for: event)] else { return true }
        return now.timeIntervalSince(last) > minimumInterval
    }

    static func recording(
        _ event: PlaceTriggerEvent, in state: TriggerCooldownState
    ) -> TriggerCooldownState {
        var updated = state
        updated.lastFired[key(for: event)] = event.occurredAt
        return updated
    }

    private static func key(for event: PlaceTriggerEvent) -> String {
        "\(event.placeId.uuidString)|\(event.kind.rawValue)"
    }
}

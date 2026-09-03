//
//  RoutineDefaults.swift
//  ADHD LifeOS
//
//  Every named number in the Routines arc (F-Routines-1-Order). One home, on purpose: these
//  are sensible defaults for many users, not E-tuned magic — the public-launch lens — and a
//  future Settings surface should be able to expose them without a hunt.
//

import Foundation

enum RoutineDefaults {
    /// A crossing becomes a ROUTINE — one notification opening the ordered routine screen —
    /// at this many tap-steps (E's settled call, 2026-09-03). Below it, the per-action
    /// notifications are the better shape: routing a single step through a screen adds a tap
    /// for nothing, and a place with no tap-steps has nothing to route.
    static let stepThreshold = 2

    /// How long a DEPARTURE run stays live. An arrival run ends at the place's own departure
    /// crossing; a departure run has no such closing bracket, so it gets a fixed window.
    /// Deliberately the same 30 minutes as `TriggerCooldown.minimumInterval` today — a
    /// matched default, not a shared constant, and the two may drift apart on purpose later.
    static let departureRunWindow: TimeInterval = 30 * 60
}

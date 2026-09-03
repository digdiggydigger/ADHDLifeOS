//
//  PlaceRoutineNotificationContent.swift
//  ADHD LifeOS
//
//  The routine notification's words and wire (F-Routines-2-Notify) — pure, so every phrasing
//  is pinned. ONE notification per qualifying crossing, absorbing the place's custom message
//  and the auto-run report (E's settled call #2), so the crossing interrupts once; the task
//  nudge stays its own, visually distinct species and carries tasks alone.
//

import Foundation

enum PlaceRoutineNotificationContent {
    /// The routine's OWN prefix. `placeAction-` is greedy (its router claims anything under
    /// it, broken payloads included, by pinned design) — a routine identifier must never
    /// start with it.
    static let identifierPrefix = "placeRoutine-"

    /// The routine species' notification category — its own look and, later, its own action
    /// buttons. Registered ONCE at launch; `setNotificationCategories` replaces the whole
    /// set, so that call is the app's single category registry.
    static let categoryIdentifier = "PLACE_ROUTINE"

    /// The ONLY thing the tap carries: the minted run UUID. The screen reads steps from the
    /// run store — one source of truth — and a UUID mismatch IS the stale-tap rule.
    static let runIdUserInfoKey = "place_routine_run_id"

    /// A notification is a glance — quote at most this many step names, the
    /// `ArrivalNudgeContent.maximumQuotedTitles` convention.
    static let maximumQuotedSteps = 2

    /// Stable per place+direction, so an undelivered predecessor is REPLACED, never stacked —
    /// the nudge's own rule.
    static func identifier(placeId: UUID, kind: PlaceTriggerEvent.Kind) -> String {
        "\(identifierPrefix)\(placeId.uuidString)-\(kind.rawValue)"
    }

    static func userInfo(for run: RoutineRun) -> [String: String] {
        [runIdUserInfoKey: run.id.uuidString]
    }

    /// Title = the place moment; body = custom message · auto-run report · "N steps ready —
    /// <first names>. Tap to run." (the canvas After board).
    static func notification(for run: RoutineRun, ranLines: [String]) -> (title: String, body: String) {
        let moment = run.direction == .arrival
            ? "You're at \(run.displayName)" : "Leaving \(run.displayName)"
        var parts: [String] = []
        if let message = run.customMessage {
            parts.append(message)
        }
        parts.append(contentsOf: ranLines)
        parts.append(stepsLine(for: run))
        return (title: moment, body: parts.joined(separator: " · "))
    }

    /// "N steps ready — Open Spotify · Text Ben. Tap to run." N counts TAP-steps only — the
    /// auto steps already ran and are reported above, not offered. Always plural on purpose:
    /// the ≥2 threshold is the only door into this notification.
    private static func stepsLine(for run: RoutineRun) -> String {
        let tapSteps = run.steps.filter { $0.state != .autoDone }
        var quoted = tapSteps.prefix(maximumQuotedSteps)
            .map { PlaceActionRowLabel.title(for: $0.action) }
            .joined(separator: " · ")
        if tapSteps.count > maximumQuotedSteps {
            quoted += " · +\(tapSteps.count - maximumQuotedSteps) more"
        }
        return "\(tapSteps.count) steps ready — \(quoted). Tap to run."
    }
}

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

    /// The minted run UUID. Until deferred logging (Block A) this was the ONLY thing the tap
    /// carried, because the crossing had already written the run and the key merely resolved
    /// against the store. It is still carried — the door's stale rule reads it, and a banner
    /// delivered by an older build carries nothing else.
    static let runIdUserInfoKey = "place_routine_run_id"

    /// The whole frozen run, as JSON — the `place_action_json` precedent, for the same reason
    /// and one stronger. E's rule is that a crossing writes NOTHING, so at tap time there is no
    /// stored run for a bare UUID to resolve against: the tap has to be able to CREATE the
    /// routine, and everything it needs to do that rides here.
    static let runPayloadUserInfoKey = "place_routine_run_json"

    /// A notification is a glance — quote at most this many step names, the
    /// `ArrivalNudgeContent.maximumQuotedTitles` convention.
    static let maximumQuotedSteps = 2

    /// Stable per place+direction, so an undelivered predecessor is REPLACED, never stacked —
    /// the nudge's own rule.
    static func identifier(placeId: UUID, kind: PlaceTriggerEvent.Kind) -> String {
        "\(identifierPrefix)\(placeId.uuidString)-\(kind.rawValue)"
    }

    static func userInfo(for run: RoutineRun) -> [String: String] {
        var info = [runIdUserInfoKey: run.id.uuidString]
        if let data = try? JSONEncoder().encode(run),
           let json = String(data: data, encoding: .utf8) {
            info[runPayloadUserInfoKey] = json
        }
        return info
    }

    static func run(fromUserInfo userInfo: [AnyHashable: Any]) -> RoutineRun? {
        guard let json = userInfo[runPayloadUserInfoKey] as? String,
              let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(RoutineRun.self, from: data)
    }

    static func runKey(fromUserInfo userInfo: [AnyHashable: Any]) -> UUID? {
        (userInfo[runIdUserInfoKey] as? String).flatMap(UUID.init(uuidString:))
    }

    /// Title = the place moment; body = custom message · what will run by itself · "N steps
    /// ready — <first names>. Tap to run." (the canvas After board).
    ///
    /// The middle part used to be the auto-run REPORT — `Journaled "Leg day"`, past tense,
    /// truthful because the crossing had already written it. Under deferred logging nothing has
    /// run at post time, so it is forward-looking instead. The line was worth keeping rather
    /// than dropping: it is the only place the banner says the routine does something for you.
    static func notification(for run: RoutineRun) -> (title: String, body: String) {
        let moment = run.direction == .arrival
            ? "You're at \(run.displayName)" : "Leaving \(run.displayName)"
        var parts: [String] = []
        if let message = run.customMessage {
            parts.append(message)
        }
        parts.append(contentsOf: run.steps
            .filter { $0.state == .autoDone }
            .compactMap { PlaceActionNotificationContent.willRunLine(for: $0.action) })
        parts.append(stepsLine(for: run))
        return (title: moment, body: parts.joined(separator: " · "))
    }

    /// "N steps ready — Open Spotify · Text Ben. Tap to run." N counts TAP-steps only — the
    /// auto steps need no tap and are named above, not offered. Always plural on purpose:
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

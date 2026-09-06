//
//  RoutineRunRecord.swift
//  ADHD LifeOS
//
//  One `routine_runs` document (F-RoutineRecord-1-Ledger): the durable answer to E's
//  2026-09-05 ask — what was OFFERED, what was ACCEPTED, what was COMPLETED, and when.
//
//  Derived from the live `RoutineRun`, never re-deciding anything the screen decided: the
//  counts are `PlaceRoutineProgress`'s, the step states are the run's, the stamps are the
//  moments the record is told about. `status` is stored for the console's sake; the app reads
//  `phase`, which is derived from the stamps — a document that somehow carries a `dismissed_at`
//  AND a `started_at` was started, because a swipe cannot undo a tap.
//
//  Snake_cased on the wire, the `tasks` / `places` / `location_events` convention. The one
//  camelCase value is a step's `state` ("autoDone"), which is `RoutineStepState`'s own raw
//  value and rides the notification payload already; spelling it twice would be worse.
//

import Foundation

enum RoutineRunPhase: String, Codable, Equatable, Sendable {
    case offered
    case dismissed
    case expired
    case started
    case ended
}

/// How the OFFER was resolved. `tap` is the one that becomes a run.
enum RoutineRunDismissalMethod: String, Codable, Equatable, Sendable {
    case tap
    case swipe
    case timeout
}

enum RoutineRunEndReason: String, Codable, Equatable, Sendable {
    case completed
    case leftPlace = "left_place"
    case windowLapsed = "window_lapsed"
    case dayEnded = "day_ended"
    case replaced
}

struct RoutineRunRecord: Codable, Identifiable, Equatable, Sendable {
    struct Step: Codable, Equatable, Sendable {
        let actionId: UUID
        let title: String
        /// The action's own wire kind name (`open_app`, `journal_line`), so a step can be
        /// joined back to its kind without a table.
        let kind: String
        var state: RoutineStepState
        var resolvedAt: Date?

        enum CodingKeys: String, CodingKey {
            case title, kind, state
            case actionId = "action_id"
            case resolvedAt = "resolved_at"
        }
    }

    /// The minted run key: the banner payload, the local live-run cache and this document
    /// share it, which is what lets each transition address the document without a lookup.
    let id: UUID
    let placeId: UUID
    let direction: PlaceTriggerEvent.Kind
    let displayName: String
    let customMessage: String?
    var status: RoutineRunPhase
    /// The CROSSING, not the write — `RoutineRun.startedAt` is the event's `occurredAt`.
    let offeredAt: Date
    var startedAt: Date?
    var dismissedAt: Date?
    var expiredAt: Date?
    var dismissalMethod: RoutineRunDismissalMethod?
    var steps: [Step]
    var totalStepsCount: Int
    var autoStepsCount: Int
    var completedStepsCount: Int
    var skippedStepsCount: Int
    var timeSpentSeconds: Int
    var lastInteractionAt: Date?
    var endedAt: Date?
    var endReason: RoutineRunEndReason?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, direction, status, steps
        case placeId = "place_id"
        case displayName = "display_name"
        case customMessage = "custom_message"
        case offeredAt = "offered_at"
        case startedAt = "started_at"
        case dismissedAt = "dismissed_at"
        case expiredAt = "expired_at"
        case dismissalMethod = "dismissal_method"
        case totalStepsCount = "total_steps_count"
        case autoStepsCount = "auto_steps_count"
        case completedStepsCount = "completed_steps_count"
        case skippedStepsCount = "skipped_steps_count"
        case timeSpentSeconds = "time_spent_seconds"
        case lastInteractionAt = "last_interaction_at"
        case endedAt = "ended_at"
        case endReason = "end_reason"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Derived from the stamps, strongest first. The stored `status` is written from the same
    /// transitions and should agree; when a document disagrees with itself, this wins.
    var phase: RoutineRunPhase {
        if endedAt != nil { return .ended }
        if startedAt != nil { return .started }
        if expiredAt != nil { return .expired }
        if dismissedAt != nil { return .dismissed }
        return .offered
    }

    // MARK: - Creation

    static func offered(_ run: RoutineRun, now: Date) -> RoutineRunRecord {
        var record = RoutineRunRecord(
            id: run.id,
            placeId: run.placeId,
            direction: run.direction,
            displayName: run.displayName,
            customMessage: run.customMessage,
            status: .offered,
            offeredAt: run.startedAt,
            steps: run.steps.map { step in
                Step(
                    actionId: step.action.id,
                    title: PlaceActionRowLabel.title(for: step.action),
                    kind: step.action.wireKindName,
                    state: step.state,
                    resolvedAt: step.resolvedAt
                )
            },
            totalStepsCount: 0, autoStepsCount: 0, completedStepsCount: 0, skippedStepsCount: 0,
            timeSpentSeconds: 0,
            createdAt: now,
            updatedAt: now
        )
        record.recount(run)
        return record
    }

    // MARK: - Transitions

    mutating func started(at now: Date) {
        startedAt = now
        dismissalMethod = .tap
        status = .started
        updatedAt = now
    }

    mutating func dismissed(at now: Date) {
        dismissedAt = now
        dismissalMethod = .swipe
        status = .dismissed
        updatedAt = now
    }

    mutating func expired(at now: Date) {
        expiredAt = now
        dismissalMethod = .timeout
        status = .expired
        updatedAt = now
    }

    mutating func ended(at now: Date, reason: RoutineRunEndReason) {
        endedAt = now
        endReason = reason
        status = .ended
        updatedAt = now
    }

    /// The screen's step changes, taken from the run wholesale — states, per-step stamps, the
    /// counts and the time spent all come from the SAME run, so they cannot disagree.
    mutating func progressed(to run: RoutineRun) {
        guard run.id == id else { return }
        for index in steps.indices {
            guard let step = run.steps.first(where: { $0.action.id == steps[index].actionId }) else { continue }
            steps[index].state = step.state
            steps[index].resolvedAt = step.resolvedAt
        }
        recount(run)
        lastInteractionAt = run.steps.compactMap(\.resolvedAt).max()
        if let lastInteractionAt {
            updatedAt = lastInteractionAt
        }
    }

    private mutating func recount(_ run: RoutineRun) {
        totalStepsCount = run.steps.count
        autoStepsCount = run.steps.filter { $0.state == .autoDone }.count
        completedStepsCount = PlaceRoutineProgress.doneCount(run)
        skippedStepsCount = run.steps.filter { $0.state == .skipped }.count
        // To the LAST STEP INTERACTION, never to the end stamp: a run ended by a departure an
        // hour later, or left open on a screen, must not claim that hour.
        if let activatedAt = run.activatedAt, let last = run.steps.compactMap(\.resolvedAt).max() {
            timeSpentSeconds = max(0, Int(last.timeIntervalSince(activatedAt)))
        } else {
            timeSpentSeconds = 0
        }
    }
}

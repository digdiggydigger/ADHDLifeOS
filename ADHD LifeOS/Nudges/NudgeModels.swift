//
//  NudgeModels.swift
//  ADHD LifeOS
//

import Foundation

struct Nudge: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var label: String
    var schedule: String
    var active: Bool
    var lastFiredAt: Date?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, label, schedule, active
        case lastFiredAt = "last_fired_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// A partial update payload — mirrors web's `normalizeUpdateNudgeInput`: only fields that
/// actually changed are populated, so `NudgesClientAdapting.updateNudge` only ever sends the
/// delta, never the whole form. `schedule` is encoded to its cron string form only at the adapter
/// boundary (`SupabaseNudgesClientAdapter`) — the wire format/DB column itself is unchanged.
struct NudgeUpdatePayload: Equatable, Sendable {
    var label: String?
    var schedule: NudgeSchedule?
    var active: Bool?

    var isEmpty: Bool { label == nil && schedule == nil && active == nil }
}

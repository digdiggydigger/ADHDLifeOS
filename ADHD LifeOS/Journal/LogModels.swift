//
//  LogModels.swift
//  ADHD LifeOS
//

import Foundation

enum LogType: String, Codable, Equatable, Sendable, CaseIterable {
    case log
    case journal
}

/// Append-only — `public.logs` has no update/delete RLS policy at all, so this type is never
/// mutated once fetched; there is no update/delete method anywhere in this feature.
struct Log: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let lifeAreaId: UUID?
    let type: LogType
    let body: String
    let entryDate: Date
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, type, body
        case lifeAreaId = "life_area_id"
        case entryDate = "entry_date"
        case createdAt = "created_at"
    }
}

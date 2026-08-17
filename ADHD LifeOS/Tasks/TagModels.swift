//
//  TagModels.swift
//  ADHD LifeOS
//

import Foundation

struct Tag: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
}

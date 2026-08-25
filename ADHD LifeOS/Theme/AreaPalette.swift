//
//  AreaPalette.swift
//  ADHD LifeOS
//

import SwiftUI

/// The Momentum v3 identity palette (Claude Design handoff, 2026-08-24): every life area owns one
/// of five hue families — work blue, health teal, admin gold, growth purple, hobby pink. Each
/// family is a four-token set in the asset catalog, all with hand-tuned light/dark variants:
/// - base (`AreaWork`): label-safe — darkened in light mode so text on white stays readable
/// - vivid (`AreaWorkVivid`): bars, rings and solid fills
/// - tint (`AreaWorkTint`): washes behind chips and icon wells
/// - onColor (`OnAreaWork`): text/glyphs over a solid vivid fill
///
/// `LifeArea.colour` stores an EMOJI (app-wide convention, see `FirebaseManager+Seed`), so the
/// resolver maps emoji → family. Six seeded areas share five families — one repeat is forced, and
/// gold suits both 🏠 (v3's "Admin & Home") and 💰. Unknown emoji fall back on the first UUID
/// byte, which is stable across launches, renames and reorders (never `hashValue`: that is
/// salted per process and would reshuffle hues on every launch).
enum AreaPalette: String, CaseIterable {
    case work = "AreaWork"
    case health = "AreaHealth"
    case admin = "AreaAdmin"
    case growth = "AreaGrowth"
    case hobby = "AreaHobby"

    var assetName: String { rawValue }
    var vividAssetName: String { rawValue + "Vivid" }
    var tintAssetName: String { rawValue + "Tint" }
    var onAssetName: String { "On" + rawValue }

    var color: Color { Color(assetName) }
    var vivid: Color { Color(vividAssetName) }
    var tint: Color { Color(tintAssetName) }
    var onColor: Color { Color(onAssetName) }

    /// Wire key for the stored per-area override (`LifeArea.palette`) — a clean noun, never the
    /// asset name, so the catalog can be reorganised without a data migration.
    var key: String {
        switch self {
        case .work: return "work"
        case .health: return "health"
        case .admin: return "admin"
        case .growth: return "growth"
        case .hobby: return "hobby"
        }
    }

    /// What the editor's swatches call each family — the colour, not the seeded area name, since
    /// the whole point of the override is that any area can wear any hue.
    var displayName: String {
        switch self {
        case .work: return "Blue"
        case .health: return "Teal"
        case .admin: return "Gold"
        case .growth: return "Purple"
        case .hobby: return "Pink"
        }
    }

    init?(key: String) {
        guard let match = AreaPalette.allCases.first(where: { $0.key == key }) else { return nil }
        self = match
    }

    /// Keys are stored WITHOUT U+FE0F — `family(for:)` strips the variation selector before the
    /// lookup, so the seed's bare emoji and a picker's presentation form resolve identically.
    private static let emojiFamilies: [String: AreaPalette] = [
        "🫀": .health, "🏋": .health,
        "💼": .work,
        "🏠": .admin, "📝": .admin, "💰": .admin,
        "🌱": .growth, "🧘": .growth,
        "💬": .hobby, "🎨": .hobby
    ]

    static func family(for area: LifeArea) -> AreaPalette {
        // An explicitly assigned colour beats the emoji mapping (E's 2026-08-25 call) — this is
        // the one choke point every surface resolves through, so the override repaints cards,
        // chips, bars and rows alike. A key this build doesn't recognise resolves to automatic
        // rather than crashing or pinning something arbitrary.
        if let stored = area.palette, let chosen = AreaPalette(key: stored) { return chosen }
        let key = area.colour.replacingOccurrences(of: "\u{FE0F}", with: "")
        if let mapped = emojiFamilies[key] { return mapped }
        let families = allCases
        return families[Int(area.id.uuid.0) % families.count]
    }
}

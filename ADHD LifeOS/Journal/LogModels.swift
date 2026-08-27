//
//  LogModels.swift
//  ADHD LifeOS
//

import Foundation

enum LogType: String, Codable, Equatable, Sendable, CaseIterable {
    case log
    case journal
}

/// How much petrol was in the tank when the entry was written — the web's `EnergyLevel`
/// (`'low' | 'medium' | 'high'`, `src/types.ts`).
///
/// The raw values go into Firestore, so they are a wire contract and must not be renamed for
/// display; the glyphs and titles below are what the UI shows.
enum EnergyLevel: String, Codable, Equatable, Sendable, CaseIterable {
    case low
    case medium
    case high

    /// Paired with `title` everywhere it is shown, never used alone — an ADHD readout must not
    /// depend on decoding an emoji, and §4 forbids meaning carried by colour or glyph alone.
    var glyph: String {
        switch self {
        case .low: return "🪫"
        case .medium: return "⚡"
        case .high: return "🔥"
        }
    }

    var title: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    /// The web's descriptive half of each option ("Low Energy / Fatigue" and friends).
    var detail: String {
        switch self {
        case .low: return "Fatigue"
        case .medium: return "Steady"
        case .high: return "Hyperfocus"
        }
    }

    /// The journal list's chip, mirroring the web's `{entry.energyLevel} energy`.
    var chipLabel: String { "\(rawValue) energy" }
}

/// The mood palette, ported verbatim from the web journal composer's `moodOptions`.
enum JournalMood {
    static let options = ["⚡", "🔥", "🧘", "🔋", "😴", "🧠", "🌊", "🎯"]
    /// What both web composers start on.
    static let defaultEmoji = "⚡"
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
    /// Journal entries only, and OPTIONAL on purpose.
    ///
    /// Every entry E wrote before this field existed is missing the key, and `Log` is decoded
    /// straight off the Firestore document — a non-optional would throw and take the whole journal
    /// list down. Optional also keeps the data honest: "not recorded" is a real state, distinct
    /// from a `medium` the user never chose. A quick `.log` never carries either field
    /// (`LogValidation` enforces that), because the web keeps them on `JournalEntry` alone.
    let energyLevel: EnergyLevel?
    let moodEmoji: String?
    /// Tag membership, written ONCE at create (E's 2026-08-25 note) — `firestore.rules` denies
    /// update on logs, so unlike tasks/captures there is no arrayUnion path: the document is born
    /// with its tags or never has them. `nil` on every entry written before the field existed.
    let tagIds: [UUID]?
    /// WHERE this entry was written (F-Location-Tagging, block 3 remainder). Resolved ONCE at
    /// create, the capture rule verbatim: a place's radius can be edited later, and re-resolving
    /// would silently rewrite where things happened. `placeId` is nil outside every named place —
    /// the coordinate is still kept. All three are nil on entries written before this shipped,
    /// and on any written with tagging or permission off.
    let placeId: UUID?
    let latitude: Double?
    let longitude: Double?

    init(
        id: UUID,
        lifeAreaId: UUID?,
        type: LogType,
        body: String,
        entryDate: Date,
        createdAt: Date,
        energyLevel: EnergyLevel? = nil,
        moodEmoji: String? = nil,
        tagIds: [UUID]? = nil,
        placeId: UUID? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = id
        self.lifeAreaId = lifeAreaId
        self.type = type
        self.body = body
        self.entryDate = entryDate
        self.createdAt = createdAt
        self.energyLevel = energyLevel
        self.moodEmoji = moodEmoji
        self.tagIds = tagIds
        self.placeId = placeId
        self.latitude = latitude
        self.longitude = longitude
    }

    enum CodingKeys: String, CodingKey {
        case id, type, body, latitude, longitude
        case lifeAreaId = "life_area_id"
        case entryDate = "entry_date"
        case createdAt = "created_at"
        case energyLevel = "energy_level"
        case moodEmoji = "mood_emoji"
        case tagIds = "tag_ids"
        case placeId = "place_id"
    }

    /// Hand-written for one reason: an `energy_level` this build doesn't recognise decodes to `nil`
    /// rather than throwing. A synthesized decoder would fail the whole document — and one entry
    /// written by a later build would empty the entire journal list. Everything else decodes
    /// exactly as the synthesis would.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            lifeAreaId: try container.decodeIfPresent(UUID.self, forKey: .lifeAreaId),
            type: try container.decode(LogType.self, forKey: .type),
            body: try container.decode(String.self, forKey: .body),
            entryDate: try container.decode(Date.self, forKey: .entryDate),
            createdAt: try container.decode(Date.self, forKey: .createdAt),
            energyLevel: (try? container.decodeIfPresent(EnergyLevel.self, forKey: .energyLevel)) ?? nil,
            moodEmoji: try container.decodeIfPresent(String.self, forKey: .moodEmoji),
            tagIds: try container.decodeIfPresent([UUID].self, forKey: .tagIds),
            placeId: try container.decodeIfPresent(UUID.self, forKey: .placeId),
            latitude: try container.decodeIfPresent(Double.self, forKey: .latitude),
            longitude: try container.decodeIfPresent(Double.self, forKey: .longitude)
        )
    }
}

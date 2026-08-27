//
//  AreaDetailPresentation.swift
//  ADHD LifeOS
//

import Foundation

/// The v3 area screen's content filter — entity kind, not task status: the whole point of the
/// area screen is that tasks, journal and captures share one home.
enum AreaDetailFilter: CaseIterable, Equatable {
    case tasks
    case journal
    case captures
    case all

    /// "Tasks 3" — the chip carries its count; "All" stands alone.
    func title(count: Int) -> String {
        switch self {
        case .tasks: return "Tasks \(count)"
        case .journal: return "Journal \(count)"
        case .captures: return "Captures \(count)"
        case .all: return "All"
        }
    }
}

enum AreaDetailPresentation {
    /// The momentum card's line under the ring. A `nil` rate is a dormant area — stated plainly,
    /// not rendered as 0%.
    static func ringLine(rate: Double?, areaName: String) -> String {
        guard let rate else { return "Nothing here has moved this week" }
        if rate >= 1 { return "All of this week's \(areaName) items closed" }
        return "\(Int((rate * 100).rounded()))% of this week's \(areaName) items closed"
    }

    /// The waiting captures genuinely filed to THIS area — what the screen's Captures section
    /// shows, and the count on its chip.
    ///
    /// It used to return a second list too: every capture with no area at all, offered a "File
    /// here" button. That predicate (`lifeAreaId == nil`) never mentions the area on screen, so
    /// one unfiled capture rendered on EVERY area's detail simultaneously — eight areas, eight
    /// copies, eight buttons, all writing the same document (the audit's A1). An area shows what
    /// lives here; what lives nowhere yet belongs to the inbox, where the triage card decides it
    /// under a rule this screen never enforced.
    static func capturesFiledHere(_ captures: [Capture], areaId: UUID) -> [Capture] {
        captures.filter { $0.lifeAreaId == areaId }
    }
}

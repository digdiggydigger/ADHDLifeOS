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

    /// Waiting captures, split for the two sections: already filed here (awaiting triage) and
    /// area-less ones the screen offers a real "File here" (writes `life_area_id` via the
    /// existing `updateCapture` seam — no new backend surface).
    static func splitCaptures(
        _ captures: [Capture], areaId: UUID
    ) -> (filedHere: [Capture], unfiled: [Capture]) {
        (
            filedHere: captures.filter { $0.lifeAreaId == areaId },
            unfiled: captures.filter { $0.lifeAreaId == nil }
        )
    }
}

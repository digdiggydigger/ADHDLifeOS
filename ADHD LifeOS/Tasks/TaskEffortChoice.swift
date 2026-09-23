//
//  TaskEffortChoice.swift
//  ADHD LifeOS
//
//  The task composer's Time menu (`F-D1-ComposerBothDoors`) — pure, so the values are tested
//  apart from the view. Written to the task as `focusDurationSeconds`, the field the Momentum
//  board ranks quick wins by and the sprint planner seeds its length from.
//
//  **Ported, not designed.** These are the three effort chips the capture disc's Task tile
//  offered (`QuickCaptureComponents.effortSection`, deleted by this block), with their spelling —
//  "1 hr" rather than `MomentumScoreboard.effortLabel`'s "60 min", because this is the word E saw
//  on the chip and on every composer board since.
//

import Foundation

enum TaskEffortChoice: Equatable, CaseIterable {
    case fifteen
    case thirty
    case hour

    /// What the menu reads when nobody touches it — "15 min" on every board E approved (rounds 6,
    /// 6b, 7b), and the 900 seconds the fan's Task tile already wrote on every create.
    static let standard: TaskEffortChoice = .fifteen

    var title: String {
        switch self {
        case .fifteen: return "15 min"
        case .thirty: return "30 min"
        case .hour: return "1 hr"
        }
    }

    var seconds: Int {
        switch self {
        case .fifteen: return 900
        case .thirty: return 1800
        case .hour: return 3600
        }
    }
}

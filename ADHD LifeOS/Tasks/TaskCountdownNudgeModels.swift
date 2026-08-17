//
//  TaskCountdownNudgeModels.swift
//  ADHD LifeOS
//

import Foundation

/// Which countdown-nudge menu applies to a task, per the 6-hour cutover rule.
enum NudgeCountdownMode: Equatable, Sendable {
    case evenDivision
    case checkpoint
}

/// Fixed checkpoint offsets before a task's due time, used in the >6-hour adaptive mode. Order
/// matches declaration order (farthest to nearest), which `CaseIterable` preserves.
enum NudgeCheckpoint: CaseIterable, Equatable, Hashable, Sendable {
    case oneWeekBefore
    case threeDaysBefore
    case oneDayBefore
    case threeHoursBefore
    case oneHourBefore

    var offset: TimeInterval {
        switch self {
        case .oneWeekBefore: return 7 * 24 * 3600
        case .threeDaysBefore: return 3 * 24 * 3600
        case .oneDayBefore: return 24 * 3600
        case .threeHoursBefore: return 3 * 3600
        case .oneHourBefore: return 3600
        }
    }

    var label: String {
        switch self {
        case .oneWeekBefore: return "1 week before"
        case .threeDaysBefore: return "3 days before"
        case .oneDayBefore: return "1 day before"
        case .threeHoursBefore: return "3 hours before"
        case .oneHourBefore: return "1 hour before"
        }
    }
}

/// One even-division menu option (1, 2, or 3 nudges), pre-labeled with its actual interval so the
/// UI can show e.g. "2 nudges (every 14 min)" without recomputing formatting itself.
struct EvenDivisionMenuOption: Equatable, Sendable, Identifiable {
    let count: Int
    let intervalDescription: String
    let fireDates: [Date]

    var id: Int { count }
}

/// What the user has chosen for a task's countdown nudges. `.none` means the toggle is off /
/// nothing is scheduled for this task.
enum NudgeCountdownSelection: Equatable, Sendable {
    case none
    case evenDivision(count: Int)
    case checkpoints(Set<NudgeCheckpoint>)
}

/// A single resolved local-notification fire time, ready to hand to the scheduling adapter —
/// the pure math layer's output, independent of `UNUserNotificationCenter`.
struct ScheduledCountdownNudge: Equatable, Sendable {
    let date: Date
    let body: String
}

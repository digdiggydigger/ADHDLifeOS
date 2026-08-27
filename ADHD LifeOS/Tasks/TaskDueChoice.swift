//
//  TaskDueChoice.swift
//  ADHD LifeOS
//

import Foundation

/// The S1-style task composer's "When is it due?" chips — the pure mapping between a chip and
/// `TaskCreateService.dueDate`, so the view holds no date arithmetic.
///
/// "Today" means START of day, the convention the capture fan's fast-task path established
/// (`QuickCaptureView.saveTask`): the due DAY is the honest fact a chip can state; a precise
/// moment is what `custom`'s picker is for.
enum TaskDueChoice: Equatable, CaseIterable {
    case notYet
    case today
    case tomorrow
    case custom

    var title: String {
        switch self {
        case .notYet: return "Not yet"
        case .today: return "Today"
        case .tomorrow: return "Tomorrow"
        case .custom: return "Pick a date"
        }
    }

    /// The due date this chip stands for. `custom` keeps whatever is already chosen — switching
    /// to the picker must never clobber a date — and seeds `now` when there is nothing yet,
    /// because a `DatePicker` needs a concrete starting value.
    func resolvedDueDate(existing: Date?, asOf now: Date, calendar: Calendar = .current) -> Date? {
        switch self {
        case .notYet:
            return nil
        case .today:
            return calendar.startOfDay(for: now)
        case .tomorrow:
            let today = calendar.startOfDay(for: now)
            return calendar.date(byAdding: .day, value: 1, to: today) ?? today
        case .custom:
            return existing ?? now
        }
    }

    /// Which chip a stored due date reads back as. Anything that is not exactly a chip's own
    /// value — including a hand-picked time later today — is a deliberate pick and stays `custom`.
    static func choice(for dueDate: Date?, asOf now: Date, calendar: Calendar = .current) -> TaskDueChoice {
        guard let dueDate else { return .notYet }
        let today = calendar.startOfDay(for: now)
        if dueDate == today { return .today }
        if dueDate == calendar.date(byAdding: .day, value: 1, to: today) { return .tomorrow }
        return .custom
    }
}

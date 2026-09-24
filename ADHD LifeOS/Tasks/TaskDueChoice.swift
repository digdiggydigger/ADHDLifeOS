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
///
/// *Annotated by `F-D2-ComposerKeyboardLayout`:* the last clause is no longer true of the
/// composer. E's Step 0 answer (2026-09-24, "date only") made its picker offer a DAY, stored as
/// that day's start like the other three (`pickedDueDate`). A precise moment is set on the task's
/// detail screen (`TaskDetailFormSections`), whose picker still offers the time.
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
        // Round 7b, E: "Text, then the date. It reads 'Date' in LabelPrimary like its neighbours,
        // with no calendar glyph." It was "Pick a date" until F-D2.
        case .custom: return "Date"
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

    /// What a segment reads. Round 7b, E: the Date segment reads "Date", and *"once a date is
    /// picked, Date becomes the selected segment and shows that date ('Fri 26')."*
    ///
    /// Keyed on the SELECTION, not on the date: Today and Tomorrow hold a due date too, and the
    /// Date segment must never name a day another segment is already lit for.
    func segmentTitle(
        selected: TaskDueChoice, dueDate: Date?, asOf now: Date,
        calendar: Calendar = .current, locale: Locale = .current
    ) -> String {
        guard self == .custom, selected == .custom, let dueDate else { return title }
        let style = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
        let days = calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: dueDate)
        ).day ?? 0
        // "Fri 26" names ONE day only while the day of the month cannot come round again: inside
        // four weeks of today. Past that, or for a day already gone, the month says which.
        if (0..<Self.weekdayLabelDays).contains(days) {
            return dueDate.formatted(style.weekday(.abbreviated).day())
        }
        return dueDate.formatted(style.day().month(.abbreviated))
    }

    /// Four weeks: the longest run of days in which no day of the month repeats.
    static let weekdayLabelDays = 28

    /// E's Step 0 answer (2026-09-24, "date only"): the composer's picker offers a DAY, so a pick is
    /// stored as that day's start, which is what Today and Tomorrow already write. `choice(for:)`
    /// then reads a picked today back as `.today`: one date, one segment.
    static func pickedDueDate(_ picked: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: picked)
    }
}

//
//  HomeNudgesSection.swift
//  ADHD LifeOS
//

import Foundation

/// Today's nudges module, the pure half — sibling of `HomeInboxPeek` beside it.
///
/// Nudges lost their tab when Captures took the slot back (E's call, 2026-08-28), so Today is
/// where a due nudge is now met and dismissed. That is a deliberate reversal of F-V3-Today, which
/// had replaced Today's inline dismiss strip with a "Nudges waiting" row that only crossed to the
/// tab: with no tab to cross to, a teaser row would leave Today announcing work it could not let
/// you do.
///
/// This decides WHICH nudges appear inline and what the lines say; the section lays them out, and
/// everything the module cannot hold — creating, editing, rescheduling, the completion history —
/// stays on the pushed `NudgesView`.
enum HomeNudgesSection {
    /// Today is the app's densest screen, so the inline cards are capped and the rest are named
    /// rather than rendered — the `HomeInboxPeek.maxRows` bargain, for the same reason.
    static let maxCards = 3

    /// The due nudges that get a card, oldest-due first so the one that has waited longest is the
    /// one you meet. Explicitly re-sorted rather than trusting the caller's ordering.
    static func cards(_ due: [Nudge]) -> [Nudge] {
        Array(due.sorted { lastFired($0) < lastFired($1) }.prefix(maxCards))
    }

    /// Names only what the cards cannot show; `nil` when they already show everything.
    static func overflowLine(dueCount: Int) -> String? {
        let hidden = dueCount - maxCards
        guard hidden > 0 else { return nil }
        return hidden == 1 ? "and 1 more due" : "and \(hidden) more due"
    }

    /// The section's eyebrow. Zero due is not a deficit — it is the state a nudge schedule is
    /// FOR — so it reads as settled rather than as a count of nothing.
    static func countLine(dueCount: Int, scheduledCount: Int) -> String {
        guard dueCount > 0 else {
            return scheduledCount > 0 ? "Nothing due · \(scheduledCount) scheduled" : "No nudges yet"
        }
        return "\(dueCount) due · \(max(scheduledCount, 0)) scheduled"
    }

    /// How many active nudges are NOT due — the "scheduled" half of the eyebrow. Inactive nudges
    /// are excluded: a paused nudge is not waiting for you.
    static func scheduledCount(all: [Nudge], due: [Nudge]) -> Int {
        let dueIds = Set(due.map(\.id))
        return all.filter { $0.active && !dueIds.contains($0.id) }.count
    }

    /// A nudge's reference moment — the same one `NudgeDueness` measures dueness from, so
    /// "waited longest" here means what it means there.
    private static func lastFired(_ nudge: Nudge) -> Date {
        nudge.lastFiredAt ?? nudge.createdAt
    }

    // MARK: - The door (E's screenshot note, 2026-08-28)

    /// The card's second line, under "Nudges".
    ///
    /// Nothing due is the state a schedule exists to produce, so it is said as settled rather than
    /// as a count of nothing — the rule "Inbox clear" and the collapsed life-areas line already
    /// follow. The empty case describes what nudges ARE, because someone with none has no idea.
    static func doorSubtitle(dueCount: Int, scheduledCount: Int) -> String {
        if dueCount > 0 {
            return "Waiting on you — clear them when you can."
        }
        return scheduledCount > 0
            ? "Nothing due — all on time."
            : "Recurring reminders you set for yourself."
    }

    /// The chip beside the title, counting whichever number actually matters in this state: what
    /// is waiting on you if anything is, otherwise how many are simply on the books.
    static func chipText(dueCount: Int, scheduledCount: Int) -> String {
        if dueCount > 0 { return "\(dueCount) due" }
        return scheduledCount > 0 ? "\(scheduledCount) scheduled" : "None yet"
    }

    /// "Today 18:00" / "Tomorrow 05:00" / "Mon 09:30" — when this nudge next fires, measured from
    /// `now` rather than from the nudge's own reference date (see `NudgeDueness.nextFire`).
    ///
    /// Beyond tomorrow the weekday is NAMED rather than counted: "in 4 days" makes the reader do
    /// arithmetic to answer a question they asked to avoid doing arithmetic. `nil` for a schedule
    /// the app cannot parse — the same refusal to invent that `NudgeSchedule.summary` makes.
    static func nextFireLine(
        for nudge: Nudge, now: Date, timeZone: TimeZone = .current, locale: Locale = .current
    ) -> String? {
        guard let next = NudgeDueness.nextFire(for: nudge, after: now, timeZone: timeZone) else {
            return nil
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.locale = locale

        let time = DateFormatter()
        time.locale = locale
        time.timeZone = timeZone
        time.dateStyle = .none
        time.timeStyle = .short
        let clock = time.string(from: next)

        // Deliberately NOT `isDateInToday`, which asks the system clock. "Today" here means the
        // day of `now`, and `now` is a parameter precisely so this is testable at a fixed moment.
        let days = calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: next)
        ).day ?? 0
        switch days {
        case 0: return "Today \(clock)"
        case 1: return "Tomorrow \(clock)"
        default:
            let weekday = calendar.component(.weekday, from: next) - 1
            let symbols = calendar.shortWeekdaySymbols
            guard symbols.indices.contains(weekday) else { return clock }
            return "\(symbols[weekday]) \(clock)"
        }
    }

    /// The not-yet-due nudges that get a row, soonest first — the one about to happen is the one
    /// worth reading, not the one added first.
    ///
    /// Excludes anything already due (it has its own card above, and the same nudge twice on one
    /// screen is worse than saying less), anything paused, and anything whose schedule will not
    /// parse — an unschedulable nudge has no position in a soonest-first list to claim.
    static func upcoming(
        all: [Nudge], due: [Nudge], now: Date, timeZone: TimeZone = .current
    ) -> [Nudge] {
        let dueIds = Set(due.map(\.id))
        let dated: [(nudge: Nudge, fires: Date)] = all.compactMap { nudge in
            guard !dueIds.contains(nudge.id),
                  let fires = NudgeDueness.nextFire(for: nudge, after: now, timeZone: timeZone)
            else { return nil }
            return (nudge, fires)
        }
        return Array(dated.sorted { $0.fires < $1.fires }.prefix(maxCards).map(\.nudge))
    }

    /// Names only what the rows could not fit. `nil` when they showed everything.
    static func upcomingOverflowLine(scheduledCount: Int) -> String? {
        let hidden = scheduledCount - maxCards
        guard hidden > 0 else { return nil }
        return hidden == 1 ? "and 1 more scheduled" : "and \(hidden) more scheduled"
    }
}

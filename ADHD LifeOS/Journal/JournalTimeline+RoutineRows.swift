//
//  JournalTimeline+RoutineRows.swift
//  ADHD LifeOS
//
//  The routine record on the Journal (F-RoutineRecord-2-Surfaces): which rows one
//  `routine_runs` document becomes, and every word on them. E's calls: TWO rows per run —
//  started and finished, each at its own stamp; the OFFER rows muted; an unfinished run read
//  gently ("· 2 of 4 done", never "abandoned" — count up only); "cleared" for a swipe, "not
//  opened" for the rest.
//
//  E's device-walk call (2026-09-06, on real data): the "All activity" switch gates EVERY
//  routine row, not only the offers. Off — every launch — the Journal shows the crossing alone;
//  on, the whole routine story. The design's "started and finished always visible" is
//  superseded by that call.
//
//  Names resolve through the CURRENT place like `locationEventLine`, so a rename updates every
//  row and a deleted place drops it — the reason the id is stored rather than the name.
//

import Foundation

extension JournalTimeline {
    enum RoutineRowKind: String {
        case offered
        case started
        case ended
    }

    /// The rows for these runs. Ambient garnish for the Everything view, like location rows —
    /// the caller applies that gate. A run that reached `ended` without a `started_at` (a
    /// document from the future, or a hand edit) shows its ending alone rather than inventing
    /// a start.
    static func routineEntries(
        runs: [RoutineRunRecord], places: [Place], showAllActivity: Bool
    ) -> [Entry] {
        guard showAllActivity else { return [] }
        return runs.flatMap { record -> [Entry] in
            guard places.contains(where: { $0.id == record.placeId }) else { return [] }
            switch record.phase {
            case .started:
                return [.routineStarted(record)]
            case .ended:
                return record.startedAt == nil
                    ? [.routineEnded(record)]
                    : [.routineStarted(record), .routineEnded(record)]
            case .offered, .dismissed, .expired:
                return [.routineOffered(record)]
            }
        }
    }

    /// The row's words. `nil` for a dangling place; `routineEntries` has already dropped those,
    /// but the row guards anyway.
    static func routineLine(
        _ kind: RoutineRowKind, for record: RoutineRunRecord, places: [Place]
    ) -> String? {
        guard let place = places.first(where: { $0.id == record.placeId }) else { return nil }
        let name = place.emoji.map { "\(place.name) \($0)" } ?? place.name
        let progress = "\(record.completedStepsCount) of \(record.totalStepsCount) done"
        switch kind {
        case .started:
            return "Started routine at \(name)"
        case .ended:
            // Recorded fully, read gently: the row says what happened, never why it stopped.
            return record.endReason == .completed
                ? "Finished routine at \(name) · \(progress)"
                : "Routine at \(name) · \(progress)"
        case .offered:
            let outcome = record.dismissalMethod == .swipe ? "cleared" : "not opened"
            return "Routine offered at \(name) · \(outcome)"
        }
    }
}

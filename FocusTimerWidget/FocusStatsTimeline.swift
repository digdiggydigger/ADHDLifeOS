//
//  FocusStatsTimeline.swift
//  FocusTimerWidget
//
//  When the Home Screen widget is redrawn, and with what. Split out of `FocusStatsWidget` when the
//  sprint entries pushed that file over its 400-line budget — and it reads better here anyway: the
//  timeline is about TIME, and everything beside it in that file is about layout.
//

import WidgetKit

struct FocusStatsEntry: TimelineEntry {
    let date: Date
    /// `nil` means "the app has never published" — a fresh install, or an App Group the widget
    /// can't reach. Distinct from a real week of zeros, which is a decoded snapshot.
    let snapshot: FocusWidgetSnapshot?
}

struct FocusStatsProvider: TimelineProvider {
    private let store = FocusWidgetSnapshotStore()

    func placeholder(in context: Context) -> FocusStatsEntry {
        FocusStatsEntry(date: Date(), snapshot: FocusWidgetSnapshot.placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (FocusStatsEntry) -> Void) {
        completion(FocusStatsEntry(date: Date(), snapshot: store.read()))
    }

    /// One entry now, one at each of a running sprint's remaining checkpoints, one at its deadline,
    /// refreshed at midnight.
    ///
    /// Nothing else here changes minute to minute — the app reloads this timeline the moment its own
    /// numbers move (`AppGroupFocusWidgetPublisher`), so the only *time*-driven changes are the week
    /// rolling over and the sprint progressing. The sprint entries are what make the live section
    /// self-sufficient: the app publishes once and is then suspended, with no way to update a widget
    /// on a schedule, so a section that had to be TOLD its checkpoint count would freeze at whatever
    /// it was when the app last drew breath (observed in-simulator, 2026-08-20: "2 of 11" while
    /// checkpoint 4 had already fired). Each entry re-renders the count against its own date, and
    /// the final one retires the section when the sprint runs out.
    ///
    /// Extra entries in a timeline the OS already holds are free — WidgetKit's refresh budget counts
    /// reloads, not entries — and `refreshDates` bounds them for a very fine nudge cadence.
    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusStatsEntry>) -> Void) {
        let now = Date()
        let snapshot = store.read()
        let sprintDates = snapshot?.activeSprint?.refreshDates(after: now) ?? []
        let entries = ([now] + sprintDates).map { FocusStatsEntry(date: $0, snapshot: snapshot) }
        let nextMidnight = Calendar.current.startOfDay(for: now.addingTimeInterval(24 * 60 * 60))
        completion(Timeline(entries: entries, policy: .after(nextMidnight)))
    }
}

//
//  DailySummaryStore.swift
//  ADHD LifeOS
//

import Foundation

/// What the Daily Executive Summary card remembers between appearances.
///
/// A generated summary is a **record of the day**, not view state — so it belongs in storage rather
/// than in a `@StateObject` that lives and dies with the view hierarchy. Home's `.task` re-runs
/// `HomeService.load()` on every tab switch, which flips its load state back through `.loading` and
/// destroys the whole loaded subtree; anything held only in the card's own state goes with it.
///
/// Two guards decide whether the record may be read back, and they are the whole point of the type:
/// it must belong to the signed-in account, and it must be a record of the day being shown.
struct DailySummarySnapshot: Codable, Equatable, Sendable {
    /// Bump whenever the shape changes. Same rule as `FocusWidgetSnapshot`: a payload stamped with
    /// a version this build doesn't know is discarded rather than half-decoded.
    static let currentVersion = 1

    let version: Int
    /// The Firebase uid this belongs to. The summary quotes task titles and journal reflections, so
    /// it is only ever handed back to the account that generated it.
    let userId: String?
    /// The selected voice. A preference rather than a record, so it is not date-scoped.
    let tone: DailySummaryTone
    /// The last summary that generated successfully; `nil` before the user has generated anything.
    let summary: GeneratedDailySummary?

    init(userId: String?, tone: DailySummaryTone, summary: GeneratedDailySummary?) {
        self.version = Self.currentVersion
        self.userId = userId
        self.tone = tone
        self.summary = summary
    }

    /// Whether this snapshot may be read back for `userId`.
    ///
    /// An unattributed snapshot is unclaimable rather than universally claimable — "nobody wrote
    /// this" must not read as "anybody may have it".
    func belongs(to userId: String?) -> Bool {
        guard let owner = self.userId, let userId else { return false }
        return owner == userId
    }

    /// The stored summary, but only when it is a record of `date`'s day.
    ///
    /// A summary from ten minutes ago is still true and comes back. Yesterday's is still a true
    /// record *of yesterday*, and presenting it as today's would be a lie — so it is dropped and the
    /// card falls back to its idle on-device synthesis.
    func summary(on date: Date, calendar: Calendar = .current) -> GeneratedDailySummary? {
        guard let summary, calendar.isDate(summary.generatedAt, inSameDayAs: date) else { return nil }
        return summary
    }
}

/// The persistence seam, so the service can be built without one (previews, tests) and never
/// reaches real defaults by accident.
///
/// Not `Sendable`, unlike the provider and generator seams beside it: those are awaited across a
/// suspension, this is read and written synchronously on the main actor by `DailySummaryService`
/// and never crosses an isolation boundary. Requiring it would only force an `@unchecked` escape
/// hatch around `UserDefaults`.
protocol DailySummaryStoring {
    func read() -> DailySummarySnapshot?
    func write(_ snapshot: DailySummarySnapshot)
}

/// The shipping store. App-local `UserDefaults` rather than the App Group suite: unlike the focus
/// snapshot this crosses no process boundary — the widget has no business reading the user's
/// journal reflections.
///
/// Every failure path degrades to "remembers nothing" instead of trapping, mirroring
/// `FocusWidgetSnapshotStore`: unavailable defaults, corrupt data, and an unknown version all leave
/// the card working and merely forgetful.
struct UserDefaultsDailySummaryStore: DailySummaryStoring {
    static let snapshotKey = "home.dailySummary.snapshot"

    private let defaults: UserDefaults?

    init(defaults: UserDefaults? = .standard) {
        self.defaults = defaults
    }

    func read() -> DailySummarySnapshot? {
        guard
            let data = defaults?.data(forKey: Self.snapshotKey),
            let snapshot = try? JSONDecoder().decode(DailySummarySnapshot.self, from: data),
            snapshot.version == DailySummarySnapshot.currentVersion
        else { return nil }
        return snapshot
    }

    func write(_ snapshot: DailySummarySnapshot) {
        guard let defaults, let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: Self.snapshotKey)
    }
}

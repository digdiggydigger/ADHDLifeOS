//
//  RecentlyDeletedPresentation.swift
//  ADHD LifeOS
//
//  `F-C3-RecentlyDeleted`: the screen's words and its countdown, as pure values.
//
//  Kept out of the view body for the reason every presentation type here is: view bodies are ~0%
//  covered by design, so a rule left inside one is a rule nothing checks. `ToolsRoutinesCatalog`
//  is the shape this follows — including its rule that a knob is INTERPOLATED and never spelled,
//  because copy reading "30 days" beside a `retention` of 14 is a lie no compiler catches.
//

import Foundation

enum RecentlyDeletedPresentation {

    // MARK: - The window

    /// E's *"Kept 30 days"*, read from the constant the purge reads rather than restated.
    static var retentionDays: Int { Int(SoftDelete.retention / (24 * 60 * 60)) }

    /// How much longer this item has.
    ///
    /// **Rounds UP, and the direction is a decision.** Rounding down would tell someone with
    /// eleven hours left that they have none. Rounding up can only ever over-state by less than a
    /// day, and `RecentlyDeletedPresentationTests` sweeps the whole window asserting the one
    /// invariant that matters: **a positive number here means the purge would not take it.** Time
    /// shown is time the user actually has.
    ///
    /// Zero means the last day *or* overdue — `isPurgeable` uses `>`, so an item at exactly the
    /// boundary is still here. `remainingPhrase` says "Last day" rather than a bare 0, which is
    /// true of both.
    static func daysRemaining(deletedAt: Date, now: Date) -> Int {
        let remaining = SoftDelete.retention - now.timeIntervalSince(deletedAt)
        return max(0, Int(ceil(remaining / (24 * 60 * 60))))
    }

    static func remainingPhrase(daysRemaining: Int) -> String {
        switch daysRemaining {
        case 0: return "Last day"
        case 1: return "1 day left"
        default: return "\(daysRemaining) days left"
        }
    }

    // MARK: - The words

    static let screenTitle = "Recently Deleted"
    static let sectionTitle = "Recently Deleted"
    static let restoreTitle = "Restore"
    static let deleteForeverTitle = "Delete Forever"

    static var sectionCaption: String {
        "Tasks, captures and tags you delete wait \(retentionDays) days before they're gone"
            + " for good."
    }

    static let emptyHeadline = "Nothing deleted"

    static var emptyBody: String {
        "Anything you delete waits here for \(retentionDays) days, so a slip is never the end of"
            + " it. Nothing is waiting right now."
    }

    // **Two strings lived here and are GONE, which is worth a note rather than a silence.**
    // `softDeleteReassurance` ("You can restore it from Recently Deleted for 30 days.") and
    // `captureDiscardMessage` were written to replace the false *"This can't be undone."* in the
    // two delete confirmations. E then dropped both confirmations outright (2026-09-22, after the
    // `apple-design` review), which left the replacements with no call site — the dead-shared-
    // component pattern this repo has shipped seven times, caught here by a grep rather than by a
    // test, because a string nothing reads breaks nothing.
    //
    // **The 30-day rule is still taught**, by `sectionCaption` on the Tools row and by
    // `emptyBody` on the screen. What is lost is teaching it at the MOMENT of the delete, and
    // that is the cost E accepted: the capsule's "Deleted · Undo" is the feedback now, and the
    // Tools row is where the window is explained.

    /// Q10's sanctioned friction: *"friction is allowed executing permanent deletions"*. This is
    /// the one place in the app where "This can't be undone" is TRUE.
    enum DeleteForever {
        static func title(for kind: RecentlyDeletedItem.Kind) -> String {
            switch kind {
            case .task: return "Delete this task forever?"
            case .capture: return "Delete this capture forever?"
            case .tag: return "Delete this tag forever?"
            }
        }

        static let message = "This can't be undone."
        static let confirmTitle = RecentlyDeletedPresentation.deleteForeverTitle
        static let cancelTitle = "Keep it"
    }

    // MARK: - One row per deleted thing

    struct Row: Identifiable, Equatable {
        let item: RecentlyDeletedItem
        let glyph: String
        let title: String
        let subtitle: String

        var id: String { item.id }

        /// Per-ROW and never on a container: an identifier on a container is inherited by its
        /// children and would rename this row's Restore button out from under itself — the trap
        /// `ToolsRoutinesCatalog` records and `ToolsRoutinesSection` works around.
        var accessibilityIdentifier: String { "recentlyDeletedRow-\(item.id)" }
    }

    enum Content: Equatable {
        case rows([Row])
        case empty
    }

    /// **Sorted by when it was DELETED, newest first.** `fetchDeletedTasks()` orders by
    /// `created_at` because that is the index the collection already carries; the order a person
    /// expects here is the order they did the deleting, and the thing about to expire has to be
    /// findable without reading every row.
    static func content(from items: [RecentlyDeletedItem], now: Date = .now) -> Content {
        guard !items.isEmpty else { return .empty }
        return .rows(items.sorted { $0.deletedAt > $1.deletedAt }.map { row(for: $0, now: now) })
    }

    private static func row(for item: RecentlyDeletedItem, now: Date) -> Row {
        Row(
            item: item,
            glyph: glyph(for: item.kind),
            title: item.title,
            subtitle: "\(word(for: item.kind)) · "
                + remainingPhrase(daysRemaining: daysRemaining(deletedAt: item.deletedAt, now: now))
        )
    }

    /// The glyph each kind's own TAB wears (`AppTabBarPresentation`), so a row here is recognised
    /// as the thing it came from rather than learned as a new symbol.
    static func glyph(for kind: RecentlyDeletedItem.Kind) -> String {
        switch kind {
        case .task: return "checklist"
        case .capture: return "tray.full"
        // Tags have no tab of their own, so the rule above cannot apply. This is the glyph the
        // Tag Editor's own row in Settings wears, and the one every tag chip in the app carries.
        case .tag: return "tag"
        }
    }

    /// Singular and capitalised — it opens the row's second line, not a sentence.
    static func word(for kind: RecentlyDeletedItem.Kind) -> String {
        switch kind {
        case .task: return "Task"
        case .capture: return "Capture"
        case .tag: return "Tag"
        }
    }

    // MARK: - The one row on Tools

    /// E's round 2: *"Where Recently Deleted lives → 'One row in Tools'"*. One line, so it carries
    /// the one number that changes what the user would do — how long the SOONEST departure has,
    /// not the newest, because the newest is the one that needs no attention.
    /// What the row says before the count is known, and after a failed read. **Never "Nothing
    /// waiting"** — claiming the list is empty because the fetch failed is the same lie the screen
    /// itself refuses to tell, told one level up with less room to explain it.
    static let toolsRowLoadingSubtitle = "Restore something you deleted by mistake"

    static func toolsRowSubtitle(for items: [RecentlyDeletedItem], now: Date = .now) -> String {
        guard let soonest = items.map({ daysRemaining(deletedAt: $0.deletedAt, now: now) }).min() else {
            return "Nothing waiting"
        }
        let count = items.count == 1 ? "1 item" : "\(items.count) items"
        return "\(count) · \(remainingPhrase(daysRemaining: soonest))"
    }
}

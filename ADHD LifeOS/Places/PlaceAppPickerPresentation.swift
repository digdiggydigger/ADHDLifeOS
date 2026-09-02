//
//  PlaceAppPickerPresentation.swift
//  ADHD LifeOS
//
//  Pure presentation rules behind the app-directory design pass (E's 2026-09-02 device
//  verdict on the field-gate screenshots: the picker and the action editor were "ugly and
//  plain"). Kept out of the views so each rule is pinned by a test.
//

import Foundation

enum PlaceAppPickerPresentation {
    /// The initial the avatar disc shows. The directory has no app icons to draw on — iOS
    /// offers no public way to fetch another app's icon — so a monogram is the honest identity
    /// mark available.
    static func monogram(for name: String) -> String {
        guard let first = name.trimmingCharacters(in: .whitespaces).first else { return "" }
        return String(first).uppercased()
    }

    /// The ranked head, shown as "Popular" above the category map — the directory's own sense
    /// of what most people mean, so the common pick never needs a category tapped at all.
    ///
    /// Replaced the old `browseSplit`: its alphabetical 144-row tail is exactly what the
    /// collapsed shape does away with, and leaving the function half-used would have been the
    /// dead-code pattern this repo keeps re-learning.
    static func popular(
        _ ranked: [PlaceAppDirectoryEntry], count: Int = 8
    ) -> [PlaceAppDirectoryEntry] {
        Array(ranked.prefix(count))
    }

    /// The category map: one section per non-empty category, in declaration order, each
    /// holding its apps A–Z.
    ///
    /// Deliberately **complete rather than a partition** — an app in the popular head still
    /// appears under its own category, because a category that quietly omits the most obvious
    /// app in it reads as broken. Hidden entries never surface, and a category left empty by
    /// that filtering is dropped rather than shown as a row leading nowhere.
    static func categoryBrowse(
        _ entries: [PlaceAppDirectoryEntry]
    ) -> [PlaceAppCategoryBrowseSection] {
        let visible = entries.filter { !$0.hidden }
        return PlaceAppCategory.allCases.compactMap { category in
            let members = visible
                .filter { $0.category == category }
                .sorted { $0.name.localizedLowercase < $1.name.localizedLowercase }
            guard !members.isEmpty else { return nil }
            return PlaceAppCategoryBrowseSection(category: category, entries: members)
        }
    }

    /// Row metrics for the directory list. E's 2026-09-02 device verdict: only **10 of a
    /// category's 22 apps** fitted on screen, so the disc drops 36 → 28 and the row owns a
    /// tight 8pt vertical padding instead of a list's generous default.
    ///
    /// `minimumHeight` holds §3's 44pt touch target regardless — the PADDING got tighter, the
    /// TARGET did not, and a test pins that the disc plus its padding still fits inside the
    /// floor so the floor keeps governing.
    enum RowMetrics {
        static let discSize: CGFloat = 28
        static let verticalPadding: CGFloat = 8
        static let minimumHeight: CGFloat = 44
    }

    /// Whether a row shows its trailing "more ways in" control. E's 2026-09-02 call: the row
    /// TAP now always picks the app — every row behaves alike — so deep destinations get their
    /// own hit area instead of hijacking the whole row and charging an extra tap for the
    /// ordinary thing.
    static func showsDestinationControl(for entry: PlaceAppDirectoryEntry) -> Bool {
        !entry.destinations.isEmpty
    }

    /// **The directory tick is OFF — E's call, 2026-09-02:** "do not display the tick icon …
    /// this means we don't have to deal with this at the minute". The mark is positive-only,
    /// so an unswept scheme can only ever fail as a FALSE negative — a silent row for an app
    /// E does have — which made the 45-scheme device sweep a blocker on the merge. Silence
    /// costs nothing and blocks nothing.
    ///
    /// Nothing underneath was removed: `PlaceQueryableSchemes`, the three-state verdict,
    /// `PlaceAppInstallCopy` and the Info.plist parity tripwire are intact and still tested,
    /// and the action editor's own verdict line stays visible by E's explicit instruction.
    /// Flip this to `true` on E's word and the tick returns — no other change.
    static let showsInstalledBadge = false

    /// Whether one directory row draws its installed tick. The verdict is an `@autoclosure`
    /// so a switched-off badge costs ZERO `canOpenURL` calls rather than 45 discarded ones
    /// per sheet open — the off state is inert, not merely invisible. Positive-only survives
    /// the switch: even re-enabled, only `.looksInstalled` ever marks a row.
    static func showsInstalledCheck(
        enabled: Bool = showsInstalledBadge,
        verdict: @autoclosure () -> PlaceAppInstallVerdict
    ) -> Bool {
        enabled && verdict() == .looksInstalled
    }

    /// The SF Symbol each action kind wears in the editor's Action picker.
    static func kindGlyph(for choice: PlaceActionDraft.KindChoice) -> String {
        switch choice {
        case .openApp: return "arrow.up.forward.app"
        case .openURL: return "safari"
        case .textContact: return "message"
        case .startSprint: return "timer"
        case .createCapture: return "tray.and.arrow.down"
        case .journalLine: return "square.and.pencil"
        case .openScreen: return "rectangle.on.rectangle"
        }
    }
}

/// One row of the picker's category map: the group, and the apps that browse under it.
struct PlaceAppCategoryBrowseSection: Identifiable, Equatable {
    let category: PlaceAppCategory
    let entries: [PlaceAppDirectoryEntry]

    var id: PlaceAppCategory { category }
    var count: Int { entries.count }
}

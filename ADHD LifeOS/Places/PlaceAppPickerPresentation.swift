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

    /// The browse split: the ranked head reads as "Popular" (rank order, the directory's own
    /// sense of what most people mean), and the long tail reads alphabetically — past the head,
    /// rank stops meaning anything and A–Z is the only order a scanning eye can use.
    static func browseSplit(
        _ ranked: [PlaceAppDirectoryEntry], popularCount: Int = 8
    ) -> (popular: [PlaceAppDirectoryEntry], rest: [PlaceAppDirectoryEntry]) {
        let popular = Array(ranked.prefix(popularCount))
        let rest = ranked.dropFirst(popularCount)
            .sorted { $0.name.localizedLowercase < $1.name.localizedLowercase }
        return (popular, rest)
    }

    /// **The directory tick is OFF — E's call, 2026-09-02:** "do not display the tick icon …
    /// this means we don't have to deal with this at the minute". The mark is positive-only,
    /// so an unswept scheme can only ever fail as a FALSE negative — a silent row for an app
    /// E does have — which made the 45-scheme device sweep a blocker on the merge. Silence
    /// costs nothing and blocks nothing.
    ///
    /// Nothing underneath was removed: `PlaceQueryableSchemes`, the three-state verdict,
    /// `PlaceAppInstallCopy` and the Info.plist parity tripwire are intact and still tested,
    /// and the action editor's own verdict line is untouched. Flip this to `true` on E's word
    /// and the tick returns — no other change.
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

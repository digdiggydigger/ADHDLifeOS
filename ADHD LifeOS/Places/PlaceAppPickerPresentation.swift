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

//
//  AppearancePreference.swift
//  ADHD LifeOS
//

import SwiftUI

/// The v3 Settings appearance override (F-V3-Settings). Adaptation, flagged: v3 draws only
/// Light/Dark, but this app has always followed the system — so System stays, as the default.
/// Stored raw in UserDefaults under one key that BOTH ends observe via `@AppStorage`, so the
/// Settings picker and `RootView`'s `preferredColorScheme` stay in lockstep with no plumbing.
enum AppearancePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    static let storageKey = "settings.appearance"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var systemImage: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }

    /// `nil` means "no override" — SwiftUI then follows the system appearance.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    /// v3's themeLine, per choice — the honest one-liner under the picker.
    var explanation: String {
        switch self {
        case .system: return "Follows your device. The palette carries light and dark variants for every token."
        case .light: return "Light for daylight. Area colours darken so labels stay readable."
        case .dark: return "Dark by default — the closure green reads brightest against it."
        }
    }
}
